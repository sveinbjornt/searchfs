#!/usr/bin/python
""" Python 2.7 script to run simple tests on the searchfs binary. """

import sys
import os
import logging
import time

SEARCHFS="./searchfs"

def run_tests():
    print("Running tests... (this may take a while)")
    start = time.time()
    
    cmd = "{0} -e 'ls'".format(SEARCHFS)
    out = os.popen(cmd).read()

    assert "/bin/ls" in out.split("\n")
    
    elapsed = time.time() - start
    print("Tests completed in %.1f seconds" % (elapsed,))

if __name__ == "__main__":
    # Make sure binary exists
    exists = os.path.isfile(SEARCHFS)
    if not exists:
        print("Binary not found: {0}".format(SEARCHFS))
        sys.exit(1)
    
    run_tests()
