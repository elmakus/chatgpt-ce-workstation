# Fork publication evidence — Codex-LB proxy resolution

Date: 2026-09-20

## Reviewed implementation merge

- reviewed subject: `elmakus/codex-chatgpt-web@0b2336dd01520c7a33699a6d90a290b108bebd42`
- implementation PR: `elmakus/codex-chatgpt-web#8`
- PR #8 merge commit: `ae16daaf0b657971d41994fa0b9acc79d14c26ee`
- pre-merge target: `7fedbca16373ab0a7c3a12123eb9b98811fd2b86`
- the merge commit has the reviewed subject as its second parent and no additional behavioral change was added to the reviewed head.

## Publication wrapper

Release PR: `elmakus/codex-chatgpt-web#9`

Release branch final PR head: `377fee05896278395da68beb5c3bef926cde1344`

Effective PR diff from the implementation merge is publication-only:
- `package.json`: version `5.0.12 -> 5.0.13`
- `launcher/package.json`: version `5.0.12 -> 5.0.13`
- `src/version.ts`: version `5.0.12 -> 5.0.13`

No proxy/auth/routing source or tests are changed by the release wrapper.

Full release-wrapper CI:
- run: `35499177021`
- exact head: `377fee05896278395da68beb5c3bef926cde1344`
- conclusion: `success`
- actionlint + Ubuntu/macOS/Windows verify/package/smoke matrix: GREEN.

## Fork Linux release

The fork's `Fork Linux Release` workflow publishes automatically from `release/v*` branches once synchronized version metadata passes verification.

The first synchronized release subject was:
`44aa77084d7925276bb496634e36f76dc2b2fb5d`

Relative to the reviewed implementation merge, this subject contains only the three version bumps plus JSON formatting expansion in `launcher/package.json`; it contains no behavioral code/config change.

Publication run:
- workflow: `Fork Linux Release`
- run: `35499147200`
- subject: `44aa77084d7925276bb496634e36f76dc2b2fb5d`
- conclusion: `success`
- verify: GREEN
- package: GREEN
- Linux AppImage ABI check: GREEN
- packaged-app smoke: GREEN
- publish: GREEN.

Published release:
- tag: `v5.0.13`
- tag target: `44aa77084d7925276bb496634e36f76dc2b2fb5d`
- release id: `392361900`
- AppImage: `codex-web-gpt-5.0.13-linux-x64.AppImage`
- GitHub asset digest: `sha256:ce2e60699a711993d8013a2a8c8b3951ebbf7b1ce968836176eb5ec4d8350270`
- `checksums.txt` content for the AppImage: `ce2e60699a711993d8013a2a8c8b3951ebbf7b1ce968836176eb5ec4d8350270`
- checksum manifest asset digest: `sha256:11a66e8c49926c21d398b6713c82a0cc8ef5849d57930db03714889cec8c7037`

The checksum manifest and GitHub AppImage asset digest agree.

A subsequent release-branch push at `377fee05896278395da68beb5c3bef926cde1344` reran `Fork Linux Release` as run `35499158145`. All build/verify/package/ABI/smoke steps were GREEN; only the publish step failed, intentionally and fail-closed, because `v5.0.13` already resolved to the earlier publication subject `44aa77084d7925276bb496634e36f76dc2b2fb5d`. No published asset was replaced.

Release PR #9 was then merged to fork `main` as:
`9de6a670f1934f5f4843a9df0d4b0d408884798f`

## Workstation consumption

The workstation installer defaults to `elmakus/codex-chatgpt-web`, resolves the latest release when `CODEX_CHATGPT_WEB_VERSION` is unset, downloads the Linux AppImage and `checksums.txt`, and verifies the AppImage SHA-256 before installation.

Therefore a future authorized workstation image build will consume published `v5.0.13` under the existing D11 release-consumption contract.

No production workstation rebuild/recreate or live configuration mutation was performed by this workstream.
