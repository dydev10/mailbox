# shellcheck shell=bash
#
# Step 4: Add the test domain and user alice (safe to repeat).
# Sourced by test/run.sh; not run on its own.

section "4. Test user"

# Hash the password inside the container, then add the domain, address and
# mailbox. INSERT OR IGNORE keeps existing rows, so rerunning the step is safe.
password_hash=$(in_container doveadm pw -s SHA512-CRYPT -p "$TEST_PASSWORD")

in_container sqlite3 /etc/mailsql/mail.sqlite <<SQL
INSERT OR IGNORE INTO Domain (name, class, uid) VALUES ('test.local', 'mailbox', 5000);

INSERT OR IGNORE INTO Address (localpart, domain)
  SELECT 'alice', id FROM Domain WHERE name = 'test.local';

INSERT OR IGNORE INTO VMailbox (id, password)
  SELECT A.id, '$password_hash'
  FROM Address A JOIN Domain D ON D.id = A.domain
  WHERE A.localpart = 'alice' AND D.name = 'test.local';
SQL

expect_output "alice in the Mailbox view (receive=1, login=1)" \
  '^alice@test\.local\|1\|1$' \
  in_container sqlite3 /etc/mailsql/mail.sqlite "SELECT email, receive, login FROM Mailbox"
