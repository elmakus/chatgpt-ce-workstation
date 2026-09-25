# Independent final-integration review — Codex Web GPT upstream v6 sync

Date: 2026-09-25
Review owner: workstream manifest `change-codex-web-upstream-v6-sync`
Requirement: RECOMMENDED
Verdict: GREEN

## Immutable subject

`elmakus/codex-chatgpt-web@0dcf8ed9dbd229cf908cc68b31f4126c0af2414d`

The fork branch `work/upstream-v6.1-sync` resolves exactly to this commit. The candidate is a descendant of both the trusted upstream v6.1.0 subject `293341084ac7a1ddd2de12fede3706023f5b6474` and the pre-sync fork main `0f77eb00203f93617f7c38a24ad4e1c6e1cc9d3b`. The tested merge subject `7f1f20e26d9503ec28cb5af9b485c1f7c1a954ed` and the final candidate have no file-tree differences.

## Authority and acceptance reviewed

- `requirements/SMART_UPSTREAM_UPDATES.md`, especially latest-trusted-stable Codex Web GPT behavior, preservation of authenticity/provenance, image-managed updates, and unchanged runtime isolation.
- `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md` for the related-repository update boundary.
- `implementation/workstreams/change-codex-web-upstream-v6-sync/INTAKE.md`.
- `implementation/workstreams/change-codex-web-upstream-v6-sync/cards/T01.md`.
- `implementation/workstreams/change-codex-web-upstream-v6-sync/evidence/T01-upstream-v6-sync.md`.

## Independent findings

1. Upstream v6.1.0 content is present rather than selectively backported: the candidate is directly ahead of the frozen upstream subject. Upstream v6 model/effort/catalog, Bigger Context, Limits/browser/runtime and AST-based interrupt-hook changes remain in the candidate.
2. Codex-LB routing/auth is preserved. The candidate keeps the configurable native upstream, dedicated API-key boundary and persistent key-file fallback. Custom upstream requests replace the incoming ChatGPT OAuth bearer instead of forwarding it.
3. Muse remains a parallel, separately authenticated route. `muse-*` requests go to the configured Muse/CLIProxyAPI upstream; non-Muse requests remain on Codex-LB. Missing Muse routing fails closed for Muse traffic, while optional Muse catalog failure degrades only Muse picker rows.
4. Encoded-body routing remains correct. The server decodes zstd input for model authority, passes the exact model hint to routing, and preserves the original encoded bytes when no compatibility rewrite is needed. Tests cover Muse and ordinary native zstd paths.
5. Muse compatibility normalization is bounded: the Gmail namespace is omitted only for Muse Responses traffic and `search_content_types` is removed only from Muse `web_search`; unrelated tools and ordinary native request bodies are preserved.
6. Muse catalog merge imports only `muse-*` rows, supports both Codex-shaped and OpenAI-compatible CLIProxyAPI catalogs, deduplicates rows and does not import unrelated provider models.
7. The interrupt-hook change uses upstream's TOML AST implementation rather than restoring the former regex parser. Fork recovery normalization is layered on top and tests protect ownership, order, exact hash/state and user hook preservation.
8. Launcher proxy resolution remains restricted to the official Codex endpoint plus explicitly configured native/Muse bases; control-server bearer authentication remains intact.
9. Image-managed update behavior is preserved via `CODEX_WEB_GPT_DISABLE_UPDATES=1`. Fork Linux release publication builds and smokes the package and emits SHA-256 checksums; an existing release is not overwritten unless its tag resolves to the current build SHA.
10. Fork version `6.1.1` is intentionally separated from the upstream launcher asset version `6.1.0`; `check-version.ts` explicitly validates that split. No versioning inconsistency was found.
11. Durable implementation evidence records focused fork regression 122/122, full runtime 811 pass / 4 skip / 0 fail, launcher tests, typecheck/build and Linux AppImage/ABI package smoke GREEN on the exact tested tree. The final candidate has the same tree as that tested subject.
12. No production Workstation image was rebuilt/promoted and the fork main/release was not published before this review gate.

GitHub does not expose attached commit-status/workflow-run records for the immutable candidate SHA; this review therefore used the durable exact-tree execution evidence plus direct source/test inspection and immutable Git ancestry/tree comparisons.

## Verdict

GREEN. The immutable candidate satisfies the workstream/T01 acceptance surface reviewed above. No blocking correctness, auth-boundary, routing, packaging/provenance or unjustified-complexity defect was found.
