# Intake — managed persistent AGENTS

Date: 2026-09-19
Workstream ID: `feature-managed-persistent-agents`
Kind: `feature`
Status: complete

## Operator intent

Create a durable lifecycle for the workstation-wide persistent `~/.codex/AGENTS.md` so repository-managed workstation guidance can evolve across rebuilds without overwriting user-managed content or the block managed by `codex_workflow`.

## Discovery

- Normal integration target is `main`.
- No existing matching workstream or branch was found for this feature.
- The current source seeds `defaults/AGENTS.md` into the persistent home only when `~/.codex/AGENTS.md` does not already exist.
- The current init path already contains one narrowly targeted stock-text migration for the historical `/workspace` path change, proving that persistent policy migration is an existing lifecycle concern.
- Accepted D12 explicitly protects existing user changes from blind overwrite.
- The recently integrated ydotool guidance changed the repository template, but an already-existing persistent AGENTS file is not updated by the seed-once behavior.
- Live verification on the target workstation confirmed the persistent file is still the older workstation policy followed by a distinct `codex-workflow-user-managed` marker block; the current file has no workstation-managed markers yet.

## Base / dependency classification

Independent workstream.

The feature operates on behavior already present on `main` and does not require unmerged parent-only state. It is based on:

`elmakus/chatgpt-ce-workstation@4c4da56e1c7db6d0cfc69e170ada3800db185c28`

Integration target: `main`.

## Initial scope

Explore a managed-block model for workstation-owned global Codex policy, including:
- deterministic updates of workstation-owned guidance;
- preservation of unrelated user-authored content;
- preservation of content owned by `codex_workflow`;
- safe one-time migration from the current legacy seed-only file layout;
- fail-closed behavior when legacy content cannot be identified safely;
- idempotent behavior across rebuilds/restarts.

## Classification

Path: `brainstorming`

Next route: `brainstorming:managed-persistent-agents@R1`

Canonical exploratory record: `brainstorming/managed-persistent-agents.md`

Definition promotion remains `pending`; the `#feature` directive does not authorize Project Definition promotion.
