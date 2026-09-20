# M03-T02 implementation evidence

Integrated M03 implementation/test subject: `83e77ed669a2d58da248e052896c6c44a90f8972`
PR: #7
Reconciled integration target: `main@04440574afb2d85790301c915e9d7f8c90721021`

## Result

The exact integrated M03 updater subject is complete and remains non-production.

The updater and deterministic fixtures prove:
- source validation, resolver, host-preflight, candidate build and candidate-readback failures stop before any production recreate;
- source validation -> host preflight -> exact image build ordering is preserved before mutation;
- promotion recreates from the exact already-built candidate with `--no-build` and verifies the running image identity;
- the exact prior production image identity is captured and retained before promotion;
- promotion failure, promoted-image mismatch, health failure and runtime-verification failure enter rollback;
- successful rollback verifies the restored exact prior image but still reports the update as failed;
- rollback failure is represented separately and never reports success;
- bounded update evidence records resolution/candidate/previous-image identities without secrets;
- no timestamp/random/global-`--no-cache` freshness mechanism remains in the normal updater.

## Target reconciliation

Before freezing M03, current `main` had advanced through the independently completed Codex marketplace updater workstream. The workstream was reconciled to current `main` in exact merge subject `83e77ed669a2d58da248e052896c6c44a90f8972`.

Detailed reconciliation evidence:
`implementation/workstreams/feature-smart-upstream-updates/evidence/M03-target-reconciliation.md`

The only authority-name collision was concurrent use of D24. Current `main` retained its already-integrated marketplace D24; the unchanged smart-upstream decision was mechanically renumbered D25 and all smart-upstream-owned references were reconciled. Both independent validation blocks were preserved. No accepted smart-upstream behavior, architecture, rollback semantics, trust policy or milestone strategy changed.

## Exact verification

GitHub Actions on exact subject `83e77ed669a2d58da248e052896c6c44a90f8972`:
- CI run #154 / run id `35484470786` — GREEN:
  - source-validation — GREEN, including `SOURCE_VALIDATION_GREEN` and updater orchestration fixtures;
  - noVNC desktop workarea regression — GREEN;
  - full ShellCheck — GREEN;
  - Dockerfile static/buildx check — GREEN;
  - repository-history secret scan — GREEN.
- Exact candidate build run #19 / run id `35484470787` — GREEN:
  - frozen upstream resolution — GREEN;
  - exact non-production candidate build — GREEN;
  - exact candidate provenance readback — GREEN.

Independent isolated verification on Tower at the same reconciled source state also passed:
- `bash scripts/test-update-orchestration.sh` — `UPDATE_ORCHESTRATION_TESTS_GREEN`;
- `bash scripts/validate-source.sh` — `SOURCE_VALIDATION_GREEN`, including both smart-upstream and Codex marketplace deterministic suites;
- `docker buildx build --check --file Dockerfile .` — GREEN, no warnings;
- CI-equivalent full ShellCheck — GREEN;
- Gitleaks full-history scan — 651 commits scanned, no leaks found.

No real `scripts/update.sh` invocation, production Compose recreate, production promotion or live rollback was performed.

## Review boundary

The immutable implementation/test subject for the required independent M03-T02 review is:
`83e77ed669a2d58da248e052896c6c44a90f8972`

Any commits after that subject used only to persist this evidence or Task Board review bookkeeping do not change the reviewed implementation behavior. M04 production activation remains outside this subject and behind its explicit deployment/live-write authorization gate.
