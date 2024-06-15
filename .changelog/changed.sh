#!/bin/bash -l
set -euxo pipefail

# Source first argument if it exists
if [ -n "${1-}" ]; then
  set -o allexport
  source "$1"
  set +o allexport
fi

# Build json array of untracked and tracked files
GIT_UNTRACKED_CHANGES=$(git ls-files --others --exclude-standard | jq -R -s -c 'split("\n")[:-1]')
GIT_TRACKED_CHANGES=$(git diff --name-only | jq -R -s -c 'split("\n")[:-1]')

# Group the untracked and tracked files
GIT_CHANGED_FILES=$(echo "$GIT_UNTRACKED_CHANGES" "$GIT_TRACKED_CHANGES" | jq -s -c 'add | unique')

# Check if the changelog file has changed
GIT_HAS_CHANGELOG_CHANGED=$(echo $GIT_CHANGED_FILES | jq -r --arg target "$GIT_CLIFF_OUTPUT" '.[] | select(. == $target)')

# Exit if no changes are detected
if [ -z "$GIT_HAS_CHANGELOG_CHANGED" ]; then
  echo "No changes detected after generating the changelog."
  exit 1
fi

exit 0