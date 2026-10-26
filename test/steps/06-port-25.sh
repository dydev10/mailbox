# shellcheck shell=bash
#
# Step 6: Port 25: mail from other servers.
# Sourced by test/run.sh; not run on its own.

section "6. Port 25 (mail from other servers)"

# Note alice's inbox count before the first message of this run (used in step 8)
remember_inbox_start

if expect_output "mail to alice accepted" \
     '250 2\.0\.0 Ok: queued' \
     send_mail --server localhost:25 --from someone@gmail.com --to "$TEST_USER"; then
  MESSAGES_SENT=$((MESSAGES_SENT + 1))
fi

expect_output "mail to an unknown user refused" \
  '550 5\.1\.1' \
  send_mail --server localhost:25 --from someone@gmail.com --to nobody@test.local

expect_no_output "no AUTH offered" \
  '^<-  *250[- ]AUTH' \
  send_mail --server localhost:25 --quit-after EHLO

expect_output "VRFY refused" \
  '^502' \
  ask_vrfy
