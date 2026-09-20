# Research — Muse worker skill plane

Research ID: R-MUSE-WORKER-SKILLS-2026-09-20
Status: consumed
Origin role: project_definition
Origin subject: requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md
Return target: project_definition:requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md
Research question: How should specialized skills be made available to Muse workers, and should a domain skill such as HA_Bubble_Skill be available to both Executor and Tester?
Return reconciliation: applied
Return reconciliation result: requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md; brainstorming/MUSE_WORKER_MCP_ACCESS_OPEN_QUESTIONS.md

## Findings

1. Muse Code 1.3.0 natively supports Agent Skills-style `SKILL.md` directories.
2. At session start Muse sends only catalog metadata; a full skill body is loaded on demand through `read_skill`.
3. User skills can be persistent under the Muse config directory or the cross-agent `.agents/skills` root. Muse also recognizes Claude/Codex skill roots and can import foreign personal skills.
4. Project skills are workspace-trust gated.
5. Skill `allowed-tools` is metadata only and does not grant/enforce permissions; skill knowledge and MCP/tool authorization are separate planes.
6. `johnnyh1975/HA_Bubble_Skill` has compatible front matter and a ~59 KiB `SKILL.md`, below Muse's 256 KiB limit.
7. The HA Bubble package contains both authoring guidance and review/evaluation material: a dashboard Health-Check Mode plus a behavioral eval set for the skill itself.
8. Executor and Tester can safely share domain reference knowledge without sharing trajectory. The independence risk is correlated wrong guidance, so Tester must treat the skill as supporting evidence and independently verify material claims against current state/runtime/primary sources where practical.
9. Creating separate physical skill catalogs per role is possible but adds installation/update/runtime isolation machinery and is not required by Muse's skill model.

## Sources

- Muse Code Developer Docs — Skills: https://meta-models.github.io/muse-code-sdk/next/guides/extend/skills/
- Muse Code Developer Docs — Packages and capabilities: https://meta-models.github.io/muse-code-sdk/next/guides/plugins/concepts/packages-and-capabilities/
- HA Bubble Skill: https://github.com/johnnyh1975/HA_Bubble_Skill
