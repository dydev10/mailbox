# shellcheck shell=bash
#
# Mail helpers: talk to the server's mail ports from this machine.
# Sourced by test/run.sh; not run on its own.

# Send one test message with swaks; all options are passed through
send_mail() {
  swaks --timeout 30 "$@" 2>&1
}

# Ask port 25 whether an address exists (VRFY) and print the server's reply
ask_vrfy() {
  local line

  # Open a TCP connection on file descriptor 3
  exec 3<>/dev/tcp/127.0.0.1/25 || return 1

  # Read the greeting; it may span several "220-" lines and ends with "220 "
  while IFS= read -r -t 30 line <&3; do
    if [[ "$line" == "220 "* ]]; then break; fi
  done

  printf 'EHLO test.example\r\n' >&3
  while IFS= read -r -t 30 line <&3; do
    if [[ "$line" == "250 "* ]]; then break; fi
  done

  printf 'VRFY alice\r\n' >&3
  IFS= read -r -t 30 line <&3
  echo "$line"

  printf 'QUIT\r\n' >&3
  exec 3<&-                      # close the connection
}
