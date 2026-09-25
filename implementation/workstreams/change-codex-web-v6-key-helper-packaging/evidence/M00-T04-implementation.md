# M00-T04 implementation evidence — v6 Codex-LB key-helper packaging correction

Date: 2026-09-26
Workstream: `change-codex-web-v6-key-helper-packaging`
Card: `M00-T04`

## Triggering live evidence

A user-authorized normal Workstation update was run on Tower from current Workstation `main` through `scripts/update.sh`.

Pre-promotion gates:
- source validation: GREEN;
- resolver selected `v6.1.0-private.1` with SHA-256 `777679d63d44e84a63574f80ecdf75d98f9f6890afe4ec44af1dbea1e2b82e28`;
- host preflight: GREEN;
- candidate build failed before any production mutation at the Codex Web GPT install layer with `Launcher AppImage has no Codex-LB key helper`.

Updater durable readback:
- `status: pre_promotion_failed`;
- `reason: candidate_build_failed`;
- candidate image: none;
- production container remained running and healthy on Codex Web GPT `5.0.16`.

## Root cause

The helper source `launcher/assets/set-codex-lb-key.sh` still exists in the v6.1 fork source.

Compared with `v5.0.16`, `v6.1.0-private.1` had lost that asset from both:
- `launcher/package.json -> build.files`;
- `launcher/package.json -> build.asarUnpack`.

The published AppImage therefore omitted the helper even though source-level behavior remained present. Workstation's fail-closed consumer check correctly rejected the incomplete artifact.

## Exact implementation subject

Related repository:
`elmakus/codex-chatgpt-web@78297853c0d17242a241592719e5204e5de30078`

PR:
`elmakus/codex-chatgpt-web#21`

Base:
`elmakus/codex-chatgpt-web@f7251910b526e84bbe85c480341e1a264f455ff5`

Diff:
- 5 files;
- 24 insertions;
- 4 deletions;
- `git diff --check`: GREEN.

Implemented correction:
- restores `set-codex-lb-key.sh` to launcher `build.files`;
- restores it to `build.asarUnpack`;
- advances coherent fork/launcher/runtime version metadata to `6.1.0-private.2`;
- adds static packaging-contract assertions for the required helper;
- extends Linux package smoke to extract the real generated AppImage and require both `linux-appimage-runner.sh` and `set-codex-lb-key.sh` in `resources/app.asar.unpacked/assets`.

## Exact verification

GitHub Actions CI run:
`36201143502`

On exact subject `78297853c0d17242a241592719e5204e5de30078`:
- actionlint: GREEN;
- Ubuntu verify: GREEN;
- Ubuntu app package: GREEN;
- Ubuntu Linux AppImage ABI smoke: GREEN;
- Ubuntu packaged-app smoke: GREEN, including the new actual-AppImage helper-presence assertion;
- macOS verify/package/smoke: GREEN;
- Windows PowerShell installer validation + verify/package/smoke: GREEN.

This directly covers the observed failure class: a launcher source asset can no longer silently disappear from the final Linux AppImage without failing package smoke.

## Production boundary

No corrected release has been published or deployed yet. The running Workstation remains healthy on Codex Web GPT `5.0.16`.

Next legal step is fresh independent review of the exact subject before merge/publication.
