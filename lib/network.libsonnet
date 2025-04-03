local Ingress(host, service, port='') =
  local name = std.strReplace(host, '.', '-');
  {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: name,
      annotations: {
        'cert-manager.io/cluster-issuer': 'letsencrypt-production',
      },
    },
    spec: {
      rules: [{
        host: host,
        http: {
          paths: [{
            backend: {
              service: {
                name: service,
                port: { name: if port == '' then service else port },
              },
            },
            path: '/',
            pathType: 'Prefix',
          }],
        },
      }],
      tls: [{
        hosts: [host],
        secretName: name + '-tls',
      }],
    },
  };

local Service(name, ports, headless=false) =
  local selector = { app: name };
  {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: name,
      labels: selector,
    },
    spec: {
      type: 'ClusterIP',
      [if headless then 'clusterIP']: 'None',
      ports: std.map(function(p) { name: p.key, port: p.value.number }, std.objectKeysValues(ports)),
      selector: selector,
    },
  };

{
  Ingress: Ingress,
  Service: Service,
}
