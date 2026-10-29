#!/bin/bash
# Set a new password for a mailbox (also the "forgot password" fix).
#
# Usage (needs a terminal: docker exec -it): mbox passwd USER@DOMAIN
set -euo pipefail
. "$(dirname "$0")/common.sh"
[ $# -eq 1 ] || die "usage: mbox passwd USER@DOMAIN"
EMAIL=$(lowercase "$1")

# Only plain addresses: it goes straight into the SQL
validate_email "$EMAIL" || die "not an address: $EMAIL"
[ "$(sql "SELECT count(*) FROM Mailbox WHERE email = '$EMAIL';")" = 1 ] || die "no mailbox $EMAIL"

ask_password "$EMAIL"
sql "UPDATE VMailbox SET password = '$HASH' WHERE id = (SELECT id FROM Mailbox WHERE email = '$EMAIL');"
echo "Password changed for $EMAIL."
