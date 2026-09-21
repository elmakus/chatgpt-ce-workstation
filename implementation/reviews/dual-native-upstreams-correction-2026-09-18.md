# Dual native upstreams — corrective implementation evidence

Date: 2026-09-18

## Corrective subject

- Repository: `elmakus/codex-chatgpt-web`
- Branch: `feat/dual-native-upstreams`
- Corrected implementation head: `0cad74ba6f3f9bc13d6e973d94bc993d8b2ff5c3`
- Corrective base / prior RED subject: `2c7eb2ac5266df0cf198a11abb14eba314f411e0`
- Corrective card: `M01-T02`

## RED finding addressed

The prior independent review found that automatic routing classified `muse-*` as ordinary native traffic whenever `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` was absent, allowing a Muse request to fall through to Codex-LB or the official native backend.

The correction makes automatic route classification depend only on model identity:

```ts
isMuseNativeModel(model) ? "muse" : "native"
```

The existing Muse-route validation now fails closed when the Muse upstream is missing.

## Regression coverage added

`tests/native-network-upstream.test.ts` now covers the exact RED case:

- Codex-LB is configured.
- Muse upstream is absent.
- A `muse-spark-1.3` request must reject with the Muse-upstream configuration error.
- In the same configuration, a normal native model still rewrites to Codex-LB and uses the Codex-LB key.

## Verification performed

- GitHub readback confirmed the branch is exactly two commits ahead of the prior RED subject and changes only:
  - `src/native-network.ts`: one routing condition changed;
  - `tests/native-network-upstream.test.ts`: regression test added.
- Exact source readback confirms `muse-*` selects the Muse route without checking whether the Muse upstream is configured.
- A direct Node runtime check of the corrected routing/rewrite logic returned `TARGETED_ROUTE_CHECK_GREEN`:
  - Muse without Muse upstream failed closed with `NativeProxyConfigurationError`;
  - ordinary native traffic still rewrote to Codex-LB with the dedicated native key.

## Verification limitation

Full repository Bun verification was not executed in this ChatGPT runtime.

- Repository CI triggers only on pushes to `main` or pull requests and has no `workflow_dispatch`.
- The current container does not have Bun installed.
- A PR was not opened merely to obtain CI before the required independent review.

This evidence is implementation evidence only. It is not an independent GREEN verdict.

## Review boundary

A fresh normal ChatGPT chat must independently review the exact corrected head above using the same routing/auth/catalog authority slice. The implementing chat must not issue the independent verdict.
