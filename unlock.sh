#!/bin/sh
set -e -u

if [ "$#" -ne 1 ]; then
  echo >&2 "usage: $0 HOST"
  exit 1
fi

host="$1"

openssl enc -aes256 -pbkdf2 -d -in "luks-${host}.key" | command ssh "${host}-boot" cryptsetup-askpass
