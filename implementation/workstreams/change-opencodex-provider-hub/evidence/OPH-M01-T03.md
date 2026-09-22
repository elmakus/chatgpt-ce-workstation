# OPH-M01-T03 Evidence — isolated secret-free provider proof configuration

Card: `OPH-M01-T03`  
Implementation subject: `commit:414877d910b1a02d7b603d38e2979d6bb7337faf`  
Draft workstream PR: #23

## Source result

The implementation adds a repository-owned `workstation-opencodex-proof-config` helper that deterministically renders a secret-free OpenCodex proof `config.json` for the stable provider ids `codex-lb`, `cliproxyapi`, `chatgpt-web`, and native `meta-muse`.

The helper keeps the current production CE/Codex route untouched, refuses normal `~/.opencodex` and `~/.codex` state roots, requires an explicit private-network opt-in for literal local/private provider destinations, rejects credential-shaped input fields, disables Codex native injection/steering, and validates only through the frozen `ocx config validate <path> --json` command under isolated `OPENCODEX_HOME` and `CODEX_HOME`.

The `meta-muse` proof row matches the frozen OpenCodex 2.59.0 registry contract: `openai-responses`, `https://api.meta.ai/v1`, OAuth auth mode, `x-api-version: 1.0.0`, the two Muse Spark 1.3 model ids, the 1,048,576-token context window, text+image modalities, and the upstream `minimal|low|medium|high|xhigh` reasoning ladder/identity map. This is schema/configuration evidence only; it is not live credential, billing, subscription-coverage, or provider-compatibility evidence.

## Deterministic source validation

On exact implementation subject `414877d910b1a02d7b603d38e2979d6bb7337faf`, GitHub CI run `35709835674` is GREEN:

- `source-validation` — GREEN
  - focused lifecycle contract — GREEN
  - focused isolated provider proof configuration — GREEN
  - `SOURCE_VALIDATION_GREEN`
  - ShellCheck — GREEN
- `dockerfile-check` — GREEN
- `secret-scan` — GREEN

The focused provider-config test covers deterministic byte-identical rendering, stable provider ids, the default provider, disabled native injection/steering, the native `meta-muse` transport/auth/header/model seed, mode `0600`, secret-bearing input rejection, private-endpoint opt-in rejection, unsupported adapter rejection, production-path rejection, disposable-state fencing, and the exact bounded `ocx config validate <path> --json` invocation.

## Exact frozen-candidate validation

GitHub Exact candidate build run `35709835663` is GREEN on the same implementation subject.

- image: `chatgpt-ce-workstation-ci:candidate-2ef0f0e719fc02e0`
- image ID: `sha256:0a4b1fd7b780a021a9d626ad8195ada28e14dba71d3177f672672cb9ae583636`
- frozen upstream resolution SHA-256: `2ef0f0e719fc02e034d49416d704dbdfaeccaf5c101a2130377e1a682c60068a`
- image provenance label and embedded `/opt/workstation/upstream-resolution.json` matched the same resolution SHA
- exact installed frozen OpenCodex validation returned `OPENCODEX_PROOF_CONFIG_RUNTIME_GREEN`

The candidate smoke rendered the proof config into disposable state, invoked the image-owned frozen `ocx config validate`, checked the four expected provider ids and native Meta configuration, and verified that sentinels in the normal disposable user's `~/.codex` and `~/.opencodex` trees were unchanged.

## Bounded correction discovered during execution

An earlier exact-candidate run (`35706614050`) failed at the new validation step even though the configuration contract itself matched the frozen upstream. The smoke harness was checking structured `--json` output with a whitespace-sensitive literal `grep` for `"ok":true`, while OpenCodex's frozen `printData` implementation pretty-prints JSON as `"ok": true`.

The correction on the reviewed implementation subject parses the validation output as JSON and requires `ok is true` instead of depending on formatting. A diagnostic-only intermediate commit was superseded. Final CI and exact-candidate validation above are both GREEN.

## Boundary readback

- no provider credentials, OAuth/browser state, API keys, generated tokens, or secret placeholders were added
- no live provider request, OAuth login, browser login, daemon start, service install, shim install, `ocx init`, or `ocx sync` was performed by this Card
- normal workstation startup and the current production CE/Codex route/catalog remain unchanged
- `chatgpt-web` remains an explicitly configured browser-backed downstream route; this Card does not claim it is live
- the independent Muse workstream is untouched
- live provider compatibility and operator acceptance remain later workflow obligations

