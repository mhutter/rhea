#!/bin/sh
set -e -u

if [ "$#" -ne 1 ]; then
  echo >&2 "usage: $0 HOST"
  exit 1
fi

host="$1"

rbw get "luks ${host}" | openssl enc -aes256 -pbkdf2 -e -out "luks-${host}.key"
