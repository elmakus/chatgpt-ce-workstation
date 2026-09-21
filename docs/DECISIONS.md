# Architecture decisions

Date: 2026-09-17

This document records accepted architecture decisions so they do not need to be reconstructed from chat history.

## D1 — Docker instead of VM

**Decision:** run the workstation as an Unraid Docker container.

The workload should consume CPU/RAM on demand instead of reserving resources for a full guest operating system. The user primarily needs an always-on Codex host, not a general-purpose VM.

## D2 — ChatGPT Community Edition is the host application

Use `ilysenko/codex-desktop-linux` / ChatGPT Community Edition as the Linux desktop host.

It builds a Linux desktop around the OpenAI ChatGPT/Codex application payload and exposes Linux-specific integrations required by this workstation, including Remote Mobile Control.

Upstream project:

- https://github.com/ilysenko/codex-desktop-linux

## D3 — No separate standalone Codex CLI in v1

The user intends to work primarily through ChatGPT Remote Control on Android.

A second standalone Codex CLI would introduce a possible version split between CE's bundled Codex and another independently updated executable. The native Remote workflow therefore keeps CE's bundled Codex as the authoritative runtime.

A standalone CLI may be added later only if a concrete terminal workflow requires it.

## D4 — CE Linux features

Current workstation selection:

```json
{
  "enabled": [
    "remote-mobile-control",
    "agent-workspace",
    "computer-use-linux",
    "authored-message-visibility",
    "automation-extensions",
    "mcp-helper-reaper",
    "node-repl-reaper",
    "project-group-last-updated-sort",
    "directory-only-working-tree-watch"
  ]
}
```

`directory-only-working-tree-watch` is the selected repository-watch strategy. Do not enable the conflicting `shallow-repository-watches` path at the same time.

Android Remote Control has been validated on the target workstation. It remains an upstream-sensitive feature and should be regression-tested after significant CE updates.

## D5 — Native `.deb` and accepted Electron sandbox compromise

Build CE through its native Debian packaging path and install the resulting package in the image.

Set:

```text
PACKAGE_WITH_UPDATER=0
```

The CE updater must not mutate a running container. Updating CE means rebuilding the workstation image.

On the target Unraid Docker boundary, CE's Chromium/Electron sandbox does not initialize reliably without broader container privileges. The accepted runtime therefore launches CE with `--no-sandbox` **inside the dedicated unprivileged workstation container** instead of adding `SYS_ADMIN`, `privileged`, a host-root mount, or the Docker socket.

Docker remains the isolation boundary.

## D6 — s6-overlay instead of systemd

Use s6-overlay as PID 1 and supervisor.

Reasons:

- container-native;
- lightweight;
- good lifecycle/restart behavior;
- avoids turning the container into a mini VM just to gain systemd.

Current pinned bootstrap version: `3.2.3.2`. User-service membership follows the s6-overlay v3 path under `/etc/s6-overlay/user-bundles.d/user/contents.d/`.

## D7 — Lightweight recoverable noVNC desktop

Use:

```text
Xvfb
  -> Openbox (desktop lifetime anchor)
  -> Tint2 panel
  -> ChatGPT CE / Codex Web GPT / terminal
  -> x11vnc (localhost only)
  -> websockify/noVNC :6080
```

noVNC is intended for login, configuration, recovery and diagnostics. It is also intentionally capable of relaunching applications without restarting the container.

ChatGPT CE is **not** the desktop lifetime anchor. If CE is closed with Quit, Openbox/noVNC remains alive. CE can be relaunched from the Tint2 panel or Openbox right-click menu.

Critical Openbox/x11vnc/websockify exits terminate the desktop longrun so s6 restarts the desktop session as one clean unit. CE and Codex Web GPT exits do not control the session lifetime.

## D8 — Persistent full user home

Bind mount the entire home:

```text
/mnt/user/appdata/chatgpt-ce-workstation/home
  -> /home/codex
```

Persisting the full home protects state written by CE, Codex, keyring, Remote Control, SSH/GitHub, Codex Web GPT and future tools without requiring per-directory guesses.

## D9 — Projects live directly on Unraid at CE's native project path

Bind:

```text
/mnt/user/projects
  -> /home/codex/Documents/ChatGPT
```

`/home/codex/Documents/ChatGPT` is the single canonical persistent project root and the native CE **Create Project** location.

There is no second `/workspace` project mount and no `/workspace` compatibility symlink in the desired architecture.

Prefer cloning this workstation repository itself to:

```text
/mnt/user/projects/chatgpt-ce-workstation
```

so the running agent sees its own durable source at:

```text
/home/codex/Documents/ChatGPT/chatgpt-ce-workstation
```

A separate project-data share should be added only for a concrete storage-tier or shared-large-data requirement.

## D10 — Image owns system/application state

System/application changes must ultimately be reproducible from the repository.

A live install may temporarily unblock a task, but useful changes must be persisted in `Dockerfile`, `compose.yaml`, `rootfs/`, `scripts/container/`, or the relevant project manifest before the next recreate/update.

## D11 — Codex Web GPT included; our fork is the default package source

The workstation installs Codex Web GPT from:

- https://github.com/elmakus/codex-chatgpt-web

The fork preserves normal browser-backed behavior and additionally contains optional native-upstream routing support for future Codex-LB use. The workstation v1 does not require Codex-LB to function.

The Docker build downloads the fork's Linux x64 release, verifies its checksum, installs it into `/opt/codex-web-gpt`, and exposes `/usr/local/bin/codex-web-gpt`.

Codex Web GPT starts automatically with the desktop session and can be relaunched from the noVNC panel/menu if closed.

## D12 — GitHub pushes and global agent policy

Editing a bind-mounted repository immediately edits the real Unraid file, but does not update GitHub until normal Git operations occur.

Do not create a blind post-commit auto-push hook. Durable agent instructions should require tests/status/commit/push at accepted task completion and forbid force-push without explicit approval.

The workstation-wide instruction template at `defaults/AGENTS.md` is seeded to `~/.codex/AGENTS.md` only when that persistent file does not already exist. Existing user changes are not overwritten automatically.

## D13 — No Docker socket in v1

Do not mount:

```text
/var/run/docker.sock
```

Do not add a host-root bind or privileged container mode as a shortcut either.

Passwordless sudo is intentionally limited to the workstation container's own namespace and mounted project/home data.

## D14 — Security / exposure

- expose noVNC only to trusted networks unless another authenticated ingress is deliberately added;
- raw VNC binds only to loopback inside the container;
- only websockify/noVNC is published;
- no secrets, browser profiles, ChatGPT auth, Remote private keys, SSH private keys or GitHub tokens in Git;
- VNC and keyring passwords are supplied from Unraid-side secret files.

## D15 — Validation order is part of the architecture

Regression/deployment checkpoints remain ordered:

```text
source validation
  -> host preflight
  -> image builds
  -> direct bind migration/recreate
  -> desktop/noVNC healthy
  -> exact runtime mount/isolation verification
  -> native CE/Android Remote regression check
  -> Codex Web GPT configuration/model routing
  -> Agent Workspace / Computer Use
```

The target host has already passed the CE login/keyring, Android Remote and native remote-task gates. They should not be treated as unknowns anymore, but remain regression checks after major upstream changes.

## D16 — Docker Compose is the primary deployment definition

`compose.yaml` is the runtime source of truth for:

- image/build arguments;
- container name/restart policy;
- port publication;
- bind mounts;
- secret wiring;
- `shm_size`;
- environment variables;
- future devices/capabilities if explicitly required.

Unraid Compose Manager may operate the stack, but helper scripts must remain wrappers around the tracked Compose definition rather than creating a second deployment configuration.

## D17 — Desktop health does not require CE to be open

The container healthcheck verifies the desktop substrate:

- noVNC HTTP endpoint;
- X display;
- Openbox;
- x11vnc;
- websockify.

ChatGPT CE and Codex Web GPT are intentionally outside the health condition because either application may be closed and relaunched during recovery without making the workstation itself unhealthy.

## D18 — Project-bind migration is guarded and verifiable

`scripts/init-unraid.sh` must not manipulate the persistent-home nested-bind target while the workstation container is running.

The supported migration path is `scripts/migrate-project-bind.sh`. An existing installation should first `git pull --ff-only` so the current helper exists locally. The helper then requires a clean `main`, fast-forwards/re-execs if needed, runs static source validation plus non-mutating host preflight, builds the replacement image **before downtime**, and only then stops the stack, prepares the bind target, recreates, waits for health and runs `scripts/verify-runtime.sh`.

Runtime verification checks the exact home/project bind sources and destinations plus the intended container isolation boundary, not merely that some mount exists at the canonical destination.

Unexpected pre-bind data under the old persistent-home project target is preserved under a timestamped `ChatGPT.pre-*` backup instead of being silently hidden or deleted. Disposable test-only backups may be deleted after final verification and manual inspection.

## D19 — Merge Muse Code candidate before live validation

**Decision:** merge the source-ready Muse Code candidate from PR #1 into workstation `main` before the first live Unraid validation.

The earlier hold on merging before live validation is superseded by the user's explicit 2026-09-18 decision. The purpose is operational simplicity: the next workstation build should be runnable directly from `main`, and any installer/runtime defects discovered during live Muse validation will be corrected on normal follow-up branches/PRs.

This does not waive the live validation itself. Muse authentication persistence, `muse exec` headless behavior, model/effort controls, timeout/cancellation, sandbox behavior, and orchestrator worker integration remain unvalidated until tested on the live workstation.

## D20 — ChatGPT-owned delegated Muse workers behind a normalized harness — SUPERSEDED

**Status:** superseded on 2026-09-18 by D21 after the `muse-max` runtime audit established that internal worker orchestration belongs in `elmakus/codex_workflow`, not in generic `chatgpt_only` workflow semantics.

**Historical decision:** add an opt-in delegated-worker capability under the existing `chatgpt_only` policy. ChatGPT remains the formal Task Card executor/control plane; Muse Code is a bounded leaf worker used initially for `executor` and `tester` roles.

The workflow repository will define only generic delegated-worker semantics: ownership, wait/return behavior, bounded result expectations and authority boundaries. It will not embed Muse-specific CLI syntax.

The workstation repository will own a stable Muse adapter (working name: `muse-worker`) that:
- launches one Muse process for one assigned worker task;
- awaits process completion instead of requiring the main agent to poll;
- drains and stores raw Muse output outside the main context;
- parses the installed Muse machine-readable output;
- validates and emits one compact normalized final result;
- enforces timeout and process-tree cancellation.

For normal GREEN execution, the main ChatGPT agent consumes the normalized result, not the full Muse transcript. Raw logs are escalation/debug evidence only.

A tester receives the accepted task/review contract plus actual repository/worktree state, not the executor transcript. This makes review independently grounded and prevents executor context from being recopied through the orchestrator.

Muse-native nested fan-out remains disabled by default. Fan-out ownership stays with the ChatGPT orchestrator.

The initial rollout is opt-in so existing `chatgpt_only` behavior remains backward compatible while the Muse path is validated.

**Rationale:** current external harnesses converge on the same separation: a small CLI/subprocess runner localizes volatile backend contracts, the orchestrator awaits completion, structured results are schema-normalized, and full trajectories/logs remain separate from parent-facing context. See `research/muse-delegated-worker-orchestration-2026-09-18.md`.

**Rejected for the first implementation:**
- teaching the main agent to call raw `muse exec` flags directly;
- periodic polling as the standard completion mechanism;
- injecting the worker JSONL/transcript into the main context;
- interactive steering/MSP as a prerequisite;
- allowing Muse to create its own subagent tree by default.


## D21 — `muse-max` is a mixed-harness, stateful-worker `codex_workflow` profile

**Decision (amended 2026-09-19):** define Muse workers only through the existing `elmakus/codex_workflow` worker-role system. Do not add Muse runtime semantics to Project Workflow and do not create a second Muse orchestration layer in `chatgpt-ce-workstation`.

The `muse-max` profile is the only profile changed by this work. `plus`, `luna-xhigh`, and `pro-x5` must preserve their current model allocations and lifecycle behavior.

Under `muse-max`:

- Main remains the user-selected Codex model and owns worker orchestration, routing and integration inside `codex_workflow`.
- `companion` runs as one persistent internal Codex worker on GPT-5.6 Luna XHigh.
- `micro_executor`, `default_executor`, `senior_executor`, `tester`, `investigator`, and `archivist` run through native Muse Code using Muse Spark 1.3 Contributor with `max` reasoning.
- existing worker TOMLs remain the canonical semantic role contracts; do not create parallel `muse_*.toml` definitions.
- Muse-specific session/process behavior belongs to the `muse-max` runtime/orchestration layer in `codex_workflow`, not to provider-specific copies of role semantics.
- a logical Muse worker may persist across multiple bounded turns through one stable Muse session; every physical turn/process has its own unique invocation/artifact identity.
- logical session identity is bound to role, active allocation, assigned workspace and opaque caller scope/lane identity. One session may have at most one active invocation and may not be reused across roles, workspaces or lanes.
- Muse workers remain leaf workers: no nested Muse worker tree and no direct sibling Muse messaging.
- Executor and Tester are distinct logical workers/sessions. Tester receives the verification capsule plus current repository/workspace state and relevant evidence, not the Executor trajectory, and Tester never performs production repair.
- ordinary RED routes through Main: focused Tester findings return to the owning Executor; the owning Executor is resumed for repair when safe; the independent Tester is resumed for a full verification of the changed target when safe.
- a changed implementation target does not by itself require a fresh Tester. Fresh A2/B2 replacement is required only when a controlling contract requires freshness, the previous session is unavailable/unsafe/binding-invalid, or Main has a material reason for a fresh independent context.
- resume/fallback is fail-closed. A failed resume must never silently mint a new session while continuing to present it as the old logical worker.
- raw Muse event streams/stdout/stderr remain outside ordinary Main context. Main receives compact normalized results plus bounded evidence/artifact references.
- the Muse runtime adapter validates active profile and per-role harness through `compute_profiles.py`; it must not hard-code a drifting role/model allocation.
- exact Muse lifecycle mechanics are bound from installed-build evidence. Stateful-default promotion requires live Meta-backed interrupted-turn fault-injection proving process-tree cleanup and either safe resume or explicit safe replacement.

**Repository/responsibility boundary:** `codex_workflow` owns only worker runtime/orchestration semantics: role separation, session/invocation lifecycle, binding, locking, resume/fallback, result normalization and Muse process control. It must not own or interpret Project Workflow execution policy, Task Board lifecycle, review-state transitions or immutable review-attempt bookkeeping. `session_id`, `invocation_id`, leases and resume mechanics are private runtime details.

A higher-level caller — future Project Workflow `codex_only`, another workflow, or a standalone Codex task — may supply opaque task/lane/workspace authority and may interpret Tester output according to its own state machine. `codex_workflow` must not need to know which higher-level system is calling it.

Caller-authorized independent lanes may run concurrently against distinct non-overlapping workspaces. Each lane has its own Executor/Tester sessions, and cross-lane session reuse is forbidden.

`chatgpt-ce-workstation` owns installation, persistence and runtime availability of official Muse Code plus user authentication state. It does not own the worker scheduler or normalized worker lifecycle protocol.

**Rationale:** live Muse Code 1.3.0 research on 2026-09-19 proved that separate headless `muse exec` processes can reuse the same durable session and preserve context across the exact A1 -> B1 -> A1 -> B1 cycle while keeping Executor and Tester sessions separate. The current one-shot behavior comes from the adapter conflating per-run artifact identity with Muse session identity, not from a Muse limitation. Keeping Project Workflow policy/state outside `codex_workflow` preserves reusable runtime semantics for any caller. See `research/MUSE_SESSION_RESUME_LIFECYCLE_2026-09-19.md`.

## D22 — M10 production promotion uses an exact release-candidate lineage

**Decision (2026-09-19):** publish and promote the accepted M10 stateful Muse runtime through a new exact `codex_workflow` release candidate derived from the independently GREEN M10 subject, rather than publishing that source checkpoint directly under stale release metadata.

The release path must:

- preserve the accepted M10 behavioral subject as the release candidate's behavioral base;
- add only the synchronized release/version changes and strictly version-coupled test/document literals required by the existing release contract;
- independently review the exact release candidate when required by the release plan;
- live-validate the exact candidate before publication;
- preserve commit identity from accepted release candidate through `main`, tag/release provenance and workstation installation;
- fail closed to normal correction/review/revalidation if any behavioral change, incompatible `main` drift or release-lineage mismatch appears;
- verify after production promotion that `muse-max` uses the accepted stateful lifecycle and that `plus`, `luna-xhigh`, and `pro-x5` remain unchanged.

**Rationale:** the accepted M10 source still carries the prior production version metadata. A distinct exact release candidate preserves auditable source → review → live validation → publication → production identity and avoids silently treating release metadata mutation as if it were the already-reviewed M10 source subject.

## D23 — Persistent global AGENTS uses workstation-owned reconciliation

**Decision (2026-09-19):** replace the permanent seed-once model for workstation global Codex policy with an explicitly delimited workstation-owned block inside the persistent `~/.codex/AGENTS.md`.

The workstation image/repository owns only that block. Container initialization reconciles it to the current image policy when global policy is enabled.

Content outside the workstation block remains outside workstation ownership. In particular, the `codex_workflow` block delimited by `codex-workflow-user-managed-start` / `codex-workflow-user-managed-end` must be preserved unchanged by workstation reconciliation, as must unrelated user-authored content.

Existing unmarked installations are migrated only when the old workstation-owned portion can be recognized conservatively from known repository-owned legacy content/layout. Ambiguous legacy files and malformed/duplicate workstation markers fail closed: the persistent file is left unchanged and a diagnostic is emitted instead of guessing.

Fresh installations are seeded directly into the managed form, and repeated reconciliation against the same image must be idempotent.

**Rationale:** the full home is intentionally persistent, so seed-once behavior leaves existing installations on stale workstation policy after image updates. Whole-file overwrite would violate D12 and can destroy independently managed or user-authored content. Explicit block ownership gives the image a safe update boundary while preserving the persistent file as a shared user configuration surface.



## D24 — Global Codex marketplace refresh uses one persistent s6 timer

**Decision (2026-09-20):** Workstation owns one deterministic automatic updater for all configured Git-backed Codex plugin marketplaces.

The updater:
- runs as an independent s6-overlay longrun registered through the existing Workstation user bundle;
- runs as user `codex` with the persistent `/home/codex` home;
- uses CE's bundled Codex runtime rather than adding a second independently managed Codex CLI;
- refreshes all configured Git marketplaces in one invocation by running the Codex marketplace upgrade command without a marketplace name;
- schedules the normal next refresh 24 hours after the **last successful refresh**, with that success timestamp persisted across container restart/recreate;
- performs a first refresh promptly when no successful timestamp exists;
- treats zero configured Git marketplaces as a successful no-op;
- does not advance last-success state on failure and retries later with a bounded non-busy interval;
- keeps update failures isolated from Workstation/desktop health;
- never injects refresh output into LLM session context;
- requires no SessionStart hook, LLM action, manual user command, cron, systemd, or per-skill/per-plugin updater.

Exact persistent state path, retry interval, executable discovery and machine-readable success validation are implementation details as long as they preserve the requirements in `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md`.

**Rationale:** Codex already provides one command that refreshes all configured Git marketplaces, while Workstation already standardizes service lifecycle on s6-overlay and persists the full Codex home. One persistent scheduler avoids duplicated updater logic across skills, avoids refreshes caused merely by container restart, and remains independent of whether a user opens a Codex session.

**Rejected alternatives:**
- SessionStart + TTL updater — rejected by explicit user preference;
- one updater per skill/plugin — rejected as duplicated lifecycle/state;
- plain container-lifetime `sleep 86400` cadence — rejected because restart/recreate would reset timing;
- cron/systemd — rejected because s6-overlay is the accepted Workstation supervisor.

## D25 — Workstation updates resolve latest stable identities before build

**Decision (2026-09-20):** replace timestamp-driven upstream refresh as the normal workstation update model with a `resolve -> freeze -> build -> validate -> promote` lifecycle.

Normal update policy is:

- keep the operating-system family on Ubuntu 24.04 LTS while following the current `ubuntu:24.04` image and supported package set;
- follow the latest trusted stable/current supported channel for image-managed upstreams rather than maintaining permanent stale pins;
- resolve each moving upstream to the strongest practical immutable identity before building one candidate;
- use those real identities as build/cache inputs so unchanged upstreams do not rebuild merely because time passed;
- treat the CE Git revision and the official OpenAI ChatGPT stable Linux package as separate freshness inputs while preserving CE's signed-package validation authority;
- keep `scripts/update.sh` as the one normal user-facing update operation;
- keep `scripts/build.sh` as a lower-level development/exact-build primitive that does not itself mean "advance all upstreams";
- validate a candidate before production recreation and retain the prior known-working image for deterministic rollback if post-promotion health/runtime verification fails;
- keep runtime application self-updaters disabled.

The image may use multi-stage/build-stage isolation where that materially improves cache reuse, but the architecture does not promise impossible layer reuse after changed base dependencies.

Expert pins/overrides remain permissible only as explicit recovery/debug/compatibility controls and must not replace the default latest-stable policy silently.

**Rationale:** the former `UPSTREAM_REFRESH=<timestamp>` mechanism guarantees some remote layers rerun but invalidates cache even when nothing changed and does not coherently refresh the earliest Ubuntu package layer. Resolving trusted immutable identities first gives both freshness and reproducibility, while candidate validation plus rollback prevents the updater from treating a broken rebuild as a successful production update.

**Consequences for earlier decisions:** D25 supersedes the permanent-version-pin aspect of D6 for ordinary s6-overlay updates while preserving s6-overlay as the accepted supervisor. D5's disabled CE self-updater, D10's image-owned application state, D11's Codex Web GPT image management, D15's validation discipline and D16's Compose deployment authority remain in force.

**Integration reconciliation note (2026-09-20):** this decision was originally numbered D24 on the smart-upstream workstream before reconciliation with current main. Current main already owned D24 for the Codex marketplace updater, so the identifier was renumbered to D25 without changing the accepted decision content.

## D26 — Workstation GNOME keyring is intentionally passwordless

**Decision (2026-09-20):** keep GNOME Keyring / Secret Service as the workstation desktop secret-store interface, but do not protect the workstation login keyring with a separate master password.

The target state is:

- the canonical desktop D-Bus session owns the GNOME Secret Service used by CE and desktop applications;
- the persistent login keyring remains under the persistent `/home/codex` home;
- the login keyring uses an empty master password and is therefore available without an unlock prompt;
- existing encrypted keyring state must be migrated in place to an empty master password without deleting stored items or forcing a fresh CE login;
- secondary/root-context processes must not silently autolaunch another D-Bus + keyring session against the same persistent codex home;
- migration must fail closed before changing existing keyring state when the installed GNOME keyring runtime does not expose the verified password-change mechanism;
- no keyring password is requested from the operator for fresh installations after this migration path is implemented.

**Security consequence accepted by the operator:** stored keyring secrets no longer receive a separate master-password encryption barrier at rest. Anyone who gains sufficient access to the persistent workstation home may have easier access to those stored secrets. Docker/Unraid access controls, filesystem permissions and the existing container boundary remain the surrounding protection.

**Supersedes:** only the D14 statement that a keyring password must be supplied from an Unraid-side secret file. D14's noVNC/network exposure and no-secrets-in-Git requirements remain in force.

**Rationale:** this workstation is a dedicated always-on headless container whose keyring is expected to be available automatically. A separate keyring password adds prompt/unlock failure modes without providing useful interactive authentication in the normal operating model. Preventing accidental secondary D-Bus/keyring sessions remains independently valuable and is retained.

## D27 — noVNC recovery desktop is intentionally passwordless on trusted networks

**Decision (2026-09-20):** remove VNC-password authentication from the Workstation noVNC recovery path.

The target state is:

- opening the published noVNC endpoint does not require a VNC/noVNC password;
- Workstation setup, Compose, container initialization and validation do not require or create a `novnc-password` runtime secret or persistent `vnc.pass` authentication file;
- raw x11vnc remains bound only to container loopback and is never host-published directly;
- only websockify/noVNC remains published;
- the published noVNC endpoint is intentionally unauthenticated at the VNC layer and must remain reachable only from trusted networks unless a separately authenticated ingress is deliberately placed in front of it;
- obsolete noVNC secret/auth files left by an older installation may remain on disk, but current runtime behavior must not depend on them;
- unrelated Docker isolation, desktop lifecycle, CE/Remote authentication and GNOME Keyring behavior remain unchanged.

**Security consequence accepted by the operator:** any client that can reach the published noVNC endpoint can control the recovery desktop without presenting a VNC password. Network reachability therefore becomes the access-control boundary for this endpoint, and broader/untrusted exposure requires a separate authenticated ingress.

**Supersedes:** the VNC-password portion of D14's statement that VNC and keyring passwords are supplied from Unraid-side secret files. D26 already superseded the keyring-password portion. D14's trusted-network restriction, raw-VNC loopback binding, noVNC-only publication and no-secrets-in-Git rules remain in force.

**Rationale:** this workstation is operated as a dedicated recovery desktop on a trusted network. The operator explicitly prefers passwordless noVNC access and accepts shifting access control from a VNC credential to the surrounding network boundary.

## D28 — Bound workstation Docker image and build-cache retention

**Integration reconciliation note (2026-09-20):** this retention decision was originally numbered D27 on the isolated workstream. Current main already owns D27 for passwordless noVNC, so the retention decision is renumbered to D28 without changing its accepted content.

**Decision (2026-09-20):** extend the D25 smart-update lifecycle with bounded post-success garbage collection for workstation Docker artifacts.

After an update candidate has been promoted and has passed the required workstation health and runtime verification:

- retain the exact current verified production image;
- retain exactly one immediately previous known-working workstation image as the deterministic rollback baseline;
- remove older workstation-specific candidate/rollback tags or images when they are no longer required by either protected identity or another live Docker reference;
- treat BuildKit/build cache as a separate resource class with its own bounded workstation-scoped retention policy;
- preserve useful identity-driven cache reuse rather than disabling cache or forcing clean rebuilds;
- never use an unscoped/global Docker prune that can remove unrelated Unraid project artifacts;
- never touch persistent home, projects, secrets, keyring or other bind-mounted user data;
- report retention cleanup separately from production verification, so cleanup failure after a verified promotion is a cleanup warning/failure rather than a false update/rollback failure.

Cleanup is forbidden before the new production image has passed the D25/R12 success gate. Any failed promotion, health check or runtime verification must preserve the image required for deterministic rollback.

The exact Docker/BuildKit filtering, builder identity and age/size/GC mechanism are implementation details to be selected only after verifying the target Unraid backend. They must preserve the workstation-only scope and bounded-retention outcome.

**Rationale:** D25 intentionally retains a previous known-working image and uses BuildKit cache for efficient repeated updates, but without an explicit lifecycle older candidate/rollback artifacts and historical cache can accumulate indefinitely on bounded Unraid Docker storage. Keeping only the current image plus one rollback baseline preserves deterministic recovery while separating safe image retention from bounded cache reuse.

## D29 — Native Interrupt-hook disable state is narrowly repairable, while ownership drift remains fail-closed

**Decision (2026-09-21):** treat native Codex `enabled = false` on the codex-chatgpt-web journal-owned Interrupt hook as a distinct recoverable compatibility state only when the journal proves that the hook is otherwise exactly the same owned hook.

The compatibility boundary is:

- normal status/verification still reports a disabled Interrupt hook as inconsistent; it is never healthy merely because the command and trusted hash still match;
- explicit setup, upgrade, or recovery may remove/replace the native disable override and restore enabled semantics only when managed boundaries, command, event/type, timeout, state key, trusted hash, and structural ownership all still match journal authority;
- the repair must be followed by exact re-verification before route startup continues;
- any other mutation remains subject to the existing strict fail-closed refusal;
- the implementation must add positive regression coverage for the exact `enabled = false` incident and negative coverage for unrelated/tampered drift.

**Rationale:** R01 verified that upstream Codex intentionally exposes user-config hooks as toggleable and persists `hooks.state.<key>.enabled` with an Upsert that preserves the existing trusted hash. codex-chatgpt-web simultaneously treats the hook block as strictly journal-owned. The 2026-09-19 outage was therefore an ownership-model compatibility conflict, not evidence that strict verification itself is wrong. Narrow repair of the native enablement-state override restores the integration invariant without granting permission to overwrite arbitrary managed-hook changes.

**Rejected alternatives:** treating `enabled = false` as healthy; blindly overwriting any changed block; moving the hook into a system/MDM/enterprise managed layer; or patching upstream Codex solely to special-case codex-chatgpt-web ownership markers.

