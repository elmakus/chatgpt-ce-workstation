# Public repository release checklist

This repository is designed so runtime credentials and user state stay outside Git.

Before changing repository visibility to public, complete these checks.

## 1. Current-tree hygiene

Run:

```bash
bash scripts/validate-source.sh
bash scripts/public-audit.sh
```

Expected final markers:

```text
SOURCE_VALIDATION_GREEN
PUBLIC_AUDIT_GREEN
```

The repository intentionally keeps these local-only:

```text
.env
secrets/
ChatGPT / Codex auth state
GNOME keyring state
SSH private keys
browser profiles
Remote Control private state
```

Do not commit any of them.

## 2. Full Git history

A clean current tree is not enough. Secret scanning must include full Git history and every branch/tag that will become public.

GitHub Actions checks out full history for the `secret-scan` job. The local helper also runs a full-history Gitleaks scan when `gitleaks` is installed.

If personal information or credentials are found in old commits, rewrite the affected history before publication. Treat an actual credential as compromised even after history rewriting and rotate/revoke it.

## 3. Branches and tags

Repository visibility applies to all branches and tags. Review them before publication; do not assume only `main` is exposed.

Development branches should contain only material suitable for public access. Account-specific subscription details, personal names, private infrastructure addresses, credentials and copied private logs do not belong in public history.

## 4. GitHub Actions security

Public CI should run on GitHub-hosted runners only.

Do not attach a self-hosted Unraid/workstation runner to workflows that can execute code from public pull requests. A malicious fork/PR could otherwise execute attacker-controlled code on the self-hosted machine.

The tracked CI workflow uses:

- read-only repository permissions;
- GitHub-hosted `ubuntu-latest` runners;
- pinned action commit SHAs;
- full-history secret scanning;
- source validation, ShellCheck and Dockerfile static checks.

Do not add repository secrets to pull-request jobs unless the trust boundary is explicitly redesigned.

## 5. Runtime configuration stays private

Public source may document generic defaults such as:

```text
/mnt/user/projects
/mnt/user/appdata/chatgpt-ce-workstation
port 6080
UID/GID defaults
```

Those are deployment conventions, not credentials. Real passwords, tokens, account identifiers, private hostnames/IP addresses and user-specific auth state must remain outside Git.

## 6. Final publication gate

Before switching visibility:

```text
[ ] main CI is green
[ ] full-history Gitleaks scan is green
[ ] every branch/tag has been reviewed
[ ] no private account/personal notes remain
[ ] no credential has ever been committed, or any exposed credential has been rotated
[ ] public workflows use GitHub-hosted runners only
```

Only then change repository visibility.
