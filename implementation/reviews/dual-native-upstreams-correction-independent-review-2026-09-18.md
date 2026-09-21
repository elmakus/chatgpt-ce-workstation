# Independent re-review — dual native upstreams correction

Date: 2026-09-18

## Verdict

**RED / NOT PR READY**

## Independence and exact subject

- Reviewer: fresh normal ChatGPT chat; this chat did not implement the reviewed subject.
- Repository: `elmakus/codex-chatgpt-web`
- Review subject: `0cad74ba6f3f9bc13d6e973d94bc993d8b2ff5c3`
- Corrective base / prior RED subject: `2c7eb2ac5266df0cf198a11abb14eba314f411e0`
- Original milestone base: `f8dc469a43cc562a4173bb77f7a7d9fe2b569187`
- Branch readback: `feat/dual-native-upstreams` pointed exactly at the review subject during review.

## Authority applied

Milestone M01 requires parallel deterministic routing:

- `chatgpt-web/*` -> local ChatGPT Web adapter;
- `muse-*` -> CLIProxyAPI / Meta;
- remaining native models -> Codex-LB/native upstream.

M01-T02 additionally requires that `muse-*` fail closed when the Muse upstream is absent and never fall through to Codex-LB or the official native backend.

Accepted prior review decisions remain in force:

- Muse is intended for simple single tasks, so its different `multi_agent_version` is not a blocker.
- Muse context-window metadata must not be hardcoded or overwritten; preserve the value reported by CLIProxyAPI/Meta.

## Scope reviewed independently

The review re-read the exact corrected source at the review subject, the complete M01 diff from the milestone base, the corrective diff, the affected tests, the routing/auth/catalog implementation, and the durable implementation evidence.

Confirmed for ordinary uncompressed JSON requests:

- automatic `muse-*` classification no longer depends on whether the Muse upstream is configured;
- missing Muse upstream therefore fails closed for an ordinary JSON Muse request;
- configured Muse requests use the Muse/CLIProxyAPI key, not the incoming ChatGPT OAuth bearer;
- ordinary native requests continue to use Codex-LB and its separate key;
- model discovery imports only `muse-*` rows from CLIProxyAPI and tolerates optional Muse-catalog failure;
- Muse catalog rows are not normalized through the bridge's native `multi_agent_version` or context override, matching the accepted decisions above.

## Blocking finding

### R2 — zstd-compressed `muse-*` requests can still fall through to native routing

The corrected router still discovers the model by reparsing the already-forwarded request body with ordinary `Request.json()`.

At the exact review subject:

- `src/http-body.ts` explicitly supports `Content-Encoding: zstd` and decompresses it before JSON parsing.
- `src/native-passthrough.ts` uses that decoder, successfully extracts the request model, but preserves the original encoded bytes when bridge-artifact scrubbing makes no change.
- The resulting upstream request is then passed to `fetchNativeCodex`.
- `src/native-network.ts::requestModel()` independently calls `request.clone().json()`; it does not decode zstd. Parsing therefore fails and is caught as an unknown model.
- Unknown model selects the ordinary `native` route.

The repository already has a native-passthrough regression proving zstd request bodies are a supported input path and that their original encoded bytes are intentionally preserved.

Consequences for a zstd-compressed body containing `"model":"muse-..."`:

- with Codex-LB configured, the request can be rewritten to Codex-LB with the native key;
- without a custom native upstream, it can remain aimed at the official Codex backend;
- this occurs even though `native-passthrough` had already decoded and identified the Muse model.

That violates M01-T02's fail-closed contract and the milestone's deterministic `muse-* -> CLIProxyAPI` routing rule.

## Required correction

Do not rediscover the route by reparsing the preserved encoded request after `native-passthrough` has already decoded it. Carry the already-decoded model or an explicit route hint into the native network layer, or otherwise make routing consume the same content-encoding-aware decoded representation without losing the intentionally preserved raw request body.

Add regression coverage proving at least:

1. zstd-compressed `muse-*` with Codex-LB configured and no Muse upstream fails closed and is never sent to Codex-LB;
2. zstd-compressed `muse-*` with Muse configured routes to CLIProxyAPI with the Muse key;
3. ordinary zstd-compressed native traffic still routes to Codex-LB.

## Tests / runtime evidence

- The new correction test covers the original RED case for an uncompressed JSON body, but not the supported zstd path above.
- GitHub reported no workflow runs and no commit statuses for the exact review subject.
- Repository CI runs on pushes to `main` or pull requests and has no manual `workflow_dispatch`.
- This review environment has no Bun installation, and direct repository cloning was unavailable because outbound DNS to `github.com` failed, so the Bun test suite could not be executed here.

The RED verdict is based on a directly readable fail-open path in the exact reviewed source and does not depend on the unavailable full runtime suite.

## Re-review gate

After the zstd-safe routing correction and regression tests are committed, freeze a new exact `review_subject` and require a fresh independent review before M01 can become GREEN.
