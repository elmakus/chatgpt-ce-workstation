# MF-T01 — Fix Codex-LB launcher proxy resolution

- Milestone: `micro-fix`

> This file is a stable Task Card contract. Mutable execution/review/result state lives only in the selected canonical Task Board.

## Authority slice

- Master Plan / milestone contract: none — qualified micro-fix under R6 + `implementation/workstreams/issue-codex-lb-proxy-resolution/INTAKE.md`
- Requirements: exact completed Intake operator intent, diagnosis and acceptance
- Accepted decisions: `docs/DECISIONS.md#D10`, `docs/DECISIONS.md#D11`, `docs/DECISIONS.md#D15`
- Relevant OpenSpec: none
- Accepted dependency results: none

### Must preserve

- `elmakus/codex-chatgpt-web` remains the workstation's Codex Web GPT package source.
- Native Codex requests may be routed to the configured Codex-LB upstream while `chatgpt-web/*` routing remains unchanged.
- A custom native upstream keeps its dedicated authentication boundary; the incoming ChatGPT OAuth bearer must not be forwarded to Codex-LB.
- Launcher system-proxy/PAC resolution must apply to the actual outbound native target, including a configured custom upstream.
- The launcher proxy-resolution control endpoint must remain fail-closed and must not become a general arbitrary-URL proxy oracle.
- No change may weaken the existing explicit-environment proxy behavior or unsupported-proxy-protocol rejection.
- Useful source changes must be durable in the related fork/project repositories; do not rely on a live-container patch.

### Must not / rationale that must travel

- Do not “fix” this by resolving PAC only for `https://chatgpt.com` after a custom upstream has been selected; that can apply the wrong PAC/NO_PROXY decision to the real target.
- Do not broadly remove the launcher URL allowlist.
- Do not route ChatGPT Web models through Codex-LB.
- Do not perform a production workstation rebuild/recreate or live configuration mutation without a separate explicit deployment authorization.

## Dependencies

- none

## Outcome

A configured Codex-LB native upstream no longer fails through the launcher with `Launcher native proxy resolution failed (HTTP 400)`, while the launcher continues to resolve proxies only for the official Codex endpoint and explicitly configured native upstream bases.

## Scope

### Included

- Correct the related fork `elmakus/codex-chatgpt-web` launcher/native-network proxy-resolution authorization path.
- Keep proxy resolution target-aware for `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM` and the existing optional Muse native upstream when applicable.
- Add focused regression coverage proving the exact Codex-LB failure is removed and arbitrary unrelated URLs remain rejected.
- Run the fork's relevant unit/verification/CI checks.
- Prepare the corrected fork change for independent review and subsequent normal release consumption by the workstation.

### Excluded

- Changing Codex-LB routing architecture, authentication model, model catalog semantics or ChatGPT Web routing.
- General proxy subsystem redesign.
- CLIProxyAPI/Muse behavior changes except preserving the same explicit-upstream proxy-resolution safety contract.
- Production workstation rebuild/recreate or live secret/config mutation.

## Acceptance

1. With a configured native upstream such as `http://127.0.0.1:2455/backend-api/codex`, native Responses proxy resolution is accepted for that exact configured base instead of returning launcher HTTP 400.
2. Proxy resolution is performed for the actual rewritten outbound URL so PAC/NO_PROXY policy can differ correctly between `chatgpt.com` and a local/custom upstream.
3. Official `https://chatgpt.com/backend-api/codex/*` proxy resolution remains accepted.
4. URLs outside the official Codex base and explicitly configured native/Muse upstream bases remain rejected by the launcher control server.
5. Native upstream authentication replacement and existing ChatGPT Web routing behavior are unchanged.
6. Focused regression tests and the fork's relevant verification/CI are GREEN on the exact review subject.
7. No live production workstation mutation is performed by this Card.

## Required tests / checks

- Focused launcher control-server tests for official Codex, configured custom upstream, and unrelated-URL rejection.
- Focused native-network regression with launcher descriptor + configured native upstream demonstrating no HTTP 400 path.
- Existing native-network tests covering auth replacement, system proxy semantics and unsupported proxy protocols.
- Fork verification/test suite relevant to changed files.
- GitHub CI on the exact fork implementation subject.

## Optional execution hints

- Priority: HIGH
- Complexity: MEDIUM
- Phase: transport regression correction
- Expected/relevant code locations:
  - `elmakus/codex-chatgpt-web:src/native-network.ts`
  - `elmakus/codex-chatgpt-web:launcher/electron/control-server.cjs`
  - `elmakus/codex-chatgpt-web:launcher/electron/main.cjs`
  - `elmakus/codex-chatgpt-web:launcher/tests/control-server.test.cjs`
  - `elmakus/codex-chatgpt-web:tests/native-network.test.ts`

## External write/readback needs

- Related fork: create a bounded fix branch/PR in `elmakus/codex-chatgpt-web`; verify exact pushed head and CI.
- Corrected fork release publication is allowed only after independent GREEN review of the exact implementation subject; verify release/tag/checksum artifact before workstation consumption.
- Project workstream remains on `fix/codex-lb-proxy-resolution`.
- Production workstation deployment is excluded pending separate explicit authorization.

## Independent review

`RECOMMENDED` — behavioral network/security-boundary code changed in the related fork, and the exact immutable subject must be independently checked before merge/release.
