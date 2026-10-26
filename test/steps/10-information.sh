# shellcheck shell=bash
#
# Step 10: Facts shown for information only (not checks).
# Sourced by test/run.sh; not run on its own.

section "10. For information"

spamhaus_answer=$(in_container getent hosts 2.0.0.127.zen.spamhaus.org | awk '{print $1}' | head -n 1)
note "Spamhaus from here: ${spamhaus_answer:-no answer}"
note "(127.0.0.x = answering; 127.255.255.254 or no answer = refused, expected on a laptop)"
