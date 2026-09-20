# Muse worker external-tool and skill access

Status: **approved**
Workstream: `issue-muse-worker-mcp-access`
Date: 2026-09-20

## Goal

Muse workers used by the `muse-max` profile must be able to use external authenticated systems and reusable domain skills without pretending to inherit Codex Main's live connectors or collapsing Executor/Tester independence.

## Accepted architecture

- D25: Muse owns a persistent external capability plane.
- D26: Muse owns one shared persistent skill catalog across worker roles.

Research:
- `research/MUSE_CROSS_HARNESS_CAPABILITY_PATTERNS_2026-09-20.md`
- `research/MUSE_WORKER_SKILL_PLANE_2026-09-20.md`

## Requirements

### R1 — Persistent Muse capability plane

Required MCP servers and their Muse-side authentication/configuration must be reusable by later `muse exec` workers running under the same persistent Muse user/config root.

### R2 — No implicit Main inheritance

A Muse worker must never assume Codex Main/ChatGPT connector sessions, MCP clients or authenticated app sessions are inherited across the process/harness boundary.

### R3 — Direct worker use is the default

When an external capability is configured for Muse, ordinary worker calls use the Muse-owned client directly. Main-mediated brokerage is not the normal path.

### R4 — Secret boundary

Credentials, OAuth material and service secrets must not be copied into task capsules, normalized worker results, repository files or ordinary Main context.

### R5 — Hard least privilege

Where a capability requires restriction, enforcement must occur through a real boundary such as MCP-server configuration, credential scope, endpoint exposure or another runtime-enforced control. Prompt text and Muse tool-list metadata are insufficient as security boundaries.

### R6 — Shared persistent skill catalog

Reusable domain skills must be installable once at Muse user scope and discoverable by all Muse worker roles. Separate per-role physical catalogs are not required.

### R7 — Lazy skill use

Workers should rely on Muse's native skill catalog/read mechanism rather than copying full skill bodies into every task capsule. Task capsules may identify a relevant/required skill by stable ID.

### R8 — Executor / Investigator use

When a task explicitly names a required domain skill, Executor/Investigator must load and use it before making domain-specific changes or conclusions. If the named skill is unavailable, the worker must report the limitation instead of silently proceeding as though it was loaded.

### R9 — Tester use and independence

Tester may load the same domain skill as supporting reference. Tester must still:
- receive no Executor trajectory;
- verify against accepted task/review requirements and actual repository/runtime state;
- independently validate material skill claims through current primary/runtime evidence, tests/parsers or upstream documentation when practical;
- never treat the shared skill alone as sufficient evidence for GREEN.

### R10 — Skill scope

Broadly reusable skills should normally be installed at persistent Muse user scope. Repository-specific skills may live in the trusted project's supported skill directory.

### R11 — Skills do not grant tools

Skill metadata cannot grant MCP/tool capability or bypass capability restrictions. Tool authorization and domain knowledge remain separate planes.

### R12 — Existing Muse orchestration invariants remain

D21 remains unchanged: Main owns orchestration/integration; Muse workers remain bounded leaf workers; Executor and Tester remain distinct logical sessions; `codex_workflow` remains Project-Workflow-state agnostic.

## Non-goals

This work does not:
- transplant Codex/ChatGPT live connector sessions into Muse;
- introduce a universal Main capability broker;
- create per-role Muse homes or per-role skill installations;
- put credentials into Git or task text;
- make an arbitrary third-party skill an image-baked mandatory dependency merely because it was used as a case study;
- redefine the D21 worker lifecycle.

## Acceptance-level outcomes

The target is satisfied when:

1. a later `muse exec` worker can reuse previously configured Muse-side MCP/auth state without Main copying credentials;
2. two distinct Muse roles can discover the same persistent user-level skill;
3. an Executor/Investigator can be explicitly told to load a relevant skill and fails visibly if it cannot;
4. an independent Tester can use the same domain skill while retaining separate session/trajectory boundaries and evidence-based verification;
5. existing non-`muse-max` profiles and D21 lifecycle semantics are not changed by this work;
6. live user-home/auth mutations occur only behind an explicit authorization gate.
