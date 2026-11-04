# Cycle 2 — 2026-11-04 (migration)
- **Stage completed:** framework migration to external design folders
- **Unit status:** generated
- **Spec work (gate 0):** not started — run `fpga-spec` (new first step)
- **Plan:** pending
- **Test plan:** pending
- **Tests:** not run
- **Notes:** documents moved to `spec/`; framework tools now take the design
  folder (`bash <LOGIC_SPEC>/tools/run_tests.sh .`). Gate 0 must be
  approved before tests can count for validation.

# Cycle 2 — 2026-10-12
- **Stage completed:** framework consistency migration
- **Unit status:** generated (RTL top added; tests not run)
- **Plan:** pending — revised (FIFO → `xpm_fifo_async`, RTL top), needs re-approval
- **Test plan:** pending — new `testplan.md`, T01–T04 (all must), needs approval
- **Tests:** not run
- **Notes:** manifest moved from `spec.md` to `architecture.md`; ACs numbered
  AC-1…AC-4; testbench rewritten to one test per test-plan entry (adds the
  missing backpressure test); `tb/Makefile` defaults to the real top, `FAST=1`
  keeps the behavioural loop.

# Cycle 1
- **Stage Completed:** Code Generated (Architect, Plan, RTL, Testbench completed)
- **Design Status:** `generated` (plan approved + code generated; not yet validated)
- **Test Plan Status:** Integration/Functional testbench generated, pending simulation run
