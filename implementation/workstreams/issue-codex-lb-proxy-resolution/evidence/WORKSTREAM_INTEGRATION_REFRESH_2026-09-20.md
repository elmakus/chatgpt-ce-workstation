# Workstream integration refresh — Codex-LB proxy resolution

Date: 2026-09-20

## Scope

Workstream: `issue-codex-lb-proxy-resolution`

Qualified micro-fix Card: `MF-T01`

Reviewed behavioral subject:

`elmakus/codex-chatgpt-web@0b2336dd01520c7a33699a6d90a290b108bebd42`

## Current-target refresh

### Workstation integration target

- target: `elmakus/chatgpt-ce-workstation@main`
- current target SHA: `04440574afb2d85790301c915e9d7f8c90721021`
- workstream base SHA: `04440574afb2d85790301c915e9d7f8c90721021`
- result: target has not moved since workstream creation.

The workstream branch differs from workstation `main` only by its namespaced Intake/Card/Task Board/review/evidence package. It contains no workstation runtime/code/config behavioral change.

### Related fork integration target

- target: `elmakus/codex-chatgpt-web@main`
- current target SHA: `7fedbca16373ab0a7c3a12123eb9b98811fd2b86`
- PR #8 base SHA: `7fedbca16373ab0a7c3a12123eb9b98811fd2b86`
- result: target has not moved since the reviewed implementation branch was based.

The reviewed fork subject remains exactly four commits ahead of current fork `main`, changing only the four files recorded in the MF-T01 implementation evidence.

## Final-integration review coverage

The independent GREEN Card review covers the complete behavioral workstream acceptance surface:

1. MF-T01 is the only implementation Card and contains the entire behavioral change.
2. The refreshed behavioral/final subject remains exactly `elmakus/codex-chatgpt-web@0b2336dd01520c7a33699a6d90a290b108bebd42`.
3. No code/config/behavior change occurred after that subject.
4. The Card review used the complete Intake + MF-T01 authority and acceptance surface.
5. Both integration targets remain at the exact baselines used for implementation/review, so no compatibility reconciliation is required.

Therefore the distinct workstream final-integration gate may reuse the independent MF-T01 GREEN verdict under the one-Card micro-fix coverage rule.

## Publication boundary

Fork merge/release metadata changes are closure/publication work only. They must not change the reviewed proxy/auth/routing behavior. A new release must use a new synchronized package/launcher/runtime version because the existing `v5.0.12` tag/release already points to the pre-fix release subject.

Production workstation rebuild/recreate or live configuration mutation remains excluded.
