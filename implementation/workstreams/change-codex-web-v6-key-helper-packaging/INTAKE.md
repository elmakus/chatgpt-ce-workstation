# Intake — change-codex-web-v6-key-helper-packaging

## Identity

- Kind: change
- Workstream: `change-codex-web-v6-key-helper-packaging`
- Branch: `work/codex-web-v6-key-helper-packaging`
- Base: `elmakus/chatgpt-ce-workstation@3f5c37dd33ef674357c7d0ace91dad637aaf79a5`
- Integration target: `main`
- Dependency classification: independent
- Parent workstream: none
- Intake state: active

## Authorized bounded scope

Complete the explicitly authorized live Workstation update to the latest accepted Codex Web GPT fork release. The live update is blocked before production mutation because the published `v6.1.0-private.1` AppImage omits the Codex-LB key helper that Workstation requires.

## Baseline diagnosis

Live Tower update on 2026-09-25 used current Workstation `main` and the normal `scripts/update.sh` path.

- source validation: GREEN;
- frozen resolver selected `v6.1.0-private.1` with the published AppImage SHA-256;
- host preflight: GREEN;
- candidate build failed before production mutation in `scripts/build/install-codex-web-gpt.sh` with `Launcher AppImage has no Codex-LB key helper`;
- production remained on Codex Web GPT `5.0.16`.

Exact source comparison proves the regression class:

- `launcher/assets/set-codex-lb-key.sh` still exists in fork source at `v6.1.0-private.1`;
- `v5.0.16` included that asset in both launcher `build.files` and `build.asarUnpack`;
- `v6.1.0-private.1` dropped it from both packaging lists during the upstream-v6 synchronization;
- Workstation correctly fails closed rather than installing an artifact missing the required helper.

## Base / dependency decision

The defect is independently reproducible from current Workstation `main` and current fork `main`; it does not depend on another unmerged Workstation workstream. The implementation lives in related repository `elmakus/codex-chatgpt-web`; this Workstation workstream owns the integration/release/deployment acceptance evidence.

## Downstream classification

Pending final post-creation classification.
