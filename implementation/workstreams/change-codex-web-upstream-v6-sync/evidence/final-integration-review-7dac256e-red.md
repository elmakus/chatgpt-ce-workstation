# Independent final-integration review — corrected Codex Web GPT v6.1 candidate

Date: 2026-09-25
Review owner: workstream manifest `change-codex-web-upstream-v6-sync`
Requirement: RECOMMENDED
Verdict: RED

## Immutable subject

`elmakus/codex-chatgpt-web@7dac256e2607cf6cb46ce0441f17a123fb50bbda`

Independent Git readback confirmed `work/upstream-v6.1-sync` at this exact SHA. The subject is one commit ahead of the previously reviewed `0dcf8ed9dbd229cf908cc68b31f4126c0af2414d`, retains both accepted upstream v6.1.0 subject `293341084ac7a1ddd2de12fede3706023f5b6474` and pre-sync fork-main `0f77eb00203f93617f7c38a24ad4e1c6e1cc9d3b` in its ancestry, and changes only the six release/version-contract files recorded by T02.

The canonical lane is correctly `v6.1.0-private.1`: no existing `v6.1.0-private.N` tag was present, package/launcher/runtime version metadata is synchronized, the upstream launcher baseline remains `6.1.0`, and the release workflow treats canonical private-lineage tags as stable while ordinary suffixed tags remain prereleases.

## Blocking finding

M00 requires the full applicable runtime suite to be GREEN on the exact reviewed tree. Independent exact-SHA validation on an isolated checkout produced:

- `bun run check-version`: GREEN for `6.1.0-private.1`;
- `bun test ./tests`: **810 pass / 4 skip / 1 fail** across 58 files.

The failing test is `model catalog health distinguishes no request, transport failure, upstream denial, and recovery without secrets` in `tests/server-lifecycle.test.ts`. Its privacy assertion rejects any health JSON containing the substring `"private"`. The accepted canonical public version now contains that substring in `"version":"6.1.0-private.1"`, so the assertion fails even though the sensitive fixture values remain absent.

This is a bounded test-contract regression introduced by the release-lineage correction, not evidence of a routing/auth/runtime secret leak. The exact subject nevertheless fails the M00 exact-tree GREEN acceptance requirement and therefore cannot pass final integration review.

## Corrective classification

Bounded L1/L2 implementation correction inside accepted authority. Keep the canonical `6.1.0-private.1` version and replace the over-broad substring check with assertions against the actual sensitive fixture values (proxy error detail, upstream body detail, and bearer token), then rerun the required exact-subject verification and freeze a new immutable subject for fresh independent review.
