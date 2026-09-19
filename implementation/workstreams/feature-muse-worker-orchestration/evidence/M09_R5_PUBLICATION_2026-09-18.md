# M09-T07 publication evidence — exact reviewed/live-validated R5 release candidate

Date: 2026-09-18

## Subject

Card: `M09-T07 — Publish exact reviewed and live-validated R5 release candidate`.

Exact publication subject:

- repository: `elmakus/codex_workflow`
- commit: `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`
- release version/tag: `1.1.17-private.11` / `v1.1.17-private.11`

The subject already had REQUIRED independent review GREEN and fresh live two-lane Muse GREEN before publication.

## Pre-write Refresh Gate

Immediately before publication:

- `main` = `f2b1811853a2c1da5a5af4bb735c84c3111a44d6`;
- `release/m09-muse-max-candidate` = exact `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`;
- compare `main...candidate`: candidate ahead by 12, behind by 0, merge base exactly current main;
- `v1.1.17-private.11` did not exist.

Therefore the candidate could be advanced to `main` as a true fast-forward with no merge/squash/rebase/cherry-pick commit.

## Publication write/readback

GitHub branch ref `main` was updated with `force=false` directly to:

`4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`

Immediate readback confirmed `main` at that exact commit.

No new source commit was created.

## Release workflow

The `main` push triggered GitHub Actions Release run:

- workflow: `Release`
- run ID: `35389560885`
- event: `push`
- head branch: `main`
- head SHA: exact `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`
- status: completed
- conclusion: success

The single release job `105744474641` completed GREEN. Its relevant steps all completed successfully:

- Require main branch;
- Checkout exact release commit;
- Read and validate version metadata;
- Refuse an existing tag or release;
- Runtime regression tests;
- Validate package;
- Build release package;
- Verify release package;
- Prepare release notes;
- Publish prerelease with verified assets;
- Verify published release.

The separate `Tests` push workflow for the same exact head also completed successfully.

## Published release readback

GitHub Releases readback for `v1.1.17-private.11` confirms:

- release ID: `391754821`;
- tag: `v1.1.17-private.11`;
- target commit: exact `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`;
- `draft=false`;
- `prerelease=true`;
- published at `2026-09-18T20:06:01Z`.

Git ref `refs/tags/v1.1.17-private.11` independently resolves directly to exact commit `4081cde7...`.

Published assets are exactly:

- `codex_workflow-1.1.17-private.11.zip`;
- `SHA256SUMS`.

The ZIP asset reports SHA-256:

`e274b3a23c49c785631f0ec6e645cfd4623c2e3388b65bac1d44f414b718e3c7`

The release body records the same exact source commit and successful runtime/package/archive/checksum verification.

## Result

**M09-T07 GREEN.**

The exact independently reviewed and live-validated release candidate is now the exact published `codex_workflow` main/tag/release subject.

Approved R5 now permits JIT preparation of production workstation promotion to this exact release under the already-recorded M09 live-operation authorization. The deferred GPT-5.6 Luna XHigh Companion proof remains a final M09/project-completion gate.
