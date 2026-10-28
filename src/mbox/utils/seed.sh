#!/bin/sh
# Seed a new domain: admin@ and test@ mailboxes with random passwords that
# nobody knows, plus postmaster@ and abuse@ aliases to the admin.
# Then set the real passwords with "mbox passwd". Safe to run again:
# existing rows are kept as they are.
#
# Usage: mbox seed DOMAIN [ADMIN_LOCALPART]
#   DB=/path/to/copy.sqlite mbox seed ...   to try it on a copy first
set -eu
[ $# -ge 1 ] && [ $# -le 2 ] || { echo "usage: mbox seed DOMAIN [ADMIN]" >&2; exit 1; }
DOMAIN=$(printf %s "$1" | tr 'A-Z' 'a-z')
ADMIN=$(printf %s "${2:-admin}" | tr 'A-Z' 'a-z')
DB=${DB:-/etc/mailsql/mail.sqlite}
SEED_SQL=${SEED_SQL:-$(dirname "$0")/seed.sql}

# Only plain names: they go straight into the SQL
echo "$DOMAIN" | grep -Eq '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$' \
  || { echo "mbox seed: not a domain name: $DOMAIN" >&2; exit 1; }
echo "$ADMIN" | grep -Eq '^[a-z0-9][a-z0-9._-]*$' \
  || { echo "mbox seed: not a local part: $ADMIN" >&2; exit 1; }
case $ADMIN in
  test|postmaster|abuse) echo "mbox seed: the admin mailbox cannot be $ADMIN@" >&2; exit 1 ;;
esac

# A password nobody knows: 24 random bytes, hashed, and never shown
random_hash() {
  doveadm pw -s SHA512-CRYPT -p "$(head -c 24 /dev/urandom | base64)"
}
ADMIN_HASH=$(random_hash)
TEST_HASH=$(random_hash)

sed -e "s|@DOMAIN@|$DOMAIN|g" -e "s|@ADMIN@|$ADMIN|g" \
    -e "s|@ADMIN_HASH@|$ADMIN_HASH|g" -e "s|@TEST_HASH@|$TEST_HASH|g" \
    "$SEED_SQL" | sqlite3 -bail "$DB"

echo
echo "Seeded $DOMAIN. The passwords are random and unknown; set them with:"
echo "  mbox passwd $ADMIN@$DOMAIN"
echo "  mbox passwd test@$DOMAIN"
