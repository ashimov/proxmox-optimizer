#!/usr/bin/env bash
################################################################################
# This is property of ashimov.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Berik Ashimov :: berik@ashimov.com
################################################################################
#
# Builds the SHA256SUMS list published with each release.
#
# Covers what a user is told to download and run: the shell scripts, the two
# extensionless Hetzner post-install files, and the sample env file. Test
# helpers are not in the list, nobody fetches those from a release.
#
# Usage:
#   ./scripts/make-checksums.sh              # print to stdout
#   ./scripts/make-checksums.sh SHA256SUMS   # write to a file
#
################################################################################
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

out="${1:-}"

# while-read rather than mapfile so this also runs on the bash 3.2 that ships
# with macOS, where a maintainer might regenerate the list by hand.
files=()
while IFS= read -r line; do
  files+=("$line")
done < <(
  {
    find . -path ./.git -prune -o -path ./.history -prune -o -path ./tests -prune \
         -o -name '*.sh' -type f -print
    printf '%s\n' ./hetzner/pve ./hetzner/pbs ./install-post.env.sample
  } | sed 's|^\./||' | sort -u
)

if [ "${#files[@]}" -eq 0 ]; then
  echo "ERROR: no files matched" >&2
  exit 1
fi

for f in "${files[@]}"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: listed file is missing: $f" >&2
    exit 1
  fi
done

if [ -n "$out" ]; then
  sha256sum "${files[@]}" > "$out"
  echo "Wrote ${out} (${#files[@]} files)" >&2
else
  sha256sum "${files[@]}"
fi
