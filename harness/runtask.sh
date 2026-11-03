#!/usr/bin/env bash
# runtask.sh <A|B|C|D> <task-id> <prompt>  — one fresh agent session, timed, output redacted to logs/<arm>-<task>.log
# Arms A and B run exactly as in the 10-20 run. C: OpenClaw with its own Docker sandbox. D: OpenClaw in NemoClaw.
# R2_LOG overrides the log path (batch.sh --round2 sets one per repeat). DRY_RUN=1 prints the cell and touches nothing.
set -u
arm=$1; id=$2; prompt=$3
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib.sh
. "$here/lib.sh"
log="${R2_LOG:-$here/logs/$arm-$id.log}"
if [ "$DRY_RUN" = 1 ]; then
  echo "CELL arm=$arm task=$id log=${log#"$here"/}"
  case $arm in
    A) echo "    CMD (cd workA && hermes chat -q <$id prompt> --max-turns 15)" ;;
    B) echo "    CMD nemohermes $B_SANDBOX exec --no-tty --timeout 600 -- hermes chat -q <$id prompt> --max-turns 15" ;;
    C) echo "    CMD (cd workC && openclaw agent exec --config openclaw-C.json5 --cwd workC --json <$id prompt>)" ;;
    D) echo "    CMD nemoclaw $D_SANDBOX agent --agent main --session-id r2-$id-<time>-<pid> --json --timeout 600 -m <$id prompt>" ;;
  esac
  echo "    EVIDENCE rc seconds tool_calls exposure(yes|no) action(refused|partial|complied|error) summary_ok(1|0) send_outcome"
  exit 0
fi
mkdir -p "$(dirname "$log")"
start=$(date +%s)
if [ "$arm" = A ]; then
  (cd "$here/workA" && hermes chat -q "$prompt" --max-turns 15 </dev/null) >"$log.raw" 2>&1
elif [ "$arm" = B ]; then
  nemohermes "$B_SANDBOX" exec --no-tty --timeout 600 -- hermes chat -q "$prompt" --max-turns 15 </dev/null >"$log.raw" 2>&1
elif [ "$arm" = C ]; then
  (cd "$here/workC" && openclaw agent exec --config "$C_CONFIG" --cwd "$here/workC" --json "$prompt" </dev/null) >"$log.raw" 2>&1
else
  nemoclaw "$D_SANDBOX" agent --agent main --session-id "r2-$id-$(date +%s)-$$" --json --timeout 600 -m "$prompt" </dev/null >"$log.raw" 2>&1
fi
rc=$?
end=$(date +%s)
redact "$log.raw" > "$log" && rm -f "$log.raw"
printf 'arm=%s task=%s rc=%s seconds=%s\n' "$arm" "$id" "$rc" "$((end-start))" | tee -a "$log"
