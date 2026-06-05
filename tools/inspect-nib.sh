#!/bin/sh

set -eu

usage() {
  echo "usage: $0 PATH-TO-NIB" >&2
  exit 2
}

[ "$#" -eq 1 ] || usage

nib_path=$1
[ -e "$nib_path" ] || {
  echo "error: '$nib_path' does not exist" >&2
  exit 1
}

inspect_file() {
  path=$1

  printf '\nFILE %s\n' "$path"
  printf 'TYPE '
  file -b "$path"
  printf 'SIZE '
  wc -c < "$path" | tr -d ' '
  printf '\nHEADER '
  od -An -tx1 -N32 "$path" | tr -s ' ' | sed 's/^ //'
  printf 'STRINGS\n'
  strings -a "$path" | head -n 80 || true
}

printf 'NIB %s\n' "$nib_path"
printf 'INSPECTED_AT_UTC '
date -u '+%Y-%m-%dT%H:%M:%SZ'

if [ -d "$nib_path" ]; then
  printf 'LAYOUT\n'
  find "$nib_path" -type f -print | LC_ALL=C sort

  find "$nib_path" -type f -print | LC_ALL=C sort |
    while IFS= read -r path; do
      inspect_file "$path"
    done
else
  inspect_file "$nib_path"
fi

