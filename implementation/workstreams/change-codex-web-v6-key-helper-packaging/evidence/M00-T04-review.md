# M00-T04 independent review — Codex-LB key-helper packaging

Date: 2026-09-26
Workstream: `change-codex-web-v6-key-helper-packaging`
Card: `M00-T04`
Review subject: `elmakus/codex-chatgpt-web@78297853c0d17242a241592719e5204e5de30078`
PR: `elmakus/codex-chatgpt-web#21`

## Verdict

GREEN.

No review defect was found against the accepted M00-T04 contract and authority slice.

## Independent checks

- The exact PR head is `78297853c0d17242a241592719e5204e5de30078`, based on `f7251910b526e84bbe85c480341e1a264f455ff5`, with a focused five-file diff.
- `launcher/package.json` includes `assets/set-codex-lb-key.sh` in both `build.files` and `build.asarUnpack`; the existing bounded Linux runner remains present.
- The helper source blob is unchanged from the accepted base, so the correction restores packaging without changing Codex-LB key persistence/auth behavior.
- `launcher/tests/packaging-contract.test.cjs` asserts helper source presence plus both packaging-manifest entries.
- Linux `launcher/scripts/smoke-package.cjs` selects the produced AppImage, runs `--appimage-extract`, and fails unless both `linux-appimage-runner.sh` and `set-codex-lb-key.sh` exist at `resources/app.asar.unpacked/assets`.
- Root package, launcher package and runtime version metadata are `6.1.0-private.2`. Both Bun lockfiles contain no workspace version field and are unchanged; frozen-lockfile installs and the repository version check passed in CI.
- The published `v6.1.0-private.1` release still targets the previously accepted subject. No `v6.1.0-private.2` release existed at review time, so the next canonical private revision is not overwriting an existing release.
- CI run `36201143502` is GREEN on the exact review subject. Ubuntu ran `bun run verify`, `bun run app:package`, Linux AppImage ABI verification, and `bun run app:smoke`; macOS and Windows also completed applicable verify/package/smoke checks.
- The diff does not weaken Workstation's fail-closed helper validation and does not mutate Workstation production.

## Acceptance conclusion

The reviewed subject satisfies the M00-T04 acceptance surface: the required key helper is restored to the packaged launcher and final Linux AppImage, regression coverage exercises the observed omission class, release lineage advances to the next legal private revision, required verification is GREEN, and the production boundary remains intact.
