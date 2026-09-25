# M00 close evidence — Codex Web GPT v6.1.0-private.2 packaging repair

Date: 2026-09-26
Workstream: `change-codex-web-v6-key-helper-packaging`
Milestone: `M00`
Verdict: GREEN

## Exact accepted subject

`elmakus/codex-chatgpt-web@78297853c0d17242a241592719e5204e5de30078`

The manifest-owned final-integration gate is GREEN by exact coverage from the independent M00-T04 review:
`implementation/workstreams/change-codex-web-v6-key-helper-packaging/evidence/M00-T04-review.md`.

Refresh/coverage evidence:
`implementation/workstreams/change-codex-web-v6-key-helper-packaging/evidence/M00-final-integration-refresh.md`.

## Fork-main integration readback

GitHub PR #21, `Fix v6 Codex-LB key helper packaging`, merged the exact reviewed head
`78297853c0d17242a241592719e5204e5de30078` into `elmakus/codex-chatgpt-web:main`.

Merge commit:
`18bee7d10fcd73debf204d438dc11bbeaa6fd187`

A compare from the reviewed subject to the merge commit reports one merge commit and zero changed files, so the merged tree/content is identical to the reviewed subject.

## Canonical release publication

Release branch:
`release/v6.1.0-private.2@78297853c0d17242a241592719e5204e5de30078`

GitHub Actions:
- workflow: `Fork Linux Release`
- run: `36202667930`
- attempt 1: GREEN
- frozen installs, full `bun run verify`, AppImage packaging, Linux ABI verification, packaged-app smoke and publication: GREEN

Published immutable release:
`v6.1.0-private.2`

Release readback:
- draft: false
- prerelease: false
- target/tag SHA: `78297853c0d17242a241592719e5204e5de30078`
- AppImage: `codex-web-gpt-6.1.0-private.2-linux-x64.AppImage`
- AppImage GitHub digest: `sha256:8addbc2949f395068f3f2fdb95ea1ae38e19557a4df6f6ac13cca0b0d03c4af1`
- `checksums.txt` GitHub digest: `sha256:ebe1ba37dcf6f5bc0901590a2136f3912cf0d4f0d2678b6ab492b2ca2cf8c87e`

The prior canonical release `v6.1.0-private.1` remains immutable. Under workflow-main fork release versioning, `private.2` is the next legal revision for the accepted upstream 6.1.0 baseline.

## Workstation integration refresh

Workstation integration target `main` remained exactly
`3f5c37dd33ef674357c7d0ace91dad637aaf79a5`, the workstream's recorded base, through the publication decision.

The Workstation branch contains only namespaced workstream intake/Card/state/evidence for this correction; no Workstation source/runtime behavior was changed.

## Production boundary

M00 did not rebuild, recreate, promote or otherwise mutate the running Workstation production image/container. The earlier failed live candidate remained pre-promotion and production stayed on the previous known-working image.

## M00 conclusion

GREEN / done. The configured fork now has the independently reviewed packaging correction merged and canonically published as `v6.1.0-private.2`, with the actual Linux release path proving the corrected AppImage package/smoke contract.


## Workstation final-target integration readback

Workstation PR #26 (`Close Codex Web GPT v6 key-helper packaging repair`) merged the closure-ready package into `main`.

- exact PR head: `30bb457e9ad140c0585f88bf5bdf19a162575e38`
- exact integration target before merge: `3f5c37dd33ef674357c7d0ace91dad637aaf79a5`
- exact merge result: `main@ec3336428e6cb157e14bfc63585b6763f4ad14d6`
- PR mergeability at final readback: GREEN
- compare surface before merge: nine files, all under `implementation/workstreams/change-codex-web-v6-key-helper-packaging/`; no Workstation runtime/source file changed
- original source branch `work/codex-web-v6-key-helper-packaging` was automatically removed by GitHub after merge

The target-side package therefore contains the completed M00 checkpoint, implementation/review/publication evidence, cumulative handoff, manifest final-integration GREEN, PR pointer and immutable final integration result without depending on the deleted source branch.
