#!/bin/sh
# Usage: passwd-vmaps-to-sql.sh passwd vmaps   (called by import-legacy.sh)
# Turns the old .domains.env files into INSERTs for two staging tables.
# Skips comments and blank lines, lower-cases addresses, escapes quotes.
q() { sed "s/'/''/g"; }
echo "CREATE TEMP TABLE import_passwd (email TEXT PRIMARY KEY, password TEXT);"
echo "CREATE TEMP TABLE import_vmaps  (email TEXT PRIMARY KEY);"
grep -v '^[[:space:]]*#' "$1" | grep ':' | while IFS=: read -r email pass _rest; do
  printf "INSERT OR REPLACE INTO import_passwd VALUES ('%s', '%s');\n" \
    "$(printf %s "$email" | tr 'A-Z' 'a-z' | q)" "$(printf %s "$pass" | q)"
done
grep -v '^[[:space:]]*#' "$2" | awk 'NF >= 1 {print tolower($1)}' | while read -r email; do
  printf "INSERT OR IGNORE INTO import_vmaps VALUES ('%s');\n" "$(printf %s "$email" | q)"
done