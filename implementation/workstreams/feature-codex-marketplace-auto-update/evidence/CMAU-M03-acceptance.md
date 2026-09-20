# CMAU-M03 milestone acceptance

Date: `2026-09-20`
Milestone: `CMAU-M03 — Runtime validation and release readiness`
Result: **GREEN**

## Accepted checkpoint

- Reviewed implementation/candidate subject: `577a64630b6aa942b89c7c657265f3d6e8f448f3`.
- Terminal Card: `CMAU-M03-T01` — terminal after independent GREEN review.
- Card implementation evidence: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M03-T01-implementation.md`.
- Card review evidence: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M03-T01-review.md`.

## Acceptance

GREEN against the approved CMAU-M03 outcome and cross-cutting CMAU-REQ-001..016 surface.

The exact repository-built disposable candidate demonstrated:
- independent s6 service presence and runtime identity under user `codex` with persistent `/home/codex`;
- real CE-bundled Codex execution and successful zero-marketplace first run;
- last-success persistence across restart and full container recreate before due;
- controlled due refresh advancing success state only after verified success;
- controlled failure leaving last-success unchanged, retrying after 3600 seconds, and preserving Workstation desktop/health independence;
- recovery after restoring the bundled Codex path;
- GREEN full source validation and successful candidate image build;
- no production Workstation recreate, production marketplace/home mutation, new credential material, or standalone Codex installation.

## Publication boundary

The milestone implementation/validation checkpoint is accepted. Final branch-isolated integration into `main` remains owned by Close and requires the workstream integration-refresh/final-review gate before merge.
