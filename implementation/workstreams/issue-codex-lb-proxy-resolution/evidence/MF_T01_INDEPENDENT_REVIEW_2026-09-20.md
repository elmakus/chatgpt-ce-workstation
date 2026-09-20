# MF-T01 independent review — Codex-LB launcher proxy resolution

Date: 2026-09-20

## Review owner

- Workstation workstream: `issue-codex-lb-proxy-resolution`
- Card: `MF-T01`
- Review requirement: `RECOMMENDED`
- Review owner: selected workstream Task Board

## Exact immutable subject

`elmakus/codex-chatgpt-web@0b2336dd01520c7a33699a6d90a290b108bebd42`

Related PR: `elmakus/codex-chatgpt-web#8`
Base: `7fedbca16373ab0a7c3a12123eb9b98811fd2b86`

## Authority checked

- `implementation/workstreams/issue-codex-lb-proxy-resolution/INTAKE.md`
- `implementation/workstreams/issue-codex-lb-proxy-resolution/cards/MF-T01.md`
- `docs/DECISIONS.md#D10`
- `docs/DECISIONS.md#D11`
- `docs/DECISIONS.md#D15`
- implementation evidence `MF_T01_CODEX_LB_PROXY_RESOLUTION_2026-09-20.md`

## Independent findings

GREEN.

The exact reviewed subject keeps proxy resolution fail-closed while authorizing the actual rewritten native target:

- the launcher always keeps the official `https://chatgpt.com/backend-api/codex` base;
- only configured `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM` and `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` HTTP(S) bases are added;
- configured bases containing credentials, query strings, fragments, unsupported schemes or invalid URLs are ignored for authorization;
- target authorization requires exact origin plus either the exact base path or a descendant path, so sibling paths and prefix-confusion paths such as `/backend-api/codex-evil/*` remain rejected;
- credentials-bearing target URLs remain rejected;
- proxy resolution still runs against the rewritten outbound request URL, preserving target-specific PAC/NO_PROXY behavior;
- explicit environment proxy handling and unsupported proxy-protocol rejection in `src/native-network.ts` are unchanged;
- native upstream request rewriting still replaces the incoming ChatGPT OAuth bearer with the dedicated configured Codex-LB API key before sending the request.

The focused launcher test covers owner authentication, official Codex acceptance, configured native/Muse acceptance, unrelated-origin rejection, sibling/prefix-confusion rejection and proxy resolver failure.

The focused native-network regression exercises the configured Codex-LB path end-to-end and proves both:
1. launcher proxy resolution receives the rewritten Codex-LB URL; and
2. the upstream receives only the dedicated Codex-LB bearer, not the incoming ChatGPT OAuth bearer.

No production workstation deployment or live configuration mutation is part of this reviewed subject.

## Exact-subject verification

GitHub Actions run `35498117851` is completed with conclusion `success` on exact head `0b2336dd01520c7a33699a6d90a290b108bebd42`.

Observed GREEN jobs:
- actionlint;
- verify on Windows;
- verify on Ubuntu;
- verify on macOS;
- package/smoke stages on applicable runners.

## Verdict

`GREEN`

MF-T01 acceptance is satisfied by the exact immutable subject. No corrective route is required.
