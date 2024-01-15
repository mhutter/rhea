#!/bin/sh
set -e -u

if [ "$#" -ne 1 ]; then
  echo >&2 "usage: $0 HOST"
  exit 1
fi

host="$1"

# First manually build the NixOS configuration. This adds it to the GC roots,
# preventing GC from removing it
nix build ".#nixosConfigurations.${host}.config.system.build.toplevel" --out-link ".result-${host}"
deploy ".#${host}"
