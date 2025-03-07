#!/usr/bin/env bash
set -e -u -o pipefail

CACHE="$(mktemp -d /tmp/kubeconform.XXXXXXXXXX)"
cleanup() {
  rm -rf "$CACHE"
}
trap cleanup EXIT

ERRORS=0
while read -r dir; do
  echo
  echo "---> ${dir}";

  if [ -f "${dir}/Chart.yaml" ]; then
    echo "     Helm Chart"
    MANIFESTS="$(helm template "${dir}")"
  elif [ -f "${dir}/kustomization.yaml" ]; then
    echo "     Kustomization"
    MANIFESTS="$(kustomize build "${dir}")"
  else
    echo "     Jsonnet"
    MANIFESTS="$(find "${dir}" -name '*.jsonnet' | xargs -n1 jsonnet -J lib)"
  fi

  set +e
  echo "$MANIFESTS" | \
  kubeconform -cache "$CACHE" -summary \
    -strict \
    -schema-location default \
    -schema-location 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/{{.NormalizedKubernetesVersion}}/{{.ResourceKind}}.json' \
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
  CODE="$?"
  set -e

  ERRORS=$((ERRORS + CODE))
done <<< "$(ls -d apps/*)"

test "$ERRORS" -eq 0
