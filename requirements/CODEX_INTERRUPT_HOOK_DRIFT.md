# Codex Interrupt Hook Drift Compatibility Requirements

Revision: `R1`
Status: `approved`
Updated: `2026-09-21`

## Goal / target state

Codex Web GPT routing must recover safely when native Codex persists `enabled = false` for the journal-owned Interrupt lifecycle hook, without treating a disabled lifecycle hook as healthy and without weakening strict ownership checks for any other hook drift.

## Product / system requirements

| ID | Requirement | Priority | Source / decision | Status |
|---|---|---|---|---|
| CIH-001 | A route whose journal-owned Interrupt hook has `enabled = false` must be reported as unhealthy/inconsistent, never as a healthy active route. | MUST | R01; D29 | accepted |
| CIH-002 | Explicit setup, upgrade, or recovery may repair `enabled = false` only when the journal proves the same owned hook identity and every other owned field matches exactly. | MUST | R01; D29 | accepted |
| CIH-003 | The repair path must restore enabled semantics and then re-verify the canonical journal-owned hook before route startup continues. | MUST | R01; D29 | accepted |
| CIH-004 | Command, event/type, timeout, managed markers/location, state key, trusted hash, or structural drift outside the recognized native enablement override must remain fail-closed. | MUST | Existing ownership invariant; R01; D29 | accepted |
| CIH-005 | The compatibility fix must cover the exact incident shape in automated tests and retain negative tests proving unrelated/tampered drift is still rejected. | MUST | R01; D29 | accepted |
| CIH-006 | The fix must not require moving the hook into a system/MDM/enterprise managed Codex layer or patching upstream Codex solely to hide the hook from native enable/disable controls. | MUST | YAGNI; R01; D29 | accepted |

## Constraints

- The existing journal remains the authority for the integration-owned hook identity.
- Native Codex intentionally treats hooks from user `config.toml` as unmanaged and may persist `hooks.state.<key>.enabled = false`.
- A textual codex-chatgpt-web ownership marker does not make the hook a Codex managed-layer hook.
- The existing fail-closed behavior for unrecognized ownership drift remains a safety invariant.

## Non-goals

- Treating a disabled Interrupt hook as valid/healthy.
- Blindly overwriting arbitrary changes in the managed hook block.
- Redesigning Codex hook management or adding a new config layer.
- Proving which exact user gesture/client invocation caused the historical 2026-09-19 write; retained evidence does not contain that event.

## Global invariants

- A route may be considered healthy only when the Interrupt lifecycle hook is operational.
- Self-healing is allowed only for the narrowly recognized native enablement-state override on an otherwise journal-exact hook.
- Any ambiguity about hook identity or ownership continues to fail closed.
- Recovery must be reproducible in the related `elmakus/codex-chatgpt-web` source and tests, not depend on manual live-file editing.

## Acceptance-level requirements

- Starting from a journal-exact installed hook plus only `enabled = false`, explicit setup/upgrade/recovery restores the hook and permits normal route startup.
- Status/verification before repair identifies that state as inconsistent.
- A changed command, trusted hash, state key, hook type/event, timeout, managed boundary, or structural shape is still rejected.
- The repaired fragment re-verifies against journal authority.
- Existing `enabled = true` native normalization remains compatible.
- Regression coverage reproduces the 2026-09-19 failure shape and prevents recurrence of the dead-route startup failure.

## Definition completeness

GREEN. R01 established the writer class, intentional upstream semantics, failure chain, and bounded compatibility rule. The exact initiating gesture is not recoverable but is non-blocking for implementation.
