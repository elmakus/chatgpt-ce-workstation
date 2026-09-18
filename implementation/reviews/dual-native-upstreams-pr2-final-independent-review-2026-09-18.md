# Independent review — M01-T05 and integrated M01 / PR #2

Date: 2026-09-18

## Verdict

**GREEN**

This is the REQUIRED independent review for M01-T05 and the integrated M01 acceptance review for PR #2.

## Independence and exact subject

- Reviewer: fresh normal ChatGPT chat; this chat did not implement the reviewed subject.
- Project branch: `elmakus/chatgpt-ce-workstation:feat/muse-code`.
- Implementation repository: `elmakus/codex-chatgpt-web`.
- Implementation branch: `feat/dual-native-upstreams`.
- PR: #2.
- Exact review subject: `4eaa9c350a885faa627e3e681a8d8861c9f4ba41`.
- PR readback during review: open, mergeable, non-draft, head still equals the exact review subject.
- No PR review threads or submitted GitHub reviews were present.

## Authority applied

M01 requires parallel deterministic routing:
- `chatgpt-web/*` remains on the local ChatGPT Web adapter;
- `muse-*` routes only through CLIProxyAPI / Meta;
- other native models use the primary native / Codex-LB upstream.

The prior accepted corrections additionally require:
- missing Muse upstream/key fails closed instead of falling through;
- zstd-compressed Muse requests classify from the already-decoded model identity while preserving encoded bytes.

M01-T05 requires PR macOS packaging without `CSC_LINK`/`CSC_NAME` to exercise the existing ad-hoc identity `-`, without broadening credentialed signing or weakening the existing `codesign --verify --deep --strict` verification.

## Independent source findings

The full PR diff and exact subject source were inspected.

Routing/auth/catalog:
- `responseRequest()` decodes the request with the repository's encoding-aware decoder and sends every non-`chatgpt-web/*` model into native passthrough while ChatGPT Web models remain on the local adapter path.
- `forwardNativeCodexRequest()` extracts a validated model from the decoded representation and passes it as `modelHint` to the native network layer while retaining the original encoded body when no bridge scrub is required.
- `prepareNativeCodexRequest()` classifies `muse-*` by model identity independently of upstream presence, so missing Muse configuration fails closed.
- Muse and native/Codex-LB credentials are resolved separately and the incoming Authorization bearer is replaced by the selected upstream key.
- Model discovery imports only `muse-*` rows from CLIProxyAPI, removes any primary-catalog Muse duplicates, leaves ChatGPT Web rows last, and degrades to the primary catalog when the optional Muse catalog fails.
- Muse rows are merged after primary-native augmentation, so Muse-reported context / multi-agent metadata is not overwritten by the bridge.

Post-T03 deltas:
- From the prior independently GREEN zstd subject to the current subject there are exactly two commits and only two changed files: the zstd regression helper plus the macOS package script.
- T04 copies the exact zstd-compressed bytes into a BodyInit-compatible `ArrayBuffer`; it does not change production routing.
- T05 changes only `launcher/scripts/package.cjs`.

Signing boundary:
- The new `CSC_FOR_PULL_REQUEST=true` assignment is inside the existing macOS no-credential branch guarded by both `!CSC_LINK` and `!CSC_NAME`.
- The same no-credential path disables signing identity auto-discovery and explicitly selects ad-hoc identity `-`.
- Therefore the correction does not enable credentialed PR signing and does not introduce a certificate, key, or secret.
- The existing archive verification remains unconditional for macOS packaging.

## Runtime / CI readback

PR workflow run `35299105025` for the exact head completed successfully.

All workflow jobs are GREEN:
- actionlint;
- macOS 15 verify/package/smoke;
- Ubuntu verify/package/smoke;
- Windows verify/package/smoke.

The macOS verify log directly shows the Muse/native regressions executing and passing, including:
- ordinary Muse -> CLIProxyAPI with its own key;
- non-Muse -> Codex-LB;
- missing Muse upstream -> fail closed;
- zstd Muse missing upstream -> fail closed;
- zstd Muse -> CLIProxyAPI with exact encoded-byte preservation;
- zstd ordinary native -> Codex-LB;
- Muse-only catalog merge and optional-catalog failure isolation.

The macOS package log shows Electron Builder signing the app with `identityName=-`. The `bun run app:package` step then succeeds. Because `launcher/scripts/package.cjs` unconditionally runs `codesign --verify --deep --strict` on the extracted macOS archive before package success, the GREEN step proves that the existing archive verification passed. `bun run app:smoke` also succeeds.

## Findings

No blocking finding remains for M01-T05 or integrated M01 at the exact review subject.

The Electron Builder log emits its generic warning about `CSC_FOR_PULL_REQUEST=true`; in this implementation the flag is only set in the explicitly no-credential, ad-hoc-signing branch described above, so the warning does not expose a conflicting credentialed-signing path in the reviewed subject.

## Result

- M01-T05: **GREEN**.
- Integrated M01 / PR #2 at the exact subject: **GREEN**.

Publication/merge may proceed only through the normal milestone-close route and its remaining publication-state checks.
