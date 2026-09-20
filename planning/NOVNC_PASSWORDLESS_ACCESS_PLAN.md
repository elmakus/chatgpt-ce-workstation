# noVNC Passwordless Access — Master Plan

Plan revision: `NPA-P1`
Status: `approved`
Review requirement: `RECOMMENDED`
Updated: `2026-09-20`

## Goal and authority

Implement the approved passwordless noVNC target defined by:

- `requirements/NOVNC_PASSWORDLESS_ACCESS.md` R1;
- `docs/DECISIONS.md#D7 — Lightweight recoverable noVNC desktop`;
- `docs/DECISIONS.md#D14 — Security / exposure`, except the password requirement superseded below;
- `docs/DECISIONS.md#D27 — noVNC recovery desktop is intentionally passwordless on trusted networks`.

The workstream is independent and targets `main`.

## Execution baseline

Current source requires a host-side `novnc-password` secret, creates persistent `vnc.pass`, starts x11vnc with `-rfbauth`, and verifies that authenticated state across setup/preflight/source/runtime checks.

Raw VNC is already loopback-only and only websockify/noVNC is published. That topology must remain unchanged.

## Milestone M01 — Passwordless noVNC runtime contract

### Outcome

The Workstation starts and exposes the recovery desktop through noVNC without any VNC password secret or password prompt, while preserving the existing trusted-network and loopback-only VNC boundaries.

### Requirement ownership

Owns NPA-001 through NPA-005.

### Planned work packages

1. **Runtime authentication removal**
   - remove the Compose `novnc_password` secret wiring;
   - stop generating/requiring persistent `vnc.pass` during container init;
   - start x11vnc explicitly in passwordless mode while retaining `-localhost`, `-forever`, `-shared`, the existing display/port and desktop supervision semantics.

2. **Host setup and validation reconciliation**
   - stop prompting for or requiring the noVNC password in `scripts/init-unraid.sh`;
   - remove noVNC-secret requirements from host preflight;
   - update source validation so passwordless noVNC is the required contract and regressions back to `-rfbauth`/required secret wiring fail;
   - update runtime verification so absence of `vnc.pass` is accepted/expected and raw VNC publication remains prohibited.

3. **Documentation and regression coverage**
   - update user-facing setup/runtime documentation to describe passwordless noVNC and the trusted-network security consequence;
   - preserve or add deterministic checks that verify noVNC password artifacts are not required and that x11vnc remains loopback-only;
   - ensure unrelated keyring, CE, Codex Web GPT, desktop restart and container-isolation checks remain intact.

### Acceptance checkpoint

M01 is GREEN when all of the following hold on the exact implementation subject:

- no source/runtime path requires `APPDATA_ROOT/secrets/novnc-password`;
- no source/runtime path requires or generates `/home/codex/.config/workstation/vnc.pass`;
- x11vnc is configured for passwordless access and still binds only to container loopback;
- Compose publishes only websockify/noVNC, not raw VNC;
- source validation and relevant deterministic test fixtures pass;
- a build/runtime smoke or equivalent exact runtime evidence proves the desktop/noVNC stack starts without the noVNC secret and reaches healthy state;
- existing isolation and unrelated keyring/application behavior remain unchanged by the patch.

## Security, migration and rollback strategy

- The security model is intentionally passwordless at the VNC layer. Trusted-network reachability remains the access-control boundary.
- Do not widen the published bind or add raw VNC exposure.
- Existing installations may retain obsolete `novnc-password` and `vnc.pass` files; the new runtime ignores them. No destructive cleanup is required for the source change.
- Keeping obsolete files untouched preserves straightforward rollback for an existing installation to an older image that still expects them.
- A fresh installation created after this change may need a VNC secret recreated manually before rolling back to an older image; this is acceptable and should be documented if rollback instructions are touched.

## Verification strategy

Execution Prep must create concrete Task Card acceptance around the exact affected files. Verification should include:

- repository source validation;
- shell/static checks covering edited shell/Compose files;
- deterministic passwordless-noVNC assertions;
- image build or equivalent build validation;
- exact container/runtime smoke where the workstation starts with no `novnc-password` secret;
- checks that no raw VNC host publication or container privilege expansion was introduced.

A live production update of the user's Unraid workstation is **not** implied by source implementation or merge. It requires an explicit operator authorization at the deployment/live-write gate.

## Requirement coverage

| Requirement | Owner milestone | Execution path |
|---|---|---|
| NPA-001 | M01 | Runtime authentication removal + runtime smoke |
| NPA-002 | M01 | Runtime configuration + publication/isolation verification |
| NPA-003 | M01 | Preserve bind topology + documentation/security checks |
| NPA-004 | M01 | Host setup/preflight/source/runtime validation reconciliation |
| NPA-005 | M01 | Regression validation of unrelated workstation behavior |

## JIT decomposition

Execution Prep may split M01 into one or more concrete Cards according to the actual current source surface, but may not change the approved security model, expose raw VNC, or introduce a new authentication mechanism without returning to Project Definition.

## Planning audit

GREEN:

- Definition prerequisites are approved and coherent.
- The plan does not invent new product/security intent.
- All NPA requirements map to M01 and a concrete execution path.
- Runtime, migration/rollback, verification and live-deployment boundaries are explicit.
- No unresolved research question blocks execution.
- Independent plan review is practical and therefore classified `RECOMMENDED`.
