# M01-T03 related-fork correction evidence

Card: `M01-T03`
Workstation workstream: `change-muse-native-upstream`
Related repository: `elmakus/codex-chatgpt-web`

## Exact implementation subject

- Branch: `fix/muse-cliproxy-catalog`
- Base: `main@9de6a670f1934f5f4843a9df0d4b0d408884798f`
- Implementation HEAD: `9ec01b939a08a191082b551bc2d6dc738a0159e2`
- Pull request: `elmakus/codex-chatgpt-web#11` (draft)
- Changed files:
  - `src/model-catalog.ts`
  - `tests/model-catalog.test.ts`
  - `tests/server-models.test.ts`

Final readback confirmed PR #11 still points at the exact implementation HEAD and related-fork `main` still points at the exact reviewed base.

## Implemented behavior

- The optional Muse catalog now accepts the observed OpenAI-compatible CLIProxyAPI `/v1/models` contract with rows under `data` and public identity in `id`.
- Only `muse-*` IDs are normalized into the Codex catalog; non-Muse CLIProxyAPI rows remain excluded.
- Sparse OpenAI-compatible rows are converted into conservative list-visible Codex descriptors rather than inheriting unverified native-model reasoning, context, compaction, access, tool or multi-agent capability claims.
- The previously supported Codex-shaped Muse catalog form using `models[]` / `slug` remains accepted.
- Existing primary native and `chatgpt-web/*` catalog ordering is preserved.
- Invalid or unavailable optional Muse catalog input remains failure-isolated by the existing server path; the primary native and browser-backed catalog remains available.
- Request-routing and authentication ownership were not changed.

Current OpenAI Codex source was checked during implementation to confirm that a usable remote `ModelInfo` requires more than a slug alone; this is why the live `id` rows are normalized into a minimal Codex descriptor rather than merely renamed.

## Regression coverage

Added focused coverage for:

- observed `{ object, data: [...] }` / `id` CLIProxyAPI shape;
- Muse-only filtering;
- duplicate Muse IDs;
- preservation of the existing `models[]` / `slug` form;
- malformed Muse schema failure isolation;
- end-to-end catalog merge through `modelsRequest`.

Existing Muse outage-isolation and native/Muse route tests remain in the full verification suite.

## Required verification

GitHub Actions CI run `35580909483` for exact HEAD `9ec01b939a08a191082b551bc2d6dc738a0159e2` completed with conclusion `success`.

- `actionlint`: GREEN.
- macOS: `bun run verify`, package and app smoke GREEN.
- Windows: `bun run verify`, package and app smoke GREEN.
- Ubuntu: `bun run verify`, package, Linux AppImage ABI validation and app smoke GREEN.

The repository-required `bun run verify` includes version check, audits, typecheck, full test suites, launcher checks/build, runtime bundle build, license generation and release smoke.

## External-state / secret boundary

- No Workstation production configuration was changed by this Card.
- No release was published and no related-fork PR was merged.
- No CLIProxyAPI credential or runtime secret value was read into source, fixtures, logs or this evidence.
- Production Muse activation remains disabled pending independent review and later R5 release/deployment steps.
