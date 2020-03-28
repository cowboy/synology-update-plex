#!/usr/bin/env bash

# Script to Auto Update Plex Media Server on Synology NAS
#
# "Cowboy" Ben Alman
# Last updated on 3/28/20
#
# Download latest version from
# https://github.com/cowboy/synology-update-plex

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

echo 'Checking for a Plex Media Server update...'

if [[ $EUID -ne 0 ]]; then
  echo 'This script must be run as root. Aborting!'
  exit 1
fi

current_version=$(synopkg version 'Plex Media Server')
echo "Current version: $current_version"

release_mode=official
# release_mode=beta

releases_url="https://plex.tv/api/downloads/5.json"
if [[ "$release_mode" == "beta" ]]; then
  pms_dir="$(find / -path '*/@appstore' -prune -o -path '*/Plex Media Server' -print -quit)"
  token=$(grep -oP 'PlexOnlineToken="\K[^"]+' "$pms_dir/Preferences.xml" || true)
  if [[ -z "$token" ]]; then
    echo 'Unable to find PlexOnlineToken. Aborting!'
    exit 1
  fi
  releases_url="$releases_url?channel=plexpass&X-Plex-Token=$token"
fi

releases_json="$(curl -s "$releases_url")"

new_version=$(jq -r .nas.Synology.version <<< "$releases_json")
echo "New version: $new_version"

# https://stackoverflow.com/a/4024263
function version_lte() {
  [[ "$1" == "$(echo -e "$1\n$2" | sort -V | head -n1)" ]]
}

if version_lte $new_version $current_version; then
  echo 'Plex is up-to-date, exiting!'
  exit
fi

echo 'New version available!'
synonotify PKGHasUpgrade '{"[%HOSTNAME%]": $(hostname), "[%OSNAME%]": "Synology", "[%PKG_HAS_UPDATE%]": "Plex", "[%COMPANY_NAME%]": "Synology"}'

tmp_dir=$(mktemp -d)
function cleanup() {
  rm -rf $tmp_dir
}
trap cleanup EXIT

echo 'Downloading new version...'
machine=$(uname -m)
installer_url="$(jq -r '.nas.Synology.releases[] | select(.build == "linux-'$machine'").url' <<< "$releases_json")"
if [[ -z "$installer_url" ]]; then
  echo "Unable to find installer URL for $machine. Aborting!"
  exit 1
fi
wget "$installer_url" -P $tmp_dir

echo 'Installing new version...'
synopkg install $tmp_dir/*.spk

echo 'Restarting Plex Media Server...'
synopkg start 'Plex Media Server'

echo 'Done!'
