#!/usr/bin/env bash
# Basic benchmark script comparing searchfs with find
# Tests on root filesystem only

# searchfs
time ./searchfs -v / Foundation &> /dev/null

# -xdev flag ensures other filesystems are not traversed
time find / -xdev -name '*Foundation*' &> /dev/null
