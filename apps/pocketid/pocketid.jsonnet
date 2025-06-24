local k = import '../../lib/k.libsonnet';
local mh = import '../../lib/mh.libsonnet';
local params = import 'params.libsonnet';

local pocketid = mh.workload(
  name='pocketid',
  image='ghcr.io/pocket-id/pocket-id:' + params.version,
  ports={
    http: {
      number: 1411,
      host: params.host,
    },
  },
  env={
    APP_URL: 'https://' + params.host,
    DB_PROVIDER: 'postgres',
    TRUST_PROXY: 'true',
  },
  envFromSecret=['pocketid-env'],
  volumes={
    data: '/app/data',
  },
  readinessPath='/health',
);


k.List(
  [
    k.Namespace('pocketid'),
    mh.OnePasswordItem('pocketid-env', 'ygghe4vrf6je7fejk4hbncbhbeickez4zpicz5myaqeboysf37l4'),
  ]
  + std.objectValues(pocketid)
)
