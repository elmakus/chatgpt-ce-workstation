# Fork publication checkpoint — Codex-LB proxy resolution

Date: 2026-09-20

## Reviewed implementation merge

- reviewed subject: `elmakus/codex-chatgpt-web@0b2336dd01520c7a33699a6d90a290b108bebd42`
- implementation PR: `elmakus/codex-chatgpt-web#8`
- PR #8 merged successfully
- merge commit: `ae16daaf0b657971d41994fa0b9acc79d14c26ee`
- pre-merge target: `7fedbca16373ab0a7c3a12123eb9b98811fd2b86`
- no behavioral commit was added to the reviewed head before merge

## Publication wrapper

Existing latest release before this publication is `v5.0.12`; its tag points to pre-fix commit `750cafe9bab55d13ce60ff415ec864f415429201`.

Release branch `release/v5.0.13` was created from the reviewed implementation merge `ae16daaf0b657971d41994fa0b9acc79d14c26ee`.

Release PR: `elmakus/codex-chatgpt-web#9`

Exact release-wrapper head: `377fee05896278395da68beb5c3bef926cde1344`

The effective diff from fork `main` is publication-only:
- `package.json`: version `5.0.12 -> 5.0.13`
- `launcher/package.json`: version `5.0.12 -> 5.0.13`
- `src/version.ts`: version `5.0.12 -> 5.0.13`

No proxy/auth/routing source or tests are changed by the release wrapper.

## Verification state

- PR #9 CI run: `35499177021`
- current state at checkpoint: in progress
- `v5.0.13` tag: absent
- `v5.0.13` release: absent

Publication remains incomplete until CI is GREEN, the exact release-wrapper head is tagged, the release workflow publishes the checksummed artifacts, and those artifacts are read back.
