# shellcheck shell=bash
#
# Step 2: Build the image and start the test container.
# Sourced by test/run.sh; not run on its own.

section "2. Build and start"

if ! "${COMPOSE[@]}" up -d --build; then
  fail "image builds and container starts"
  exit 1
fi

if wait_until_running; then
  pass "dovecot and postfix running"
else
  fail "dovecot and postfix running" "$("${COMPOSE[@]}" logs --tail 20 mailbox 2>&1)"
  exit 1
fi

# supervisord's CRIT lines at startup (running as root, no auth on its
# local socket) are expected: they are not matched here.
expect_no_output "logs: no fatal, panic or error lines on startup" \
  '[Ff]atal|[Pp]anic|[Ee]rror' \
  "${COMPOSE[@]}" logs mailbox
