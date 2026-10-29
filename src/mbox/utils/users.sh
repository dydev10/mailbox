#!/bin/bash
# List the mailboxes and aliases, for every domain or just one.
#
# Usage: mbox users [DOMAIN]
set -euo pipefail
. "$(dirname "$0")/common.sh"
[ $# -le 1 ] || die "usage: mbox users [DOMAIN]"

# Which rows to show: all (1 is always true), or one domain's
FILTER="1"
if [ $# -eq 1 ]; then
  DOMAIN=$(lowercase "$1")
  validate_domain "$DOMAIN" || die "not a domain name: $DOMAIN"
  FILTER="domain = '$DOMAIN'"
fi

# Each row comes back as email|receive|login
echo "Mailboxes:"
sql "SELECT email, receive, login FROM Mailbox WHERE $FILTER ORDER BY domain, localpart;" |
while IFS='|' read -r email receive login; do
  if   [ "$receive" = 0 ]; then note=" (disabled: no mail, no login)"
  elif [ "$login" = 0 ];   then note=" (login blocked)"
  else                          note=""
  fi
  echo "  $email$note"
done

# Each row comes back as alias|target
echo "Aliases:"
sql "SELECT localpart || '@' || domain, target FROM AliasTarget
     WHERE $FILTER AND target IS NOT NULL ORDER BY domain, localpart;" |
while IFS='|' read -r alias target; do
  echo "  $alias -> $target"
done
