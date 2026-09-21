# Research — project trust registry drift

Research ID: project-trust-registry-drift-r1
Status: blocked
Origin role: other
Origin subject: issue-project-trust-registry-drift@intake
Return target: project_definition:issue-project-trust-registry-drift
Research question: Determine the cause of the remote/mobile trust-verification failure for the ogolny project, distinguish recent workstation changes from project-deletion state drift, and identify the smallest safe validation path.
Return reconciliation: pending
Return reconciliation result: none

## Verified findings

The affected repository exists at the expected container path and is readable by the codex user. Git ownership checks succeed for the user that runs the desktop application.

The active Codex config contains the exact ogolny project path with trust_level set to trusted.

The app-server project database contains ogolny with the correct root path, while the current Electron/global local-project registry contains only chatgpt-ce-workstation and does not contain ogolny.

The same global state still contains legacy project mappings for the deleted testowy and test3 records. Its modification time is approximately 2026-09-21 13:46:55 +02:00, immediately before the Android failures captured at 13:47 and 13:48.

Archived session evidence confirms ogolny was created successfully through the local newproject helper and was later used successfully as a Codex Desktop workspace.

The recent workstation commits inspected around the interrupt-hook recovery changed workflow/evidence state, while the live ogolny trust configuration remains present.

## Diagnosis

The strongest supported explanation is cross-store project-registration drift rather than a missing trust_level.

Remote/mobile can still discover ogolny through app-server state, while the desktop's local project/folder-consent registry no longer contains the corresponding project registration. Deleting testowy and test3 is strongly correlated with the global-state rewrite and is the leading trigger. The deletion did not remove ogolny's explicit trust setting.

The recent hook/workstation changes are not supported by current evidence as the direct cause.

## Remaining uncertainty and blocker

Exact causality at the desktop API/event level is not yet proven. The smallest discriminating experiment is to re-open or re-add the original ogolny folder in Codex Desktop and confirm its trust/consent setting, then verify that the local project registry is restored and Android can open it.

That operation mutates live Codex Desktop project state and is outside the current diagnosis-only authorization. No manual SQLite or global-state edit should be attempted before the supported UI reconciliation path is tested.
