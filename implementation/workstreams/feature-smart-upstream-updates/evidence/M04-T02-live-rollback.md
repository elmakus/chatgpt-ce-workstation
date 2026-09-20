# M04-T02 live rollback and no-change update verification

Status: **GREEN**

## Accepted production subject

The accepted production candidate before and after this exercise is:

- frozen resolution SHA-256: `27a9929c4cb4da99c0c3cd4c4e5807539ad759b5360559a872664162b5ba1fff`
- candidate tag: `chatgpt-ce-workstation:candidate-27a9929c4cb4da99`
- candidate image ID: `sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`
- retained previous image ID used for the rollback exercise: `sha256:e11e3f473ee45c25585f79f7b891e18f359a0a133d9b3e37359e7514233a4972`
- retained previous-image tag: `chatgpt-ce-workstation:rollback-e11e3f473ee45c25`

The live execution subject before evidence bookkeeping was `c4ba05b1d3f7fc01cd83379c8125c97a899c4fda`.

## Persistent-data sentinels

Before fault injection, two disposable sentinels were created across the accepted persistence boundaries:

- persistent home SHA-256: `530750285ebc38818d0b73452907ae1703ddfd9cd1c85050501503b74f999661`
- project bind SHA-256: `196a9c438bfea8e7d1156488b678132ee794a168e7097f30db88b9d8dc2ba81d`

The project sentinel was also read back directly from the host-backed `/mnt/user/projects` bind.

Both hashes remained unchanged after the rollback and after restoration of the accepted candidate. The sentinels were removed after final verification.

## Bounded live rollback

To ensure the updater had a genuinely different previous image, production was first recreated from the retained known-working `e11e3f...` image. That baseline became healthy and passed the full `scripts/verify-runtime.sh` gate before the fault run.

The actual `scripts/update.sh` implementation was then sourced by an ephemeral `/tmp` wrapper. The wrapper changed no repository file and overrode only `verify_runtime()` so that:

1. the first invocation, after exact candidate promotion, returned a controlled failure;
2. the next invocation, used by the real rollback path, delegated to the unmodified `scripts/verify-runtime.sh`.

The normal updater then:

- resolved the same exact frozen resolution;
- rebuilt the exact `ea264b...` candidate with cache reuse;
- captured `e11e3f...` as the actual previous production image;
- promoted `ea264b...`;
- reached healthy state;
- received the injected post-promotion runtime-verification failure;
- entered the real `rollback_after_failure` path;
- recreated production from the retained `rollback-e11e3f473ee45c25` tag;
- reached healthy state on the rollback image;
- passed the full runtime verifier;
- read back the exact expected prior image ID.

The updater returned failure status as required for the failed candidate. Persisted fault evidence recorded:

- `status=update_failed_rolled_back`
- `reason=candidate_runtime_verification_failed`
- candidate image `ea264b...`
- previous/restored image `e11e3f...`
- exact resolution `27a992...`

A successful rollback therefore did not convert the failed candidate into update success.

## Accepted-candidate restoration and regressions

After rollback readback, the two persistence sentinels retained their original hashes and the container was healthy on exact `e11e3f...`.

The unmodified normal `bash scripts/update.sh` was then run to restore the accepted candidate. It completed with `status=success`, promoted exact image `ea264b...`, and passed health plus `WORKSTATION_RUNTIME_GREEN`.

Post-restoration application checks were GREEN:

- native CE Codex app-server active with `app-server --remote-control`;
- Codex Web GPT `5.0.12`: `Doctor result: ready`;
- Agent Workspace: X11 workspace/viewer ready, no blockers;
- real disposable Agent Workspace start/run/stop returned `M04_T02_RESTORE_WORKSPACE_GREEN` with exit code 0;
- Computer Use readiness GREEN with no blockers and development input available.

## Stable no-change update and cache evidence

Immediately before the no-change cycle, a fresh upstream resolution was generated and canonicalized. It was byte-identical to the active embedded resolution:

- fresh canonical SHA-256: `27a9929c4cb4da99c0c3cd4c4e5807539ad759b5360559a872664162b5ba1fff`
- active embedded SHA-256: `27a9929c4cb4da99c0c3cd4c4e5807539ad759b5360559a872664162b5ba1fff`
- byte comparison: GREEN

A second unmodified normal `scripts/update.sh` then completed successfully with:

- unchanged resolution SHA `27a992...`;
- unchanged candidate tag `candidate-27a9929c4cb4da99`;
- unchanged candidate image ID `ea264b...`;
- 24 BuildKit `CACHED` markers, with the substantive Dockerfile build layers reused;
- final updater evidence `status=success`, with previous image ID equal to the candidate image ID.

This directly demonstrates that elapsed time alone does not invalidate the build path and that a true no-change cycle reuses the frozen-identity cache.

## Final production readback

After the no-change recreate:

- production image: exact `ea264b...`;
- running: true;
- health: healthy;
- both persistence sentinels still matched their original hashes before cleanup;
- native CE remote-control app-server active;
- Codex Web GPT doctor ready;
- Agent Workspace ready with no blockers;
- Computer Use ready with no blockers.

No persistent user data, project data, or secrets were modified by the fault injection beyond the disposable sentinels, and no rollback image was pruned.

## Result

M04-T02 acceptance is **GREEN**. The target host has now proven the real post-promotion rollback path to an exact prior image, preservation of persistent state, restoration and revalidation of the accepted candidate, and deterministic no-change update/cache behavior.
