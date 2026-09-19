# M01-T01 noVNC workarea correction evidence

Date: 2026-09-19

## Baseline defect

Live workstation desktop stack before source correction:

- Xvfb display: 1920x1080, single Xinerama head.
- Tint2: 17.0.1.
- Openbox: 3.6.1.
- Tint2 was the only window publishing an EWMH strut.
- With `panel_dock = 1`, Tint2 published a nominal 38 px bottom strut, but Openbox root `_NET_WORKAREA` became `960,0,960,1080` on all four desktops.
- Maximized application windows therefore used only the right half of the display.

## Candidate correction

Set `panel_dock = 0` while preserving:

- `panel_position = bottom center horizontal`;
- `panel_layer = top`;
- full-width `panel_size = 100% 38`;
- EWMH dock window type and 38 px bottom strut.

A dedicated regression probe was added at `scripts/test-desktop-workarea.sh`.

## Exact-runtime verification

The probe was executed inside the running workstation container using its installed Xvfb/Openbox/Tint2 stack, on isolated test displays only.

Results:

- 1280x720: `DESKTOP_WORKAREA_GREEN 1280x720 panel=38`.
- 1920x1080: `DESKTOP_WORKAREA_GREEN 1920x1080 panel=38`.
- At 1280x720, root workarea was `0,0,1280,682`, Tint2 remained `_NET_WM_WINDOW_TYPE_DOCK`, panel geometry was 1280x38 at y=682, and the bottom strut remained 38 px.
- Maximized probe windows started at x=0 and used the full display width.

## Negative regression proof

The same probe was run against an otherwise-identical temporary config with `panel_dock = 1`.

Expected failure was observed:

`FAIL: unexpected _NET_WORKAREA: _NET_WORKAREA(CARDINAL) = 960, 0, 960, 1080, ...`

The probe exited non-zero, proving it detects the exact reported regression.

## Source verification

`bash scripts/validate-source.sh` completed with `SOURCE_VALIDATION_GREEN`.

PR CI evidence is appended after the branch is pushed and the pull request checks finish.
