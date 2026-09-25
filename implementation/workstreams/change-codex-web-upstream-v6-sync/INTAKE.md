# Intake — Codex Web GPT upstream v6 sync

Date: 2026-09-25
Workstream ID: `change-codex-web-upstream-v6-sync`
Kind: `change`
Status: complete

## Operator intent

Update the Workstation-managed fork `elmakus/codex-chatgpt-web` from the currently published fork release v5.0.16 to current trusted upstream v6.1.0 while preserving the fork-specific Codex-LB, Muse/CLIProxyAPI, routing, compatibility, packaging and provenance behavior.

## Discovery and base classification

- Workstation integration target: `main`.
- Independent workstream; no unmerged Workstation parent-only state is required.
- Workstation base: `elmakus/chatgpt-ce-workstation@dfa41ce0867824757a50dc151afe3a87c4826457`.
- Related fork release actually consumed by Workstation: `elmakus/codex-chatgpt-web@d7c9db70cf1d54029c061490d73335146a23ed28` (v5.0.16).
- Upstream target: `miuuyy/codex-chatgpt-web@293341084ac7a1ddd2de12fede3706023f5b6474` (v6.1.0).
- The fork and upstream diverged from `e0904bc82001f06e06e7f85f564ce760c92bfd79`.
- Dry merge identified seven direct textual conflicts; most changes merge automatically.
- Existing Smart Upstream Updates R4 requires Codex Web GPT to follow the configured fork's current trusted stable release.

## Classification

Path: `execution_prep`
Next route: `execution_prep:codex-web-upstream-v6-sync`

The accepted Smart Upstream Updates authority already defines latest-stable behavior and related-repository update semantics; no new product/system decision is required.
