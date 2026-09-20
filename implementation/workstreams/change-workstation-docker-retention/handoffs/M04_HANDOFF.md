# M04 handoff — Live Unraid verification

Milestone: `M04`
Plan revision: `workstation-docker-retention-R1`
Status: **GREEN / done**
Implementation checkpoint: `9c2523a0bd0ae18c43a3a559a05e57e8275aaa77`

## Achieved state

The accepted workstation Docker-retention implementation has been exercised through the normal updater path on the real Tower/Unraid Docker backend.

- corrected D26-compatible host preflight accepts the intentionally empty passwordless keyring placeholder and still rejects a missing placeholder;
- production was built and promoted from the exact reviewed subject and exact frozen upstream resolution;
- runtime verification passed before cleanup, after the persistence recreate, and in an independent post-write readback;
- image retention converged to exactly current production plus one previous known-working rollback image;
- stale Workstation lifecycle references were removed only after verified promotion;
- the dedicated Workstation Buildx builder uses the `docker-container` driver and bounded GC;
- useful cache survived cleanup and an unchanged-input rebuild reused the retained cache;
- persistent home/projects/secrets/keyring state and unrelated Docker workloads were preserved.

## Acceptance and evidence

Primary live acceptance:
`implementation/workstreams/change-workstation-docker-retention/evidence/M04-T02.md`

Pre-live integrated implementation review:
`implementation/workstreams/change-workstation-docker-retention/evidence/M04-T01.md`

Corrected keyring-preflight subject and independent review:
`implementation/workstreams/change-workstation-docker-retention/evidence/M04-T03.md`

Exact accepted implementation subject:
`9c2523a0bd0ae18c43a3a559a05e57e8275aaa77`

Exact promoted image:
`sha256:9a6be62fdab865a9dce65412933acd21d1a944e4c250172ddb8e0afdbceb5248`

Exact retained rollback baseline:
`sha256:dcf23c733b28b39827b2b6161cea880d3b45151b698ae5a6427bdd397ea1dd5a`

Frozen upstream resolution:
`ff89c28ab47d599919bb98ac70493f5a00b711ce8d36a0e32655b8e454d9bb93`

Live acceptance highlights:
- `WORKSTATION_RUNTIME_GREEN` before and after recreate and on independent post-write verification;
- image cleanup success: 8 stale Workstation lifecycle refs removed, 0 failures, 2 retained;
- BuildKit cleanup success on dedicated `chatgpt-ce-workstation` builder;
- 5.842 GB useful cache retained after bounded GC;
- unchanged-input rebuild: 24/24 Dockerfile slots observed, slots 2–24 explicit `CACHED`, pinned base slot completed without rebuild, identical candidate image ID;
- unrelated control sets preserved: 113 containers and 74 tagged images;
- persistent directory metadata and keyring/secrets SHA-256 inventories unchanged.

## Authority in force

- `planning/WORKSTATION_DOCKER_RETENTION_MASTER_PLAN.md#Milestone-M04--Live-Unraid-verification`
- `requirements/SMART_UPSTREAM_UPDATES.md#R11`
- `requirements/SMART_UPSTREAM_UPDATES.md#R12`
- `requirements/SMART_UPSTREAM_UPDATES.md#R16` through `#R24`
- `docs/DECISIONS.md#D25`
- `docs/DECISIONS.md#D26`
- `docs/DECISIONS.md#D28`

## Material exceptions

The runtime verifier reports the already-known preserved pre-migration backup:
`/mnt/user/appdata/chatgpt-ce-workstation/home/Documents/ChatGPT.pre-bind-20260917-201518`.
It is not part of retention cleanup and was not modified by M04.

## Next durable starting point

M04 is complete. The workstream is ready for the branch-isolated final-integration refresh/review gate against current `main`.

Before integration:
1. refresh exact workstream content against current `main`;
2. satisfy the manifest-owned final-integration review gate;
3. only then publish/integrate into `main` and perform target-side closure reconciliation.

No further live Docker/deployment mutation is required by the approved M04 scope.
