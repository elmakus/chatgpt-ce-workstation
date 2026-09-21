# Workstation toolchain

`openai/codex-universal` is the reference for the breadth of the development environment. It is not used directly as the base image because its runtime/toolchains are arranged around `/root`, while this workstation intentionally runs daily work as the persistent non-root `codex` user under `/home/codex`.

Reference: https://github.com/openai/codex-universal

## Principle

The image should contain the tools that are broadly useful across projects. Project-specific dependencies should remain in the project when practical.

The agent is allowed to install a missing tool temporarily inside the running container with passwordless `sudo` when that is the fastest way to unblock work. A successful temporary system-level install is not considered complete infrastructure work: after the tool is proven useful, the agent must make the corresponding durable source change so the next rebuilt image contains the tool too.

Use the correct durable location:

- OS package/library/tool -> `Dockerfile`.
- Runtime/deployment setting, mount, port, device, environment or secret wiring -> `compose.yaml`.
- s6 service/startup behavior -> `rootfs/`.
- Project-only dependency -> the project manifest/environment when possible, not the workstation image.

Never rely on the writable container layer as the only copy of an important tool or configuration.

## Current v1 baseline

The current Dockerfile includes a broad daily-use development set:

- Git, Git LFS, GitHub CLI, OpenSSH client, rsync;
- curl, wget, jq, Ubuntu `yq`, ripgrep, fd, tree, archives and compression tools;
- GCC/G++, Clang, make, CMake, Ninja and pkg-config;
- Python 3, pip, pipx and venv;
- Go;
- Rust toolchain for CE/native feature builds;
- OpenJDK 21;
- SQLite plus PostgreSQL/MariaDB/Redis clients;
- ffmpeg, ImageMagick, Poppler and qpdf;
- process/network/debug tools;
- Xvfb, Openbox, xterm, x11vnc, noVNC and X11 Computer Use helpers;
- official Google Chrome Stable installed from Google's signed Debian repository;
- ChatGPT Community Edition and its bundled Codex;
- Agent Workspace backend pinned to `0.3.2` by default;
- codex-chatgpt-web.

### Chrome / browser workflows

The image installs `google-chrome-stable`, not Ubuntu's Chromium transition package. Ubuntu 24.04 routes Chromium through Snap, which is unnecessary complexity inside this Docker workstation.

The image exports:

```text
BROWSER_BIN=/usr/bin/google-chrome
CHROME_BIN=/usr/bin/google-chrome
```

This is intended to serve both CE's upstream Browser/Chrome integrations and `agent-workspace-linux workspace open-browser` workflows. Chrome remains part of the immutable image and is refreshed by the workstation `UPSTREAM_REFRESH` update path. Do not add `--no-sandbox` globally as a first response to a browser startup issue; validate the non-root container sandbox path first.

### `yq` note

Ubuntu 24.04's package named `yq` is the Python/jq-style implementation, not Mike Farah's Go `yq` v4. That is acceptable for first bring-up, but agents must not assume Mike Farah CLI syntax. If the Go implementation becomes useful across projects, replace/add it explicitly and pin the chosen version in the Dockerfile.

## `codex-universal` parity target

OpenAI's reference image is broader than the v1 baseline. Its current categories include:

- Python 3.10/3.11/3.12/3.13/3.14 plus pyenv, Poetry, uv, ruff, black, mypy, pyright and isort;
- Node 18/20/22 (and current Dockerfile revisions may include additional versions) plus npm, corepack, Yarn, pnpm, Prettier, ESLint and TypeScript;
- multiple Rust toolchains plus rustfmt/clippy;
- multiple Go versions plus golangci-lint;
- multiple JDKs plus Maven and Gradle;
- Swift;
- Ruby;
- PHP;
- Bun;
- Bazel/Bazelisk;
- Erlang and Elixir;
- protobuf compiler, ccache, SWIG, ctags, NASM/YASM and a broad native-development library set.

The goal is practical category parity, not byte-for-byte duplication of `codex-universal`. Do not make the first Remote-Control bring-up fragile solely to preinstall every historical runtime version.

Preferred evolution:

1. prove CE + noVNC + Android Remote;
2. keep the broad baseline image working;
3. add missing `codex-universal` categories in reproducible layers;
4. where multi-version runtimes materially help, use a version manager or immutable image install rather than ad-hoc user state;
5. pin important versions once the first working workstation image is established.

## Self-improving workstation workflow

When an agent encounters a missing tool:

```text
need tool now
  -> install temporarily (sudo/package manager if appropriate)
  -> verify it actually solves the task
  -> decide whether it is workstation-wide or project-only
  -> update Dockerfile / compose.yaml / project manifest as appropriate
  -> run syntax/build checks
  -> commit and push the durable change when repository policy permits
```

The agent may report that a rebuild is required. It must not attempt to gain host-level Docker control by adding `/var/run/docker.sock` or other broad host access without explicit user approval.
