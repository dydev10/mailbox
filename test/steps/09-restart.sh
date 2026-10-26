# shellcheck shell=bash
#
# Step 9: Two restarts leave the generated files clean.
# Sourced by test/run.sh; not run on its own.

section "9. Restart twice"

restarts_ok=yes
for round in 1 2; do
  if ! "${COMPOSE[@]}" restart >/dev/null 2>&1 || ! wait_until_running; then
    restarts_ok=no
  fi
done

if [ "$restarts_ok" = yes ]; then
  pass "two restarts"
else
  fail "two restarts"
fi

# Files the entrypoint writes must hold each entry once, however often it runs
expect_output "99-generated.conf: one lmtp block" \
  '^1$' \
  in_container grep -c '^protocol lmtp' /etc/dovecot/conf.d/99-generated.conf

expect_output "main.cf: one relayhost line" \
  '^1$' \
  in_container grep -c '^relayhost' /etc/postfix/main.cf

expect_output "vmail_ssl.map: one line per hostname" \
  '^1$' \
  in_container grep -c . /etc/postfix/vmail_ssl.map
