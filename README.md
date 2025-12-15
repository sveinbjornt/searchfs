[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Language](https://img.shields.io/badge/language-objective--c-lightgrey)](https://en.wikipedia.org/wiki/Objective-C)
[![Release](https://shields.io/github/v/release/sveinbjornt/searchfs?display_name=tag)](https://github.com/sveinbjornt/searchfs/releases)
[![Build](https://github.com/sveinbjornt/searchfs/actions/workflows/macos.yml/badge.svg)](https://github.com/sveinbjornt/searchfs/actions)

# searchfs

<img src="searchfs.png" width="164" height="164" alt="searchfs icon" 
style="float: right; margin-left: 20px; margin-bottom: 20px;" align="right">

`searchfs` is a macOS command line tool to quickly search by filename 
on entire APFS and HFS+ volumes. Searching takes place at the driver 
level using the file system catalog. This means the volume's directory 
tree can be scanned much faster than with a standard recursive filename 
search using `find`.

Search is case-insensitive by default. Matching files are printed to
standard output in the order they are found in the catalog. See the 
[man page](https://sveinbjorn.org/files/manpages/searchfs.1.html) for details.

## Download

* [⬇ Download latest searchfs binary](https://sveinbjorn.org/files/software/searchfs.zip) (v0.4, <20 KB, Intel 64-bit, macOS 11.5 or later)

## Documentation

* [searchfs man page](https://sveinbjorn.org/files/manpages/searchfs.1.html) (HTML)

## Build & Install

```bash
git clone https://github.com/sveinbjornt/searchfs.git
cd searchfs
make
make install
```

Installs binary by default into `/usr/local/bin/`. Man page goes into 
`/usr/local/share/man/man1/`. These can be overridden with `DEST_DIR` and `MAN_DIR`.

## Performance

According to some basic benchmarks, `searchfs` runs up to **100x** faster 
than `find` when performing full-volume search on APFS filesystems, and 
even faster on HFS+. This can be tested with the `benchmark.sh` script.

Although I have yet to test this properly, it’s is probably *much* 
*much* faster than `find` on hard disk drives, which have higher seek times. 

## Testing

You need Python 3 installed.

```bash
python3 test.py
```

## History Lesson

Apple added file system catalog search to Mac OS with the introduction of 
the Hierarchical File System (HFS) back in 1985. HFS replaced the previous
flat table structure in the old MFS file system with a catalog file using
a B-tree structure. Unlike Windows' FAT file system, HFS (and later, HFS+)
thus arranged the entire directory tree into one large file on the disk,
with interlinked nodes that did not match the hierarchical folder structure. 
This meant that volumes could be searched very quickly regardless of size.

Classic Mac OS exposed this functionality via the `FSCatalogSearch()`
function, which iterated efficiently over the nodes, thus minimizing disk
seek times. In the pre-SSD era, this gave the Mac a significant performance
advantage over Windows when it came to full-volume search. For a long time,
`FSCatalogSearch` continued to be available in Mac OS X / macOS via the
Carbon APIs but it has now been deprecated and does not support APFS,
Apple's new file system.

However, catalog search for both HFS+ and APFS is available in Darwin's
low-level system libraries via the
[`searchfs()`](https://www.unix.com/man-page/osx/2/searchfs/) function.
The `searchfs` program makes use of this function.

## Version History

See [CHANGES.md](CHANGES.md)

## BSD License

Copyright © 2017-2025 [Sveinbjorn Thordarson](mailto:sveinbjorn@sveinbjorn.org)

See [LICENSE.txt](LICENSE.txt)
