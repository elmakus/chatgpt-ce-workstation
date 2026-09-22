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


## Independent review

Review subject: `commit:40ad8ee1182304b54f628b588787b8c97002eba4`
Verdict: **RED**

The implementation preserves the production fork route, adds distinct frozen candidate identities, and the focused source tests reported above are consistent with the reviewed source. The review nevertheless found two acceptance-blocking defects.

### R1 — Exact-candidate GitHub Actions workflow is invalid

The reviewed change adds the candidate-image readback Python heredoc to `.github/workflows/candidate-build.yml`, but the heredoc body is emitted at YAML column 1 rather than remaining indented inside the `run: |` scalar. GitHub therefore cannot materialize the workflow job.

Exact external evidence for the reviewed subject:

- workflow run: `35689565827`;
- `head_sha`: `40ad8ee1182304b54f628b588787b8c97002eba4`;
- conclusion: `failure`;
- jobs returned by the run: none.

This means the Card-required CI/exact-candidate image readback path did not execute on the reviewed subject. The separately captured Tower APT provenance failures do not waive this defect because they exercise a different execution surface and do not prove the checked-in GitHub workflow is runnable.

Required bounded correction: fix the workflow block structure, validate the workflow on the corrected exact subject, and retain the existing fail-closed candidate readback checks.

### R2 — New frozen candidate identity validation is not fail-closed enough

The Card requires missing/unknown/**malformed** candidate identity fields to be rejected before build inputs are accepted. On the reviewed subject:

- `codex_web_gpt_upstream.package_sha256` is only read as non-empty text by `render-build-env.py`; it is not validated as 64 lowercase hex there;
- `opencodex.integrity` is accepted solely by a `sha512-` prefix check;
- the canonical `identity` strings for both new components are not cross-checked against their version + checksum/integrity fields.

Consequently a frozen manifest can carry an inconsistent/malformed candidate identity and still pass the render stage, contrary to the Card acceptance language. The installer may fail later for some malformed values, but that is not equivalent to rejecting malformed frozen build inputs at the manifest/render boundary.

Required bounded correction: add strict format/consistency validation for the new candidate fields in the renderer and deterministic negative tests covering malformed/mismatched identities.

### Review classification

Both defects are bounded L1/L2 implementation corrections inside the already accepted OPH-R1 / OPH-PLAN-R2 authority. No Definition or strategic-plan change is required.


## Corrected subject after RED review

Corrected implementation subject: `d93f5d7f7b1e6773c83c86a447a271e7ccbb1382`

The bounded R1/R2 corrections stay within the accepted OPH-R1 / OPH-PLAN-R2 authority:

- the candidate-build readback heredoc is structurally inside the GitHub Actions `run: |` block;
- OpenCodex npm SHA-512 SRI is validated as strict base64 encoding of exactly 64 digest bytes;
- upstream browser proof SHA-256 is validated as exactly 64 lowercase hex characters;
- upstream asset/identity and OpenCodex identity are cross-checked against their frozen version + checksum/integrity values;
- deterministic negative tests cover malformed and mismatched candidate identities.

The existing production `elmakus/codex-chatgpt-web` install/launcher remains the production path. The corrected subject does not start OpenCodex, run `ocx init`, mutate `~/.codex`, alter provider routing/catalog state, or start the upstream proof runtime.

### Corrected-subject source and workflow validation

Executed on Tower from a fresh clone reset to exact subject `d93f5d7f7b1e6773c83c86a447a271e7ccbb1382`:

- `python3 scripts/test-resolve-upstreams.py` — GREEN, 23 tests.
- `python3 scripts/test-render-build-env.py` — GREEN, 15 tests.
- `bash scripts/test-proof-component-installers.sh` — GREEN.
- `bash scripts/validate-source.sh` — `SOURCE_VALIDATION_GREEN`.
- extracted exact `Read back exact candidate provenance` workflow shell block — `WORKFLOW_BLOCK_INDENT_OK`.
- extracted workflow shell body — `bash -n` GREEN as `WORKFLOW_SHELL_OK`.

The previous invalid-workflow symptom does not recur as a malformed push workflow run on the corrected subject. The candidate workflow itself is configured for pull-request / manual dispatch, so the exact runtime proof below was executed directly from the same corrected subject rather than creating an unrelated PR solely to trigger CI.

### Exact corrected-subject candidate build and image readback

A non-production exact-candidate build was executed from exact subject `d93f5d7f7b1e6773c83c86a447a271e7ccbb1382` with a freshly frozen resolver manifest.

Result: **GREEN**.

- image: `chatgpt-ce-workstation-oph-review:candidate-e6a786ec6416f067`
- image ID: `sha256:938f7e3024dce94936912e0a5ac23bdd305523449392a77f40163f99f2a717f4`
- frozen resolution SHA-256: `e6a786ec6416f067fef1818a9f92db5dbff26a49653befaffc0d446b3751ef0b`
- image resolution label matched the frozen resolution SHA-256;
- embedded `/opt/workstation/upstream-resolution.json` byte-matched the frozen input;
- OpenCodex `ocx` was present and its version matched the frozen OpenCodex component;
- `codex-chatgpt-web-upstream` and production `codex-web-gpt` resolved to distinct executables;
- the upstream runtime manifest version matched the frozen upstream component;
- upstream proof `--help` exposed the expected `serve` command.

The build passed the D25 Ubuntu APT identity checks that had failed closed on the earlier reviewed subject. The frozen Ubuntu aggregate identity was `sha256:5634740a319f19b60a53380280fe96608bcf62c90366bfa1da171fefccd6ed15`, including the converged `noble-backports` InRelease SHA-256 `6569ef03ae3d3ae4db73c8c00d1bb290a1e5874e30280d91aa6207d2a8ca745e`.

Candidate proof identities used by the successful build remained:

- OpenCodex: `@bitkyc08/opencodex@2.59.0`, integrity `sha512-Un/aahv/CEgNkevHmLDidlzsJH9HpEjEr7KSMB4BWTW82U9TDUaiN2N13+E7G5/sCV+FclsaLC3QIeXFZ3YH1w==`, shasum `cab35ddd186a8646f08c9d9031f614c2595e9170`;
- upstream browser proof: `miuuyy/codex-chatgpt-web` `5.0.8`, SHA-256 `289c9938fd7e2ba076dfa8c003dda7dfe67f6762a9bab4da508a5dbc17b75abb`;
- existing production fork: `elmakus/codex-chatgpt-web` `5.0.16`, SHA-256 `7a46e032a74d1bd848a8d946f36d4d427ec2a89e6aa047c518a0bd6bea922f30`.

No production Workstation service/container or persistent provider state was modified by this non-production build/readback.

### Review handoff

The corrected implementation remains non-terminal and requires a fresh independent review because the Card's review requirement is RECOMMENDED. The new immutable review subject is `commit:d93f5d7f7b1e6773c83c86a447a271e7ccbb1382`.


## Independent review — corrected subject

Review subject: `commit:d93f5d7f7b1e6773c83c86a447a271e7ccbb1382`
Verdict: **RED**

The corrected source closes the two implementation defects from the prior review. The GitHub Actions candidate readback block is now structurally inside the workflow `run: |` scalar and its extracted shell parses successfully; the frozen OpenCodex/upstream candidate fields are now validated fail-closed for SHA/SRI format and identity/asset consistency, with deterministic negative coverage. The reviewed source also keeps the production fork install/start path distinct and does not introduce provider credentials, route takeover, `ocx init`, candidate auto-start, or catalog mutation.

### R3 — required exact-subject CI/workflow readback evidence is absent

The Card requires the exact-candidate build workflow, CI/check results, and candidate-image provenance/readback produced by that workflow. For the exact reviewed subject `d93f5d7f7b1e6773c83c86a447a271e7ccbb1382`, GitHub Actions reports zero workflow runs for that `head_sha`, and no commit-status checks are present.

The corrected implementation evidence explicitly records that the successful exact-candidate build/readback was executed directly from the subject rather than through `.github/workflows/candidate-build.yml`. That direct non-production build is useful implementation evidence, but it does not satisfy the separate Card requirement for the checked-in workflow itself to execute and produce the candidate provenance/readback. Static YAML/shell validation likewise cannot substitute for that required workflow execution.

Required bounded correction: obtain a real exact-candidate workflow run on an immutable corrected implementation subject, capture its CI/check result plus workflow-produced image provenance/readback, then freeze the resulting exact subject for a fresh independent review. No product-definition or strategic-plan change is required.

### Review classification

This is a bounded execution/evidence correction inside the existing OPH-R1 / OPH-PLAN-R2 authority. No source-design defect beyond the missing required workflow evidence was found in this review.


## Corrected subject after R3 evidence completion

Corrected implementation/evidence subject: `30d42dd73b8b613bb20cbb2617e5ee6c5c97e970`.

The only change since the prior reviewed source subject is durable workflow/review state; implementation source remains the corrected source previously reviewed at `d93f5d7f7b1e6773c83c86a447a271e7ccbb1382`. The required checked-in GitHub Actions workflow was then executed by the operator against this exact branch subject.

### GitHub Actions exact-candidate workflow evidence

Workflow run: `35696273152`
Event: `workflow_dispatch`
Head SHA: `30d42dd73b8b613bb20cbb2617e5ee6c5c97e970`
Conclusion: **success**
Job: `exact-candidate` — **success**

Required workflow steps were GREEN, including:

- checkout of exact head `30d42dd73b8b613bb20cbb2617e5ee6c5c97e970`;
- frozen upstream resolution;
- exact non-production candidate build;
- `Read back exact candidate provenance`.

Workflow-produced candidate evidence:

- image ref: `chatgpt-ce-workstation-ci:candidate-e6a786ec6416f067`;
- image ID: `sha256:f0ae39b39eefae84457a8fec81dc4964d0b390de3d5bf47e5e4ff40f23eb48ed`;
- resolution SHA-256: `e6a786ec6416f067fef1818a9f92db5dbff26a49653befaffc0d446b3751ef0b`;
- image label SHA-256 matched the resolution SHA-256;
- embedded resolution SHA-256 matched the same exact value;
- OpenCodex executable/version readback passed;
- upstream and production browser executables were distinct;
- upstream runtime version matched the frozen manifest;
- upstream proof executable exposed the expected `serve` command.

This closes R3's missing-workflow-evidence condition. The workflow ran entirely on GitHub-hosted CI and did not mutate the production Workstation container, provider routing, persistent `/home/codex`, browser profile, OAuth state, or the currently running OpenCodex instance.

### Review handoff

The Card remains non-terminal because independent review is RECOMMENDED. The next immutable review subject is `commit:30d42dd73b8b613bb20cbb2617e5ee6c5c97e970`.


## Independent review — exact workflow-evidence subject

Review subject: `commit:30d42dd73b8b613bb20cbb2617e5ee6c5c97e970`
Verdict: **RED**

The exact-candidate defect recorded as R3 is closed. Independent readback of GitHub Actions run `35696273152` confirms `workflow_dispatch` on exact `head_sha=30d42dd73b8b613bb20cbb2617e5ee6c5c97e970`, a GREEN `exact-candidate` job, exact-subject checkout, successful candidate build, and successful provenance/readback. The job logs confirm matching resolution/image-label/embedded SHA-256 `e6a786ec6416f067fef1818a9f92db5dbff26a49653befaffc0d446b3751ef0b`, a version-matching `ocx`, and distinct upstream-proof versus production browser executables.

The reviewed implementation source is unchanged from the prior corrected source subject `d93f5d7f7b1e6773c83c86a447a271e7ccbb1382`; the intervening changes through the reviewed subject affect only durable Task Board/evidence state. Independent source inspection confirms strict fail-closed OpenCodex SRI/shasum and upstream proof SHA/identity/asset validation, isolated candidate install paths, no candidate auto-start, no `ocx init`, no provider route/catalog takeover, and no production fork replacement in this Card.

### R4 — required CI source/static/secret checks have no workflow evidence

The Card's required checks explicitly include `CI source validation / Dockerfile static check / secret scan`. The repository-owned `.github/workflows/ci.yml` defines those as the `source-validation`, `dockerfile-check`, and `secret-scan` jobs.

GitHub Actions reports only one run for the exact reviewed subject: `35696273152`, the separate `Exact candidate build` workflow. There is no `CI` workflow run for `30d42dd73b8b613bb20cbb2617e5ee6c5c97e970`. There is likewise no workflow run at the source-identical prior corrected subject `d93f5d7f7b1e6773c83c86a447a271e7ccbb1382`. The locally recorded `validate-source.sh` GREEN result is useful source evidence but does not supply the separately required CI Dockerfile-static and repository-history secret-scan results.

Required bounded correction: execute the repository `CI` workflow against an immutable subject whose implementation source is the reviewed corrected source, capture GREEN results for `source-validation`, `dockerfile-check`, and `secret-scan`, then freeze the resulting exact subject for fresh independent review.

### Review classification

R4 is a bounded execution/evidence correction inside the existing OPH-R1 / OPH-PLAN-R2 authority. No Project Definition or strategic-plan change is required, and no additional implementation-source defect was found.
