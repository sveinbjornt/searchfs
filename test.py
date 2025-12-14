#!/usr/bin/env python3

""" Python 3 script to run simple tests on the searchfs binary. """

import sys
import os
import logging
import time
from pprint import pprint
import subprocess

SEARCHFS = "./searchfs"

# Exit codes from sysexits.h
EX_USAGE = 64

def run_tests():
    print("Running tests... (this may take a while)")
    start = time.time()

    def run_searchfs(args_list, expected_exit_code=0):
        cmd_to_run = [SEARCHFS] + args_list
        print(" ".join(cmd_to_run))
        try:
            result = subprocess.run(cmd_to_run, capture_output=True, text=True, check=False)
            out = result.stdout
            err = result.stderr

            if result.returncode != expected_exit_code:
                raise AssertionError(
                    f"Command '{' '.join(cmd_to_run)}' exited with {result.returncode}, expected {expected_exit_code}.\n" +
                    f"Stdout: {out}\n" +
                    f"Stderr: {err}"
                )

            # Handle empty output correctly
            stripped = out.strip()
            if not stripped:
                return []
            return stripped.split("\n")
        except FileNotFoundError:
            raise AssertionError(f"Binary not found: {SEARCHFS}")
        except Exception as e:
            print(f"An unexpected error occurred: {e}", file=sys.stderr)
            raise

    # Test volume listing
    lines = run_searchfs(["--list"])
    rootvol = [v for v in lines if v.endswith(": /")]
    assert len(rootvol) == 1
    rootvol = rootvol[0]
    device = rootvol.split()[0]

    # Test with volume specified by device
    lines = run_searchfs(["-v", "/", "s", "-m", "10"])
    assert len(lines) == 10

    # Test with volume specified by mount point
    lines = run_searchfs(["--volume", "/", "C", "--limit", "10"])
    assert len(lines) == 10

    # Match start only
    lines = run_searchfs(["-v", "/", "^README", "-s", "-m", "20"])
    assert len(lines) == 20
    assert len([n for n in lines if n.split("/")[-1].startswith("README")]) == 20

    # Match end only
    lines = run_searchfs(["-v", "/", ".plist$", "--limit", "25"])
    assert len(lines) == 25
    assert len([n for n in lines if n.endswith(".plist")]) == 25

    # Find directories only
    lines = run_searchfs(["-v", "/", "-d", "s", "-m", "15"])
    assert len(lines) == 15
    for path in lines:
        assert os.path.isdir(path)

    # Exact filename
    lines = run_searchfs(["-v", "/", "-d", "-e", "Contents", "-s", "-m", "10"])
    assert len(lines) == 10
    assert len([n for n in lines if n.split("/")[-1] == "Contents"]) == 10
    assert len([n for n in lines if os.path.isdir(n)]) == 10

    # Negate params (uses multi-volume search, reduced limit for speed)
    not_present = "Hold the newsreaders nose squarely, waiter, or friendly milk will countermand my trousers"
    lines = run_searchfs(["-n", not_present, "-m", "20"])
    assert len(lines) > 0

    # Find files only
    lines = run_searchfs(["-v", "/", "-f", "s", "-m", "7"])
    assert len(lines) == 7
    for path in lines:
        assert (
            os.path.islink(path) or os.path.isdir(path) == False
        ), f"Path {path} is a dir."

    # Find "/bin/ls"
    lines = run_searchfs(["-v", "/", "-e", "ls"])
    assert "/bin/ls" in lines

    # Skip files in packages
    lines = run_searchfs(["-v", "/", "-pse", "Contents"])
    assert "/Applications/Calendar.app/Contents" not in lines

    # Skip /System folder
    lines = run_searchfs(["-v", "/", "-xse", "Frameworks"])
    assert len(lines) > 0
    assert len([n for n in lines if n.startswith("/System")]) == 0

    # Test empty search string (should exit with EX_USAGE)
    run_searchfs([""], expected_exit_code=EX_USAGE)

    # --- New Test Cases ---

    # Test for no matches
    print("Testing for no matches...")
    lines = run_searchfs(["-v", "/", "XYZXYZXYZ"])
    assert len(lines) == 0, "Expected no matches for a random string."

    # Test mutually exclusive flags -d and -f
    print("Testing mutually exclusive -d and -f flags...")
    run_searchfs(["-d", "-f", "some_term"], expected_exit_code=EX_USAGE)

    # Test search string longer than PATH_MAX
    print("Testing search string longer than PATH_MAX...")
    long_string = "a" * 2000  # PATH_MAX is typically 1024
    run_searchfs([long_string], expected_exit_code=EX_USAGE)

    # Test prefix match without exact-match
    print("Testing prefix match without exact-match...")
    lines = run_searchfs(["-v", "/", "^README", "-m", "100"])
    assert len(lines) > 0
    assert all(n.split("/")[-1].startswith("README") for n in lines)

    # Test suffix match without exact-match
    print("Testing suffix match without exact-match...")
    lines = run_searchfs(["-v", "/", ".plist$", "-m", "100"])
    assert len(lines) > 0
    assert all(n.endswith(".plist") for n in lines)

    # Test case-sensitive prefix match (assuming 'README' exists, but 'readme' does not)
    print("Testing case-sensitive prefix match...")
    lines = run_searchfs(["-v", "/", "-s", "^readme", "-m", "100"])
    assert len([n for n in lines if n.split("/")[-1].startswith("readme")]) == 0, \
        "Expected no matches for case-sensitive 'readme' prefix."

    # Test multi-volume search (default behavior)
    print("Testing multi-volume search...")
    lines = run_searchfs(["Foundation", "-m", "10"])
    assert len(lines) == 10, "Expected 10 results from multi-volume search"

    # All done
    elapsed = time.time() - start
    print(f"Tests completed in {elapsed:.1f} seconds")


if __name__ == "__main__":
    # Make sure binary exists
    exists = os.path.isfile(SEARCHFS)
    if not exists:
        print(f"Binary not found: {SEARCHFS}")
        sys.exit(1)

    run_tests()
