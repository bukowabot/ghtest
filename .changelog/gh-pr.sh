#!/bin/bash -l
set -euxo pipefail

# Make sure we exit gracefully
export GIT_CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
function cleanup {
  git checkout "$GIT_CURRENT_BRANCH"
}
trap cleanup EXIT

# Source first argument if it exists
if [ -n "${1-}" ]; then
  set -o allexport
  source "$1"
  set +o allexport
fi

VERSION=$(cat "${GIT_CLIFF_CONTEXT:?}" | jq -r '.[0].version')

# Build name of the branch where the PR will be created
BRANCH_NAME="_changelog/${CHANGELOG_PACKAGE_NAME}-$VERSION"

# Create a new branch or checkout an existing one
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  git checkout -f "$BRANCH_NAME"
else
  git checkout -f -b "$BRANCH_NAME"
  git push -u origin "$BRANCH_NAME" || true
fi

# Reset the branch to the state of GIT_CURRENT_BRANCH
git reset --hard "$GIT_CURRENT_BRANCH"

# Add to git and push only 3 files
#"$GIT_CLIFF_OUTPUT" "$GIT_CLIFF_PREPEND" "$GIT_CLIFF_CONTEXT"
#
git add "$GIT_CLIFF_OUTPUT" || true
git add "$GIT_CLIFF_PREPEND" || true
git add "$GIT_CLIFF_CONTEXT" || true

# commit
git commit -m "changelog: $VERSION"

# push
git push --force --set-upstream origin "$BRANCH_NAME"

# check if there's pr for this branch targeting the main branch
PR_URL=$(gh pr list --head "$BRANCH_NAME" --base=$GIT_CURRENT_BRANCH --json url --jq '.[0].url')

if [ -z "$PR_URL" ]; then
  gh pr create --title "changelog: $VERSION" --body "changelog: $VERSION" --head "$BRANCH_NAME" --base "$GIT_CURRENT_BRANCH"
fi