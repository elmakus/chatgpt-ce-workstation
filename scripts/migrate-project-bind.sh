#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

if [[ "$(id -u)" -ne 0 ]]; then
  fail 'run this migration from an Unraid root shell'
fi

command -v git >/dev/null || fail 'git is required'
command -v docker >/dev/null || fail 'docker is required'
docker compose version >/dev/null || fail 'Docker Compose v2 is required'
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail 'repository is not a Git working tree'

# Deployment is intentionally sourced from main. Do not accidentally migrate a
# host while a development branch (for example the separate Muse work) is checked
# out. Refuse local edits as well so the replacement image is reproducible from
# the pushed repository state.
echo '=== repository preflight ==='
branch="$(git branch --show-current)"
[[ "$branch" == main ]] || fail "checkout main before migration (current branch: ${branch:-detached})"
if [[ -n "$(git status --porcelain --untracked-files=all)" ]]; then
  git status --short >&2
  fail 'working tree is not clean; preserve/commit/stash local changes before migration'
fi

before_pull_head="$(git rev-parse HEAD)"
echo 'Fast-forwarding main before migration...'
git pull --ff-only
after_pull_head="$(git rev-parse HEAD)"
if [[ -n "$(git status --porcelain --untracked-files=all)" ]]; then
  git status --short >&2
  fail 'working tree became dirty after pull'
fi

# If the pull updated this migration script or any helper it invokes, restart
# from the newly checked-out source before touching the host. Git keeps the old
# script inode readable to the current shell, so an explicit re-exec avoids
# continuing with stale migration logic after a fast-forward.
if [[ "$after_pull_head" != "$before_pull_head" && "${MIGRATE_PROJECT_BIND_REEXEC:-0}" != 1 ]]; then
  echo "main advanced to $after_pull_head; restarting migration from the updated source..."
  exec env MIGRATE_PROJECT_BIND_REEXEC=1 bash "$REPO_ROOT/scripts/migrate-project-bind.sh"
fi

echo "source HEAD: $after_pull_head"

echo
echo '=== source validation ==='
bash scripts/validate-source.sh

echo
echo '=== host preflight ==='
bash scripts/preflight-host.sh

echo
echo 'This will build the new image first, then briefly stop the workstation to normalize the project bind target, recreate, and verify it.'
echo 'Existing data found at the old persistent-home target is preserved by scripts/init-unraid.sh.'
echo 'Disposable test repositories/backups can be removed after the final runtime verification.'
printf 'Continue? [y/N] '
read -r answer
case "$answer" in
  y|Y|yes|YES) ;;
  *) echo 'Cancelled.'; exit 0 ;;
esac

# Build before downtime. If the image build fails, the currently running
# workstation remains untouched and the bind migration has not started.
echo
echo '=== prebuild ==='
bash scripts/build.sh

echo
echo '=== stop ==='
docker compose down

echo
echo '=== prepare bind target ==='
bash scripts/init-unraid.sh

echo
echo '=== start ==='
bash scripts/run.sh --recreate

echo
echo '=== wait for health ==='
bash scripts/wait-healthy.sh

echo
echo '=== verify ==='
bash scripts/verify-runtime.sh
