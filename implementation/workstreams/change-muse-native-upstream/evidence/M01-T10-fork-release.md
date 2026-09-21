# M01-T10 — v5.0.15 fork release evidence

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T10`

## Publication subject

- Exact independently GREEN candidate: `elmakus/codex-chatgpt-web@3a6d1d28c28dbe1be885077ae53fe4bba62b9673`.
- `release/v5.0.15` was created directly from that exact SHA.
- Readback compare `release/v5.0.15` ↔ reviewed candidate: identical.
- Fork Linux Release run: `35602104526`.
- Run head: `release/v5.0.15@3a6d1d28c28dbe1be885077ae53fe4bba62b9673`.
- Terminal result: **GREEN**.

Successful publication gates:
- dependency/toolchain preparation;
- `bun run verify`;
- `bun run app:package`;
- Linux AppImage ABI validation on current Arch;
- virtual-display setup;
- `bun run app:smoke`;
- existing `Publish fork Linux release` step.

## Release readback

- Published release/tag: `v5.0.15`.
- Release is non-draft and non-prerelease.
- Release target/tag resolves identically to exact reviewed candidate `3a6d1d28c28dbe1be885077ae53fe4bba62b9673`.
- Published assets:
  - `codex-web-gpt-5.0.15-linux-x64.AppImage`
    - size: `185592466` bytes
    - GitHub digest: `sha256:bdad25547ae79f29ee27a029bed5ec6c7762f98a92e7578762de40a113b9b49d`
  - `checksums.txt`
    - size: `106` bytes
    - GitHub digest: `sha256:70a2fee51c14973724c549abf8964f9729f12d8cdb6080ce229d5fc05da6425a`

Checksum consistency was independently verified from the unchanged publication contract. The workflow writes exactly one `sha256sum` line for the AppImage. The expected 106-byte line containing the AppImage digest above hashes to `sha256:70a2fee51c14973724c549abf8964f9729f12d8cdb6080ce229d5fc05da6425a`, which exactly matches the published `checksums.txt` asset digest.

## Concurrent-main isolation

- Pre-publication related-fork `main`: `0f77eb00203f93617f7c38a24ad4e1c6e1cc9d3b`.
- Post-publication readback: `main` remains identical to that SHA.
- No rebase, merge, fast-forward, force/reset or other main mutation was performed.
- The unrelated post-candidate interrupt/integration changes therefore did not enter `v5.0.15`.

Candidate PR `elmakus/codex-chatgpt-web#15` was closed after successful publication and remains unmerged, with exact head `3a6d1d28c28dbe1be885077ae53fe4bba62b9673`.

## Boundary

No Workstation source, image, container, CLIProxyAPI runtime, Muse endpoint, credentials, or operator runtime values were changed by this Card.

The exact immutable release/tag/SHA and AppImage checksum are durable predecessor evidence for the next JIT D25 consumption step.

**GREEN**
