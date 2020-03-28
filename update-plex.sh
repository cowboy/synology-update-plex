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

# Set release_channel=plexpass to enable beta releases
release_channel=

function fail() {
  echo "FAIL: $@"
  exit 1
}

echo 'Checking for a Plex Media Server update...'

if [[ $EUID -ne 0 ]]; then
  fail 'This script must be run as root.'
fi

current_version=$(synopkg version 'Plex Media Server')
echo "Current version: $current_version"

downloads_url="https://plex.tv/api/downloads/5.json"
if [[ "$release_channel" == plexpass ]]; then
  pms_dir="$(find / -path '*/@appstore' -prune -o -path '*/Plex Media Server' -print -quit)"
  if [[ ! -d "$pms_dir" ]]; then
    fail 'Unable to find "Plex Media Server" directory.'
  fi
  prefs_file="$pms_dir/Preferences.xml"
  if [[ ! -e "$prefs_file" ]]; then
    fail 'Unable to find Plex Media Server Preferences.xml file.'
  fi
  token=$(grep -oP 'PlexOnlineToken="\K[^"]+' "$prefs_file" || true)
  if [[ -z "$token" ]]; then
    fail 'Unable to detect PlexOnlineToken in Preferences.xml.'
  fi
  downloads_url="$downloads_url?channel=plexpass&X-Plex-Token=$token"
fi

downloads_json="$(curl -s "$downloads_url")"

new_version=$(jq -r .nas.Synology.version <<< "$downloads_json")
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
installer_url="$(jq -r '.nas.Synology.releases[] | select(.build == "linux-'$machine'").url' <<< "$downloads_json")"
if [[ -z "$installer_url" ]]; then
  fail "Unable to find installer URL for $machine."
fi
wget "$installer_url" -P $tmp_dir

echo 'Installing new version...'
synopkg install $tmp_dir/*.spk

echo 'Restarting Plex Media Server...'
synopkg start 'Plex Media Server'

echo 'Done!'
