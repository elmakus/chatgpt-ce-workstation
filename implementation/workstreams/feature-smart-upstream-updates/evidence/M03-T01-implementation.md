# M03-T01 implementation evidence

Implementation subject: `eeebbc3d14a26ba7b896b5d0e5af6693303301b2`
PR: #7

## Result

`scripts/update.sh` now owns the resolver-driven update lifecycle through an exact frozen candidate:
- source validation;
- upstream resolution/freeze;
- host preflight;
- exact candidate build;
- candidate label + embedded-manifest readback;
- known-working production image capture and exact rollback tag retention;
- exact candidate recreation through Compose with `--no-build`;
- running-image identity, health and runtime verification;
- rollback to the exact prior image when post-promotion verification fails;
- distinct `update_failed_rolled_back` versus `rollback_failed` evidence states.

The lower-level `scripts/build.sh` remains pre-resolved/exact. Local update evidence is secret-free and excluded from Git/Docker build context.

## Verification

On the isolated temporary clone at exact subject `eeebbc3d14a26ba7b896b5d0e5af6693303301b2` on Tower:
- `bash -n scripts/update.sh scripts/test-update-orchestration.sh` — GREEN.
- `bash scripts/test-update-orchestration.sh` — `UPDATE_ORCHESTRATION_TESTS_GREEN`.
- `bash scripts/validate-source.sh` — `SOURCE_VALIDATION_GREEN`, including resolver/build fixtures and updater orchestration fixtures.
- `docker buildx build --check --file Dockerfile .` — GREEN, no warnings.
- ShellCheck error-level validation of the new M03 shell files in an isolated ShellCheck container — GREEN.

No real updater invocation, production Compose recreate, promotion or rollback was executed. The real workstation production container was not mutated by the M03 updater path during implementation verification.

## Boundary

This is the M03-T01 implementation slice only. Integrated M03 failure-path coverage and the exact pre-activation review subject are owned by M03-T02.
