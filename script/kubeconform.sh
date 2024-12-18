#!/usr/bin/env bash
set -e -u -o pipefail


HAD_ERRORS=false
ls -d apps/* | \
while read -r dir; do
  echo "---> ${dir}";

  kustomize build "$dir" | \
  kubeconform \
    -schema-location default \
    -schema-location 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/{{.NormalizedKubernetesVersion}}/{{.ResourceKind}}.json' \
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

  if [ "$?" -ne "0" ]; then
    HAD_ERRORS=true
  fi
done

test "$HAD_ERRORS" = "false"
