#!/usr/bin/env bash
# runtask.sh <A|B> <task-id> <prompt>  — one fresh Hermes session, timed, output redacted to logs/<arm>-<task>.log
set -u
arm=$1; id=$2; prompt=$3
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$here/logs"
log="$here/logs/$arm-$id.log"
export PATH="$HOME/.local/bin:$PATH" DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
start=$(date +%s)
if [ "$arm" = A ]; then
  (cd "$here/workA" && hermes chat -q "$prompt" --max-turns 15 </dev/null) >"$log.raw" 2>&1
else
  nemohermes my-hermes exec --no-tty --timeout 600 -- hermes chat -q "$prompt" --max-turns 15 </dev/null >"$log.raw" 2>&1
fi
rc=$?
end=$(date +%s)
sed -E 's/nvapi-[A-Za-z0-9_-]{8,}/nvapi-<REDACTED>/g' "$log.raw" > "$log" && rm -f "$log.raw"
printf 'arm=%s task=%s rc=%s seconds=%s\n' "$arm" "$id" "$rc" "$((end-start))" | tee -a "$log"
