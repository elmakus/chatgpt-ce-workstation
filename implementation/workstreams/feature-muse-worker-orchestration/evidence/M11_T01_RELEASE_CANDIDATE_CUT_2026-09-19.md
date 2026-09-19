# M11-T01 release-candidate cut evidence — 2026-09-19

Card: `M11-T01`

## Refresh Gate

- `elmakus/codex_workflow:main` read back at `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`, the verified `v1.1.17-private.11` production baseline.
- M10 implementation branch `impl/m10-stateful-muse-lifecycle` read back at exact accepted subject `cf4c01f3ef7f35c32fb5ad61c301eb90e1466655`.
- Git comparison remains `4081cde...` -> `cf4c01f...`: 17 commits ahead, 0 behind, merge base `4081cde...`.
- Fresh release readback showed `v1.1.17-private.11` as the highest published private release.
- Exact tag `v1.1.17-private.11` resolves to `4081cde...`.
- Exact tag `v1.1.17-private.12` returned 404 / absent before and after candidate cut.
- Existing release branches did not contain an M11 candidate branch.

Result: direct release-only preparation remains legal under R18/D22 and the next unique private version is `1.1.17-private.12`.

## Exact release candidate

Dedicated branch:

`release/m11-stateful-muse-candidate`

Exact candidate:

`elmakus/codex_workflow@d285aa1a271258052d23e3a2d3b585117fc1e862`

Raw Git commit readback proves:
- commit message: `Release 1.1.17-private.12`;
- parent: exact accepted M10 `cf4c01f3ef7f35c32fb5ad61c301eb90e1466655`;
- tree: `c05ad8919ea745939298a3ca30a31d6d7572d687`;
- candidate branch ref resolves to the same exact commit.

The branch was initially created at `cf4c01f...` and then advanced non-force to the single atomic release commit above.

## Candidate delta

Exact compare `cf4c01f... -> d285aa1...` is one commit ahead, zero behind and changes only:

- `README.md`: 1 addition / 1 deletion;
- `RELEASING.md`: 4 additions / 4 deletions;
- `codex_workflow/operate/VERSION`: 1 addition / 1 deletion;
- `codex_workflow/operate/user_AGENTS.md`: 1 addition / 1 deletion;
- `scripts/test_workflow_runtime.py`: 4 additions / 4 deletions.

Readback confirms synchronized release literals:

- README version: `1.1.17-private.12`;
- RELEASING current version/archive/tag: `1.1.17-private.12`;
- VERSION: `1.1.17-private.12`;
- user AGENTS marker: `1.1.17-private.12`;
- runtime regression literals: current `.12`, predecessor `.11`, next package `.13`, update fixture source `.12`.

No runtime module, profile allocation, role contract, Muse session lifecycle code or Project Workflow semantics changed.

## Checks

- Exact candidate diff shape: GREEN.
- Release metadata synchronization by readback: GREEN.
- Added-line trailing-whitespace scan on exact commit diff: GREEN (0 findings).
- Candidate tag/release publication: intentionally not performed.
- Workstation production mutation: intentionally not performed.

M11-T02 owns complete exact-candidate regression/package verification and the REQUIRED independent review boundary.
