# M01-T14 — related-fork Muse web-search normalization evidence

Status: implementation complete; independent review pending
Implementation subject: `elmakus/codex-chatgpt-web@acc95f7a5447144bdfc5cd40ff50ce7e63dd3e95`
Related-fork branch: `work/muse-web-search-normalization`
Review vehicle: `elmakus/codex-chatgpt-web#17` (draft)
Exact base: `release/v5.0.15@3a6d1d28c28dbe1be885077ae53fe4bba62b9673`

## Scope readback

GitHub compare `release/v5.0.15...work/muse-web-search-normalization` is exactly two commits ahead and zero behind the published v5.0.15 base. The diff contains only:

- `src/native-passthrough.ts`
- `tests/native-passthrough.test.ts`

No package/version metadata, Workstation source, CLIProxyAPI source/configuration, credentials, or production runtime state changed.

The existing Muse Responses normalization was extended in place. For validated `muse-*` `responses` requests it now:

- preserves the existing exact `mcp__codex_apps__gmail` namespace omission;
- preserves every `web_search` tool entry while deleting only its own `search_content_types` property when present;
- preserves unrelated tool entries/properties and relative order;
- does not apply the property normalization to `web_search_preview`;
- preserves the existing no-rewrite path and original encoded request bytes when no bounded compatibility rewrite is needed;
- preserves the existing reserialization/content-encoding handling when a Muse compatibility rewrite is required.

Ordinary native/Codex-LB behavior and browser-backed `chatgpt-web/*` behavior were not changed by this subject.

## Regression coverage

Focused `tests/native-passthrough.test.ts` coverage now proves:

- exact property-only omission on Muse `web_search`;
- preservation of remaining `web_search` properties plus representative function/namespace tools and order;
- composition with the accepted Muse Gmail namespace omission;
- `web_search_preview` non-overreach with zstd bytes preserved;
- ordinary native Gmail plus multimodal `web_search.search_content_types` remain byte-for-byte preserved;
- existing Muse no-op, Gmail-only, zstd routing, native passthrough, catalog/routing and bridge behavior remain covered by the existing suite.

## CI / package evidence

GitHub Actions CI run `35617383232` completed **success** on exact subject `acc95f7a5447144bdfc5cd40ff50ce7e63dd3e95`.

GREEN jobs/checks:

- `actionlint`
- `verify (ubuntu-latest)`: `bun run verify`, app package, Linux AppImage ABI, app smoke
- `verify (macos-15)`: `bun run verify`, app package, app smoke
- `verify (windows-latest)`: installer validation, `bun run verify`, app package, app smoke

PR #17 readback after CI remains draft/open/mergeable with exact base `3a6d1d28c28dbe1be885077ae53fe4bba62b9673` and exact head `acc95f7a5447144bdfc5cd40ff50ce7e63dd3e95`.

## Review boundary

Card review requirement is `RECOMMENDED`. The exact implementation subject above is frozen for a fresh independent review before M01-T14 can become terminal or any release/D25/production activation work can begin.
