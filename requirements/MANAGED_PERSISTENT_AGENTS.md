# Managed persistent global AGENTS lifecycle

Status: **approved**
Date: 2026-09-19

## Goal

Keep workstation-owned global Codex guidance in the persistent `~/.codex/AGENTS.md` automatically aligned with the current workstation image while preserving all content the workstation does not own.

The feature replaces the current seed-once lifecycle with explicit ownership and conservative migration. It does not make the workstation the owner of the entire persistent file.

## Requirements

### R1 — Persistent path remains canonical

The global policy path remains `~/.codex/AGENTS.md` under the persistent `/home/codex` bind.

Container recreation and workstation updates MUST preserve non-workstation-owned content in that file.

### R2 — Workstation policy is explicitly owned

Workstation-managed guidance MUST live inside one clearly delimited workstation-owned block.

The image/repository MUST be the source of truth for the block payload. Reconciliation MUST update only that block, not replace the whole persistent file.

### R3 — Automatic reconciliation

When global workstation policy is enabled, container initialization MUST reconcile the workstation-owned block to the policy shipped by the current image.

A user MUST NOT need a hand-written Codex prompt or manual edit for ordinary future workstation-policy changes.

### R4 — Preserve foreign and user content

Reconciliation MUST preserve content outside the workstation-owned block.

In particular, the existing block delimited by `codex-workflow-user-managed-start` / `codex-workflow-user-managed-end` is independently owned and MUST remain outside workstation ownership and unchanged by workstation reconciliation.

The same preservation rule applies to unrelated user-authored content before, after or between managed regions.

### R5 — Fresh installations are managed from first seed

When `~/.codex/AGENTS.md` does not yet exist and global policy is enabled, initialization MUST create it in the managed form so later workstation-policy updates use the same reconciliation path rather than a separate permanent seed-only format.

### R6 — Existing legacy installations receive a conservative migration

The current legacy seed-only workstation policy MUST be migratable into the managed form when the workstation-owned legacy portion can be identified from known repository-owned legacy content/layout.

Migration MUST preserve any independently managed or unrelated trailing/adjacent content.

The known live workstation layout — legacy workstation policy followed by the `codex_workflow` managed block — is an acceptance case.

### R7 — Ambiguous legacy content fails closed

If an existing file has no valid workstation-managed block and its legacy workstation-owned portion cannot be identified safely, initialization MUST NOT guess, delete, reorder or broadly rewrite the file.

It MUST leave the file unchanged and surface a clear diagnostic that manual reconciliation is required.

### R8 — Malformed managed state fails closed

Duplicate workstation blocks, unmatched workstation markers or another structurally ambiguous workstation-owned region MUST NOT be auto-repaired by destructive splicing.

The file MUST remain unchanged and the condition MUST be reported clearly.

### R9 — Reconciliation is idempotent

Starting the same image repeatedly against an already-current valid managed file MUST produce no content change.

Updating only the workstation block to a newer image policy and then starting again MUST also be idempotent.

### R10 — Existing ownership and permission expectations remain intact

The resulting file MUST remain readable by Codex and owned/permissioned consistently with the existing persistent-home model.

This feature MUST NOT weaken the container isolation boundary or require Docker-socket, host-root or additional privilege access.

### R11 — Validation covers ownership and migration safety

Repository tests/checks MUST cover at least:

- fresh managed seed;
- update of an existing valid workstation-managed block;
- preservation of the `codex_workflow` block;
- preservation of unrelated user content;
- migration of the known current legacy layout;
- ambiguous legacy content left unchanged;
- duplicate/unmatched workstation marker handling;
- repeated-start idempotency.

Runtime verification after deployment MUST be able to confirm that the persistent file contains the current managed workstation policy without requiring inspection of private unrelated content beyond what is necessary for that assertion.

### R12 — Production mutation remains deployment-gated

Implementation and tests MAY use fixtures or isolated temporary files without additional authorization.

The currently running workstation's persistent `~/.codex/AGENTS.md` MUST NOT be rewritten as part of source implementation or review. Live migration occurs only through an explicitly authorized deployment/recreate or other explicit live-write action.

## Acceptance-level outcomes

The feature is accepted when:

1. a fresh persistent home receives a valid managed global AGENTS file;
2. a subsequent image policy change replaces only the workstation-owned block;
3. the current known live legacy layout migrates to managed form while retaining the existing `codex_workflow` block unchanged;
4. arbitrary unrelated user text surrounding managed regions survives reconciliation unchanged;
5. ambiguous or malformed state is not destructively modified and produces an actionable diagnostic;
6. repeated reconciliation is content-idempotent;
7. source validation and isolated migration tests are GREEN;
8. after separately authorized deployment, runtime verification confirms the live persistent file carries the current workstation policy, including the integrated X11/ydotool guidance.

## Non-goals

- workstation ownership of the complete `~/.codex/AGENTS.md` file;
- editing or versioning the content owned by `codex_workflow`;
- inventing a generic multi-manager configuration framework;
- silently merging arbitrary user edits made inside an old unmarked stock template;
- relying on a manual prompt to Codex for each workstation-policy change;
- adding new container privileges or host-control surfaces.

## Definition notes

Exact marker strings, helper/script decomposition, optional human-readable schema/hash metadata and precise warning text are implementation details as long as the ownership, preservation, fail-closed and idempotency requirements above are met.

No unresolved product/system choice blocks Planning.
