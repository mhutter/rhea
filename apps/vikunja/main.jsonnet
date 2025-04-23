local k = import '../../lib/k.libsonnet';
local mh = import '../../lib/mh.libsonnet';
local params = import 'params.libsonnet';

local app = mh.workload(
  name='vikunja',
  image='docker.io/vikunja/vikunja:' + params.version,
  ports={
    http: {
      number: 3456,
      host: params.host,
    },
  },
  env={
    VIKUNJA_SERVICE_PUBLICURL: 'https://%s/' % params.host,
    VIKUNJA_DATABASE_TYPE: 'postgres',
    VIKUNJA_DATABASE_USER: 'vikunja',
    VIKUNJA_DATABASE_HOST: 'psql.psql.svc.cluster.local',
    VIKUNJA_DATABASE_DATABASE: 'vikunja',
    VIKUNJA_AUTH_LOCAL_ENABLED: 'false',
    VIKUNJA_AUTH_OPENID_ENABLED: 'true',
    VIKUNJA_AUTH_OPENID_PROVIDERS_POCKETID_NAME: 'mhnet ID',
    VIKUNJA_AUTH_OPENID_PROVIDERS_POCKETID_AUTHURL: 'https://me.mhnet.app',
  },
  envFromSecret=['vikunja-env'],
  volumes={
    files: '/app/vikunja/files',
  },
);


k.List(
  [
    k.Namespace('vikunja'),
    mh.OnePasswordItem('vikunja-env', 'rhea/vikunja-env'),
  ]
  + std.objectValues(app)
)
