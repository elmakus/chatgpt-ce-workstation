# M01-T13 Muse activation blocker

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T13`
State: **BLOCKED; production rolled back**

## Baseline and activation readback

- Starting image and post-activation image were identical: `sha256:7470b64402282c56300ea6225c9d316c475b441878d38d68ff7862b5ff30248f`.
- Embedded frozen `codex_web_gpt` remained `5.0.15@sha256:bdad25547ae79f29ee27a029bed5ec6c7762f98a92e7578762de40a113b9b49d`, `override: false`.
- Native upstream remained `http://192.168.2.104:2455/backend-api/codex`.
- Persistent Muse key remained mode `0600`, uid/gid `99:100`, readable by the runtime user; its content was not emitted.
- Direct authenticated CLIProxyAPI `GET /v1/models` returned HTTP 200 / OpenAI-compatible list with five public Muse IDs: `muse-spark-1.1`, `muse-spark-1.2`, `muse-spark-1.2-contributor`, `muse-spark-1.3`, `muse-spark-1.3-contributor`, plus twelve non-Muse rows.
- With Muse enabled, Codex catalog discovery exposed those five `muse-*` IDs plus ordinary `gpt-5.6-sol` and `chatgpt-web/{light,medium,high}`; none of the CLIProxyAPI non-Muse `claude-*`, `gemini-*`, or `gpt-oss-120b-medium` rows were imported.
- Ordinary native `gpt-5.6-sol` smoke succeeded with `NATIVE_SMOKE_OK`.

## Blocking acceptance failure

A normal Codex client turn using `muse-spark-1.3` with the real client tool surface reached the Muse route but failed before model completion. CLIProxyAPI returned an OpenAI-compatible `invalid_request_error`:

`tools[].search_content_types is only supported for web_search_preview tools.`

This is a different normal-client compatibility failure than the reviewed Gmail recursive-schema issue. M01-T13 explicitly excludes additional provider/tool compatibility exceptions, so changing request rewriting inside this Card would exceed its bounded authority.

## Rollback

Per the approved R7 rollback contract:

- `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` was reset to empty in local untracked `.env`.
- Workstation was recreated with `--no-build` from the same exact candidate tag/frozen resolution.
- Running image readback remained exactly `sha256:7470b64402282c56300ea6225c9d316c475b441878d38d68ff7862b5ff30248f`.
- Health returned `healthy`.
- Native upstream readback remained unchanged.
- Runtime Muse endpoint readback is empty.
- `codex-chatgpt-web route status` is active with `errors: []`.

The Codex local model cache still contains Muse rows learned during the activation attempt; this is being treated as cache state rather than proof that the Muse route remains enabled because runtime env/readback is unset. R2 will determine whether any cache-specific reconciliation is required for rollback acceptance.

No secret value was committed or persisted in evidence.
