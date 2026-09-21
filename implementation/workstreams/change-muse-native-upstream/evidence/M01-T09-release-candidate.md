# M01-T09 — v5.0.15 release-candidate evidence

Date: 2026-09-21
Card: `M01-T09`

## Reviewed correction integration

- Related fork: `elmakus/codex-chatgpt-web`
- Independently GREEN behavioral subject from M01-T08: `2bd8a74a6f467767c7a640806720e672f7342471`
- PR #13 was re-read immediately before merge and still had the exact reviewed head.
- PR #13 merge result: `d752b2609d8a173e0b6f516f3dcbae4b509640d1`.
- The merge commit parents are the previous main `2686d2a616864a1bc9cd975901773ab16a54ba47` and exact reviewed correction `2bd8a74a6f467767c7a640806720e672f7342471`.

## Release candidate

- Branch: `release-prep/v5.0.15`
- Candidate PR: `elmakus/codex-chatgpt-web#15` (draft; no publication action)
- Immutable candidate subject: `3a6d1d28c28dbe1be885077ae53fe4bba62b9673`
- Candidate base at preparation time: post-correction merge `d752b2609d8a173e0b6f516f3dcbae4b509640d1`
- Candidate delta from that base is version-only:
  - `package.json`: 1 addition / 1 deletion
  - `launcher/package.json`: 1 addition / 1 deletion
  - `src/version.ts`: 1 addition / 1 deletion
- Exact versions at candidate SHA:
  - package version: `5.0.15`
  - launcher package version: `5.0.15`
  - runtime version: `5.0.15`
  - `upstreamLauncherVersion`: unchanged at `5.0.8`

An intermediate formatting-only launcher diff was detected before the PR was opened and corrected. The final candidate has no formatting churn and exactly three version-line changes.

## CI

GitHub Actions CI run `35600382479`, exact head `3a6d1d28c28dbe1be885077ae53fe4bba62b9673`: **GREEN**.

- `actionlint`: success
- macOS 15: `bun run verify`, package, app smoke — success
- Ubuntu: `bun run verify`, package, Linux AppImage ABI, app smoke — success
- Windows: installer validation, `bun run verify`, package, app smoke — success

## Publication isolation

Readback after candidate creation:

- no `v5.0.15` tag exists;
- no `release/v5.0.15` publication-triggering branch exists;
- latest published release remains `v5.0.14`.

No Workstation, CLIProxyAPI or production Muse activation state was changed by this Card.

## Concurrent-main drift

After the candidate was frozen and CI had started, related-fork `main` advanced independently from `d752b260...` to `0f77eb00203f93617f7c38a24ad4e1c6e1cc9d3b` by seven commits affecting only the separate Codex interrupt-hook/integration surface (`src/codex-interrupt-hook.ts`, `src/codex-integration*.ts` and their tests).

Those unrelated concurrent commits were deliberately **not** absorbed into this R7 release candidate. Doing so would broaden the immutable corrected-release subject beyond the reviewed Gmail correction plus version metadata. The candidate remains rooted at the exact post-M01-T08 merge state and its own delta remains version-only.

Any later publication/integration step must preserve this exact reviewed release subject and must account for the now-advanced unrelated `main` without silently adding those unrelated commits to v5.0.15.

## Review freeze

Independent review subject:

`elmakus/codex-chatgpt-web@3a6d1d28c28dbe1be885077ae53fe4bba62b9673`

Review should confirm the exact subject contains the accepted M01-T08 correction, only synchronized v5.0.15 metadata beyond the post-correction base, required CI is GREEN, publication has not occurred, and the concurrent-main drift is not accidentally folded into the release candidate.
