---
name: fpga-architect
description: Capture FPGA design requirements from an input spec.md file or natural-language request, choose the vendor target, and write the unit manifest. Resolves which requirements are met by existing validated units versus new logic or vendor IP. Use at the very start of a new unit, before planning or any code. Produces designs/<name>/architecture.md and never modifies the input spec.md.
---

# FPGA Architect

Turn the request or input `spec.md` into a structured architecture document, a vendor choice, and a unit manifest.
Write no HDL, Tcl, or testbench code here. **Never modify the input `spec.md` file.**

## Steps

1. Ask for a short unit `<name>` if not given (directory-safe).
2. Extract summary, external interfaces, and functional requirements from the user request or input `spec.md`.
3. **Hierarchy resolution.** Scan `designs/*/architecture.md`. For each requirement,
   decide whether it is met by:
   - an existing unit whose `architecture.md` is `status: validated` → reuse it (record
     it in `dependencies`), or
   - a vendor IP (keep it **abstract**, e.g. "dual-clock FIFO 512×64"), or
   - new custom logic.
   Never plan to reuse a unit that is not `validated`.
4. Choose exactly one vendor (`xilinx` or `altera`), justified by requirements.
5. Set the unit `kind`: `leaf` (no sub-units), `composite` (instantiates
   validated units), or `top` (the FPGA top — see step 7).
6. Write **acceptance criteria as GIVEN/WHEN/THEN** so they map to testbench
   checks.
7. **If this is the top unit**, capture the **pin map** in `architecture.md` (or a file it
   references): a table of `top port → package pin → IO standard`, plus clock
   ports and periods. `fpga-toplevel` consumes this later.

## Outputs

Produces a single file `designs/<name>/architecture.md` based on `templates/architecture.md`. The frontmatter should contain the manifest data:

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


## Status Tracking (design_log.md)

At the end of your execution, you must update `designs/<name>/design_log.md`. Prepend the new status data to the TOP of the file. Include the current cycle version number (determine the current cycle from the existing file and increment if starting a new design round/iteration), the stage you just completed, the overall design status, and the status of the test plan.
