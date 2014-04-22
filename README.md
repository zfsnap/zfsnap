# WARNING

This branch contains the new 2.0.0 code-base which is now in beta. While
2.0.0 is a big improvement, it has not yet been as widely tested on production
systems as the zfSnap 1.x line.

Testing is most welcome, but use at your own risk.

Please use the "legacy" branch for the older, more battle-tested version of zfSnap.

# About zfsnap

zfsnap makes rolling ZFS snapshots easy and — with cron — automatic.

The main advantages of zfsnap are its portability, simplicity, and performance.
It is written purely in /bin/sh and does not require any additional software —
other than core *nix utilies.

zfsnap stores all the information it needs about a snapshot directly in its name;
no database or special ZFS properties are needed. The information is stored in
a way that is human readable, making it much easier for a sysadmin to manage
and audit backup schedules.

Snapshot names are in the format of pool/fs@[prefix]Timestamp--TimeToLive (e.g.
pool/fs@weekly-2014-04-07_05.30.00--6m). The prefix is optional and is quite
useful for filtering, Timestamp is the date and time when the snapshot was
created, and TimeToLive (TTL) is the amount of time the snapshot will be kept
until it can be deleted.

# Need help?

The wiki currently only covers zfSnap 1.x. https://github.com/zfsnap/zfsnap/wiki

For information about zfsnap 2.0, please refer to the manpage.

We have a mailing list (zfsnap@librelist.com) for questions, suggestions, and
discussion. It can also be found at gmane.comp.sysutils.zfsnap on gmane.

# Will zfsnap run on my system?

zfsnap is written with portability in mind, and our aim is for it to run on
any and every OS that supports ZFS.

Currently, zfsnap supports FreeBSD, Solaris (and Solaris-like OSs), Linux,
GNU/kFreeBSD, and OS X. It should run on your system as long as:
- your Bourne shell (/bin/sh) supports "local" variables (all modern systems should)
- your system uses the Gregorian calendar

