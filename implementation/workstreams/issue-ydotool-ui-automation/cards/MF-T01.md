# MF-T01 — Prevent unsupported ydotool drift in GUI automation

- Milestone: `micro-fix`

> This file is a stable Task Card contract. Mutable execution/review/result state lives only in the selected workstream Task Board.

## Authority slice

- Master Plan / milestone contract: none — qualified micro-fix under R6 + `implementation/workstreams/issue-ydotool-ui-automation/INTAKE.md`
- Requirements: none — bounded workstation behavior correction
- Accepted decisions: `docs/DECISIONS.md#D12`, `docs/DECISIONS.md#D13`
- Relevant OpenSpec: none
- Accepted dependency results: live diagnosis recorded in the completed Intake record

### Must preserve

- Keep the existing Xvfb/Openbox/Tint2 X11 desktop architecture.
- Keep the container unprivileged, without host-root access, Docker socket access, SYS_ADMIN, or a newly exposed `/dev/uinput` device.
- Preserve the existing image-managed `xdotool` and `wmctrl` desktop tools.
- Keep D12 behavior that existing persistent `~/.codex/AGENTS.md` is not silently overwritten.

### Must not / rationale that must travel

- Do not solve this issue by installing or upgrading ydotool in the image.
- Do not add `/dev/uinput`, privileged mode, or new device/capability wiring merely to support ydotool.
- Do not deploy/rebuild the production workstation or merge to `main` in this Card.

## Dependencies

- none

## Outcome

Codex receives durable workstation guidance to use the already-supported X11 automation tools for GUI interaction instead of installing ydotool, and repository/runtime validation protects that supported surface.

## Scope

### Included

- Add a workstation GUI-automation section to `defaults/AGENTS.md`.
- Make `scripts/validate-source.sh` assert the X11 automation guidance and image-managed xdotool presence.
- Make `scripts/verify-runtime.sh` verify `xdotool`/`wmctrl` presence and a functional X11 pointer query.

### Excluded

- Any ydotool installation/update path.
- Compose/device/capability changes.
- Changes to CE, Codex Web GPT, Muse, noVNC, Xvfb, Openbox, Tint2, or Chrome behavior.
- Production workstation package removal/rebuild/recreate.
- Merge to `main`.

## Acceptance

- `defaults/AGENTS.md` explicitly identifies the workstation desktop as Xvfb/Openbox X11 and directs GUI automation to existing `xdotool`/`wmctrl`.
- The guidance states that ydotool is not a supported ad-hoc substitute because this container does not expose the uinput substrate; adding that substrate requires an explicit architecture change.
- `scripts/validate-source.sh` fails if the GUI-automation guidance or Dockerfile xdotool installation disappears.
- `scripts/verify-runtime.sh` requires `xdotool` and `wmctrl` and runs `xdotool getmouselocation` successfully in the workstation desktop.
- `bash scripts/validate-source.sh` and relevant shell syntax/checks are GREEN on the workstream branch.

## Required tests / checks

- `bash -n scripts/validate-source.sh scripts/verify-runtime.sh`
- `bash scripts/validate-source.sh`
- targeted live-runtime probe for `xdotool getmouselocation`
- PR CI when a PR is opened

## External write/readback needs

Git branch/PR only. Production runtime must remain unchanged.

## Independent review

`RECOMMENDED` — behavior/policy guidance and runtime validation change how Codex chooses GUI-control tooling; review should verify that the fix matches the actual container boundary and does not create a hidden privilege/device requirement.

## Contract overrides

None.
