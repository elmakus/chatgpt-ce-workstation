# M04-T01 live regression evidence

Status: **BLOCKED — bounded compatibility correction required**

## Production activation result

The first authorized M04 production smart-update cycle completed successfully on the target workstation.

- frozen resolution SHA-256: `9024b66f4b60bfad8c21916ef8d9bda146d271c55f02f90823caf486fe735393`
- promoted candidate image: `sha256:214ac0f0ddbfbba6d1eb4621906ee992f947493f0b3428d93f225f273f060e9e`
- retained previous image: `sha256:c1470837045e2a2c57523174f3f3d7527e00e978576a42cd7af27051a6c2b830`
- retained rollback tag: `chatgpt-ce-workstation:rollback-c1470837045e2a2c`
- updater status: `success`
- production readback: running + healthy on the exact candidate
- image label and embedded `/opt/workstation/upstream-resolution.json` both match the frozen resolution SHA
- Ubuntu: 24.04.5 LTS / noble
- runtime isolation, mounts, persistence, secrets, desktop health and `verify-runtime.sh`: GREEN
- Computer Use doctor: GREEN readiness with no blockers; X11, AT-SPI and xdotool available
- Agent Workspace 0.3.3: present
- CE app-server: running with `--remote-control`
- Codex Web GPT launcher/proxy/tunnel/browser runtime: running

No rollback/fault-injection test has been started yet. The previous production image remains retained.

## Blocking application regression

Codex Web GPT 5.0.10 reports `Doctor result: not ready`.

The only error is:

`Codex interrupt lifecycle hook changed after setup; refusing to overwrite it`

The route remains installed and active, and the Responses proxy/browser/tunnel runtime are healthy.

Exact diagnosis:

- the managed interrupt-hook command still points to the expected Codex Web GPT 5.0.10 runtime;
- the trusted hash is unchanged;
- there is exactly one managed interrupt-hook group and one start/end marker;
- current Codex has normalized the managed command hook by inserting `enabled = true` after `timeout = 3`;
- the Codex Web GPT 5.0.10 integration journal stores the same managed fragment without that field;
- byte-for-byte comparison therefore fails even though the hook remains enabled and its command/hash semantics are unchanged;
- `src/codex-interrupt-hook.ts` in `elmakus/codex-chatgpt-web` currently requires exact owned-definition equality and has no compatibility case for this native `enabled = true` normalization.

The persistent config was not manually edited to suppress the failure.

## Corrective classification

This is a bounded implementation compatibility defect inside the accepted M04/D10/D25 authority. No requirement, architecture decision, milestone outcome or live-write authorization needs to change.

The safe correction must remain fail-closed:
- accept only the native-compatible `enabled = true` normalization for the exact owned command hook;
- continue rejecting `enabled = false`, command/timeout/trust changes, duplicate hooks and unrelated owned-definition mutation;
- prove verify + restore behavior through deterministic tests;
- publish/use the corrected Codex Web GPT artifact through the existing managed-upstream mechanism;
- re-run the affected M04 production regression before M04-T01 can become GREEN.

M04-T02 remains blocked behind M04-T01 and must not begin before this regression is corrected and reverified.
