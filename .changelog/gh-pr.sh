#!/bin/bash -l
set -euxo pipefail

# Source first argument if it exists
if [ -n "${1-}" ]; then
  set -o allexport
  source "$1"
  set +o allexport
fi

# Make sure we exit gracefully
export GIT_CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
function cleanup {
  git checkout "$GIT_CURRENT_BRANCH"
}
trap cleanup EXIT

# Get the version from the context
VERSION=$(cat "${GIT_CLIFF_CONTEXT:?}" | jq -r '.[0].version')

exit 1
# Build name of the branch where the PR will be created
BRANCH_NAME="_changelog/$VERSION"

# Create a new branch or checkout an existing one
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  git checkout -f "$BRANCH_NAME"
else
  git checkout -f -b "$BRANCH_NAME"
fi

## Reset the branch to the state of GIT_CURRENT_BRANCH
#git reset --hard "$GIT_CURRENT_BRANCH"
#
## Add changelog files to the commit
#git add "$GIT_CLIFF_OUTPUT"
#git add "$GIT_CLIFF_PREPEND"
#git add "$GIT_CLIFF_CONTEXT"
#
## Set the PR title and body
#PR_TITLE="changelog: $VERSION"
#
## Commit the changelog
#git commit -m "${PR_TITLE}"
#
## Push the branch
#git push --force --set-upstream origin "$BRANCH_NAME"
#
## Create a PR if it doesn't exist
#PR_URL=$(gh pr list --head "$BRANCH_NAME" --base=$GIT_CURRENT_BRANCH --json url --jq '.[0].url')
#
#if [ -z "$PR_URL" ]; then
#  gh pr create --title "${PR_TITLE}" --head "$BRANCH_NAME" --base "$GIT_CURRENT_BRANCH" --body "Hey!"
#else
#  # make sure to properly name the PR
#  gh pr edit $PR_URL --title "${PR_TITLE}"
#fi