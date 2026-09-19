# M11-T04 — identity-preserving release publication

Date: 2026-09-19
Card: `implementation/workstreams/feature-muse-worker-orchestration/cards/M11-T04.md`
Result: **GREEN**

## Exact published subject

- Source/review/live-validated candidate: `elmakus/codex_workflow@d285aa1a271258052d23e3a2d3b585117fc1e862`.
- Immediately before publication, `main` remained `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`, candidate branch remained the exact reviewed SHA, and compare was a clean fast-forward: 18 ahead / 0 behind with merge-base equal to current `main`.
- `v1.1.17-private.12` tag and release were absent before the write.

## Publication write/readback

User explicitly authorized this exact M11 publication/main advance and resulting release on 2026-09-19.

`main` was advanced with a non-force ref update directly to the exact candidate SHA. Post-write readback confirmed:

- `codex_workflow:main` = `d285aa1a271258052d23e3a2d3b585117fc1e862`;
- no merge, squash, rebase or replacement commit was introduced;
- release workflow run `35449274880` completed with conclusion **success**.

## Published release provenance

Published prerelease:

- tag: `v1.1.17-private.12`;
- release id: `392101412`;
- release target: `d285aa1a271258052d23e3a2d3b585117fc1e862`;
- tag ref resolves to the same exact SHA;
- release is non-draft and prerelease.

Published assets are exactly:

- `codex_workflow-1.1.17-private.12.zip`;
- `SHA256SUMS`.

Downloaded published assets passed:

- `sha256sum -c SHA256SUMS`: **GREEN**;
- repository package verifier: **GREEN**;
- ZIP SHA-256: `07ec6bb6df38cc8b5719249d54070f0e72ea0c9ec430a6b1c8dc51ab0c8a7197`, identical to the pre-publication exact-candidate package evidence.

## Production boundary

Workstation production remained unchanged after publication:

- installed version: `1.1.17-private.11`;
- installed `runtime/muse_worker.py` SHA-256: `c199a458530d0e53ad64e40fe43c2f4072af5b9efe62af4144a03a4cb0570950`.

M11-T04 did not perform workstation production promotion.

## Result

**GREEN.** `main`, tag, release target and published package provenance all preserve the exact independently reviewed and live-validated M11 candidate identity.
