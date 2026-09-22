# OPH-M01-T02 Evidence — isolated OpenCodex proof lifecycle

Card: `OPH-M01-T02`  
Implementation subject: `commit:22e226ceb4d6d63b98051c738877c85f69bc9ab5`  
Draft workstream PR: #23

## Source result

The implementation adds an opt-in `workstation-opencodex-proof` lifecycle helper with deterministic isolated OpenCodex/Codex homes under the user's persistent state tree, a dedicated default port, explicit overlap rejection for the normal `~/.opencodex` and `~/.codex` trees, and bounded `start|stop|health|status|paths` commands. It does not call `ocx init`, `ocx service`, `ocx ensure`, or `ocx codex-shim`, and it is not wired into normal desktop/container startup.

The Card also adds deterministic source tests, a disposable exact-candidate runtime smoke script, image executable permissions, and CI ShellCheck coverage for the new helper.

## Deterministic source validation

On the exact source that became `22e226ceb4d6d63b98051c738877c85f69bc9ab5`:

- `git diff --check` — GREEN
- `bash scripts/test-opencodex-proof-lifecycle.sh` — GREEN
- `python3 scripts/test-resolve-upstreams.py` — 23/23 GREEN
- `python3 scripts/test-render-build-env.py` — 15/15 GREEN
- `bash scripts/test-proof-component-installers.sh` — GREEN
- `bash scripts/validate-source.sh` — `SOURCE_VALIDATION_GREEN`

## Exact candidate runtime proof

Tower built the exact non-production candidate from the same frozen source using `scripts/resolve-upstreams.py` plus `scripts/build.sh`.

- image: `chatgpt-ce-workstation-ci:candidate-e6a786ec6416f067`
- image ID: `sha256:3e62479d419c2b10d3d77118e2317a0dbb8c28f984d666e33a0fcaead073a171`
- frozen upstream resolution SHA-256: `e6a786ec6416f067fef1818a9f92db5dbff26a49653befaffc0d446b3751ef0b`
- image provenance label matched that resolution SHA
- `scripts/candidate-opencodex-proof-smoke.sh` against the built image returned `OPENCODEX_PROOF_RUNTIME_GREEN`

The runtime smoke created sentinel files in the normal proof-container `$HOME/.codex` and `$HOME/.opencodex` trees, then exercised the actual frozen installed OpenCodex through the repository helper: start, health, status, and stop. Both sentinel hashes were unchanged after the lifecycle, and the isolated proof homes were created under `$HOME/.local/state/chatgpt-ce-workstation/opencodex-proof/{opencodex,codex-home}`.

## Exact-head GitHub CI

Draft PR #23 triggered CI on exact implementation subject `22e226ceb4d6d63b98051c738877c85f69bc9ab5`.

Run `35702966558`:

- `source-validation` — GREEN
- `dockerfile-check` — GREEN
- `secret-scan` — GREEN
- the source-validation job's ShellCheck step — GREEN and includes `workstation-opencodex-proof`

A separate GitHub Exact candidate build run `35702966572` was also triggered by the draft PR. Card acceptance does not depend on that duplicate build because the exact candidate runtime proof above was already completed against the same source and frozen resolver path.

## Boundary readback

- production CE/Codex route configuration was not changed
- no OpenCodex proof process is started by normal desktop/container startup
- no provider credentials or generated management tokens were added
- provider-family definitions, upstream browser proof daemon startup, route/catalog takeover, and final service-manager choices remain deferred to later JIT Cards
