#!/bin/sh

exit_with_error=0

script_dir="$(cd "$(dirname "$0")" && pwd)"

cd "$script_dir/unit" || exit 1
for t in *.sh; do
  sh "$t"
  [ $? -ne 0 ] && exit_with_error=1
done

echo
if [ $exit_with_error -eq 0 ]; then
  echo "All tests passed"
else
  echo "Some tests failed" >&2
  exit 1
fi
