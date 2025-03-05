local libEnv = import 'env.libsonnet';

local newWorkload(name, image, port, cmd=[], env={}) =
  local selector = { app: name };
  {
    metadata: {
      name: name,
      labels: selector,
    },
    spec: {
      revisionHistoryLimit: 1,
      selector: {
        matchLabels: selector,
      },
      template: {
        metadata: {
          labels: selector,
        },
        spec: {
          containers: [{
            name: name,
            image: image,
            [if std.length(cmd) > 0 then 'command']: cmd,
            ports: [{ name: name, containerPort: port }],
            env: libEnv.fromObj(env),
            livenessProbe: { tcpSocket: { port: port } },
            readinessProbe: { tcpSocket: { port: port } },
            startupProbe: { tcpSocket: { port: port }, failureThreshold: 30 },
            securityContext: {
              allowPrivilegeEscalation: false,
              capabilities: { drop: ['ALL'] },
            },
          }],
          securityContext: {
            runAsNonRoot: true,
            seccompProfile: {
              type: 'RuntimeDefault',
            },
          },
        },
      },
    },
  };

local asStatefulSet = {
  apiVersion: 'apps/v1',
  kind: 'StatefulSet',
  spec+: {
    serviceName: $.metadata.name,
  },
};

local asDeployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
};

{
  asDeployment: asDeployment,
  asStatefulSet: asStatefulSet,
  new: newWorkload,
}
