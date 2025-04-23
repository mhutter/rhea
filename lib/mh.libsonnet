local libEnv = import 'env.libsonnet';
local network = import 'network.libsonnet';

// generate a generic workload resource
//
// Required parameters
// - `name` - the display name of the workload. Only used internally.
// - `image` - the image of the primary app container
// - `ports` - (exposed) ports in format `{name: { number: 1234, host: null/"asdf" }}`
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
  // { name: {number, host=null}},
  ports,
  cmd=[],
  env={},
  envFromSecret=[],
  initContainers=[],
  readinessPath=null,
  volumes={},
  extraContainerConfig={},
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

  // Define the port used in probes.
  //
  // Can be overwritten by merging `{ probePort:: 1234 }`
  probePort:: std.objectValues(ports)[0].number,

  local defaultContainerConfig = {
    image: image,
    securityContext: {
      allowPrivilegeEscalation: false,
      capabilities: { drop: ['ALL'] },
    },
    volumeMounts: mapVolumes(function(v) { name: v.key, mountPath: v.value }),
  },

  local mapVolumes(fn) = std.map(fn, std.objectKeysValues(volumes)),

  service: network.Service(name, ports, headless=true),

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
            ports: std.map(function(p) { name: p.key, containerPort: p.value.number }, std.objectKeysValues(ports)),

            env: libEnv.fromObj(env),
            envFrom: std.map(function(secret) { secretRef: { name: secret } }, envFromSecret),

            livenessProbe: { tcpSocket: { port: $.probePort } },
            readinessProbe:
              if readinessPath == null
              then
                { tcpSocket: { port: $.probePort } }
              else
                { httpGet: { port: $.probePort, path: readinessPath } },
            startupProbe: self.readinessProbe { failureThreshold: 30 },
          } + extraContainerConfig],

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
} + {
  ['ingress_' + port.key]: network.Ingress(port.value.host, name, port.key)
  for port in std.filter(function(port) std.get(port.value, 'host', default=null) != null, std.objectKeysValues(ports))
}
;


local OnePasswordItem(name, id) =
  local item = if std.length(std.findSubstr('/', id)) > 0 then
    local parts = std.split(id, '/');
    { vault: parts[0], name: parts[1] }
  else
    { vault: id[0:26], name: id[26:] };

  {
    apiVersion: 'onepassword.com/v1',
    kind: 'OnePasswordItem',
    metadata: {
      name: name,
    },
    spec: {
      itemPath: 'vaults/%s/items/%s' % [item.vault, item.name],
    },
  };

// exports
{
  workload: workload,
  OnePasswordItem: OnePasswordItem,
}
