#!/bin/sh

if [ `uname` = 'SunOS' ]; then
    cd /tmp/zfsnap/
    find ./ -type d \( -name tools -o -name vagrant \) -prune -o -type f \
        -exec tools/mod_shebang.sh -s '#!/bin/bash' {} \;
    printf "SunOS Fixed\n"
fi

