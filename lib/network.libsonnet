local Ingress(host, service) =
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
                port: { name: service },
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

local Service(name, port, headless=false) =
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
      ports: [{ name: name, port: port }],
      selector: selector,
    },
  };


{
  Ingress: Ingress,
  Service: Service,
}
