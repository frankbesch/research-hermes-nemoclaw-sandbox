# Round 2 sources and open questions

Every tool claim in the round-2 design rests on a quote below. The docs sites
(docs.nvidia.com, docs.openclaw.ai, hermes-agent.nousresearch.com) were not
reachable from the authoring session, so each quote comes from the docs source
in the vendor's public repo, pinned to the commit read on 2026-11-03. Those
docs describe each project's main branch on that date, not the versions used
in 10-20 (Hermes v0.22.2, NemoClaw v0.0.136).

- NemoClaw: [NVIDIA/NemoClaw @ fc7d02e](https://github.com/NVIDIA/NemoClaw/tree/fc7d02e4a4d0dbf01c6aee55e07dfbf0625e324e/docs)
- OpenClaw: [openclaw/openclaw @ c8efa61](https://github.com/openclaw/openclaw/tree/c8efa6107418d3c45b8e300c3c8c064b214f72ea/docs)
- Hermes: [NousResearch/hermes-agent @ 7b55a7c](https://github.com/NousResearch/hermes-agent/tree/7b55a7c2363610cb3622f87ed66dcea18720bde6/website/docs)

## NemoClaw

[reference/platform-support.mdx](https://github.com/NVIDIA/NemoClaw/blob/fc7d02e4a4d0dbf01c6aee55e07dfbf0625e324e/docs/reference/platform-support.mdx):

> | macOS (Apple Silicon) | Colima, Docker Desktop | Tested with limitations |

> requires Homebrew Colima users to install both Colima and the Docker CLI (`brew install colima docker`) before `docker info` can work

> Suitable for evaluation and the documented onboarding paths; production parity with OpenClaw is not yet asserted.

> OpenShell owns capability enforcement for managed entrypoints, exec processes, and connect shells

[reference/commands.mdx](https://github.com/NVIDIA/NemoClaw/blob/fc7d02e4a4d0dbf01c6aee55e07dfbf0625e324e/docs/reference/commands.mdx)
(used for the B, D, and P1 commands):

> Run a single command non-interactively in a running sandbox via the OpenShell exec endpoint. The command runs as the sandbox user with `HOME=/sandbox`

> Run one OpenClaw turn with `$$nemoclaw my-assistant exec -- openclaw agent --agent main -m "What is 2+2?"`.

> Use this when driving the sandbox programmatically from another process (CI job, multi-agent platform, evaluation harness) rather than from an interactive terminal.

> OpenClaw invocations must include at least one target selector: `--agent`, `--session-id`, `--session-key`, or `--to`.

> Pass `--stdin` to forward an intentional pipe, or `--no-stdin` to close terminal stdin explicitly.

> Export the sandbox's OpenShell base policy as parsed YAML.

> Stop managed local inference resources, remove runtime-provider-owned resources created during onboarding, and delete the sandbox.

> To disable NemoClaw telemetry, run `export NEMOCLAW_DISABLE_TELEMETRY=1` in each shell before installation or CLI use.

[inference/use-nvidia-endpoints.mdx](https://github.com/NVIDIA/NemoClaw/blob/fc7d02e4a4d0dbf01c6aee55e07dfbf0625e324e/docs/inference/use-nvidia-endpoints.mdx):

> Set `NVIDIA_INFERENCE_API_KEY` in the host shell before onboarding.

> The sandbox receives a placeholder, not the real key.

[security/credential-storage.mdx](https://github.com/NVIDIA/NemoClaw/blob/fc7d02e4a4d0dbf01c6aee55e07dfbf0625e324e/docs/security/credential-storage.mdx)
(the basis for `PLACEHOLDER_RE`):

> The gateway stores the credential and the OpenShell L7 proxy substitutes it into outbound requests at egress, so sandboxed agents see placeholders instead of the raw secret.

> Agent configuration uses `openshell:resolve:env:<KEY>` references instead of raw keys.

[reference/network-policies.mdx](https://github.com/NVIDIA/NemoClaw/blob/fc7d02e4a4d0dbf01c6aee55e07dfbf0625e324e/docs/reference/network-policies.mdx)
(the basis for gates R4 and R5):

> NemoClaw runs with a deny-by-default network policy. The sandbox can only reach endpoints that are explicitly allowed.

> 2. OpenShell blocks the connection and logs the attempt.

> Lets every sandbox binary open TCP connections to public and private address ranges on destination ports `80` and `443`.

The last quote describes the Personal tier's `personal-open-internet` preset. On
that tier, the listener would be reachable, so P1 would test a different policy.

## Hermes

[user-guide/configuration.md](https://github.com/NousResearch/hermes-agent/blob/7b55a7c2363610cb3622f87ed66dcea18720bde6/website/docs/user-guide/configuration.md)
(the basis for arm A's probe path):

> Terminal, file, and `execute_code` calls use `docker exec` in the selected container.

> - `hermes-agent=1` — marks it as Hermes-managed

> When a Hermes process exits — `/quit`, closing a TUI session, gateway shutdown, even SIGKILL — the cleanup path is a **no-op for the container in default mode**.

> **Credential forwarding:** Env vars listed in `docker_forward_env` are resolved from your shell environment first, then `~/.hermes/.env`.

[user-guide/security.md](https://github.com/NousResearch/hermes-agent/blob/7b55a7c2363610cb3622f87ed66dcea18720bde6/website/docs/user-guide/security.md):

> **Container bypass**: When running in `docker`, `modal`, `daytona`, or `vercel_sandbox` backends (or a container plugin backend such as `singularity`), dangerous command checks are **skipped** because the container itself is the security boundary.

[user-guide/features/memory.md](https://github.com/NousResearch/hermes-agent/blob/7b55a7c2363610cb3622f87ed66dcea18720bde6/website/docs/user-guide/features/memory.md)
(the basis for check Q3):

> Both are stored in `~/.hermes/memories/` and are injected into the system prompt as a frozen snapshot at session start.

[integrations/providers.md](https://github.com/NousResearch/hermes-agent/blob/7b55a7c2363610cb3622f87ed66dcea18720bde6/website/docs/integrations/providers.md)
(the basis for the cost-path statement):

> **It only works if you're on a Claude Max plan and have purchased extra usage credits.** The base Max plan allowance (the usage included in Claude Code by default) is not consumed by Hermes — only the extra/overage credits you've added on top are. Claude Pro subscribers cannot use this path.

## OpenClaw

[gateway/sandboxing/modes-scope-and-backend.md](https://github.com/openclaw/openclaw/blob/c8efa6107418d3c45b8e300c3c8c064b214f72ea/docs/gateway/sandboxing/modes-scope-and-backend.md)
(why arm C sets a sandbox mode):

> | Mode    | `agents.defaults.sandbox.mode`    | `off`, `non-main`, `all`                          | `off`    |

> - `all`: every session runs in a sandbox.

OpenClaw's default (`off`) runs tools on the host. Round 2 does not use that
mode: it would run injection probes directly on the owner's Mac, and it would
not parallel arm A, which uses Hermes' own container backend.

[gateway/sandboxing/docker-backend.md](https://github.com/openclaw/openclaw/blob/c8efa6107418d3c45b8e300c3c8c064b214f72ea/docs/gateway/sandboxing/docker-backend.md)
(the basis for `openclaw-C.json5` and the replica in `lib.sh`):

> Defaults: `network: "none"` (no egress), `readOnlyRoot: true`, `capDrop: ["ALL"]`, image `openclaw-sandbox:trixie-slim`.

> OpenClaw also creates Docker sandbox containers with an init process and
> `no-new-privileges`.

[gateway/sandboxing/workspace-access.md](https://github.com/openclaw/openclaw/blob/c8efa6107418d3c45b8e300c3c8c064b214f72ea/docs/gateway/sandboxing/workspace-access.md):

> | `rw`             | Mounts the agent workspace read/write at `/workspace`.                                                                    |

[cli/agent.md](https://github.com/openclaw/openclaw/blob/c8efa6107418d3c45b8e300c3c8c064b214f72ea/docs/cli/agent.md)
(the basis for arm C's command):

> `openclaw agent exec` runs one embedded agent turn without connecting to a Gateway. It is the recommended headless entry point for CI and coding automation because it owns setup, cleanup, output projection, and process status.

> Exec defaults apply only where your config leaves a setting unset: the agent sandbox is off

> `--config <path>` runs against exactly that config file

[cli/sandbox.md](https://github.com/openclaw/openclaw/blob/c8efa6107418d3c45b8e300c3c8c064b214f72ea/docs/cli/sandbox.md)
(the container-name filter in `lib.sh`):

> "containerPrefix": "openclaw-sbx-",

[gateway/sandboxing/images-and-setup.md](https://github.com/openclaw/openclaw/blob/c8efa6107418d3c45b8e300c3c8c064b214f72ea/docs/gateway/sandboxing/images-and-setup.md):

> bash ca-certificates curl git jq python3 ripgrep \

> OpenClaw does not silently substitute plain `debian:trixie-slim` when `openclaw-sandbox:trixie-slim` is missing.

[providers/nvidia.md](https://github.com/openclaw/openclaw/blob/c8efa6107418d3c45b8e300c3c8c064b214f72ea/docs/providers/nvidia.md):

> NVIDIA serves open models for free through an OpenAI-compatible API at

> openclaw models set nvidia/nvidia/nemotron-3-ultra-550b-a55b

[install/index.md](https://github.com/openclaw/openclaw/blob/c8efa6107418d3c45b8e300c3c8c064b214f72ea/docs/install/index.md):

> - **macOS, Linux, or Windows**

## UNVERIFIED

The docs cannot settle these. Each one has a gate or a recorded field.

1. **OpenClaw on this host.** OpenClaw's docs list macOS, and NemoClaw lists
   macOS Apple Silicon with Colima as "Tested with limitations". Neither OpenClaw
   alone (C) nor OpenClaw in NemoClaw (D) has run on the 10-20 host. Gate R2's
   warm-ups are the first test.
2. **Listener reachability from Colima.** Whether `host.docker.internal` (or
   `host.lima.internal`) reaches the Mac's loopback listener from containers and
   from OpenShell sandboxes. Gate R2 checks it from arm A.
3. **Env parity in arm A.** `docker exec` enters the same container as Hermes'
   terminal tool, but Hermes may add env per call. P1 may then under-report A's
   env.
4. **Arm C container.** Whether OpenClaw's sandbox container outlives an
   `agent exec` run, and whether `--cwd` is the workspace it mounts. Recorded as
   `env_source` (live or replica) and checked by the R2 warm-up.
5. **Exec vs agent tools in B and D.** NemoClaw says OpenShell enforces
   "exec processes", but not that an exec process gets the same per-binary
   network rules as the agent's own tool calls. P1 tests the exec path.
6. **Placeholder form in v0.0.136.** Today's docs give `openshell:resolve:env:`;
   the 10-20 build may differ. SCORING says how to amend `PLACEHOLDER_RE`.
7. **Arm D's policy.** OpenClaw in NemoClaw gets its own baseline policy; how it
   differs from `policy-B.yaml` is recorded in gate R4, not assumed.
8. **Tools in arm A's image.** Whether it ships `curl` and `bash`. P1 records
   `unavailable` if not.
9. **NVIDIA terms.** Rate limits, credit caps, and price for NVIDIA Endpoints.
10. **macOS shell tools: partly checked.** On 2026-11-03 the operator ran
    `redact` on the Mac (BSD sed) with fake values; the output matched GNU sed.
    The Mac's default bash (3.2) has not run the real-mode paths yet; `lib.sh`
    avoids the empty-array expansion that bash 3.2 rejects under `set -u`.
11. **Hermes and NemoClaw versions.** These quotes describe main on
    2026-11-03; the run will use whatever is installed (gate R0).
