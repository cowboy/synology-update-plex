#!/usr/bin/env bash

# Plex service auto-restart script
#
# Based on
# https://www.reddit.com/r/synology/comments/op7smc/comment/iq4096i/
#
# Tested in DSM 7.1.1, YMMV

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

port=32400

echo "Checking if Plex is running on port $port."

if netstat -tnlp | grep :$port >/dev/null; then
  echo "Plex is running."
  exit 0
fi

echo 'Plex is not running, attempting to restart.'
echo
echo 'Last 20 log entries:'
echo '--------------------'
tail -20 '/volume1/PlexMediaServer/AppData/Plex Media Server/Logs/Plex Media Server.log'
echo '--------------------'
echo
echo 'Ensuring Plex service is stopped...'
synopkg stop PlexMediaServer
echo
echo 'Starting Plex service...'
synopkg start PlexMediaServer
echo
echo 'Done.'
exit 1
