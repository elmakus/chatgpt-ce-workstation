# Muse Code integration plan

Status: workstation Muse substrate installed; capability/skill ownership reconciled with D21/D25/D26
Integration history: PR #1 introduced the image-managed Muse CLI into `main`

The original image integration is historical baseline. Current worker orchestration is governed by D21 in `elmakus/codex_workflow`; this document owns only the workstation installation, persistent-home substrate and workstation-side integration boundaries.

## Goal

Install the official Muse Code CLI as an immutable workstation tool and provide the persistent user-state substrate required by Muse-backed workers.

Target ownership/topology:

```text
Codex Main
  -> elmakus/codex_workflow
      -> muse exec
          -> Muse-owned persistent config/auth/skills
          -> Muse-owned MCP clients and tool execution
```

Use Muse account/subscription authentication for the Muse CLI. Do not introduce Meta Model API/PAYG credentials by default.

## Persistence model

The workstation already bind-mounts the complete user home:

```text
/mnt/user/appdata/chatgpt-ce-workstation/home -> /home/codex
```

Therefore native Muse user paths below the home directory already persist without extra mounts, including expected paths such as:

```text
/home/codex/.config/muse/
/home/codex/.local/share/muse/
/home/codex/.local/state/muse/
```

Do not add redundant nested bind mounts for these paths. During the first live login/run, diff `/home/codex` before and after. Add a new bind only if the installed Muse build writes important durable state outside `/home/codex`.

Application binaries must not live only under `/home/codex` in the image because the runtime home bind would hide them. Keep image-owned Muse files under `/opt/muse-code` and expose a workstation wrapper from `/usr/local/bin/muse`.

## Persistent capability and skill plane

The existing full-home bind is also the persistence boundary for Muse-owned capabilities. Workstation does not create a second Muse home or a parallel capability database.

Muse-native state may include:
- user MCP configuration/authentication in the Muse config root, including `~/.config/muse/settings.json`;
- trusted-project MCP configuration through the project's supported `.mcp.json`;
- reusable user skills in Muse-supported user skill roots under the persistent home, including `~/.agents/skills`;
- repository-specific skills in the trusted project's supported skill directory.

MCP/tool authorization and skill/domain knowledge are separate planes. Skill metadata does not grant MCP/tool access.

Structured per-invocation capability guidance is owned by `elmakus/codex_workflow` through `MuseCapabilityHints`. Workstation must not parse or reimplement required/relevant skill or required/suggested capability semantics. The dedicated `elmakus/muse-capability-admin` skill owns rare inspect/install/configure/update/validate/remove procedures; the full administration runbook does not belong in workstation-global `AGENTS.md`.

## Immutable-image candidate

The intended build-time layout is:

```text
/opt/muse-code/bin/muse
/opt/muse-code/bin/muse-bin-*
/usr/local/bin/muse
```

The build helper downloads the official installer to a file, records its SHA-256, optionally verifies a configured expected SHA-256, and runs it with an isolated temporary build HOME. It requests `/opt/muse-code/bin` as the install directory and prevents PATH modification.

The wrapper disables runtime auto-update so ordinary agent runs cannot silently mutate the image-owned Muse installation. Workstation rebuild/update remains the normal upgrade path.

Because a stable first-party exact-version artifact contract has not yet been confirmed, the first implementation follows the stable channel at image-build time and records the resolved `muse --version`. If live inspection exposes a supported exact version/artifact contract, replace this with a strict pin.

## Runtime and orchestration boundary

D21 assigns Muse worker orchestration to `elmakus/codex_workflow`, not to Workstation. Session/invocation identity, role separation, workspace binding, locking, resume/fallback, process-tree cleanup, result normalization and Main-side delegation guidance must therefore be implemented and tested in that owning repository.

Workstation's responsibility is narrower:
- make the image-managed `muse` executable available;
- preserve the configured user home so later `muse exec` processes see the same Muse-native config/auth/skill state;
- avoid introducing mounts, wrappers or environment overrides that isolate Muse from that home;
- preserve the Docker/security boundary required by the workstation.

Capability hints are per-invocation replace data owned by `codex_workflow`. A resumed logical Muse session may retain conversational trajectory, but previous capability hints are not authoritative unless repeated in the current invocation. Missing required capabilities must be fail-visible; advisory hints remain non-blocking. Hints never carry credentials or installation authority.

## Authentication and mutation boundary

Muse login/auth state and Muse-owned external capability credentials belong in Muse/provider-native state backed by the persistent `/home/codex`; no auth token, OAuth material or API key belongs in the image or Git repository.

Capability mutation authority and credential availability are separate:
- a missing required capability does not authorize installation, configuration, authentication, update or removal;
- an already-approved secret reference may be reused through the owning administration path without copying plaintext into chat, task capsules, hints, normalized results, Git or ordinary logs;
- possession of a credential does not authorize a capability mutation;
- ambiguous capability choice returns to user/product authority;
- Workstation does not assume a universal secret vault and adds secret-delivery wiring only when concrete evidence proves a workstation-owned gap.

M01 performs no live Muse settings, OAuth, MCP or user-skill mutation.

## Validation boundaries

The original installation checks remain useful as historical substrate regression coverage: the image contains Muse under `/opt/muse-code`, the wrapper disables runtime auto-update, `muse exec` is available, and the full `/home/codex` bind survives workstation recreation.

Current capability-plane verification is staged separately:
- M01 validates the workstation source/persistence contract without changing live capability state;
- M02 refreshes the exact deployed `codex_workflow` and administration dependencies before integration-readiness checks;
- M03 performs only explicitly authorized, bounded and reversible live skill/MCP/auth validation with readback and rollback/removal evidence.

Worker lifecycle, model/profile allocation, resume/fallback and Executor/Tester session semantics remain governed by D21 and `elmakus/codex_workflow`, not by this workstation document.
