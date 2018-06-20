#!/bin/sh

make
zip searchfs.zip searchfs
scp searchfs.zip root@sveinbjorn.org:/www/sveinbjorn/html/files/software/
scp searchfs.1.html root@sveinbjorn.org:/www/sveinbjorn/html/files/manpages/
rm searchfs.zip
