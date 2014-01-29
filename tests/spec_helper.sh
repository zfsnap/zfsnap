test_mode="true"

spec_failed=0

ItReturns () {
  cmd="$1"
  expected_return="$2"

  eval "$cmd"
  actual_return="$?"

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
  actual_result="`eval "$cmd"`"

  echo -n "\`$cmd\` echos \`$expected_result\` ... "
  if [ $expected_result = $actual_result ]; then
    echo -e "\e[1;32mpassed\e[0m"
  else
    spec_failed=1
    echo -e "\e[1;31mfailed"
    echo "  expected result: $expected_result"
    echo "    actual result: $actual_result"
    echo -e "\e[0m"
  fi
}


ExitTests () {
  exit $spec_failed
}
