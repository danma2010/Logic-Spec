---
name: fpga-architect
description: Turn a unit's input spec.md (or a natural-language request) into architecture.md — the unit manifest plus structured architecture with numbered acceptance criteria — choosing vendor, part, kind and dependencies. Use at the very start of a unit, before planning or any code. Never modifies spec.md.
---

# FPGA Architect

Derive `designs/<name>/architecture.md` from the input. Write no HDL, Tcl or
testbench code. **Never modify `designs/<name>/spec.md`** — it is the user's input.

## Steps

1. Get the unit `<name>` (directory-safe). If `designs/<name>/spec.md` exists,
   read it as the input. If the user only gave a request in chat, write their
   request verbatim into a new `spec.md` (from `templates/spec.md`) first — that
   is the one time `spec.md` is created, and only from the user's own words.
2. Extract summary, external interfaces, generics and functional requirements.
3. **Hierarchy resolution.** Scan `designs/*/architecture.md`. For each
   requirement decide whether it is met by:
   - an existing unit → record it in `dependencies` and reuse its `top` entity.
     If that unit is not yet `validated`, mark it **pending** in the
     *Dependencies* section — allowed here, but `fpga-plan` cannot approve the
     plan until it is validated;
   - a vendor IP — keep it **abstract** (e.g. "dual-clock FIFO 512×64"); or
   - new custom logic.
4. Choose exactly one vendor (`xilinx` or `altera`) and a `part`, justified by
   the requirements.
5. Set `kind`: `leaf`, `composite` (instantiates other units) or `top`.
6. Name the unit's `top` entity (normally `<name>`). It must be an RTL entity in
   `rtl/<top>.vhd`, never a block-design wrapper.
7. Write **numbered acceptance criteria** `- **AC-n** GIVEN … WHEN … THEN …`,
   each measurable, so `fpga-testplan` can trace tests to them.
8. **Top unit only:** capture the pin map (`top port → package pin → IO
   standard`) plus clocks and periods, or reference a file holding it.

## Output

`designs/<name>/architecture.md` from `templates/architecture.md`, front-matter:

```yaml
name: <name>
vendor: xilinx | altera
part: <part>
kind: leaf | composite | top
top: <entity>
status: planned
dependencies: [ <unit names> ]
ports:
  - { name: ..., dir: in|out, width: N }
validated: {}
```

## Next

`fpga-plan`. Do not generate any code yet.

## Design log

Prepend an entry to `designs/<name>/design_log.md` (format:
`templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
