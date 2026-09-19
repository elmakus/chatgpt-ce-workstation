# M09-T03 — Luna XHigh Companion live acceptance

Date: 2026-09-19
Card: `M09-T03`
Status: **GREEN**

## Bound production subject

- promoted source: `elmakus/codex_workflow@4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`
- published/installed release: `v1.1.17-private.11`
- prior exact promotion evidence: `implementation/workstreams/feature-muse-worker-orchestration/evidence/M09_T08_PRODUCTION_PROMOTION_2026-09-18.md`

A fresh workstation readback on 2026-09-19 confirmed the running `chatgpt-ce-workstation` container still reports:

- version `1.1.17-private.11`;
- active profile `muse-max`;
- Companion allocation `codex / gpt-5.6-luna / xhigh`;
- all six non-Companion roles remain Muse-backed;
- Muse Code `1.3.0 (1.3.0-R3401.1)`.

## Actual Codex Main lifecycle proof

The actual Codex Main session returned the following bounded proof to the Project Workflow executor:

```text
production_version: v1.1.17-private.11
active_profile: muse-max
companion_identity_first_use: 01a0b912-6c17-7500-bfc2-a4dfe18fd53a
companion_identity_second_use: 01a0b912-6c17-7500-bfc2-a4dfe18fd53a
model: GPT-5.6 Luna
reasoning_effort: XHigh
harness: internal Codex
first_result: viettran-edgeAI/codex_workflow
second_result: muse-max
same_companion_identity: true
substitute_or_fallback_used: false
```

The two bounded assignments completed in the same Codex Main workflow session and report the same internal Companion identity.

## Acceptance evaluation

- exact promoted release identity: **GREEN**;
- actual Codex Main `muse-max` session: **GREEN**;
- GPT-5.6 Luna / XHigh allocation: **GREEN**;
- internal Codex harness, not Muse: **GREEN**;
- same Companion identity reused later in the same session: **GREEN**;
- no substitute/fallback: **GREEN**;
- no quota/runtime rejection accepted as a pass: **GREEN**.

M09-T03 therefore satisfies its stable Card contract. Independent review requirement is `none`.
