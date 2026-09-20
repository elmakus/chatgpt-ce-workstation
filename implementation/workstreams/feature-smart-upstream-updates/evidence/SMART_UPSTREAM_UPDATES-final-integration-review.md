# Smart upstream updates — independent final-integration review

Date: `2026-09-20`
Workstream: `feature-smart-upstream-updates`
Review owner: `implementation/workstreams/feature-smart-upstream-updates/WORKSTREAM.yaml`
Review requirement: **RECOMMENDED**
Review subject: `elmakus/chatgpt-ce-workstation@272ec9d238ca19ab3c190b1450cd2a19b7bdd4cb`
Verdict: **GREEN**

## Authority and acceptance surface

Reviewed independently against:

- `requirements/SMART_UPSTREAM_UPDATES.md` R1-R16 and its acceptance outcomes;
- accepted decisions D2, D4, D5, D6, D10, D11, D15, D16 and D25;
- approved `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md` revision `smart-upstream-updates-R2`;
- selected workstream manifest and canonical Task Board;
- exact final-integration refresh, M04 milestone acceptance, live update/regression evidence, live rollback/no-change evidence and prior exact independent review evidence materially referenced by the final acceptance surface;
- actual source on the immutable review subject.

## Subject and integration identity

- The immutable final review subject is exactly `272ec9d238ca19ab3c190b1450cd2a19b7bdd4cb`.
- Relative to accepted implementation checkpoint `a6fbfd8d9e5a7e3dca3ed3053a2bc7cab214b251`, the subject adds only M04/Close bookkeeping, acceptance evidence and the cumulative handoff; it makes no behavioral source change.
- Immediately before verdict, current `main` remained `04440574afb2d85790301c915e9d7f8c90721021`, exactly the refresh baseline and merge base; the review subject was behind by zero.
- GitHub CI run #202 on the exact review subject completed successfully.
- The Exact candidate build run associated with the closure-only subject was cancelled. This does not leave the reviewed acceptance surface without candidate evidence: the subject changes no implementation behavior, while the accepted M04 implementation was built and exercised through the real updater on the target workstation with exact frozen-resolution/image provenance and successful live readback.

## Independent findings

No blocking or material non-blocking defect was found.

The reviewed source and evidence satisfy the accepted surface:

- `scripts/update.sh` owns the normal end-to-end lifecycle and preserves source validation -> resolution/freeze -> host preflight -> exact candidate build before any production recreate.
- Candidate promotion is tied to the frozen resolution by canonical manifest, image label and embedded-manifest readback.
- Normal source contains no timestamp-only `UPSTREAM_REFRESH` cache invalidation and no global `--no-cache` update path.
- The resolver binds Ubuntu 24.04 to an exact digest before build; CE and the signed OpenAI package remain separate identities; Agent Workspace, s6-overlay, Codex Web GPT, Muse, Chrome, Rust and Ubuntu package metadata are frozen to verifiable exact inputs with explicit override accounting and fail-closed drift behavior.
- `build.sh` remains a lower-level frozen-input build primitive and does not resolve latest on its own.
- Pre-promotion resolution/source/preflight/build/readback failures are tested to leave production untouched.
- The updater captures the exact prior known-working image before promotion. Post-promotion failure uses the real rollback path, verifies health/runtime plus exact restored image identity, returns update failure even after successful rollback, and records explicit recovery state if rollback itself fails.
- Compose remains the tracked deployment authority. No Docker socket, privileged mode, host-root mount or `SYS_ADMIN` boundary was introduced, and runtime application self-update remains disabled where required.
- M02-T02 and corrected M03-T02 have exact independent GREEN implementation reviews; related Codex Web GPT C01/C02 corrections also have exact independent GREEN reviews.
- M04 live evidence proves a normal production update to frozen resolution `27a9929c4cb4da99c0c3cd4c4e5807539ad759b5360559a872664162b5ba1fff` and exact image `sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`, with Ubuntu 24.04, runtime isolation/persistence and CE Remote / Codex Web GPT / Agent Workspace / Computer Use regressions GREEN.
- The bounded live fault exercise forced post-promotion runtime verification failure through the actual updater rollback path, restored and verified exact prior image `sha256:e11e3f473ee45c25585f79f7b891e18f359a0a133d9b3e37359e7514233a4972`, preserved home/project sentinels, then restored the accepted candidate.
- A fresh no-change resolution was byte-identical to the active frozen manifest, reused the same image identity and demonstrated practical BuildKit reuse with 24 `CACHED` markers.

## Verdict

**GREEN.**

The exact final-integration subject satisfies the manifest-owned RECOMMENDED independent-review gate. This verdict covers the immutable workstream subject and acceptance surface above. Close must still re-read the integration target immediately before merge and repeat integration refresh if that target has materially moved.
