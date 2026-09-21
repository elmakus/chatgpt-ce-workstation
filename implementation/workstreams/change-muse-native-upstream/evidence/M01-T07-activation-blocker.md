# M01-T07 production activation blocker — managed Interrupt hook disabled

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T07`

## Preconditions that passed

The production Workstation was running the exact M01-T06 GREEN image:

- image ID: `sha256:ce07c414c1442bae243689a17fb32310eed457cb38c52e89394899b9a0289b42`
- embedded Codex Web GPT: `5.0.14@sha256:2c68166425e049241c61ae76eafd42afdde37343e1e887ef977fd43bf636cbf2`
- Workstation health: healthy / `WORKSTATION_RUNTIME_GREEN`
- native upstream: `http://192.168.2.104:2455/backend-api/codex`
- Muse upstream before activation: unset

The existing persistent Muse ingress-key file was verified without content disclosure:

- owner: `99:100`
- mode: `0600`
- size: 49 bytes
- readable by runtime user: yes

A secret-safe authenticated direct CLIProxyAPI `GET /v1/models` returned HTTP 200 with OpenAI-compatible `data,object` shape:

- total IDs: 17
- Muse IDs: 5
  - `muse-spark-1.1`
  - `muse-spark-1.2`
  - `muse-spark-1.2-contributor`
  - `muse-spark-1.3`
  - `muse-spark-1.3-contributor`
- non-Muse rows: 12

No credential value was emitted.

## Activation attempt

The local untracked Workstation `.env` was given only:

`CODEX_CHATGPT_WEB_MUSE_UPSTREAM=http://192.168.2.104:8317/v1`

The Workstation was recreated through the repository-owned Compose path with build inputs rendered from the running image's exact embedded frozen resolution and with the exact existing candidate image tag.

Readback after recreation:

- same image ID: yes
- container healthy
- `scripts/verify-runtime.sh`: `WORKSTATION_RUNTIME_GREEN`
- native upstream unchanged
- Muse upstream present with the authorized endpoint

## Blocking runtime condition

The exact v5.0.14 AppImage launches, but its launcher-owned local Responses proxy does not start on configured loopback port `17841`.

Persistent launcher config remains at `releaseVersion=5.0.13`. v5.0.14 correctly detects this and invokes its built-in `upgradeManagedRuntime()` transaction before proxy startup.

That transaction fails during the non-mutating `--preflight-only` step with:

`Codex interrupt lifecycle hook changed after setup; refusing to overwrite it`

The launcher then attempts its normal route fail-safe, which also refuses to overwrite the same changed managed hook. No v5.0.14 runtime-config mutation is committed.

### Ownership forensics

The persisted integration journal is version 10 and active.

The current Codex Interrupt hook is still cryptographically and structurally attributable to this codex-chatgpt-web installation:

- exactly one Interrupt hook exists at the journal-owned group index
- current hook command is exactly equal to the journal-owned command
- journal/state trusted hash is exactly equal
- journal-owned state key is present and semantically identical
- no alternate command identity was introduced

However, the current Codex configuration has materially changed the owned hook after setup:

- the managed start/end marker comments are still present exactly once
- the hook has an explicit `enabled=false`
- the journal-installed fragment did not contain that disabled state

This is not the harmless native normalization already tolerated by v5.0.14 (`enabled=true`). `enabled=false` is a semantic change, and the fork intentionally treats such a change as newer owner/user state rather than silently re-enabling it.

Therefore automatic overwrite is not authorized by the accepted execution contract.

## Safe rollback

Because T07 acceptance could not be completed, the activation was rolled back as contracted:

- removed the non-secret Muse endpoint from local `.env`
- recreated the exact same frozen candidate image
- running image remains `sha256:ce07c414c1442bae243689a17fb32310eed457cb38c52e89394899b9a0289b42`
- native upstream remains `http://192.168.2.104:2455/backend-api/codex`
- Muse upstream is unset
- container is running and healthy
- `scripts/verify-runtime.sh`: `WORKSTATION_RUNTIME_GREEN`
- target-host repository working tree is clean

The dormant Muse credential file was not changed.

## Smallest unresolved authorization

To continue T07 without weakening the fork's fail-closed ownership rule, explicit authorization is required to restore this already-journal-owned Interrupt hook from its durable v10 journal to the managed enabled state, preserving all unrelated Codex configuration.

After that authorization, execution can:

1. restore only the exact journal-owned Interrupt hook definition/state;
2. allow the built-in v5.0.14 `upgradeManagedRuntime()` transaction to run normally;
3. re-activate the Muse endpoint;
4. complete Muse-only catalog filtering, native/Muse/`chatgpt-web/*` route smokes, failure-isolation evidence and final runtime verification.

No credential change or routing-code change is requested.

**BLOCKED — explicit authorization required for the managed-hook repair.**


## Additional non-mutating forensic investigation

A follow-up read-only investigation was performed before requesting repair authorization.

### Timeline

- The active v10 journal was created on 2026-09-20 at 15:53 local time.
- An automatic backup from 2026-09-20 16:56 contains the exact journal-owned hook with no explicit `enabled` field.
- An automatic backup from 2026-09-21 06:44 contains the same exact journal-owned hook with `enabled=true`, matching command and trusted hash and retaining both managed markers.
- Workflow/Muse verification runs later on 2026-09-21 repeatedly proved the live `~/.codex/config.toml` byte-identical before/after their own work. No shell/tool call that edited this hook was found.
- The first launcher-side conflict for the current journal appears at 2026-09-21 10:27 local time, while the launcher was still v5.0.13. Therefore the `enabled=false` state predates the v5.0.14 D25 update and predates Muse activation.

### Codex Desktop diagnostics

The bundled production Codex reports:

- Codex Desktop client: `26.915.31945`
- bundled CLI: `0.155.0-alpha.9.2`

Its binary contains the hook-review/enablement surface (`Hooks need review`, `SetHookEnabled`, `Trust all and continue`, and `Continue without trusting`).

The local Codex diagnostic database was queried read-only. Between the last known enabled backup and the first launcher conflict:

- no workflow/Muse shell write to `~/.codex/config.toml` was found;
- there are no app-server config-write RPCs between 06:44 and 09:15 local;
- at 09:27:41 local Codex Desktop issued `config/batchWrite`, but its immediate RPC context is plugin synchronization (`plugin/list -> config/batchWrite -> config/read -> plugin/installed`), not a hook-management request;
- an analogous plugin-synchronization `config/batchWrite` occurs again at 10:27:13;
- no `SetHookEnabled`, hook-specific config write, or other diagnostic record proving a deliberate user toggle was found.

The logs do not record the `config/batchWrite` payload, so it is not possible to prove that the 09:27 plugin-related rewrite caused the hook's `enabled=false` normalization. It is also not possible to attribute the disable to a user action.

### Revised assessment

The evidence rules out the Muse/native-upstream work and the v5.0.14 update as the origin of the disable. The most defensible conclusion is:

- the hook remained the exact codex-chatgpt-web-owned command and trusted identity;
- its enablement changed between the last proven enabled state (06:44) and the first detected conflict (10:27);
- Codex Desktop performed at least one unrelated config rewrite in that interval;
- there is no evidence of a deliberate external replacement, malicious modification, or a workflow agent disabling the hook;
- the exact writer/action that introduced `enabled=false` cannot be proven from retained logs.

Because `enabled=false` is still a semantic state change, v5.0.14 is correct to fail closed. Explicit authorization remains required before restoring this already-owned hook to its journal-managed enabled state.

No production configuration was changed by this forensic investigation.
