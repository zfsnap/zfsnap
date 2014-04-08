# WARNING

Master is currently very unstable.
You should use zfSnap from legacy branch instead.

# About zfsnap

zfsnap makes rolling ZFS snapshots easy and — with cron — automatic.

The main advantages of zfsnap are its portability, simplicity, and performance.
It is written purely in /bin/sh and does not require any additional software —
other than typical *nix utilies.

zfsnap stores all the information it needs about a snapshot directly in its name;
no database or special ZFS properties are needed. The information is stored in
a way that is human readable, making it much easier for a sysadmin to manage
and audit backup schedules.

Snapshot names are in the format of Timestamp--TimeToLive (e.g.
pool/fs@2014-04-07_05.30.00--6m). Timestamp is the date and time when the
snapshot was created, and TimeToLive (TTL) is the amount of time the snapshot
will be kept until it is deleted.

See https://github.com/zfsnap/zfsnap/wiki for more info

# Will zfsnap run on my system?

zfsnap is written with portability in mind, and our aim is for it to run on
any and every OS that supports ZFS.

Currently, zfsnap supports FreeBSD, Solaris, Linux, GNU/kFreeBSD, and OS X.
It should run on your system as long as:
- your Bourne shell (/bin/sh) supports "local" variables (all modern systems should)
- your system uses the Gregorian calendar

zfsnap should also work on illumos and other Solaris forks, but is untested as
far as we're aware.
