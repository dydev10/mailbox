# shellcheck shell=bash
#
# Step 1: Setup: tools, a clean start, the test certificate and folders.
# Sourced by test/run.sh; not run on its own.

section "1. Setup"

for tool in docker swaks openssl curl; do
  if ! command -v "$tool" >/dev/null; then
    echo "Missing on this machine: $tool" >&2
    exit 1
  fi
done

# Always start from nothing: remove the previous test container and its data
if [ -d "$DATA_DIR" ]; then
  bash test/clean.sh >/dev/null 2>&1
fi

mkdir -p "$CERT_DIR" "$DATA_DIR/vmail" "$DATA_DIR/mailsql"
openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
  -subj "/CN=mail.test.local" \
  -keyout "$CERT_DIR/privkey.pem" \
  -out "$CERT_DIR/fullchain.pem" 2>/dev/null
touch "$DATA_DIR/relay_sasl"     # empty relay login: nothing is relayed in this test
pass "self-signed certificate and test folders in $DATA_DIR"
