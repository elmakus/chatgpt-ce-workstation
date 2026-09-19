# M11-T05 — exact published release production promotion

Date: 2026-09-19
Card: `implementation/workstreams/feature-muse-worker-orchestration/cards/M11-T05.md`
Result: **GREEN**

## Authorized production subject

The user explicitly authorized production promotion of the exact published release `v1.1.17-private.12`.

- repository/source subject: `elmakus/codex_workflow@d285aa1a271258052d23e3a2d3b585117fc1e862`
- release/tag: `v1.1.17-private.12`
- published ZIP SHA-256: `07ec6bb6df38cc8b5719249d54070f0e72ea0c9ec430a6b1c8dc51ab0c8a7197`
- prior production/rollback release: `v1.1.17-private.11` / `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`
- prior ZIP SHA-256: `e274b3a23c49c785631f0ec6e645cfd4623c2e3388b65bac1d44f414b718e3c7`

## Pre-update refresh and rollback readiness

Immediately before mutation:

- `codex_workflow:main`, tag `v1.1.17-private.12`, and the release target all still resolved to exact `d285aa1...`;
- the release remained a non-draft prerelease with exactly `SHA256SUMS` and `codex_workflow-1.1.17-private.12.zip`;
- production remained `1.1.17-private.11`;
- active profile remained `muse-max`;
- both published `.11` rollback and `.12` promotion assets were downloaded and passed their published `SHA256SUMS`;
- both extracted packages passed the workflow package validator;
- `plus`, `luna-xhigh`, and `pro-x5` profile definitions compared equal between `.11` and `.12` without switching the active profile.

## Owner-path promotion

The existing installed lifecycle CLI performed the update through its owner `update` path, with `--source` pointing only to the already verified extracted `.12` release asset. A disposable project path with no workflow entry point was used so the operation was user-level runtime only.

Updater result:

- operation: `update`;
- from: `1.1.17-private.11`;
- to: `1.1.17-private.12`;
- transactional backup: `/home/codex/.codex/codex_workflow/.backups/1.1.17-private.11-20260919T144902565118Z`;
- applied: true.

Rollback was not required because all post-update acceptance checks completed GREEN.

## Installed provenance and profile readback

Post-update readback:

- installed version: `1.1.17-private.12`;
- package validator: GREEN, all seven expected worker definitions present;
- owner `check-update`: installed `.12`, available `.12`, status `current`;
- active profile: `muse-max`;
- Companion: `gpt-5.6-luna` / `xhigh` / `codex`;
- Micro Executor, Default Executor, Senior Executor, Tester, Investigator and Archivist: `muse-spark-1.3-contributor` / `max` / `muse-code`;
- Main: unchanged.

The immutable release payload under `runtime/` and `operate/`, plus `archivist.md` and `delegation.md`, matched the verified extracted release exactly. Generated/personalized surfaces such as worker TOMLs, `AGENTS.md`, `heavy_route.md`, and project docs were intentionally not treated as byte-identical release-source files.

Exact installed/source hashes:

- `runtime/muse_worker.py`: `f78efe6bd93b8d44b10fa7384396422a366ecf598d471d2eee97b104b2999d11`;
- `runtime/muse_sessions.py`: `3be227efb4f3db09689ba63e9e44706b5e7c41d2bdca06fc40c39ba4ab23ec3e`.

## Production stateful Muse smoke

One production `default_executor` logical worker ran two bounded turns in the same disposable Git workspace.

Turn 1:

- logical worker: `m11-t05-prod-dcb955272f59`;
- session: `a3df4e65-b5c0-473c-96d2-5c61b4c01c46`;
- invocation: `6a6dd7b1-a83a-4107-90ef-9e60f6fb9da0`;
- resumed: false;
- exact workspace result: `TURN1\n`.

Turn 2:

- same session: `a3df4e65-b5c0-473c-96d2-5c61b4c01c46`;
- new invocation: `ebbea825-160b-4bc7-9ed4-3cf55404d89b`;
- resumed: true;
- exact workspace result: `TURN1\nTURN2\n`.

Both turns completed, session state returned to `ready`, and workspace status showed only the authorized `state.txt` change. The test logical session was then explicitly retired.

## Cleanup/readback

- corrected process-name/`/proc` readback found zero residual `muse` processes and zero smoke-driver processes;
- disposable smoke workspace/tasks/driver were removed;
- the transactional `.11` backup remained present through completion of acceptance.

A preliminary substring-based residual probe self-matched its own inspection shell and was discarded; it did not indicate a Muse residual and was not used as acceptance evidence.

## Result

**M11-T05 GREEN.**

The workstation production runtime is the exact published M11 release `v1.1.17-private.12`, active `muse-max` allocations are correct, stateful Muse session reuse is proven with stable session identity and distinct invocation identity, non-Muse profiles remain unchanged, and no residual validation process remains.
