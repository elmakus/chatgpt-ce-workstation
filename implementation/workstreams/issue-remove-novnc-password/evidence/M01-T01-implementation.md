# M01-T01 Implementation Evidence — Passwordless noVNC

Card: `M01-T01`
Workstream: `issue-remove-novnc-password`
Implementation source/docs subject tested: `f7128b4cf7c0405a9c678c298c5033a436182200`
Baseline: `main@e796e2fef00e348e2329be1a4856da335dff6842`
Date: 2026-09-20

## Implemented contract

- Removed the Compose `novnc_password` secret and host-side noVNC password provisioning/preflight requirement.
- Removed container-init generation/requirement of persistent `vnc.pass`.
- x11vnc now starts with `-nopw` while retaining `-localhost`, `-rfbport 5900`, `-forever`, `-shared` and existing desktop supervision.
- Source/runtime validation now rejects legacy `novnc_password` / `-rfbauth` wiring and verifies raw VNC remains unpublished.
- README/deployment documentation now states the passwordless trusted-network boundary.
- No destructive cleanup of obsolete password artifacts and no production deployment were performed.

## Source and build verification

On an isolated clone of exact subject `f7128b4cf7c0405a9c678c298c5033a436182200` on Tower:

- edited-shell `bash -n`: GREEN;
- `bash scripts/validate-source.sh`: `SOURCE_VALIDATION_GREEN`;
- repository grep found legacy noVNC auth strings only in negative regression assertions in `validate-source.sh` / `verify-runtime.sh`;
- frozen upstream resolution SHA-256: `6c10d740d4873176f0cd96039490adc0c7c3ce2fe32e9e82941e45ad5808db50`;
- isolated candidate build `chatgpt-ce-workstation-npa-test:npa-test`: GREEN;
- candidate image ID: `sha256:55109d65baf448cd1d328582cc93868ce9349433cbc143a654b546a7ba86696e`.

## Targeted isolated runtime smoke

A separate Compose project/container was started from the candidate image with:

- temporary empty persistent home/project roots;
- only an empty test keyring migration file;
- **no** `novnc-password` file/secret;
- `NOVNC_BIND_IP=127.0.0.1`, host noVNC port `16080`;
- no production container/image replacement or restart.

Observed:

- container reached Docker `healthy`;
- no `/run/secrets/novnc-password` existed;
- host PortBindings contained no `5900/tcp`;
- actual x11vnc command line contained `-localhost` and `-nopw`, and no `-rfbauth`;
- noVNC `/vnc.html` returned successfully over HTTP;
- direct loopback RFB handshake returned `RFB 003.008` with security types `[1]` (`None`);
- markers: `RFB_PASSWORDLESS_GREEN`, `NOVNC_HTTP_GREEN`, `NPA_TARGETED_RUNTIME_GREEN`.

This directly proves the candidate desktop/VNC stack starts healthy without the noVNC secret and offers passwordless RFB while raw VNC remains unexposed to the host.

## Full verifier and baseline exception

Running the updated `scripts/verify-runtime.sh` against the isolated candidate:

- Compose/container healthy: GREEN;
- noVNC published and raw 5900 not host-published: GREEN;
- exact mounts / no Docker socket / no host-root bind: GREEN;
- unprivileged and no `SYS_ADMIN`: GREEN;
- passwordless noVNC runtime section: GREEN;
- then failed in the unchanged keyring section with `FAIL: default Secret Service collection is locked` on the artificial brand-new empty home.

To classify that failure, exact baseline `main@e796e2fef00e348e2329be1a4856da335dff6842` was built with the same frozen upstream resolution (baseline image ID `sha256:a9a4c563c828be3ca807886d388ce0930c34246745e5b13f7b294b4ce5092976`) and run with the same fresh-home/keyring conditions plus its required test-only legacy VNC password secret. It reached Docker `healthy` and reproduced the identical verifier failure at `default Secret Service collection is locked`.

Therefore the fresh-empty-home keyring verifier failure is an exact pre-existing baseline condition, not a regression caused by M01-T01. The NPA patch does not modify keyring startup/migration code or its validation semantics.

## External-write/readback

- Only isolated temporary test containers/images were created.
- Cleanup readback after testing showed no `chatgpt-ce-npa-*` containers and no `chatgpt-ce-workstation-npa-*` images remaining.
- Production checkout remained `main...origin/main` at the inspected baseline; no production Workstation recreate/restart/deployment was performed.
