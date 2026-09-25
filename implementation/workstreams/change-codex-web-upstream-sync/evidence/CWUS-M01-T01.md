# CWUS-M01-T01 implementation evidence

## Frozen implementation subject

- Repository: `elmakus/codex-chatgpt-web`
- Migration branch: `work/upstream-v6.1.0-sync`
- Immutable reviewed candidate: `2900b93a800f2c01e68aaba7b35c6600a6bbf25b`
- Draft PR: `elmakus/codex-chatgpt-web#19`
- Candidate tree: `5c94073d11c6524b4294ced296b660011323905c`
- Latest upstream stable rechecked before freeze: `v6.1.0`

## Source ancestry

The candidate contains all three required source lines:

- upstream `miuuyy/codex-chatgpt-web@v6.1.0`: `293341084ac7a1ddd2de12fede3706023f5b6474`
- deployed fork `elmakus/codex-chatgpt-web@v5.0.16`: `d7c9db70cf1d54029c061490d73335146a23ed28`
- current fork `main`: `0f77eb00203f93617f7c38a24ad4e1c6e1cc9d3b`

`71fd16fe920c0213fb9922c316ac0ac07ecd03a9` merged upstream v6.1.0 with the deployed v5.0.16 behavior. `2900b93a800f2c01e68aaba7b35c6600a6bbf25b` then merged current fork `main` for integration ancestry. That second merge changed no tree bytes: tree before and after remained `5c94073d11c6524b4294ced296b660011323905c`.

## Conflict reconciliation

The initial upstream/deployed-fork merge reconciled the known seven direct conflicts:

- `launcher/electron/control-server.cjs`
- `launcher/electron/main.cjs`
- `launcher/package.json`
- `package.json`
- `src/codex-interrupt-hook.ts`
- `src/version.ts`
- `tests/model-catalog.test.ts`

The final fork-main ancestry merge conflicted only in `src/codex-interrupt-hook.ts` and `tests/codex-integration.test.ts`. The v6.1 AST-based hook ownership implementation was retained because upstream v6.1 intentionally accepts equivalent native TOML serialization even when comments are discarded. The fork-specific native `enabled = false` repair path remains present through `allowNativeDisabled`, with focused regression coverage. Reintroducing the old comment-removal rejection would have regressed upstream v6.1 behavior.

## Preserved fork behavior

The candidate retains:

- Codex-LB as the optional native Codex upstream, including dedicated credential handling and fail-closed auth boundaries;
- parallel `muse-*` routing through Muse/CLIProxyAPI with independent credentials;
- Muse model-catalog normalization/merge without importing unrelated CLIProxyAPI providers;
- deployed Muse Gmail namespace filtering and web-search `search_content_types` normalization;
- encoded/zstd model-hint routing and configured native proxy-resolution support;
- native interrupt-hook recovery/normalization, including Codex-native `enabled` rewrites and multi-agent normalization;
- Workstation image-managed update behavior and fork release/checksum/provenance support.

Upstream v6.1 browser/model/effort/limits, six-part Bigger Context, current ChatGPT UI support, hidden-browser checks, compaction/environment recovery, and launcher changes remain present.

## Local verification

Final candidate tree verification:

- root suite: `811 pass`, `4 skip`, `0 fail`, `6095 expect()` calls across `58` files;
- launcher Node 22 suite: `347` tests, `346 pass`, `1 skip`, `0 fail`;
- root and launcher typecheck/build: GREEN;
- relocatable runtime smoke: `RELOCATABLE_RUNTIME_SMOKE_OK`;
- Linux x64 AppImage built: `codex-web-gpt-6.1.0-linux-x64.AppImage` (`186063796` bytes);
- packaged launcher smoke: `PACKAGED_LAUNCHER_SMOKE_OK linux/x64`;
- current Arch Linux ABI/symbol smoke: `LINUX_APPIMAGE_SYMBOL_SMOKE_OK`;
- tracked source tree clean after verification;
- upstream v6.1.0, deployed v5.0.16, and current fork main all verified as ancestors of the candidate.

## GitHub Actions verification

Draft PR `#19` triggered CI run `36175596450` against immutable head `2900b93a800f2c01e68aaba7b35c6600a6bbf25b`.

- `actionlint`: success
- `verify (ubuntu-latest)`: success
- `verify (macos-15)`: success
- `verify (windows-latest)`: success
- Windows packaged launcher smoke recorded `PACKAGED_LAUNCHER_SMOKE_OK win32/x64`.

## Publication/deployment boundary

No stable fork release or tag was created. Workstation production was not rebuilt or mutated by this Card. Publication remains gated on independent GREEN review of this exact immutable subject.
