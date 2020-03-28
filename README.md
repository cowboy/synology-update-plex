# synology-update-plex
> Script to Auto Update Plex Media Server on Synology NAS

## Goals

- make the echoed messages super clear
- make the version checking logic as smart as possible
- make sure the script fails if there are any errors
- ensure temp files are cleaned up properly
- write bash code as idiomatically as possible
- attempt to find the "Plex Media Server" directory that contains Preferences.xml efficiently
- attempt to support all NAS architectures

## Usage

First, SSH into your NAS, save the `update-plex.sh` script somewhere and set it as executable:

```sh
$ ssh IP_OF_YOUR_NAS
you@yournas:~$ wget "https://raw.githubusercontent.com/cowboy/synology-update-plex/master/update-plex.sh"
you@yournas:~$ chmod a+x plex-update.sh
```

Then, create a Scheduled Task with a User-defined script in the Synology DSM Control Panel:
- Ensure the User is `root`
- Ensure the Run command is the `/path/to/plex-update.sh`

## Notes

- Be careful when SSHing into your NAS. I'm not responsible if you break anything!
- If you have Plex Pass and want to enable beta releases, uncomment the `release_mode=beta` line.

## References

This work wouldn't have been possible without all the other scripts I had found, such as
- https://github.com/martinorob/plexupdate
- https://github.com/nitantsoni/plexupdate
- https://gist.github.com/seanhamlin/dcde16a164377dca87a798a4c2ea051c

See discussion at
- https://forums.plex.tv/t/script-to-auto-update-plex-on-synology-nas-rev4/479748

## License

[![CC0](http://mirrors.creativecommons.org/presskit/buttons/88x31/svg/cc-zero.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

To the extent possible under law, Ben Alman has waived all copyright and related or neighboring rights to this work.
