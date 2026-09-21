# M01-T12 implementation evidence

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T12`

## Exact implementation subject

`elmakus/chatgpt-ce-workstation@55c61b0df3e4a09ca36614e4ddcec352499f51e3`

The implementation commit changes exactly:

- `scripts/update.sh`
- `scripts/test-update-orchestration.sh`

No production/container mutation occurred in this Card.

## Behavior

`scripts/update.sh` now separates one physical candidate-build attempt into `build_candidate_once` and wraps it with bounded retry orchestration:

- maximum 3 candidate-build attempts;
- every attempt receives the same already-frozen resolution path and candidate image tag;
- retry happens only when that attempt's build log contains:
  `Ubuntu InRelease SHA-256 mismatch for `
- generic/non-mismatch build failure returns immediately without retry;
- three retryable mismatches return failure and preserve the existing caller behavior:
  `pre_promotion_failed / candidate_build_failed`;
- no resolver call was added to the retry loop;
- no Ubuntu hash acceptance, mirror policy, pin, override or integrity assertion was changed.

The retry wrapper keeps the existing build output visible through `tee` while retaining a per-attempt log solely for narrow retry classification.

## Deterministic test coverage

`scripts/test-update-orchestration.sh` now covers:

- generic `build_fail` => exactly 1 build attempt, terminal pre-promotion failure, no recreate;
- `apt_mirror_retry_exhausted` => exactly 3 build attempts, terminal `candidate_build_failed`, no recreate;
- `apt_mirror_retry_success` => first two attempts emit the exact Ubuntu mismatch, third succeeds, then the unchanged normal candidate readback / two recreate+verify cycles / keyring finalization / retention cleanup path completes.

Existing updater scenarios remain in the same suite.

## Test results

On Tower from the exact implementation tree before commit:

- `bash scripts/test-update-orchestration.sh` => `UPDATE_ORCHESTRATION_TESTS_GREEN`
- `bash scripts/validate-source.sh` => `SOURCE_VALIDATION_GREEN`

The full validation also retained GREEN results for frozen upstream contracts, BuildKit cache/retention tests, Compose resolution, container boundaries, passwordless keyring/session boundaries, image-managed applications, recovery surface and secret hygiene.

`git diff --check` passed before commit.

## Scope/readback

GitHub readback of exact subject `55c61b0df3e4a09ca36614e4ddcec352499f51e3` confirms the diff is limited to the two intended files above.

M01-T11 remains blocked and production remains on its prior healthy v5.0.14 image until this correction receives independent review and normal workflow resumes T11.

## Review boundary

Independent review is RECOMMENDED by the Card because this changes failure/retry behavior in the production updater path.

The reviewer should judge exact subject `55c61b0df3e4a09ca36614e4ddcec352499f51e3` against M01-T12, D25 and the M01-T11 blocker evidence.

No implementation changes occurred after this subject was frozen.
