Shaking up GHC
==============

[![Build Status](https://travis-ci.org/snowleopard/shaking-up-ghc.svg)](https://travis-ci.org/snowleopard/shaking-up-ghc)

As part of my 6-month research secondment to Microsoft Research in Cambridge
I am taking up the challenge of migrating the current [GHC][ghc] build system
based on standard `make` into a new and (hopefully) better one based on
[Shake][shake]. If you are curious about the project you can find more details
on the [wiki page][ghc-shake-wiki] and in this [blog post][shake-blog-post].

This is supposed to go into the `shake-build` directory of the GHC source tree.

[Join us on #shaking-up-ghc on Freenode](irc://chat.freenode.net/#shaking-up-ghc)

Trying it
---------

Please see the [Preparation][ghc-preparation] on the haskell wiki
for general preparation. The preparation steps for the `shake` build system are
identical to those for the `make` build system. This means that you don't need
to adjust anything if you are already familiar with building ghc using the `make`
build system.

### Linux / Mac OS X

```bash
git clone git://git.haskell.org/ghc
cd ghc
git submodule update --init
git clone git://github.com/snowleopard/shaking-up-ghc shake-build
./boot
./configure
# or if you want to use clang (e.g. building on OS X)
./configure --with-gcc=$(which clang) # See #26

```

Now you have a couple of options:

- `./shake-build/build.sh` to run the script directly. You'll need to have
  `shake` installed globally.
- `./shake-build/build.cabal.sh` to install the build system in a Cabal sandbox
  and then run it.



### Windows

```bash
git clone --recursive git://git.haskell.org/ghc.git
cd ghc
git clone git://github.com/snowleopard/shaking-up-ghc shake-build
./boot
./configure --enable-tarballs-autodownload
shake-build/build.bat
```
Also see the [Building GHC on Windows guide][ghc-windows-building-guide].

### Resetting the build

To reset the new build system run the build script with `-B` flag. This forces Shake to rerun all rules, even if results of the previous build are still in the GHC tree. This is a temporary solution; we are working on a proper reset functionality (see [#32](https://github.com/snowleopard/shaking-up-ghc/issues/32)).


How to contribute
-----------------

The best way to contribute is to try the new build system, report the issues
you found, and attempt to fix them. Please note the codebase is very unstable
at present and we expect a lot of further refactoring. Before attempting to
fix any issue do make sure no one else is already working on it. The
documentation is currently non-existent, but we will start addressing this
once the codebase stabilises.


[ghc-shake-wiki]: https://ghc.haskell.org/trac/ghc/wiki/Building/Shake
[ghc-preparation]: https://ghc.haskell.org/trac/ghc/wiki/Building/Preparation
[ghc-windows-building-guide]: https://ghc.haskell.org/trac/ghc/wiki/Building/Preparation/Windows
[ghc]: https://en.wikipedia.org/wiki/Glasgow_Haskell_Compiler
[shake-blog-post]: https://blogs.ncl.ac.uk/andreymokhov/shaking-up-ghc
[shake]: https://github.com/ndmitchell/shake/blob/master/README.md
