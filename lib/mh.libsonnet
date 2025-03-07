local libEnv = import 'env.libsonnet';
local network = import 'network.libsonnet';

// generate a generic workload resource
//
// Required parameters
// - `name` - the display name of the workload. Only used internally.
// - `image` - the image of the primary app container
// - `port` - the port of the primary app container
//
// Optional parameters
// - `cmd` - The command of the primary app container
// - `env` - Map of environment variables for the primary app container
// - `envFromSecret` - List of secrets to inject into the environment variables
// - `initContainers` - Extra containers that run before the application.
//   Basic workload patches (securityContext) will be applied.
// - `readinessPath` - Path to check in the readiness probe. A TCP probe will be used instead.
// - `volumes` - Map of volume names to paths
local workload(
  name,
  image,
  port,
  cmd=[],
  env={},
  envFromSecret=[],
  host=null,
  initContainers=[],
  readinessPath=null,
  volumes={},
      ) = {
  // Common labels, also used as selectors
  //
  // Can be overwritten by merging `{ commonLabels+:: { ... }}`
  commonLabels:: {
    app: name,
    'app.kubernetes.io/component': name,
  },

  // Generate a stable random UID for this workload
  //
  // Can be overwritten by merging `{ uid:: 123 }`
  uid:: std.foldl(
    // multiply all the codepoints;
    // adding +1 each time to never get zero
    // module to not get values over 1'000'000
    function(acc, c) (acc + 1) * (std.codepoint(c) + 1) % 1000000,
    std.stringChars(std.md5(name)),
    1,
  ),

  local defaultContainerConfig = {
    image: image,
    securityContext: {
      allowPrivilegeEscalation: false,
      capabilities: { drop: ['ALL'] },
    },
    volumeMounts: mapVolumes(function(v) { name: v.key, mountPath: v.value }),
  },

  local mapVolumes(fn) = std.map(fn, std.objectKeysValues(volumes)),

  service: network.Service(name, port, headless=true),

  [if host != null then 'ingress']: network.Ingress(host, name),

  statefulset: {
    apiVersion: 'apps/v1',
    kind: 'StatefulSet',
    metadata: {
      name: name,
      labels: $.commonLabels,
    },
    spec: {
      revisionHistoryLimit: 1,
      serviceName: name,
      selector: {
        matchLabels: $.commonLabels,
      },
      template: {
        metadata: {
          labels: $.commonLabels,
        },
        spec: {
          automountServiceAccountToken: false,
          enableServiceLinks: false,

          // initContainers but apply defaults
          initContainers: std.map(function(c) defaultContainerConfig + c, initContainers),

          // so far only one container supported, using defaults from above
          containers: [defaultContainerConfig {
            name: name,
            // image: is in defaultContainerConfig
            [if std.length(cmd) > 0 then 'command']: cmd,
            ports: [{ name: name, containerPort: port }],

            env: libEnv.fromObj(env),
            envFrom: std.map(function(secret) { secretRef: { name: secret } }, envFromSecret),

            livenessProbe: { tcpSocket: { port: port } },
            readinessProbe:
              if readinessPath == null
              then
                { tcpSocket: { port: port } }
              else
                { httpGet: { port: port, path: readinessPath } },
            startupProbe: self.readinessProbe { failureThreshold: 30 },
          }],

          securityContext: {
            runAsNonRoot: true,
            runAsUser: $.uid,
            runAsGroup: $.uid,
            seccompProfile: {
              type: 'RuntimeDefault',
            },
          },

          volumes: mapVolumes(function(v) {
            name: v.key,
            persistentVolumeClaim: { claimName: v.key },
          }),
        },
      },

      volumeClaimTemplates: mapVolumes(function(v) {
        apiVersion: 'v1',
        kind: 'PersistentVolumeClaim',
        metadata: { name: v.key },
        spec: {
          accessModes: ['ReadWriteOnce'],
          resources: {
            requests: {
              storage: '1Gi',
            },
          },
        },
      }),
    },
  },
};

// exports
{
  workload: workload,
}
