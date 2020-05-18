#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

RELEASE_ID=$(jq --raw-output '.release.id' "$GITHUB_EVENT_PATH")

mkdir build
sed "s/(in-development)/$RELEASE_ID/" update-plex.sh > build/update-plex.sh
