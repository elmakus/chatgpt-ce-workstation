# Workstream final-integration review evidence

Workstream: `change-workstation-docker-retention`
Integration target: `main`
Review requirement: **RECOMMENDED**

## Pre-freeze integration refresh

Current integration-target commit:
`bcd74082aec6e1888d244c6aa647ad76e1d35605`.

The target is unchanged from the refresh baseline used immediately before the accepted M04 live retry:
- prior baseline -> current `main`: identical;
- current `main` -> workstream branch: `behind_by=0`;
- no target-side reconciliation, merge or rebase is required;
- no workstream-owned behavior or acceptance surface changed because of target movement.

The final accepted implementation checkpoint remains:
`9c2523a0bd0ae18c43a3a559a05e57e8275aaa77`.

M04 is terminal GREEN in the selected Task Board. Its cumulative handoff and live evidence are included in the closure-ready workstream package.

## Existing independent review coverage

Existing independent reviews remain valid for their own gates:
- M04-T01 reviewed the combined destructive-retention implementation before live activation;
- M04-T03 independently reviewed the corrected D26-compatible host-preflight subject.

Those reviews are not reused as the distinct manifest-owned final-integration review because the closure-ready branch subject also contains later live acceptance evidence and M04 finalization metadata. It is therefore not the identical immutable subject/whole acceptance surface covered by either Card review.

## Final-integration review scope

The fresh reviewer should verify the exact manifest `review.subject` against current workflow authority and current `main`, including:
- requirements R11, R12 and R16-R24;
- decisions D25, D26 and D28;
- M01-M04 cumulative acceptance and review history;
- exact implementation checkpoint `9c2523a0bd0ae18c43a3a559a05e57e8275aaa77`;
- M04 live Tower evidence and persistent/unrelated-workload readbacks;
- closure-ready Task Board + M04 handoff consistency;
- absence of unreviewed behavioral drift after the accepted implementation checkpoint;
- final integration compatibility with `main` at `bcd74082aec6e1888d244c6aa647ad76e1d35605`.

If GREEN and the target/content/acceptance surface remain unchanged, Close may proceed to publication/integration. If the target moves before merge, rerun the integration refresh contract before integrating.
