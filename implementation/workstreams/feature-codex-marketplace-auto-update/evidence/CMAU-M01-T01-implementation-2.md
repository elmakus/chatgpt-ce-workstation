# CMAU-M01-T01 corrective implementation evidence — attempt 2

Date: `2026-09-20`
Implementation subject: `elmakus/chatgpt-ce-workstation@15b399ad0bdaf7ed843039be7e402cd75796352b`
Card: `CMAU-M01-T01`
Predecessor RED review: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M01-T01-review-1.md`

## Corrective scope

- Preserved the original scheduler/updater architecture and all CMAU-M01-T01 authority.
- Made the atomic state-file rename the explicit persistence commit point.
- After `os.replace()` succeeds, a parent-directory fsync `OSError` is now a bounded warning rather than a transition to the retry/failure path.
- This prevents the contradictory state found in review attempt 1: a cycle reporting failure while the last-success file has already advanced.
- Added deterministic regression coverage for a directory-fsync failure after the atomic replace.

No s6 registration, Dockerfile/image integration, live container recreate, network marketplace refresh, or persistent live marketplace mutation was performed.

## Verification

GREEN:

- Python syntax/compile validation passed for updater + test module in the current execution runtime.
- Deterministic scheduler suite passed: `14/14`.
- The new regression injects failure into the second fsync (the parent-directory durability fsync) and verifies:
  - cycle result remains successful after the already-committed verified refresh;
  - last-success contains the successful completion timestamp;
  - no temporary state file remains.
- Existing pre-commit interruption coverage remains GREEN: an `os.replace` failure still returns the bounded retry/failure result and preserves the previous state unchanged.
- GitHub immutable readback at `15b399ad0bdaf7ed843039be7e402cd75796352b` confirms the corrective updater source, the new regression test, and existing `scripts/validate-source.sh` compile/test wiring.
- Current upstream Codex source evidence still matches the accepted command/JSON contract used by the Card.

Not executed:

- Full repository `scripts/validate-source.sh` because this execution surface does not expose a complete project checkout with Docker Compose. The Card contract permits recording that unavailable dependency while running the affected deterministic checks directly.
- Any live marketplace/network refresh or Workstation mutation.

## Acceptance assessment

The bounded RED finding from review attempt 1 is corrected inside CMAU-M01-T01 authority. The Card remains non-terminal and requires a fresh independent review of the new immutable subject before terminal completion.
