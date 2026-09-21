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

- the managed marker comments are absent
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
