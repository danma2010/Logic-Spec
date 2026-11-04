---
name: fpga-spec
description: First step of every Logic-Spec design (gate 0). Sets up the design folder if needed, reviews the user's spec/spec.md for missing, ambiguous or conflicting information, asks the user about every gap, and writes spec/spec_work.md — the refined, numbered requirements that every later step uses instead of spec.md — then asks the user to approve it. Use before fpga-architect, and again whenever spec.md changes. Never modifies spec.md.
---

# FPGA Spec Review — gate 0

Framework root: `{{LOGIC_SPEC}}`. Design root `<design>`: the open workspace
folder, unless the user names another folder. Write no architecture, HDL or Tcl.
**Never modify `<design>/spec/spec.md`** — it is the user's input.

## 1. Set up the design folder (only what is missing)

Run `bash {{LOGIC_SPEC}}/tools/new_design.sh <design>`. It creates `spec/`, the
two pointer files at the design root that load the framework rules (one for
Claude Code, one for Antigravity) and a `.gitignore`, and never overwrites an
existing file: if a pointer file already existed, it appends the framework
line instead. If the script can't run, create the same files by hand from
`{{LOGIC_SPEC}}/templates/design/`.

## 2. Get the input

- `spec/spec.md` exists → read it (and any file it references).
- Not there, but the user described the design in chat → write their words
  **verbatim** into `spec/spec.md` (from `{{LOGIC_SPEC}}/templates/spec.md`).
  That is the only time `spec/spec.md` is created, and only from the user's own words.
- Neither → ask the user to write `spec/spec.md` (point to the template) and stop.

## 3. Review

Check `spec/spec.md` against this list. For each item, classify what you find as
**Missing**, **Ambiguous**, **Conflicting**, or **OK**:

1. Purpose and scope: what is in and out of this unit.
2. Interfaces: every port or bus, its protocol (AXI-Stream, AXI-Lite, …),
   width, direction, handshake/backpressure, and data format (signedness,
   fixed-point Qm.n, I/Q packing, endianness).
3. Clocks: frequencies, relationships, which interface uses which clock,
   and the CDC points.
4. Resets: sync or async, polarity, which domain each reset belongs to, and
   the required post-reset state.
5. Functional behaviour: modes, configuration/generics with ranges and
   defaults, error and overflow handling.
6. Performance: throughput, latency (min/max, in cycles or ns), and fmax.
7. Resources: DSP/BRAM/LUT budgets.
8. Target: vendor, part or board. For an FPGA top: the pin list.
9. Implementation choices: HDL (VHDL-2008 by default), simulator (Questa +
   cocotb by default), preferred or forbidden IP.
10. Reuse: existing design folders this unit should instantiate (they are
    referenced by relative path, e.g. `../axis_fifo`).
11. Verification: scenarios that must be shown, corner cases, golden or
    reference model, numeric tolerances.
12. Measurability: can every requirement be turned into a pass/fail check?

## 4. Ask

Present the findings as numbered questions `Q-1…`, grouped by topic. Each
question gives:

- why it matters;
- a **proposed default** the user can accept with "default";
- whether it is **blocking** (the architecture can't be derived without it) or
  **non-blocking** (it can stay an open item with a stated assumption).

Ask everything in one round, wait for the answers, and ask follow-ups only if
an answer opens a new gap. Never invent a value the user didn't give or
accept. If the spec is complete, say so and go straight to step 5.

## 5. Write `spec/spec_work.md`

Fill in `{{LOGIC_SPEC}}/templates/spec_work.md`:

- Front-matter: `status: pending`, `source: spec/spec.md`, `spec_sha256: <hash of
  spec/spec.md>` (`sha256sum spec/spec.md`, or
  `python3 -c "import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" spec/spec.md`),
  `date`.
- **One `## Requirements` table** that holds every requirement, each a single
  measurable statement:
  - `R-n`: **stated by the user**, in `spec.md` (source `spec §<heading>`)
    or as an explicit answer (source `Q-n`).
  - `RR-n`: **derived** by you from stated requirements (source
    `from R-x, R-y`), or an **assumed** default the user only accepted
    (source `default (Q-n)`). Every RR must be visible to the user at the gate.
  - **One shared counter, starting at 0**, across both prefixes: R-0, R-1,
    RR-2, R-3, … No number appears twice.
  - IDs are stable: on a later revision never renumber or reuse a number. Add
    new requirements with the next free number, and mark dropped ones
    `withdrawn` in the table instead of deleting them.
  - Fill in `Category` and `Type` (`stated` / `derived` / `assumed`).
- The interface, generics, target and pin-map sections give the details and
  refer to requirement IDs. They never hold a requirement that is missing
  from the table.
- The clarifications log: every `Q-n` with the question, the answer, whether
  it was blocking, and the requirement ID(s) it produced.
- Open items: non-blocking gaps, each pointing to the `RR-n` assumption used
  meanwhile. None may be blocking.

Keep the user's intent. Make it precise, but don't add features.

## 6. The gate

Summarize what changed relative to `spec/spec.md`: how many R and RR requirements
there are, and **list every RR** (derived and assumed), since those are what
the user did not write. Then ask the user to approve. On approval, set `status: approved`. If changes are
requested, revise and keep `pending`. **Any** later edit to `spec_work.md`
puts it back to `pending`.

**If `spec/spec.md` changes later** (its hash no longer matches `spec_sha256`):
re-run this skill on the differences, update `spec_work.md` and the hash, and
set it back to `pending`. No later step runs until gate 0 is approved again.

## Next

`fpga-architect`.

## Design log

Prepend an entry to `spec/design_log.md` (create it from
`{{LOGIC_SPEC}}/templates/design_log.md` if missing): stage `fpga-spec`,
spec-work status, number of questions asked/answered, and open items.
