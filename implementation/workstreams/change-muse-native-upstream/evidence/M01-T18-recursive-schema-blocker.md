# M01-T18 — Muse recursive-schema blocker

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T18`
State: **BLOCKED; rollback required but target host currently offline**

## Confirmed user-visible failure

A real Codex Desktop conversation using `Muse Spark 1.3 Contributor` failed with the provider error:

`Recursive JSON schemas are not currently supported`

Structured error fields shown by the client:
- `code: null`
- `type: invalid_request_error`
- `param: parameters`

This is direct evidence that at least one tool/function `parameters` JSON Schema emitted by the normal Codex Desktop tool surface contains a recursive structure that the current Muse provider rejects.

## Related live execution evidence

During M01-T18 activation on the exact D25-promoted Workstation image:
- Muse endpoint activation itself was healthy.
- Workstation remained on exact image `sha256:9ede8f1f522a710707acac32d01fd8c4d7671b91912791e299d1c635d964b893`.
- Native upstream stayed unchanged.
- Workstation catalog contained the five Muse rows and excluded CLIProxyAPI non-Muse rows.
- Ordinary native `gpt-5.6-sol` completed normally.
- R3 proved the initial HTTP 426 is the expected Codex WebSocket-to-HTTP fallback signal, not a blocker.
- A direct app-server thread was successfully started with explicit model `muse-spark-1.3`.
- The corresponding CLIProxyAPI `POST /v1/responses` returned HTTP 200, but the manual app-server probe did not reach `turn/completed` within 90 seconds. That timeout is not treated as the primary root-cause evidence now that Codex Desktop surfaced the exact recursive-schema provider error above.

## Rollback obligation

The M01-T18 contract requires rollback to Muse-disabled baseline on any genuine integrated acceptance failure.

The target Tower host became unavailable before the rollback command could be executed. Current remote-device state is `offline`.

Therefore:
- do **not** claim Muse-disabled baseline has been restored;
- the next legal target-host action is to set `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` back to empty and recreate the same frozen image with repository-owned Compose;
- verify health, unchanged native upstream, exact image identity and `WORKSTATION_RUNTIME_GREEN`.

No alternate remote-execution route is authorized to bypass the unavailable host.

## Classification

The recursive-schema failure is a new, independently observed provider/tool compatibility boundary. Existing M01-T18 authority permits only the already-reviewed Gmail omission and `web_search.search_content_types` omission; it does not authorize generic JSON-Schema rewriting.

Research R4 owns exact identification of the recursive schema(s), smallest safe Muse-only normalization, compatibility with Codex Desktop tool semantics, and planning/definition classification.

No credential content was emitted.
