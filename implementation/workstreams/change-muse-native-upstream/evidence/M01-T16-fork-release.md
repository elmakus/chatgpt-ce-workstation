# M01-T16 — v5.0.16 fork release evidence

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T16`

## Publication subject

- Exact independently GREEN candidate: `elmakus/codex-chatgpt-web@d7c9db70cf1d54029c061490d73335146a23ed28`.
- `release/v5.0.16` was created directly from that exact SHA.
- Fork Linux Release run: `35624009487`.
- Run head: `release/v5.0.16@d7c9db70cf1d54029c061490d73335146a23ed28`.
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

- Published release/tag: `v5.0.16`.
- Release is non-draft and non-prerelease.
- Release target/tag resolves identically to exact reviewed candidate `d7c9db70cf1d54029c061490d73335146a23ed28`.
- Published assets:
  - `codex-web-gpt-5.0.16-linux-x64.AppImage`
    - size: `185592508` bytes
    - GitHub digest: `sha256:7a46e032a74d1bd848a8d946f36d4d427ec2a89e6aa047c518a0bd6bea922f30`
  - `checksums.txt`
    - size: `106` bytes
    - GitHub digest: `sha256:0d5d4fd8e0094d03d3251123479cc4e96aab792a1215a42cd6a42e74cae07b83`

Checksum consistency was independently read back. `checksums.txt` contains exactly the AppImage digest above, and the downloaded checksum file hashes to the published GitHub digest.

## Concurrent-main and stale-branch isolation

- Pre/post related-fork `main`: `0f77eb00203f93617f7c38a24ad4e1c6e1cc9d3b`.
- Pre/post divergent stale prep branch `release-prep/v5.0.16`: `68142a3f1725e052a606f488ac2c525db650a661`.
- Neither ref was mutated.
- Candidate PR `elmakus/codex-chatgpt-web#18` is closed and unmerged with exact head `d7c9db70cf1d54029c061490d73335146a23ed28`.

## Boundary

No Workstation source/image/runtime, CLIProxyAPI runtime, Muse endpoint, credential or operator runtime value was changed by this Card.

The exact immutable release/tag/SHA and AppImage checksum are durable predecessor evidence for the next JIT D25 consumption Card.

**GREEN**
