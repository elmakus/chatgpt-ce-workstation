# M09-T03 — actual Codex Main Companion session blocker refresh

Date: 2026-09-19
Card: `M09-T03`
Status: **blocked**

## Current production readback

A fresh live readback from the running `chatgpt-ce-workstation` container confirmed:

- installed `codex_workflow` version: `1.1.17-private.11`;
- active compute profile: `muse-max`;
- Companion allocation: internal `codex` harness, `gpt-5.6-luna`, `xhigh`;
- all six non-Companion roles remain `muse-code` / `muse-spark-1.3-contributor` / `max`;
- Muse Code remains `1.3.0 (1.3.0-R3401.1)`.

This is consistent with the exact promoted production subject already established by `implementation/evidence/M09_T08_PRODUCTION_PROMOTION_2026-09-18.md`.

## Concrete unavailable operation

M09-T03 requires one **actual Codex Main** `muse-max` workflow session to create the internal Luna XHigh Companion and later reuse that same Companion identity.

The current normal-ChatGPT execution surface exposes a Codex-native bridge, but native operations require a valid active outer-Codex `turn_token`. A direct inventory attempt from this ChatGPT session failed closed with:

`turn token is invalid, expired, or revoked`

Therefore this session is not an active outer Codex Main turn and cannot invoke or observe the internal Codex worker lifecycle needed to prove Companion creation/reuse. Running commands inside the workstation container also does not expose that internal worker lifecycle; it can verify the installed allocation but cannot satisfy the Card's live acceptance proof.

No substitute model, Muse-backed Companion, configuration readback alone, or quota/runtime rejection is accepted as GREEN.

## Smallest remedy

Start one real Codex Main session against the current workstation/project with the installed production `muse-max` profile and use its normal internal worker lifecycle to:

1. confirm production version/profile;
2. enter deployment state and create exactly one Companion;
3. record the Companion identity plus Luna/XHigh/internal-Codex allocation;
4. complete one bounded read-only Companion assignment;
5. later reuse that same existing Companion for a second bounded assignment in the same workflow session;
6. return bounded proof showing the same Companion identity was used twice and no substitute/fallback was used.

Do not ask that Codex session to own or mutate Project Workflow state. The normal ChatGPT executor will evaluate the returned runtime proof, persist M09-T03 evidence and close M09 if acceptance is satisfied.
