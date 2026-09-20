# MF-T01 evidence — Codex-LB launcher proxy resolution

Date: 2026-09-20

## Subject

- Behavioral implementation: `elmakus/codex-chatgpt-web@0b2336dd01520c7a33699a6d90a290b108bebd42`
- Related fork PR: `elmakus/codex-chatgpt-web#8` (draft, open)
- Fork base: `elmakus/codex-chatgpt-web@7fedbca16373ab0a7c3a12123eb9b98811fd2b86`
- Workstation workstream: `issue-codex-lb-proxy-resolution`
- Card: `MF-T01`

## Reproduced root cause

The native network layer rewrites an official Codex request to the configured
`CODEX_CHATGPT_WEB_NATIVE_UPSTREAM` before requesting launcher system-proxy resolution.
The launcher control server previously authorized proxy-resolution targets only when the
URL origin was `https://chatgpt.com` and the path was under `/backend-api/codex/`.

With Codex-LB configured at a target such as
`http://127.0.0.1:2455/backend-api/codex`, the launcher therefore rejected the
already-rewritten outbound URL with HTTP 400. The native network layer surfaced that as
`Launcher native proxy resolution failed (HTTP 400)`, and the CE remote operation surfaced
the resulting 502.

## Implemented correction

The related fork now:

1. keeps the official Codex backend as an allowed proxy-resolution base;
2. passes launcher-owned `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM` and
   `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` values into the browser control server;
3. authorizes only HTTP(S) targets on the exact configured base path or a descendant path;
4. keeps unrelated origins, sibling paths, credentials-bearing targets and unsupported schemes rejected;
5. still resolves PAC/system proxy policy for the actual rewritten outbound URL;
6. leaves native upstream authorization replacement and `chatgpt-web/*` routing unchanged.

Changed fork files:

- `launcher/electron/control-server.cjs`
- `launcher/electron/main.cjs`
- `launcher/tests/control-server.test.cjs`
- `tests/native-network.test.ts`

## Regression coverage

Focused coverage added/extended for:

- official Codex proxy-resolution authorization;
- configured Codex-LB and Muse upstream authorization;
- rejection of unrelated origins and sibling/prefix-confusion paths;
- end-to-end native-network behavior proving the launcher receives the rewritten Codex-LB target;
- dedicated Codex-LB bearer replacement without leaking the incoming ChatGPT OAuth bearer.

## Verification / external readback

Readback on fork PR #8 confirmed:

- PR state: open, draft;
- exact head: `0b2336dd01520c7a33699a6d90a290b108bebd42`;
- mergeable against base `7fedbca16373ab0a7c3a12123eb9b98811fd2b86`;
- GitHub Actions CI run `35498117851` completed with conclusion `success` on that exact head;
- `actionlint` GREEN;
- complete `verify` jobs GREEN on Ubuntu, macOS and Windows;
- packaging/smoke stages GREEN on all applicable runners.

The `bun run verify` stage includes version/audit checks, project and launcher typechecks,
project tests, launcher tests, launcher build, runtime-bundle build, notices generation and
release smoke verification.

## Deployment boundary

No production workstation rebuild/recreate, live configuration change, secret mutation,
fork merge, release publication or workstation consumption was performed by this Card.
Those remain downstream of the independent review boundary and normal close/release flow.

## Review boundary

Independent review requirement: `RECOMMENDED`.

Exact review subject:

`elmakus/codex-chatgpt-web@0b2336dd01520c7a33699a6d90a290b108bebd42`

The implementing chat must not issue the independent verdict.
