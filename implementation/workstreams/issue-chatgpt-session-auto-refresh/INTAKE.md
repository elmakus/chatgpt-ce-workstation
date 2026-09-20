# Issue Intake — ChatGPT session auto-refresh

Workstream ID: `issue-chatgpt-session-auto-refresh`  
Kind: `issue`  
Branch: `fix/chatgpt-session-auto-refresh`  
Integration target: `main`  
Base: `e796e2fef00e348e2329be1a4856da335dff6842`

## Operator intent

Automate the recurring Codex Web GPT warning that asks the user to refresh the ChatGPT session every two days. A still-valid saved ChatGPT session should be revalidated silently; interactive sign-in should remain necessary only when the saved session is actually invalid or ChatGPT requires reauthentication.

Do not automate passwords, passkeys, MFA, or credential entry.

## Baseline diagnosis

Related source repository: `elmakus/codex-chatgpt-web`  
Inspected source baseline: `main@9de6a670f1934f5f4843a9df0d4b0d408884798f`

The photographed warning is emitted by the fork itself, not by ChatGPT:

- `launcher/src/i18n.ts` defines “Refresh your ChatGPT session” and recommends signing in again every two days.
- `launcher/electron/state.cjs` implements that recommendation as a fixed 48-hour timer: `SESSION_REFRESH_REMINDER_INTERVAL_MS = 48 * 60 * 60 * 1000`.
- `launcher/src/App.tsx` shows the reminder when `sessionRefreshReminderAt` is due while the embedded browser is authenticated.
- `launcher/electron/main.cjs` resets the reminder after explicit login/passkey login or dismissal.
- Launcher startup already calls `browserHost.refreshAuthentication()` in automatic mode.
- `launcher/electron/browser-host.cjs` already has a bounded saved-session revalidation primitive. It loads Temporary Chat and probes `/api/auth/session` with existing browser credentials, validates the returned session/user/expiry and the authenticated composer surface.
- A successful startup authentication refresh currently does not advance `sessionRefreshReminderAt`, so the fixed 48-hour reminder can still appear even when the saved session is demonstrably healthy.
- Repository history shows the reminder was introduced as a fixed preventive 48-hour schedule; its due timestamp is not itself derived from actual session expiry.

The warning therefore represents reminder age, not proof that the ChatGPT session has expired.

## Existing workstream / dependency discovery

No existing branch/workstream matching this session-refresh issue was found in either `elmakus/chatgpt-ce-workstation` or `elmakus/codex-chatgpt-web`. No relevant open issue/PR was found for the same subject.

The behavior exists on the current fork `main` and does not require unmerged parent-only state.

Classification: **independent**.  
Parent workstream: none.  
Parent branch: none.  
Parent dependency: none.

## Intended bounded behavior

Use the existing saved-session authentication probe rather than automating a fresh credential ceremony:

1. when the 48-hour refresh becomes due, automatically run saved-session revalidation;
2. if the saved session is verified authenticated, record that successful verification and defer the next reminder without showing the warning;
3. if the session is actually unauthenticated, retain the existing interactive sign-in path;
4. if verification fails because of a transient/network error, do not falsely extend freshness;
5. never automate password/passkey/MFA entry;
6. preserve current explicit logout/login behavior and existing browser-session isolation.

The implementation belongs in the related fork `elmakus/codex-chatgpt-web`; the workstation workstream remains the Project Workflow authority and records the exact fork commit/PR evidence.

## Micro-fix qualification

- **Root cause and intended behavior are concrete:** a fixed reminder timestamp is decoupled from an already-available authoritative saved-session verification path.
- **Bounded and low strategic risk:** wire successful authentication revalidation to reminder freshness and cover the state transitions with focused tests.
- **No accepted requirement/architecture/product change:** D10/D11/D14 remain unchanged; the fork remains the package source and no secret-handling model changes.
- **Acceptance is direct:** healthy saved sessions suppress/defer the warning only after successful verification; unauthenticated/error cases do not get falsely marked fresh.
- **No substantial migration/deployment strategy:** no schema or persistent-data migration is required; normal fork release/workstation update mechanics remain unchanged.
- **Review risk:** because the behavior touches authentication/session handling, independent review is REQUIRED even though the implementation is bounded.

Path: `micro_fix`  
Next route: `execution_prep:micro_fix`  
Canonical continuation anchor: this completed Intake record plus `WORKSTREAM.yaml`.
