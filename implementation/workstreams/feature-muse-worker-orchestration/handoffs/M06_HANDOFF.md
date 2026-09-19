# M06 Handoff — Mixed-harness muse-max profile

## Completed checkpoint

- Implementation subject: `elmakus/codex_workflow@2ee25a1d84a6a3b111b68a61604276219190d2a0`
- Baseline: `elmakus/codex_workflow@f2b1811853a2c1da5a5af4bb735c84c3111a44d6`
- Branch: `impl/m06-muse-max-profile-semantics`

## Achieved state

`muse-max` is now mixed-harness: Companion is one persistent internal Codex worker on GPT-5.6 Luna XHigh; Micro, Default, Senior, Tester, Investigator and Archivist are Muse Spark 1.3 Contributor / max roles through `muse-code`.

The Muse runner resolves active profile and role allocation from shared compute-profile authority, honors shared `CODEX_HOME` semantics, takes model/reasoning from the active `WorkerModel`, and fails closed when the requested role is not assigned to `muse-code`. Companion therefore cannot be launched through the Muse adapter. Other compute-profile allocations remain unchanged. Active workflow documentation no longer describes the superseded all-seven-Muse or one-shot-Muse-Companion semantics.

## Acceptance evidence

GitHub readback confirms the implementation branch points to the exact checkpoint above with the approved M06 baseline as its parent.

Local regression on the exact committed worktree:
- focused M06 profile suite: 7/7 GREEN;
- full workflow runtime regression: 90/90 GREEN;
- `git diff --check`: GREEN;
- Python compile check: GREEN;
- semantic scan found no active stale all-seven-Muse/one-shot-Companion contract text.

No separate M06 independent review or publication is required by the approved plan.

## Deferred boundary

M06 intentionally does not implement the production Muse JSONL/result parser, normalized result contract, timeout/cancellation behavior, raw trajectory persistence, final sandbox policy, or concurrency. Those remain owned by M07–M09. M05 live evidence remains authoritative for Muse 1.3.0 process/protocol behavior, including the current nested-bubblewrap limitation in the workstation Docker runtime.

## Next durable starting point

Enter M07 Execution Prep. Materialize the exact production adapter Card(s) from the already-GREEN M05 live runtime evidence and the M06 mixed-harness checkpoint above. Deterministic adapter work may proceed normally; any required live workstation runtime smoke remains subject to the explicit live-operation authorization gate.
