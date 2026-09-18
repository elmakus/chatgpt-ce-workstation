# PR #2 publication verification — T04 GREEN, macOS PR signing blocker

Date: 2026-09-18

## Subject

- Implementation repository: `elmakus/codex-chatgpt-web`
- PR: #2
- Corrected T04 subject: `afef9e799599e8c31539ed60689a3828be7728ea`
- T04 base: `eeb57d0855f7baffc3089f66c7c84d2c06c40ef6`
- Workflow run: `35298637056`

## M01-T04 result

**GREEN**

The corrective range is exactly one commit and changes only `tests/native-passthrough.test.ts`.

The zstd regression helper now copies the `Bun.zstdCompressSync(...)` bytes into an `ArrayBuffer` before using them as `Request.body`. The exact compressed bytes are retained while the body is TypeScript-compatible.

PR #2 CI confirmed `bun run verify` GREEN on all three matrix operating systems:

- macOS 15: GREEN
- Ubuntu latest: GREEN
- Windows latest: GREEN

This closes the TypeScript/BodyInit failure recorded for the prior subject.

## New publication blocker

The same PR workflow reaches a separate failure after `bun run verify` on macOS, during `bun run app:package`.

Electron Builder reports that the current build is part of a pull request and therefore skips code signing. The repository packaging script then extracts the generated macOS ZIP and unconditionally runs:

`codesign --verify --deep --strict <app bundle>`

The PR job consequently fails with:

`code has no resources but signature indicates they must be present`

and then:

`error: codesign failed with status 1`.

Relevant current source facts:

- `.github/workflows/ci.yml` runs `bun run app:package` for pull requests on macOS.
- `launcher/scripts/package.cjs` already selects ad-hoc identity `-` when neither `CSC_LINK` nor `CSC_NAME` is configured.
- Electron Builder nevertheless suppresses signing specifically because the event is a pull request.
- The latest main push CI at `f8dc469a43cc562a4173bb77f7a7d9fe2b569187` completed successfully, including the macOS packaging job.

## Required bounded correction

For the no-credential macOS packaging path only, allow Electron Builder to perform the already-selected ad-hoc signing in pull-request CI so the existing archive `codesign --verify` check remains meaningful.

Do not broaden credentialed signing for pull requests and do not expose or require signing secrets.

After the correction, PR #2 publication CI must be re-run and the corrected subject must undergo independent review before milestone acceptance/publication can return GREEN.
