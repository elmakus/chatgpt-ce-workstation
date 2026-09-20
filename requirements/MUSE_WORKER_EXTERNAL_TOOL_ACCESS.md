# Muse worker external-tool and skill access

Status: **definition in progress**
Workstream: `issue-muse-worker-mcp-access`
Date: 2026-09-20

## Problem

Muse workers in `muse-max` are separate Muse Code sessions. They do not inherit Codex Main's live MCP/connectors/tool objects or its in-memory skill context.

When an Executor, Tester or Investigator needs an external system or specialized domain guidance, the Muse harness needs its own durable capability/knowledge surface.

## Accepted external capability model

D25 establishes a **Muse-owned persistent external capability plane**:

- configure/authenticate required MCP servers once in the Muse runtime;
- later `muse exec` processes under the same Muse user/config root reuse that configuration/auth;
- Main does not routinely broker ordinary external calls;
- credentials are never copied into task capsules/results/Git;
- hard least privilege is enforced at the MCP server, credential, endpoint or another real runtime boundary.

Research: `research/MUSE_CROSS_HARNESS_CAPABILITY_PATTERNS_2026-09-20.md`.

## Verified Muse skill model

Muse Code 1.3.0 has a native skills system:

- a skill is a directory containing `SKILL.md`;
- at session start the model receives only the skill catalog metadata, not every full skill body;
- the model loads a relevant body on demand through `read_skill`;
- user skills can live under `~/.config/muse/skills/<id>/` or `$HOME/.agents/skills/<id>/`;
- Muse can also discover Claude/Codex personal and project skill roots and can import foreign personal skills into Muse-owned storage;
- project skills require a trusted workspace;
- skill `allowed-tools` metadata does not grant/enforce tool permissions.

This means specialized skills can be installed once for the Muse harness rather than copied into every worker task or repository.

Research: `research/MUSE_WORKER_SKILL_PLANE_2026-09-20.md`.

## HA Bubble skill case study

`johnnyh1975/HA_Bubble_Skill` is a suitable example of a cross-project domain skill:

- its `SKILL.md` uses compatible name/description front matter and is well below Muse's 256 KiB skill-body limit;
- it contains generation/repair guidance for Home Assistant Lovelace, Bubble Card, Streamline, Sidebar and Mushroom;
- it includes a Health-Check Mode for reviewing existing dashboard YAML;
- it includes a behavioral `eval-set.md` for validating the skill itself;
- its repository verification script validates the skill library/package, not arbitrary generated dashboard output.

### Executor / Investigator

For a Home Assistant/Bubble task, the relevant domain skill should be available and should normally be loaded before implementation or focused diagnosis.

A domain skill may be marked/referenced as required by the dispatch/task capsule so correctness does not depend only on the model noticing the catalog trigger.

### Tester

Tester should also be able to access the relevant domain skill when verifying a domain-specific artifact. Withholding domain knowledge merely to create "independence" would make the Tester weaker.

However, shared skill access must not collapse Executor/Tester independence:

- Tester still receives no Executor trajectory;
- accepted requirements, current repository/runtime state and actual evidence remain the verification authority;
- the domain skill is supporting reference material, not the sole oracle;
- where the skill's claim is material, Tester should verify against actual runtime/component behavior, primary documentation, parsing/tests or other independent evidence when practical;
- the skill's own `eval-set.md` and package verifier are specifically useful when the subject under test is the skill itself, not as substitutes for verifying a generated dashboard.

## Proposed skill ownership model

The simplest model consistent with D21/D25 is:

1. Workstation/Muse owns one persistent user-level skill catalog.
2. All Muse worker roles can see that catalog.
3. Full skill bodies remain lazy-loaded by Muse.
4. Dispatch may identify task-relevant skills so an Executor/Investigator can be required to load them.
5. Tester may load the same domain skill as reference while preserving independent evidence and trajectory boundaries.
6. Repo-specific skills may still live in trusted project `.agents/skills`; broadly reusable domain skills should normally be installed at Muse user scope.

## Existing invariants

1. Main remains orchestration/integration authority.
2. Muse remains a bounded leaf worker harness, not a second project control plane.
3. Caller/Main owns task authorization, workspace assignment and strategic escalation.
4. `codex_workflow` remains Project-Workflow-state agnostic.
5. Secrets/auth material do not enter task capsules, normalized results or Git.
6. Executor and Tester remain distinct logical workers/sessions and Tester never receives Executor trajectory.
7. A shared domain skill is shared reference knowledge, not shared worker trajectory.

## Definition question requiring user authority

Accept or reject the proposed **shared persistent Muse skill catalog with role-specific use**:

- **Accept:** install reusable skills once for Muse; relevant Executor/Investigator tasks require the skill, and Tester may use the same skill as supporting reference while independently verifying the artifact.
- **Reject:** define separate skill catalogs/installation surfaces per worker role.

This choice materially affects Workstation skill installation/updates and whether `codex_workflow` needs role-specific skill-environment isolation.
