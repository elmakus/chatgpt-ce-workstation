# M01-T11 D25 APT mirror-consistency blocker

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T11`
State: **BLOCKED before production mutation**

## Intended subject

M01-T11 must consume exact Codex Web GPT release:

- version: `5.0.15`
- release commit: `3a6d1d28c28dbe1be885077ae53fe4bba62b9673`
- AppImage SHA-256: `bdad25547ae79f29ee27a029bed5ec6c7762f98a92e7578762de40a113b9b49d`
- normal D25 resolution: `override: false`

A preflight resolver run confirmed exactly that subject with no overrides.

## Production baseline before attempts

Target host: Tower.

- checkout: `work/muse-native-upstream`
- checkout was clean and fast-forwarded to durable branch state before D25 attempts
- container: `running/healthy`
- running image: `sha256:ce07c414c1442bae243689a17fb32310eed457cb38c52e89394899b9a0289b42`
- installed Codex Web GPT: `5.0.14`
- native upstream remained `http://192.168.2.104:2455/backend-api/codex`
- Muse upstream remained unset

## Failure

Repository-owned `bash scripts/update.sh` repeatedly stopped in the exact candidate build before any production mutation.

The frozen D25 resolver and BuildKit candidate build observed different valid copies of Ubuntu `noble-updates/InRelease` from `archive.ubuntu.com`.

Observed hashes:

- `356958899aaae2aae4a20a5af07d3256bc12575d3fbcbda5b44f6a27c9817741`
- `a0958fb27e72c1826bb6360f93d4f0ed7876a225309fff90131509461a299859`

Examples:

1. Frozen resolution `4498dfed736442735b927bae9f980250920497e7beeb26af0724cd799410a91a` expected `356958...`; candidate build fetched `a0958f...`.
2. A later resolver recheck saw `a0958f...`, proving mirror propagation had changed.
3. Frozen resolution `2dff55431e014fb6f21795951cf81d1e3286951aaeef91b2ce2b4f40f45ccd9a` expected `a0958f...`; candidate build then fetched `356958...`.

Multiple clean `docker run ubuntu:24.04@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3` probes also demonstrated that the mirror population can converge temporarily and then BuildKit can still resolve the alternate replica.

The exact failing assertion is:

`Ubuntu InRelease SHA-256 mismatch for archive.ubuntu.com_ubuntu_dists_noble-updates_InRelease`

This is the D25 integrity check working as designed; weakening or bypassing it is not authorized.

## Persisted updater readback

After the last failed attempt, `.workstation-update/last-update.json` recorded:

- `status: pre_promotion_failed`
- `reason: candidate_build_failed`
- `resolution_sha256: 2dff55431e014fb6f21795951cf81d1e3286951aaeef91b2ce2b4f40f45ccd9a`
- no candidate image ID
- no previous-image promotion pointer
- no rollback pointer

Fresh readback after failure:

- production container remains `running/healthy`
- production image remains `sha256:ce07c414c1442bae243689a17fb32310eed457cb38c52e89394899b9a0289b42`
- installed Codex Web GPT remains `5.0.14`
- repository tree was returned to clean state after removing only generated `scripts/**/__pycache__`

## Classification

This is a bounded D25 implementation defect exposed by Ubuntu mirror propagation, not a change to R7, D25, release provenance, or product intent.

A legal correction must preserve:

- exact frozen Ubuntu APT identity validation;
- fail-closed behavior when a candidate sees a different index;
- one normal user-facing `scripts/update.sh` operation;
- no silent expert override/pin;
- exact v5.0.15 Codex Web GPT provenance for M01-T11;
- no production mutation until a candidate passes all D25 gates.

The smallest correction surface is the updater/build orchestration: tolerate the known transient mirror-propagation race with a bounded retry of the exact candidate build only when the failure is specifically an Ubuntu InRelease identity mismatch. Every retry must keep the same frozen resolution and integrity assertion; unrelated build failures remain terminal.

**BLOCKED — requires bounded L1/L2 corrective Card before M01-T11 can resume.**
