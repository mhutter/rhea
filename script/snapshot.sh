#!/usr/bin/env bash
set -e -u -o pipefail

SNAPSHOT_DIR="__snapshots__"

OUT="$(mktemp -d /tmp/rhea-snapshot.XXXXXXXXXX)"
cleanup() {
  rm -rf "$OUT"
}
trap cleanup EXIT

# Render all Jsonnet files into $1
render_all() {
  local OUT_DIR="$1"

  find apps -name '*.jsonnet' | \
  while read -r file; do
    target="${OUT_DIR}/${file}.json"

    mkdir -p "$(dirname "$target")"
    jsonnet "$file" > "$target"
  done
}

cmd_diff() {
  render_all "$OUT"
  difft --exit-code --color=always "$SNAPSHOT_DIR/" "$OUT/"
}

cmd_update() {
  render_all "$SNAPSHOT_DIR"
}

case "${1:-}" in
  diff)
    cmd_diff
  ;;
  update)
    cmd_update
  ;;
  *)
    echo >&2 "usage: $0 {diff|update}"
  ;;
esac
