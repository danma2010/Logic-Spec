---
unit: <unit>
status: pending           # pending | approved — any edit resets to pending
---

# <unit> — Test plan

Derived from the acceptance criteria in `architecture.md`. Each row maps to
exactly one cocotb test in `tb/` with the given function name. Lint with
`python3 tools/make_report.py --check designs/<unit>`.

## Features
- **F1** ...
- **F2** ...

## Tests

| ID | Function | Features | AC | Priority | Pass criterion |
|---|---|---|---|---|---|
| T01 | t01_<short_name> | F1 | AC-1 | must | measurable, e.g. "all 512 words received, in order, bit-exact" |
| T02 | t02_<short_name> | F2 | AC-2 | should | ... |

Rules: IDs `T01…` unique; function names unique, `t<NN>_…`; priority
`must|should`; every `AC-n` from `architecture.md` covered by ≥1 `must` test.

## Waivers
Only for `should` tests that fail; one line each, with reason and approver.

- (none)
