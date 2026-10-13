---
name: <unit>              # = directory name under designs/
vendor: xilinx            # xilinx | altera
part: <part>              # e.g. xc7a35ticsg324-1L — used by synth check / build
kind: leaf                # leaf | composite | top
top: <unit>               # top entity of this unit, in rtl/<top>.vhd (never a BD wrapper)
status: planned           # planned | generated | validated   (see CLAUDE.md lifecycle)
dependencies: []          # sub-unit names, instantiated by direct RTL
ports: []                 # - { name: <port>, dir: in|out, width: <N> }
validated: {}             # { date: <YYYY-MM-DD>, tests: "<n/n must PASS>", report: sim/test_report.md }
---

# <unit> — Architecture

Derived from `spec.md` (input, never modified). `status` advances
planned → generated → validated; only a `validated` unit may be instantiated by
another unit.

## Summary
One-line purpose.

## Vendor & part rationale
...

## Generics
| Generic | Meaning | Default |
|---|---|---|

## Interfaces
- ...

## Hierarchy
- `<top>` (rtl/<top>.vhd)
  - sub-unit / custom module / vendor IP ...

## Dependencies
- `<unit>` — role. Status at architecture time: validated | **pending** (plan
  cannot be approved until it is validated).

## Abstract IP
- e.g. "dual-clock FIFO 512×64, FWFT"

## Acceptance criteria
Numbered; each is GIVEN/WHEN/THEN and measurable. `fpga-testplan` traces every
`AC-n` to at least one `must` test.

- **AC-1** GIVEN ... WHEN ... THEN ...
- **AC-2** GIVEN ... WHEN ... THEN ...

## Pin map (kind: top only)
| Top port | Package pin | IO standard | Notes |
|---|---|---|---|

Clocks: `<clk_port>` — `<period ns>`.
