# MF-T01 evidence — ydotool UI automation correction

Date: 2026-09-19

## Reviewed implementation subject

- Behavioral/source implementation commit: `8559ce89ab267a38ff26a2529b9ac1ff964241b9`
- Workstream: `issue-ydotool-ui-automation`
- Branch: `fix/ydotool-ui-automation`

## Root-cause evidence

The running workstation image was created at `2026-09-18T13:08:12.087456607Z`.

The container APT history records a later runtime mutation at `2026-09-18 22:50:55`:

- command: `apt-get install -y ydotool`
- requested by: `codex (99)`
- installed: `ydotool 0.1.8-3build1`

The project Dockerfile does not install ydotool. It image-manages `xdotool` and `wmctrl`.

The running Ubuntu 24.04 container reports `ydotool 0.1.8-3build1` as both installed and APT candidate. The container has no `/dev/uinput` and no `ydotoold` executable/process, while `xdotool getmouselocation` succeeds against the Xvfb/Openbox X11 desktop.

Conclusion: the ydotool package was post-build runtime drift created by a Codex task, and the distro package was not a suitable workstation GUI-control substrate.

## Implemented correction

- `defaults/AGENTS.md` now identifies Xvfb/Openbox X11 as the workstation GUI surface and directs GUI automation to existing `xdotool`/`wmctrl`.
- The guidance rejects ad-hoc ydotool installation and records that adding uinput/ydotool daemon support is an explicit architecture/deployment change.
- `scripts/validate-source.sh` asserts the image-managed xdotool dependency and the durable GUI-automation guidance.
- `scripts/verify-runtime.sh` requires `xdotool`/`wmctrl` and performs a live `xdotool getmouselocation` probe.

No ydotool package/update path, device mapping, privilege, capability, or production deployment change was added.

## Verification

Executed from an isolated detached worktree at exact implementation commit `8559ce89ab267a38ff26a2529b9ac1ff964241b9` on the Tower host:

- `bash -n scripts/validate-source.sh scripts/verify-runtime.sh` → GREEN (`SYNTAX_GREEN`)
- `bash scripts/validate-source.sh` → GREEN (`SOURCE_VALIDATION_GREEN`)
- `bash scripts/verify-runtime.sh` → GREEN (`WORKSTATION_RUNTIME_GREEN`)
- Runtime verification confirmed both `xdotool` and `wmctrl` are present and `xdotool getmouselocation` succeeds.

The runtime verification emitted one unrelated pre-existing warning about `/mnt/user/appdata/chatgpt-ce-workstation/home/Documents/ChatGPT.pre-bind-20260917-201518`.

## Persistent-home activation note

The currently persisted `/home/codex/.codex/AGENTS.md` still contains the older workstation template plus its user-managed Codex Workflow block and therefore does not yet contain this new GUI-automation guidance.

This is expected under D12: the workstation deliberately does not overwrite an existing persistent global AGENTS file. Updating that live persistent file safely is outside MF-T01's production-write scope and must preserve the user-managed block.
