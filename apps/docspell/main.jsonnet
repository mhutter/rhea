local k = import '../../lib/k.libsonnet';
local mh = import '../../lib/mh.libsonnet';
local params = import 'params.libsonnet';

local defaultEnv(infix) = {
  TZ: 'Europe/Zurich',
  POD_NAME: {
    fieldPath: 'metadata.name',
  },
  POD_NAMESPACE: {
    fieldPath: 'metadata.namespace',
  },
  ['DOCSPELL_%s_APP__ID' % infix]: '$(POD_NAME)',
  ['DOCSPELL_%s_BIND_ADDRESS' % infix]: '0.0.0.0',
  ['DOCSPELL_%s_FULL__TEXT__SEARCH_ENABLED' % infix]: 'true',
  ['DOCSPELL_%s_FULL__TEXT__SEARCH_BACKEND' % infix]: 'solr',
  ['DOCSPELL_%s_FULL__TEXT__SEARCH_SOLR_URL' % infix]: 'http://solr:8983/solr/docspell',
};

local restserver = mh.workload(
  name='restserver',
  image='ghcr.io/docspell/restserver:' + params.version,
  ports={
    restserver: { number: 7880, host: params.host },
  },
  env=defaultEnv('SERVER') {
    DOCSPELL_SERVER_APP__NAME: 'mhnet DMS',
    DOCSPELL_SERVER_BASE__URL: 'https://' + params.host,
    DOCSPELL_SERVER_INTERNAL__URL: 'http://restserver:7880',
  } + {
    ['DOCSPELL_SERVER_BACKEND_JDBC_%s' % key]: {
      secretName: 'db-creds',
      key: key,
    }
    for key in ['URL', 'USER', 'PASSWORD']
  },
  envFromSecret=['docspell-auth'],
);

local joex = mh.workload(
  name='joex',
  image='ghcr.io/docspell/joex:' + params.version,
  ports={
    joex: { number: 7878 },
  },
  env=defaultEnv('JOEX') {
    DOCSPELL_JOEX_PERIODIC__SCHEDULER_NAME: '$(POD_NAME)',
    DOCSPELL_JOEX_SCHEDULER_NAME: '$(POD_NAME)',
    DOCSPELL_JOEX_BASE__URL: 'http://joex:7878',
  } + {
    ['DOCSPELL_JOEX_JDBC_%s' % key]: {
      secretName: 'db-creds',
      key: key,
    }
    for key in ['URL', 'USER', 'PASSWORD']
  },
);

local solr = mh.workload(
  name='solr',
  image='docker.io/library/solr:' + params.solrVersion,
  cmd=['solr', '-f', '--user-managed', '-Dsolr.modules=analysis-extras'],
  ports={ solr: { number: 8983 } },
  readinessPath='/solr/docspell/admin/ping',
  initContainers=[{
    name: 'precreate-core',
    command: ['/bin/sh', '-c', 'mkdir -pv /var/solr/data; precreate-core docspell'],
  }],
  volumes={
    data: '/var/solr',
  }
);

k.List(
  [
    k.Namespace('docspell'),
    mh.OnePasswordItem('db-creds', 'ygghe4vrf6je7fejk4hbncbhbedwlorl4sz7xfiol4avrodmj7mi'),
    mh.OnePasswordItem('docspell-auth', 'ygghe4vrf6je7fejk4hbncbhbejkehpdmkbv2bd4enp43g72oeny'),
  ]
  + std.objectValues(restserver)
  + std.objectValues(joex)
  + std.objectValues(solr)
)
