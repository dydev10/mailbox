#!/bin/sh
# Import users from the old .domains.env files (passwd, vmaps) into SQLite.
# Usage: import-legacy.sh DIR [admin@domain]
#   DIR   folder holding the old passwd and vmaps files
#   DB=/path/to/copy.sqlite import-legacy.sh ...   for a dry run on a copy
# Safe to run more than once: existing rows are kept, new ones added.
set -eu
DIR=${1:?usage: import-legacy.sh DIR [admin@domain]}
ADMIN=${2:-}
DB=${DB:-/etc/mailsql/mail.sqlite}
HERE=$(dirname "$0")

[ -r "$DIR/passwd" ] && [ -r "$DIR/vmaps" ] || { echo "need $DIR/passwd and $DIR/vmaps" >&2; exit 1; }

{ "$HERE/passwd-vmaps-to-sql.sh" "$DIR/passwd" "$DIR/vmaps"; cat "$HERE/migrate.sql"; } | sqlite3 "$DB"

if [ -n "$ADMIN" ]; then
  case $ADMIN in *@*) ;; *) echo "admin must be user@domain" >&2; exit 1 ;; esac
  lp=$(printf %s "${ADMIN%@*}" | tr 'A-Z' 'a-z' | sed "s/'/''/g")
  dom=$(printf %s "${ADMIN##*@}" | tr 'A-Z' 'a-z' | sed "s/'/''/g")
  sed -e "s|@ADMIN_LOCALPART@|$lp|g" -e "s|@ADMIN_DOMAIN@|$dom|g" "$HERE/postmaster.sql" | sqlite3 "$DB"
fi