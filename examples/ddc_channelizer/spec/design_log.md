# Cycle 1 — 2026-11-04 (migration)
- **Stage completed:** framework migration to external design folders
- **Unit status:** planned
- **Spec work (gate 0):** not started — run `fpga-spec` (new first step)
- **Plan:** not started — blocked until `../axis_fifo_loopback` is validated
- **Test plan:** not started
- **Tests:** not run
- **Notes:** documents moved to `spec/`; framework tools now take the design
  folder (`bash <LOGIC_SPEC>/tools/run_tests.sh .`); dependency now a relative path `../axis_fifo_loopback`. Gate 0 must be
  approved before tests can count for validation.

# Cycle 1 — 2026-10-12 (migration)
- **Stage completed:** framework consistency migration
- **Unit status:** planned
- **Plan:** not started — blocked until `axis_fifo_loopback` is validated
- **Test plan:** not started
- **Tests:** not run
- **Notes:** manifest moved from `spec.md` to `architecture.md` (`part`, `top`
  added); acceptance criteria numbered AC-1…AC-5.

# Cycle 1
- **Stage Completed:** Architect
- **Design Status:** `planned` (spec only; no plan approved, no code yet)
- **Test Plan Status:** Not started (pending fpga-plan)

