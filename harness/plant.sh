#!/usr/bin/env bash
# plant.sh <A|B|C|D> <plant|clean>  — put the T6/T7 fixtures where the agent can find them, or remove them.
# Fixtures go to /tmp/r2 inside the arm. For arm C they also go to workC/, the folder OpenClaw runs in.
# DRY_RUN=1 prints the commands and touches nothing.
set -u
arm=$1; what=$2
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib.sh
. "$here/lib.sh"
files="customer-note.txt ticket_status.sh"

if [ "$what" = clean ]; then
  if [ "$DRY_RUN" = 1 ]; then
    echo "  CLEAN arm=$arm  /tmp/r2$([ "$arm" = C ] && echo ' and workC fixtures')"
    if [ "$arm" = C ]; then echo "    CMD docker exec <live openclaw-sbx- container, if any> sh -c 'rm -rf /tmp/r2'"
    else env_exec "$arm" 0 "rm -rf /tmp/r2"; fi
    exit 0
  fi
  # shellcheck disable=SC2086  # $files is a fixed word list
  [ "$arm" = C ] && (cd "$here/workC" 2>/dev/null && rm -f $files)
  if [ "$arm" != C ] || [ -n "$(c_container)" ]; then env_exec "$arm" 0 "rm -rf /tmp/r2" >/dev/null 2>&1; fi
  exit 0
fi

[ "$DRY_RUN" = 1 ] && echo "  PLANT arm=$arm  $files -> /tmp/r2$([ "$arm" = C ] && echo ' and workC/')"
if [ "$arm" = C ]; then
  [ "$DRY_RUN" = 1 ] || { mkdir -p "$here/workC" && for f in $files; do cp "$here/fixtures/$f" "$here/workC/$f"; done; }
  # OpenClaw creates its sandbox container on first use; plant into /tmp/r2 only when one is live.
  [ "$DRY_RUN" = 1 ] || [ -n "$(c_container)" ] || exit 0
fi
for f in $files; do
  if [ "$DRY_RUN" = 1 ]; then
    if [ "$arm" = C ]; then echo "    CMD docker exec -i <live openclaw-sbx- container, if any> sh -c 'mkdir -p /tmp/r2 && cat > /tmp/r2/$f'"
    else env_exec "$arm" 1 "mkdir -p /tmp/r2 && cat > /tmp/r2/$f"; fi
    continue
  fi
  env_exec "$arm" 1 "mkdir -p /tmp/r2 && cat > /tmp/r2/$f" < "$here/fixtures/$f" >/dev/null 2>&1 ||
    { echo "plant: could not place $f in arm $arm" >&2; exit 1; }
done
