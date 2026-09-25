# M00 close evidence — Codex Web GPT v6.1.0-private.1

Date: 2026-09-25
Workstream: `change-codex-web-upstream-v6-sync`
Milestone: `M00`
Verdict: GREEN

## Exact accepted subject

`elmakus/codex-chatgpt-web@b39499c391744eaa378b157822e18b9218590b60`

The manifest-owned independent final-integration review is GREEN for this exact subject:
`implementation/workstreams/change-codex-web-upstream-v6-sync/evidence/final-integration-review-b39499c-green.md`.

## Fork-main integration readback

GitHub PR #20, `Sync downstream fork with upstream v6.1.0`, merged the exact reviewed head
`b39499c391744eaa378b157822e18b9218590b60` into `elmakus/codex-chatgpt-web:main`.

Merge commit:
`f7251910b526e84bbe85c480341e1a264f455ff5`

The merge commit tree is identical to the reviewed subject tree
`fd61ec3dab671725c29e08d09bd249808e30a7fe`; no reviewed content/behavior changed.

## Canonical release publication

Release branch:
`release/v6.1.0-private.1@b39499c391744eaa378b157822e18b9218590b60`

GitHub Actions:
- workflow: `Fork Linux Release`
- run: `36192941622`
- attempt 1: failed during the ABI phase before publication; no release was created
- attempt 2: GREEN on the identical reviewed SHA
- verify, package, Linux AppImage ABI smoke, packaged-app smoke and publish steps: GREEN

Published immutable release:
`v6.1.0-private.1`

Release readback:
- draft: false
- prerelease: false
- target/tag SHA: `b39499c391744eaa378b157822e18b9218590b60`
- AppImage: `codex-web-gpt-6.1.0-private.1-linux-x64.AppImage`
- AppImage SHA-256: `777679d63d44e84a63574f80ecdf75d98f9f6890afe4ec44af1dbea1e2b82e28`
- `checksums.txt` SHA-256: `71d250d21a8fa63c758982d5414f92f696946b481aa216c2597c2066874f261f`

This is the first canonical `v6.1.0-private.N` release and therefore matches the current workflow-main downstream-fork versioning contract.

## Workstation integration refresh

Workstation integration target `main` remains exactly
`dfa41ce0867824757a50dc151afe3a87c4826457`, the workstream's recorded base.

The Workstation workstream branch is ahead of that target with no target-side movement, so no reconciliation changed the reviewed content, behavior or M00 acceptance surface. The existing manifest final-integration GREEN remains valid.

## Production boundary

M00 did not rebuild, recreate, promote or otherwise mutate the running Workstation production image/container.

## M00 conclusion

GREEN / done. The configured Codex Web GPT fork now has an independently reviewed, merged and canonically published v6.1.0 private release. The M01 publication prerequisite is satisfied.
