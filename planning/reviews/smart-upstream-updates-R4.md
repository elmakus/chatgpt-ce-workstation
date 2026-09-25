# Independent plan review — Smart upstream updates R4

Plan revision: smart-upstream-updates-R4
Review requirement: RECOMMENDED
Review state: in_progress
Review subject: elmakus/chatgpt-ce-workstation@c957fc7c8cc4da5a3ca24e077b1f0ae75225fe6a
Reviewed plan: planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md
Review evidence: pending

## Trigger and bounded corrective delta from R3

Independent R3 review found a P1 planning-authority reconciliation defect: the canonical approved Smart Upstream Updates Definition on the immutable R3 subject already contained R17-R24 and accepted D28 from the separately approved Workstation Docker retention extension, while R3's direct authority/coverage still stopped at R16/D25.

R4 is the bounded plan-only correction. It preserves R3's M00 fork-release-readiness checkpoint and does not reopen the accepted retention architecture. Instead it:
- adds D28 to explicit authority;
- incorporates the already approved and independently GREEN `planning/WORKSTATION_DOCKER_RETENTION_MASTER_PLAN.md` by reference for R17-R24;
- records those exact external milestone owners in requirement coverage;
- makes D28/R17-R24 inherited constraints on the shared M03/M04 updater lifecycle;
- preserves M00, M01-M04 outcomes, runtime behavior and the M04 explicit deployment/live-write authorization gate.

No product/system requirement or accepted strategic decision is changed.

## Review scope

Independently review the exact immutable R4 subject above against:

- approved `requirements/SMART_UPSTREAM_UPDATES.md` including R1-R24;
- accepted `docs/DECISIONS.md#D2`, `#D4`, `#D5`, `#D6`, `#D10`, `#D11`, `#D15`, `#D16`, `#D25` and `#D28`;
- RED evidence in `planning/reviews/smart-upstream-updates-R3.md`;
- approved `planning/WORKSTATION_DOCKER_RETENTION_MASTER_PLAN.md` and its GREEN review `planning/reviews/workstation-docker-retention-R1.md` as the existing milestone authority for R17-R24;
- approved R2/R3 history only as needed to verify that R4 is corrective rather than a new product/system design;
- the existing `change-codex-web-upstream-v6-sync` acceptance only insofar as needed to confirm M00 remains a formalization of already-authorized fork-release readiness.

Audit especially whether:

- all approved R1-R24 now have an explicit owner/execution path without silently weakening any requirement;
- incorporation by reference of the approved retention Master Plan is coherent and does not duplicate, conflict with or reassign its D28/R17-R24 architecture;
- M03/M04 preserve cleanup-after-verification, exact current + one previous rollback protection, workstation-scoped/reference-safe image cleanup, separate bounded BuildKit cache retention, distinct cleanup-failure reporting, persistent-data exclusion and multi-cycle/failure-order evidence;
- M00 remains justified by R4's configured-fork latest trusted stable requirement and introduces no production mutation;
- M00 still preserves fork authenticity/checksum, image-managed updater-disable, routing/auth isolation and final-integration review boundaries;
- M01 may perform unrelated resolver work but cannot close its Codex Web GPT resolution surface before M00 publication is verified;
- M01-M04 outcome/acceptance and the explicit M04 live-write gate are not weakened;
- D15/D4 regression ordering and Ubuntu pre-build immutable identity requirements remain intact;
- R4 is proportionate and does not add a second retention implementation architecture or unnecessary process.

## Verdict

PENDING
