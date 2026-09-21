# M01-T07 hook repair checkpoint

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T07`

## Authorization and bounded repair

User explicitly authorized repair of the existing journal-owned Codex Interrupt hook.

Pre-write safety verification proved that the current managed Interrupt block differed from the durable v10 integration journal by exactly one line:

`enabled = false`

After removing that one line in-memory, the entire managed block matched the journal fragment exactly. No unrelated Codex configuration needed to change.

A private persistent recovery snapshot was created before mutation at:

`~/.codex-chatgpt-web/recovery/m01-t07-hook-repair-20260921/`

The snapshot contains the pre-repair `config.toml` and integration journal with owner-only permissions.

The repair then atomically removed only the single `enabled = false` line from the journal-owned block.

Readback immediately after the write proved:

- managed block matches durable journal: true
- managed block contains `enabled = false`: false
- unrelated config hash unchanged: true
- official v5.0.14 `route status`: installed=true, active=true, errors=[]

## Same-image launcher restart and built-in migration

The production Workstation was recreated through repository-owned Compose on the exact already-promoted image:

`sha256:ce07c414c1442bae243689a17fb32310eed457cb38c52e89394899b9a0289b42`

The exact frozen embedded upstream resolution was rendered before recreate and Compose resolved back to the same candidate image. No rebuild occurred.

Muse remained unset. Native upstream remained:

`http://192.168.2.104:2455/backend-api/codex`

After recreate:

- local Responses proxy `127.0.0.1:17841` is listening
- launcher config migrated from releaseVersion 5.0.13 to 5.0.14
- official `route status` reports no errors
- v10 journal Interrupt command now targets the 5.0.14 managed runtime
- managed Interrupt block exactly matches the updated journal fragment
- no `enabled = false` remains in the managed block

## Model/catalog and routing readback

Proxy health is GREEN and accepted authenticated catalog requests from the native Codex client.

The native Codex model cache now contains:

- ordinary native model `gpt-5.6-sol`
- browser-backed rows `chatgpt-web/high`, `chatgpt-web/light`, `chatgpt-web/medium`
- no Muse rows while Muse endpoint remains unset

A minimal ordinary native smoke through the repaired route succeeded end-to-end:

- model: `gpt-5.6-sol`
- expected marker: `NATIVE_SOL_OK`
- result: GREEN

A `chatgpt-web/high` smoke reached the launcher/browser bridge, acquired the browser page, verified the authenticated ChatGPT session and entered effort selection. It then failed because ChatGPT returned:

`ChatGPT rate limit: too many requests. Try again in a few minutes.`

This is no longer a hook/routing failure. The browser bridge path is active and the current remaining Web smoke limitation is an external temporary ChatGPT rate limit.

An anonymous manual `GET /v1/models` returned 502 because the local proxy intentionally requires the incoming native Codex Bearer authorization for native catalog passthrough. Authenticated catalog requests from the actual Codex client succeeded and populated the model cache.

## Runtime verification

Post-repair repository verification:

- container running and Docker-health GREEN
- `scripts/wait-healthy.sh`: GREEN
- `scripts/verify-runtime.sh`: `WORKSTATION_RUNTIME_GREEN`
- tracked repository checkout clean
- no secret value emitted or committed

## Current checkpoint

The hook incident is repaired and ordinary Sol operation is restored.

Per the user's bounded "repair hook for now" instruction, Muse activation was not resumed in this checkpoint and `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` remains unset.

M01-T07 remains non-terminal because its full production acceptance still includes Muse activation and successful browser-backed route smoke. The previous hook blocker is resolved; the only observed browser-backed smoke failure after repair is the temporary ChatGPT rate limit.
