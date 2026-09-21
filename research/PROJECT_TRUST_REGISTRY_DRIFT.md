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

The affected repository exists at the expected container path and is readable by the codex runtime user. The active Codex config contains the exact ogolny path with trust_level set to trusted.

The app-server project database contains ogolny with project id `01a0bb35-f5c7-7aa1-85be-97df5def88a1` and the correct root path. Before repair, the Electron/global `local-projects` registry did not contain ogolny.

Operator correction: ogolny was already absent from the Desktop-visible local project list before testowy and test3 were deleted. Their deletion therefore is not evidence that they caused ogolny to disappear.

The installed `/home/codex/.codex/bin/newproject` helper creates the directory/Git repository, then calls app-server `project/create` directly and starts a thread with the returned app-server project id. It never invokes the Desktop ProjectsManager local-project creation path.

Inspection of the installed Desktop implementation shows the normal folder-picker path calls `ProjectsManager.createOrSelectLocalProjects`. That path creates a local project identity/cache entry and, through the app-server-backed project backend, records the legacy-local-project to app-server-project mapping. The backend's local cache write persists `LOCAL_PROJECTS`; the app-server synchronization layer persists the mapping used to associate the local project identity with the server project id.

A project created only through raw app-server `project/create` can therefore exist in the app-server database while having no corresponding Desktop local-project registration. This exactly matches ogolny's pre-repair state.

The recent interrupt-hook recovery changes do not alter this project-registration path, and ogolny's trust_level remained present.

## Diagnosis

Root cause is the newproject helper bypassing the Desktop local-project registration lifecycle. Ogolny was app-server-only rather than a fully registered Desktop local project.

Deleting testowy and test3 was incidental to the observed failure. It exposed stale mappings in global state but did not cause ogolny's missing local registration.

## Live repair result

User authorized and the live repair was applied.

A missing Desktop-local identity was registered for ogolny and mapped to the original app-server project id `01a0bb35-f5c7-7aa1-85be-97df5def88a1`. The ChatGPT/Codex Desktop application was restarted without restarting the workstation container.

Post-restart verification:
- ogolny is present in the Desktop local-project registry;
- its local identity maps to the original app-server project id;
- the app-server database still contains exactly one ogolny project/root;
- ogolny remains explicitly trusted in config;
- unrelated current projects remain present.

A pre-repair copy of the persistent Desktop state was retained locally for rollback.

The installed newproject helper remains the source defect: it calls raw app-server project creation and bypasses the Desktop local-project lifecycle. Its canonical source is the separate newproject-skill project, so this Workstation workstream does not silently mutate that other project's durable state.

## Remaining blocker

Final Android/mobile confirmation is required to prove the original trust-verification error is gone. Research remains blocked pending that end-to-end check.
