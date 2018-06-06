# searchfs

<!--<img src="http://sveinbjorn.org/images/executable_icon.jpg" width="128" height="128" alt="executable icon" style="float: right; margin-left: 20px; margin-bottom: 20px;" align="right">-->

`searchfs` is a macOS command line tool to quickly search by filename on HFS+ and APFS volumes. Searching takes place at the driver level using the file system catalog. This means the volume's entire directory tree can be scanned much faster than with a standard recursive filename search using `/usr/bin/find`.  Currently only supports case-insensitive search.

## Performance

```shell
$ time searchfs "something"
./searchfs something  0,01s user 33,15s system 32% cpu 1:41,59 total
```

```shell
$ time find / -name "something"
find / -name something  6,84s user 65,32s system 47% cpu 2:31,76 total
```

## Download

* [Download binary](https://sveinbjorn.org/files/software/searchfs.zip) (~20 KB, Intel 64-bit, macOS 10.8 or later)
* [searchfs man page](https://sveinbjorn.org/files/manpages/searchfs.1.html)

## BSD License

Copyright © 2017-2018 Sveinbjorn Thordarson <a href="mailto:sveinbjorn@sveinbjorn.org">&lt;sveinbjorn@sveinbjorn.org&gt;</a>

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
