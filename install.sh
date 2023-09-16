 #!/bin/bash
 install -o root -g root -m u+rx  sbin/zfsnap.sh  /usr/sbin/
 install -o root -g users -d /usr/share/zfsnap
 install -o root -g users -d /usr/share/zfsnap/commands
 install -o root -g root share/zfsnap/core.sh /usr/share/zfsnap/core.sh
 install -o root -g root -m ug+rx share/zfsnap/core.sh /usr/share/zfsnap/core.sh
 install -o root -g root -m ug+rx share/zfsnap/commands/*.sh  /usr/share/zfsnap/commands/
 install -o root -g users  -m a+r man/man8/zfsnap.8  /usr/share/man/man8/
 install -o root -g users  -m ug+r+x completion/zfsnap-completion.bash  /etc/bash_completion.d/zfsnap
 install -o root -g users  -d /usr/share/doc/zfsnap
 install -o root -g users  -m ug+r+x+w AUTHORS INSTALL LICENSE NEWS PORTABILITY README.md    /usr/share/doc/zfsnap
