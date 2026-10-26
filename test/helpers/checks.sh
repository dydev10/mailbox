# shellcheck shell=bash
#
# Check helpers: run a command and record PASS or FAIL.
# Each returns 0 when the check passed and 1 when it failed, so a step can
# act on the result (if expect_output ...; then ...).
# Needs output.sh (pass, fail).
# Sourced by test/run.sh; not run on its own.

# expect_output NAME PATTERN COMMAND...
# Runs COMMAND and passes if its output contains a line matching PATTERN.
expect_output() {
  local name="$1"
  local pattern="$2"
  shift 2

  local output
  output=$("$@" 2>&1)

  if echo "$output" | grep -qE -- "$pattern"; then
    pass "$name"
    return 0
  else
    fail "$name" "$(echo "$output" | tail -n 4)"
    return 1
  fi
}

# expect_no_output NAME PATTERN COMMAND...
# Runs COMMAND and passes if no line of its output matches PATTERN.
expect_no_output() {
  local name="$1"
  local pattern="$2"
  shift 2

  local output
  output=$("$@" 2>&1)

  if echo "$output" | grep -qE -- "$pattern"; then
    fail "$name" "$(echo "$output" | grep -E -- "$pattern" | head -n 4)"
    return 1
  else
    pass "$name"
    return 0
  fi
}

# expect_silence NAME COMMAND...
# Runs COMMAND and passes if it prints nothing at all (no warnings).
expect_silence() {
  local name="$1"
  shift

  local output
  output=$("$@" 2>&1)

  if [ -z "$output" ]; then
    pass "$name"
    return 0
  else
    fail "$name" "$output"
    return 1
  fi
}
