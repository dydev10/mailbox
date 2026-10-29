#!/bin/bash
# Seed a new domain: admin@ and test@ mailboxes with random passwords that
# nobody knows, plus postmaster@ and abuse@ aliases to the admin.
# Then set the real passwords with "mbox passwd". Safe to run again:
# existing rows are kept as they are.
#
# Usage: mbox seed DOMAIN [ADMIN_LOCALPART]
set -euo pipefail
. "$(dirname "$0")/common.sh"
[ $# -ge 1 ] && [ $# -le 2 ] || die "usage: mbox seed DOMAIN [ADMIN]"
DOMAIN=$(lowercase "$1")
ADMIN=$(lowercase "${2:-admin}")
SEED_SQL=${SEED_SQL:-$(dirname "$0")/seed.sql}

# Only plain names: they go straight into the SQL
validate_domain "$DOMAIN" || die "not a domain name: $DOMAIN"
validate_localpart "$ADMIN" || die "not a user name: $ADMIN"
case $ADMIN in
  test|postmaster|abuse) die "the admin mailbox cannot be $ADMIN@" ;;
esac

# A password nobody knows: 24 random bytes, hashed, and never shown
random_hash() {
  doveadm pw -s SHA512-CRYPT -p "$(head -c 24 /dev/urandom | base64)"
}
ADMIN_HASH=$(random_hash)
TEST_HASH=$(random_hash)

sed -e "s|@DOMAIN@|$DOMAIN|g" -e "s|@ADMIN@|$ADMIN|g" \
    -e "s|@ADMIN_HASH@|$ADMIN_HASH|g" -e "s|@TEST_HASH@|$TEST_HASH|g" \
    "$SEED_SQL" | sql

echo
echo "Seeded $DOMAIN. The passwords are random and unknown; set them with:"
echo "  mbox passwd $ADMIN@$DOMAIN"
echo "  mbox passwd test@$DOMAIN"
