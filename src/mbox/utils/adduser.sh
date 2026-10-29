#!/bin/bash
# Add a mailbox: pick a domain from the list, type the user name, then the
# password (asked twice).
#
# Usage (needs a terminal: docker exec -it): mbox adduser
set -euo pipefail
. "$(dirname "$0")/common.sh"

# 1. Pick a domain from the ones in the database
mapfile -t DOMAINS < <(sql "SELECT name FROM Domain WHERE class = 'mailbox' ORDER BY name;")
[ "${#DOMAINS[@]}" -gt 0 ] || die "no domains yet; run: mbox seed DOMAIN"

echo "Domains:"
for i in "${!DOMAINS[@]}"; do
  echo "  $((i + 1))) ${DOMAINS[$i]}"
done
read -r -p "Domain number: " n
[[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#DOMAINS[@]}" ] \
  || die "no domain number $n"
DOMAIN=${DOMAINS[$((n - 1))]}

# 2. The user name: the part before the @
read -r -p "User name (the part before @$DOMAIN): " USERNAME
USERNAME=$(lowercase "$USERNAME")
validate_localpart "$USERNAME" || die "not a user name: $USERNAME"
EMAIL=$USERNAME@$DOMAIN
[ "$(sql "SELECT count(*) FROM Address A JOIN Domain D ON D.id = A.domain
          WHERE A.localpart = '$USERNAME' AND D.name = '$DOMAIN';")" = 0 ] \
  || die "$EMAIL already exists"

# 3. The password
ask_password "$EMAIL"

# The address, then its mailbox (same id), both or neither
sql <<SQL
BEGIN;
INSERT INTO Address (localpart, domain) SELECT '$USERNAME', id FROM Domain WHERE name = '$DOMAIN';
INSERT INTO VMailbox (id, password) VALUES (last_insert_rowid(), '$HASH');
COMMIT;
SQL
echo "Created $EMAIL."
