#!/bin/bash -l
set -euxo pipefail

# Text colors
BLACK='\e[30m'
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
WHITE='\e[37m'

print_color() {
  local color=$1
  local text=$2
  local NC='\e[0m'
  echo -e "${color}${text}${NC}"
}


# Source first argument if it exists
if [ -n "${1-}" ]; then
  set -o allexport
  source "$1"
  set +o allexport
fi

# Avoid file expansion when passing parameters like with '*'
set -o noglob

function git-cliff-init() {
  : "${GIT_CLIFF_IGNORE_TAGS:-""}";
  : "${GIT_CLIFF_INCLUDE_PATH:?}";
  : "${GIT_CLIFF_EXCLUDE_PATH:?}";
  : "${GIT_CLIFF_TAG_PATTERN:?}";
  : "${GIT_CLIFF_PREPEND:?}"
  : "${GIT_CLIFF_CONTEXT:?}"
  : "${GIT_CLIFF_CONFIG:?}";
  : "${GIT_CLIFF_OUTPUT:?}"

  test -f "${GIT_CLIFF_CONFIG:?}" || {
    echo "${GIT_CLIFF_CONFIG}: file not found"; exit 1;
  }
  test -f "${GIT_CLIFF_CONFIG:?}" || {
    echo "${GIT_CLIFF_CONFIG}: file not found"; exit 1;
  }
  test -f "${GIT_CLIFF_PREPEND:?}" || {
    touch "${GIT_CLIFF_PREPEND:?}"
  }
}

function git-cliff-run(){
    git-cliff \
      --bump -u
}

function git-cliff-run-context(){
  git-cliff \
    --bump --context -u \
    --output ${GIT_CLIFF_CONTEXT}
}

function has_changed(){
  if ! git status --short --porcelain | cut -c 4- | grep -q "$GIT_CLIFF_OUTPUT"; then
    print_color ${GREEN} "No changes detected after generating the changelog."
    exit 0
  else
    print_color ${RED} "Changes detected after generating the changelog."
    git status
  fi
}

function git-prepare(){
  export GIT_CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  function cleanup {
    git checkout "$GIT_CURRENT_BRANCH"
  }
  trap cleanup EXIT
}


function git-checkout(){
  VERSION=$(cat "${GIT_CLIFF_CONTEXT:?}" | jq -r '.[0].version')
  BRANCH_NAME="_changelog/${VERSION:?}"

  if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME:?}"; then
    git checkout -f "${BRANCH_NAME:?}"
  else
    git checkout -f -b "${BRANCH_NAME:?}"
  fi

  git reset --hard "${GIT_CURRENT_BRANCH:?}"
}

function git-commit(){
  git add "${GIT_CLIFF_OUTPUT:?}"
  git add "${GIT_CLIFF_PREPEND:?}"
  git add "${GIT_CLIFF_CONTEXT:?}"

  COMMIT_MESSAGE="changelog: ${VERSION:?}"

  git commit --status -m "${COMMIT_MESSAGE?}"

  git status
  git show -q
}

function git-push(){
  git push --force --set-upstream origin "${BRANCH_NAME:?}"
}


function gh-pr(){
  PR_URL=$(gh pr list --head "$BRANCH_NAME" --base=$GIT_CURRENT_BRANCH --json url --jq '.[0].url')
  PR_TITLE="changelog: $VERSION"

  if [ -z "$PR_URL" ]; then
    gh pr create --title "${PR_TITLE:?}" --head "$BRANCH_NAME" --base "$GIT_CURRENT_BRANCH" --body "Hey!"
  else
    gh pr edit $PR_URL --title "${PR_TITLE}"
  fi
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Function 'my_function' was sourced."
else
    echo "Function 'my_function' was executed."
    git-cliff-init
    git-cliff-run && has_changed
    git-cliff-run-context
    git-prepare
    git-checkout
    git-cliff-run && has_changed
    git-cliff-run-context
    git-commit
    git-push
    gh-pr
fi
