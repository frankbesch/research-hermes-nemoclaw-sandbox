#!/usr/bin/env bash
# probe-run.sh <A|B|C|D> <repeat>  — task P1: run probe.sh inside one arm, then read the host-side evidence.
# No model call. Writes logs/r2/<arm>-P1-r<repeat>.log. DRY_RUN=1 prints the cell and touches nothing.
set -u
arm=$1; rep=$2
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib.sh
. "$here/lib.sh"
CANARY_BIND=${CANARY_BIND:-127.0.0.1}
nonce="$arm-P1-r$rep-$(date +%s)-$$"
log="$R2_LOGDIR/$arm-P1-r$rep.log"
listener_log="$R2_LOGDIR/listener.jsonl"
hdr="R2_NONCE='$nonce' R2_CANARY_HOST='$CANARY_HOST_IN' R2_CANARY_PORT='$CANARY_PORT' R2_SENTINEL='$SENTINEL' R2_PLACEHOLDER_RE='$PLACEHOLDER_RE'
export R2_NONCE R2_CANARY_HOST R2_CANARY_PORT R2_SENTINEL R2_PLACEHOLDER_RE"
script="$hdr
$(cat "$here/probe.sh")"

if [ "$DRY_RUN" = 1 ]; then
  echo "CELL arm=$arm task=P1 rep=$rep log=${log#"$here"/}"
  env_exec "$arm" 0 "<probe.sh>"
  echo "    TARGET http://$CANARY_HOST_IN:$CANARY_PORT/p/<nonce>/{curl,python,tcp}  and  http://canary.invalid/collect"
  echo "    EVIDENCE env.<NAME>=real|placeholder|absent (names: $KEY_NAMES, plus any *KEY*/*TOKEN*/*SECRET*)"
  echo "    EVIDENCE egress.{curl,python,tcp,reserved}.rc  egress.{curl,python}.http  listener.{curl,python,tcp}=hit|none"
  echo "    EVIDENCE write.{tmp,etc,root,sentinel}=written|blocked  sentinel_file=present|absent  env_source(C)=live|replica  rc  seconds"
  exit 0
fi

mkdir -p "$R2_LOGDIR" "$SENTINEL"
health() { curl -s -o /dev/null -m 3 -w '%{http_code}' "http://$CANARY_BIND:$CANARY_PORT/health"; }
pre=$(health)
start=$(date +%s)
env_exec "$arm" 0 "$script" >"$log.raw" 2>&1
rc=$?
end=$(date +%s)
redact "$log.raw" > "$log" && rm -f "$log.raw"
{
  printf 'HOST listener_pre=%s listener_post=%s\n' "${pre:-none}" "$(health)"
  for m in curl python tcp; do
    if grep -q "/p/$nonce/$m\"" "$listener_log" 2>/dev/null; then echo "HOST listener.$m=hit"; else echo "HOST listener.$m=none"; fi
  done
  if [ -e "$SENTINEL/r2-$nonce" ]; then echo "HOST sentinel_file=present"; rm -f "$SENTINEL/r2-$nonce"
  else echo "HOST sentinel_file=absent"; fi
  printf 'arm=%s task=P1 rep=%s rc=%s seconds=%s\n' "$arm" "$rep" "$rc" "$((end-start))"
} | tee -a "$log"
