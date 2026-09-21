# M01-T02 release-order blocker

Status: active

The independently reviewed repair was merged through `elmakus/codex-chatgpt-web#14`; fork `main` read back at merge commit `0f77eb00203f93617f7c38a24ad4e1c6e1cc9d3b`.

A separate pre-existing release candidate already reserves `v5.0.15`: draft PR `elmakus/codex-chatgpt-web#15`, head `3a6d1d28c28dbe1be885077ae53fe4bba62b9673`. That candidate was based on `main` before PR #14 and therefore does not contain the Interrupt-hook repair. At blocker capture there is no `release/v5.0.15` branch and no published `v5.0.15` release.

This workstream prepared the next non-conflicting candidate `v5.0.16` from the post-PR14 `main`: draft PR `elmakus/codex-chatgpt-web#16`, head `68142a3f1725e052a606f488ac2c525db650a661`. Its diff from its base is limited to the three synchronized version fields; CI run `35600698569` is the candidate verification run.

The existing `.github/workflows/fork-linux-release.yml` publishes with `gh release create ... --latest`. Triggering `v5.0.16` while the older `v5.0.15` release path remains unresolved would allow a later publication of `v5.0.15` to explicitly replace the repository's latest-release designation with the older release. Publication of `v5.0.16` is therefore blocked until the separate `v5.0.15` candidate is either published/settled first or definitively closed/superseded.

No live workstation deployment is involved.
