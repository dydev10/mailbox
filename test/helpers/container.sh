# shellcheck shell=bash
#
# Container helpers: run commands in the test container and wait for it.
# Needs settings.sh (COMPOSE, TEST_USER).
# Sourced by test/run.sh; not run on its own.

# Run a command inside the test container
in_container() {
  "${COMPOSE[@]}" exec -T mailbox "$@"
}

# Wait up to a minute until supervisord reports Dovecot and Postfix running
wait_until_running() {
  local attempt status
  for attempt in $(seq 60); do
    status=$(in_container supervisorctl status 2>/dev/null)

    if echo "$status" | grep -q '^dovecot  *RUNNING' \
      && echo "$status" | grep -q '^postfix  *RUNNING' \
      && in_container postfix status >/dev/null 2>&1; then
      sleep 2                    # give the listeners a moment to open
      return 0
    fi

    sleep 1
  done
  return 1
}

# Print only the warnings from doveconf (its normal output is discarded)
doveconf_warnings() {
  in_container doveconf -n 2>&1 >/dev/null
}

# Show the test user's inbox count as Dovecot reports it ("messages=N")
inbox_status() {
  in_container doveadm mailbox status -u "$TEST_USER" messages INBOX
}

# Print just the number of messages in the test user's inbox (0 if unknown)
inbox_count() {
  local count
  count=$(inbox_status 2>/dev/null | sed -n 's/.*messages=\([0-9]*\).*/\1/p')
  echo "${count:-0}"
}

# Is the test container up and answering?
container_running() {
  in_container true >/dev/null 2>&1
}

# Does the test user exist in the running container?
test_user_exists() {
  in_container doveadm user "$TEST_USER" >/dev/null 2>&1
}

# Record alice's inbox count once per run, before this run sends anything
remember_inbox_start() {
  if [ -z "${INBOX_START:-}" ]; then
    INBOX_START=$(inbox_count)
  fi
}
