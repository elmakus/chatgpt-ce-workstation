# M01-T17 — D25 execution-surface blocker

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T17`
State: **BLOCKED before D25 mutation**

## Pre-mutation refresh

The target host checkout at `/mnt/cachedl/projects/chatgpt-ce-workstation` was recovered on branch `work/muse-native-upstream`, clean, and fast-forwarded to the current durable branch state before execution.

Production baseline readback remained GREEN:
- running image: `sha256:7470b64402282c56300ea6225c9d316c475b441878d38d68ff7862b5ff30248f`;
- container health: `healthy`;
- native upstream: `http://192.168.2.104:2455/backend-api/codex`;
- Muse upstream: unset.

Release freshness readback immediately before D25 confirmed:
- latest stable fork release: `v5.0.16`;
- exact target: `d7c9db70cf1d54029c061490d73335146a23ed28`;
- AppImage SHA-256: `7a46e032a74d1bd848a8d946f36d4d427ec2a89e6aa047c518a0bd6bea922f30`.

`bash scripts/validate-source.sh` completed `SOURCE_VALIDATION_GREEN`. Its two generated untracked `__pycache__` directories were removed, restoring a clean tree.

## Blocker

The authorized repository-owned D25 operation `bash scripts/update.sh` was attempted through the available remote execution surface. The execution call was blocked by OpenAI safeguards before the script started.

No alternate or obfuscated command path was used to bypass that enforcement.

## Post-block readback

After the blocked call:
- target-host Git HEAD remained unchanged and the tree remained clean;
- running image remained exactly `sha256:7470b64402282c56300ea6225c9d316c475b441878d38d68ff7862b5ff30248f`;
- container health remained `healthy`;
- Muse upstream remained unset.

Therefore no D25 resolve/build/promotion/recreate occurred and the safe production baseline is intact.

## Smallest remedy

Run the already-authorized repository-owned operation directly on the target host from the clean workstream checkout:

`cd /mnt/cachedl/projects/chatgpt-ce-workstation && bash scripts/update.sh`

Then resume this Card so Project Workflow can verify the persisted D25 result, exact frozen v5.0.16 identity/checksum, promoted image, health/runtime state, native-upstream preservation and Muse-disabled boundary before continuing to activation.
