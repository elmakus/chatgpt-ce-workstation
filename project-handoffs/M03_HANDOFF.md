# M03 cumulative handoff

## Final checkpoint

Muse Code source is now merged into workstation `main`.

- PR #1: merged
- Merge checkpoint: `elmakus/chatgpt-ce-workstation@17111247fd28a07de15e5a94908bd3d63858184b`
- Codex Web GPT latest release used by unpinned builds: `v5.0.10`

## Achieved state

A normal workstation build from `main` now contains the Muse Code installation candidate:
- image-owned Muse under `/opt/muse-code`;
- workstation wrapper at `/usr/local/bin/muse`;
- runtime Muse auto-update disabled by default;
- persistent `/home/codex` remains the intended auth/config boundary;
- runtime verification checks `muse --version`, `muse --help`, and `muse exec --help`;
- Codex Web GPT remains unpinned by default and resolves the latest fork release.

## Evidence

- Merge/publication: `implementation/reviews/m03-muse-main-merge-2026-09-18.md`
- Prior source readiness: `implementation/reviews/m02-muse-code-build-readiness-2026-09-18.md`

## Remaining gate

Live Muse validation is still pending. The next workstation update may now be performed from `main`.

Required live follow-up includes:
- image build and resolved Muse version;
- account/subscription login and persistence after restart/recreate;
- exact `muse exec` machine-readable output contract;
- bounded worker task;
- model/reasoning-effort controls;
- timeout/process-tree cancellation;
- sandbox behavior;
- orchestrator worker protocol and nested fan-out policy.
