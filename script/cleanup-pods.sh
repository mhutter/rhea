#!/usr/bin/env bash
set -e -u -o pipefail

QUERY='
.items[] |
  select(.status.phase == "Succeeded" or .status.phase == "Failed") |
  "\(.metadata.namespace) \(.metadata.name)"
'

kubectl get pod -A -o json | \
  jq -r "$QUERY" | \
  while read -r namespace name; do
    kubectl -n "$namespace" delete pod "$name" --wait=false;
  done
