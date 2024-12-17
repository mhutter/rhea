#!/bin/bash

usage() {
  echo >&2 "usage: $0 DBNAME"
}

if [ "$#" -ne 1 ]; then
  usage
  exit 1;
fi

NAME="$(echo $1 | tr '[:upper:]' '[:lower:]')"
PASSWORD="$(cat /dev/urandom | tr -dc '[:alnum:]' | head -c 32)"

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-postgres}" >&2 <<-EOSQL
	CREATE USER ${NAME} WITH PASSWORD '${PASSWORD}';
	CREATE DATABASE ${NAME};
	GRANT ALL PRIVILEGES ON DATABASE ${NAME} TO ${NAME};
EOSQL

cat <<SECRET
apiVersion: v1
kind: Secret
metadata:
  name: db-creds
type: Opaque
stringData:
  POSTGRESQL_DB: "${NAME}"
  POSTGRESQL_HOST: psql.psql.svc.cluster.local
  POSTGRESQL_USER: "${NAME}"
  POSTGRESQL_PASSWORD: "${PASSWORD}"
  POSTGRESQL_PORT: "5432"
  POSTGRESQL_URL: "postgres://${NAME}:${PASSWORD}@psql.psql.svc.cluster.local:5432/${NAME}"
SECRET
