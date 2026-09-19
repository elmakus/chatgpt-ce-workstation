# Global Codex workstation defaults

This file is a **template** for an optional global `~/.codex/AGENTS.md`. Review before installing it because it affects every repository opened by Codex in this workstation.

## Working-tree discipline

- Before changing a repository, inspect `git status`, current branch, and configured remotes.
- Preserve unrelated user changes.
- Keep generated/build/cache files out of Git when the repository's ignore policy says they are local-only.
- Do not delete ignored local data merely because it is absent from GitHub.

## Completion discipline

When an implementation task is accepted as complete:

1. run the relevant tests/checks;
2. inspect `git diff` and `git status`;
3. make cohesive commits for the completed work;
4. push the accepted current branch to `origin` when credentials and repository policy permit;
5. report the resulting branch/commit and any CI status that is immediately available.

Do not assume that editing files under `/home/codex/Documents/ChatGPT` synchronizes them to GitHub. Git add/commit/push are explicit operations.

## Git safety

- Never force-push without explicit user approval.
- Never rewrite published history merely to make it prettier.
- Never discard uncommitted user changes without explicit approval.
- Do not push secrets, credentials, browser profiles, tokens, SSH private keys, ChatGPT auth state, Remote Control private keys, or local machine-specific state.

## Workstation assumptions

- Repositories live under `/home/codex/Documents/ChatGPT` and physically reside on the Unraid host at `/mnt/user/projects`.
- User/configuration state lives under `/home/codex` and is persistent across container recreation.
- `compose.yaml` in `chatgpt-ce-workstation` is the deployment/runtime source of truth.
- System packages and files under `/usr`, `/bin`, `/lib`, `/opt` belong to the Docker image.
- The `codex` user has passwordless sudo inside the dedicated workstation container, but does not have general authority over the Unraid host.
- `/var/run/docker.sock` is intentionally not mounted.

## Missing-tool workflow

If a task needs a missing tool, it is acceptable to install it temporarily inside the running workstation to unblock the task, including with passwordless `sudo` where appropriate.

After proving that the tool is actually useful, make the setup reproducible:

- OS package/library/tool -> update `/home/codex/Documents/ChatGPT/chatgpt-ce-workstation/Dockerfile` when that repository is available;
- deployment setting/mount/port/device/environment/secret wiring -> update `/home/codex/Documents/ChatGPT/chatgpt-ce-workstation/compose.yaml`;
- s6/startup behavior -> update workstation `rootfs/`;
- project-specific dependency -> prefer the project's own manifest/environment rather than the global workstation image.

Do not leave a useful workstation-wide dependency only in the current container writable layer. A recreate will remove it.

After the durable change, run relevant checks and commit/push it according to the repository's workflow. If the image must be rebuilt on the Unraid host, report that explicitly; do not add Docker socket access as a shortcut.
