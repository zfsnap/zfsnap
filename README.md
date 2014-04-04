# WARNING

Master is currently very unstable.
You should use zfSnap from legacy branch instead.

# About zfsnap

zfsnap makes rolling ZFS snapshots easy, and is designed to work with cron.

The main advantages of zfsnap are its portability, simplicity, and performance.
It is written purely in /bin/sh and does not require any additional software
other than typical *nix utilies.

zfsnap also stores all the information about a snapshot in the snapshot name.
No special ZFS properties are needed. This is done in a way that is human readable,
making it much easier for a sysadmin to manage and audit backup schedules.

zfsnap snapshot names are in the format of Timestamp--TimeToLive.

Timestamp includes the date and time when the snapshot was created and
TimeToLive (TTL) is the amount of time for the snapshot to stay alive before
it's ready for deletion.

See https://github.com/zfsnap/zfsnap/wiki for more info

# Will zfsnap run on my system?

Currently zfsnap supports FreeBSD, Solaris, Linux, GNU/kFreeBSD, and OS X.
zfsnap is written with portability in mind, and should run on your system as long as:
- your Bourne shell supports variables defined with "local"
- your `date` command supports converting dates (GNU's '--date' flag or BSD's '-j' '-f' flags)

zfsnap should also work on illumos and other Solaris forks, but is untested as
far as we're aware.
