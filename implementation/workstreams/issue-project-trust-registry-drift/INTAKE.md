# Intake — project trust registry drift

Workstream ID: `issue-project-trust-registry-drift`
Intake kind: `issue`
Status: complete

## Operator intent

Diagnose the Android/remote workspace failure reporting that trust settings cannot be verified for `/home/codex/Documents/ChatGPT/ogolny`, and determine whether it was caused by recent workstation changes or by deleting the old `testowy` and `test3` projects from the containerized ChatGPT/Codex desktop UI.

## Baseline and topology

Integration target: `main`
Exact base: `dfa41ce0867824757a50dc151afe3a87c4826457`
Classification: independent
Parent workstream: none
Parent dependency: none

No matching existing workstream/branch was found. The observed failure is live workstation state and does not require unmerged parent-only source to reproduce or diagnose.

## Diagnostic evidence

Live inspection established that `ogolny` still exists and is readable by the `codex` runtime user, its exact path remains explicitly trusted in Codex config, and app-server project state still contains the project. In contrast, the current Electron/global local-project registry has no `ogolny` entry and still retains legacy mappings for the deleted `testowy` and `test3` records.

The global-state rewrite immediately preceded the Android failure. Recent hook-recovery commits inspected do not alter project trust registration, and the live trust entry for `ogolny` remains intact.

## Intake classification

Path: `research`
Next route: `research:project-trust-registry-drift-r1`
Durable research record: `research/PROJECT_TRUST_REGISTRY_DRIFT.md`

The issue does not yet qualify as a micro-fix because the exact desktop reconciliation mechanism and durable fix ownership are not proven. The current diagnosis-only authorization also does not permit the live project-state mutation needed for the smallest discriminating repair experiment.

Research is therefore the smallest legal downstream route. The durable research record owns the remaining validation blocker.
