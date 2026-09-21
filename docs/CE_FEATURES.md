# ChatGPT Community Edition optional Linux features

Source of truth for the feature catalog: upstream `ilysenko/codex-desktop-linux` `README.md` and `linux-features/` on `main`.

These are **Community Edition Linux extensions**, not OpenAI account entitlements. Enabling a feature patches/stages the Linux package at build time; it does not unlock server-side ChatGPT rollouts.

## Enabled in this workstation

`config/ce-features.json` currently enables:

```json
{
  "enabled": [
    "remote-mobile-control",
    "agent-workspace",
    "computer-use-linux",
    "authored-message-visibility",
    "automation-extensions",
    "mcp-helper-reaper",
    "node-repl-reaper",
    "project-group-last-updated-sort",
    "directory-only-working-tree-watch"
  ]
}
```

Rationale:

- `remote-mobile-control` — primary product goal: Android Remote Control to the always-on Unraid workstation.
- `agent-workspace` — isolated hidden X11 desktop/browser environments owned by the agent.
- `computer-use-linux` — native Linux desktop-control UI/MCP backend for broader computer-use workflows.
- `authored-message-visibility` — keeps authored messages readable in tool-heavy threads instead of hiding them after tool activity collapses.
- `automation-extensions` — improves automation scheduling/update capabilities for an always-on workstation.
- `mcp-helper-reaper` — cleans up orphaned MCP helper processes while preserving live sessions.
- `node-repl-reaper` — cleans up Browser Use `node_repl` helpers left behind after their owner exits.
- `project-group-last-updated-sort` — makes project groups/tasks easier to navigate by ordering them by recent activity.
- `directory-only-working-tree-watch` — keeps deep repository changes visible in real time while Watchbound bounds and shares native Linux file-watch resources.

Google Chrome Stable is installed in the workstation image so CE Browser/Chrome integration and Agent Workspace browser workflows have a real browser available.

## Current public optional feature catalog

| Feature ID | Purpose | Workstation status / note |
|---|---|---|
| `agent-workspace` | Agent-workspace settings and bridge for hidden desktop environments | **Enabled** |
| `api-key-model-visibility` | Show models reported by API-key authenticated compatible providers | Off; not needed for ChatGPT-account-first v1 |
| `api-key-service-tier` | Fast/service-tier UI for API-key authenticated compatible providers | Off |
| `appshots` | Capture and crop the focused Linux window from the composer | Off; potentially useful later |
| `authored-message-visibility` | Keep assistant and user messages visible after tool activity collapses | **Enabled** |
| `authenticated-proxy` | Username/password support for HTTP proxies | Off; no current requirement |
| `automation-extensions` | Multi-time schedules and eager `automation_update` exposure | **Enabled** |
| `browser-proxy` | Pass explicit proxy settings to Browser Use network helpers | Off; no current proxy requirement |
| `chronicle-skysight` | Opt-in Linux desktop activity memory and restricted Skysight MCP tools | Off; higher-scope feature, evaluate separately |
| `codex-micro` | Work Louder Codex Micro hotplug and hidraw policy using upstream `node-hid` | Off; hardware-specific |
| `computer-use-linux` | Linux desktop-control UI and native MCP backend | **Enabled** |
| `copilot-reasoning-effort` | Persistent reasoning-effort defaults for Copilot-auth sessions | Off; irrelevant unless using Copilot auth |
| `directory-only-working-tree-watch` | Replace recursive working-tree watching with bounded Watchbound recursive coverage | **Enabled**; selected repository-watch strategy |
| `filesystem-root-follow-ups` | Allow follow-ups in existing local tasks rooted at `/` | Off; unnecessary with the dedicated `/home/codex/Documents/ChatGPT` project root |
| `flatpak-chrome-native-messaging` | Bridge the official Chrome extension into Flatpak Google Chrome | Off; our Chrome is native `.deb`, not Flatpak |
| `frameless-titlebar` | Hide official Linux overlay buttons for compositor-managed decorations | Off; cosmetic |
| `global-dictation` | X11 and XDG portal global dictation hotkeys | Off; no current voice/dictation requirement |
| `linux-performance-workarounds` | Measured renderer workarounds for affected systems | Off until an actual renderer issue appears |
| `mcp-helper-reaper` | Reap orphaned MCP helpers without touching live sessions | **Enabled** |
| `model-picker-default-presets` | Configure ordered model/effort pairs behind ChatGPT Default | Off; potentially useful after model routing is stable |
| `node-repl-reaper` | Reap Browser Use `node_repl` helpers leaked after owner exits | **Enabled** |
| `omarchy-theme` | Load CSS generated from the current Omarchy theme | Off; irrelevant in this container |
| `persistent-status-panel` | Keep the `/status` panel across thread switches and restarts | Off; convenience candidate |
| `pet-overlay` | Linux avatar-overlay placement and compositor hints | Off; cosmetic |
| `preferred-editor-file-links` | Open source links in the selected editor with a plain click | Off; limited value in Android-Remote-first workflow |
| `project-group-last-updated-sort` | Apply Last updated ordering to project groups and tasks | **Enabled** |
| `project-task-sort` | Restore Created ordering for alternate Projects tasks | Off; UX preference |
| `read-aloud` | Add Linux read-aloud controls to assistant responses | Off |
| `read-aloud-mcp` | Let the agent speak through the Linux Read Aloud backend | Off |
| `record-and-replay` | Record a Linux demonstration and turn it into a reusable skill | Off; interesting later, but adds another native feature/helper path |
| `remote-control-ui` | Expose experimental remote-control settings on Linux | Off; `remote-mobile-control` already includes the Linux Remote host/outbound flow and exposes the relevant Connections UI |
| `remote-mobile-control` | Experimental Linux remote-host and outbound-control flows | **Enabled** |
| `shallow-repository-watches` | Make Linux recursive repository watches shallow/non-recursive to bound UI latency | **Off by design**; conflicts with enabled `directory-only-working-tree-watch` |
| `shared-app-server-socket` | Share one protocol-transparent Unix app-server socket | Off; useful mainly for attaching a separate CLI, which v1 intentionally does not install |
| `thorium-chrome-plugin` | Add Thorium to the official bundled Chrome integration | Off; we use Google Chrome Stable |
| `tray-usage` | Show usage remaining in the Linux system-tray menu | Off; low value in headless/Android-first operation |
| `ui-tweaks` | Optional visual and interaction customizations | Off; defer until baseline works |

## Repository-watch strategy

`directory-only-working-tree-watch` and `shallow-repository-watches` are mutually exclusive alternative policies. Do not enable both.

This workstation deliberately selects **`directory-only-working-tree-watch`**:

- deep changes remain detectable without waiting for a focus refresh;
- Watchbound owns bounded recursive coverage and shares overlapping native watches;
- Git and configured exclusions remain part of the watching policy;
- degraded/unsupported roots can fall back conservatively to the upstream watcher.

`shallow-repository-watches` stays disabled because it trades immediate deep-change detection for simpler non-recursive watches and focus-based recovery.

## Retired compatibility IDs

Current CE compatibility metadata marks these old IDs as retired/ignored for migration purposes:

```text
codex-wrapper-updater
conversation-delete
conversation-mode
deferred-update-build
example-feature
open-target-discovery
ssh-command-wrapper
x11-ewmh-computer-use
```

`zed-opener` is an alias for retired `open-target-discovery`.

Do not add retired IDs to the workstation feature config.

## Change rule

Any feature change must be made in tracked:

```text
config/ce-features.json
```

then the Docker image must be rebuilt. Do not change the generated CE feature config only inside a running container and assume it will survive image recreation.