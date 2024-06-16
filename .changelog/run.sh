#!/bin/bash
set -euxo pipefail

PROJECTS=(
  "project-ghrp-npm"
)

run_changelog_generation() {
  local project="$1"
  local changelog_env="./$project/CHANGELOG/cliff.env"

  # Source cliff.env for the project
  source ./.changelog/git-cliff.sh "$changelog_env"

  # Check if there are changes detected
  if ./.changelog/has-changed.sh "$changelog_env"; then
    echo "Changes detected after generating the changelog for $project."
  else
    echo "No changes detected after generating the changelog for $project."
  fi
}

# Main logic starts here
if [ "$1" == "all" ]; then
  # Generate changelog for all projects
  for project in "${PROJECTS[@]}"; do
    (run_changelog_generation "$project")
  done
elif [ -d "$1" ]; then
  # Generate changelog for specified project
  (run_changelog_generation "$1")
else
  # Directory doesn't exist
  echo "Directory '$1' does not exist."
  exit 1
fi

exit 0
