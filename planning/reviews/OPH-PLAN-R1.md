# Independent Plan Review — OpenCodex Provider Hub

Plan revision: OPH-PLAN-R1
Review requirement: RECOMMENDED
Review state: red
Review subject: planning/OPENCODEX_PROVIDER_HUB_PLAN.md blob cdd7eec64d2578d919a88b8a421d7284890b8682 (frozen at commit 12fffddb8bb9c73ffa65f576bb87d328cd89e2b0)
Review evidence: RED — two bounded plan-only gaps against approved OPH-R1; architecture direction otherwise coherent.

## Review authority

- Workstream manifest: `implementation/workstreams/change-opencodex-provider-hub/WORKSTREAM.yaml`
- Requirements: `requirements/OPENCODEX_PROVIDER_HUB.md` revision `OPH-R1`
- Decision: `docs/DECISIONS.md#d31--opencodex-is-the-candidate-single-provider-hub-and-catalog-owner`
- Reviewed plan: `planning/OPENCODEX_PROVIDER_HUB_PLAN.md`

## Verdict evidence

### RED-1 — source migration is authorized before the required recreate persistence proof

Approved Definition acceptance item 8 requires restart/recreate persistence of OpenCodex/provider configuration and credentials, and item 10 allows source migration away from the custom `codex-chatgpt-web` fork only after the relevant preceding checks are GREEN. OPH-REQ-006 likewise permits fork retirement only after all required browser-backed acceptance checks pass.

The reviewed plan's OPH-LIVE-B step 8 verifies only restart of relevant proof services (and CE if needed). OPH-M04 then immediately changes the smart-upstream resolver from `elmakus/codex-chatgpt-web` to upstream `miuuyy/codex-chatgpt-web`, before any container/image recreate persistence test occurs. The first explicit recreate/update is deferred to OPH-M05, after that source migration.

Correction required: add a reversible pre-M04 recreate persistence gate using the proof-capable image/topology while the fork remains the recoverable production source, or otherwise restructure the sequence so source migration away from the fork cannot begin until restart **and recreate** persistence are operator-GREEN.

### RED-2 — direct Meta Muse replacement lacks an explicit live equivalence gate

OPH-REQ-007 permits OpenCodex native Meta Muse to replace the CLIProxyAPI Muse route only after live acceptance proves the required Muse model, effort/tool behavior and session path are equivalent enough for this Workstation.

The plan says OPH-M02 will compare the required Muse capability surface, but OPH-LIVE-A requires only “Meta Muse model + one response”; OPH-LIVE-B requires one ordinary turn per row plus generic compact/subagent checks; OPH-M05 requires one Meta Muse turn. None of the operator-owned gates explicitly requires the Muse-specific effort, harmless tool behavior, and session-path evidence before native Meta Muse may be selected as the replacement.

Correction required: make the replacement conditional explicit. If native OpenCodex Meta Muse is selected instead of the retained CLIProxyAPI Muse route, require operator-GREEN evidence for the accepted Muse model, intended effort behavior, a harmless tool path, and the required session-path behavior before declaring equivalence. Otherwise keep Muse through CLIProxyAPI and do not claim native replacement.

## Passing review findings

- The plan does not assume upstream `miuuyy/codex-chatgpt-web serve` compatibility; M02 explicitly proves it and treats source modification as a blocker rather than silently recreating the fork.
- OpenCodex is the sole candidate Codex-facing route/catalog owner during takeover; the isolated proof substrate does not take production ownership by default.
- Codex-LB and CLIProxyAPI remain available during evaluation and are not prematurely decommissioned.
- Picker routing, browser Full Harness, compaction, subagents, Android Remote, rollback, secret hygiene and provider identity all have explicit planned checks.
- The independent `change-muse-native-upstream` workstream is kept separate and is not directly mutated or deleted.
- The plan avoids adding a second provider/router abstraction inside Workstation or the browser adapter.
- Credential and browser-profile state remain outside Git with rollback designed to preserve login/profile/project state.

## Review focus

Independently verify at minimum:

- that the plan does not assume upstream `miuuyy/codex-chatgpt-web serve` compatibility before proof;
- that OpenCodex route/catalog ownership is singular and reversible;
- that Codex-LB and CLIProxyAPI remain available during evaluation rather than being prematurely removed;
- that operator-run live gates are sufficient to prove picker routing, browser Full Harness, compaction, subagents, Android Remote, persistence and rollback;
- that source migration occurs only after the reversible live proof is GREEN;
- that the independent `change-muse-native-upstream` workstream is not mutated or silently superseded;
- that requirements are completely covered without unnecessary provider/router machinery in the Workstation or browser adapter;
- that credential, browser-profile and rollback boundaries are safe.
