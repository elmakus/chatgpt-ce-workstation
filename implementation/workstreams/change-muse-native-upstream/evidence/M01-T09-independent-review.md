# M01-T09 independent review

Date: 2026-09-21
Card: `M01-T09`
Verdict: **GREEN**

## Immutable subject

- Repository: `elmakus/codex-chatgpt-web`
- Subject: `3a6d1d28c28dbe1be885077ae53fe4bba62b9673`
- Candidate PR: `elmakus/codex-chatgpt-web#15`
- Candidate preparation base: `d752b2609d8a173e0b6f516f3dcbae4b509640d1`

## Authority reviewed

- `requirements/MUSE_NATIVE_UPSTREAM.md` R2, R6, R7
- D29 — Muse optional parallel native upstream through CLIProxyAPI
- D30 — Muse-bound Codex turns intentionally omit Gmail tools
- approved `planning/MUSE_NATIVE_UPSTREAM_PLAN.md` R7 / M01 planned work 2
- `implementation/workstreams/change-muse-native-upstream/cards/M01-T09.md`
- M01-T08 independent GREEN subject `2bd8a74a6f467767c7a640806720e672f7342471`

## Independent findings

PR #13 is merged and records exact reviewed head `2bd8a74a6f467767c7a640806720e672f7342471` with merge commit `d752b2609d8a173e0b6f516f3dcbae4b509640d1`. The candidate subject is a descendant of that reviewed correction.

Comparing `d752b2609d8a173e0b6f516f3dcbae4b509640d1` to the immutable candidate changes exactly three files, one version line each:
- `package.json`: `5.0.14` → `5.0.15`
- `launcher/package.json`: `5.0.14` → `5.0.15`
- `src/version.ts`: `5.0.14` → `5.0.15`

`package.json.upstreamLauncherVersion` remains `5.0.8`. The final cumulative candidate has no formatting or behavioral delta beyond those three version-line changes. The candidate also remains a descendant of the exact M01-T08 GREEN subject, so no substitute Gmail-filter correction was introduced.

PR #15 is still open/draft and its head remains exact subject `3a6d1d28c28dbe1be885077ae53fe4bba62b9673`. Current related-fork `main` has diverged after the candidate base with unrelated Codex interrupt/integration changes; those files are absent from the candidate delta and were not silently folded into this release subject.

Publication isolation remains intact: branch search finds no `release/v5.0.15`; ref lookup for tag `v5.0.15` returns not found, while `v5.0.14` still resolves. The candidate itself contains no credentials or runtime/operator values because its cumulative delta is limited to the three version lines above.

## CI readback

GitHub Actions run `35600382479` is GREEN for the exact candidate subject:

- `actionlint`: GREEN
- macOS 15: `bun run verify`, package, app smoke — GREEN
- Ubuntu: `bun run verify`, package, Linux AppImage ABI, app smoke — GREEN
- Windows: installer validation, `bun run verify`, package, app smoke — GREEN

## Verdict

**GREEN.** The immutable v5.0.15 release candidate satisfies the M01-T09 contract: it preserves the independently accepted Muse Gmail correction, adds only synchronized release-version metadata, keeps launcher-upstream metadata unchanged, passes the required CI/package gates, and remains unpublished at this reversible checkpoint.

The later publication/integration step must continue to preserve this exact reviewed release subject rather than absorbing the unrelated commits that advanced `main` after the candidate was frozen.
