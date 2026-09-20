# M04-T01 live regression — second Codex Web GPT normalization mismatch

Status: **RED — bounded related-repository correction required**

## Production update readback

The authorized M04 updater completed successfully on the target workstation using the normal resolver/build/promote path.

- exact production image: `sha256:e11e3f473ee45c25585f79f7b891e18f359a0a133d9b3e37359e7514233a4972`
- resolution SHA-256: `604ed5c8904bc55cbf3b8c10a718acc837c6795792f1d31b8dbee2fa1f2e371b`
- retained previous-image rollback tag: `chatgpt-ce-workstation:rollback-214ac0f0ddbfbba6`
- runtime health/isolation/mount verification: GREEN
- Codex Web GPT resolved/published identity: `5.0.11@sha256:0dc9b30e8256b6ea3c6d1cda3bbca73a8a012eee2120fb7f2b2e1591712b3f86`
- Ubuntu: 24.04.5 LTS
- Agent Workspace: 0.3.3
- CE revision: `1ef0ece683afb19f8624138599308a1ca1571fa5`
- Rust: 1.98.1

The updater itself returned success only after health plus `verify-runtime.sh` were GREEN.

## Blocking application regression

Codex Web GPT v5.0.11 closes the previous Interrupt-hook `enabled = true` normalization finding, but its live doctor now reports:

`Codex [features].multi_agent changed after setup; refusing to overwrite the user's newer value`

The current persistent Codex config contains:

```toml
[features]
multi_agent = true
multi_agent_v2 = false # Managed by codex-chatgpt-web: keeps routed Web subagent payloads readable.

[agents]
max_depth = 2 # Managed by codex-chatgpt-web: allows nested routed Web subagents in Compatibility V1.
```

The corresponding integration journal is version 10, active, Compatibility V1, and records:
- `previousMultiAgent.present = false`;
- `previousMultiAgentV2.present = false`;
- `previousAgentMaxDepth.present = false`;
- installed `agent_max_depth = 2`.

Therefore `multi_agent` was not a pre-existing user value. Codex Web GPT installed the managed Compatibility V1 line as `true`; after runtime normalization current Codex retained the owned value but removed only the ownership comment.

Current source requires the exact raw line:

`multi_agent = true # Managed by codex-chatgpt-web: enables routed Web subagents.`

so literal `multi_agent = true` is rejected even though the journal proves the value is bridge-owned.

## Classification

This is a bounded native-normalization compatibility defect inside accepted M04 authority, not a user/product/architecture decision and not a user customization.

The correction must:
- tolerate only the exact native-normalized owned form `multi_agent = true` for Compatibility V1;
- preserve strict failure for `false`, duplicate/ambiguous assignments, table/semantic changes and other unexpected mutations;
- preserve exact journal-driven restoration: when the prior value was absent, deactivate/uninstall removes the normalized owned assignment; when a prior user line existed, it restores that exact line;
- avoid any manual persistent-config rewrite as the durable fix;
- receive fresh REQUIRED independent review before publication/redeployment.

The proxy/tunnel readiness checks were also not GREEN immediately after recreate, but they are separate runtime readiness surfaces and do not explain the deterministic Codex integration ownership error above.

No controlled rollback exercise has been started. M04-T02 remains blocked behind M04-T01.
