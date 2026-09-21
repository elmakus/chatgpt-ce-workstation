# CMAU-M03-T01 implementation evidence

Date: `2026-09-20`
Implementation / candidate subject: `elmakus/chatgpt-ce-workstation@577a64630b6aa942b89c7c657265f3d6e8f448f3`
Card: `CMAU-M03-T01`

## Candidate identity

- Source branch was verified identical to exact subject `577a64630b6aa942b89c7c657265f3d6e8f448f3` before validation.
- Validation used an isolated detached worktree on the authorized Tower checkout; the user's normal repository checkout remained on its unrelated active branch.
- Candidate image tag: `chatgpt-ce-workstation:cmau-m03-577a646`.
- Built candidate image ID: `sha256:d381d48737aa059fe3b53b8ebda5243c80df357bb346c6d6cbff11441e425894`.
- Disposable container name: `cmau-m03-577a646`.
- Candidate used an isolated test home/projects/secrets root under `/mnt/user/projects/.workflow-runtime/cmau-m03-577a646`; no production Workstation home/configuration was mounted.

## Source/build verification

GREEN on exact subject:

- `bash scripts/validate-source.sh` -> `SOURCE_VALIDATION_GREEN`.
- The validator included 21 shell/run syntax checks, 9/9 managed-global-AGENTS fixtures, 14/14 deterministic marketplace-updater tests, Docker Compose config validation, service/image wiring, desktop/health independence and secret hygiene.
- `docker build --progress=plain -t chatgpt-ce-workstation:cmau-m03-577a646 .` completed successfully and produced the image ID above.

## Runtime identity and first-run success

The disposable candidate reached Workstation health GREEN.

Runtime readback:

- `/opt/codex-desktop/resources/codex --version` -> `codex-cli 0.155.0-alpha.9.2`.
- Marketplace updater process: `python3 /opt/workstation/bin/codex_marketplace_updater.py`.
- Process owner: user `codex`, UID `99`, GID `100`.
- `getent passwd codex` reports home `/home/codex`.
- s6 logged successful start of `codex-marketplace-updater`.
- First real bundled-Codex zero-marketplace cycle succeeded with `selected=0 upgraded=0`.
- First persisted state: `lastSuccessUnix=1789869977.1133566`.
- Workstation health remained GREEN.

## Restart/recreate cadence persistence

Using the same isolated home and without editing the timestamp:

- restart before due:
  - before: `1789869977.1133566`
  - after:  `1789869977.1133566`
  - updater log: not due, waiting about 86356 seconds
  - result: GREEN.
- full disposable-container recreate before due:
  - before: `1789869977.1133566`
  - after:  `1789869977.1133566`
  - updater log: not due, waiting about 86345 seconds
  - result: GREEN.

This proves the cadence state survives both restart and container recreate through the persistent isolated `/home/codex` bind and does not refresh merely because the service/container starts.

## Controlled due refresh

The isolated test state timestamp was set to an intentionally overdue value and only the updater service process was restarted under s6.

- due seed: `1789780058.2603638`
- after verified real bundled-Codex success: `1789870059.6116369`
- updater log: `Marketplace refresh succeeded; selected=0 upgraded=0; next refresh in 86400 seconds`
- Workstation health: GREEN.

The success timestamp advanced only after the real zero-marketplace bundled-Codex command completed successfully.

## Controlled failure and recovery

Failure was injected only in the disposable container overlay by temporarily replacing the bundled-Codex pathname with an `exit 42` wrapper after moving the original executable aside. No repository source, production image or production persistent state was changed.

Before injection, the original bundled Codex SHA-256 was:
`c544a899873ce1a51506304bb2818af6975a97715bb8c4c9ff0abd566a3fe3f6`.

With an intentionally overdue isolated state:

- failure seed: `1789780098.1552107`
- state after command exit 42: `1789780098.1552107` — unchanged.
- updater log: refresh failed, last-success unchanged, retrying in `3600` seconds.
- updater remained an s6-managed process running as `codex` (UID 99/GID 100).
- Workstation health remained GREEN.

The original bundled executable was then restored and verified against the exact pre-injection SHA-256. Restarting the updater produced normal recovery:

- recovery seed: `1789780098.1552107`
- recovery success: `1789870122.238573`
- updater log returned to `selected=0 upgraded=0` success.
- Workstation health remained GREEN.

## Harness notes

Two candidate-only diagnostic attempts were corrected without changing repository source or production state:

- the first manual due-state fixture accidentally wrote a literal `\\n` suffix, producing malformed JSON before the fixture was rewritten correctly;
- an initial in-place executable overwrite was rejected by the kernel with `Text file busy`; the successful failure-injection method used rename + disposable wrapper instead.

Neither event altered the immutable candidate source or the user's production Workstation.

## Cleanup / production boundary

After evidence capture:

- the exact disposable container was removed;
- the exact candidate image tag was removed;
- the isolated runtime fixture directory and detached validation worktree were removed;
- cleanup readback was GREEN.

No live production Workstation recreate/replacement occurred. No production `/home/codex`, real marketplace configuration or credential material was mutated.

## Acceptance assessment

GREEN for the CMAU-M03-T01 implementation/runtime scope:

- exact candidate source/build identity recorded;
- real s6 service and process identity validated;
- real CE-bundled Codex path exercised;
- zero-marketplace first-run success persisted state;
- restart/recreate-before-due preserved state without refresh;
- controlled due state refreshed and advanced success state;
- controlled failure preserved last-success, used bounded one-hour retry, and did not affect desktop/Workstation health;
- restored command path recovered normally;
- full source validation remained GREEN;
- production/live state was not touched.

The Card is implementation-complete but remains non-terminal pending its RECOMMENDED fresh independent exact-subject review.
