# Independent review — dual native upstreams

Date: 2026-09-18

## Verdict

**RED / NOT PR READY**

## Independence and exact subject

- Reviewer: fresh normal ChatGPT chat; this chat did not implement the reviewed subject.
- Repository: `elmakus/codex-chatgpt-web`
- Review subject: `2c7eb2ac5266df0cf198a11abb14eba314f411e0`
- Base: `f8dc469a43cc562a4173bb77f7a7d9fe2b569187`
- Branch readback: `feat/dual-native-upstreams` still pointed at the exact review subject during review.

## Accepted user decisions applied during review

- Muse is intended for simple single tasks; the Muse `multi_agent_version` difference is not a blocker.
- Do not hardcode or overwrite the Muse context window. Preserve the value reported by CLIProxyAPI/Meta.

## Scope reviewed independently

The review read the exact source at the review subject, the changed-file set from base to head, current routing/passthrough code, the added tests, and the implementing evidence without adopting its verdict.

Primary checks:
- `chatgpt-web/*` -> local ChatGPT Web adapter
- `muse-*` -> CLIProxyAPI -> Meta
- remaining native models -> Codex-LB
- separate proxy credentials and replacement of incoming ChatGPT bearer
- `/models` merge/filtering and CLIProxyAPI catalog failure isolation
- tests and available CI/runtime evidence

## Confirmed behavior

- `chatgpt-web/*` requests stay on the local adapter path; non-`chatgpt-web/*` models enter native passthrough.
- With `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` configured, `muse-*` JSON requests are rewritten to the Muse/CLIProxyAPI base and use only the Muse ingress key.
- Non-Muse native JSON requests remain on the primary native/Codex-LB upstream and use the native/Codex-LB key.
- Muse and native credentials are resolved independently; the network rewrite replaces `Authorization` with the selected proxy key.
- Successful model discovery imports only `muse-*` rows from the CLIProxyAPI catalog and keeps ChatGPT Web rows after native rows.
- A failing optional Muse catalog request is caught so the primary Codex-LB + ChatGPT Web catalog still returns.
- Muse catalog rows are merged after primary native augmentation, so the accepted decision is respected: Muse context window and `multi_agent_version` are not rewritten by the bridge.

## Blocking finding

### R1 — `muse-*` does not fail closed when the Muse upstream is absent

In `src/native-network.ts`, automatic route selection is currently equivalent to:

```ts
hasMuseNativeUpstream() && isMuseNativeModel(model) ? "muse" : "native"
```

Therefore a request whose model is `muse-*` is classified as **native** whenever `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` is unset/empty.

Consequences:
- if `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM` is configured, the Muse request is rewritten to Codex-LB with the native/Codex-LB key;
- if the primary custom native upstream is also absent, it can remain aimed at the official Codex backend.

This contradicts the accepted deterministic routing contract:

`muse-* -> CLIProxyAPI -> Meta`

A missing Muse route must not silently reinterpret a Muse model as an ordinary native model.

### Required correction

Route classification must depend on the model ID, not on whether the Muse upstream happens to be configured. For automatic routing, `muse-*` must select the Muse route unconditionally; the existing Muse-route validation can then fail closed with `NativeProxyConfigurationError` when the Muse upstream or key is absent.

Add regression coverage proving that:
1. a `muse-*` request with Codex-LB configured but no Muse upstream does **not** produce a Codex-LB request and fails closed;
2. an ordinary native model still routes to Codex-LB in the same configuration.

## Tests / runtime evidence

- Added source tests cover configured Muse routing, non-Muse routing, separate keys, persistent Muse key lookup, Muse catalog filtering, and optional Muse-catalog failure isolation.
- No test covers the blocking missing-Muse-upstream case above.
- GitHub reported no workflow runs and no commit statuses for the exact review subject.
- Local runtime verification could not be executed in this chat because the container cannot resolve `github.com`, so the exact repository could not be cloned for `bun run verify`.

The RED verdict is based on a directly readable routing defect in the exact reviewed source and does not depend on the missing runtime execution.

## Re-review gate

After the routing correction and regression test are committed, set a new exact `review_subject` and require a fresh independent review before M01 can become GREEN.
