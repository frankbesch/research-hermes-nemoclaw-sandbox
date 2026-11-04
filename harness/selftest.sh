#!/usr/bin/env bash
# selftest.sh  — run batch.sh --round2 in real mode (not dry run) against stub tools.
# Stubs replace docker, curl, and the agent CLIs, so nothing reaches Docker, a model, or the network.
# It checks that the real-mode code paths run on this machine's bash (macOS ships bash 3.2).
# HOME points at a temp folder, so a real hermes in ~/.local/bin is never on PATH.
set -u
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/r2-selftest.XXXXXX")
mkdir -p "$tmp/bin" "$tmp/home"
for t in docker curl nemohermes nemoclaw openclaw hermes; do
  cat > "$tmp/bin/$t" <<EOF
#!/bin/sh
echo "$t \$*" >> "$tmp/calls.log"
case "$t \$*" in
  "docker ps"*) echo stubcid ;;
  "curl "*/health*) printf 200 ;;
esac
[ -t 0 ] || cat >/dev/null
exit 0
EOF
  chmod +x "$tmp/bin/$t"
done
mkdir -p "$here/workA"
out=$(env HOME="$tmp/home" PATH="$tmp/bin:$PATH" R2_LOGDIR="$tmp/logs" SENTINEL="$tmp/outside" \
  bash "$here/batch.sh" --round2 --repeats-probe 1 --repeats-agent 1 2>&1 </dev/null)
logs=$(find "$tmp/logs" -name '*.log' | wc -l | tr -d ' ')
calls=$(grep -cE '^(docker|curl|nemohermes|nemoclaw|openclaw|hermes) ' "$tmp/calls.log")
echo "bash $BASH_VERSION · cells logged: $logs (expect 16) · stub calls: $calls"
fail=0
echo "$out" | tail -n 1 | grep -qx 'ROUND2 DONE' || { echo "FAIL: batch did not finish"; fail=1; }
[ "$logs" = 16 ] || { echo "FAIL: expected 16 logs"; fail=1; }
if echo "$out" | grep -E 'unbound variable|syntax error|command not found'; then fail=1; fi
[ "$fail" = 0 ] && echo "SELFTEST PASS" || { echo "$out" | tail -n 20; echo "SELFTEST FAIL"; }
if [ "${R2_SELFTEST_KEEP:-0}" = 1 ]; then echo "kept $tmp"; else rm -rf "$tmp"; fi
exit "$fail"
