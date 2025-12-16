# Makefile for searchfs command line tool

BIN_NAME = searchfs
MAN_NAME = searchfs.1
CC=clang
CFLAGS = -Os -g -mmacosx-version-min=11.5
DEST_DIR ?= /usr/local/bin/
MAN_DIR ?= /usr/local/share/man/man1/
FRAMEWORKS = -framework Foundation -framework CoreServices

all:: main

main: main.m
	$(CC) $(FRAMEWORKS) -o "$(BIN_NAME)" $(CFLAGS) main.m
	/usr/bin/strip -xS "$(BIN_NAME)"

universal: main.m
	$(CC) $(FRAMEWORKS) -o "$(BIN_NAME)" $(CFLAGS) -arch arm64 -arch x86_64 main.m
	/usr/bin/strip -xS "$(BIN_NAME)"

install:
	cp "$(BIN_NAME)" "$(DEST_DIR)"
	cp "$(MAN_NAME)" "$(MAN_DIR)"

uninstall:
	rm "$(DEST_DIR)$(BIN_NAME)"
	rm "$(MAN_DIR)$(MAN_NAME)"

clean:
	rm -rf *.o searchfs 2> /dev/null
