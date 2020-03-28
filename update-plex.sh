#!/usr/bin/env bash

# Script to Auto Update Plex Media Server on Synology NAS
#
# "Cowboy" Ben Alman
# Last updated on 3/28/20
#
# Download latest version from
# https://github.com/cowboy/synology-update-plex
#
# Adapted from work first published at
# https://forums.plex.tv/t/script-to-auto-update-plex-on-synology-nas-rev4/479748

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

shopt -s nullglob

# Set release_channel=plexpass to enable beta releases
release_channel=

function fail() {
  echo "FAIL: $@"
  exit 1
}

echo 'Checking for a Plex Media Server update...'

[[ $EUID -ne 0 ]] && fail 'This script must be run as root.'

current_version=$(synopkg version 'Plex Media Server')
echo "Current version: $current_version"

downloads_url="https://plex.tv/api/downloads/5.json"

if [[ "$release_channel" == plexpass ]]; then
  pms_dir="$(find / -path '*/@appstore' -prune -o -path '*/Plex Media Server' -print -quit)"
  [[ ! -d "$pms_dir" ]] && fail 'Unable to find "Plex Media Server" directory.'

  prefs_file="$pms_dir/Preferences.xml"
  [[ ! -e "$prefs_file" ]] && fail 'Unable to find Preferences.xml file.'

  token=$(grep -oP 'PlexOnlineToken="\K[^"]+' "$prefs_file" || true)
  [[ -z "$token" ]] && fail 'Unable to find Plex Token.'

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

echo 'Finding release...'
machine=$(uname -m)
release_json="$(jq '.nas.Synology.releases[] | select(.build == "linux-'$machine'")' <<< "$downloads_json")"
[[ -z "$release_json" ]] && fail "Unable to find $machine release."

echo 'Downloading release package...'
package_url="$(jq -r .url <<< "$release_json")"
wget "$package_url" -P $tmp_dir

package_file=$(echo $tmp_dir/*.spk)
[[ ! -e "$package_file" ]] && fail "Unable to download package file from $package_url."

echo 'Verifying checksum...'
expected_checksum="$(jq -r .checksum <<< "$release_json")"
actual_checksum=$(sha1sum $package_file | cut -f1 -d' ')
[[ "$actual_checksum" != "$expected_checksum" ]] && \
  fail "Checksum mismatch for $(basename $package_file). Expected $expected_checksum, got $actual_checksum."

echo 'Installing package...'
synopkg install $package_file

echo 'Restarting Plex Media Server...'
synopkg start 'Plex Media Server'

echo 'Done!'
