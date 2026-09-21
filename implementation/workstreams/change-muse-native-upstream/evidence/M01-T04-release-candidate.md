# M01-T04 release-candidate evidence

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T04`

## Reviewed predecessor integration

- M01-T03 independent review was GREEN for exact related-fork subject `elmakus/codex-chatgpt-web@9ec01b939a08a191082b551bc2d6dc738a0159e2`.
- Related-fork PR #11 was moved out of draft only after the exact reviewed head was re-read and remained `9ec01b939a08a191082b551bc2d6dc738a0159e2`.
- PR #11 was merged with GitHub's `expected_head_sha` guard set to that exact reviewed SHA.
- Resulting related-fork `main` merge commit: `ae3eb2734a7f95d0454ad7184f96e7727d3e0b90`.
- Readback of that merge commit shows parents:
  - previous `main@9de6a670f1934f5f4843a9df0d4b0d408884798f`;
  - exact reviewed correction `9ec01b939a08a191082b551bc2d6dc738a0159e2`.

## v5.0.14 release candidate

- Non-publishing branch: `release-prep/v5.0.14`.
- Exact base: post-merge `main@ae3eb2734a7f95d0454ad7184f96e7727d3e0b90`.
- Exact candidate HEAD: `2686d2a616864a1bc9cd975901773ab16a54ba47`.
- Candidate PR: `elmakus/codex-chatgpt-web#12` (draft, base `main`).
- PR diff: exactly 3 additions / 3 deletions across exactly 3 files:
  - `package.json`: `version 5.0.13 -> 5.0.14`;
  - `launcher/package.json`: `version 5.0.13 -> 5.0.14`;
  - `src/version.ts`: `VERSION 5.0.13 -> 5.0.14`.
- `package.json.upstreamLauncherVersion` remains `5.0.8`.
- No catalog/routing/auth/proxy/launcher behavior or unrelated formatting changed in the candidate diff.

## Candidate validation

Exact candidate CI run: `35582708176` on `2686d2a616864a1bc9cd975901773ab16a54ba47`.

Terminal result: **GREEN**.

Successful jobs:
- `actionlint`;
- `verify (ubuntu-latest)` — includes `bun run verify`, package, Linux AppImage ABI validation, app smoke;
- `verify (macos-15)` — includes `bun run verify`, package, app smoke;
- `verify (windows-latest)` — includes Windows installer validation, `bun run verify`, package, app smoke.

The repository's `bun run verify` includes version-sync validation, so the synchronized `5.0.14` metadata passed the normal release-candidate verification surface.

## Publication isolation readback

- Latest published related-fork release after candidate preparation remains `v5.0.13`.
- No `release/v5.0.14` trigger branch exists.
- No `v5.0.14` release/tag was published by this Card.
- PR #12 remains draft and unmerged.

## Review boundary

M01-T04 deliberately stops at the exact reversible release candidate:
`elmakus/codex-chatgpt-web@2686d2a616864a1bc9cd975901773ab16a54ba47`.

The next role is a fresh independent review of this exact candidate before any release publication action.
