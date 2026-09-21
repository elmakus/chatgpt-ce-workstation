# M01-T02 live activation blocker — CLIProxyAPI catalog contract

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T02`

## Production preflight

- Running Workstation image before activation: `sha256:9a6be62fdab865a9dce65412933acd21d1a944e4c250172ddb8e0afdbceb5248`.
- Installed fork artifact: `/opt/codex-web-gpt/5.0.13/Codex Web GPT.AppImage`.
- Workstation health before activation: healthy.
- Existing native upstream remained `http://192.168.2.104:2455/backend-api/codex`.
- No Muse upstream was present before activation.
- CLIProxyAPI authenticated `GET /v1/models` returned HTTP 200.
- CLIProxyAPI exposed five public Muse IDs:
  - `muse-spark-1.1`
  - `muse-spark-1.2`
  - `muse-spark-1.2-contributor`
  - `muse-spark-1.3`
  - `muse-spark-1.3-contributor`
- The same CLIProxyAPI catalog contained 12 non-Muse rows.
- The CLIProxyAPI response shape was OpenAI-compatible: top-level keys `data, object`; model-row keys `created, id, object, owned_by`.

## Secret-safe credential provisioning

- Exactly one CLIProxyAPI ingress key was present in operator-managed configuration.
- The value was never emitted to validation output or committed.
- It was persisted at the fork-owned Workstation path `~/.config/codex-web-gpt/muse-proxy-api-key`.
- Readback metadata only: owner `99:100`, mode `0600`, file size 49 bytes.
- The persisted credential successfully authenticated the HTTP 200 CLIProxyAPI catalog request.

## Activation attempt

- Production checkout was fast-forwarded to the exact workstream branch state.
- Local, untracked `.env` received only the non-secret endpoint `CODEX_CHATGPT_WEB_MUSE_UPSTREAM=http://192.168.2.104:8317/v1`.
- `bash scripts/validate-source.sh` returned `SOURCE_VALIDATION_GREEN`.
- The first direct `docker compose up --force-recreate --no-build` attempt stopped before container mutation because Compose still requires frozen build-input interpolation even on `--no-build`.
- Recreate was then performed through the same repository Compose definition with the current image's embedded `/opt/workstation/upstream-resolution.json` rendered by `scripts/render-build-env.py`.
- The container recreated on the exact same image ID.
- `scripts/wait-healthy.sh` and `scripts/verify-runtime.sh` returned healthy / `WORKSTATION_RUNTIME_GREEN`.
- Runtime environment readback proved both native and Muse upstream endpoint variables were present and the native value was unchanged.

## Blocking acceptance result

After activation, local `codex-web-gpt` `GET /v1/models` returned HTTP 200 but exposed:
- 12 ordinary native model rows;
- 3 `chatgpt-web/*` rows;
- 0 `muse-*` rows.

The v5.0.13 fork source explains the failure deterministically:
- `modelsRequest()` passes the Muse upstream JSON directly to `mergeMuseNativeModelCatalog()`;
- `mergeMuseNativeModelCatalog()` requires `museCatalog.models`;
- the actual CLIProxyAPI `/v1/models` contract returns its rows under `data` with public identity in `id`.

Therefore v5.0.13 contains the parallel Muse route and configured-upstream proxy-resolution fix, but its live catalog adapter is not compatible with the actual CLIProxyAPI model-list response contract. The optional-catalog failure behavior correctly preserved ordinary native and `chatgpt-web/*` rows, but R4/R6 cannot be accepted because Muse discovery remains empty.

## Rollback/readback

The accepted rollback was applied immediately:
- removed `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` from production `.env`;
- recreated the Workstation on the same frozen image/resolution;
- runtime readback: native upstream unchanged, Muse upstream unset;
- `scripts/verify-runtime.sh` with the current frozen resolution returned `WORKSTATION_RUNTIME_GREEN`;
- local catalog after rollback: HTTP 200, 12 ordinary native rows, 3 `chatgpt-web/*` rows, 0 Muse rows.

The persistent Muse key file remains dormant, which is allowed by the approved rollback contract.

## Routing conclusion

The approved Definition R1-R6 and D29 remain valid: the fork should own provider/catalog adaptation and Workstation should only wire endpoint + persistent credential. The R4 execution strategy is insufficient because it assumed the released fork's model-catalog contract already matched the live CLIProxyAPI response. Strategic replanning is required to add a bounded `codex-chatgpt-web` compatibility correction, independently verify/release it, then update/re-preflight Workstation before reactivating Muse.
