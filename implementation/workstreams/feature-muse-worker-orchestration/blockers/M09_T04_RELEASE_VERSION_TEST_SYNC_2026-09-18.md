# M09-T04 blocker — release-version regression synchronization

Date: 2026-09-18

## Exact affected Card

`M09-T04 — Cut exact next-version release candidate`

## Evidence

The intended four-file `1.1.17-private.10` -> `1.1.17-private.11` metadata bump was applied only in a disposable local worktree based exactly on `elmakus/codex_workflow@f6603767115cf7f31ef7d8c3cb3a419a7f430aca`.

`python3 -B scripts/test_workflow_runtime.py -v` then ran 90 tests and failed with one FAIL plus one ERROR. Both failures came from release-version literals in `scripts/test_workflow_runtime.py`: the current-version assertion still required `1.1.17-private.10`, and the update fixture still searched for `1.1.17-private.10` after the package marker had become `.11`.

A disposable diagnostic changed only the four version-coupled literals in `scripts/test_workflow_runtime.py` to the natural next-release values: current `.11`, previous `.10`, next `.12`, and update-fixture source `.11`. The same runtime suite then completed **90/90 GREEN**.

GitHub readback of prior release commit `f2b1811853a2c1da5a5af4bb735c84c3111a44d6` (`Release 1.1.17-private.10`) shows that its release synchronization likewise changed `scripts/test_workflow_runtime.py` version expectations together with VERSION/user marker/README/RELEASING metadata.

## Classification

The approved Muse-max Definition and D21 remain unchanged. The issue is release preparation scope: current M09-T04 explicitly forbids test-file changes, while the repository's existing release regression contract requires version-only synchronization in `scripts/test_workflow_runtime.py` for the next version.

No candidate commit or remote release branch was produced. The disposable worktree was restored clean to exact `f6603767115cf7f31ef7d8c3cb3a419a7f430aca`; `release/m09-muse-max-candidate` does not exist on the remote.
