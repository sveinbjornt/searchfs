#!/usr/bin/env bash
# Convert man page to HTML

cd "$(dirname "$0")" || exit

/usr/bin/man ./searchfs.1 | ./cat2html > searchfs.1.html

