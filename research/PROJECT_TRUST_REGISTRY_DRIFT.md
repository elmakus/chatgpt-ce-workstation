# Research — project trust registry drift

Research ID: project-trust-registry-drift-r1
Status: active
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

## Repair plan and verification

User authorized live repair after diagnosis.

Repair the missing local registration by preserving the existing app-server project id and creating the corresponding Desktop local project identity plus legacy-to-app-server mapping. Do not create another app-server project for the same root. Preserve unrelated projects and current user state.

Restart only the ChatGPT/Codex Desktop application as needed to reload the repaired persistent registry; do not restart the whole workstation container unless required.

Verify after restart that:
- ogolny exists in the Desktop local-project registry;
- its mapping points to the original app-server project id;
- the app-server database still has only the original ogolny project for that root;
- trust_level remains trusted;
- unrelated current projects remain intact.

Final Android/mobile confirmation remains the end-to-end validation of the original trust-verification symptom.
