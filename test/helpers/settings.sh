# shellcheck shell=bash
#
# Settings shared by the test scripts.
# Sourced by test/run.sh and test/clean.sh; not run on its own.

# Every docker compose call for the test uses this project name and override
COMPOSE=(docker compose -p mailbox-test -f compose.yaml -f test/compose.test.yaml)

# Throwaway data: certificate, Maildirs, database, relay secret (git-ignored)
DATA_DIR="test/.data"
CERT_DIR="$DATA_DIR/letsencrypt/live/mail.test.local"

# The one test account the run creates
TEST_USER="alice@test.local"
TEST_PASSWORD="testpass"
