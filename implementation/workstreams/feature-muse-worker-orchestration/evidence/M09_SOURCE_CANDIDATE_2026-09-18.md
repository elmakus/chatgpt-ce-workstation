# M09 source candidate evidence — 2026-09-18

## Subject

Card: `M09-T01 — Add bounded managed Muse lane concurrency`.

Exact review subject:

- repository: `elmakus/codex_workflow`
- branch: `impl/m09-muse-lane-concurrency`
- commit: `f6603767115cf7f31ef7d8c3cb3a419a7f430aca`
- PR: `elmakus/codex_workflow#6`
- PR base: `main@f2b1811853a2c1da5a5af4bb735c84c3111a44d6`
- M09 predecessor/base checkpoint: `b87f4eb4e1611407a9a5aa1d31b16b2cc8f1974b`

The M09 delta from the accepted M07 checkpoint is eight commits and six files only:
`.github/workflows/tests.yml`, `README.md`, `RELEASING.md`,
`codex_workflow/delegation.md`, `codex_workflow/runtime/muse_worker.py`, and
`scripts/test_muse_adapter.py`. No `compute_profiles.py`, worker TOML, Companion
allocation, or other-profile lifecycle code changed in M09.

## Implemented behavior

The exact subject adds a managed concurrency helper over the existing single-run
Muse adapter. Main/Project Workflow supplies an explicit set of already-authorized
lane invocations and isolated workspaces; the helper does not discover dependencies,
decide `parallel_safe`, create branches/worktrees, or own Task Board state.

The helper:

- validates all concurrent workspaces before process launch and rejects equal or
  ancestor/descendant overlap;
- bounds one submitted batch to eight explicit invocations;
- uses the existing `execute_worker` process/result contract for every lane;
- preserves result order while allowing independent Muse processes to run together;
- keeps cancellation/timeout/process-tree ownership per invocation;
- does not cancel a healthy lane because another lane returns a normalized failure;
- allocates distinct run IDs/artifact directories;
- serializes retention mutation and protects all batch-active run directories from
  concurrent retention cleanup;
- leaves executor -> Tester -> optional repair -> fresh Tester ordering inside a lane
  to Main/Project Workflow authority.

The existing unmanaged-background-process prohibition remains in force.

Documentation was reconciled to the accepted mixed-harness D21 semantics and the
observed workstation Docker boundary. CI now includes the Muse adapter suite and a
Python compile check whose generated cache is removed before release packaging.

## Verification

Final PR CI run: GitHub Actions `Tests` run `35378766734`, job
`105709690291`, on exact head `f6603767115cf7f31ef7d8c3cb3a419a7f430aca`.

Final run GREEN:

- workflow runtime regression: **90/90 GREEN**;
- Muse adapter suite: **17/17 GREEN**, including two-lane barrier concurrency,
  overlap rejection, lane failure isolation, lane cancellation isolation, and
  active-run retention protection;
- Python compile check: GREEN;
- Muse-max/profile regression: **7/7 GREEN**;
- package validation: GREEN for version `1.1.17-private.10`;
- release archive build: GREEN;
- release archive verification: GREEN.

The first PR run (`35378687470`) had all runtime/adapter/compile/profile/validation
checks GREEN but failed package build because the newly added compile step left
`__pycache__` inside the source tree. The CI-only compile step was corrected to
remove generated caches before packaging. The final exact subject above is the
post-correction subject and its full run is GREEN.

Unified PR diff readback on the candidate showed no added-line trailing whitespace.
The M09 delta is bounded to the six files listed above.

## Deferred/live gates

No M09 live workstation operation, release publication, merge, version bump, or
production promotion was performed by M09-T01.

Still unsatisfied and intentionally outside this source-only Card:

- live two-lane Muse workstation smoke on isolated disposable worktrees;
- deferred R3/D21 live creation and in-session reuse of one internal GPT-5.6 Luna
  XHigh Companion on the exact reviewed candidate;
- release/version publication;
- workstation production promotion/readback.

Approved Master Plan R2 requires the Companion check to be GREEN before publication
or promotion. Quota/runtime rejection keeps that gate open; substitute models do
not satisfy it.

## Review boundary

`M09-T01` requires independent review. The exact immutable subject for that review
is `elmakus/codex_workflow@f6603767115cf7f31ef7d8c3cb3a419a7f430aca`, with PR
`#6` and this evidence record. The implementing chat must not issue the verdict.
