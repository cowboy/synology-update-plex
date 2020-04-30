#!/usr/bin/env bash

function help() { cat <<HELP
Auto Update Plex Media Server on Synology NAS

"Cowboy" Ben Alman
Last updated on 2020-04-29

Download latest version from
https://github.com/cowboy/synology-update-plex

Adapted from work first published at
https://forums.plex.tv/t/script-to-auto-update-plex-on-synology-nas-rev4/479748

Usage: $(basename "$0") [options...]

Options:
  --plex-pass  Enable early access / beta releases (requires Plex Pass)
  --help       Display this help message
HELP
}

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

shopt -s nullglob

function header() { echo -e "\n[ $@ ]"; }
function warn() { echo "WARN: $@" >&2; }
function fail() { echo "FAIL: $@"; exit 1; }

plex_pass=
while [[ "${1-}" ]]; do
  case $1 in
    -h|-\?|--help)
      help
      exit
      ;;
    --plex-pass)
      plex_pass=1
      ;;
    *)
      warn "Unknown option (ignored): $1"
      ;;
  esac
  shift
done

tmp_dir=
function cleanup() {
  code=$?
  if [[ -d "$tmp_dir" ]]; then
    header 'Cleaning up'
    echo "Removing $tmp_dir"
    rm -rf $tmp_dir
  fi
  echo
  if [[ $code == 0 ]]; then
    echo 'Done!'
  else
    notify PlexUpdateError
    echo 'Done, with errors!'
  fi
}
trap cleanup EXIT

function notify() {
  synonotify $1 '{"%PLEX_VERSION%":"'${available_version:-(unknown)}'"}'
}

function init_notifications() {
  lang="$(source /etc/synoinfo.conf; echo "$maillang")"
  mails_file=/var/cache/texts/$lang/mails
  if [[ ! -e "$mails_file" ]]; then
    header "Initializing notification system"
    echo "Notifications disabled (file $mails_file not found)"
    return
  fi
  if [[ ! "$(grep PlexUpdateInstalled $mails_file || true)" ]]; then
    header "Initializing notification system"
    cp $mails_file $mails_file.bak
    cat << 'EOF' >> $mails_file

[PlexUpdateInstalled]
Subject: Successfully updated Plex to %PLEX_VERSION% on %HOSTNAME%

Dear user,

Successfully updated Plex to %PLEX_VERSION% on %HOSTNAME%

---
https://github.com/cowboy/synology-update-plex


[PlexUpdateError]
Subject: Unable to update Plex to %PLEX_VERSION% on %HOSTNAME%

Dear user,

Unable to update Plex to %PLEX_VERSION% on %HOSTNAME%.

If this error persists, enable saving output results in Task Scheduler and file an issue at https://github.com/cowboy/synology-update-plex/issues including the script output.

---
https://github.com/cowboy/synology-update-plex

EOF
    echo 'Notifications installed'
  fi
}

echo 'Checking for a Plex Media Server update...'

if [[ $EUID != 0 ]]; then
  fail 'This script must be run as root'
fi

init_notifications

downloads_url='https://plex.tv/api/downloads/5.json'

if [[ "$plex_pass" ]]; then
  header "Enabling Plex Pass releases"

  pms_dir="$(echo /volume*"/Plex/Library/Application Support/Plex Media Server")"
  if [[ ! -d "$pms_dir" ]]; then
    pms_dir="$(find /volume* -type d -name 'Plex Media Server' -execdir test -e "{}/Preferences.xml" \; -print -quit)"
  fi

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

available_version=$(jq -r .nas.Synology.version <<< "$downloads_json")
echo "Available version: $available_version"

installed_version=$(synopkg version 'Plex Media Server')
echo "Installed version: $installed_version"

# https://stackoverflow.com/a/4024263
function version_lte() {
  [[ "$1" == "$(echo -e "$1\n$2" | sort -V | head -n1)" ]]
}

echo
if version_lte $available_version $installed_version; then
  if [[ "$installed_version" != "$available_version" ]]; then
    echo 'The installed version of Plex is newer than the available version. If' \
      'you have Plex Pass, be sure to run this script with the --plex-pass option.'
  fi
  echo 'Plex is up-to-date.'
  exit
fi

echo 'New version available!'

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
tmp_dir=$(mktemp -d --tmpdir plex.XXXXXX)
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

notify PlexUpdateInstalled
