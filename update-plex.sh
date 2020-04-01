#!/usr/bin/env bash

# Script to Auto Update Plex Media Server on Synology NAS
#
# "Cowboy" Ben Alman
# Last updated on 2020-03-30
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

# Set release_channel=plexpass to enable early access / beta releases
release_channel=

tmp_dir=
function cleanup() {
  code=$?
  echo ""
  if [[ -d "$tmp_dir" ]]; then
    echo 'Cleaning up temp files'
    rm -rf $tmp_dir
  fi
  if [[ $code == 0 ]]; then
    echo 'Done!'
  else
    echo 'Done, with errors!'
  fi
}
trap cleanup EXIT

function header() { echo -e "\n[ $@ ]"; }
function fail() { echo "FAIL: $@"; exit 1; }

echo 'Checking for a Plex Media Server update...'

if [[ $EUID != 0 ]]; then
  fail 'This script must be run as root'
fi

downloads_url="https://plex.tv/api/downloads/5.json"

if [[ "$release_channel" == plexpass ]]; then
  header "Using plexpass release channel"

  pms_dir="$(find / -path '*/@appstore' -prune -o -path '*/Plex Media Server' -print -quit)"
  if [[ ! -d "$pms_dir" ]]; then
    fail 'Unable to find "Plex Media Server" directory'
  fi

  prefs_file="$pms_dir/Preferences.xml"
  if [[ ! -e "$prefs_file" ]]; then
    fail 'Unable to find Preferences.xml file'
  fi

  token=$(grep -oP 'PlexOnlineToken="\K[^"]+' "$prefs_file" || true)
  if [[ -z "$token" ]]; then
    fail 'Unable to find Plex Token'
  fi

  echo "Found Plex Token"
  downloads_url="$downloads_url?channel=plexpass&X-Plex-Token=$token"
fi

header 'Retrieving version data'
downloads_json="$(curl -s "$downloads_url")"
if [[ -z "$downloads_json" ]]; then
  fail 'Unable to retrieve version data'
fi

latest_version=$(jq -r .nas.Synology.version <<< "$downloads_json")
echo "LATEST VERSION: $latest_version"

current_version=$(synopkg version 'Plex Media Server')
echo "CURRENT VERSION: $current_version"

# https://stackoverflow.com/a/4024263
function version_lte() {
  [[ "$1" == "$(echo -e "$1\n$2" | sort -V | head -n1)" ]]
}

if version_lte $latest_version $current_version; then
  echo 'Plex is up-to-date.'
  exit
fi

echo 'New version available!'
synonotify PKGHasUpgrade '{"[%HOSTNAME%]": $(hostname), "[%OSNAME%]": "Synology", "[%PKG_HAS_UPDATE%]": "Plex", "[%COMPANY_NAME%]": "Synology"}'

header 'Finding release'
hw_version=$(</proc/sys/kernel/syno_hw_version)
machine=$(uname -m)

# The following armv7 logic was derived from:
# jq -r '.nas.Synology.releases[] | select(.label | contains("ARMv7"))' <<< "$downloads_json"
#
# linux-armv7hf
#   ARMv7 (x13 Series, x14 Series (excluding DS414j), DS115j, RS815, and DS216se)
# linux-armv7hf_neon
#   ARMv7 (x15 Series (excluding DS115j and RS815), x16 Series (excluding DS216se), x17 Series, x18 Series, and DS414j)

if [[ "$machine" =~ armv7 ]]; then
  declare -A model_machine_map
  model_machine_map[DS414j]=armv7hf_neon
  model_machine_map[DS115j]=armv7hf
  model_machine_map[RS815]=armv7hf
  model_machine_map[DS216se]=armv7hf
  if [[ "${model_machine_map[$hw_version]+_}" ]]; then
    arch=${model_machine_map[$hw_version]}
  elif [[ "${hw_version//[^0-9]/}" =~ 1[5-8]$ ]]; then
    arch=armv7hf_neon
  else
    arch=armv7hf
  fi
else
  arch=$machine
fi

release_json="$(jq '.nas.Synology.releases[] | select(.build == "linux-'$arch'")' <<< "$downloads_json")"
if [[ -z "$release_json" ]]; then
  fail "Unable to find release for $hw_version/$machine/$arch"
fi
echo "$release_json"

header 'Downloading release package'
package_url="$(jq -r .url <<< "$release_json")"
tmp_dir=$(mktemp -d)
wget --no-verbose "$package_url" -P $tmp_dir

package_file=$(echo $tmp_dir/*.spk)
if [[ ! -e "$package_file" ]]; then
  fail "Unable to download package file"
fi

header 'Verifying checksum'
expected_checksum="$(jq -r .checksum <<< "$release_json")"
actual_checksum=$(sha1sum $package_file | cut -f1 -d' ')
if [[ "$actual_checksum" != "$expected_checksum" ]]; then
  fail "Checksum $actual_checksum invalid"
fi
echo "Checksum valid!"

header 'Installing package'
synopkg install $package_file

header 'Restarting Plex Media Server'
synopkg start 'Plex Media Server'
