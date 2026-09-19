# Project Router

project: chatgpt-ce-workstation
repository: elmakus/chatgpt-ce-workstation

## Lifecycle

This repository defines and maintains the Docker-native ChatGPT Community Edition workstation for Unraid.

The project is in active implementation and validation. Live execution state, review state, exact branches/SHAs, blockers, and checkpoints are authoritative only in `implementation/TASK_BOARD.yaml`.

## Execution policy

`chatgpt_only`

Normal ChatGPT is the fixed Task Card executor. Do not run the Capability Gate or speculative capability preflight. If a concrete required operation cannot be performed with the current chat's available tools/connectors, persist the blocker and request the smallest remedy.

## Workflow authority

- Workflow repository: `elmakus/chatgpt-codex-project-workflow`
- Workflow ref: current `main`
- Normal ChatGPT entrypoint: `CHATGPT.md`

## Project authority index

- Accepted architecture decisions: `docs/DECISIONS.md`
- Approved workstation implementation/deployment plan: `docs/IMPLEMENTATION_PLAN.md`
- Active Muse-max Project Definition: `requirements/MUSE_MAX_RUNTIME.md`
- Approved Muse-max Master Plan: `planning/MASTER_PLAN.md`
- Muse Code workstream plan when that workstream is active: `docs/MUSE_CODE_PLAN.md`
- Superseded delegated-worker plan/requirements remain historical only and are not current authority.
- Live implementation state: `implementation/TASK_BOARD.yaml`
- Latest cumulative handoff: `project-handoffs/M11_HANDOFF.md`

## Repository source-of-truth notes

- `compose.yaml` is the runtime/deployment source of truth for the workstation container.
- System/application changes must be reproducible from repository source rather than existing only in a live container.
- Current execution truth must not be mirrored here; read `implementation/TASK_BOARD.yaml`.
