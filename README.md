# WARNING

This branch is very unstable.
You should use zfSnap from legacy branch instead.




zfSnap is a simple sh script to make rolling zfs snapshots with cron. The main
advantage of zfSnap is it's written in 100% pure /bin/sh so it doesn't require
any additional software to run.

zfSnap keeps all information about snapshot in snapshot name.

zfs snapshot names are in the format of Timestamp--TimeToLive.

Timestamp includes the date and time when the snapshot was created and
TimeToLive (TTL) is the amount of time for the snapshot to stay alive before
it's ready for deletion.


See https://github.com/graudeejs/zfSnap/wiki for more info
