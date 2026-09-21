# Intake — issue-codex-interrupt-hook-drift

## Identity

- Kind: issue
- Workstream: `issue-codex-interrupt-hook-drift`
- Branch: `fix/codex-interrupt-hook-drift`
- Base: `elmakus/chatgpt-ce-workstation@dfa41ce0867824757a50dc151afe3a87c4826457`
- Integration target: `main`
- Dependency classification: independent
- Parent workstream: none
- Intake state: complete

## Operator intent

Preserve the 2026-09-21 Codex routing outage as a dedicated issue for later diagnosis. Determine why the journal-owned `codex-chatgpt-web` Interrupt lifecycle hook acquired `enabled = false`, why that latent drift caused a later full routing outage, and what bounded fix should prevent recurrence without weakening ownership/fail-closed safety.

Do not diagnose or implement the fix as part of this intake; the active Muse workstream may continue independently after this issue is durably captured.

## Reproduction / incident evidence

Observed production incident on 2026-09-21:

- Workstation Docker health remained GREEN while Codex routing was unusable.
- Codex route state remained installed+active at `http://127.0.0.1:17841/v1`.
- No local Responses listener existed on TCP/17841.
- Both ordinary native `gpt-5.6-sol` and browser-backed `chatgpt-web/*` traffic therefore failed.
- The launcher/WebUI error was: `Codex interrupt lifecycle hook changed after setup; refusing to overwrite it`.
- Retained v5.0.13 and current v5.0.14 runtimes both reported the same inconsistency, proving that an AppImage rollback alone could not repair the persistent route state.
- The earliest retained matching launcher failure was 2026-09-19 04:13 Europe/Zurich, predating the v5.0.14 workstation update.

Exact hook forensics before repair:

- the current Interrupt hook command matched the integration journal command;
- the same journal state key was present;
- the same trusted hash was present;
- command/type/timeout matched;
- the entire journal-owned managed block differed from the durable journal fragment by exactly one line: `enabled = false`.

Bounded recovery on 2026-09-21 removed only that single line after a private snapshot. Readback proved the repaired managed block matched the journal exactly and unrelated Codex configuration was unchanged. After restarting the same frozen workstation image, the launcher migrated the persistent runtime to v5.0.14, the listener on 17841 returned, `route status` had no errors, the managed hook/journal were updated to v5.0.14, and an end-to-end `gpt-5.6-sol` smoke passed.

This establishes the failure mechanism but not the actor or operation that originally persisted `enabled = false`.

## Workstream discovery / base decision

No matching hook-drift branch/workstream was found before creation.

This issue is independent from the active Muse-native-upstream workstream:

- the first retained mismatch predates the v5.0.14/Muse activation work;
- Muse was unset during the routing outage and during the successful hook repair;
- retained v5.0.13 itself already detected the same persistent hook drift.

The issue therefore bases on current `main`, not on an unmerged parent branch.

The likely implementation surface includes the related fork `elmakus/codex-chatgpt-web`; this workstation issue workstream owns diagnosis, integration/release acceptance, and any workstation-side correction that proves necessary.

## Classification

Micro-fix qualification cannot yet be established because the root actor and intended compatibility behavior remain materially unresolved. In particular, it is not yet known whether `enabled = false` came from a Codex-native hook-management operation, launcher/UI action, migration/normalization behavior, or another writer, nor whether the correct durable fix belongs in hook verification, hook representation, install/upgrade recovery, or elsewhere.

- Path: Research
- Next route: `research:codex-interrupt-hook-drift-r1`
- Canonical Research record: `implementation/workstreams/issue-codex-interrupt-hook-drift/research/R01.md`
