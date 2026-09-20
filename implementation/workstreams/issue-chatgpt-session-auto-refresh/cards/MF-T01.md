# MF-T01 — Auto-verify due ChatGPT Web sessions

- Milestone: `micro-fix`

> This file is a stable Task Card contract. Mutable execution/review/result state lives only in the selected manifest-bound workstream Task Board.

## Authority slice

- Master Plan / milestone contract: `none — qualified micro-fix under R6 + implementation/workstreams/issue-chatgpt-session-auto-refresh/INTAKE.md`
- Requirements: `none — bounded issue intent is owned by the completed Intake record`
- Accepted decisions: `docs/DECISIONS.md#D10`, `docs/DECISIONS.md#D11`, `docs/DECISIONS.md#D14`
- Relevant OpenSpec: `none`
- Accepted dependency results: `none`
- Related implementation source baseline: `elmakus/codex-chatgpt-web@9de6a670f1934f5f4843a9df0d4b0d408884798f`

### Must preserve

- Codex Web GPT remains sourced from the maintained fork under D11; workstation packaging/runtime architecture does not change.
- Existing embedded-browser authentication/session isolation remains intact.
- Existing password/passkey/MFA flows remain user-driven; no credential entry, secret extraction, or identity-provider automation may be added.
- A due 48-hour reminder is only a scheduling signal. It must not be treated as proof that the ChatGPT session is invalid.
- Reminder freshness may advance automatically only after the existing saved-session verification path has positively returned an authenticated ChatGPT Temporary Chat surface/session.
- An unauthenticated result or verification/network error must not be recorded as a successful refresh.
- Explicit login, passkey-login, logout, dismissal and normal browser-turn behavior must remain compatible.
- No browser profile/auth material or other secrets may be written to Git or project evidence.

### Must not / rationale that must travel

Do not replace the existing bounded `/api/auth/session` verification with password/passkey/MFA automation. The goal is to eliminate needless periodic manual re-login while preserving ChatGPT's own reauthentication boundary when the saved session is no longer valid.

## Dependencies

- none

## Outcome

A valid saved ChatGPT session is revalidated automatically when the existing 48-hour reminder becomes due. Successful validation silently moves the next reminder forward; a genuinely invalid or unverifiable session remains on the existing recovery/sign-in path.

## Scope

### Included

- `elmakus/codex-chatgpt-web` launcher changes needed to invoke the existing `BrowserHost.refreshAuthentication()` path automatically when the reminder becomes due.
- State wiring that advances `sessionRefreshReminderAt` only after a verified authenticated result.
- Deduplication so one due reminder does not cause an uncontrolled refresh loop.
- Focused launcher tests for successful, unauthenticated and failed verification behavior plus API/wiring regressions.
- Exact fork commit/PR and test evidence recorded back in this workstation workstream.

### Excluded

- Automating ChatGPT/OpenAI passwords, passkeys, MFA, OAuth consent or other credential ceremonies.
- Changing the 48-hour interval as the primary fix.
- Changing ChatGPT cookies/token formats, bypassing server expiry, or inventing a local session lifetime.
- Workstation deployment/rebuild to Unraid in this Card.
- Unrelated launcher/session refactors.

## Acceptance

1. When `sessionRefreshReminderAt` is due and the embedded browser is currently authenticated, the launcher automatically invokes the existing saved-session refresh/verification path without requiring the reminder's Log out/Dismiss buttons.
2. When that verification returns authenticated, the launcher durably advances `sessionRefreshReminderAt` by the existing interval and the reminder does not surface for that due occurrence.
3. When verification returns unauthenticated, the reminder timestamp is not advanced as a successful refresh and existing sign-in/recovery behavior remains available.
4. When verification throws or reports a transient verification error, freshness is not falsely advanced and no retry loop is created.
5. A not-yet-due reminder performs no automatic refresh.
6. No new credential automation or secret persistence is introduced.
7. Existing explicit login/passkey-login/logout/dismiss behavior and launcher verification remain green.

## Required tests / checks

- Add focused unit/integration coverage for due + authenticated success advancing the reminder.
- Add focused coverage for due + unauthenticated result not advancing the reminder.
- Add focused coverage for refresh failure/error not advancing the reminder or looping.
- Add coverage that not-due state does not refresh.
- Update IPC/preload/renderer wiring tests if a new launcher API is introduced.
- Run the fork's normal verification command (`bun run verify`) on the exact implementation subject.
- Record exact fork commit/PR and CI/local verification evidence in the workstation workstream.

## Optional execution hints

- Priority: `MEDIUM`
- Complexity: `MEDIUM`
- Phase: `launcher authentication lifecycle`
- Expected/relevant code locations:
  - `launcher/electron/main.cjs`
  - `launcher/electron/browser-host.cjs`
  - `launcher/electron/preload.cjs`
  - `launcher/src/App.tsx`
  - `launcher/src/types.ts`
  - `launcher/tests/*`

## External write/readback needs

Create an implementation branch in `elmakus/codex-chatgpt-web`, persist the exact implementation commit and open/read back the related fork PR before freezing review subject. Workstation durable workflow/evidence remains on `fix/chatgpt-session-auto-refresh`.

## Independent review

`REQUIRED` — the bounded change touches authentication/session behavior. The implementing chat may not issue its own verdict.

## Contract overrides

None.
