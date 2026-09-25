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

## Independent review attempt 1 — RED

Reviewed immutable subject: `commit:414877d910b1a02d7b603d38e2979d6bb7337faf`.

The frozen OpenCodex 2.59.0 `meta-muse` registry contract, exact-subject CI run `35709835674`, and exact-subject candidate run `35709835663` independently match the implementation evidence. Provider ids, secret-free schema shape, disabled native injection/steering, production-home fencing, and exact installed `ocx config validate` behavior are consistent with the Card.

Acceptance-blocking findings:

1. The Card explicitly requires focused negative coverage for malformed URLs and missing required endpoint inputs. `scripts/test-opencodex-proof-config.sh` covers secret-bearing input, private-endpoint opt-in, unsupported adapters, and path fencing, but contains no malformed-URL case and no missing-`baseUrl`/endpoint case. The implementation has fail-closed code paths for these inputs, but the required regression evidence is absent.
2. `atomic_write_json()` unconditionally runs `path.parent.chmod(0o700)` after `mkdir(..., exist_ok=True)`. For a caller-selected pre-existing `--disposable` directory, rendering therefore mutates that directory's permissions even though the Card authorizes writing the proof artifact there, not retagging unrelated parent-directory access. This is an unnecessary side effect on the disposable-output surface and is not covered by a regression test.

Classification: bounded L1/L2 correction inside accepted OPH-R1 / OPH-PLAN-R2 authority. No product, planning, research, credential, live-provider, or user-authorization decision is required.

## Bounded correction after review attempt 1

Corrected immutable implementation subject: `commit:33023b6915b1fe80b2e1efa828af3fd2f90348ec`.

The RED findings were corrected without expanding Card authority:

- `atomic_write_json()` now changes parent-directory mode to `0700` only when that final parent did not already exist; a pre-existing caller-selected `--disposable` parent keeps its existing permissions.
- focused negative coverage now rejects a non-http(s) provider URL and a provider row missing required `baseUrl`;
- a regression case renders into a pre-existing mode-`0755` disposable parent and verifies the parent remains `0755`.

Exact corrected-subject verification:

- GitHub CI run `35713048312` — GREEN on `33023b6915b1fe80b2e1efa828af3fd2f90348ec`;
  - `source-validation` — GREEN, including the corrected proof-config test;
  - `dockerfile-check` — GREEN;
  - `secret-scan` — GREEN.
- GitHub Exact candidate build run `35713048323` — GREEN on the same subject;
  - frozen upstream resolution SHA-256: `2ef0f0e719fc02e034d49416d704dbdfaeccaf5c101a2130377e1a682c60068a`;
  - image: `chatgpt-ce-workstation-ci:candidate-2ef0f0e719fc02e0`;
  - image ID: `sha256:ea072166f8c4b5ea54e18cdf8b96a7103a900c4a91f675401e791de0460d04b7`;
  - provenance readback — GREEN;
  - exact installed frozen OpenCodex proof validation — `OPENCODEX_PROOF_CONFIG_RUNTIME_GREEN`.

No production route/catalog ownership, credential handling, live provider traffic, login flow, startup wiring, or independent Muse workstream behavior changed in the correction.

A new independent review is required for this corrected subject. Review attempt 1 remains preserved above as RED evidence for the superseded subject.

## Independent review attempt 2 — GREEN

Reviewed immutable subject: `commit:33023b6915b1fe80b2e1efa828af3fd2f90348ec`.

Verdict: **GREEN**. No acceptance-blocking finding remains on the corrected subject.

Independent readback verified the Card contract and its OPH-R1 / OPH-PLAN-R2 authority slice against the actual immutable source rather than relying on the implementing-session narrative. The corrected subject preserves the stable provider ids `codex-lb`, `cliproxyapi`, `chatgpt-web`, and `meta-muse`; keeps native Codex injection/steering disabled; fences normal `~/.opencodex` and `~/.codex`; requires explicit private-network intent for literal local/private endpoints; rejects secret-shaped provider input; and invokes only the bounded `ocx config validate <path> --json` path under the isolated T02 state roots.

The two attempt-1 defects are closed on the reviewed subject: the renderer no longer changes mode on a pre-existing disposable parent, and focused negative coverage now exercises both a non-http(s) endpoint and a missing required `baseUrl`. The permission regression is also covered explicitly.

Exact-subject external evidence was independently read back:

- CI run `35713048312` has `head_sha=33023b6915b1fe80b2e1efa828af3fd2f90348ec` and is GREEN for source validation, Dockerfile checks, ShellCheck, and repository secret scan.
- Exact candidate build run `35713048323` has the same `head_sha`, is GREEN, proves matching frozen-candidate provenance `2ef0f0e719fc02e034d49416d704dbdfaeccaf5c101a2130377e1a682c60068a`, and records `OPENCODEX_PROOF_CONFIG_RUNTIME_GREEN` from the image-owned installed OpenCodex.
- Frozen upstream tag `lidge-jun/opencodex@v2.59.0` resolves to `134c92a01b120162f00c7275189cc47858720379`. Its registry/model seeds independently match the proof row's `meta-muse` adapter/base URL/OAuth identity, `x-api-version: 1.0.0`, two Muse Spark 1.3 model ids, 1,048,576-token context window, text+image modality, and `minimal|low|medium|high|xhigh` identity reasoning ladder. The upstream warning also confirms that subscription/device-login semantics remain unsupported/unverified and therefore outside this Card's GREEN claim.

This verdict covers deterministic secret-free configuration/schema validation only. It does not claim live provider compatibility, credential reuse, billing/subscription behavior, browser-daemon compatibility, picker takeover, or production-route migration; those remain later proof/live-acceptance obligations.
