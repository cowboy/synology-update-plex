# synology-update-plex
> Script to Auto Update Plex Media Server on Synology NAS

## Goals

- ensure temp files are cleaned up properly
- make sure the script fails if there are any errors
- make the echoed messages super clear
- write bash code as idiomatically as possible
- make the version checking logic as smart as possible
- attempt to find the "Plex Media Server" directory that contains Preferences.xml efficiently

## Usage

First, save the `update-plex.sh` script somewhere and set is as executable:

```sh
$ ssh IP_OF_YOUR_NAS
you@yournas:~$ wget ___
you@yournas:~$ chmod a+x ___
```

Then, create a Scheduled Task with a User-defined script in the Synology DSM Control Panel:
- Ensure the User is `root`
- Ensure the Run command is the `/path/to/plex-update.sh`

## Notes

If you have Plex Pass and want to enable beta releases, uncomment the `release_mode=beta` line.

## References

This work wouldn't have been possible without all the other scripts I had found, such as
- https://github.com/martinorob/plexupdate
- https://github.com/nitantsoni/plexupdate
- https://gist.github.com/seanhamlin/dcde16a164377dca87a798a4c2ea051c

See discussion at
- https://forums.plex.tv/t/script-to-auto-update-plex-on-synology-nas-rev4/479748
