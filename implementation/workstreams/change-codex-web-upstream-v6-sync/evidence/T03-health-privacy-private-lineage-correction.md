# M00-T03 evidence — exact-tree health privacy correction

Date: 2026-09-25
Executor: ChatGPT
Result subject: `elmakus/codex-chatgpt-web@b39499c391744eaa378b157822e18b9218590b60`
Parent/review-RED subject: `7dac256e2607cf6cb46ce0441f17a123fb50bbda`

## Change

The correction is one commit and one test file only:

- `tests/server-lifecycle.test.ts`
- replace the generic `JSON.stringify(snapshot).not.toContain("private")` assertion with explicit negative assertions for the three sensitive fixtures:
  - `private proxy credentials and host`
  - `private upstream account detail`
  - `private-session-token`

No runtime, routing, auth, release, packaging or version source changed. Canonical release identity remains `6.1.0-private.1`.

This directly resolves the independent final-integration RED evidence at `implementation/workstreams/change-codex-web-upstream-v6-sync/evidence/final-integration-review-7dac256e-red.md`: public fork-version metadata may contain the canonical word `private`, while the health regression still proves the actual secret/detail fixtures are absent.

## Exact-subject validation

All checks below ran from an isolated checkout whose HEAD was read back as `b39499c391744eaa378b157822e18b9218590b60`.

- `bun run check-version`: GREEN — `VERSION_SYNC_OK 6.1.0-private.1 bun@1.4.0`.
- Focused `bun test tests/server-lifecycle.test.ts`: GREEN — **38 pass / 0 fail**.
- Full `bun test ./tests`: GREEN — **811 pass / 4 skip / 0 fail**, 6096 expectations across 58 files.
- Root typecheck: GREEN.
- Launcher typecheck + production Vite build: GREEN.
- Node 24 full launcher suite: GREEN — **347 pass / 1 skip / 0 fail** (348 tests).
- Linux x64 AppImage release-path build: GREEN using the CI-equivalent prepared libnotify and owned AppImage toolset.
- Packaged launcher smoke: `PACKAGED_LAUNCHER_SMOKE_OK linux/x64`.
- AppImage symbol/ABI smoke in the build environment: GREEN.
- Current-Arch container ABI smoke: GREEN.
- Built AppImage SHA-256: `cc34d386f0148f5db7c5c89efe0147a02efc5b4f850c5dc4a90a18adf4c94ee6`.

The successful package reproduction explicitly carried the two environment values that GitHub Actions normally propagates between steps through `GITHUB_ENV`: `CODEX_WEB_GPT_LINUX_LIBNOTIFY` and `APPIMAGE_TOOLS_PATH`. Earlier local wrapper attempts that omitted that step-carried environment or passed a relative helper path were environment-harness errors and were discarded; the exact CI-equivalent path above is GREEN.

## External readback

GitHub branch `elmakus/codex-chatgpt-web:work/upstream-v6.1-sync` read back at the exact result SHA `b39499c391744eaa378b157822e18b9218590b60`.

No tag, GitHub release, fork-main publication or Workstation production deployment was performed.

## Review boundary

T03 itself requires no Card-level independent review. The workstream final-integration requirement remains `RECOMMENDED`; the corrected exact subject must be frozen as a new manifest-owned pending review and reviewed by a fresh normal ChatGPT chat before publication.
