# M09-T05 evidence — R5 synchronized release candidate

Date: 2026-09-18
Card: `M09-T05 — Cut R5 synchronized next-version release candidate`

## Exact subject

- repository: `elmakus/codex_workflow`
- branch: `release/m09-muse-max-candidate`
- exact candidate: `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`
- exact parent: `f6603767115cf7f31ef7d8c3cb3a419a7f430aca`
- exact tree: `3f10a9a640e3501724be709aea0c043dfc2bcd56`
- selected release version: `1.1.17-private.11`

GitHub compare readback reports the candidate is exactly one commit ahead of `f660376...` with no divergence.

## Execution-time release readback

Immediately before the cut:

- `codex_workflow/main` read back at `f2b1811853a2c1da5a5af4bb735c84c3111a44d6`;
- tag/release `v1.1.17-private.10` existed at that commit;
- tag `v1.1.17-private.11` did not exist;
- GitHub Releases lookup for `v1.1.17-private.11` returned HTTP 404.

Therefore `1.1.17-private.11` was the next unique private release version at execution time.

## Exact diff

The candidate changes only these five R5-authorized paths:

- `README.md`;
- `RELEASING.md`;
- `codex_workflow/operate/VERSION`;
- `codex_workflow/operate/user_AGENTS.md`;
- `scripts/test_workflow_runtime.py`.

GitHub compare reports 11 additions and 11 deletions, all line replacements.

The `scripts/test_workflow_runtime.py` diff contains exactly the four authorized release-version line updates:

1. current version `.10 -> .11`;
2. version-order assertion `.10 > .9 -> .11 > .10`;
3. `NEXT_PACKAGE_VERSION .11 -> .12`;
4. update-fixture source version `.10 -> .11`.

No version-independent assertion, fixture behavior, runtime code, Muse orchestration code, compute-profile allocation, role contract, release workflow, or workstation source changed.

## Exact-subject verification

A local disposable preparation commit was first built from `f660376...` and produced tree `3f10a9a640e3501724be709aea0c043dfc2bcd56`. Direct HTTPS push from Tower could not authenticate and made no remote change.

The authenticated GitHub repository API then created one commit directly on `f660376...` using the exact same five blob contents. GitHub assigned exact candidate SHA `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`; its tree readback is the same `3f10a9a640e3501724be709aea0c043dfc2bcd56`.

The remote candidate was then fetched back to Tower and all required verification was rerun on checkout of exactly `4081cde7...`.

## Verification on exact candidate

On exact remote subject `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`:

- `python3 -B scripts/test_workflow_runtime.py -v`: **90/90 GREEN**;
- `python3 -B scripts/test_muse_adapter.py -v`: **17/17 GREEN**;
- `python3 -B scripts/test_muse_profile.py -v`: **7/7 GREEN**;
- Python compile check matching repository CI: **GREEN**;
- package validation: **GREEN**, version `1.1.17-private.11`, expected seven worker roles;
- package build: **GREEN**;
- archive verification: **GREEN**;
- `SHA256SUMS` verification: **GREEN**;
- `git diff --check HEAD^ HEAD`: **GREEN**;
- working tree after verification: clean.

## External-write/readback

Remote branch readback after creation:

- `release/m09-muse-max-candidate -> 4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`.

Post-write non-publication readback:

- `main` remained `f2b1811853a2c1da5a5af4bb735c84c3111a44d6`;
- tag `v1.1.17-private.11` remained absent;
- release `v1.1.17-private.11` remained absent (HTTP 404).

No `main` advancement, tag/release creation, asset publication, workstation runtime update, live two-lane validation, or Companion validation occurred in this Card.

## Result

M09-T05 implementation and deterministic verification are GREEN for exact candidate `elmakus/codex_workflow@4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`.

Card completion remains non-terminal because its independent review requirement is **REQUIRED**. The exact candidate must receive fresh independent review GREEN before live two-lane validation or publication/promotion.
