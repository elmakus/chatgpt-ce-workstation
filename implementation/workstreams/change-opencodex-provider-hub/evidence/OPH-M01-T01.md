# OPH-M01-T01 implementation evidence

Card: `OPH-M01-T01 — Add frozen OpenCodex and upstream browser proof binaries`
Implementation subject: `40ad8ee1182304b54f628b588787b8c97002eba4`
Branch: `work/opencodex-provider-hub`

## Result

Implementation is ready for independent review.

The exact subject adds frozen supply-chain identities and isolated image-owned proof binaries for:

- OpenCodex package `@bitkyc08/opencodex`;
- unmodified upstream `miuuyy/codex-chatgpt-web`;

while retaining the existing `elmakus/codex-chatgpt-web` production install and desktop auto-start path unchanged.

No production Workstation container, Codex route/catalog, persistent `/home/codex`, browser profile, OAuth state, provider credential, or live service was mutated during this Card.

## Deterministic source evidence

Executed on Tower from a fresh temporary clone of exact subject `40ad8ee1182304b54f628b588787b8c97002eba4`:

- `python3 scripts/test-resolve-upstreams.py` — GREEN, 22 tests.
- `python3 scripts/test-render-build-env.py` — GREEN, 10 tests.
- `bash scripts/test-proof-component-installers.sh` — GREEN.
- `bash scripts/validate-source.sh` — `SOURCE_VALIDATION_GREEN`.

The negative fixture paths intentionally emit failure text before their surrounding harness proves fail-closed behavior; their test suites completed GREEN.

## Fresh resolved identities

A fresh resolver run on the exact subject resolved:

### OpenCodex

- package: `@bitkyc08/opencodex`
- version: `2.59.0`
- provenance: `npm-registry`
- integrity: `sha512-Un/aahv/CEgNkevHmLDidlzsJH9HpEjEr7KSMB4BWTW82U9TDUaiN2N13+E7G5/sCV+FclsaLC3QIeXFZ3YH1w==`
- shasum: `cab35ddd186a8646f08c9d9031f614c2595e9170`

### Upstream browser proof runtime

- repository: `miuuyy/codex-chatgpt-web`
- version: `5.0.8`
- asset: `codex-web-gpt-5.0.8-linux-x64.AppImage`
- SHA-256: `289c9938fd7e2ba076dfa8c003dda7dfe67f6762a9bab4da508a5dbc17b75abb`

### Existing production fork remains distinct

- repository: `elmakus/codex-chatgpt-web`
- version: `5.0.16`
- asset: `codex-web-gpt-5.0.16-linux-x64.AppImage`
- SHA-256: `7a46e032a74d1bd848a8d946f36d4d427ec2a89e6aa047c518a0bd6bea922f30`

## Exact-candidate build/readback

Two non-production exact-candidate build attempts were made from fresh temporary clones with `IMAGE_NAME=chatgpt-ce-workstation-oph`. Neither altered the running production Workstation.

Both builds failed **before the new OpenCodex/upstream proof component installation/readback steps** because the existing D25 Ubuntu APT signed-InRelease identity gate detected mirror/CDN index movement.

### Attempt 1

The build progressed through the existing CE package build and then, after a later `apt-get update`, the D25 assertion rejected:

- frozen `noble-backports InRelease`: `c265e3c189f751178678e9add9818c67ef86d7fb75bd416ff641659e25ebdcb7`
- observed: `6569ef03ae3d3ae4db73c8c00d1bb290a1e5874e30280d91aa6207d2a8ca745e`

Failure location: existing `/usr/local/lib/workstation/assert-ubuntu-apt-identity.sh` invoked by the pre-existing CE install path around Dockerfile lines 213–240.

### Attempt 2

An immediate resolve-and-retry again failed closed, this time at the initial base APT phase around Dockerfile lines 60–149, with the same backports transition:

- frozen: `c265e3c189f751178678e9add9818c67ef86d7fb75bd416ff641659e25ebdcb7`
- observed: `6569ef03ae3d3ae4db73c8c00d1bb290a1e5874e30280d91aa6207d2a8ca745e`

A subsequent fresh resolver call, after mirror/CDN propagation converged, resolved the current backports identity as `6569ef03ae3d3ae4db73c8c00d1bb290a1e5874e30280d91aa6207d2a8ca745e`, confirming that the gate was rejecting moving external APT metadata rather than silently accepting drift.

Current fresh Ubuntu APT resolution from that later call:

- aggregate identity: `sha256:5634740a319f19b60a53380280fe96608bcf62c90366bfa1da171fefccd6ed15`
- `noble-backports`: `6569ef03ae3d3ae4db73c8c00d1bb290a1e5874e30280d91aa6207d2a8ca745e`
- `noble-updates`: `6d891f63e9f95675e772ebcc7cc98ac90de252c1fd3b51b98052a921605b0609`
- `noble`: `cdb2f31d809f589719a53c6ad15f255b27569c4059542ada282aaa21b8e164b0`
- `noble-security`: `d12ea18bd49adb821cac70c8fe2e5aafb1ff5755b0138d9c1e1ba5080c7bea47`

## Acceptance disposition

- Frozen candidate identities: GREEN.
- Fork/upstream separation: GREEN in source/tests.
- Build-input fail-closed validation: GREEN.
- No candidate auto-start / no route takeover in this Card: GREEN in source validation.
- Exact-candidate image readback: **not reached** because the pre-existing D25 APT provenance gate failed closed on moving Ubuntu metadata.
- The concrete build failure is durably captured here as required by the Card acceptance contract; it is not waived or reclassified as GREEN.

Independent review should judge the exact implementation subject and this evidence, including whether the captured fail-closed candidate-build result is sufficient under the Card contract or whether a later rerun/follow-up is required before the Card can be finalized.
