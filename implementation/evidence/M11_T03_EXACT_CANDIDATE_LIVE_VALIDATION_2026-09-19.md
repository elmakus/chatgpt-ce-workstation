# M11-T03 — exact release-candidate live validation

Date: 2026-09-19
Card: `implementation/cards/M11-T03.md`
Result: **GREEN**

## Exact subject

- Repository: `elmakus/codex_workflow`
- Candidate: `d285aa1a271258052d23e3a2d3b585117fc1e862`
- Candidate remained detached/clean at the exact independently GREEN M11-T02 subject before and after live validation.
- Muse runtime: `Muse Code 1.3.0 (1.3.0-R3401.1)`.

## Bounded stateful live proof

Validation ran inside `chatgpt-ce-workstation` with a disposable candidate runtime and disposable workspaces. The installed production `codex_workflow` tree was used only for before/after readback.

- One `default_executor` logical worker completed two bounded turns.
- Turn 2 resumed the exact retained session from turn 1.
- The two turns used distinct invocation identities.
- A separate `tester` logical worker/session performed a full read-only verification and returned GREEN.
- Tester workspace hash was unchanged by verification.
- Executor and Tester session identities were distinct.
- Two caller-authorized non-overlapping lane workspaces ran concurrently and both completed GREEN.
- All four logical sessions used across lifecycle/Tester/two-lane validation were distinct where separation was required.

## Runtime isolation/readback

- Four retained logical workers ended in `ready`.
- Five private invocation/run directories were created.
- Private runtime directories were mode `0700`; private files were mode `0600`.
- No M11-T03 candidate Muse process remained after validation.
- Candidate checkout remained clean and at exact subject `d285aa1a271258052d23e3a2d3b585117fc1e862`.

## Production boundary

Before and after validation:

- installed production version: `1.1.17-private.11`;
- installed production `runtime/muse_worker.py` SHA-256: `c199a458530d0e53ad64e40fe43c2f4072af5b9efe62af4144a03a4cb0570950`;
- production remained unchanged.

No `codex_workflow:main` advance, tag/release publication, or production promotion was performed.

## Result

**GREEN.** The exact independently reviewed M11 release candidate satisfies the bounded live stateful/session-reuse, Executor/Tester separation, lane-isolation, cleanup and production-non-mutation acceptance surface required by M11-T03.
