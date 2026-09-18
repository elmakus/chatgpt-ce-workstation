# M01-T04 implementation evidence — PR #2 typecheck correction

Date: 2026-09-18

## Corrective subject

- Implementation repository: `elmakus/codex-chatgpt-web`
- Branch: `feat/dual-native-upstreams`
- Corrective base: `eeb57d0855f7baffc3089f66c7c84d2c06c40ef6`
- Corrected head: `afef9e799599e8c31539ed60689a3828be7728ea`
- Pull request: #2
- Corrective range: one commit, one file: `tests/native-passthrough.test.ts` (+4/-2)

## Cause and correction

PR #2 workflow run `35298432101` exposed a TypeScript error in the newly added zstd regression helper: the result of `Bun.zstdCompressSync()` was a `Buffer<ArrayBufferLike>` and was passed directly as `Request.body`, which is not accepted as `BodyInit` by repository typecheck.

The correction is test-only:

- retain the exact bytes returned by `Bun.zstdCompressSync()`;
- allocate an `ArrayBuffer` of identical byte length;
- copy the compressed bytes into that buffer with `new Uint8Array(encoded).set(compressed)`;
- use the `ArrayBuffer` as the request body.

This matches the existing zstd request construction pattern already present in the same test file. No routing, authentication, catalog, or production source changed.

## Verification

PR #2 rerun for corrected head: workflow run `35298637056`.

At readback:

- `actionlint`: GREEN.
- macOS: `bun run verify` GREEN.
- Ubuntu: `bun run verify` GREEN; package/ABI/smoke GREEN; job GREEN.
- Windows: `bun run verify` GREEN and package GREEN; final smoke was still in progress at the time this evidence was first written.

The macOS job remains RED only at the later `bun run app:package` step. This is a known PR-event baseline failure rather than a change introduced by M01/T04:

- the failure is `codesign failed with status 1` after electron-builder explicitly reports that code signing is skipped for pull-request builds;
- prior PR #1 workflow run `35235654447` shows the same macOS pattern: `bun run verify` GREEN followed by the same unsigned-PR codesign verification failure;
- push workflow run `35281319642` for the exact current M01 base `main@f8dc469a43cc562a4173bb77f7a7d9fe2b569187` is fully GREEN;
- neither CI workflow files nor launcher packaging scripts are in the M01/T04 diff.

## Review boundary

This chat implemented `afef9e799599e8c31539ed60689a3828be7728ea`, so it does **not** issue the required independent acceptance verdict for that changed subject.

The exact next review subject is:

`elmakus/codex-chatgpt-web@afef9e799599e8c31539ed60689a3828be7728ea`

A fresh normal ChatGPT independent review is required before PR #2 may be merged. The review should verify the one-commit corrective diff, the preserved M01 acceptance slice, and the documented PR-only macOS packaging baseline exception.
