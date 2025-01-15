#!/usr/bin/env bash
set -e -u -o pipefail

CACHE="$(mktemp -d /tmp/kubeconform.XXXXXXXXXX)"
cleanup() {
  rm -rf "$CACHE"
}
trap cleanup EXIT

ERRORS=0
while read -r dir; do
  echo "---> ${dir}";

  if [ -f "${dir}/Chart.yaml" ]; then
    echo "     Helm Chart"
    MANIFESTS="$(helm template "${dir}")"
  else
    echo "     Kustomization"
    MANIFESTS="$(kustomize build "${dir}")"
  fi

  set +e
  echo "$MANIFESTS" | \
  kubeconform -cache "$CACHE" \
    -schema-location 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/{{.NormalizedKubernetesVersion}}/{{.ResourceKind}}.json' \
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
  CODE="$?"
  set -e

  ERRORS=$((ERRORS + CODE))
done <<< "$(ls -d apps/*)"

test "$ERRORS" -eq 0
