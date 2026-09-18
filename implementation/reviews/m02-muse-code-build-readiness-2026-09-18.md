# M02-T02 — Muse Code workstation build-readiness evidence

Date: 2026-09-18

## Subject

- Repository: `elmakus/chatgpt-ce-workstation`
- Branch: `feat/muse-code`
- Functional source checkpoint: `3c3bab996a4b188a3566f09e2d7ff3a5146a4fd8`
- Draft integration PR: #1
- Dependency release: `elmakus/codex-chatgpt-web` `v5.0.10`
- Release target: `553b98f1cbe456643eb9b1955d84c2007375e99d`

## Acceptance readback

The next workstation build is source-ready for Muse Code live validation:

- `.env.example` leaves `CODEX_CHATGPT_WEB_VERSION=` empty.
- `scripts/build/install-codex-web-gpt.sh` resolves the fork's `releases/latest` when unpinned, then downloads the Linux AppImage and verifies it against the published checksum.
- GitHub release readback confirms the current latest release is `v5.0.10`, containing the M01 Muse-routing implementation.
- `Dockerfile` installs Muse Code through `scripts/build/install-muse-code.sh` into the immutable `/opt/muse-code/bin` application layer.
- the build helper uses an isolated temporary HOME with `MUSE_LOGIN=0`, so image build does not require/store user login state.
- `/usr/local/bin/muse` executes the image-owned binary and defaults `MUSE_NO_AUTO_UPDATE=1`.
- the existing full `/home/codex` bind remains the persistence boundary for Muse auth/config/session state; no nested Muse bind is introduced.
- runtime verification asserts `muse --version`, `muse --help`, and `muse exec --help`.
- source validation explicitly asserts empty latest-release resolution, Muse installer wiring, image-owned wrapper target, runtime auto-update disablement, and Muse exec surface.

## CI

GitHub Actions PR run `35304113360` on the functional source checkpoint completed GREEN.

A later exact-head run `35304164411` also completed GREEN after state-only metadata was added. Jobs included:

- source-validation — GREEN, including `scripts/validate-source.sh` and ShellCheck;
- dockerfile-check — GREEN;
- secret-scan — GREEN.

## Boundary

No Unraid image build, container recreate, Muse account login, or Muse worker task was performed by this Card.

PR #1 intentionally remains draft and must not be merged before the planned live Unraid validation succeeds.

## Next gate

Live validation on Unraid must record the resolved Muse version and CLI help surface, complete normal Muse account/subscription login, observe persistent paths, prove auth survives restart/recreate, run a bounded disposable-repository `muse exec` task, and validate model/effort, cancellation, sandbox and nested fan-out policy.
