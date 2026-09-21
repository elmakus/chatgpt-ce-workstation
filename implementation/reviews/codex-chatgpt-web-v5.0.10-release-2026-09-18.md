# codex-chatgpt-web v5.0.10 publication evidence

Date: 2026-09-18

## Subject

- Repository: `elmakus/codex-chatgpt-web`
- Release branch: `release/v5.0.10`
- Release commit: `553b98f1cbe456643eb9b1955d84c2007375e99d`
- Parent / reviewed M01 merge: `85d13359bef65208c286ae34e0a00ddbbd185e63`
- Release: `v5.0.10`

The release commit changes only synchronized version metadata from 5.0.9 to 5.0.10 in `package.json`, `launcher/package.json`, and `src/version.ts`.

## Workflow

Fork Linux Release run `35303570175` completed successfully on the exact release commit.

GREEN steps included:
- dependency installation;
- compatible Linux libnotify and owned AppImage tooling;
- `bun run verify`;
- `bun run app:package`;
- Linux AppImage ABI validation;
- packaged app smoke;
- release publication.

## Publication readback

GitHub release readback confirms:
- latest release: `v5.0.10`;
- tag target / release target: `553b98f1cbe456643eb9b1955d84c2007375e99d`;
- `codex-web-gpt-5.0.10-linux-x64.AppImage` published, GitHub digest `sha256:6acc75df69a063dc8b30d305b399f14b56e030b41b1da9c30d096dffefab2428`;
- `checksums.txt` published, GitHub digest `sha256:8ea63a00a2cfb559576bf6ebfc346ef467581b7cb18810da13750c874a9c3420`.

The publication workflow itself generated `checksums.txt` from the AppImage before creating the release.

## Default branch readback

After successful publication, fork `main` was fast-forwarded without force from the reviewed M01 merge to the exact release commit. Readback confirms:
- `main` = `553b98f1cbe456643eb9b1955d84c2007375e99d`;
- root package version = `5.0.10`;
- latest release remains `v5.0.10`.

## Workstation consequence

The workstation installer leaves `CODEX_CHATGPT_WEB_VERSION` empty by default and resolves `releases/latest`. Therefore a subsequent image build with no local version override will resolve `v5.0.10`.

No Unraid/runtime state was modified by this Card.
