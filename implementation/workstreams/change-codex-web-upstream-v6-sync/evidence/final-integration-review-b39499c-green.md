# Independent final-integration review — Codex Web GPT v6.1 private.1 candidate

Date: 2026-09-25
Review owner: workstream manifest `change-codex-web-upstream-v6-sync`
Requirement: RECOMMENDED
Verdict: GREEN

## Immutable subject

`elmakus/codex-chatgpt-web@b39499c391744eaa378b157822e18b9218590b60`

Independent Git readback confirmed `work/upstream-v6.1-sync` is identical to this exact SHA.

The candidate is a descendant of:
- trusted upstream v6.1.0 subject `293341084ac7a1ddd2de12fede3706023f5b6474`; and
- pre-sync fork main `0f77eb00203f93617f7c38a24ad4e1c6e1cc9d3b`.

It is exactly two commits ahead of the previously independently GREEN T01 subject `0dcf8ed9dbd229cf908cc68b31f4126c0af2414d`.

## Authority and acceptance reviewed

- `requirements/SMART_UPSTREAM_UPDATES.md`, especially R4/R5/R9/R13.
- `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md#milestone-m00--codex-web-gpt-fork-release-readiness`.
- `docs/DECISIONS.md` D5/D10/D11/D25.
- current workflow-main `workflow/common/FORK_RELEASE_VERSIONING.md`.
- T01/T02/T03 contracts and exact durable evidence.
- prior independent T01 GREEN and exact prior T02 RED evidence.

## Independent findings

1. The branch still freezes the intended immutable subject. Compare readback reports no commits or file differences between the branch and `b39499c...`.
2. The upstream-v6.1 integration remains intact. The candidate is directly ahead of the frozen upstream subject and of the pre-sync fork-main subject; no replacement/rebase drift was found.
3. The previously independently GREEN T01 runtime/routing/auth/isolation implementation is unchanged by the two later commits. T01 -> T02 changes exactly six release/version-contract files; T02 -> T03 changes only `tests/server-lifecycle.test.ts`.
4. Canonical fork release identity is correctly `v6.1.0-private.1`. Root package, launcher package and runtime `VERSION` are synchronized to `6.1.0-private.1`, while `upstreamLauncherVersion` remains `6.1.0`.
5. The generic release workflow recognizes only canonical `vX.Y.Z-private.N` tags as stable despite the hyphen; ordinary suffixed tags remain prerelease. The fork Linux release workflow separately requires the branch-derived tag to equal the package version, builds/smokes the Linux artifact, emits SHA-256 checksums, refuses to replace a release whose tag resolves to a different SHA, and publishes the canonical fork release as latest/stable.
6. The prior RED condition is resolved without runtime behavior changes. The corrected health test rejects the exact sensitive proxy error detail, upstream denial detail and bearer token while allowing public canonical version metadata containing the word `private`.
7. Exact-subject execution evidence records: focused health 38/38; full runtime 811 pass / 4 skip / 0 fail; Node 24 launcher 347 pass / 1 skip / 0 fail; root and launcher typecheck/build GREEN; Linux x64 AppImage release-path build, packaged-launcher smoke and current-Arch ABI smoke GREEN. The evidence explicitly identifies `b39499c...` as the tested HEAD.
8. GitHub exposes no combined commit-status records for this immutable SHA, so review confidence is based on immutable Git ancestry/diff/source inspection plus the workstream's exact-tree execution evidence.
9. No fork-main merge, tag/release publication or Workstation production rebuild/recreate/promotion has occurred as part of this reviewed subject.
10. No new speculative mechanism or unrelated complexity was introduced by the T02/T03 corrections.

## Verdict

GREEN. The exact release-ready subject satisfies the M00 workstream final-integration acceptance surface. No blocking correctness, privacy, routing/auth/isolation, release-lineage, checksum/provenance or packaging defect was found in the reviewed subject.
