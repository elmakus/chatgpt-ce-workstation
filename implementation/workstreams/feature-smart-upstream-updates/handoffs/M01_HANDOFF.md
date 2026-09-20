# M01 handoff — frozen upstream resolution contract

Checkpoint implementation head: `b337578fd3bad298cd96ec69d82ae2ebc3b5c6f0`
Workstream: `feature-smart-upstream-updates`
Branch: `feat/smart-upstream-updates`
PR: #7 (draft)

## Achieved state

M01's canonical resolver now produces deterministic, secret-free JSON for every approved moving upstream without timestamp/nonce invalidation:

- Ubuntu remains on the `ubuntu:24.04` family and its base manifest digest is resolved before candidate build execution.
- Ubuntu package freshness is represented by the exact signed InRelease identities from the frozen base.
- CE branch freshness resolves to an exact Git commit.
- OpenAI ChatGPT Linux package freshness is resolved separately by the exact CE commit's own signed stable-repository resolver; CE's pinned key/signature/index/package-hash trust chain remains authoritative.
- Agent Workspace resolves the npm latest dist-tag plus package integrity.
- s6-overlay resolves the latest stable GitHub release plus exact asset hashes.
- Codex Web GPT resolves the latest stable release and the AppImage SHA-256 from the existing upstream `checksums.txt` contract.
- Muse Code resolves the public `muse-stable` release id plus exact installer SHA-256.
- Chrome stable resolves exact version/package SHA-256 through verified Google APT metadata and records the signing-key hash.
- Rust stable resolves exact toolchain version from the official stable channel manifest, verifies that manifest's SHA-256, and records the rustup installer SHA-256.

Explicit overrides are marked in the manifest. Required source/network/metadata failures are fail-closed. Normal output contains no wall-clock or random freshness field.

## Acceptance evidence

- Exact accepted M01 implementation subject: `b337578fd3bad298cd96ec69d82ae2ebc3b5c6f0`.
- PR #7 CI run #102: source validation (including full resolver fixtures/unit tests), desktop workarea regression, ShellCheck, Dockerfile buildx static check and secret scan all GREEN.
- No production container recreate, promotion, rollback or other live workstation write occurred.
- Independent review is intentionally deferred to the approved integrated M01-M02 resolver/build subject before production activation.

## Authority in force

- `requirements/SMART_UPSTREAM_UPDATES.md`
- `docs/DECISIONS.md` D2, D4, D5, D6, D10, D11, D15, D16, D24
- approved `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md` revision `smart-upstream-updates-R2`
- independent plan review GREEN at `planning/reviews/smart-upstream-updates-R2.md`

## Next durable start

M02 — exact candidate build + cache semantics. The build must consume the frozen M01 manifest rather than re-resolving moving inputs, remove `UPSTREAM_REFRESH`, preserve upstream authenticity/checksum contracts and produce inspectable candidate provenance. Production recreation remains out of scope.
