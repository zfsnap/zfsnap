# Packaging

This directory contains packaging files for various distributions and package managers.

## Structure

- `debian/` - Debian/Ubuntu packaging (debian/rules, control, etc.)
- `rpm/` - RPM packaging (.spec file, etc.)
- `arch/` - Arch Linux packaging (PKGBUILD, etc.)
- `freebsd/` - FreeBSD port files (Makefile, pkg-descr, etc.)

## Adding a new package

1. Create a subdirectory named after the distribution/package format
2. Add the necessary packaging files
3. Document any build assumptions or dependencies in a README within the subdirectory
