# shellcheck shell=bash
#
# Step 3: Postfix and Dovecot configuration has no warnings.
# Sourced by test/run.sh; not run on its own.

section "3. Configuration"

expect_silence "postfix check: no warnings"  in_container postfix check
expect_silence "doveconf -n: no warnings"    doveconf_warnings
