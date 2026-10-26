# shellcheck shell=bash
#
# Step 5: Dovecot finds alice and accepts her password.
# Sourced by test/run.sh; not run on its own.

section "5. Dovecot lookups"

expect_output "userdb: home /home/vmail/test.local/alice" \
  'home[[:space:]]+/home/vmail/test\.local/alice' \
  in_container doveadm user "$TEST_USER"

expect_output "userdb: uid 5000" \
  'uid[[:space:]]+5000' \
  in_container doveadm user "$TEST_USER"

expect_output "passdb: password accepted" \
  'auth succeeded' \
  in_container doveadm auth test "$TEST_USER" "$TEST_PASSWORD"
