# shellcheck shell=bash
# common.sh: helpers shared by the mbox scripts.
# Loaded with ". common.sh" at the top of each script, not run on its own.

# The database; DB=/path/to/copy.sqlite tries a command on a copy first
DB=${DB:-/etc/mailsql/mail.sqlite}

# Print an error and stop
die() { echo "mbox: $*" >&2; exit 1; }

# Run SQL on the database (-batch: no "Loading resources" line in a terminal)
sql() { sqlite3 -batch -bail "$DB" "$@"; }

lowercase() { printf %s "$1" | tr 'A-Z' 'a-z'; }

# Checks for names typed by the admin. Names go straight into the SQL,
# so only plain characters are allowed.

# A user name (the part before the @)
validate_localpart() { echo "$1" | grep -Eq '^[a-z0-9][a-z0-9._-]*$'; }

# A domain name: letters, digits and hyphens, with at least one dot
validate_domain() {
  echo "$1" | grep -Eq '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$'
}

# A plain address (user@domain)
validate_email() { echo "$1" | grep -Eq '^[a-z0-9._+-]+@[a-z0-9.-]+$'; }

# Ask twice for a new password for address $1; sets HASH to its hash.
# The password is never shown or stored.
ask_password() {
  local password again          # only inside this function
  read -r -s -p "New password for $1: " password; echo
  read -r -s -p "Same again: " again; echo
  [ "$password" = "$again" ] || die "the two entries differ"
  [ "${#password}" -ge 12 ]  || die "use at least 12 characters"
  HASH=$(doveadm pw -s SHA512-CRYPT -p "$password")
}
