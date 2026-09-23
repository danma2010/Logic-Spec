---
name: fpga-architect
description: Capture FPGA design requirements from a natural-language request, choose the vendor target, and write the unit manifest. Resolves which requirements are met by existing validated units versus new logic or vendor IP. Use at the very start of a new unit, before planning or any code. Produces designs/<name>/spec.md and designs/<name>/unit.md.
---

# FPGA Architect

Turn the request into a structured spec, a vendor choice, and a unit manifest.
Write no HDL, Tcl, or testbench code here.

## Steps

1. Ask for a short unit `<name>` if not given (directory-safe).
2. Extract summary, external interfaces, and functional requirements.
3. **Hierarchy resolution.** Scan `designs/*/unit.md`. For each requirement,
   decide whether it is met by:
   - an existing unit whose `unit.md` is `status: validated` → reuse it (record
     it in `dependencies`), or
   - a vendor IP (keep it **abstract**, e.g. "dual-clock FIFO 512×64"), or
   - new custom logic.
   Never plan to reuse a unit that is not `validated`.
4. Choose exactly one vendor (`xilinx` or `altera`), justified by requirements.
5. Set the unit `kind`: `leaf` (no sub-units), `composite` (instantiates
   validated units), or `top` (the FPGA top — see step 7).
6. Write **acceptance criteria as GIVEN/WHEN/THEN** so they map to testbench
   checks.
7. **If this is the top unit**, capture the **pin map** in `spec.md` (or a file it
   references): a table of `top port → package pin → IO standard`, plus clock
   ports and periods. `fpga-toplevel` consumes this later.

## Outputs

`designs/<name>/spec.md` (requirements, vendor + rationale, interfaces, abstract
IP, acceptance criteria, and — for top — the pin map).

`designs/<name>/unit.md` from `templates/unit.md`:

```markdown
---
name: <name>
vendor: xilinx | altera
kind: leaf | composite | top
status: planned
dependencies: [ <validated unit names> ]
ports:
  - { name: ..., dir: in|out, width: N }
validated: {}
---
```

## Next

`/fpga-plan`. Do not generate any code yet.
