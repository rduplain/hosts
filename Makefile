all: build test

exe := ./build/hosts
src := $(shell find . -maxdepth 1 -name '*.janet')

build: jpm-deps $(exe)

test: build | jpm-command
	@$(JPM) test

clean:
	rm -fr build # Keep .Makefile.d and .reqd.

MAKEFILE := $(lastword $(MAKEFILE_LIST))
JANET_REV := v1.12.2

include .Makefile.d-init.mk
include .Makefile.d/janet.mk

src+ := $(src)
src+ += $(MAKEFILE)
src+ += .git/HEAD
src+ += $(shell git branch --format=".git/%(refname)" | xargs ls 2>/dev/null)
src+ += $(shell find .git/refs/tags -maxdepth 1)

$(exe): $(src+)
	@rm -f $@
	@$(JPM) build

$(JANET): $(MAKEFILE)
