# M01 cumulative handoff

## Final checkpoint

M01 is complete.

- Related implementation repository: `elmakus/codex-chatgpt-web`
- PR: #2, merged into `main`
- Final merge checkpoint: `85d13359bef65208c286ae34e0a00ddbbd185e63`
- Exact independently reviewed implementation subject: `4eaa9c350a885faa627e3e681a8d8861c9f4ba41`

## Achieved state

The related fork now provides deterministic parallel routing for the workstation integration:

- `chatgpt-web/*` remains on the local ChatGPT Web adapter;
- `muse-*` routes only to the configured CLIProxyAPI / Meta upstream;
- other native models remain on the primary native / Codex-LB upstream;
- missing Muse upstream/key fails closed instead of falling through;
- zstd requests preserve encoded bytes while routing from the already-decoded model identity;
- model discovery imports only Muse rows from the optional CLIProxyAPI catalog and preserves Muse-reported metadata;
- macOS PR packaging uses the existing ad-hoc identity only in the no-credential path, while retaining archive signature verification.

## Acceptance and publication evidence

- Integrated M01 and REQUIRED M01-T05 independent review: `implementation/reviews/dual-native-upstreams-pr2-final-independent-review-2026-09-18.md`.
- PR #2 CI on the reviewed subject completed GREEN across actionlint plus verify/package/smoke on macOS, Ubuntu, and Windows.
- macOS package readback confirmed ad-hoc identity `-` and successful existing archive signature verification.
- GitHub merge readback confirms PR #2 merged successfully as `85d13359bef65208c286ae34e0a00ddbbd185e63`.

## Material boundary

This milestone published the related-fork routing/signing changes. It did not perform a live workstation deployment or mutate Unraid runtime state.

## Next durable starting point

`implementation/TASK_BOARD.yaml` is authoritative. M01 is done and no later approved milestone is currently present there. Any follow-up implementation should begin from a newly accepted milestone/Card and the then-current workflow `main`.
