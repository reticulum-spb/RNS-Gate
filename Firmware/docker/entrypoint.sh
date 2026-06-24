#!/bin/bash
# Runs as root to make the persistent build volume and the bind-mounted
# output directory writable by the unprivileged build user, then drops
# privileges. br2_external stays read-only and is never chowned.
set -euo pipefail

chown br:br /build || true
mkdir -p /build/out
chown br:br /build/out || true

exec gosu br /usr/local/bin/build.sh "$@"
