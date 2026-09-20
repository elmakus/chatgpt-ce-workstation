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

The warning therefore represents timer age, not proof that the ChatGPT session has expired.

## Existing workstream / dependency discovery

No existing branch/workstream matching this session-refresh issue was found in either `elmakus/chatgpt-ce-workstation` or `elmakus/codex-chatgpt-web`. No relevant open issue/PR was found for the same subject.

The behavior exists on the current fork `main` and does not require unmerged parent-only state.

Classification: **independent**.  
Parent workstream: none.  
Parent branch: none.  
Parent dependency: none.

## Candidate bounded behavior

Use the existing saved-session authentication probe rather than automating a fresh credential ceremony:

1. when a refresh is due, run the existing session revalidation path;
2. if the saved session is verified authenticated, defer the next reminder without showing the warning;
3. if the session is actually unauthenticated, keep the existing interactive sign-in path;
4. if verification fails because of a transient/network error, do not falsely extend freshness;
5. never automate password/passkey/MFA entry.

Post-creation micro-fix classification and the exact implementation contract are still to be materialized before Intake is marked complete.
