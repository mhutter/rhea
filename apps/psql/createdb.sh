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

# Create the user
psql -U "${POSTGRES_USER:-postgres}" --command "CREATE USER ${NAME} WITH PASSWORD '${PASSWORD}';" >&2

# Create the database, setting the new user as the owner
createdb -U "${POSTGRES_USER:-postgres}" -O "$NAME" "$NAME"

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
