#!/bin/sh
# Validate mdoc man page syntax using groff.
# Usage: ./validate_man.sh [man_file]
# Exit 0 on success, 1 on warnings/errors.

set -eu

MAN_FILE="${1:-../man/man8/zfsnap.8}"

if [ ! -f "$MAN_FILE" ]; then
    printf 'Error: %s not found\n' "$MAN_FILE" >&2
    exit 2
fi

WARNINGS=""

# Check for common mdoc issues

# 1. File must start with .\" or .Dd
if ! head -n1 "$MAN_FILE" | grep -qE '^\.["\\]|^\.Dd'; then
    WARNINGS="${WARNINGS}Line 1: File should start with a comment (.\\\") or .Dd date macro\n"
fi

# 2. Required macros must be present
for macro in ".Dd" ".Dt" ".Sh NAME" ".Sh SYNOPSIS" ".Sh DESCRIPTION"; do
    if ! grep -q "^${macro}" "$MAN_FILE"; then
        WARNINGS="${WARNINGS}Missing required macro: ${macro}\n"
    fi
done

# 3. Check for unmatched .Bl/.El (block lists)
OPEN_BL=$(grep -c '^\.Bl' "$MAN_FILE" || true)
CLOSE_EL=$(grep -c '^\.El' "$MAN_FILE" || true)
if [ "$OPEN_BL" -ne "$CLOSE_EL" ]; then
    WARNINGS="${WARNINGS}Unmatched .Bl/.El: ${OPEN_BL} opens, ${CLOSE_EL} closes\n"
fi

# 4. Check for unmatched .Bd/.Ed (block displays)
OPEN_BD=$(grep -c '^\.Bd' "$MAN_FILE" || true)
CLOSE_ED=$(grep -c '^\.Ed' "$MAN_FILE" || true)
if [ "$OPEN_BD" -ne "$CLOSE_ED" ]; then
    WARNINGS="${WARNINGS}Unmatched .Bd/.Ed: ${OPEN_BD} opens, ${CLOSE_ED} closes\n"
fi

# 5. Check for unmatched .Pp (should not have consecutive .Pp)
if grep -q '^\.Pp$' "$MAN_FILE"; then
    PREV_Pp=0
    LINE_NUM=0
    while IFS= read -r line; do
        LINE_NUM=$((LINE_NUM + 1))
        case "$line" in
            .Pp)
                if [ "$PREV_Pp" -eq 1 ]; then
                    WARNINGS="${WARNINGS}Line ${LINE_NUM}: Consecutive .Pp macros\n"
                fi
                PREV_Pp=1
                ;;
            *)
                PREV_Pp=0
                ;;
        esac
    done < "$MAN_FILE"
fi

# 6. Check for trailing whitespace on macro lines
if grep -q '^\\.[A-Za-z].*[[:space:]]$' "$MAN_FILE"; then
    WARNINGS="${WARNINGS}Trailing whitespace found on macro lines\n"
fi

# 7. Run groff in parse-only mode to catch syntax errors
GROFF_OUTPUT=$(groff -mdoc -z "$MAN_FILE" 2>&1) || true
if [ -n "$GROFF_OUTPUT" ]; then
    WARNINGS="${WARNINGS}groff warnings/errors:\n${GROFF_OUTPUT}\n"
fi

# Report results
if [ -z "$WARNINGS" ]; then
    printf '\033[1;32m%s\033[0m\n' "Man page validation passed: $MAN_FILE"
    exit 0
else
    printf '\033[1;33m%s\033[0m\n' "Man page validation found issues in $MAN_FILE:"
    printf "%b" "$WARNINGS"
    exit 1
fi
