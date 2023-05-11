#!/usr/bin/env bash

script_args=("$@")
script_version='(in-development)' # auto-generated during release

function help() { cat <<HELP
Auto Update Plex Media Server on Synology NAS
Version $script_version

Download latest release from
https://github.com/cowboy/synology-update-plex/releases

Adapted from work first published at
https://forums.plex.tv/t/script-to-auto-update-plex-on-synology-nas-rev4/479748

Usage: $(basename "$0") [options...]

Options:
  --plex-pass  Enable early access / beta releases (requires Plex Pass)
  --version    Display the script release version
  --help       Display this help message
HELP
}

function header() { echo -e "\n[ $@ ]"; }
function warn() { echo "WARN: $@" >&2; }
function fail() { fail_reason="$@"; echo "FAIL: $@"; exit 1; }

function process_args() {
  while [[ "${1-}" ]]; do
    case $1 in
      -h|-\?|--help)
        help
        exit
        ;;
      -v|--version)
        echo "$script_version"
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
}

function dump_vars() {
  vars=(
    script_args
    script_version
    plex_pass
    pms_dir
    dsm_major_version
    available_version
    installed_version
    tmp_dir
    package_file
    debug_json
  )
  header 'Debugging info'
  for var in "${vars[@]}"; do
    (set -o posix ; set | grep ${var}= || true)
  done
  echo
}

function cleanup() {
  code=$?
  if [[ -d "${tmp_dir-}" ]]; then
    header 'Cleaning up'
    echo "Removing $tmp_dir"
    rm -rf $tmp_dir
  fi
  if [[ $code == 0 ]]; then
    echo
    echo 'Done!'
  else
    notify_failure
    dump_vars
    echo 'Done, with errors!'
    echo
    echo 'If this problem persists, please file an issue here, and include the output from this script:'
    echo 'https://github.com/cowboy/synology-update-plex/issues'
  fi
}

function notify() {
  local json= tag_event=PkgMgr_$1
  set -- PKG_NAME "Plex Media Server" "${@:2}"
  while [[ "${1-}" ]]; do
    [[ -n "$json" ]] && json="$json,"
    json="$json\"%$1%\":\"${2//\"/\\\"}\""
    shift 2
  done
  synonotify $tag_event "{$json}"
}

function notify_success() {
  notify UpgradedPkg PKG_VERSION "${available_version:-(unknown)}"
}

function notify_failure() {
  notify UpgradePkgFail FAILED_REASON "${fail_reason-}"
}

function retrieve_dsm_version() {
  header "Retrieving DSM version"
  dsm_major_version=$(awk -F "=" '/majorversion/ {print $2}' /etc.defaults/VERSION | tr -d '"')
  if [[ "7" -eq "$dsm_major_version" ]]; then
    json_dsm_pattern="Synology (DSM 7)"
    pms_package_name="PlexMediaServer"
    echo "Found DSM version 7"
  else
    json_dsm_pattern="Synology"
    pms_package_name="Plex Media Server"
    echo "Found DSM version <6"
  fi
}

function build_downloads_url() {
  downloads_url='https://plex.tv/api/downloads/5.json'

  if [[ "${plex_pass-}" ]]; then
    header "Enabling Plex Pass releases"

    if [ "$pms_package_name" = "PlexMediaServer" ]; then
    	pms_dir='/var/packages/PlexMediaServer/home/Plex Media Server'
    else
    	pms_dir="$(echo /volume*"/Plex/Library/Application Support/Plex Media Server")"
    fi
    if [[ ! -d "$pms_dir" ]]; then
      pms_dir="$(find /volume* -type d -name 'Plex Media Server' -execdir test -e "{}/Preferences.xml" \; -print -quit)"
    fi

    if [[ ! -d "$pms_dir" ]]; then
      fail 'Unable to find "Plex Media Server" directory'
    fi

    local prefs_file="$pms_dir/Preferences.xml"
    if [[ ! -e "$prefs_file" ]]; then
      fail 'Unable to find Preferences.xml file'
    fi

    local token=$(grep -oP 'PlexOnlineToken="\K[^"]+' "$prefs_file" || true)
    if [[ -z "$token" ]]; then
      fail 'Unable to find Plex Token'
    fi

    echo "Found Plex Token"
    downloads_url="$downloads_url?channel=plexpass&X-Plex-Token=$token"
  fi
}

function retrieve_version_data() {
  header 'Retrieving version data'
  downloads_json="$(curl -s "$downloads_url")"
  if [[ -z "$downloads_json" ]]; then
    fail 'Unable to retrieve version data'
  fi
}

function set_available_version() {
  available_version=$(jq -r '.nas["'"$json_dsm_pattern"'"].version' <<< "$downloads_json")
  if [[ "$available_version" == null ]]; then
    debug_json="$downloads_json"
    fail 'Unable to retrieve version data'
  fi
  echo "Available version: $available_version"
}

function set_installed_version() {
  installed_version=$(synopkg version "$pms_package_name")
  echo "Installed version: $installed_version"
}

# https://stackoverflow.com/a/4024263
function version_lte() {
  [[ "$1" == "$(echo -e "$1\n$2" | sort -V | head -n1)" ]]
}

function check_up_to_date() {
  set_available_version
  set_installed_version
  
  local available_version_no_build=${available_version/%-*}
  local installed_version_no_build=${installed_version/%-*}

  echo
  if version_lte "$available_version_no_build" "$installed_version_no_build"; then
    if [[ "$installed_version_no_build" != "$available_version_no_build" ]]; then
      echo 'The installed version of Plex is newer than the available version. If' \
        'you have Plex Pass, be sure to run this script with the --plex-pass option.'
    fi
    echo 'Plex is up-to-date.'
    exit
  fi

  echo 'New version available!'
}

function get_arch() {
  local arch machine=$1 hw_version=$2
  if [[ "$machine" =~ armv7 ]]; then
    declare -A model_machine_map
    model_machine_map[DS414j]=armv7hf_neon
    model_machine_map[DS115j]=armv7hf
    model_machine_map[RS815]=armv7hf
    model_machine_map[DS216se]=armv7hf
    model_machine_map[DS215jv10-j]=armv7hf_neon
    if [[ "${model_machine_map[$hw_version]+_}" ]]; then
      arch=${model_machine_map[$hw_version]}
    elif [[ "${hw_version//[^0-9]/}" =~ 1[5-8]$ ]]; then
      arch=armv7hf_neon
    else
      arch=armv7hf
    fi
  elif [[ "$machine" =~ i686 ]]; then
    arch=x86
  else
    arch=$machine
  fi
  echo $arch
}

function find_release() {
  header 'Finding release'
  local hw_version=$(</proc/sys/kernel/syno_hw_version)
  local machine=$(uname -m)
  local arch=$(get_arch "$machine" "$hw_version")
  release_json="$(jq '.nas["'"$json_dsm_pattern"'"].releases[] | select(.build == "linux-'$arch'")' <<< "$downloads_json")"
  if [[ -z "$release_json" ]]; then
    debug_json="$downloads_json"
    fail "Unable to find release for $hw_version/$machine/$arch"
  fi
}

function download_package() {
  header 'Downloading release package'
  local package_url="$(jq -r .url <<< "$release_json")"
  tmp_dir=$(mktemp -d --tmpdir plex.XXXXXX)
  wget --no-verbose "$package_url" -P $tmp_dir

  package_file=$(echo $tmp_dir/*.spk)
  if [[ ! -e "$package_file" ]]; then
    fail "Unable to download package file"
  fi
}

function verify_checksum() {
  header 'Verifying checksum'
  local expected_checksum="$(jq -r .checksum <<< "$release_json")"
  local actual_checksum=$(sha1sum $package_file | cut -f1 -d' ')
  if [[ "$actual_checksum" != "$expected_checksum" ]]; then
    fail "Checksum $actual_checksum invalid"
  fi
  echo "Checksum valid!"
}

function install_package() {
  header 'Installing package'
  synopkg install $package_file
}

function restart_plex() {
  header 'Restarting Plex Media Server'
  synopkg start "$pms_package_name"
}

function main() {
  set -o errexit
  set -o pipefail
  set -o nounset
  # set -o xtrace

  shopt -s nullglob

  process_args "$@"

  trap cleanup EXIT

  echo 'Checking for a Plex Media Server update...'

  if [[ $EUID != 0 ]]; then
    fail 'This script must be run as root'
  fi

  retrieve_dsm_version

  build_downloads_url
  retrieve_version_data

  check_up_to_date

  find_release
  echo "$release_json"

  download_package
  verify_checksum

  install_package
  restart_plex

  notify_success
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
