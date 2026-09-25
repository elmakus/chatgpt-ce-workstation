# CWUS-M01-T01 — Rebase deployed Codex Web fork behavior onto upstream v6.1.0

- Milestone: `CWUS-M01`

> This file is a stable Task Card contract. Mutable execution/review/result state lives only in the selected manifest-bound workstream Task Board.

## Authority slice

- Master Plan / milestone contract: `docs/IMPLEMENTATION_PLAN.md#phase-7--codex-web-gpt-configuration-and-audit`
- Requirements: `implementation/workstreams/change-codex-web-upstream-sync/INTAKE.md`
- Accepted decisions: `docs/DECISIONS.md#d10--image-owns-systemapplication-state`, `docs/DECISIONS.md#d11--codex-web-gpt-included-our-fork-is-the-default-package-source`
- Relevant OpenSpec: none
- Accepted dependency results: deployed `elmakus/codex-chatgpt-web@v5.0.16` = `d7c9db70cf1d54029c061490d73335146a23ed28`; upstream `miuuyy/codex-chatgpt-web@v6.1.0` = `293341084ac7a1ddd2de12fede3706023f5b6474`

### Must preserve

- Upstream v6.1.0 browser/UI, model/effort, continuation/compaction, limits and launcher behavior unless a fork-specific accepted behavior requires a bounded compatibility adaptation.
- Normal browser-backed `chatgpt-web/*` behavior when custom native routes are unset.
- Codex-LB native routing remains opt-in, uses a dedicated credential, never forwards the incoming ChatGPT OAuth bearer to the configured custom upstream, and fails closed when configured without usable auth.
- Parallel Muse routing remains deterministic for `muse-*`, imports only Muse rows from CLIProxyAPI, preserves Codex-LB/native and browser-backed catalogs when Muse is unavailable, and preserves the currently deployed Muse Gmail/web-search request normalization until upstream behavior proves it unnecessary.
- Workstation image owns installed application state; packaged launcher self-update remains disableable for image-managed deployment.
- Fork release artifacts remain checksum/provenance-verifiable by Workstation's resolver.

### Must not / rationale that must travel

- Do not use current fork `main` as the behavioral source; it omits release-only code present in deployed `v5.0.16`.
- Do not independently replace ChatGPT Desktop's embedded Codex CLI; the official ChatGPT package owns that runtime.
- Do not drop fork-specific behavior merely because upstream touched the same file; resolve semantic conflicts explicitly.
- Do not publish a new stable fork release in this Card. Publication is gated on this Card's independent GREEN review.

## Dependencies

- none

## Outcome

Produce a tested migration branch in `elmakus/codex-chatgpt-web` whose baseline incorporates upstream v6.1.0 and whose behavior retains the still-required Workstation-specific patchset from deployed v5.0.16.

## Scope

### Included

- Create an isolated fork migration branch.
- Merge/reconcile upstream v6.1.0 with deployed v5.0.16 behavior.
- Resolve all textual and semantic conflicts.
- Update version metadata only as needed for a non-published migration candidate.
- Preserve/reconcile fork-specific tests and add/update regression coverage where upstream 6.x changed affected surfaces.
- Run upstream unit/integration/package checks practical on Linux plus focused Codex-LB, Muse, interrupt-hook, model-catalog, launcher-update and AppImage packaging checks.
- Persist exact branch/head/test evidence for independent review.

### Excluded

- Publishing/tagging a stable fork release.
- Updating Workstation's running image.
- Changing Workstation accepted architecture or provider ownership.
- Independently upgrading embedded Codex CLI.

## Acceptance

1. Migration branch has exact ancestry/evidence tying it to upstream v6.1.0 and deployed fork v5.0.16 behavior.
2. All seven dry-run textual conflicts are resolved with explicit semantic preservation.
3. Upstream v6.1.0 functionality is present, including current ChatGPT UI compatibility and v6 model/effort surfaces.
4. Codex-LB native routing/auth behavior remains covered and GREEN.
5. Muse routing/catalog/Gmail/web-search compatibility remains covered and GREEN.
6. Interrupt-hook and model-catalog regressions are GREEN against upstream 6.x changes.
7. Upstream project tests and Linux packaging/AppImage validation relevant to the changed surfaces are GREEN or any non-applicable check is explicitly evidenced.
8. No stable release/tag or Workstation production mutation occurs before independent review.

## Required tests / checks

- repository unit/integration test suite;
- typecheck/lint/build checks defined by upstream package scripts;
- focused native-network/native-passthrough/model-catalog/codex-integration/codex-interrupt-hook/server-model tests;
- launcher control-server/update/package tests;
- Linux AppImage/package smoke used by the project;
- exact Git diff/ancestry and clean-tree verification.

## External write/readback needs

- Write only to a new migration branch in `elmakus/codex-chatgpt-web`.
- Read back the exact pushed branch HEAD and CI/check results.
- No release/tag and no production Workstation write in this Card.

## Independent review

`RECOMMENDED` because this reconciles a large upstream release with security-sensitive auth/routing and lifecycle-hook customizations.
