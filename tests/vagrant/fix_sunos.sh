#!/bin/sh

if [ `uname` = 'SunOS' ]; then
    cd /tmp/zfsnap/
    find ./src -type f \
        -exec src/tools/mod_shebang.sh -s '#!/bin/bash' {} \;
    printf "SunOS Fixed\n"
fi

