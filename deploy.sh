#!/bin/sh
set -e -u

if [ "$#" -ne 1 ]; then
  echo >&2 "usage: $0 HOST"
  exit 1
fi

host="$1"

set -x
nixos-rebuild switch --fast --flake ".#${host}" --target-host "$host" --build-host "$host"
