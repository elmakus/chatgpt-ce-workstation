# M04-T01-C01 implementation evidence

Status: **GREEN — exact corrected source subject frozen for REQUIRED independent review**

Related repository: `elmakus/codex-chatgpt-web`  
Branch: `fix/interrupt-hook-enabled-normalization`  
PR: #4 (draft)  
Exact corrected source subject: `9dd258be18605f9ca2d9fdbd76edd437cf0e12a4`

## Correction

The Codex interrupt-hook ownership verifier/restorer now tolerates only the Codex-native normalization that materializes `enabled = true` on the exact managed command hook.

The implementation:
- keeps exact command/timeout/trusted-state matching;
- recognizes only literal `enabled = true` in the native normalized location;
- removes that tolerated field as part of the owned range during restore;
- continues to reject `enabled = false` and unexpected owned mutation;
- leaves the original journal/trusted hash identity unchanged.

## Production-shape readback

The target workstation currently contains the native normalization in this exact shape:

```toml
[[hooks.Interrupt.hooks]]
type = "command"
command = "<managed codex-chatgpt-web interrupt command>"
timeout = 3

enabled = true
[hooks.state."<managed state key>"]
trusted_hash = "<managed trusted hash>"
```

No persistent production config was manually normalized as the durable fix.

## Verification

Related-repository CI run `35488714398` is GREEN on PR #4:
- Linux, Windows and macOS verify jobs: GREEN;
- actionlint: GREEN;
- targeted `tests/codex-interrupt-hook.test.ts` includes `accepts native enabled=true normalization without weakening managed hook ownership`: PASS;
- full runtime test suite: 736 pass / 0 fail on Linux verify;
- repository `bun run verify`, typecheck/build/package and platform smoke surfaces completed successfully.

PR CI checked synthetic merge subject `a972e76fadc65cfee23826d156e458aa76f62ec9`. Exact Git comparison from `9dd258be18605f9ca2d9fdbd76edd437cf0e12a4` to that synthetic merge contains zero changed files, so the tested tree is identical to the frozen corrected subject.

No corrected release was published and no production recreate/write was performed by this corrective Card.

## Review boundary

REQUIRED independent review subject:
`elmakus/codex-chatgpt-web@9dd258be18605f9ca2d9fdbd76edd437cf0e12a4`

Release/publication and production revalidation remain blocked until this exact subject is independently GREEN.
