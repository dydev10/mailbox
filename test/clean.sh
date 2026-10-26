#!/usr/bin/env bash
#
# Stops the local test container and deletes its data in test/.data.
#
# The files in test/.data belong to users inside the container (vmail, root),
# so a plain "rm" on this machine would need sudo. A throwaway container
# deletes them instead.
#
# Usage (from anywhere):  bash test/clean.sh

set -euo pipefail
cd "$(dirname "$0")/.."          # work from the repo root

source test/helpers/settings.sh     # COMPOSE, DATA_DIR

# Compose refuses to run if the secret file it names is missing
mkdir -p "$DATA_DIR"
touch "$DATA_DIR/relay_sasl"

# Stop and remove the test container
"${COMPOSE[@]}" down --remove-orphans

# Delete everything inside test/.data, then the empty folder itself
docker run --rm \
  --volume "$PWD/$DATA_DIR:/data" \
  ubuntu:24.04 \
  sh -c 'rm -rf /data/* /data/.[!.]* 2>/dev/null; true'
rmdir "$DATA_DIR"
