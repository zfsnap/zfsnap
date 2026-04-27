#!/bin/sh
# POSIX build script: copy src -> dist, normalize shebangs, set execute bits, create tarball
# Source lives in src/, distribution output goes to dist/, packaging files in dist/packaging/
set -eu

SRC=${1:-src}
DEST=${2:-dist}

if [ ! -d "$SRC" ]; then
	printf 'Source directory %s not found\n' "$SRC" >&2
	exit 2
fi

rm -rf "$DEST"
mkdir -p "$DEST"

# Copy preserving attributes where possible
if cp -a "$SRC/." "$DEST/" 2>/dev/null; then
	:
else
	(cd "$SRC" && tar cf - .) | (cd "$DEST" && tar xf -)
fi

# Normalize shebangs using included tool (if present)
if [ -x "$DEST/tools/mod_shebang.sh" ]; then
	find "$DEST" -type f | while IFS= read -r f; do
		if head -n1 "$f" 2>/dev/null | grep -q '^#!'; then
			"$DEST/tools/mod_shebang.sh" -s '#!/bin/sh' "$f" || true
		fi
	done
fi

# Ensure executables have correct mode
[ -f "$DEST/sbin/zfsnap.sh" ] && chmod 0755 "$DEST/sbin/zfsnap.sh"
find "$DEST/share" -type f -name '*.sh' -exec chmod 0755 {} \; 2>/dev/null || true

# Create a tarball if NEWS file exists to derive version
if [ -f "docs/NEWS" ]; then
	VER=$(head -n1 "docs/NEWS" 2>/dev/null | awk '{print $1}' | tr -d 'v' || echo "0.0.0")
else
	VER=0.0.0
fi

TARBALL="zfsnap-${VER}.tar.gz"

# Try to create a reproducible-ish tarball (fallback if --sort unsupported)
if (cd "$DEST" && tar --sort=name -czf "../${TARBALL}" .) 2>/dev/null; then
	:
else
	(cd "$DEST" && tar -czf "../${TARBALL}" .)
fi

if command -v sha256sum >/dev/null 2>&1; then
	sha256sum "${TARBALL}" >"${TARBALL}.sha256" || true
fi

printf 'Build completed: %s -> %s\n' "$SRC" "$DEST"
