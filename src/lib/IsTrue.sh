# Returns 0 if argument is "true"
case "$1" in
    true)  return 0 ;;
    false) return 1 ;;
    *)     Fatal "'$1' must be true or false." ;;
esac