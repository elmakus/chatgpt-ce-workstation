# OPH-M02-T01 implementation evidence

Card: `OPH-M02-T01 — Add isolated OpenCodex data-plane probe`  
Implementation subject: `commit:e6602ed132ecdb9d15ab7839339015206e3eb598`  
Workstream PR: `#23`

## Result

The implementation adds an opt-in image-owned helper at `/usr/local/bin/workstation-opencodex-live-a` for the isolated OpenCodex proof data plane.

Supported bounded operations are:

- `health` — loopback `/healthz`;
- `models` — normalized IDs from loopback `/v1/models`;
- `model <provider/model-id>` — exact model-presence check;
- `response <provider/model-id>` — exactly one non-streaming `/v1/responses` request using the fixed harmless prompt `Reply with exactly: OPH-LIVE-A OK`.

The helper accepts only the existing `OPENCODEX_PROOF_PORT`, constructs its base URL as `http://127.0.0.1:<port>`, accepts no credential/header input, does not run `ocx` lifecycle or route-takeover commands, and is not wired into normal desktop startup.

Focused source tests replace curl with a fake local executable. Therefore CI/candidate validation of this Card performs no provider login, provider request, browser request, Meta Muse request, or other live inference.

## Exact implementation surface

Compared with the pre-implementation OPH-M02-T01 execution state, the subject changes only:

- `.github/workflows/candidate-build.yml`
- `.github/workflows/ci.yml`
- `Dockerfile`
- `rootfs/usr/local/bin/workstation-opencodex-live-a`
- `scripts/candidate-opencodex-live-a-smoke.sh`
- `scripts/test-opencodex-live-a.sh`
- `scripts/validate-source.sh`

No ChatGPT CE route/catalog configuration, normal startup path, provider credential material, browser profile, or production provider service is changed.

## Focused/source evidence

Exact CI run `35717632054` is GREEN on `e6602ed132ecdb9d15ab7839339015206e3eb598`.

Relevant readback:

- source-validation: GREEN;
- `OK: isolated OpenCodex OPH-LIVE-A probe contract`;
- `SOURCE_VALIDATION_GREEN`;
- Dockerfile check: GREEN;
- ShellCheck in the source-validation job: GREEN;
- repository secret scan: GREEN.

The focused fake-transport coverage verifies deterministic catalog ordering, exact-model success and missing-model failure, rejection of bare/whitespace model ids, fixed harmless Responses payload construction, malformed-response failure, invalid-port/extra-argument failure, local-only endpoints, absence of credential-bearing interface terms, and absence of route-takeover/lifecycle mutation commands.

An earlier source run exposed that a newly created repository helper is not executable before image packaging; the test was corrected to execute the source helper via Bash while retaining the candidate-image executable-bit assertion. The corrected exact subject above is the only review subject.

## Exact candidate-image evidence

Exact candidate build run `35717632009` is GREEN on the same implementation subject.

Candidate provenance readback:

- image: `chatgpt-ce-workstation-ci:candidate-2ef0f0e719fc02e0`;
- image id: `sha256:9b47e9c52f514512871d85a979f7a3293237a0b74330cc356b09908a78ca8830`;
- frozen resolution SHA-256: `2ef0f0e719fc02e034d49416d704dbdfaeccaf5c101a2130377e1a682c60068a`;
- image label SHA-256: same frozen resolution;
- embedded resolution SHA-256: same frozen resolution.

Runtime smoke readback:

- `OPENCODEX_PROOF_CONFIG_RUNTIME_GREEN`;
- `OK: isolated OpenCodex OPH-LIVE-A probe contract`;
- `OPENCODEX_LIVE_A_RUNTIME_GREEN`.

The candidate smoke explicitly requires `/usr/local/bin/workstation-opencodex-live-a` to be executable inside the built image before running the same fake-transport contract test against the installed helper.

## Boundary

This evidence proves only the reusable local probe and its image packaging. It does not claim that Codex-LB, CLIProxyAPI, upstream ChatGPT Web, or Meta Muse has passed OPH-LIVE-A. No live provider call was performed by this Card.

Those provider-specific observations remain operator-owned live-gate evidence for later OPH-M02 JIT work.
