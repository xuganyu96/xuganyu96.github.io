#!/usr/bin/env bash

# Synchronize the contents of a local directory with a remote directory using rsync.
# This script was written with assistance from OpenAI's GPT-5.6 Sol model

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  dumbsync.sh [OPTIONS] <up|down>

Synchronize the contents of a local directory with a remote directory using
rsync.

Commands:
  up
      Sync from the local directory to the remote directory.

  down
      Sync from the remote directory to the local directory.

Options:
  --local <path>
      Local directory path.

      If omitted, $DUMBSYNC_LOCAL is used. If neither is set, the command exits
      with an error.

      For `up`, the local directory must be readable. For `down`, the local
      destination must be writable.

  --remote <path>
      Remote directory URL or local directory path passed to rsync.

      If omitted, $DUMBSYNC_REMOTE is used. If neither is set, the command exits
      with an error.

      The remote path is always treated as a directory, and its contents are
      synchronized rather than the directory itself.

  --ignore <path>
      Path to a file passed to rsync with --exclude-from.

      If omitted, $DUMBSYNC_IGNORE is used. If neither is set, no exclude file
      is used.

  --dry-run
      Perform a dry run. Passes --dry-run and --verbose to rsync, and does not
      use --info=progress2.

      Without --dry-run, rsync uses --info=progress2 and not --verbose.

  -h, --help
      Show this help message and exit.

rsync is always run with:
  -azhu

Directory paths are given trailing slashes so that the contents of the source
directory are synchronized with the contents of the destination directory,
rather than copying the source directory itself into the destination.
EOF
}

local_path=""
remote_path=""
ignore_path=""
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)
      [[ $# -ge 2 ]] || {
        usage >&2
        exit 2
      }
      local_path=$2
      shift 2
      ;;
    --remote)
      [[ $# -ge 2 ]] || {
        usage >&2
        exit 2
      }
      remote_path=$2
      shift 2
      ;;
    --ignore)
      [[ $# -ge 2 ]] || {
        usage >&2
        exit 2
      }
      ignore_path=$2
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "unknown option: $1" >&2
      echo >&2
      usage >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

command=$1

case "$command" in
  up|down)
    ;;
  *)
    echo "command must be 'up' or 'down'" >&2
    echo >&2
    usage >&2
    exit 2
    ;;
esac

if [[ -z "$local_path" ]]; then
  local_path=${DUMBSYNC_LOCAL:-}
fi

if [[ -z "$local_path" ]]; then
  echo "local path must be explicitly set with --local or with environment variable DUMBSYNC_LOCAL" >&2
  exit 1
fi

if [[ -z "$remote_path" ]]; then
  remote_path=${DUMBSYNC_REMOTE:-}
fi

if [[ -z "$remote_path" ]]; then
  echo "remote path must be explicitly set with --remote or environment variable DUMBSYNC_REMOTE" >&2
  exit 1
fi

if [[ -z "$ignore_path" ]]; then
  ignore_path=${DUMBSYNC_IGNORE:-}
fi

if [[ -n "$ignore_path" && ! -r "$ignore_path" ]]; then
  echo "ignore file is not readable: $ignore_path" >&2
  exit 1
fi

# The remote path always represents a directory.
remote_path="${remote_path%/}/"

rsync_args=(-azhu --delete)

if [[ -n "$ignore_path" ]]; then
  rsync_args+=(--exclude-from "$ignore_path")
fi

if [[ "$dry_run" == true ]]; then
  rsync_args+=(--dry-run --verbose)
else
  rsync_args+=(--info=progress2)
fi

if [[ "$command" == up ]]; then
  if [[ ! -d "$local_path" ]]; then
    echo "local path is not a directory: $local_path" >&2
    exit 1
  fi

  if [[ ! -r "$local_path" || ! -x "$local_path" ]]; then
    echo "local directory is not readable: $local_path" >&2
    exit 1
  fi

  source_path="${local_path%/}/"
  destination_path=$remote_path
else
  source_path=$remote_path
  destination_path=$local_path

  if [[ -e "$destination_path" ]]; then
    if [[ ! -d "$destination_path" ]]; then
      echo "local destination is not a directory: $destination_path" >&2
      exit 1
    fi

    if [[ ! -w "$destination_path" || ! -x "$destination_path" ]]; then
      echo "local destination directory is not writable: $destination_path" >&2
      exit 1
    fi
  else
    parent_dir=$(dirname "$destination_path")

    if [[ ! -d "$parent_dir" || ! -w "$parent_dir" || ! -x "$parent_dir" ]]; then
      echo "parent directory of local destination is not writable: $parent_dir" >&2
      exit 1
    fi
  fi

  destination_path="${destination_path%/}/"
fi

rsync "${rsync_args[@]}" "$source_path" "$destination_path"
