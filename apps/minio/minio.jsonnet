local k = import '../../lib/k.libsonnet';
local mh = import '../../lib/mh.libsonnet';
local params = import 'params.libsonnet';

local minio = mh.workload(
  name='minio',
  image='quay.io/minio/minio:' + params.version,
  cmd=['minio', 'server'],
  ports={
    api: {
      number: 9000,
      host: params.host,
    },
    console: {
      number: 9001,
      host: params.consoleHost,
    },
  },
  env={
    MINIO_BROWSER_LOGIN_ANIMATION: 'off',
    MINIO_BROWSER_REDIRECT: 'false',
    MINIO_BROWSER_REDIRECT_URL: 'https://' + params.consoleHost,
    MINIO_CONSOLE_ADDRESS: ':9001',
    MINIO_DOMAIN: params.host,
    MINIO_VOLUMES: '/data',
  },
  envFromSecret=['minio-env'],
  volumes={
    data: '/data',
  },
  readinessPath='/minio/health/live',
);


k.List(
  [
    k.Namespace('minio'),
    mh.OnePasswordItem('minio-env', 'ygghe4vrf6je7fejk4hbncbhbec67rmqnsqi3tfrvna4tazwxvse'),
  ]
  + std.objectValues(minio)
)
