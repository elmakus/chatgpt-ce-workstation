# CMAU-M03-T01 independent review

Date: `2026-09-20`
Review subject: `elmakus/chatgpt-ce-workstation@577a64630b6aa942b89c7c657265f3d6e8f448f3`
Verdict: **GREEN**

## Authority checked

- Stable Card: `implementation/workstreams/feature-codex-marketplace-auto-update/cards/CMAU-M03-T01.md`.
- Milestone: `planning/CODEX_MARKETPLACE_AUTO_UPDATE_PLAN.md#milestone-cmau-m03--runtime-validation-and-release-readiness`.
- Definition: CMAU-REQ-001..016 in `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md`.
- Accepted architecture: D3, D6, D8, D10, D14, D15, D17 and D24 in `docs/DECISIONS.md`.
- Accepted dependency: `implementation/workstreams/feature-codex-marketplace-auto-update/handoffs/CMAU-M02_HANDOFF.md`.

## Subject and evidence checked

- Exact immutable subject `577a64630b6aa942b89c7c657265f3d6e8f448f3`.
- Comparison against accepted CMAU-M02 subject `51d9cf2463c03c15dde6ae0c09965fc6ba572ab8`: no updater/runtime source changed; intervening files are Task Board/Card/evidence/handoff state for the already-accepted implementation.
- Exact updater core `scripts/container/codex_marketplace_updater.py`, deterministic tests, s6 longrun/run script, user-bundle registration, Dockerfile installation, desktop service and Workstation healthcheck.
- Implementation/runtime evidence: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M03-T01-implementation.md`.
- Prior independent GREEN CMAU-M01 and CMAU-M02 review evidence.

## Review result

GREEN. The exact candidate source plus durable runtime evidence satisfy the CMAU-M03-T01 contract and the integrated CMAU-REQ-001..016 acceptance surface.

- The updater remains exactly one repository-owned independent s6 longrun, registered through the Workstation user bundle and isolated from desktop/health lifecycle.
- The service source drops to user `codex`, sets `HOME=/home/codex`, and launches the repository-owned updater core; runtime evidence independently binds the candidate to UID 99/GID 100 and the persistent Codex home.
- The updater invokes CE's bundled `/opt/codex-desktop/resources/codex plugin marketplace upgrade --json` command with no marketplace-name argument and adds no standalone Codex installation or new credential path.
- The persisted scheduler state is under `/home/codex`; the candidate evidence shows first-run success, unchanged state across restart and full recreate before due, and a later due refresh advancing last-success only after verified success.
- Controlled exit-42 failure left last-success unchanged, produced the bounded 3600-second retry, remained s6-managed, and left Workstation health GREEN. Restoring the bundled command path produced normal recovery.
- The zero-marketplace path succeeded through the real bundled Codex runtime; deterministic source tests cover all-marketplace command shape, JSON error classification, malformed state/result handling, pre-commit state-write failure and the post-replace directory-fsync commit point.
- Source validation was GREEN on the exact candidate source, the candidate image built successfully, and the recorded image/container/source identity is sufficient to bind the runtime evidence to the reviewed subject.
- The evidence records cleanup of only the disposable candidate artifacts and no live Workstation recreate, production `/home/codex`, marketplace configuration or credential mutation.

## Review limitation

The disposable candidate was intentionally removed after implementation evidence capture, so this review did not re-run that already-recorded container session. Independent exact-subject source inspection found no contradiction with the durable runtime readbacks, and the Card requires review of the exact candidate source plus durable runtime evidence rather than a second live production validation.
