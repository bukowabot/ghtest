#!/bin/bash -l
set -euxo pipefail

# Source first argument if it exists
if [ -n "${1-}" ]; then
  set -o allexport
  source "$1"
  set +o allexport
fi

# Check for changes in git status output
if ! git status --short --porcelain | cut -c 4- | grep -q "$GIT_CLIFF_OUTPUT"; then
  echo "No changes detected after generating the changelog."
  exit 1
fi

exit 0