# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

TEST_MODE="true"

spec_failed=0

ItReturns () {
  cmd="$1"
  expected_return="$2"

  eval "$cmd"
  actual_return="$?"

  printf "\`%s\` returns %s ... " "$cmd" "$expected_return"
  if [ $expected_return -eq $actual_return ]; then
    printf "\033[1;32mpassed\033[0m\n"
  else
    spec_failed=1
    printf "\033[1;31mfailed\n"
    printf "\texpected return value: %s\n" "$expected_return"
    printf "\tactual return value:   %s\n" "$actual_return"
    printf "\033[0m\n"
  fi
}

# Check both the global variable RETVAL and the return of a given function
ItsRetvalIs() {
  cmd="$1"
  expected_retval="$2"
  expected_return="$3"

  eval "$cmd"
  actual_return="$?"
  actual_retval="$RETVAL"

  printf "\`%s\` retvals '%s' and '%s' ... " "$cmd" "$expected_retval" "$expected_return"
  if [ "$expected_retval" = "$actual_retval" ] && [ $expected_return -eq $actual_return ]; then
    printf "\033[1;32mpassed\033[0m\n"
  else
    spec_failed=1
    printf "\033[1;31mfailed\n"
    printf "\texpected retval: %s\n" "$expected_retval"
    printf "\tactual retval:   %s\n" "$actual_retval"
    printf "\texpected return value: %s\n" "$expected_return"
    printf "\tactual return value:   %s\n" "$actual_return"
    printf "\033[0m\n"
  fi
}

ItEchos () {
  cmd="$1"
  expected_result="$2"
  actual_result="`eval "$cmd"`"

  printf "\`%s\` echos '%s' ... " "$cmd" "$expected_result"
  if [ "$expected_result" = "$actual_result" ]; then
    printf "\033[1;32mpassed\033[0m\n"
  else
    spec_failed=1
    printf "\033[1;31mfailed\n"
    printf "\texpected result: %s\n" "$expected_result"
    printf "\tactual result:   %s\n" "$actual_result"
    printf "\033[0m\n"
  fi
}

ExitTests () {
  exit $spec_failed
}
