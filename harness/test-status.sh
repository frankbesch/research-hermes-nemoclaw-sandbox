#!/usr/bin/env bash
# test-status.sh  — regression test for run_status (lib.sh). No Docker, model, or network.
# 1. The 120 round-2 agent logs: exactly the 7 runs that SCORING.md's 2026-11-04 amendment
#    codes as stopped by HTTP 429 must be rate_limited; every other run must be ok
#    (B-T5-r9 and B-T7-r9 hit a 429 on a side call and still answered).
# 2. Synthetic cases for patterns round 2 never produced, chiefly OpenClaw failures.
set -u
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib.sh
. "$here/lib.sh"
logs="$here/../logs/round2"
fail=0
expect() {  # expect <arm> <file> <status>
  local got; got=$(run_status "$1" "$2")
  if [ "$got" != "$3" ]; then echo "FAIL $(basename "$2"): got $got, want $3"; fail=1; fi
}

limited=" B-T5-r8 B-T6-r8 B-T6-r9 B-T6-r10 B-T7-r7 B-T7-r8 B-T7-r10 "
n=0
for f in "$logs"/[ABCD]-T*-r*.log; do
  cell=$(basename "$f" .log); arm=${cell%%-*}
  case $limited in *" $cell "*) want=rate_limited ;; *) want=ok ;; esac
  expect "$arm" "$f" "$want"; n=$((n+1))
done
[ "$n" = 120 ] || { echo "FAIL: expected 120 round-2 logs, found $n"; fail=1; }
for f in "$logs"/supplement-429/*.a1.log; do expect B "$f" ok; done

t=$(mktemp -d "${TMPDIR:-/tmp}/r2-status.XXXXXX")
printf 'x\n' > "$t/empty"
printf ' \xe2\x94\x80  \xe2\x98\xa4 Hermes  \xe2\x94\x80\n API call failed after 3 retries: HTTP 500: boom\n' > "$t/h500"
printf '[model-fetch] response provider=nvidia status=429 elapsedMs=12\n{\n  "ok": false,\n  "final": ""\n}\n' > "$t/c429"
printf '{\n  "status": "error",\n  "error": { "message": "Too Many Requests" }\n}\n' > "$t/d429"
printf '{\n  "status": "ok",\n  "sessionId": "r2-T7-1793748542-95429",\n  "result": { "payloads": [ { "text": "Ticket is open." } ] }\n}\n' > "$t/dok"
expect A "$t/empty" no_answer
expect B "$t/h500" api_error
expect C "$t/empty" no_answer
expect C "$t/c429" rate_limited
expect D "$t/d429" rate_limited
expect D "$t/dok" ok
rm -rf "$t"

[ "$fail" = 0 ] && echo "STATUS TEST PASS ($n round-2 logs, 7 rate_limited)" || echo "STATUS TEST FAIL"
exit "$fail"
