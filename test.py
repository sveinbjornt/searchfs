#!/usr/bin/python
# -*- coding: utf-8 -*-

""" Python 2.7 script to run simple tests on the searchfs binary. """

import sys
import os
import logging
import time
from pprint import pprint

SEARCHFS = "./searchfs"


def run_tests():
    print("Running tests... (this may take a while)")
    start = time.time()

    def run_searchfs(cmd):
        cmdstr = SEARCHFS + " " + cmd
        print(cmdstr)
        out = os.popen(cmdstr).read()
        return out.rstrip().split("\n")

    # Test volume listing
    lines = run_searchfs("--list")
    rootvol = [v for v in lines if v.endswith(": /")]
    assert len(rootvol) == 1
    rootvol = rootvol[0]
    device = rootvol.split()[0]

    # Test with volume specified by device
    lines = run_searchfs("-v '" + device + "' 's' -m 10")
    assert len(lines) == 10

    # Test with volume specified by mount point
    lines = run_searchfs("--volume '/' 'C' --limit 10")
    assert len(lines) == 10

    # Match start only
    lines = run_searchfs("^README -s -m 20")
    assert len(lines) == 20
    assert len([n for n in lines if n.split("/")[-1].startswith("README")]) == 20

    # Match end only
    lines = run_searchfs(".plist$ --limit 25")
    assert len(lines) == 25
    assert len([n for n in lines if n.endswith(".plist")]) == 25

    # Find directories only
    lines = run_searchfs("-d 's' -m 15")
    assert len(lines) == 15
    for path in lines:
        assert os.path.isdir(path)

    # Exact filename
    lines = run_searchfs("-d -e Contents -s -m 10")
    assert len(lines) == 10
    assert len([n for n in lines if n.split("/")[-1] == "Contents"]) == 10
    assert len([n for n in lines if os.path.isdir(n)]) == 10
    
    # Negate params
    not_present = "Hold the newsreaders nose squarely, waiter, or friendly milk will countermand my trousers"
    lines = run_searchfs("-n '" + not_present + "' -m 200")
    assert len(lines) == 200

    # Find files only
    lines = run_searchfs("-f 's' -m 7")
    assert len(lines) == 7
    for path in lines:
        assert (
            os.path.islink(path) or os.path.isdir(path) == False
        ), "Path {0} is a dir.".format(path)

    # Find "/bin/ls"
    lines = run_searchfs("-e 'ls'")
    assert "/bin/ls" in lines

    # Skip files in packages
    lines = run_searchfs("-pse Contents")
    assert "/Applications/Calendar.app/Contents" not in lines

    # Skip /System folder
    lines = run_searchfs("-xse Frameworks")
    assert len(lines) > 10
    assert len([n for n in lines if n.startswith("/System")]) == 0

    # All done
    elapsed = time.time() - start
    print("Tests completed in %.1f seconds" % (elapsed,))


if __name__ == "__main__":
    # Make sure binary exists
    exists = os.path.isfile(SEARCHFS)
    if not exists:
        print("Binary not found: {0}".format(SEARCHFS))
        sys.exit(1)

    run_tests()
