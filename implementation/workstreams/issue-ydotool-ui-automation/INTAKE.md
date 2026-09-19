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
- `/var/log/apt/history.log` records `apt-get install -y ydotool` at `2026-09-18 22:50:55`, with `Requested-By: codex (99)`.
- Installed package: `ydotool 0.1.8-3build1`; APT candidate is the same Noble/Universe package.
- Ubuntu 24.04 package index also exposes `0.1.8-3build1`: https://packages.ubuntu.com/noble/amd64/ydotool
- Upstream ydotool has newer 1.x releases, including v1.0.4: https://github.com/ReimuNotMoe/ydotool/releases
- Project `Dockerfile` installs `xdotool`, not `ydotool`.
- `xdotool getmouselocation` succeeds in the live Xvfb/Openbox desktop.
- `compose.yaml` intentionally does not map `/dev/uinput`; the live container has no `/dev/uinput`.
- The live container has no `ydotoold` executable after installing only the Noble `ydotool` package.
- `defaults/AGENTS.md` currently permits temporary installation of missing tools but does not state that this workstation's GUI automation surface is X11/`xdotool` and that `ydotool` is unsupported without an explicit uinput architecture change.

Conclusion: the old ydotool was runtime drift introduced by a Codex task after the image was built, not a package baked into the image. A normal rebuild/update does not explain or fix this mismatch: ydotool is not image-managed, and Ubuntu Noble's current package is still 0.1.8.

## Workstream discovery / base decision

Repository branch/workstream discovery found no existing ydotool-specific issue lane. Existing Muse and noVNC workstreams do not provide parent-only state required to reproduce or fix this issue. The issue is therefore independent and is based directly on current `main`.

## Downstream classification

Pending post-creation micro-fix qualification.
