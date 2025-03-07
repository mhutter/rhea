local env = import 'env.libsonnet';

local network = import 'network.libsonnet';
local workload = import 'workload.libsonnet';

local statefulApp(name, image, port, cmd=[], env={}, workloadPatches=[]) = [
  network.Service(name, port, headless=true),
  // apply all workload patches
  std.foldl(
    function(wl, patch) wl + patch,
    workloadPatches,
    (workload.new(name=name, image=image, port=port, cmd=cmd, env=env) + workload.asStatefulSet)
  ),
];

local List(items) = {
  apiVersion: 'v1',
  kind: 'List',
  items: items,
};

local Namespace(name, restricted=true) = {
  apiVersion: 'v1',
  kind: 'Namespace',
  metadata: {
    name: name,
    [if restricted then 'labels']: {
      'pod-security.kubernetes.io/enforce': 'restricted',
      'pod-security.kubernetes.io/enforce-version': 'latest',
      'pod-security.kubernetes.io/warn': 'restricted',
      'pod-security.kubernetes.io/warn-version': 'latest',
    },
  },
};

{
  List: List,
  Namespace: Namespace,
  statefulApp: statefulApp,
  workload: workload,
} + network
