# M02-T02 implementation evidence — integrated M01-M02 subject

Review subject: `35e979542815451079fbeb6f6398b70066c5a962`
Workstream: `feature-smart-upstream-updates`
Branch: `feat/smart-upstream-updates`
PR: #7

## Exact acceptance evidence

- PR CI run #141 (run id `35482343888`) is GREEN on exact subject `35e979542815451079fbeb6f6398b70066c5a962`: source validation, frozen resolver/build-input fixtures, desktop workarea regression, ShellCheck, Dockerfile BuildKit static check and secret scan all passed.
- Exact candidate build run #11 (run id `35482343889`) is GREEN on exact subject `35e979542815451079fbeb6f6398b70066c5a962`.
- The candidate resolver froze resolution SHA-256 `837043af65bd6f13793af245c6a32cc2ad6e142504afd9e9cd2b47fbc7d246d8`.
- The exact non-production candidate was `chatgpt-ce-workstation-ci:candidate-837043af65bd6f13`, image id `sha256:ef4b0c22c261356fd1c5f1a2b9f17b935160042663149aba0e6debe83686d5a5`.
- Candidate readback proved the image label SHA-256 and embedded `/opt/workstation/upstream-resolution.json` SHA-256 both equal the frozen resolution SHA-256 above.
- The final candidate build consumed the exact Ubuntu 24.04 base digest and exact frozen Ubuntu InRelease set; later third-party repositories added by required build dependencies do not redefine the frozen Ubuntu identity.
- CE source is bound to the frozen CE commit while the official OpenAI package remains a separate frozen identity and continues through CE's signed stable-repository trust path.
- Agent Workspace, s6-overlay, Codex Web GPT, Muse, Chrome and Rust consume frozen exact versions/checksums/integrities rather than independently resolving moving latest values during candidate build.
- Build-input fixtures prove stable manifest -> stable candidate seed/build inputs and component-specific invalidation mappings. Source assertions reject `UPSTREAM_REFRESH`, global `--no-cache`, and resolver invocation from lower-level `build.sh`.
- The candidate build/readback ran only on a GitHub-hosted non-production runner. No production workstation recreate, promotion, rollback or live-write operation occurred.

## Integrated predecessor evidence

M01 remains frozen at `b337578fd3bad298cd96ec69d82ae2ebc3b5c6f0` with its cumulative handoff at `implementation/workstreams/feature-smart-upstream-updates/handoffs/M01_HANDOFF.md` and CI #102 GREEN. The review subject above contains the complete integrated M01-M02 implementation history.

## Review boundary

M02-T02 remains non-terminal until the RECOMMENDED fresh independent review of the exact subject above is GREEN. M03 production-activation work must not start before that review is resolved.
