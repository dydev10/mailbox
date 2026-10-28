#!/bin/bash
# Set a new password for a mailbox (also the "forgot password" fix).
# Asks twice; the password is never shown or stored, only its hash.
#
# Usage (needs a terminal: docker exec -it): mbox passwd USER@DOMAIN
set -euo pipefail
[ $# -eq 1 ] || { echo "usage: mbox passwd USER@DOMAIN" >&2; exit 1; }
EMAIL=$(printf %s "$1" | tr 'A-Z' 'a-z')
DB=${DB:-/etc/mailsql/mail.sqlite}

# Only plain addresses: it goes straight into the SQL
echo "$EMAIL" | grep -Eq '^[a-z0-9._+-]+@[a-z0-9.-]+$' \
  || { echo "mbox passwd: not an address: $EMAIL" >&2; exit 1; }
[ "$(sqlite3 -batch "$DB" "SELECT count(*) FROM Mailbox WHERE email = '$EMAIL';")" = 1 ] \
  || { echo "mbox passwd: no mailbox $EMAIL" >&2; exit 1; }

read -r -s -p "New password for $EMAIL: " password; echo
read -r -s -p "Same again: " again; echo
[ "$password" = "$again" ] || { echo "mbox passwd: the two entries differ" >&2; exit 1; }
[ "${#password}" -ge 12 ]  || { echo "mbox passwd: use at least 12 characters" >&2; exit 1; }

HASH=$(doveadm pw -s SHA512-CRYPT -p "$password")
sqlite3 -batch -bail "$DB" "UPDATE VMailbox SET password = '$HASH' WHERE id = (SELECT id FROM Mailbox WHERE email = '$EMAIL');"
echo "Password changed for $EMAIL."
