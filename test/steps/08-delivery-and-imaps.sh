# shellcheck shell=bash
#
# Step 8: Every message accepted in this run is delivered and visible over IMAPS.
# Sourced by test/run.sh; not run on its own.

section "8. Delivery and IMAPS (993)"

# Every message accepted in this run (steps 6 and 7) must reach alice's inbox.
# When step 8 runs on its own, nothing was sent, so the count must not change.
remember_inbox_start
expected_messages=$((INBOX_START + MESSAGES_SENT))

# Delivery takes a moment: wait up to 30 seconds for the count to arrive
for attempt in $(seq 30); do
  if [ "$(inbox_count)" -eq "$expected_messages" ]; then break; fi
  sleep 1
done

expect_output "inbox holds $expected_messages messages ($MESSAGES_SENT sent in this run)" \
  "messages=$expected_messages\$" \
  inbox_status

expect_output "IMAPS login sees the same $expected_messages messages" \
  "MESSAGES $expected_messages\\)" \
  curl --silent --insecure --max-time 20 \
    --user "$TEST_USER:$TEST_PASSWORD" \
    --request 'STATUS INBOX (MESSAGES)' 'imaps://localhost/'

# curl exits with 67 when the server refuses the login
expect_output "IMAPS wrong password refused" \
  'exit=67' \
  sh -c "curl --silent --insecure --max-time 20 --user '$TEST_USER:wrong' \
           --request 'STATUS INBOX (MESSAGES)' 'imaps://localhost/'; echo exit=\$?"
