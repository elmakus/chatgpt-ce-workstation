# M01-T08 evidence — Muse-only Gmail namespace filter

Status: implementation complete; pending independent review
Card: `M01-T08`
Date: 2026-09-21

## Exact related-fork subject

- Repository: `elmakus/codex-chatgpt-web`
- Base: `main@2686d2a616864a1bc9cd975901773ab16a54ba47` (released v5.0.14 baseline)
- Branch: `fix/muse-gmail-namespace-filter`
- Review subject / implementation HEAD: `2bd8a74a6f467767c7a640806720e672f7342471`
- Pull request: `elmakus/codex-chatgpt-web#13`
- Changed files:
  - `src/native-passthrough.ts`
  - `tests/native-passthrough.test.ts`
- No version/release metadata changed.

## Implemented behavior

The existing decoded native Responses boundary now removes a tool entry only when all of the following are true:

- endpoint is native `responses`;
- the already-validated model is `muse-*`;
- the top-level tool entry is exactly `type: "namespace"`;
- its name is exactly `mcp__codex_apps__gmail`.

All non-Gmail tool entries retain their original order/content. If that Gmail namespace is absent, this feature does not rewrite the body. Ordinary native/Codex-LB requests retain Gmail unchanged.

When a Muse Gmail removal requires reserialization, the forwarded request drops stale `content-encoding`; existing passthrough logic already drops stale `content-length`. Existing zstd decode, bridge-artifact scrubbing, native/Muse routing and separate credentials remain owned by the same fork boundaries.

## Regression coverage

Focused tests include:

- a zstd-compressed Muse Responses request containing an R1-shaped Gmail namespace with recursive `#/$defs/GmailMessagePartRequest`;
- preservation and ordering of representative non-Gmail function/namespace tools;
- forwarded Muse request uses the Muse upstream and no stale `content-encoding`;
- ordinary native zstd Responses with the same Gmail namespace remains byte-for-byte unchanged;
- the pre-existing zstd Muse request without Gmail remains byte-for-byte unchanged, covering the no-op case.

## CI / verification

GitHub Actions CI run `35598358048` on exact subject `2bd8a74a6f467767c7a640806720e672f7342471` completed GREEN.

- `actionlint`: GREEN
- macOS 15: `bun run verify` GREEN; package GREEN; app smoke GREEN
- Ubuntu: `bun run verify` GREEN; package GREEN; Linux AppImage ABI GREEN; app smoke GREEN
- Windows: `bun run verify` GREEN; package GREEN; app smoke GREEN

The PR diff is limited to the focused request filter and its regression tests.

## Boundary / safety readback

- Workstation production was not mutated.
- `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` production activation remains rolled back/unset under the accepted R7 baseline.
- CLIProxyAPI/Meta configuration/source was not changed.
- No credential was added, printed or committed.
- No Workstation provider-routing or request-body filtering logic was added.
