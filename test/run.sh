#!/usr/bin/env bash
#
# Local end-to-end test for the mail server image.
#
# Builds the image, starts a throwaway container (project "mailbox-test",
# domain test.local, self-signed certificate), adds one test user and checks
# every port. Prints PASS or FAIL for each check and exits with an error if
# any check failed. The container is left running so you can look around;
# "bash test/clean.sh" removes it and its data.
#
# Needs on this machine: docker (with Compose 2.24 or later), swaks, openssl
# and curl, and nothing else listening on ports 25, 465, 587 or 993.
#
# Usage (from anywhere):
#   bash test/run.sh           run every step, starting from nothing
#   bash test/run.sh 6 7 8     run only these steps, against the test container
#                              left running by an earlier full run
#   bash test/run.sh 2 6 7     rebuild the image first (step 2), then steps 6 and 7
#
# The steps are the numbered files in test/steps/; the functions they use are
# in test/helpers/.

set -uo pipefail                 # no "set -e": a failed check must not stop the run
cd "$(dirname "$0")/.."          # work from the repo root

source test/helpers/settings.sh
source test/helpers/output.sh
source test/helpers/checks.sh
source test/helpers/container.sh
source test/helpers/mail.sh

# Messages accepted for the test user during this run (steps 6 and 7 add to
# it; step 8 checks they all arrived)
MESSAGES_SENT=0

# --- Choose the steps -------------------------------------------------------------

selected_steps=()

if [ $# -eq 0 ]; then
  # No arguments: every step, in order
  selected_steps=(test/steps/[0-9][0-9]-*.sh)
else
  for number in "$@"; do
    if ! [[ "$number" =~ ^[0-9]+$ ]]; then
      echo "Not a step number: $number" >&2
      exit 1
    fi

    # 6 -> test/steps/06-*.sh
    step_file=$(ls test/steps/"$(printf '%02d' "$((10#$number))")"-*.sh 2>/dev/null)
    if [ -z "$step_file" ]; then
      echo "No step $number in test/steps/" >&2
      exit 1
    fi
    selected_steps+=("$step_file")
  done
fi

# --- Running only some steps needs what the full run set up -------------------------

# Step 1 starts from nothing, so it needs nothing. Without it, the container
# must already be running, and without step 4 the test user must already exist.
selection="${selected_steps[*]}"

if [[ "$selection" != *"/01-"* ]]; then
  if ! container_running; then
    echo "The test container isn't running. Run the full test first: bash test/run.sh" >&2
    exit 1
  fi

  if [[ "$selection" != *"/04-"* ]] && ! test_user_exists; then
    echo "The test user doesn't exist yet. Run the full test first: bash test/run.sh" >&2
    exit 1
  fi
fi

# --- Run them ---------------------------------------------------------------------

for step_file in "${selected_steps[@]}"; do
  source "$step_file"
done

print_summary
