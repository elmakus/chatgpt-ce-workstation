# Independent Plan Review — OpenCodex Provider Hub

Plan revision: OPH-PLAN-R2
Review requirement: RECOMMENDED
Review state: green
Review subject: planning/OPENCODEX_PROVIDER_HUB_PLAN.md blob fd53679fe0afb74b38bcbdeb857b5dc75f028532 (frozen at commit b0a687f84fa9086d32f0a07162f7cdc436921bc0)
Review evidence: GREEN — OPH-PLAN-R2 closes both OPH-PLAN-R1 RED findings and is consistent with approved OPH-R1/D31; no P0/P1 planning defect found.

## Review authority

- Workstream manifest: `implementation/workstreams/change-opencodex-provider-hub/WORKSTREAM.yaml`
- Requirements: `requirements/OPENCODEX_PROVIDER_HUB.md` revision `OPH-R1`
- Decision: `docs/DECISIONS.md#d31--opencodex-is-the-candidate-single-provider-hub-and-catalog-owner`
- Reviewed plan: `planning/OPENCODEX_PROVIDER_HUB_PLAN.md`
- Prior review: `planning/reviews/OPH-PLAN-R1.md` (RED)

## Verdict evidence

### GREEN-1 — OPH-PLAN-R1 RED-1 is closed

OPH-M03 now makes restart persistence and **operator-authorized recreate persistence** part of OPH-LIVE-B before source migration. The recreate explicitly uses a proof-capable image/branch that still retains the custom fork as the recoverable source path, and the plan states that OPH-M04 is blocked unless this recreate check is run and GREEN. OPH-M04 dependency is OPH-M03 GREEN and its first source-migration step is explicitly conditional on OPH-LIVE-B including recreate persistence being GREEN.

This satisfies OPH-R1 acceptance items 8 and 10 and OPH-REQ-006/010/011/016: source migration cannot begin before the reversible live proof, including recreate persistence and rollback, has passed while the previous fork-backed path remains recoverable.

### GREEN-2 — OPH-PLAN-R1 RED-2 is closed

OPH-M02 and OPH-LIVE-A now make native OpenCodex Meta Muse replacement conditional on operator-GREEN evidence for the accepted Muse model, intended effort behavior, one harmless tool path, and the required session/task path without silent provider substitution. If that equivalence surface is not GREEN, Muse remains on the retained CLIProxyAPI route. OPH-M05 repeats the same equivalence smoke when production uses native OpenCodex Meta Muse.

This satisfies OPH-REQ-007 and prevents a simple model/response smoke from being treated as sufficient replacement evidence.

### GREEN-3 — upstream browser compatibility remains a proof gate, not an assumption

The plan requires **unmodified upstream** `miuuyy/codex-chatgpt-web serve` to pass direct provider compatibility in OPH-M02 and treats source modification merely to operate behind OpenCodex as a proof failure/blocker rather than silently recreating the fork. Current upstream source independently confirms a standalone `codex-chatgpt-web serve` command exists (`src/cli.ts` on upstream main), but the plan correctly does not infer downstream OpenCodex compatibility from that fact.

### GREEN-4 — route/catalog ownership, reversibility and retained providers are coherent

OpenCodex is the only candidate Codex-facing provider/catalog owner during takeover. The proof substrate is opt-in and isolated before takeover; the current production route remains unchanged until OPH-M03. Codex-LB and CLIProxyAPI are retained through evaluation and production migration rather than being decommissioned as prerequisites. Rollback is prepared before takeover, exercised in OPH-LIVE-B, and the prior known-working image/route remains the recovery baseline under the existing D25 lifecycle.

### GREEN-5 — operator live acceptance covers the approved behavioral surface

OPH-LIVE-B explicitly covers CE startup, picker rows, provider-identity routing with no silent fallback, browser Full Harness, compaction/capability truth, subagents, Android Remote, restart persistence, recreate persistence and rollback. OPH-M05 repeats the production candidate surface before final integration. Static/candidate evidence is explicitly prevented from substituting for required operator live evidence.

### GREEN-6 — concurrent workstream, security and data-integrity boundaries are preserved

The plan leaves `change-muse-native-upstream` independent and only hands it evidence after OpenCodex production acceptance; it does not merge, rewrite, delete or mark that workstream superseded. Credentials, ChatGPT/OAuth state and browser profiles remain outside Git under persistent user state; proof state is isolated; route/catalog state is snapshotted before takeover; rollback must preserve login/profile/projects; ambiguous routing/capability advertisement fails closed.

### GREEN-7 — baseline and YAGNI checks

The current Workstation source supports the plan's baseline: `scripts/build/install-codex-web-gpt.sh` defaults to `elmakus/codex-chatgpt-web` and requires the fork's packaged Codex-LB key helper; `scripts/resolve-upstreams.py` resolves that fork by default; `compose.yaml` still exposes `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM`; the desktop session auto-starts Codex Web GPT. Current OpenCodex upstream documents provider/model routing, arbitrary OpenAI-compatible providers, Codex integration/restore behavior and account routing, and its source contains Meta Muse provider/OAuth paths. The plan therefore uses existing upstream responsibilities instead of adding another Workstation/browser-adapter provider-router abstraction.

## Review focus result

- R1 recreate-persistence ordering defect: **closed**.
- R1 native-Muse equivalence defect: **closed**.
- Upstream `serve` compatibility assumed before proof: **no**.
- Singular/reversible OpenCodex ownership: **yes**.
- Codex-LB/CLIProxyAPI preserved during evaluation: **yes**.
- Picker/Full Harness/compaction/subagents/Android/persistence/rollback live gates: **covered**.
- Source migration before reversible proof GREEN: **no**.
- Independent Muse workstream mutation/silent supersession: **no**.
- Requirement coverage / unnecessary routing machinery: **acceptable; no material gap found**.
- Credential/browser-profile/rollback boundaries: **acceptable**.

## Evidence identities checked

- Frozen plan blob: `fd53679fe0afb74b38bcbdeb857b5dc75f028532` at commit `b0a687f84fa9086d32f0a07162f7cdc436921bc0`.
- Approved Definition blob: `a981904a950f47971372fa31671e991f9d3353af`.
- Prior RED review blob: `967e8653399374434df7035c0c5a497c6e89469a`.
- Workstation baseline source: `compose.yaml` `b6734b5e80f9861df599811aa81d5de043d83ca7`; installer `a5a546d376e876710b937c56b0bc78191f123ac5`; resolver `0ff9791e2b6b3ba3a803f9fca4590fa415ed8ec3`; desktop session `099725d113c084151b78a4b6dc70ff7c69514283`.
- Upstream `miuuyy/codex-chatgpt-web` checked at main `eaf4f09ae92d4dc4429fa597b0861663138f08f8`, including `src/cli.ts` blob `5d1cfac7107472d3ca46498d625c24809b6229b3`.
- OpenCodex checked at main `7c625fc9755c9824653ab944190e243091a2c85c`; README blob `d29cd2f43aff6c468a843ed2de20c71b836fc59f`.

## Review focus

Independently verify at minimum:

- that the OPH-PLAN-R1 RED findings are actually closed:
  - source migration cannot start before operator-GREEN restart + recreate persistence while the fork remains recoverable;
  - native OpenCodex Meta Muse cannot replace the CLIProxyAPI Muse route without explicit operator-GREEN model/effort/tool/session-path equivalence;
- that the plan does not assume upstream `miuuyy/codex-chatgpt-web serve` compatibility before proof;
- that OpenCodex route/catalog ownership is singular and reversible;
- that Codex-LB and CLIProxyAPI remain available during evaluation rather than being prematurely removed;
- that operator-run live gates are sufficient to prove picker routing, browser Full Harness, compaction, subagents, Android Remote, persistence and rollback;
- that source migration occurs only after the reversible live proof is GREEN;
- that the independent `change-muse-native-upstream` workstream is not mutated or silently superseded;
- that requirements are completely covered without unnecessary provider/router machinery in the Workstation or browser adapter;
- that credential, browser-profile and rollback boundaries are safe.
