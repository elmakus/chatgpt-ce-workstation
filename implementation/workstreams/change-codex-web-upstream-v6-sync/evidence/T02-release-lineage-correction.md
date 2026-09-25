# T02 evidence — canonical private fork release lineage

Date: 2026-09-25

## Trigger

M00 publication refresh against current Project Workflow `main` found that the accepted T01 candidate used fork version `6.1.1`, while `workflow/common/FORK_RELEASE_VERSIONING.md` requires the first canonical downstream release for accepted upstream baseline `v6.1.0` to be `v6.1.0-private.1`.

The fork still had no canonical `v6.1.0-private.N` release. Existing `v5.0.x` releases are legacy immutable provenance and do not participate in the new baseline-local private counter.

## Exact corrected subject

- Related repository: `elmakus/codex-chatgpt-web`
- Branch: `work/upstream-v6.1-sync`
- Corrected candidate: `7dac256e2607cf6cb46ce0441f17a123fb50bbda`
- Parent reviewed T01 candidate: `0dcf8ed9dbd229cf908cc68b31f4126c0af2414d`
- Accepted upstream baseline: `miuuyy/codex-chatgpt-web v6.1.0`
- Canonical fork release identity: `v6.1.0-private.1`

Branch readback resolved exactly to the corrected candidate.

## Bounded correction

The corrected candidate is exactly one commit ahead of the prior reviewed subject and changes only:

- `package.json`: fork version `6.1.1 -> 6.1.0-private.1`; upstream launcher baseline remains `6.1.0`.
- `launcher/package.json`: launcher/fork package version synchronized to `6.1.0-private.1`.
- `src/version.ts`: runtime-reported fork version synchronized.
- `.github/workflows/release.yml`: canonical `vX.Y.Z-private.N` tags are no longer classified as prerelease merely because they contain a hyphen; ordinary suffixed tags such as RCs retain prerelease behavior.
- `docs/release-validation.md`: documents the private-lineage/stability distinction.
- `launcher/tests/packaging-contract.test.cjs`: focused source contract for canonical private version synchronization and stable publication semantics.

The fork-specific `.github/workflows/fork-linux-release.yml` was not changed. It already derives the release tag from `release/v*`, requires the tag to match `package.json`, builds/smokes the Linux package, emits checksums, refuses to overwrite a release whose tag resolves to another SHA, and creates the release as latest/stable.

No runtime routing, auth, Muse/Codex-LB behavior, interrupt-hook implementation, proxy behavior, browser integration, isolation behavior, or Workstation production state changed.

## Exact validation

Validation ran against an isolated temporary clone pinned to `7dac256e2607cf6cb46ce0441f17a123fb50bbda` on Tower using an ephemeral `oven/bun:1.4.0` container:

- `bun run check-version` — GREEN: `VERSION_SYNC_OK 6.1.0-private.1 bun@1.4.0`.
- `bun test launcher/tests/packaging-contract.test.cjs` — GREEN: 13 pass, 0 fail.
- root TypeScript typecheck — GREEN.
- launcher TypeScript typecheck — GREEN.
- launcher Vite production build — GREEN.
- repository remained source-clean after validation (ignoring dependency install artifacts as configured by Git).
- `actionlint v1.7.7` over `.github/workflows/*.yml` — GREEN.

A first host-native validation attempt found only that Tower does not expose `bun` in the host PATH; validation was rerun in the pinned ephemeral Bun container and completed GREEN. Two initial actionlint harness invocations failed before linting (Go PATH, then unexpanded glob); the corrected shell invocation completed GREEN.

## Review consequence

The previous manifest final-integration GREEN verdict covered `elmakus/codex-chatgpt-web@0dcf8ed9dbd229cf908cc68b31f4126c0af2414d` and explicitly reviewed its former `6.1.1` release/version split. It therefore does not cover this corrected publication subject.

The workstream-level RECOMMENDED final-integration gate must be re-frozen on `elmakus/codex-chatgpt-web@7dac256e2607cf6cb46ce0441f17a123fb50bbda` before fork-main merge or release publication.
