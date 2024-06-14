#!/bin/bash
set -euxo pipefail

if [ "$1" == "all" ]; then
  ./.changelog/git-cliff.sh project-ghrp-npm/CHANGELOG/cliff.env
fi
