# M04-T01-C02 implementation evidence

Status: **GREEN implementation — REQUIRED independent review pending**

Related repository: `elmakus/codex-chatgpt-web`  
Branch: `fix/multi-agent-normalization`  
PR: #6 (draft)  
Exact implementation subject: `9317954b0e9391bb0def278c54e04084b1699465`  
Base: `main@c8dc0a58d4a3d0ebf319d02ad4b16352c5e19415`

## Live regression reproduced

The production workstation is healthy on its current exact image, but Codex Web GPT v5.0.11 reports an ownership mismatch after current Codex normalizes the Compatibility V1 managed line:

```toml
multi_agent = true # Managed by codex-chatgpt-web: enables routed Web subagents.
```

to:

```toml
multi_agent = true
```

The version-10 integration journal proves the prior `multi_agent` assignment was absent and the installed protocol is Compatibility V1, so this exact literal form is a native normalization of bridge-owned state rather than a pre-existing user setting.

## Correction

The implementation:
- adds one explicit native-normalized constant: literal `multi_agent = true`;
- keeps generic managed boolean verification strict by default;
- allows the native-normalized form only in the Compatibility V1 `multi_agent` verifier/restore path;
- makes journal-driven restore/deactivate/uninstall recognize the same bounded owned form;
- continues to reject `multi_agent = false`, altered/commented forms, duplicate assignments and other ownership mutations;
- preserves exact restoration of the previous user line when one existed, or removal when the journal baseline says the assignment was absent.

No persistent production config was manually rewritten. No corrected release was published and no production redeployment was performed by C02.

## Exact source scope

The subject is one commit ahead of related-repository `main` and changes only:
- `src/codex-integration-document.ts`;
- `src/codex-integration-route.ts`;
- `src/codex-integration-shared.ts`;
- `tests/codex-integration.test.ts`.

## Verification

GitHub Actions CI run `35494779591` / run number 29 is GREEN on the exact head `9317954b0e9391bb0def278c54e04084b1699465`:
- actionlint: GREEN;
- verify Ubuntu: GREEN;
- verify macOS: GREEN;
- verify Windows: GREEN;
- main Bun suite: 739 pass / 0 fail;
- launcher test suite: 309 pass / 0 fail;
- launcher typecheck/build: GREEN;
- packaging and application smoke: GREEN;
- relocatable runtime smoke: GREEN.

Focused regression tests all PASS:
- Compatibility V1 accepts Codex-native `multi_agent` comment normalization and restores an absent baseline;
- Compatibility V1 restores an exact prior `multi_agent` user line after native comment normalization;
- Compatibility V1 still rejects non-native `multi_agent` ownership mutations.

## Review boundary

REQUIRED independent review subject:

`elmakus/codex-chatgpt-web@9317954b0e9391bb0def278c54e04084b1699465`

Publication/release and production revalidation remain blocked until this exact subject receives an independent GREEN verdict.
