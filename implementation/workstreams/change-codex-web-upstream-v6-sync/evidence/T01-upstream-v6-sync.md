# T01 evidence — Codex Web GPT upstream v6.1 sync

Date: 2026-09-25

## Immutable implementation subject

- Candidate: `elmakus/codex-chatgpt-web@0dcf8ed9dbd229cf908cc68b31f4126c0af2414d`
- Candidate tree: `55b18ccd0395684119d7b545f5cb630dc98be084`
- Branch readback: `elmakus/codex-chatgpt-web:work/upstream-v6.1-sync` resolved to the exact candidate SHA above.
- Candidate version: `6.1.1`.
- Upstream target: `miuuyy/codex-chatgpt-web@293341084ac7a1ddd2de12fede3706023f5b6474` / stable `v6.1.0`.
- Published fork baseline: `elmakus/codex-chatgpt-web@d7c9db70cf1d54029c061490d73335146a23ed28` / `v5.0.16`.
- Current fork main integrated into candidate history: `elmakus/codex-chatgpt-web@0f77eb00203f93617f7c38a24ad4e1c6e1cc9d3b`.

The tested upstream merge commit was `7f1f20e26d9503ec28cb5af9b485c1f7c1a954ed`.
After joining current fork main history, final candidate `0dcf8ed9dbd229cf908cc68b31f4126c0af2414d`
has the identical tree `55b18ccd0395684119d7b545f5cb630dc98be084`; no content changed after the test subject.

## Integration result

The upstream v6.1 implementation was retained, including current ChatGPT UI/browser behavior,
new v6 model/effort surfaces, Limits support, multipart-6 Bigger Context and the upstream AST-based
Codex interrupt-hook ownership implementation.

Fork-specific behavior was preserved on the v6.1 base:
- configurable Codex-LB native upstream with dedicated authentication and persistent key-file handling;
- parallel `muse-*` routing through CLIProxyAPI with independent authentication;
- Muse model catalog merge and OpenAI-compatible catalog normalization;
- Muse Gmail namespace omission and `web_search.search_content_types` compatibility normalization;
- native proxy-resolution/model-hint/zstd routing behavior;
- Workstation update/release provenance behavior;
- native interrupt-hook normalization/recovery, forward-ported onto upstream's AST implementation rather than restoring the old parser.

The initial merge produced seven textual conflicts. They were resolved semantically. Joining the
previous fork-main-only hook-recovery history afterward produced two conflicts in code already
forward-ported; keeping the tested candidate side yielded an identical tree.

## Verification

Focused fork/compatibility regression:
- 122 passed, 0 failed, 958 assertions.
- Covers Codex-LB, Muse/CLIProxyAPI routing/catalog, Muse passthrough normalization, model catalog,
  interrupt-hook recovery and integration lifecycle.
- `bun run check-version`: GREEN (`VERSION_SYNC_OK 6.1.1 bun@1.4.0`).
- TypeScript typecheck: GREEN.

Full runtime suite:
- 811 passed, 4 skipped, 0 failed.
- 6088 assertions across 58 files.

Launcher:
- Full Node 24 launcher test suite: GREEN, exit 0.
- Runtime bundle build: GREEN.
- Launcher TypeScript + Vite production build: GREEN.

Linux package:
- Release-path compatible libnotify 0.8.7 built successfully and proved to export
  `notify_notification_get_activation_app_launch_context`.
- Owned AppImage toolset prepared successfully.
- AppImage packaged as fork version 6.1.1 with `APPIMAGE_TOOLS_PATH` explicitly consumed by electron-builder.
- Representative package/ABI smoke against the Workstation Linux runtime environment:
  `PACKAGED_LAUNCHER_SMOKE_OK linux/x64`.

Intermediate smoke failures were environment-only and preserved in execution telemetry:
minimal test images lacked either `readelf`, `file`, or desktop runtime libraries. The final
release-path package plus representative runtime smoke is GREEN.

## Refresh Gate

Immediately before freezing the subject:
- upstream `main` still resolved to `293341084ac7a1ddd2de12fede3706023f5b6474`;
- upstream latest stable release remained `v6.1.0`;
- fork `main` still resolved to `0f77eb00203f93617f7c38a24ad4e1c6e1cc9d3b`.

No production Workstation image was rebuilt or promoted, no fork release was published, and no fork-main merge was performed.
