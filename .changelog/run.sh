#!/bin/bash
set -euxo pipefail

PROJECTS=(
  "project-ghrp-npm"
)

run(){

  ./.changelog/git-cliff.sh ${1}/CHANGELOG/cliff.env

  if ./.changelog/has-changed.sh ${1}/CHANGELOG/cliff.env; then
    echo "Changes detected after generating the changelog."
  else
    echo "No changes detected after generating the changelog."
  fi
}

# If the first argument is "all", then generate the changelog for all projects
if [ "$1" == "all" ]; then
  for project in "${PROJECTS[@]}"; do
    run $project
  done
  exit 0
# If the first argument is not empty, then generate the changelog for the specified project
  else
    # If the directory does not exist, then exit
    if [ ! -d "$1" ]; then
      echo "Directory '$1' does not exist."
      exit 1
    fi
    run $1
    exit 0
fi
