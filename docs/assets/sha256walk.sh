#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [--sortchecksum] <input_directory>"
  exit 1
}

SORT_BY_CHECKSUM=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sortchecksum) SORT_BY_CHECKSUM=true; shift ;;
    -*) echo "Error: Unknown flag '$1'" >&2; usage ;;
    *) break ;;
  esac
done

[[ $# -lt 1 ]] && usage

INPUT_DIR="${1%/}"  # Strip trailing slash

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Error: '$INPUT_DIR' is not a directory." >&2
  exit 1
fi

output=$(find "$INPUT_DIR" -type f -print0 | sort -z | while IFS= read -r -d '' file; do
  relative="${file#"$INPUT_DIR"/}"
  if command -v sha256sum &>/dev/null; then
    checksum=$(sha256sum "$file" | awk '{print $1}')
  else
    checksum=$(shasum -a 256 "$file" | awk '{print $1}')
  fi
  echo "$relative,$checksum"
done)

if $SORT_BY_CHECKSUM; then
  echo "$output" | sort -t',' -k2
else
  echo "$output"
fi
