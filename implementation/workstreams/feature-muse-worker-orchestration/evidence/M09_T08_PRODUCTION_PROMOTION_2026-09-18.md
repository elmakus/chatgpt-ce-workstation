# M09-T08 production workstation promotion — exact published Muse-max release

Date: 2026-09-18

## Subject

Card: `M09-T08 — Promote published Muse-max release to workstation production runtime`.

Exact production release:

- repository: `elmakus/codex_workflow`
- commit: `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`
- tag/version: `v1.1.17-private.11` / `1.1.17-private.11`
- published ZIP SHA-256: `e274b3a23c49c785631f0ec6e645cfd4623c2e3388b65bac1d44f414b718e3c7`
- M09 live workstation operations were explicitly authorized by the user on 2026-09-18.

This Card performed production promotion only. It did not attempt or claim the deferred Luna XHigh Companion acceptance proof.

## Refresh Gate

Immediately before mutation:

- workstation project checkout was on `feat/muse-worker-orchestration`, clean, and fast-forwarded to the durable M09-T08 execution state;
- container `chatgpt-ce-workstation` was running and healthy;
- production `/home/codex/.codex/codex_workflow` was absent;
- Muse Code was `1.3.0 (1.3.0-R3401.1)`;
- persistent Muse auth existed with mode `0600`; credential contents were not read;
- GitHub readback reconfirmed release/tag/main at exact `4081cde7...`, with the ZIP digest above and exactly the expected release assets.

## Exact release acquisition and validation

The workstation downloaded only:

- `codex_workflow-1.1.17-private.11.zip`;
- `SHA256SUMS`.

`sha256sum -c SHA256SUMS` returned GREEN. Direct final readback of the ZIP digest matched the accepted SHA-256 exactly.

The archive extracted to exactly one top-level `codex_workflow/` directory. The release runtime validator returned:

- `valid=true`;
- version `1.1.17-private.11`;
- all seven expected worker definitions.

No repository clone or unreviewed source checkout was used as the production install source.

## Production bootstrap and profile promotion

Because no shared production runtime existed, the supported first-install bootstrap path was used against a disposable project under the canonical project root. This avoided changing the tracked workstation repository merely to provide a bootstrap target.

Bootstrap applied successfully and installed shared workflow state into persistent `/home/codex/.codex`. Immediate readback showed version `1.1.17-private.11`.

Bootstrap returned the required Project Documentation Framework Archivist action. The production profile was then switched transactionally from the bootstrap default `plus` to `muse-max`, with readback:

- Companion -> `gpt-5.6-luna` / `xhigh` / internal `codex`;
- Micro Executor, Default Executor, Senior Executor, Tester, Investigator and Archivist -> `muse-spark-1.3-contributor` / `max` / `muse-code`;
- Main -> unchanged.

The required bootstrap documentation action was executed by a separate Muse-backed Archivist, not silently by Main.

Archivist run:

- run ID: `b7577c0a-78fb-43dd-82b4-9677b946639c`;
- terminal status: completed;
- process exit: 0;
- blocking findings: none;
- all six required framework files were populated;
- independent readback confirmed all six files existed and no `codex-workflow-bootstrap-template` marker remained.

## Production Executor -> fresh Tester smoke

Disposable production smoke workspace: `.m09-t08-prod-smoke`.

Default Executor run:

- run ID: `be857061-1d68-48d9-8154-44915c67da8f`;
- terminal status: completed;
- process exit: 0;
- only `result.txt` changed;
- exact content: `PRODUCTION_MUSE_OK\n` (19 bytes).

Main independently read back the exact bytes and Git state before launching Tester.

Fresh Tester run:

- run ID: `b6cdc396-00a4-41aa-84cf-484e27359dd7`;
- terminal status: completed;
- process exit: 0;
- verdict: `GREEN`;
- blocking findings: none.

The Tester capsule supplied only the verification contract and workspace state and explicitly forbade reading executor transcript/result or private Muse run artifacts.

## Managed two-lane production smoke

Two isolated disposable Git workspaces were assigned by Main:

- lane A: `.m09-t08-parallel/lane-a`;
- lane B: `.m09-t08-parallel/lane-b`.

The exact production runtime's `MuseWorkerInvocation` plus `execute_workers_concurrently(..., max_workers=2)` launched one Default Executor per lane.

A live process readback during the managed batch observed both Muse processes simultaneously:

- lane A: PID 5424, PGID 5424, run/session ID `d211b65f-c21b-4fbc-81fe-fbde3f4dc52f`;
- lane B: PID 5427, PGID 5427, run/session ID `e9064cec-e55e-4bb2-a8a1-a27e04c6d1dc`.

Each process referenced only its assigned workspace and private prompt/schema paths.

Managed batch elapsed time: approximately 67.233 seconds.

Normalized results:

- lane A: completed, exit 0, only `lane-result.txt`, exact bytes `lane-a-green\n`;
- lane B: completed, exit 0, only `lane-result.txt`, exact bytes `lane-b-green\n`;
- both reported no blocking findings or decision requirement.

Main independently re-read both exact files and Git status after completion.

## Artifact isolation, preservation and cleanup

For all five production Muse runs in this Card:

- run directory mode: `0700`;
- `events.jsonl`, `stderr.log`, `result.json`: `0600`;
- parsed JSONL contained exactly one `run.terminal.completed`;
- parsed JSONL contained zero `run.terminal.failed`;
- normalized `result.json` contained no raw terminal lifecycle record.

Pre/post hashes for existing Codex auth, hooks and Muse auth files matched exactly. Credential contents were not read or copied into project evidence.

Final process readback found no M09-T08 Muse/driver process subtree.

The disposable bootstrap, sequential smoke and two-lane workspaces were removed and absence was read back. Private bounded Muse run artifacts remain under the production `~/.codex/codex_workflow/muse_runs/` retention policy.

The workstation image/container was not rebuilt or recreated; this promotion correctly changed only persistent user-level workflow runtime state.

## Final production readback

Final live readback:

- installed version: `1.1.17-private.11`;
- installed package validation: GREEN;
- active profile: `muse-max`;
- role mapping: exact accepted mixed-harness allocation;
- Muse Code: `1.3.0 (1.3.0-R3401.1)`;
- workstation healthcheck: GREEN;
- owner-release `check-update`: installed `1.1.17-private.11`, available `1.1.17-private.11`, status `current`.

## Result

**M09-T08 GREEN.**

The exact published and independently reviewed release `4081cde7...` is now promoted into the workstation's persistent production workflow runtime and the production Muse path is live-validated.

The deferred `M09-T03` GPT-5.6 Luna XHigh Companion creation/reuse proof remains mandatory for final M09/project completion. No Companion invocation or substitute model was counted in this Card.
