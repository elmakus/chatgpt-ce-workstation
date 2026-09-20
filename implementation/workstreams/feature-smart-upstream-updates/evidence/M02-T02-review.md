# M02-T02 independent review

Verdict: **GREEN**

Review subject: `35e979542815451079fbeb6f6398b70066c5a962`
Workstream: `feature-smart-upstream-updates`
Card: `M02-T02`

## Scope reviewed

Independent review against the exact M02 Task Card authority slice:
- `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md#milestone-m02--exact-candidate-build--cache-semantics`
- requirements R1-R9 and R13-R16 as carried by the Card, with M02 ownership focused on R2-R9/R13-R16
- accepted decisions D2, D5, D6, D10, D11, D15, D16 and D25
- completed M01 checkpoint plus exact GREEN M02-T01 dependency result

## Findings

No blocking correctness, authority, provenance, cache-semantics, trust-boundary or scope finding was identified on the immutable review subject.

The reviewed implementation:
- resolves moving upstreams first and carries exact/frozen identities into the candidate build;
- removes timestamp/global-no-cache invalidation from the normal candidate path;
- keeps CE and the official OpenAI package as distinct cache/provenance inputs while retaining CE's signed-package validation path;
- binds Ubuntu 24.04 to an exact image digest and verifies the frozen signed Ubuntu InRelease set during relevant APT phases;
- binds Agent Workspace, s6-overlay, Codex Web GPT, Muse, Chrome and Rust to frozen version/hash/integrity inputs with fail-closed drift checks where the upstream distribution path remains moving;
- embeds the canonical non-secret resolution manifest and labels the built image with the same resolution SHA-256;
- keeps `build.sh` as a frozen-input build primitive and does not resolve latest inside that wrapper;
- preserves the accepted container isolation/runtime-self-update boundaries;
- does not perform production recreate, promotion or rollback in M02.

## Evidence verified

- GitHub associates CI run #141 (run id `35482343888`) and Exact candidate build run #11 (run id `35482343889`) with exact review subject `35e979542815451079fbeb6f6398b70066c5a962`; all inspected jobs concluded success.
- Candidate run readback verified:
  - resolution SHA-256 `837043af65bd6f13793af245c6a32cc2ad6e142504afd9e9cd2b47fbc7d246d8`;
  - image id `sha256:ef4b0c22c261356fd1c5f1a2b9f17b935160042663149aba0e6debe83686d5a5`;
  - image label SHA-256 equals the resolution SHA-256;
  - embedded `/opt/workstation/upstream-resolution.json` byte-compares with the resolved manifest and hashes to the same SHA-256.
- Exact source inspection covered the resolver, manifest renderer, lower-level build wrapper, Compose build arguments, Dockerfile consumption/checks, Ubuntu APT identity assertion, Muse/Codex Web GPT installers, candidate-build workflow and resolver/build-input fixture coverage.
- Current PR head had advanced past the review subject only through durable Task Board/evidence bookkeeping; compare `35e9795..c5ac8b5` showed no behavioral source change. The review remained attached to the immutable subject above.

## Boundary

This GREEN verdict covers only the exact integrated M01-M02 subject `35e979542815451079fbeb6f6398b70066c5a962`. It does not pre-approve M03 production lifecycle implementation or any later changed subject.
