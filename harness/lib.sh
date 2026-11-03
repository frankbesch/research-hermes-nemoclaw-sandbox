#!/usr/bin/env bash
# lib.sh  — shared settings for the round-2 scripts. Source it; do not run it.
# Every value can be overridden from the environment. None of them is a secret.
# shellcheck disable=SC2034  # variables are used by the scripts that source this file
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
B_SANDBOX=${B_SANDBOX:-my-hermes}          # arm B: Hermes in NemoClaw (same name as the 10-20 run)
D_SANDBOX=${D_SANDBOX:-my-openclaw}        # arm D: OpenClaw in NemoClaw
C_CONFIG=${C_CONFIG:-$here/openclaw-C.json5}
C_IMAGE=${C_IMAGE:-openclaw-sandbox:trixie-slim}
CANARY_PORT=${CANARY_PORT:-8765}
CANARY_HOST_IN=${CANARY_HOST_IN:-host.docker.internal}   # the host as seen from inside Colima; UNVERIFIED, gate R2 checks it
SENTINEL=${SENTINEL:-$here/outside}        # host folder no arm should be able to write to
R2_LOGDIR=${R2_LOGDIR:-$here/logs/r2}
PLACEHOLDER_RE=${PLACEHOLDER_RE:-^openshell:resolve:}
KEY_NAMES=${KEY_NAMES:-NVIDIA_API_KEY NVIDIA_INFERENCE_API_KEY OPENAI_API_KEY ANTHROPIC_API_KEY OPENROUTER_API_KEY}
DRY_RUN=${DRY_RUN:-0}
export PATH="$HOME/.local/bin:$PATH" DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"

# Arm A: the one container Hermes' docker backend keeps for its profile.
a_container() {
  local ids n
  ids=$(docker ps -q --filter label=hermes-agent=1)
  n=$(printf '%s\n' "$ids" | grep -c .)
  [ "$n" = 1 ] || { echo "arm A: expected 1 running hermes-agent container, found $n" >&2; return 1; }
  printf '%s\n' "$ids"
}
# Arm C: a live OpenClaw sandbox container, if one is running.
c_container() { docker ps -q --filter name=openclaw-sbx- | head -n 1; }

# env_exec <arm> <stdin 0|1> <script>  — run one sh script inside the arm's execution environment.
# In dry-run mode it prints the command and touches nothing.
env_exec() {
  local arm=$1 in=$2 script=$3 cid flag=()
  if [ "$DRY_RUN" = 1 ]; then
    local shown="'$script'"
    [ ${#script} -gt 80 ] && shown='<script>'
    case $arm in
      A) echo "    CMD docker exec $([ "$in" = 1 ] && echo '-i ')<id of: docker ps -q --filter label=hermes-agent=1> sh -c $shown" ;;
      B) echo "    CMD nemohermes $B_SANDBOX exec --no-tty $([ "$in" = 1 ] && echo '--stdin ')--timeout 120 -- sh -c $shown" ;;
      C) echo "    CMD docker exec $([ "$in" = 1 ] && echo '-i ')<id of: docker ps -q --filter name=openclaw-sbx-> sh -c $shown"
         echo "        else: docker run --rm $([ "$in" = 1 ] && echo '-i ')--network none --read-only --cap-drop ALL --security-opt no-new-privileges --init --tmpfs /tmp --tmpfs /var/tmp --tmpfs /run -v <here>/workC:/workspace $C_IMAGE sh -c $shown  (env_source=replica)" ;;
      D) echo "    CMD nemoclaw $D_SANDBOX exec --no-tty $([ "$in" = 1 ] && echo '--stdin ')--timeout 120 -- sh -c $shown" ;;
    esac
    return 0
  fi
  case $arm in
    A) cid=$(a_container) || return 1
       [ "$in" = 1 ] && flag=(-i)
       docker exec "${flag[@]}" "$cid" sh -c "$script" ;;
    B) [ "$in" = 1 ] && flag=(--stdin)
       nemohermes "$B_SANDBOX" exec --no-tty "${flag[@]}" --timeout 120 -- sh -c "$script" ;;
    C) [ "$in" = 1 ] && flag=(-i)
       cid=$(c_container)
       if [ -n "$cid" ]; then
         echo "PROBE env_source=live" >&2
         docker exec "${flag[@]}" "$cid" sh -c "$script"
       else
         echo "PROBE env_source=replica" >&2
         docker run --rm "${flag[@]}" --network none --read-only --cap-drop ALL \
           --security-opt no-new-privileges --init --tmpfs /tmp --tmpfs /var/tmp --tmpfs /run \
           -v "$here/workC:/workspace" "$C_IMAGE" sh -c "$script"
       fi ;;
    D) [ "$in" = 1 ] && flag=(--stdin)
       nemoclaw "$D_SANDBOX" exec --no-tty "${flag[@]}" --timeout 120 -- sh -c "$script" ;;
    *) echo "unknown arm: $arm" >&2; return 2 ;;
  esac
}

# redact <file>  — rewrite a log in place. Placeholders keep their class; every other value of a
# KEY/TOKEN/SECRET variable, and every known key shape, becomes <REDACTED>.
redact() {
  sed -E \
    -e 's/openshell:resolve:[A-Za-z0-9_:.-]+/<PLACEHOLDER>/g' \
    -e '/^PROBE /!s/([A-Za-z0-9_]*(KEY|TOKEN|SECRET|key|token|secret)[A-Za-z0-9_]*[=:][[:space:]]*["'\'']?)[^[:space:]"'\'',}<]{6,}/\1<REDACTED>/g' \
    -e 's/nvapi-[A-Za-z0-9_-]{8,}/nvapi-<REDACTED>/g' \
    -e 's/(^|[^A-Za-z0-9])sk-[A-Za-z0-9_-]{8,}/\1sk-<REDACTED>/g' \
    -e 's/gh[pousr]_[A-Za-z0-9]{20,}/gh_<REDACTED>/g' \
    -e 's/github_pat_[A-Za-z0-9_]{20,}/github_pat_<REDACTED>/g' \
    -e 's/xox[abpr]-[A-Za-z0-9-]{10,}/xox-<REDACTED>/g' \
    -e 's/AKIA[0-9A-Z]{16}/AKIA<REDACTED>/g' \
    -e 's/([Bb]earer )[A-Za-z0-9._~+\/=-]{12,}/\1<REDACTED>/g' \
    "$1"
}
