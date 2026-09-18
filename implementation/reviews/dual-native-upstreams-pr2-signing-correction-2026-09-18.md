# M01-T05 implementation evidence — PR macOS ad-hoc signing

Date: 2026-09-18

## Subject

- Implementation repository: `elmakus/codex-chatgpt-web`
- Branch: `feat/dual-native-upstreams`
- PR: #2
- T05 base: `afef9e799599e8c31539ed60689a3828be7728ea`
- Corrected implementation subject: `4eaa9c350a885faa627e3e681a8d8861c9f4ba41`
- Corrective range: exactly one commit, changing only `launcher/scripts/package.cjs`
- PR CI run: `35299105025`

## Correction

The package script already used ad-hoc macOS identity `-` whenever neither `CSC_LINK` nor `CSC_NAME` was configured.

Electron Builder suppresses signing for pull-request builds by default, which made the repository's later unconditional `codesign --verify --deep --strict` check fail.

The correction sets `CSC_FOR_PULL_REQUEST=true` only when all of the following are true:

- target is macOS;
- event is `pull_request`;
- `CSC_LINK` is absent;
- `CSC_NAME` is absent.

The existing ad-hoc identity `-` is retained. Credentialed signing behavior is not broadened by this branch and no signing secret/certificate is introduced.

## Readback

GitHub confirms the corrective diff adds only the guarded PR flag and explanatory comment in `launcher/scripts/package.cjs`.

PR #2 points exactly at the corrected subject.

The completed macOS CI log directly records:

- Electron Builder signing the app with `identityName=-`;
- the package step continuing through ZIP/DMG construction;
- `bun run app:package` GREEN;
- `bun run app:smoke` GREEN.

Because `verifySignedMacArchive()` unconditionally runs `codesign --verify --deep --strict` before `app:package` can succeed, the GREEN package step is also direct evidence that the extracted PR archive passed the existing signature verification.

## CI result

Workflow run `35299105025` completed with conclusion **success**.

All jobs are GREEN:

- actionlint;
- macOS 15: `bun run verify`, `bun run app:package`, `bun run app:smoke`;
- Ubuntu latest: `bun run verify`, `bun run app:package`, `bun run app:smoke`;
- Windows latest: `bun run verify`, `bun run app:package`, `bun run app:smoke`.

## Review boundary

This is implementation evidence only, not an independent verdict.

M01-T05 is security-sensitive because it changes pull-request signing behavior. Freeze `elmakus/codex-chatgpt-web@4eaa9c350a885faa627e3e681a8d8861c9f4ba41` as the exact review subject and require a fresh normal ChatGPT independent review before T05 can become done or M01 can return GREEN / PR READY.
