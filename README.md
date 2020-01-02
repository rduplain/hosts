## hosts: Build a hosts (/etc/hosts) file from multiple sources.

[![Build Status][build]](https://travis-ci.org/rduplain/hosts)


### Overview

`hosts` is a command-line tool to build a hosts (/etc/hosts) file from multiple
sources.

The project's [Janet](https://janet-lang.org/) source code compiles to a
stand-alone `hosts` executable on all major platforms (GNU/Linux, Mac OS X,
BSD, Windows).


### Installation

The `hosts` binary is a standalone executable. Download a suitable binary from
[project releases][releases], or review [_Development_](#development) to build
the executable locally. Simply add the executable to the system/shell `PATH`.

[releases]: https://github.com/rduplain/hosts/releases


### Motivation

A hosts file itself is simple: provide static data on how to resolve a given
hostname and its aliases to an IP address. The process of updating an IP
address or hostname can be a straightforward find/replace with Unix tools such
as `sed`. A more generalized edit, however, gets complicated fast, because
hosts (/etc/hosts) data is relational. An IP address maps to one or more hosts
by name.

In order to allow for sophisticated updates, especially configuration updates
which assume nothing other than a valid hosts files, the `hosts` command
provides for full parsing, merging, and in-place rewriting of hosts data.

Use cases:

* Create an unpublished alias for an existing host, by running a script as a
  scheduled task (i.e. cron) to perform a DNS query and update /etc/hosts with
  `hosts -f /etc/hosts -s "<ip> <domain>"`. This is particularly useful for
  not-yet-published domains which are under development, and for moving aliases
  from program-local configurations like `~/.ssh/config` to system-wide aliases
  available to all programs.
* Coordinate hosts with DNS discovery without a name server, by distributing a
  hosts file which then overlays the existing /etc/hosts file with `hosts -f
  /etc/hosts -f <file>`. This provides a minimalist approach to service
  discovery and orchestration, especially when configuration management tools
  are already in place.
* Merge multiple hosts files on a network appliance.

(Redirect `hosts` stdout output to perform the actual update of /etc/hosts.)


### Usage

Help output available with `hosts -h`:

```
usage: hosts [option] ...

Build a hosts (/etc/hosts) file from multiple sources.

 Optional:
 -d, --delimiter VALUE=' '    Whitespace to append hostname.
 -f, --file VALUE             A hosts file as input.
 -h, --help                   Show this help message.
 -s, --static VALUE           A static hosts entry.
 -v, --version                Output version, then exit.
```

Example command to write the IPv4 address of `example.net` as `server`:

```sh
hosts -f /etc/hosts -s "$(dig example.net A +short | grep '^[.0-9]*$')  server"
```

Redirect stdout to write to a file. Example:

```
hosts -f /etc/hosts.base -s "192.168.1.10 example.com # comment" > /etc/hosts
```

`hosts` accepts repeated command-line flags for arbitrarily many input files.


### Parse, Merge, and Rewrite In-Place

A hosts file contains lines with the pattern:

    <ip>  <hostname> [<alias>]... # comment

Fields delimit with whitespace comprised of any number of spaces and/or
tabs. Comments start with a hash (`#`) and blank lines are allowed. Hostnames
can have alphanumeric characters and hyphens (`-`); they can be up to 63
characters, must begin with an alphabetic character, and must not end in a
hyphen. Domain names combine hostname elements with a dot (`.`) and must not be
longer than 253 characters. Hostnames are case-insensitive and can have zero or
more aliases.

As `hosts` processes input hosts lines, it will:

* **Preserve order.** Read input line by line, left to right in the
  command-line arguments. Any line matching a previous line, either by IP or
  hostname alias, will update the fields of the previous line instead of
  writing to output.
* **Discard redundant comments.** Any line matching a previous line will have
  its comment (if any) discarded, such that the first-seen matching hosts line
  will be the only to have its comment in the output.
* **Use latest information.** The last line in a group of matched lines is
  presumed to have the latest information on the IP for all aliases in the
  match; the output includes that IP for all matched aliases.

While `hosts` can reliably rewrite hosts data in-place, repeat autonomous calls
to `hosts` benefit from writing to an output file which is not ultimately used
as an input file in a later invocation. This will avoid the case where a
previously merged alias is now out-of-date and unused. Aliases merge, but
nowhere in the process are they dropped without manual edits.

References:

* `man 7 hostname` on Linux
* `man 5 hosts` on Linux


### Development

This project provides a single-command build to install a project-local Janet,
install dependencies, build, and test. On a Unix-like system, just run GNU Make
(`make`, which is sometimes `gmake` on BSD systems):

```
make
```

On Windows:

```
.\bin\build.cmd
```

Otherwise, with [Janet](https://janet-lang.org/) installed, build and test:

```
[sudo] jpm deps # first time only
jpm test
```

The `build/` directory contains the `jpm build` (called by `jpm test`) output
of a redistributable binary for the current platform.


### Meta

[build]: https://travis-ci.org/rduplain/hosts.svg?branch=master

Copyright (c) 2019-2020, R. DuPlain. All rights reserved.
BSD 2-Clause License.
