#!/bin/sh

exit_with_error=0

for i in unit integration; do
  cd "$i"
  for t in `ls`; do
    sh $t
    [ $? -ne 0 ] && exit_with_error=1
  done
  cd ..
done


echo
if [ $exit_with_error -eq 0 ]; then
  echo "All tests passed"
else
  echo "Some tests failed" > /dev/stderr
  exit 1
fi
