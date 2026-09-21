# M01-T07 live routing outage addendum

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T07`

## User-visible impact confirmed

The Workstation container itself is running and Docker-health is GREEN, but the Codex routing plane is not functional.

Current runtime readback:

- running image: `sha256:ce07c414c1442bae243689a17fb32310eed457cb38c52e89394899b9a0289b42`
- installed AppImage: `/opt/codex-web-gpt/5.0.14/Codex Web GPT.AppImage`
- launcher process is running
- configured Responses proxy port: `127.0.0.1:17841`
- no listener exists on TCP/17841
- persistent launcher config remains `releaseVersion=5.0.13`
- Codex `openai_base_url` remains `http://127.0.0.1:17841/v1`

Therefore ordinary native/Sol traffic is still routed to a dead local endpoint. This explains the reported failure of both ordinary Sol models and `chatgpt-web/*` discovery/use.

Official `route status` from both the installed 5.0.14 runtime and retained 5.0.13 runtime returns the same state:

- installed: true
- active: true
- route URL: `http://127.0.0.1:17841/v1`
- error: `Codex interrupt lifecycle hook changed after setup; refusing to overwrite it`

This proves that rolling back only the fork AppImage/image version would not repair the persistent routing state.

## Timeline

The earliest matching launcher failure in retained logs is:

- 2026-09-19 02:13:40 UTC / 04:13:40 Europe/Zurich

Immediately before it, the launcher started its runtime daemon and attempted `bridge-connect`. The fail-safe then detected the already-inconsistent Interrupt hook and refused to restore/overwrite it.

Therefore the hook drift predates the v5.0.14 D25 update by roughly two days. Today's recreate exposed the latent inconsistency as a full routing outage because no healthy proxy remained listening on 17841.

Current `.codex/config.toml` was rewritten during the latest container startup (2026-09-21 12:22:50 Europe/Zurich), while the durable codex-chatgpt-web v10 integration journal dates from 2026-09-20 15:53. The current hook still has the same journal-owned command and trusted hash but carries an explicit `enabled=false`.

## D25 comparison

Comparing the current promoted image to the retained rollback image shows only:

- Codex Web GPT: 5.0.13 -> 5.0.14
- Ubuntu package resolution digest changed

The Codex Desktop component did not change between those images. The hook incompatibility is therefore not caused by a Codex Desktop version change introduced by M01-T06.

## Current safe state

- Muse endpoint remains unset.
- Native upstream environment remains unchanged.
- Container remains Docker-healthy.
- Repository checkout remains clean.
- No credential value was read or emitted.

However, Docker health does not imply Codex routing health: the local Responses proxy is absent and the active Codex route still targets it.

## Required recovery

A simple image rollback is insufficient. Recovery requires repairing the persistent codex-chatgpt-web managed route state. The smallest bounded repair remains restoring the journal-owned Interrupt hook to its managed enabled form, preserving unrelated Codex configuration, then allowing the built-in launcher upgrade/start transaction to verify and start the local proxy.

**BLOCKED pending explicit authorization for the managed-hook repair.**
