---
name: fpga-architect
description: Capture FPGA design requirements from a natural-language request and choose the vendor target (Xilinx or Altera). Use at the very start of a new design, before planning or any code generation. Produces designs/<name>/spec.md with structured requirements, interfaces, abstract IP needs, and acceptance criteria.
---

# FPGA Architect

Turn the user's request into a structured spec and pick a vendor. Write no HDL,
Tcl, or testbench code here.

## Steps

1. Ask for a short design `<name>` if not given (directory-safe).
2. Extract: a one-line summary, the external interfaces, and the functional
   requirements.
3. Express IP needs **abstractly** — e.g. "dual-clock FIFO 512×64", "DDR4
   controller", "GT transceivers" — never as a concrete vendor part.
4. Choose exactly **one vendor** (`xilinx` or `altera`), and justify it from the
   requirements (available IP, transceivers, board, existing flow).
5. Write **acceptance criteria as GIVEN/WHEN/THEN** so they map directly to
   testbench checks later.

## Output

Write `designs/<name>/spec.md`:

```markdown
# <name> — Spec
Summary: ...
Vendor: xilinx | altera
Vendor rationale: ...
Interfaces: [...]
Abstract IP: [ "dual-clock FIFO 512x64", ... ]
Acceptance criteria:
- GIVEN ... WHEN ... THEN ...
```

## Next

Tell the user to run `/fpga-plan`. **Do not generate any code yet.**
