#!/bin/bash -l
set -euxo pipefail

# Source first argument if it exists
if [ -n "${1-}" ]; then
  set -o allexport
  source "$1"
  set +o allexport
fi

# Avoid file expansion when passing parameters like with '*'
set -o noglob

# Check if all required environment variables are set
: GIT_CLIFF_CONFIG: "${GIT_CLIFF_CONFIG:?}";
: GIT_CLIFF_INCLUDE_PATH: "${GIT_CLIFF_INCLUDE_PATH:?}";
: GIT_CLIFF_EXCLUDE_PATH: "${GIT_CLIFF_EXCLUDE_PATH:?}";
: GIT_CLIFF_TAG_PATTERN: "${GIT_CLIFF_TAG_PATTERN:?}";
: GIT_CLIFF_IGNORE_TAGS: "${GIT_CLIFF_IGNORE_TAGS:-""}";
: GIT_CLIFF_OUTPUT: "${GIT_CLIFF_OUTPUT:?}"
: GIT_CLIFF_PREPEND: "${GIT_CLIFF_PREPEND:?}"
: GIT_CLIFF_CONTEXT: "${GIT_CLIFF_CONTEXT:?}"

# Check if config file exists
test -f "${GIT_CLIFF_CONFIG:?}" || {
  echo "${GIT_CLIFF_CONFIG}: file not found"; exit 1;
}

# Create the prepend file if it does not exist
test -f "${GIT_CLIFF_PREPEND:?}" || {
  touch "${GIT_CLIFF_PREPEND:?}"
}

# Run git-cliff
git-cliff \
  --bump -u

# Run git-cliff with context
unset GIT_CLIFF_PREPEND
git-cliff \
  --bump --context \
  --output ${GIT_CLIFF_CONTEXT}
