#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "OK: $*"
}

command -v git >/dev/null || fail 'git is required'
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail 'not a Git working tree'

echo '=== tracked sensitive filenames ==='
mapfile -t suspicious < <(
  git ls-files | grep -E '(^|/)(\.env$|secrets/|auth\.json$|id_(rsa|ed25519)$)|\.(pem|key|p12|pfx|kdbx)$' || true
)
if (( ${#suspicious[@]} > 0 )); then
  printf '%s\n' "${suspicious[@]}" >&2
  fail 'potentially sensitive tracked filenames found'
fi
pass 'no obvious sensitive credential files tracked'

echo
echo '=== ignore hygiene ==='
grep -Fx '.env' .gitignore >/dev/null || fail '.env is not ignored by Git'
grep -Fx 'secrets/' .gitignore >/dev/null || fail 'secrets/ is not ignored by Git'
grep -Fx '.env' .dockerignore >/dev/null || fail '.env is not excluded from Docker build context'
grep -Fx 'secrets/' .dockerignore >/dev/null || fail 'secrets/ is not excluded from Docker build context'
pass 'local overrides and secrets are excluded'

echo
echo '=== branch/tag inventory ==='
git for-each-ref --format='%(refname:short)' refs/heads refs/tags | sort
pass 'review every branch/tag above before changing repository visibility'

echo
echo '=== full-history secret scan ==='
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks git --no-banner --redact .
  pass 'gitleaks full-history scan'
else
  echo 'SKIP: gitleaks is not installed locally.'
  echo 'Install it and rerun this script, or rely on the pinned GitHub Actions secret-scan job before publication.'
fi

echo
echo 'PUBLIC_AUDIT_GREEN'
