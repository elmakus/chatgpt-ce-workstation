# M01-T05 fork release evidence

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T05`

## Publication subject

- Exact independently GREEN candidate: `elmakus/codex-chatgpt-web@2686d2a616864a1bc9cd975901773ab16a54ba47`.
- `release/v5.0.14` was created directly from that SHA without an intervening release or merge commit.
- Fork Linux Release run: `35584309931`.
- Run head: `release/v5.0.14@2686d2a616864a1bc9cd975901773ab16a54ba47`.
- Terminal result: **GREEN**.

Successful publication gates:
- `bun run verify`;
- `bun run app:package`;
- Linux AppImage ABI validation on current Arch;
- virtual-display setup;
- `bun run app:smoke`;
- existing `Publish fork Linux release` step.

## Release readback

- Published release/tag: `v5.0.14`.
- Release is non-draft, non-prerelease and is the current latest release.
- Release target/tag resolves to exact reviewed candidate `2686d2a616864a1bc9cd975901773ab16a54ba47`.
- Published assets:
  - `codex-web-gpt-5.0.14-linux-x64.AppImage`
    - size: `185592534` bytes
    - GitHub digest: `sha256:2c68166425e049241c61ae76eafd42afdde37343e1e887ef977fd43bf636cbf2`
  - `checksums.txt`
    - size: `106` bytes
    - GitHub digest: `sha256:1da748b38bf15aa0e920a56ef7c65991d2fe96169fccc0ec163d83531fe1bee5`

Checksum consistency was independently verified from the publication contract. The workflow writes exactly:

```text
2c68166425e049241c61ae76eafd42afdde37343e1e887ef977fd43bf636cbf2  codex-web-gpt-5.0.14-linux-x64.AppImage
```

including the trailing newline. That exact 106-byte text hashes to `sha256:1da748b38bf15aa0e920a56ef7c65991d2fe96169fccc0ec163d83531fe1bee5`, matching the published `checksums.txt` asset digest.

## Post-publication integration

- Related-fork `main` was fast-forwarded without force to exact candidate SHA `2686d2a616864a1bc9cd975901773ab16a54ba47`.
- Readback compare candidate ↔ `main`: identical, zero commits/files different.
- Candidate PR `elmakus/codex-chatgpt-web#12` is closed after the exact candidate became `main`; no source mutation was required.

## Boundary

No Workstation source, image, container, CLIProxyAPI runtime, Muse endpoint, credentials, or operator runtime values were changed by this Card.

The exact immutable release/tag/SHA and published AppImage checksum are now durable predecessor evidence for the next JIT Workstation D25 consumption step.
