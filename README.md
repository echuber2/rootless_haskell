# rootless_haskell
_install Haskell on EWS without root permissions_

This is a temporary stopgap measure for installing Haskell (with Stack) on Illinois EWS user accounts.

## About
Benefits:
- You get to do your homework on EWS.

Caveats:

- Slow. This will take 30-60 minutes to install on EWS.
- Big. It uses over 2 GB of your storage quota.
- Probably deprecated soon. Hopefully there will be an official Haskell module available on the server.

This script downloads and builds the GMP library from source, but jury-rigs the resulting files with a few that do exist on the server for compatibility, using symlinks.

Then it downloads and installs Stack binaries, and Stack installs GHC binaries. Several tweaks have been made to make sure these installers use the correct library files.

## Checklist
Before installation:
- _Read_ the script to see what it does.
- Back up any crucial files in your EWS home directory to an external location.

Installation:
- Put the script in your home directory (`cd ~`) and then run it (`sh ./install_rootless_haskell.sh`)

After installation:
- Every terminal session, it's necessary to type `source ~/rootless_haskell.rc` to get started.
- The first time a `stack test` is run in a project directory, a bunch of packages will download and build... it won't take so long after that.

If you aren't using an EWS terminal this script is probably useless to you.

## Troubleshooting
If you are trying to do this over SSH, and you probably shouldn't, then you may get disconnected during the install which will ruin everything. One thing you _could_ do is press ctrl-Z after the install begins, which pauses the process, and then type `bg && disown`. That will let the installer keep running (invisibly) apart from your terminal session. If it goes crazy for some reason, you'd have to hunt down and kill it with ``ps aux | grep `whoami` | grep install`` and then `kill` the PID.

## Uninstallation
You can remove this version of Haskell from your home directory like this:
```
cd ~
rm -rf .stack stack .gmp
```
Be careful!

***

Script by Eric Huber based on a script by Yury Antonov:
https://github.com/yantonov/install-ghc/blob/master/ubuntu/install-ghc-ubuntu.md
