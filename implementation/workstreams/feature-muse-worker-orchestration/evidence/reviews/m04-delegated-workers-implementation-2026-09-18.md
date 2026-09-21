# M04 delegated-worker workflow implementation evidence

Date: 2026-09-18
Status: implementation complete; **REQUIRED independent review pending**

## Exact subject

- Workflow repository: `elmakus/chatgpt-codex-project-workflow`
- Base: `main@23b8c368aea160566abdfd3fbc42bd0facb88bd4`
- Implementation branch: `feat/delegated-workers`
- Review subject: `a5bca27b10f68703e9c7646a95735c04731778cf`
- Draft PR: #23

The PR/head readback confirms the exact subject is open, unmerged, draft, and mergeable. It must not be merged before independent review is GREEN.

## Implemented contract

The subject adds generic delegated-worker semantics under `chatgpt_only` while preserving normal ChatGPT as the fixed Task Card executor.

The implementation provides:
- an opt-in delegated-worker contract;
- stable Card-level worker role/profile/input/workspace/result/failure requirements;
- await-based worker completion with no normal busy-loop polling;
- raw transcript/log isolation from the main ChatGPT context by default;
- normalized parent-facing worker results;
- tester/verifier grounding in accepted authority + resulting state rather than executor transcript;
- leaf-worker semantics;
- normal blocker/corrective handling on worker/protocol failure;
- Task Board remaining the sole mutable execution-state authority;
- an explicit statement that delegated tester/verifier evidence does not replace REQUIRED/RECOMMENDED fresh ChatGPT Independent Review.

Backend-specific Muse CLI/runtime details are intentionally absent from generic workflow authority.

## Scope readback

Compare `main...feat/delegated-workers` reports the branch ahead with exactly these 10 changed files:
- `README.md`
- `docs/audits/CHATGPT_ONLY_DELEGATED_WORKERS.md`
- `docs/audits/CHATGPT_ONLY_LOSSLESS_SEMANTIC_MATRIX.md`
- `workflow/chatgpt_only/DELEGATED_WORKERS.md`
- `workflow/chatgpt_only/EXECUTION.md`
- `workflow/chatgpt_only/EXECUTION_PREP.md`
- `workflow/chatgpt_only/ROUTER.md`
- `workflow/chatgpt_only/STATE.md`
- `workflow/chatgpt_only/TASK_CARDS.md`
- `workflow/chatgpt_only/TASK_CARD_TEMPLATE.md`

No non-`chatgpt_only` policy namespace or project runtime source is changed.

## Implementer checks

Targeted readback/semantic checks are GREEN for:
- fixed ChatGPT Task Card executor ownership;
- Task Board as sole mutable execution-state authority;
- worker await/no-poll semantics;
- transcript isolation;
- executor/tester separation;
- delegated tester distinct from workflow Independent Review;
- leaf-worker default;
- conditional/lean delegated-worker contract loading.

A targeted forbidden-term scan over normative generic workflow files found no Muse-specific CLI/path/model terms such as `muse`, `muse-worker`, `/opt/muse` or `--json`.

The workflow branch also contains `docs/audits/CHATGPT_ONLY_DELEGATED_WORKERS.md` as implementation self-audit and additive ownership rows in the lossless semantic matrix.

## Review boundary

This file is implementer evidence only and is **not** an independent verdict.

The fresh reviewer must inspect the exact immutable subject above against:
- `implementation/workstreams/feature-muse-worker-orchestration/cards/M04-T01.md`;
- `requirements/MUSE_DELEGATED_WORKERS.md`;
- `docs/DECISIONS.md` D20;
- `planning/MUSE_DELEGATED_WORKERS_MASTER_PLAN.md` M04;
- the actual workflow diff/source.

The reviewer should especially verify that executor ownership, review independence, state ownership, no-poll semantics, backward compatibility and worker-failure completion behavior were not weakened.
