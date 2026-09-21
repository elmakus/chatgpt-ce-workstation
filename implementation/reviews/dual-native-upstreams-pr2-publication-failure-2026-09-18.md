# Publication verification failure — PR #2

Date: 2026-09-18

## Artifact

- Implementation repository: `elmakus/codex-chatgpt-web`
- PR: #2
- Accepted implementation head entering publication: `eeb57d0855f7baffc3089f66c7c84d2c06c40ef6`
- PR base: `main@f8dc469a43cc562a4173bb77f7a7d9fe2b569187`
- GitHub PR merge test ref: `74100d912174b7116adecc33af86dfa80c99db5b`
- Workflow run: `35298432101`

## Result

**RED / DO NOT MERGE**

PR publication CI exposed a compile-time failure in the newly added M01-T03 regression helper.

macOS `verify` failed during `bun run typecheck`:

```text
tests/native-passthrough.test.ts(36,7): error TS2322:
Type 'Buffer<ArrayBufferLike>' is not assignable to type 'BodyInit | null | undefined'.
```

The failing expression is the zstd regression helper passing the result of `Bun.zstdCompressSync(...)` directly as `Request.body`.

This is inside the bounded M01-T03 test change and is not an unrelated runner/baseline failure.

## Required correction

Represent the compressed bytes with a BodyInit-compatible type (the file already uses an `ArrayBuffer` copy pattern elsewhere), without changing routing semantics or encoded bytes.

After correction:
- obtain a new exact implementation subject;
- run PR CI / `bun run verify`;
- require a fresh independent review because the reviewed subject changed;
- do not merge PR #2 before those gates are GREEN.
