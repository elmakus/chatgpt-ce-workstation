# M01-T01 Independent Review Evidence

Card: `M01-T01`
Workstream: `issue-remove-novnc-password`
Review subject: `elmakus/chatgpt-ce-workstation@a13757a8611201a15784dd4d0250ac1c35068cb6`
Implementation source/docs subject: `f7128b4cf7c0405a9c678c298c5033a436182200`
Verdict: **GREEN**
Date: 2026-09-20

## Independent review

The immutable review subject was checked against the M01-T01 Card, approved NPA R1 requirements, NPA-P1 M01 plan, and accepted D7/D14-preserved/D27 decisions.

Findings:

- Compose no longer wires the `novnc_password` secret and still publishes only the existing noVNC/websockify container port; raw TCP 5900 is not host-published.
- Container init no longer reads `/run/secrets/novnc-password`, generates `vnc.pass`, or requires either artifact.
- x11vnc is explicitly started with `-nopw` and retains `-localhost`, `-rfbport 5900`, `-forever`, `-shared`, and the existing desktop supervision path.
- Host initialization and preflight no longer create, prompt for, or require the noVNC password secret.
- Source/runtime validators reject reintroduction of legacy noVNC auth wiring, verify loopback-only/passwordless x11vnc, prohibit raw-VNC host publication, and retain the unrelated Docker-isolation/keyring/application checks.
- README and deployment documentation state the intended passwordless/trusted-network security boundary without adding replacement authentication or broadening exposure.
- No destructive cleanup of legacy password artifacts and no production deployment are part of the reviewed subject.

## Runtime evidence assessment

The implementation evidence is tied to exact source/docs subject `f7128b4cf7c0405a9c678c298c5033a436182200`, whose only later commit inside the review subject adds that evidence record. It reports:

- shell/source validation GREEN;
- exact isolated image build GREEN;
- isolated no-secret runtime healthy;
- no host 5900 binding;
- x11vnc `-localhost -nopw` with no `-rfbauth`;
- noVNC HTTP GREEN;
- RFB 3.8 offering only security type `None`.

The full verifier's fresh-empty-home keyring failure was reproduced identically on exact baseline `e796e2fef00e348e2329be1a4856da335dff6842` under the same artificial conditions. The NPA patch does not modify that keyring path, so this is accepted as a demonstrated pre-existing baseline condition rather than an NPA regression.

## Verdict basis

All M01-T01 acceptance requirements relevant to the reviewed change are satisfied by the exact immutable subject and its exact runtime evidence. The approved network/container boundaries are preserved, the VNC/noVNC password dependency is removed, and no unreviewed behavioral drift exists between the tested implementation source/docs subject and the frozen review subject.

**GREEN — no corrective work required.**
