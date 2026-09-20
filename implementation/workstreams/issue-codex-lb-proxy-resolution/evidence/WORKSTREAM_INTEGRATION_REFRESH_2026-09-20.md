# Workstream integration refresh — Codex-LB proxy resolution

Date: 2026-09-20

## Scope

Workstream: `issue-codex-lb-proxy-resolution`

Qualified micro-fix Card: `MF-T01`

Reviewed behavioral subject:

`elmakus/codex-chatgpt-web@0b2336dd01520c7a33699a6d90a290b108bebd42`

## Initial integration refresh

At the first Close refresh:
- workstation target `main` was still `04440574afb2d85790301c915e9d7f8c90721021`, equal to the workstream base;
- fork target `main` was still `7fedbca16373ab0a7c3a12123eb9b98811fd2b86`, equal to PR #8 base.

That allowed the one-Card micro-fix final-integration gate to reuse the independent MF-T01 GREEN review because the behavioral subject and both targets were unchanged.

## Final pre-integration refresh

Immediately before workstation integration, `elmakus/chatgpt-ce-workstation@main` had advanced to:

`c32898eaa20a60aaddec8edad96dfc3e91cc4bdc`

The movement from the original base `04440574afb2d85790301c915e9d7f8c90721021` is the independently completed smart-upstream-updates workstream. It materially changes workstation build/update mechanics, so compatibility was rechecked rather than assuming the earlier refresh remained sufficient.

### Compatibility reconciliation

Current `main` still preserves D11: the workstation package source for Codex Web GPT remains `elmakus/codex-chatgpt-web` and the Linux release checksum must be verified.

D25 changes the consumption mechanism from an implicit moving download to `resolve -> freeze -> build -> validate -> promote`:

- `scripts/resolve-upstreams.py::resolve_codex_web_gpt` resolves the fork's stable GitHub release;
- it requires both the Linux AppImage and `checksums.txt`;
- it parses the AppImage SHA-256 and freezes the identity as `version@sha256:<digest>`;
- `scripts/build/install-codex-web-gpt.sh` now requires an exact resolved version and exact frozen SHA-256;
- the installer verifies that the frozen SHA still matches the published checksum manifest and that the downloaded AppImage bytes match the same digest.

Published `v5.0.13` satisfies that current contract:
- release: `v5.0.13`;
- AppImage: `codex-web-gpt-5.0.13-linux-x64.AppImage`;
- published checksum: `ce2e60699a711993d8013a2a8c8b3951ebbf7b1ce968836176eb5ec4d8350270`.

Therefore current workstation `main` will resolve/freeze the fixed release, rather than invalidate or bypass the reviewed Codex-LB proxy-resolution behavior.

### Workstream branch surface

The workstation workstream contributes only the namespaced `implementation/workstreams/issue-codex-lb-proxy-resolution/**` Intake/Card/Task Board/review/evidence package. It introduces no workstation runtime, build, resolver, Compose or live configuration change.

The behavioral implementation remains in the fork and was already independently reviewed on the immutable subject.

## Related fork integration/publication

The independently reviewed fork subject was merged through PR #8 as:

`ae16daaf0b657971d41994fa0b9acc79d14c26ee`

Publication-only release metadata then produced `v5.0.13`; release PR #9 was merged to fork `main` as:

`9de6a670f1934f5f4843a9df0d4b0d408884798f`

Exact publication evidence is recorded in `FORK_PUBLICATION_2026-09-20.md`.

## Final-integration review coverage

The independent GREEN Card review continues to cover the complete behavioral workstream acceptance surface after target reconciliation:

1. MF-T01 is the only implementation Card and contains the entire behavioral change.
2. The reviewed behavioral subject remains exactly `elmakus/codex-chatgpt-web@0b2336dd01520c7a33699a6d90a290b108bebd42`.
3. Later fork changes are merge/release metadata only and do not change proxy/auth/routing behavior.
4. Current workstation target movement changes only how the already-published fork release is resolved and frozen; it does not modify the reviewed fork behavior.
5. The current resolver/installer contract is stricter than the original release-consumption path because it freezes and re-verifies the published SHA-256 before installation.
6. The workstation workstream itself adds evidence/state only, with no production code/config change.

No new behavioral review subject is created by this reconciliation. The final-integration gate remains GREEN and no corrective review route is required.

## Production boundary

Production workstation rebuild/recreate and live configuration mutation remain excluded from this workstream. A later authorized workstation update can consume `v5.0.13` through the current D25 resolver/freeze path.
