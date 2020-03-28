# synology-update-plex
> Script to Auto Update Plex Media Server on Synology NAS

## Goals

- Make the echoed messages super clear
- Make the version checking logic as smart as possible
- Ensure the script fails if there are any errors
- Ensure temp files are cleaned up properly
- Write bash code as idiomatically as possible
- Attempt to find the "Plex Media Server" directory that contains Preferences.xml efficiently
- Attempt to support all Synology NAS architectures

## Usage

First, SSH into your NAS, save the [update-plex.sh](update-plex.sh) script somewhere and set it as executable:

```sh
$ ssh you@IP_OF_YOUR_NAS
you@yournas:~$ wget "https://raw.githubusercontent.com/cowboy/synology-update-plex/master/update-plex.sh"
you@yournas:~$ chmod a+x update-plex.sh
```

Then, create a Scheduled Task with a User-defined script in the Synology DSM Control Panel:
- Ensure the User is `root`
- Ensure the Run command is `/path/to/plex-update.sh`

## Notes

- Be careful when SSHing into your NAS. I'm not responsible if you break anything!
- This was tested on a Synology DS918+ NAS. It should work with other Synology NAS models. If it doesn't, please file an issue or PR.
- This assumes Plex was installed manually from https://www.plex.tv/media-server-downloads/.
- You'll probably need to [add Plex as a trusted publisher for package installations](https://support.plex.tv/hc/en-us/articles/205165858).
- If you have Plex Pass and want to enable beta releases, uncomment the `release_mode=beta` line.

## References

This work wouldn't have been possible without all the other scripts I had found, such as:
- https://github.com/martinorob/plexupdate
- https://github.com/nitantsoni/plexupdate
- https://gist.github.com/seanhamlin/dcde16a164377dca87a798a4c2ea051c
- https://forums.plex.tv/t/script-to-auto-update-plex-on-synology-nas-rev4/479748/67

And the healthy collaborative discussion in the Plex forums:
- https://forums.plex.tv/t/script-to-auto-update-plex-on-synology-nas-rev4/479748

## License

[![CC0](http://mirrors.creativecommons.org/presskit/buttons/88x31/svg/cc-zero.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

To the extent possible under law, Ben Alman has waived all copyright and related or neighboring rights to this work.
