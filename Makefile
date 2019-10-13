all: build test

exe := ./build/hosts
src := $(shell find . -maxdepth 1 -name '*.janet')

build: jpm-deps $(exe)

test: build | jpm-command
	@jpm test

clean:
	rm -fr build # Keep .Makefile.d and .reqd.

include .Makefile.d-init.mk
include .Makefile.d/janet.mk

$(exe): $(src)
	@jpm build
