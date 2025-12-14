#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

/usr/bin/man ./searchfs.1 | ./cat2html > searchfs.1.html

