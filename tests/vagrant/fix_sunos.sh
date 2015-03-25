#!/bin/sh

if [ `uname` = 'SunOS' ]; then
    cd /tmp/zfsnap/;
    find ./ -type f ! -name 'mod_shebang.sh' ! -name 'fix_sunos.sh' \
      -exec ./mod_shebang.sh -s '#!/bin/bash' {} \;
    printf "SunOS Fixed\n"
fi

