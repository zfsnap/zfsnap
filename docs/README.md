# Note

This branch contains the new 2.0 code-base which is in beta. While 2.0 is a big
step forward and has far better testing, it has not been used as widely in
production as the zfSnap 1.x line.

Testing is most welcome, but use at your own risk.

Please use the "legacy" branch for the older, more battle-tested version of zfSnap.

# About zfsnap

zfsnap makes rolling ZFS snapshots easy and — with cron — automatic.

The main advantages of zfsnap are its portability, simplicity, and performance.
It is written purely in /bin/sh and does not require any additional software —
other than a few core *nix utilies.

zfsnap stores all the information it needs about a snapshot directly in its name;
no database or special ZFS properties are needed. The information is stored in
a way that is human readable, making it much easier for a sysadmin to manage
and audit backup schedules.

Snapshot names are in the format of pool/fs@[prefix]Timestamp--TimeToLive (e.g.
pool/fs@weekly-2014-04-07_05.30.00--6m). The prefix is optional but can be quite
useful for filtering, Timestamp is the date and time when the snapshot was
created, and TimeToLive (TTL) is the amount of time the snapshot will be kept
until it can be deleted.

# Need help?

The wiki covers zfSnap 1.x. https://github.com/zfsnap/zfsnap/wiki

For information about zfsnap 2.0, please refer to the manpage or the [zfsnap
website](http://www.zfsnap.org).

We have a mailing list (zfsnap@librelist.com) for questions, suggestions, and
discussion. It can also be found at gmane.comp.sysutils.zfsnap on gmane.

# Will zfsnap run on my system?

zfsnap is written with portability in mind, and our aim is for it to run on
any and every OS that supports ZFS.

Currently, zfsnap supports FreeBSD, Solaris (and Solaris-like OSs), Linux,
GNU/kFreeBSD, and OS X. It should run on your system as long as:
- ZFS is installed
- your Bourne shell is POSIX compliant and supports "local" variables (all modern systems should)
- your system provides at least the most basic of POSIX utilities (uname, head, etc)
- your system uses the Gregorian calendar

See the PORTABILITY file for additional information on specific shells and OSs.
