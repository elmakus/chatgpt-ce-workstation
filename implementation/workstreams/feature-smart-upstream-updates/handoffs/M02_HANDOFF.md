# M02 handoff — exact candidate build and cache semantics

Milestone: `M02`
Status: **GREEN / complete**
Implementation checkpoint: `35e979542815451079fbeb6f6398b70066c5a962`

## Achieved state

The workstation candidate build now consumes one frozen smart-upstream resolution set and uses resolved identities as build/cache inputs instead of timestamp-driven invalidation.

The exact M02 checkpoint:
- binds Ubuntu 24.04 to the frozen image digest and signed Ubuntu InRelease set;
- binds CE, OpenAI ChatGPT package, Agent Workspace, s6-overlay, Codex Web GPT, Muse, Chrome and Rust to the frozen resolution inputs used by the candidate;
- keeps CE's signed OpenAI package path authoritative;
- embeds the canonical non-secret resolution manifest in the candidate and labels the image with its resolution SHA-256;
- keeps `scripts/build.sh` as an exact/pre-resolved lower-level primitive;
- preserves the accepted runtime isolation and disabled self-updater boundaries;
- performs no production recreate or promotion.

## Acceptance and independent review

- CI #141 is GREEN on the exact implementation checkpoint.
- Exact non-production candidate build #11 is GREEN on the same checkpoint.
- Candidate readback matched resolution SHA-256 `837043af65bd6f13793af245c6a32cc2ad6e142504afd9e9cd2b47fbc7d246d8` in both the image label and embedded manifest.
- Candidate image id was `sha256:ef4b0c22c261356fd1c5f1a2b9f17b935160042663149aba0e6debe83686d5a5`.
- Fresh independent review of the exact integrated M01-M02 subject is GREEN: `implementation/workstreams/feature-smart-upstream-updates/evidence/M02-T02-review.md`.
- Implementation evidence remains at `implementation/workstreams/feature-smart-upstream-updates/evidence/M02-T02-implementation.md`.

## Authority now in force

- Requirements: `requirements/SMART_UPSTREAM_UPDATES.md`
- Decisions: D2, D4, D5, D6 as amended by D24, D10, D11, D15, D16, D24 in `docs/DECISIONS.md`
- Approved plan: `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md` revision `smart-upstream-updates-R2`

## Continuation

Next approved milestone: `M03 — Safe promote/verify/rollback updater`.

Execution Prep may now decompose M03 from its approved authority. M03 source implementation and isolated/mock orchestration verification do not authorize a real workstation recreate or production image mutation. The explicit deployment/live-write gate remains in M04.
