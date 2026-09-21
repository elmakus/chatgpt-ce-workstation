# Independent milestone acceptance review — dual native upstreams

Date: 2026-09-18

## Verdict

**GREEN / PR READY**

## Independence and exact subject

- Reviewer: fresh normal ChatGPT chat; this chat did not implement the reviewed subject.
- Implementation repository: `elmakus/codex-chatgpt-web`
- Branch: `feat/dual-native-upstreams`
- Milestone review subject: `eeb57d0855f7baffc3089f66c7c84d2c06c40ef6`
- Milestone base: `f8dc469a43cc562a4173bb77f7a7d9fe2b569187`
- Branch readback during review: exact branch head equals the review subject.
- Base readback during review: `main` still equals the milestone base.
- Full milestone range: 11 commits ahead, zero behind.

## Authority applied

Milestone M01 contract:
- parallel native routing in `elmakus/codex-chatgpt-web`;
- `chatgpt-web/*` remains on the local ChatGPT Web adapter;
- `muse-*` routes only through CLIProxyAPI / Meta;
- remaining native models route through the native/Codex-LB path.

M01-T02 additionally requires Muse routing to fail closed when the Muse upstream is absent.

M01-T03 additionally requires supported encoded requests, especially zstd, to classify Muse from the already decoded model identity while preserving raw encoded bytes when no scrub is required.

Accepted decisions retained from the prior independent review:
- Muse is intended for simple single tasks, so its differing `multi_agent_version` is not a blocker.
- Muse context-window metadata is not hardcoded or overwritten by the bridge; the CLIProxyAPI/Meta value is preserved.

## Integrated findings

### Routing

- `responseRequest()` parses request bodies through the content-encoding-aware decoder and keeps `chatgpt-web/*` on the local adapter.
- Every other model is forwarded through native passthrough with the already decoded body available.
- Native passthrough extracts the validated model identity and passes it as `modelHint`.
- Automatic native routing classifies `muse-*` as Muse independently of configuration state.
- Missing Muse upstream therefore fails closed instead of falling through to Codex-LB or the official backend.
- zstd-compressed Muse requests retain that classification because routing consumes the decoded model hint rather than reparsing the preserved encoded body.
- Non-Muse native traffic continues through the native/Codex-LB route.

### Authentication and upstream separation

- Native/Codex-LB and Muse/CLIProxyAPI credentials are resolved separately.
- Rewriting replaces the incoming ChatGPT OAuth Authorization header with the selected proxy's dedicated key.
- Missing Muse credentials fail only the Muse route; ordinary native routing remains independent.
- Upstream URLs are constrained to credential-free HTTP(S) base URLs.

### Model discovery

- The primary native catalog is fetched through the native route.
- When a Muse upstream is configured, model discovery performs a separate forced Muse/CLIProxyAPI fetch.
- Only public `muse-*` rows are imported; unrelated CLIProxyAPI providers are filtered.
- Optional Muse-catalog failure is isolated so native Codex and `chatgpt-web/*` rows remain available.
- Imported Muse rows are merged without applying the bridge's native context or compatibility metadata rewrite, matching the accepted decisions above.

### Encoded-body preservation

- The native body decoder supports identity and zstd.
- When native history scrubbing is unnecessary, passthrough forwards the original encoded bytes and leaves `Content-Encoding: zstd` intact.
- M01-T03 regression source covers fail-closed zstd Muse, configured zstd Muse -> CLIProxyAPI with the Muse key, ordinary zstd native -> Codex-LB, and exact encoded-byte preservation.

## Prior RED findings

- R1 (Muse falling through when the Muse upstream is absent): corrected before the final subject.
- R2 (zstd Muse losing model identity and falling through): corrected before the final subject.
- The bounded M01-T03 independent review is GREEN at the same final subject.

No new blocking finding was found in the integrated final subject.

## Verification boundary

- GitHub source, exact branch/base identity, commit ancestry, full changed-file set, routing/auth/catalog implementation, and affected regression source were independently read back.
- The implementation subject has no pre-PR workflow runs or commit statuses.
- Full Bun repository verification was not available before publication.
- The zstd correction evidence records a targeted local routing check as GREEN.

Because repository CI is configured around pull requests / `main`, the absence of pre-PR CI is a publication-verification obligation rather than a contradictory implementation finding. Merge must not occur until the PR artifact is confirmed to match this accepted subject and required CI/check evidence is understood.

## Result

M01 implementation at `eeb57d0855f7baffc3089f66c7c84d2c06c40ef6` is **GREEN / PR READY**.

The next legal route is publication/PR verification against that exact accepted subject.
