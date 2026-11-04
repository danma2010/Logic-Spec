---
name: fpga-architect
description: Turn a design's approved refined spec (spec/spec_work.md, gate 0) into spec/architecture.md — the unit manifest plus structured architecture with numbered acceptance criteria — choosing vendor, part, kind and dependencies. Use right after fpga-spec, before planning or any code. Never modifies spec.md or spec_work.md.
---

# FPGA Architect

Framework root: `{{LOGIC_SPEC}}`. Design root `<design>`: the open workspace
folder. Derive `spec/architecture.md` from `spec/spec_work.md`. Write no HDL,
Tcl or testbench code. **Never modify `spec/spec.md` or `spec/spec_work.md`.**

## Gate check (do this first)

Require `spec/spec_work.md` with `status: approved` whose `spec_sha256`
matches the current `spec/spec.md` (gate 0). Otherwise stop and run `fpga-spec`.

## Steps

1. The unit `<name>` is the design folder name. Read `spec/spec_work.md` as
   the requirements (`spec.md` only for background). If a requirement is
   still unclear, stop and send it back to `fpga-spec` — do not guess.
2. Extract summary, external interfaces, generics and functional requirements;
   keep each requirement traceable: cite its `R-n` / `RR-n` ID next to the AC it
   produces. Every non-withdrawn requirement is covered by at least one AC, or
   is explicitly noted as not testable in simulation (e.g. a resource budget).
3. **Hierarchy resolution.** Look at the designs `spec_work.md` names for
   reuse, and at sibling design folders (`../*/spec/architecture.md`). For each
   requirement decide whether it is met by:
   - an existing design → record its folder, **relative to `<design>`** (e.g.
     `../axis_fifo`), in `dependencies` and reuse its `top` entity.
     If that unit is not yet `validated`, mark it **pending** in the
     *Dependencies* section — allowed here, but `fpga-plan` cannot approve the
     plan until it is validated;
   - a vendor IP — keep it **abstract** (e.g. "dual-clock FIFO 512×64"); or
   - new custom logic.
4. Choose exactly one vendor (`xilinx` or `altera`) and a `part`, justified by
   the requirements (use the ones `spec_work.md` fixes, if any).
5. Set `kind`: `leaf`, `composite` (instantiates other units) or `top`.
6. Name the unit's `top` entity (normally `<name>`). It must be an RTL entity in
   `rtl/<top>.vhd`, never a block-design wrapper.
7. Write **numbered acceptance criteria** `- **AC-n** GIVEN … WHEN … THEN …`,
   each measurable, so `fpga-testplan` can trace tests to them.
8. **Top unit only:** capture the pin map (`top port → package pin → IO
   standard`) plus clocks and periods, or reference a file holding it.

## Output

`spec/architecture.md` from `{{LOGIC_SPEC}}/templates/architecture.md`, front-matter:

```yaml
name: <name>
vendor: xilinx | altera
part: <part>
kind: leaf | composite | top
top: <entity>
status: planned
dependencies: [ <relative paths to design folders, e.g. ../axis_fifo> ]
ports:
  - { name: ..., dir: in|out, width: N }
validated: {}
```

## Next

`fpga-plan`. Do not generate any code yet.

## Design log

Prepend an entry to `spec/design_log.md` (format:
`{{LOGIC_SPEC}}/templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
