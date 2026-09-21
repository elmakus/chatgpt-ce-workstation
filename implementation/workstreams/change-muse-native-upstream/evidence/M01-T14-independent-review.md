# M01-T14 independent review

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T14`
Verdict: **GREEN**

## Exact reviewed subject

`elmakus/codex-chatgpt-web@acc95f7a5447144bdfc5cd40ff50ce7e63dd3e95`

Review owner: workstream Task Board Card review for M01-T14.

## Authority checked

- `implementation/workstreams/change-muse-native-upstream/cards/M01-T14.md`.
- `planning/MUSE_NATIVE_UPSTREAM_PLAN.md` approved R8 / M01 planned work 0-2.
- `requirements/MUSE_NATIVE_UPSTREAM.md` R2, R6 and R7.
- `docs/DECISIONS.md` D29 and D30.
- `implementation/workstreams/change-muse-native-upstream/research/R2.md`.
- `implementation/workstreams/change-muse-native-upstream/evidence/M01-T13-muse-activation-blocker.md`.
- exact related-fork subject, PR #17 diff and CI run 35617383232.

## Review findings

GREEN. The exact subject is two commits ahead of the published v5.0.15 baseline `3a6d1d28c28dbe1be885077ae53fe4bba62b9673`, zero behind, and changes only `src/native-passthrough.ts` plus `tests/native-passthrough.test.ts`. No version/release metadata, Workstation source, CLIProxyAPI source/configuration or credential material is part of the subject.

The implementation extends the existing Muse Responses normalization in place. The new path is gated by exact `endpoint === "responses"`, a validated request model and `isMuseNativeModel(model)` (`muse-*`). It preserves the existing exact Gmail namespace omission. For exact `type: "web_search"` entries that own `search_content_types`, it clones that tool, deletes only `search_content_types`, preserves every other property and tool ordering, and leaves `web_search_preview` untouched.

When no Muse compatibility rewrite and no existing bridge scrub is needed, the original request bytes and zstd content encoding remain unchanged. When a bounded rewrite occurs, the existing JSON reserialization path removes stale `content-encoding`. Ordinary native/Codex-LB requests retain Gmail and the multimodal `web_search.search_content_types` shape byte-for-byte. Browser-backed `chatgpt-web/*` behavior is outside the changed files.

Focused regression coverage proves property-only omission, preservation of remaining `web_search` properties and unrelated tools/order, Gmail composition, preview non-overreach/no-op byte preservation, ordinary-native byte preservation and zstd rewrite behavior. Existing routing/catalog/bridge behavior remains covered by the unchanged verification suite.

## Independent verification

- PR #17 is draft/open/mergeable with exact base `release/v5.0.15@3a6d1d28c28dbe1be885077ae53fe4bba62b9673` and exact head `acc95f7a5447144bdfc5cd40ff50ce7e63dd3e95`.
- GitHub compare confirms exactly 2 changed files, 2 commits ahead and 0 behind the accepted release baseline.
- CI run `35617383232` completed successfully for the exact subject.
- GREEN jobs: actionlint; Ubuntu/macOS/Windows `bun run verify`; package checks; app smoke; Linux AppImage ABI validation on Ubuntu.

## Verdict

**GREEN** — M01-T14 satisfies its bounded authority and acceptance contract. It is suitable for deterministic post-review Card finalization and the approved R8 release sequence.
