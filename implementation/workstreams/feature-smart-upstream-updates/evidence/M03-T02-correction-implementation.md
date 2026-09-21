# M03-T02 corrective implementation evidence

Corrected implementation/test subject: `ffe39dfcb6ac5584af9410feee5eab5f81b008cc`
PR: #7
Prior RED review subject: `83e77ed669a2d58da248e052896c6c44a90f8972`
Prior RED review evidence: `implementation/workstreams/feature-smart-upstream-updates/evidence/M03-T02-review.md`

## Correction

The bounded M03-T02 correction closes the independent-review finding for rollback failure recovery-state reporting.

On every `rollback_failed` path, `scripts/update.sh` now performs a best-effort post-rollback production-state readback and records/reports:
- readback status (`complete`, `partial`, `container_missing`, or `container_lookup_failed`);
- current container ID when present;
- current running state;
- current health state;
- actual current image ID.

The snapshot is persisted as `recovery_state` in the bounded update JSON evidence. Readback failures are represented explicitly rather than guessed, and the original previous/candidate/rollback identities remain preserved.

Deterministic orchestration coverage now includes:
- rollback recreate failure with the candidate still present/unhealthy;
- rollback failure leaving the production container absent;
- rollback verification failure where a healthy but wrong image is present;
- direct serialization verification of the `recovery_state` JSON object.

No requirement, architecture decision, upstream policy, milestone strategy, production-write boundary, or deployment authorization changed.

## Verification

GitHub Actions on the corrected subject:
- CI #162 / run id `35486258531` — GREEN:
  - source validation — GREEN, including `UPDATE_ORCHESTRATION_TESTS_GREEN` and `SOURCE_VALIDATION_GREEN`;
  - noVNC desktop workarea regression — GREEN;
  - full ShellCheck — GREEN;
  - Dockerfile static/buildx check — GREEN;
  - repository-history secret scan — GREEN.
- Exact candidate build #27 / run id `35486258589` — GREEN:
  - frozen upstream resolution — GREEN;
  - exact non-production candidate build — GREEN;
  - exact candidate provenance readback — GREEN.

The PR-triggered workflows checked out synthetic merge commit `190fc2f49b7c751530f30e0449137ad7f2fd33b4` ("Merge ffe39df... into 04440574..."). Exact Git comparison from the corrected review subject to that synthetic merge contains zero changed files, so the tested tree is identical to the frozen subject.

Candidate provenance readback:
- resolution SHA-256: `9024b66f4b60bfad8c21916ef8d9bda146d271c55f02f90823caf486fe735393`;
- image ID: `sha256:6ce16fa516a155187b4ab5114b9af03557e8663cac22862c5c7a4823e364880f`;
- image label and embedded resolution manifest matched the same frozen resolution identity.

No real `scripts/update.sh` invocation, production Compose recreate, production promotion, or live rollback was performed.

## Review boundary

The new immutable implementation/test subject for REQUIRED independent M03-T02 review is:
`ffe39dfcb6ac5584af9410feee5eab5f81b008cc`

Commits after that subject may persist only evidence and Task Board review bookkeeping. They do not change the corrected implementation behavior. M04 production activation remains outside this subject and behind its explicit deployment/live-write authorization gate.
