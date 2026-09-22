# Master Plan — OpenCodex Provider Hub

Plan revision: `OPH-PLAN-R1`
Status: `draft`
Date: `2026-09-22`
Independent plan review: `RECOMMENDED`

## Goal and authority

Execute the approved target defined by:
- `requirements/OPENCODEX_PROVIDER_HUB.md` revision `OPH-R1`;
- `docs/DECISIONS.md#d31--opencodex-is-the-candidate-single-provider-hub-and-catalog-owner`;
- inherited Workstation decisions D2, D3, D4, D8, D10, D11, D14, D15, D16, D25 and D26.

This plan is proof-gated. The operator performs live Workstation checks and reports PASS/FAIL. Repository/static work may proceed without a production route switch, but no replacement path is declared accepted until the exact live gate is GREEN.

## Verified execution baseline

- ChatGPT CE is the desktop host and CE's bundled Codex is the native runtime.
- The Workstation currently installs Codex Web GPT from `elmakus/codex-chatgpt-web`.
- The current installer is fork-specific: it resolves releases from `elmakus/codex-chatgpt-web` by default and requires the fork's packaged Codex-LB key helper.
- Codex Web GPT starts automatically inside the shared desktop/D-Bus session.
- Compose currently exposes `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM`, reflecting the old topology where the browser adapter can own native upstream routing.
- The smart-upstream resolver currently freezes the Codex Web GPT release from `elmakus/codex-chatgpt-web`.
- OpenCodex current main supports Codex config/catalog injection, routed `provider/model` catalog rows, arbitrary OpenAI-compatible providers, ChatGPT/Codex account routing and Meta Muse.
- Upstream `miuuyy/codex-chatgpt-web` exposes `codex-chatgpt-web serve`, but its use as a downstream provider behind OpenCodex is not yet live-proven.
- The independent `work/muse-native-upstream` branch is not a dependency of this workstream and remains untouched until proof evidence can justify its own closure path.

## Inherited invariants

- One component owns Codex-facing route/catalog integration at a time.
- Browser-backed `chatgpt-web/*` traffic remains browser-backed.
- Existing production routes remain recoverable until replacement acceptance is GREEN.
- Credentials/browser state remain outside Git and under persistent user state.
- The final runtime is reproducible from repository-owned image/Compose/source.
- Android Remote/native CE behavior must remain working.
- No live PASS is inferred from static checks.
- Codex-LB and CLIProxyAPI remain available during this migration; removing either is out of scope.

## Milestone OPH-M01 — Reversible provider-hub proof substrate

### Outcome

Repository source can build/install an **experimental, opt-in** OpenCodex proof substrate without taking ownership of the production Codex route by default. The proof can run alongside the current Workstation path and can be removed without changing persistent projects or existing browser login state.

### Requirement ownership

OPH-REQ-001, 003, 004, 008..013, 016..018.

### Planned work packages

1. Add OpenCodex to the Workstation upstream-resolution/build pipeline using the same D25 resolve/freeze/verify discipline as other image-managed upstreams.
2. Install OpenCodex in the image without enabling Codex integration automatically.
3. Add a repository-owned proof configuration mechanism that can define:
   - Codex-LB as an OpenAI/Responses-compatible provider;
   - CLIProxyAPI as an OpenAI-compatible provider;
   - a candidate downstream provider for upstream `miuuyy/codex-chatgpt-web serve`;
   - OpenCodex native Meta Muse for comparison.
4. Keep credentials and browser profile material in persistent user-owned locations, never tracked source.
5. Add isolated port/profile/state choices for the proof so the current Codex Web GPT production route stays intact until the live switch gate.
6. Add static/source validation for:
   - exact upstream identity/checksum;
   - no default route takeover;
   - no new secret material in Git/image;
   - deterministic provider IDs/namespaces;
   - rollback/removal path.
7. Record exact operator commands for starting/stopping the proof services and inspecting health/models without changing CE's production route.

### Acceptance checkpoint

- Source validation is GREEN.
- OpenCodex and upstream Codex Web GPT proof binaries/runtime are present and version-identifiable.
- OpenCodex starts in isolated mode and reports healthy without modifying the production Codex route.
- Provider configuration can be generated/validated without embedded secrets.
- Existing CE + current Codex Web GPT route remains unchanged when the experiment is disabled.

### JIT boundary

Do not freeze the final OpenCodex service manager/layout or the final upstream Codex Web GPT daemon ownership until the isolated runtime proves which process must own browser login/launcher/serve lifecycle.

## Milestone OPH-M02 — Direct provider compatibility proof

### Outcome

Before giving OpenCodex ownership of ChatGPT CE's catalog, each required downstream path is proven against the OpenCodex data plane in isolation.

### Dependencies

OPH-M01 GREEN.

### Requirement ownership

OPH-REQ-002..007, 009, 011, 012, 015, 017.

### Planned work packages

1. Verify OpenCodex catalog discovery/explicit model configuration for Codex-LB.
2. Verify CLIProxyAPI catalog/routing through OpenCodex with at least one configured model.
3. Start **unmodified upstream** `miuuyy/codex-chatgpt-web serve` in the proof profile and determine whether OpenCodex can consume:
   - its model surface;
   - Responses streaming;
   - compaction where advertised;
   - required authentication/headers;
   - browser-backed model IDs without collision.
4. Verify OpenCodex native Meta Muse independently and compare the required Muse capability surface with the retained CLIProxyAPI path.
5. Normalize only OpenCodex/provider configuration where possible. If the upstream browser daemon requires source modification merely to operate behind OpenCodex, record that as a proof failure/blocker rather than immediately recreating our fork.
6. Produce one exact operator-run direct-smoke checklist.

### Operator live gate OPH-LIVE-A

The operator runs the supplied checklist and reports results for:

- `OpenCodex health` — PASS/FAIL.
- `Codex-LB model list + one harmless response` — PASS/FAIL.
- `CLIProxyAPI model list + one harmless response` — PASS/FAIL.
- `upstream chatgpt-web model list + one browser-backed response` — PASS/FAIL.
- `Meta Muse model + one response` — PASS/FAIL.

For each failure, capture the exact command/model/error and relevant bounded log excerpt.

### Acceptance checkpoint

All required provider families needed for the CE picker have at least one proven OpenCodex route, and upstream `codex-chatgpt-web serve` is either GREEN as an unmodified downstream or the workstream is explicitly blocked for compatibility resolution.

No CE route ownership changes occur in this milestone.

## Milestone OPH-M03 — Reversible ChatGPT CE catalog/route takeover

### Outcome

OpenCodex temporarily becomes the single Codex-facing route/catalog owner in a controlled live proof, exposes all required model families in ChatGPT CE, and can be rolled back to the previous known-working route.

### Dependencies

OPH-M02 GREEN.

### Requirement ownership

OPH-REQ-001..016.

### Planned work packages

1. Snapshot/record the existing Codex route/catalog configuration required for deterministic restoration.
2. Use OpenCodex's supported integration/injection path rather than manually maintaining duplicate `openai_base_url` / catalog edits.
3. Sync a curated proof catalog with distinct provider namespaces and truthful capability metadata.
4. Prepare a one-command or tightly bounded rollback sequence before the live switch.
5. Provide the operator an ordered live checklist that starts with picker/catalog evidence and only then exercises model turns.

### Operator live gate OPH-LIVE-B

The operator reports PASS/FAIL for this exact sequence:

1. **CE startup:** ChatGPT CE starts normally after OpenCodex owns the candidate route/catalog.
2. **Picker:** visible rows include at least:
   - one native Codex/Codex-LB model;
   - one CLIProxyAPI model;
   - one `chatgpt-web/*` browser-backed model;
   - one Meta Muse route under the topology being evaluated.
3. **Routing:** one ordinary turn on each row reaches the intended provider; no silent fallback to a different provider is accepted.
4. **Browser Full Harness:** one `chatgpt-web/*` turn invokes a harmless local tool (for example read-only `pwd`/file listing) through its normal Full Harness and returns the tool result.
5. **Compaction:** native and browser-backed long-context/forced-compaction smoke follows the capability actually advertised; unsupported provider compact must fail closed or remain unadvertised rather than route elsewhere.
6. **Subagents:** one bounded subagent smoke confirms the selected compatibility/native protocol and expected provider identity for parent/child.
7. **Android Remote:** open/use the task from Android Remote and complete one harmless prompt/tool interaction.
8. **Restart persistence:** restart the relevant proof services (and CE if needed) and verify the expected catalog/provider config survives from persistent state.
9. **Rollback:** disable/remove OpenCodex Codex integration and verify the previous known-working CE/Codex Web GPT route returns without loss of ChatGPT login, browser profile or projects.

### Failure rule

Any FAIL stops migration. Preserve the current production path and route the exact failing surface to correction/research. Do not compensate by deleting the failing provider, silently changing the tested model family, or modifying upstream browser code unless accepted authority is explicitly updated.

### Acceptance checkpoint

OPH-LIVE-B is fully GREEN and exact evidence is durable enough to identify the tested versions/configuration.

## Milestone OPH-M04 — Production source migration

### Outcome

The repository's normal Workstation build/runtime uses OpenCodex as the single Codex route/catalog owner and uses unmodified upstream `miuuyy/codex-chatgpt-web` for the browser-backed provider, while retaining Codex-LB and CLIProxyAPI as downstream providers.

### Dependencies

OPH-M03 GREEN.

### Requirement ownership

OPH-REQ-001..018.

### Planned work packages

1. Change the smart-upstream resolver from the fork release to the verified upstream `miuuyy/codex-chatgpt-web` release identity.
2. Generalize/replace the current fork-specific installer assumptions, especially the required packaged Codex-LB key helper.
3. Promote OpenCodex from opt-in proof component to repository-owned runtime component using the lifecycle proven by M01–M03.
4. Remove production dependence on `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM` where provider aggregation is now owned by OpenCodex.
5. Reconcile desktop launchers/supervision so:
   - CE startup remains independent;
   - browser login/launcher remains available from noVNC;
   - the downstream browser daemon lifecycle matches the proven topology;
   - closing/reopening a GUI launcher does not accidentally create a competing Codex route owner.
6. Persist provider configuration templates/defaults without persisting credentials.
7. Extend source/runtime verification for:
   - OpenCodex installation/version;
   - singular route/catalog ownership;
   - expected provider rows;
   - upstream Codex Web GPT package source;
   - absence of obsolete fork-specific helper assumptions;
   - rollback compatibility.
8. Update D11/implementation runbook documentation to reflect the new accepted runtime only after implementation evidence matches the plan.
9. Produce evidence that the new topology covers the intended Muse-native-upstream behavior; hand that evidence to the separate `change-muse-native-upstream` lifecycle. Do not directly mutate or delete that independent workstream from this one.

### Acceptance checkpoint

- Repository source reproduces the exact topology that passed OPH-LIVE-B.
- No fork-only routing feature is required for normal Workstation behavior.
- Current provider credentials/profile data remain outside Git.
- Static/source and candidate-container verification are GREEN.

## Milestone OPH-M05 — Production rebuild/regression acceptance

### Outcome

An exact production candidate built from the migrated repository passes the same user-owned behavioral surface before final integration.

### Dependencies

OPH-M04 GREEN.

### Planned work packages

1. Build the exact candidate through normal D25 update/build tooling.
2. Run repository/static and disposable candidate checks first.
3. Present the operator with the reduced production acceptance checklist derived from OPH-LIVE-B.
4. After explicit live-rebuild authorization, recreate/update the Workstation through the normal guarded path.
5. Record operator-reported results for:
   - CE/noVNC health;
   - picker provider families;
   - one native Codex/Codex-LB turn;
   - one CLIProxyAPI turn;
   - one browser-backed Full Harness turn;
   - one Meta Muse turn;
   - Android Remote;
   - restart persistence;
   - rollback readiness.
6. Only after GREEN may final integration/closure claim the fork is no longer required by the Workstation.

### Explicit live authorization gate

The plan authorizes preparation of source and test instructions, not an unattended production rebuild. The live Workstation recreate/update is a user-controlled gate. The operator performs/authorizes the live action and reports the result.

### Acceptance checkpoint

The exact candidate intended for integration matches the previously proven topology and all required operator-run production smokes are GREEN.

## Requirement coverage

| Requirements | Owner milestone | Execution path |
|---|---|---|
| OPH-REQ-001, 008..013, 016..018 | OPH-M01 | reversible installation/configuration substrate |
| OPH-REQ-002..007, 009, 011, 012, 015, 017 | OPH-M02 | direct provider compatibility + OPH-LIVE-A |
| OPH-REQ-001..016 | OPH-M03 | temporary CE route/catalog takeover + OPH-LIVE-B |
| OPH-REQ-001..018 | OPH-M04 | repository production migration |
| OPH-REQ-001..018 | OPH-M05 | exact production candidate + operator live regression |

## Verification strategy

Three evidence layers are deliberately separate:

1. **Repository/static:** resolver identities, installers, configs, validation tests, secret hygiene, singular ownership rules.
2. **Disposable/candidate runtime:** process health, generated catalog/config shape, direct provider HTTP/Responses behavior and rollback mechanics.
3. **Operator live Workstation:** CE picker, browser-backed Full Harness, compact/subagents, Android Remote, restart persistence and production rollback.

A lower layer cannot substitute for a required higher-layer PASS.

## Provider/model identity strategy

Use explicit stable provider namespaces during proof. Avoid relying on bare model-name auto-matching when two providers can publish the same model family.

The exact visible labels may be refined during Execution Prep, but the catalog must make intended ownership obvious enough that the operator can confirm routing during live smoke.

## Security / data-integrity strategy

- Do not commit API keys, ChatGPT/OAuth credentials, browser state or OpenCodex account data.
- Keep proof and production state under persistent `/home/codex` with owner-appropriate permissions.
- Never forward CE's incoming ChatGPT bearer to an unrelated custom upstream merely because it is OpenAI-compatible.
- Snapshot/reversibly journal route/catalog state before first takeover.
- Do not delete existing browser profile/state during rollback.
- Fail closed on ambiguous provider routing/capability advertisement.

## Migration / rollback strategy

Migration is staged:

```text
current production
  -> isolated OpenCodex proof
  -> direct provider smoke
  -> temporary CE takeover
  -> rollback proof
  -> repository migration
  -> exact production candidate
  -> production live acceptance
```

At every pre-production stage, disabling the experiment returns to the prior route. The fork remains available until the exact production candidate passes the final gate.

## Concurrent workstream strategy

`work/muse-native-upstream` remains an independent lane. This plan may produce evidence that makes it redundant, but it does not merge, rewrite or delete that workstream. After OpenCodex production acceptance, its own router/closure path can consume the evidence and decide whether it should be superseded or closed.

## JIT decomposition triggers

Execution Prep should defer exact details until predecessor evidence exists for:

- OpenCodex service/supervision form inside this container;
- upstream Codex Web GPT daemon launch/profile flags behind OpenCodex;
- exact auth/header requirements between OpenCodex and the browser daemon;
- capability metadata adjustments required by real compact/subagent behavior;
- final provider display names/allowlists;
- whether OpenCodex native Meta Muse fully replaces only the Muse portion of CLIProxyAPI.

These are technical choices inside the approved definition unless evidence changes the required product behavior.

## Planning audit

Result: `GREEN`.

- Definition coverage is complete.
- The plan does not assume the central unknown (`codex-chatgpt-web serve` behind OpenCodex) is already solved.
- Production mutation occurs only after two earlier reversible proof layers.
- User ownership of live tests is explicit and appears at each live boundary.
- Existing Codex-LB/CLIProxyAPI services are preserved rather than prematurely removed.
- The custom fork is retired only after behavioral equivalence is proven.
- The active Muse-native-upstream workstream remains isolated.
- Rollback is tested before source migration.
- Android Remote, Full Harness, compact and subagent behavior are included rather than relying on a simple text-response smoke.
- YAGNI: no new provider/router abstraction is planned inside the Workstation or browser adapter; OpenCodex owns that responsibility.
- No unresolved Definition-owned product choice is hidden in implementation.
- Independent plan review is `RECOMMENDED` because this is a material architecture migration with live rollback consequences and independent review is practical.
