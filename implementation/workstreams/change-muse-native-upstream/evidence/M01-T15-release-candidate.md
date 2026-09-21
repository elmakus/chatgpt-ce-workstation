# M01-T15 — v5.0.16 release-candidate evidence

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T15`
Status: implementation complete; independent review pending

## Exact candidate subject

`elmakus/codex-chatgpt-web@d7c9db70cf1d54029c061490d73335146a23ed28`

Candidate branch: `release-prep/muse-v5.0.16`
Review vehicle: `elmakus/codex-chatgpt-web#18` (draft)
Published baseline: `release/v5.0.15@3a6d1d28c28dbe1be885077ae53fe4bba62b9673`
Behavioral predecessor: independently GREEN M01-T14 subject `acc95f7a5447144bdfc5cd40ff50ce7e63dd3e95`

## Candidate construction and scope readback

The fresh candidate branch was created directly from the exact independently GREEN M01-T14 subject. One candidate commit was added:

- `d7c9db70cf1d54029c061490d73335146a23ed28` — `chore(release): prepare v5.0.16 candidate`

Compare from M01-T14 subject to the candidate is exactly one commit, zero behind, and exactly three modified files:

- `package.json`
- `launcher/package.json`
- `src/version.ts`

Those three changes only synchronize the release version from `5.0.15` to `5.0.16`. `package.json.upstreamLauncherVersion` remains `5.0.8`.

Compare from published v5.0.15 to the candidate is exactly three commits, zero behind, and exactly five changed files:

- the already independently GREEN M01-T14 behavior/test files:
  - `src/native-passthrough.ts`
  - `tests/native-passthrough.test.ts`
- the three version-only files above.

No unrelated current-`main` interrupt-hook/integration drift is present.

The pre-existing divergent branch `release-prep/v5.0.16` was not reset, modified or reused; readback remained `68142a3f1725e052a606f488ac2c525db650a661`.

PR #18 is draft/open/mergeable with exact base `release/v5.0.15@3a6d1d28c28dbe1be885077ae53fe4bba62b9673` and exact head `d7c9db70cf1d54029c061490d73335146a23ed28`. No release trigger branch/tag/release was created.

## CI / package evidence

GitHub Actions CI run `35621150066` completed **success** for exact candidate `d7c9db70cf1d54029c061490d73335146a23ed28`.

Final GREEN jobs/checks:

- `actionlint`
- `verify (ubuntu-latest)`: `bun run verify`, app package, Linux AppImage ABI, app smoke
- `verify (macos-15)`: `bun run verify`, app package, app smoke
- `verify (windows-latest)`: installer validation, `bun run verify`, app package, app smoke

The first Windows attempt failed only because two unrelated trusted-environment-continuity tests exceeded their 5-second timeout. No candidate file was changed. A single same-SHA Windows job rerun was performed; `bun run verify`, packaging and app smoke all completed GREEN. Ubuntu and macOS remained GREEN from the same run. Therefore the final accepted CI matrix is GREEN on the unchanged immutable candidate.

## Boundary readback

- no `release/v5.0.16` publication branch was created by this Card;
- no `v5.0.16` tag/release was published;
- related-fork `main` was not integrated or mutated by this Card;
- Workstation source/runtime, CLIProxyAPI and production Muse state were not mutated;
- no credential value was added to source or evidence.

## Review boundary

M01-T15 review requirement is `RECOMMENDED`. The exact candidate subject above is frozen for a fresh independent review before any v5.0.16 publication work may begin.
