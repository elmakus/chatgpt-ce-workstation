# Intake — issue-ydotool-ui-automation

## Identity

- Kind: issue
- Workstream: `issue-ydotool-ui-automation`
- Branch: `fix/ydotool-ui-automation`
- Base: `elmakus/chatgpt-ce-workstation@77cd342c4ebffc57b84356fd6e224a1dc1afa5e3`
- Integration target: `main`
- Dependency classification: independent
- Parent workstream: none

## Operator intent

Investigate why Codex reported that GUI control was blocked by an old `ydotool 0.1.8`, determine whether that old tool came from the workstation image/update path, and prevent recurrence when the workstation already provides a compatible X11 automation surface.

## Baseline diagnosis

Observed on the running `chatgpt-ce-workstation` container on 2026-09-19:

- Container image creation time: `2026-09-18T13:08:12.087456607Z`.
- APT history records `apt-get install -y ydotool` at `2026-09-18 22:50:55`, requested by user `codex (99)`.
- Installed package and APT candidate: `ydotool 0.1.8-3build1` from Ubuntu Noble/Universe.
- Ubuntu 24.04 package index: https://packages.ubuntu.com/noble/amd64/ydotool
- Upstream ydotool has newer 1.x releases including v1.0.4: https://github.com/ReimuNotMoe/ydotool/releases
- Project `Dockerfile` installs `xdotool`, not `ydotool`.
- `xdotool getmouselocation` succeeds in the live Xvfb/Openbox desktop.
- `compose.yaml` does not map `/dev/uinput`; the live container has no `/dev/uinput`.
- The live container has no `ydotoold` executable after installing only the Noble `ydotool` package.
- `defaults/AGENTS.md` permits temporary installation of missing tools but does not identify the supported GUI automation surface.

Conclusion: ydotool was runtime drift introduced after the image was built, not an image-managed dependency. Rebuilding does not upgrade it because it is not in the Dockerfile, and Noble currently packages 0.1.8.

## Workstream discovery / base decision

No existing ydotool-specific workstream was found. Existing Muse and noVNC workstreams do not provide parent-only state required by this issue. The issue is independent and based on current `main`.

## Micro-fix qualification

- Root cause and intended behavior are concrete: use the existing X11 automation surface instead of installing ydotool for this desktop.
- Change is bounded and low risk: clarify global workstation guidance and verify the supported X11 automation tool.
- No accepted requirement, architecture or product decision changes are needed; the change reinforces D12 and D13.
- Acceptance is direct: guidance prefers `xdotool`/`wmctrl`, warns that ydotool needs explicit uinput architecture support, and validation verifies the supported X11 tool.
- No substantial migration or deployment strategy is needed. Existing persistent `~/.codex/AGENTS.md` may require an explicit refresh because D12 intentionally does not overwrite it.

## Downstream classification

- Path: `micro_fix`
- Next route: `execution_prep:micro_fix`
- Canonical continuation anchor: this completed Intake record plus `WORKSTREAM.yaml`.
