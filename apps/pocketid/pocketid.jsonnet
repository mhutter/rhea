local k = import '../../lib/k.libsonnet';
local mh = import '../../lib/mh.libsonnet';
local params = import 'params.libsonnet';

local pocketid = mh.workload(
  name='pocketid',
  image='ghcr.io/pocket-id/pocket-id:' + params.version,
  ports={
    http: {
      number: 80,
      host: params.host,
    },
  },
  env={
    PUBLIC_APP_URL: 'https://' + params.host,
    TRUST_PROXY: 'true',
    DB_PROVIDER: 'postgres',
    UPDATE_CHECK_DISABLED: 'true',
  },
  envFromSecret=['pocketid-env'],
  volumes={
    data: '/app/backend/data',
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
