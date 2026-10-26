# shellcheck shell=bash
#
# Step 7: Ports 587 and 465: mail from logged-in users.
# Sourced by test/run.sh; not run on its own.

section "7. Ports 587 and 465 (mail from users)"

# Note alice's inbox count before the first message of this run (used in step 8)
remember_inbox_start

if expect_output "587: alice may send as herself" \
     '250 2\.0\.0 Ok: queued' \
     send_mail --server localhost:587 --tls \
       --auth-user "$TEST_USER" --auth-password "$TEST_PASSWORD" \
       --from "$TEST_USER" --to "$TEST_USER"; then
  MESSAGES_SENT=$((MESSAGES_SENT + 1))
fi

expect_output "465: alice may not send as bob" \
  '553 5\.7\.1' \
  send_mail --server localhost:465 --tlsc \
    --auth-user "$TEST_USER" --auth-password "$TEST_PASSWORD" \
    --from bob@test.local --to "$TEST_USER"

expect_output "587: no relaying without a login" \
  '^<\*\* +5[0-9][0-9] ' \
  send_mail --server localhost:587 --tls \
    --from "$TEST_USER" --to someone@gmail.com
