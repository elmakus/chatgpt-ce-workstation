# M11-T02 exact release-candidate verification — 2026-09-19

Card: `M11-T02`

Exact subject:

`elmakus/codex_workflow@d285aa1a271258052d23e3a2d3b585117fc1e862`

Candidate branch:

`release/m11-stateful-muse-candidate`

Behavioral base:

`elmakus/codex_workflow@cf4c01f3ef7f35c32fb5ad61c301eb90e1466655`

## Exact-subject/diff verification

Git comparison `cf4c01f... -> d285aa1...` is exactly one commit ahead and zero behind.

Only five release/version-coupled files differ:

- `README.md`;
- `RELEASING.md`;
- `codex_workflow/operate/VERSION`;
- `codex_workflow/operate/user_AGENTS.md`;
- `scripts/test_workflow_runtime.py`.

The exact commit's parent is `cf4c01f...`. No runtime implementation, Muse session registry/worker code, compute-profile allocation source, worker-role TOML, lifecycle code or Project Workflow semantics changed.

Version synchronization readback is internally coherent at `1.1.17-private.12`; the runtime regression version contract compares `.12 > .11` and expects next package version `.13`.

## Fresh isolated Tower verification

A disposable checkout at `/tmp/codex-workflow-m11-rc` was cloned and detached at exact `d285aa1...`. The installed workstation production runtime was not used as the source tree and was not mutated.

Results:

- `scripts/test_muse_adapter.py -v`: **33/33 GREEN**.
- `scripts/test_workflow_runtime.py -v`: **90/90 GREEN**.
- `scripts/test_muse_profile.py -v`: **7/7 GREEN**.
- source-text compile check: **24 Python files GREEN**.
- `git diff --check`: **GREEN**.
- package validator: **GREEN**, version `1.1.17-private.12`, seven expected workers.
- release package build: **GREEN**.
- release package verification: **GREEN**.
- `SHA256SUMS`: **GREEN**.
- ZIP integrity: **GREEN**.
- output artifact count: exactly **2** (`codex_workflow-1.1.17-private.12.zip` and `SHA256SUMS`).
- ZIP SHA-256: `07ec6bb6df38cc8b5719249d54070f0e72ea0c9ec430a6b1c8dc51ab0c8a7197`.
- disposable source checkout status before and after successful packaging: **clean**.

The first packaging attempt was intentionally not accepted as evidence because prior regression execution had generated an untracked `codex_workflow/runtime/__pycache__` in the disposable checkout and the packager correctly failed closed on generated cache content. Only generated `__pycache__` / `*.py[co]` artifacts were removed; no tracked source changed. Packaging was then rerun from the same exact clean `d285aa1...` checkout and all package/archive/checksum checks passed.

## Profile/regression boundary

The exact-candidate profile suite explicitly passed:

- one internal Companion plus six Muse roles for `muse-max`;
- unchanged Codex-backed allocations for `plus`, `luna-xhigh`, and `pro-x5`;
- profile switching/materialization regression;
- Muse runner rejection of non-Muse allocations.

Because the exact candidate changes no behavioral blobs relative to independently accepted M10, the exhaustive M10 fault-injection/live evidence remains applicable under R18/D22. M11-T03 must still perform the bounded exact-candidate live stateful proof after independent review GREEN.

## Boundary

No live exact-candidate Muse validation, `codex_workflow:main` advance, tag/release publication, or workstation production mutation was performed by M11-T02.

The exact subject above is now ready for **REQUIRED independent release-candidate review**.
