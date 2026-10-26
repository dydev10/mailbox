# shellcheck shell=bash
#
# Output helpers: section headings, PASS/FAIL lines and the final summary.
# Sourced by test/run.sh; not run on its own.

PASSED=0
FAILED=0

section() {
  echo
  echo "$1"
}

pass() {
  PASSED=$((PASSED + 1))
  echo "  PASS  $1"
}

# fail NAME [DETAILS]: DETAILS (command output) is printed indented below
fail() {
  FAILED=$((FAILED + 1))
  echo "  FAIL  $1"
  if [ -n "${2:-}" ]; then
    echo "$2" | sed 's/^/        /'
  fi
}

note() {
  echo "  INFO  $1"
}

# Print the counts and exit with an error if any check failed
print_summary() {
  echo
  echo "$PASSED passed, $FAILED failed."
  echo "The container is still running; bash test/clean.sh removes it."

  if [ "$FAILED" -gt 0 ]; then
    exit 1
  fi
}
