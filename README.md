# searchfs

<img src="http://sveinbjorn.org/images/executable_icon.jpg" width="128" height="128" alt="executable icon" style="float: right; margin-left: 20px; margin-bottom: 20px;" align="right">

`searchfs` is a Mac command line tool to quickly search by filename on entire HFS+ and APFS volumes. Searching takes place at the driver level using the file system catalog. This means the volume's directory tree can be scanned much faster than with a standard recursive filename search using `find`.  

Search is case-insensitive by default. Matching files are printed to standard output in the order they are found in the catalog. See the [man page](https://sveinbjorn.org/files/manpages/searchfs.1.html) for details.

[KatSearch](https://github.com/sveinbjornt/KatSearch) is a graphical application built on top of `searchfs`.

## Download

* [⇩ Download searchfs binary](https://sveinbjorn.org/files/software/searchfs.zip) (<20 KB, Intel 64-bit, macOS 10.8 or later)
* [searchfs man page](https://sveinbjorn.org/files/manpages/searchfs.1.html) (HTML)

## Build & Install

* `git clone https://github.com/sveinbjornt/searchfs.git`
* `cd searchfs`
* `make`
* `make install`

Installs binary into <code>/usr/local/bin/</code>. Man page goes into <code>/usr/local/share/man/man1/</code>.

## Performance

According to my benchmarks, `searchfs` runs about 35-50% faster than `find` under typical conditions.

The following are benchmark results on a 2012 Retina MacBook Pro with an Apple-supplied 512 GB SSD running an APFS file system containing about 2 million files:

### searchfs
```shell
$ time searchfs "something"
0,01s user 33,15s system 32% cpu 1:33,59 total
```
### find
```shell
$ time find / -name "*something*"
9,53s user 67,64s system 49% cpu 2:37,39 total
```

Although I have yet to test this properly, `searchfs` is probably *much* faster than `find` on hard disk drives, which have higher seek times. It is also very fast indeed on file systems with a small number of files.

## History

Apple added file system catalog search to Mac OS with the introduction of the Hiearchical File System (HFS) back in 1985. HFS replaced the previous flat table structure in the old MFS file system with a catalog file using a B-tree structure. Unlike Windows' FAT file system, HFS (and later, HFS+) thus arranged the entire directory tree into one large file on the disk, with interlinked nodes that did not match the hierarchical folder structure. This meant that volumes could be searched very quickly regardless of size.

The Classic Mac OS exposed this functionality via the FSCatalogSearch() function, which iterated efficiently over the nodes, thus minimizing disk seek times. In the pre-SSD era, this gave the Mac a significant performance advantage over Windows when it came to full-volume search. For a long time, FSCatalogSearch continued to be available in Mac OS X / macOS via the Carbon APIs but it has now been deprecated and does not support APFS, Apple's new file system.

However, catalog search for both HFS+ and APFS remains available in Darwin's low-level system libraries via the [searchfs()](https://www.unix.com/man-page/osx/2/searchfs/) function. The `searchfs` program makes use of this function.

## TODO

* The API supports searching the catalog for files based on creation, modification, access date, finder flags, deprecated old-school file and creator types,, and so on. Add that.

## Version History

* 14/07/2018 - **0.1.0** - Initial release

## BSD License

Copyright © 2017-2018 Sveinbjorn Thordarson <a href="mailto:sveinbjorn@sveinbjorn.org">&lt;sveinbjorn@sveinbjorn.org&gt;</a>

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
