# Brainstorm — managed persistent AGENTS

Date: 2026-09-19
Scope ID: `managed-persistent-agents`
Revision: `R1`
Status: `ready_for_definition`

## Problem / goal

The workstation-wide `~/.codex/AGENTS.md` lives in the persistent home. The image currently seeds `defaults/AGENTS.md` only when that file does not exist, so later repository-managed policy improvements do not reach existing installations. The goal is to make workstation-owned guidance safely updateable across rebuilds/restarts without taking ownership of unrelated persistent user content.

## Current understanding

### Verified facts

- D8 makes the full `/home/codex` persistent across container recreation.
- D12 intentionally prevents blind overwrite of an existing global AGENTS file.
- `rootfs/etc/cont-init.d/10-workstation-init` currently seeds the template only when `~/.codex/AGENTS.md` is absent.
- The same init script already performs one narrowly matched legacy migration for the historical `/workspace` wording.
- The repository template on current `main` contains newer workstation guidance, including the supported X11 GUI automation policy.
- The current live persistent `~/.codex/AGENTS.md` still contains the older workstation template and therefore does not contain the newer GUI automation section.
- The current live file contains an independently owned block delimited by `<!-- codex-workflow-user-managed-start -->` and `<!-- codex-workflow-user-managed-end -->`; that block must not be rewritten by workstation policy migration.

### Existing accepted decisions

- D10: durable system/application behavior belongs in repository-managed image/source state.
- D12: existing persistent user changes must not be blindly overwritten.
- The user explicitly prefers an automatic managed lifecycle rather than receiving a manual Codex prompt for every future AGENTS policy update.
- The user accepted the managed-block direction: update only workstation-owned content, preserve the `codex_workflow` block and unrelated user-authored content, and fail closed when a legacy file cannot be identified safely.

### Assumptions to verify during Definition / implementation

- A workstation-owned block can be delimited with stable markers and replaced idempotently on startup.
- The current legacy stock portion can be recognized strongly enough to permit a one-time migration without consuming the adjacent `codex_workflow` block.
- A version/hash marker is useful for diagnostics but should not become the only safety boundary; content ownership markers and exact migration recognition should remain authoritative.

## Ideas / alternatives considered

### Option A — overwrite the entire persistent file from the image

Rejected direction. It is simple but violates D12 and would destroy unrelated user content or independently managed blocks.

### Option B — keep seed-once behavior and use manual prompts for every change

Rejected product direction. It leaves existing installations stale and requires repeated manual intervention.

### Option C — workstation-managed block inside the persistent file

Preferred direction for Definition.

- The image owns a clearly delimited workstation block.
- Startup reconciles that block to the current repository template.
- Content outside that block is preserved byte-for-byte as far as practical.
- The independently managed `codex_workflow` block remains outside workstation ownership.
- Existing installations receive a one-time legacy migration only when their old workstation-owned portion is safely recognizable.
- Ambiguous legacy files are left unchanged and produce a clear diagnostic instead of guessing.

### Option D — separate workstation policy into an included file

Potentially cleaner ownership, but only useful if Codex has a stable supported include/import mechanism for global AGENTS semantics. No such mechanism is currently an accepted workstation contract, so this is not the preferred baseline.

## Trade-offs / questions

- Marker corruption or duplicate workstation markers must fail closed rather than splice arbitrary content.
- A legacy file that has user edits interleaved inside the old stock workstation section is harder to classify safely than the current observed live file.
- Reconciliation should be deterministic and idempotent; repeated starts with the same image must produce no changes.
- The migration should make the current integrated ydotool/X11 guidance effective on the existing workstation after deployment, without requiring a hand-written live edit.
- Tests should cover fresh seed, current known legacy migration, existing managed block update, preservation of `codex_workflow`, preservation of unrelated user content, duplicate/malformed markers and idempotency.

## Research needed

No formal research obligation is currently required. The relevant repository behavior and the current live persistent-file layout have been directly verified.

## Open questions

- Exact workstation marker names and whether the managed block carries a human-readable schema/version or content hash.
- Whether the repository template becomes only the managed block payload or remains a full-file seed template for a new installation.
- Exact warning/exit behavior when migration cannot safely identify the legacy workstation-owned portion.
- Whether runtime verification should assert only marker/current-content state or also expose an explicit migration status.

## Outcome of this session

- Tentative conclusions: use an idempotent workstation-managed block plus a conservative one-time legacy migration; preserve independently owned and user-authored content; fail closed on ambiguity.
- Explicit user/product choices to promote through Project Definition: automatic propagation of workstation AGENTS policy; no manual prompt-per-change workflow; preserve `codex_workflow` and unrelated user content; safe migration instead of blind overwrite.
- Research still needed: none before Definition based on current evidence.
- Open questions: implementation-level marker/versioning and diagnostics details listed above.
- Next phase/action: `ready for definition`
- Definition promotion authorization: `user_authorized`
- Definition promotion subject: `managed-persistent-agents@R1`

> Nothing in this file becomes accepted requirement/decision authority by itself. Project Definition owns promotion into canonical `requirements/` and `decisions/`. The `#feature` directive does not itself authorize phase promotion.
