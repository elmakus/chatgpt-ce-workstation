# Intake — Codex Web upstream sync

Date: 2026-09-25
Workstream ID: `change-codex-web-upstream-sync`
Kind: `change`
Status: active

## Operator intent

Bring the Workstation-owned fork `elmakus/codex-chatgpt-web` forward from the currently deployed fork release `v5.0.16` to current upstream `miuuyy/codex-chatgpt-web@v6.1.0`, preserving the fork-specific native Codex-LB route, parallel Muse/CLIProxyAPI route, Workstation release/update policy, and compatibility corrections that remain required.

## Discovery

- Workstation `main` at intake: `dfa41ce0867824757a50dc151afe3a87c4826457`.
- Workstation image policy resolves the latest stable release from `elmakus/codex-chatgpt-web`; the currently deployed release is `v5.0.16`.
- The actual fork release `v5.0.16` is commit `d7c9db70cf1d54029c061490d73335146a23ed28`, not the fork's current `main`.
- Fork `main` is `0f77eb00203f93617f7c38a24ad4e1c6e1cc9d3b`; therefore using fork `main` as the migration source would omit release-only Muse web-search normalization present in deployed `v5.0.16`.
- Upstream `miuuyy/codex-chatgpt-web` current stable is `v6.1.0`, commit `293341084ac7a1ddd2de12fede3706023f5b6474`.
- The fork and upstream share merge base `e0904bc82001f06e06e7f85f564ce760c92bfd79`.
- Relative to that base, upstream has 9 commits and the deployed fork lineage has the Workstation-specific Codex-LB/Muse/release compatibility patchset.
- A dry Git merge of deployed fork `v5.0.16` with upstream `v6.1.0` auto-merges most files and reports seven direct textual conflicts: `launcher/electron/control-server.cjs`, `launcher/electron/main.cjs`, `launcher/package.json`, `package.json`, `src/codex-interrupt-hook.ts`, `src/version.ts`, and `tests/model-catalog.test.ts`.
- Upstream 6.x materially changes browser compatibility, model/effort selection, limits UI, context multipart behavior, continuation/compaction, launcher/browser recovery and hook handling.
- Fork-specific behavior to preserve includes Codex-LB routing/auth, parallel Muse routing/catalog normalization, Muse Gmail/web-search compatibility, native proxy resolution, interrupt-hook compatibility, image-managed updater behavior, release provenance/checksums, and corresponding regression tests.

## Base / dependency classification

Independent workstream.

The Workstation-side change is a maintenance/integration update against normal `main`. It does not require any unmerged Workstation workstream state.

Base:
`elmakus/chatgpt-ce-workstation@dfa41ce0867824757a50dc151afe3a87c4826457`

Integration target: `main`.

The related fork migration must use the deployed fork release `v5.0.16` as the behavioral source and upstream `v6.1.0` as the new upstream baseline.

## Initial scope

1. Create an isolated migration branch in `elmakus/codex-chatgpt-web`.
2. Reconcile upstream `v6.1.0` with the complete deployed `v5.0.16` Workstation patchset.
3. Resolve textual and semantic conflicts without dropping upstream 6.x behavior or Workstation-specific routes.
4. Run upstream tests plus focused Codex-LB, Muse, interrupt-hook, model-catalog, packaging and Linux AppImage regression checks.
5. Publish a new fork release only after verification.
6. Update/rebuild Workstation against that release and verify the runtime.
7. Do not replace the ChatGPT Desktop embedded Codex CLI independently; it remains owned by the official OpenAI ChatGPT package bundled through `codex-desktop-linux`.

## Classification

Path: `execution_prep`

Next route: `execution_prep:codex-web-upstream-sync`

Rationale: accepted Workstation authority already selects our fork as the package source and explicitly requires auditing/updating it against upstream while preserving optional native routing. The requested change is technical integration within that accepted intent rather than a new product/architecture decision.
