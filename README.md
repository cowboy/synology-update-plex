# synology-update-plex
> Script to Auto Update Plex Media Server on Synology NAS

[![Latest Release](https://img.shields.io/github/v/release/cowboy/synology-update-plex)][release]
[![Test](https://github.com/cowboy/synology-update-plex/workflows/Test/badge.svg)][test-master]
[![Donate](https://img.shields.io/badge/Support%20this%20project!-$5-success)][donate]

## Goals

- Make the echoed messages super clear
- Make the version checking logic as smart as possible
- Ensure the script fails if there are any errors
- Ensure temp files are cleaned up properly
- Write bash code as idiomatically as possible
- Attempt to find the "Plex Media Server" directory that contains Preferences.xml efficiently
- Attempt to support all Synology NAS architectures

## Usage

First, SSH into your NAS, save the [latest release][release] update-plex.sh script somewhere and set it as executable:

```sh
$ ssh you@IP_OF_YOUR_NAS
you@yournas:~$ wget "https://github.com/cowboy/synology-update-plex/releases/latest/download/update-plex.sh"
you@yournas:~$ chmod a+x update-plex.sh
```

Then, create a Scheduled Task with a User-defined script in the Synology DSM Control Panel:
- Ensure the User is `root`
- Ensure the Run command is `/path/to/update-plex.sh`
- Add the `--plex-pass` option (eg. `/path/to/update-plex.sh --plex-pass`) if you have Plex Pass and want to enable early access / beta releases
- Add the `--update-chromecast` if you want to update the Chromecast profile to be able to directly stream without transcoding newer codecs like H.265, EAC3, etc. to Chromecast devices (see [ambroisemaupate's Github](https://github.com/ambroisemaupate/plex-profiles))

## Caveats

[donate]: https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RRUNYDUYBAH58&source=url
[test-master]: https://github.com/cowboy/synology-update-plex/actions?query=workflow%3ATest+branch%3Amaster
[release]: https://github.com/cowboy/synology-update-plex/releases/latest
[issue]: https://github.com/cowboy/synology-update-plex/issues
[pr]: https://github.com/cowboy/synology-update-plex/pulls

- Be careful when SSHing into your NAS. I'm not responsible if you break anything!
- This script may contain bugs. I'm not responsible if it breaks anything!
- This script has been tested on a Synology DS918+ NAS. It should work with other Synology NAS models.
- This script assumes Plex was installed manually from https://www.plex.tv/media-server-downloads/.

## Common Issues

- If the script is trying to download the wrong release file for your NAS, please see the comments at the top of the [get_arch](/test/get_arch.bats) test suite.
- If the script fails with `Unable to find "Plex Media Server" directory` when `--plex-pass` is specified, you may need to manually change `/volume*` in the script to your volume's root path.
- If the script fails with `error = [289]` while installing package, [add Plex as a trusted publisher for package installations](https://support.plex.tv/hc/en-us/articles/205165858).

If you find a bug or an issue not listed here, please [file an issue][issue] or [create a pull request][pr]. Explain the situation and include all script output.


## References

Adapted from work first published at:
- https://forums.plex.tv/t/script-to-auto-update-plex-on-synology-nas-rev4/479748

Including other update scripts such as:
- https://github.com/martinorob/plexupdate
- https://github.com/nitantsoni/plexupdate
- https://gist.github.com/seanhamlin/dcde16a164377dca87a798a4c2ea051c
- https://forums.plex.tv/t/script-to-auto-update-plex-on-synology-nas-rev4/479748/67

## License

[![CC0](http://mirrors.creativecommons.org/presskit/buttons/88x31/svg/cc-zero.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

To the extent possible under law, Ben Alman has waived all copyright and related or neighboring rights to this work.
