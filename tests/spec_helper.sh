#!/bin/sh

test_mode="true"
spec_failed=0
tests_run=0

ItReturns () {
  cmd="$1"
  expected_return="$2"

  eval "$cmd" >/dev/null 2>&1
  actual_return="$?"
  tests_run=$((tests_run + 1))

  echo -n "\`$cmd\` returns $expected_return ... "
  if [ $expected_return -eq $actual_return ]; then
    echo -e "\e[1;32mpassed\e[0m"
  else
    spec_failed=1
    echo -e "\e[1;31mfailed"
    echo "  expected return value: $expected_return"
    echo "    actual return value: $actual_return"
    echo -e "\e[0m"
  fi
}

ItEchos () {
  cmd="$1"
  expected_result="$2"
  actual_result="`eval "$cmd" 2>/dev/null`"
  tests_run=$((tests_run + 1))

  echo -n "\`$cmd\` echos \`$expected_result\` ... "
  if [ "$expected_result" = "$actual_result" ]; then
    echo -e "\e[1;32mpassed\e[0m"
  else
    spec_failed=1
    echo -e "\e[1;31mfailed"
    echo "  expected result: $expected_result"
    echo "    actual result: $actual_result"
    echo -e "\e[0m"
  fi
}

ItOutputsStdout () {
  cmd="$1"
  expected_result="$2"
  actual_result="`eval "$cmd" 2>/dev/null`"
  tests_run=$((tests_run + 1))

  echo -n "\`$cmd\` stdout contains \`$expected_result\` ... "
  case "$actual_result" in
    *"$expected_result"*)
      echo -e "\e[1;32mpassed\e[0m"
      ;;
    *)
      spec_failed=1
      echo -e "\e[1;31mfailed"
      echo "  expected stdout to contain: $expected_result"
      echo "    actual stdout: $actual_result"
      echo -e "\e[0m"
      ;;
  esac
}

ItOutputsStderr () {
  cmd="$1"
  expected_result="$2"
  actual_result="`eval "$cmd" 2>&1 >/dev/null`"
  tests_run=$((tests_run + 1))

  echo -n "\`$cmd\` stderr contains \`$expected_result\` ... "
  case "$actual_result" in
    *"$expected_result"*)
      echo -e "\e[1;32mpassed\e[0m"
      ;;
    *)
      spec_failed=1
      echo -e "\e[1;31mfailed"
      echo "  expected stderr to contain: $expected_result"
      echo "    actual stderr: $actual_result"
      echo -e "\e[0m"
      ;;
  esac
}

ItExitsWith () {
  # Runs cmd in subshell to catch exit
  cmd="$1"
  expected_return="$2"

  ( eval "$cmd" ) >/dev/null 2>&1
  actual_return="$?"
  tests_run=$((tests_run + 1))

  echo -n "\`$cmd\` exits with $expected_return ... "
  if [ $expected_return -eq $actual_return ]; then
    echo -e "\e[1;32mpassed\e[0m"
  else
    spec_failed=1
    echo -e "\e[1;31mfailed"
    echo "  expected exit: $expected_return"
    echo "    actual exit: $actual_return"
    echo -e "\e[0m"
  fi
}

ExitTests () {
  echo ""
  echo "Tests run: $tests_run"
  if [ $spec_failed -eq 0 ]; then
    echo -e "\e[1;32mAll tests passed\e[0m"
  else
    echo -e "\e[1;31mSome tests failed\e[0m" >&2
  fi
  exit $spec_failed
}
