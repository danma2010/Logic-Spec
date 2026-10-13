# <unit> — Requirements (input)

> **Input document, written by the user.** The framework never modifies this
> file; `fpga-architect` derives `architecture.md` from it. Free-form is fine —
> the headings below are a checklist, not a schema.

## Purpose
What the block does, in one or two sentences.

## Interfaces
External ports/buses, clocks, resets (protocols, widths, directions).

## Functional requirements
- ...

## Performance & resources
Throughput, latency, fmax, DSP/BRAM budgets.

## Target
Vendor/part/board preference (or "architect decides"). For an FPGA top: the
board pin list or a reference to it.

## Verification expectations
Scenarios that must be demonstrated; corner cases; reference/golden models.

## Open questions
- ...
