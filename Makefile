all: build test

exe := ./build/hosts
src := $(shell find . -maxdepth 1 -name '*.janet')

build: jpm-deps $(exe)

test: build | jpm-command
	@$(JPM) test

clean:
	rm -fr build # Keep .Makefile.d and .reqd.

MAKEFILE := $(lastword $(MAKEFILE_LIST))

include .Makefile.d-init.mk
include .Makefile.d/janet.mk

src+ := $(src)
src+ += $(MAKEFILE)

$(exe): $(src+)
	@rm -f $@
	@$(JPM) build
