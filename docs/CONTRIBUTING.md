# Contributing to zfSnap

## Repository Layout

```
src/              # Source code (authoritative development workspace)
  sbin/           # Main zfsnap.sh script
  share/zfsnap/   # Core library and command modules
  man/            # Man pages
  completion/     # Shell completion scripts
  periodic/       # Periodic job scripts
  tools/          # Build tools

dist/             # Distribution output (build artifacts)
  completion/     # Built completion scripts
  man/            # Built man pages
  periodic/       # Built periodic scripts
  sbin/           # Built main script
  share/          # Built library files
  packaging/      # Package maintainer files (tracked)
    debian/       # Debian/Ubuntu packaging
    rpm/          # RPM packaging
    arch/         # Arch Linux packaging
    freebsd/      # FreeBSD port files

docs/             # Documentation
  README.md       # Project overview
  INSTALL         # Installation instructions
  NEWS            # Changelog / version history
  PORTABILITY     # Platform compatibility notes
  AUTHORS         # Contributors
  LICENSE         # BSD-3-Clause license
  TESTING         # Testing guide
  CONTRIBUTING.md # This file

tests/            # Test suite (unit, integration, system)
build.sh          # Build script (src/ -> dist/)
Makefile          # Build targets
```

## Local Development

Work in `src/`. Tests run against source by default:

```sh
./tests/run.sh
```

To test the distributable build:

```sh
make build
ZFSNAP_PREFIX=$(pwd)/dist ./tests/run.sh
```

## Release Workflow

`dist/packaging/` is tracked for package maintainer files. The rest of `dist/`
is build output and is gitignored. Commit `dist/packaging/` changes as needed.

Typical release steps:

1. Create a release branch: `git checkout -b release/vX.Y.Z`
2. Update `docs/NEWS` (first line should contain the version `vX.Y.Z`)
3. Run `make build` (populates `dist/` with built files and tarball)
4. Run tests against the built tree:
   `ZFSNAP_PREFIX=$(pwd)/dist ./tests/run.sh`
5. Update packaging files in `dist/packaging/` if needed
6. Commit packaging changes and tag:
   `git add dist/packaging`
   `git commit -m "release: vX.Y.Z — update packaging"`
   `git tag vX.Y.Z && git push origin vX.Y.Z`

## Packaging

Package maintainers should place their packaging files in `dist/packaging/<format>/`.
See `dist/packaging/README.md` for details on each format.
