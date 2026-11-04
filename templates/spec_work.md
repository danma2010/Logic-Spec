---
status: pending           # pending | approved — any edit resets to pending (gate 0)
source: spec/spec.md      # the user's input, never modified
spec_sha256: <sha256 of spec/spec.md at the time of the review>
date: <YYYY-MM-DD>
---

# <unit> — Refined specification (spec_work)

> Written by `fpga-spec` from `spec.md` and the user's answers. This file, not
> `spec.md`, is the requirements input for every later step.

## Requirements

**ID rules**

- `R-n`: a requirement **stated by the user**, either in `spec.md` or as
  an explicit answer to a question (`Q-n`).
- `RR-n`: a requirement **derived** by the agent from stated ones, or an
  **assumed** default the user only accepted.
- **One shared counter, starting at 0**: R-0, R-1, RR-2, R-3, RR-4, … Each
  number is used exactly once, whichever prefix it has.
- IDs are **stable**. Never renumber or reuse a number. New requirements take
  the next free number. A dropped requirement stays in the table, marked
  `withdrawn`.

**Columns**

- `Type`: `stated` (R), or `derived` / `assumed` (RR).
- `Source`: one of `spec §<heading>` · `Q-n` · `default (Q-n)` ·
  `from R-x, R-y`.
- `Category`: purpose · interface · clock · reset · function · config ·
  performance · resources · target · implementation · reuse · verification.

| ID | Requirement (measurable) | Category | Type | Source |
|---|---|---|---|---|
| R-0 | ... | purpose | stated | spec §Purpose |
| R-1 | ... | interface | stated | Q-2 |
| RR-2 | ... | reset | assumed | default (Q-1) |
| RR-3 | ... | performance | derived | from R-0, R-1 |

## Interfaces
| Port / bus | Dir | Protocol | Width / format | Clock | Req |
|---|---|---|---|---|---|

## Configuration (generics)
| Generic | Meaning | Range | Default | Req |
|---|---|---|---|---|

## Target & implementation choices
- Vendor / part / board: ... *(Req)*
- HDL: VHDL-2008 · Simulator: Questa + cocotb *(Req, or framework default)*
- IP preferences / restrictions: ...
- Reused designs (relative paths): ...

## Pin map (FPGA top only)
| Top port | Package pin | IO standard | Notes |
|---|---|---|---|

## Clarifications log
| Q | Question | Answer | Blocking | Resulting req |
|---|---|---|---|---|
| Q-1 | ... | ... | yes / no | RR-2 |

## Open items (non-blocking)
- (none) — or: item → the `RR-n` assumption used meanwhile
