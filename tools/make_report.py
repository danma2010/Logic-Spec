#!/usr/bin/env python3
"""make_report.py — test-plan lint, test list and per-test report builder.

  python3 tools/make_report.py --check  designs/<unit> [--require-approved]
  python3 tools/make_report.py --list   designs/<unit>
  python3 tools/make_report.py --report designs/<unit> [--sim questa] [--make-args "..."]

--check   Lint testplan.md against architecture.md (and tb/*.py if present).
          Exit 0 OK, 1 issues found.
--list    Print "ID function priority" per test (for tools/run_tests.sh).
--report  Build sim/test_report.md + sim/test_report.json from
          sim/tests/<ID>.xml|.log. Exit 0 when the unit meets the validation
          gate (every must test PASS on current sources, every non-passing
          should test waived, test plan approved), else 1.

Standard library only (no PyYAML needed).
"""
from __future__ import annotations

import argparse
import datetime as _dt
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

# ---------------------------------------------------------------- parsing ---


def front_matter(text: str) -> tuple[dict, str]:
    """Parse a minimal YAML front-matter block: scalars, [a, b] and '- x' lists."""
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end < 0:
        return {}, text
    block, body = text[3:end], text[end + 4:]
    data: dict = {}
    key = None
    for raw in block.splitlines():
        line = re.sub(r"\s+#.*$", "", raw).rstrip()
        if not line.strip():
            continue
        m = re.match(r"^([A-Za-z_][\w-]*)\s*:\s*(.*)$", line)
        if m and not raw.startswith((" ", "\t")):
            key, val = m.group(1), m.group(2).strip()
            if val.startswith("[") and val.endswith("]"):
                data[key] = [v.strip() for v in val[1:-1].split(",") if v.strip()]
            elif val == "":
                data[key] = []
            else:
                data[key] = val
            continue
        m = re.match(r"^\s+-\s*(.+)$", line)
        if m and key is not None and isinstance(data.get(key), list):
            item = m.group(1).strip()
            data[key].append(item if item.startswith("{") else item.split()[0])
    return data, body


def section(body: str, title: str) -> str:
    m = re.search(rf"^##\s+{re.escape(title)}\s*$(.*?)(?=^##\s|\Z)", body, re.M | re.S | re.I)
    return m.group(1) if m else ""


def defined_acs(arch_text: str) -> list[str]:
    _, body = front_matter(arch_text)
    found = re.findall(r"^\s*[-*]\s*\**\s*(AC-\d+)\b", body, re.M)
    return list(dict.fromkeys(found))


def parse_tests(tp_body: str) -> list[dict]:
    rows = [l for l in section(tp_body, "Tests").splitlines() if l.strip().startswith("|")]
    if len(rows) < 2:
        return []
    header = [c.strip().lower() for c in rows[0].strip().strip("|").split("|")]

    def col(*names):
        for n in names:
            if n in header:
                return header.index(n)
        return None

    idx = {k: col(*v) for k, v in {
        "id": ("id",), "fn": ("function", "cocotb test", "name"),
        "features": ("features", "feature"), "ac": ("ac", "acs", "acceptance criteria"),
        "priority": ("priority",), "criterion": ("pass criterion", "pass criteria", "criterion"),
    }.items()}
    tests = []
    for r in rows[1:]:
        cells = [c.strip() for c in r.strip().strip("|").split("|")]
        if all(re.fullmatch(r":?-+:?", c) for c in cells if c):
            continue
        get = lambda k: cells[idx[k]] if idx[k] is not None and idx[k] < len(cells) else ""
        tests.append({
            "id": get("id"), "function": get("fn").strip("`"),
            "features": [f.strip() for f in re.split(r"[,\s]+", get("features")) if f.strip()],
            "acs": re.findall(r"AC-\d+", get("ac")),
            "priority": get("priority").lower(), "criterion": get("criterion"),
        })
    return tests


def parse_waivers(tp_body: str) -> dict[str, str]:
    out = {}
    for m in re.finditer(r"^\s*[-*]\s*(T\d+)\s*[:—-]\s*(.+)$", section(tp_body, "Waivers"), re.M):
        out[m.group(1)] = m.group(2).strip()
    return out


def cocotb_tests(tb_dir: Path) -> set[str]:
    names: set[str] = set()
    for py in tb_dir.glob("*.py"):
        names |= set(re.findall(r"@cocotb\.test\b[^\n]*\n(?:\s*@[^\n]*\n)*\s*async\s+def\s+(\w+)",
                                py.read_text(encoding="utf-8", errors="replace")))
    return names

# ------------------------------------------------------------------ check ---


def load(unit: Path):
    arch_p, tp_p = unit / "architecture.md", unit / "testplan.md"
    if not arch_p.exists():
        sys.exit(f"TESTPLAN FAIL: {arch_p} not found")
    if not tp_p.exists():
        sys.exit(f"TESTPLAN FAIL: {tp_p} not found (run fpga-testplan)")
    arch_text = arch_p.read_text(encoding="utf-8")
    arch_fm, _ = front_matter(arch_text)
    tp_fm, tp_body = front_matter(tp_p.read_text(encoding="utf-8"))
    return arch_fm, defined_acs(arch_text), tp_fm, tp_body


def check(unit: Path, require_approved: bool) -> tuple[list[str], list[str], list[dict]]:
    arch_fm, acs, tp_fm, tp_body = load(unit)
    tests = parse_tests(tp_body)
    errs, warns = [], []
    status = str(tp_fm.get("status", "")).lower()
    if status not in ("pending", "approved"):
        errs.append(f"testplan status must be pending|approved, got '{status}'")
    elif require_approved and status != "approved":
        errs.append("testplan status is 'pending' — gate 2: approve it before running tests")
    if not acs:
        errs.append("architecture.md defines no acceptance criteria '- **AC-n** ...'")
    if not tests:
        errs.append("no tests found in the '## Tests' table")
    seen_id, seen_fn = set(), set()
    for t in tests:
        tid = t["id"] or "<blank>"
        if not re.fullmatch(r"T\d{2,}", t["id"]):
            errs.append(f"{tid}: ID must look like T01")
        if t["id"] in seen_id:
            errs.append(f"{tid}: duplicate ID")
        seen_id.add(t["id"])
        if not re.fullmatch(r"[A-Za-z_]\w*", t["function"]):
            errs.append(f"{tid}: function '{t['function']}' is not a valid Python identifier")
        elif not re.match(rf"{t['id'].lower()}_", t["function"]):
            warns.append(f"{tid}: function '{t['function']}' should start with '{t['id'].lower()}_'")
        if t["function"] in seen_fn:
            errs.append(f"{tid}: duplicate function '{t['function']}'")
        seen_fn.add(t["function"])
        if t["priority"] not in ("must", "should"):
            errs.append(f"{tid}: priority must be must|should, got '{t['priority']}'")
        c = t["criterion"]
        if not c or c in ("...", "TBD") or "<" in c:
            errs.append(f"{tid}: pass criterion missing or placeholder")
        if not t["acs"]:
            errs.append(f"{tid}: covers no AC-n")
        for a in t["acs"]:
            if a not in acs:
                errs.append(f"{tid}: references {a}, not defined in architecture.md")
    must_cov = {a for t in tests if t["priority"] == "must" for a in t["acs"]}
    for a in acs:
        if a not in must_cov:
            errs.append(f"{a}: not covered by any 'must' test")
    tb = unit / "tb"
    if tb.is_dir() and any(tb.glob("*.py")):
        impl = cocotb_tests(tb)
        for t in tests:
            if t["function"] and t["function"] not in impl:
                errs.append(f"{t['id']}: no @cocotb.test '{t['function']}' in tb/*.py")
        for extra in sorted(impl - seen_fn):
            warns.append(f"tb has @cocotb.test '{extra}' that is not in the test plan")
    for w in parse_waivers(tp_body):
        if w not in seen_id:
            warns.append(f"waiver for unknown test {w}")
    return errs, warns, tests

# ----------------------------------------------------------------- report ---

_IGNORE = {"sim_build", "__pycache__", "results.xml", "modelsim.ini", "transcript"}


def newest_source(unit: Path, deps: list[str]) -> float:
    roots = [unit / "rtl", unit / "tb", unit / "tcl", unit / "bd", unit / "testplan.md"]
    for d in deps:
        roots += [unit.parent / d / "rtl", unit.parent / d / "tcl"]
    newest = 0.0
    for r in roots:
        files = [r] if r.is_file() else (r.rglob("*") if r.is_dir() else [])
        for f in files:
            if f.is_file() and not (set(f.parts) & _IGNORE) and f.suffix not in (".wlf", ".vcd", ".pyc") \
                    and "ip" not in f.relative_to(unit.parent).parts[2:3]:
                newest = max(newest, f.stat().st_mtime)
    return newest


def read_result(xml_p: Path, log_p: Path, fn: str) -> dict:
    res = {"result": "NOT RUN", "message": "", "seed": "", "time_s": ""}
    if not xml_p.exists():
        if log_p.exists():
            res.update(result="ERROR", message="no results.xml (compile/elaboration failure?) — see log")
        return res
    try:
        root = ET.parse(xml_p).getroot()
    except ET.ParseError as e:
        return {**res, "result": "ERROR", "message": f"unreadable xml: {e}"}
    for p in root.iter("property"):
        if "seed" in (p.get("name") or "").lower():
            res["seed"] = p.get("value", "")
    case = next((c for c in root.iter("testcase") if c.get("name") == fn), None)
    if case is None:
        return {**res, "result": "ERROR", "message": f"test '{fn}' not found in results"}
    res["time_s"] = case.get("time", "")
    bad = case.find("failure") if case.find("failure") is not None else case.find("error")
    if bad is not None:
        msg = (bad.get("message") or bad.text or "").strip().splitlines()
        res.update(result="FAIL", message=(msg[0] if msg else "failed")[:200])
    elif case.find("skipped") is not None:
        res["result"] = "SKIP"
    else:
        res["result"] = "PASS"
    if not res["seed"] and log_p.exists():
        m = re.search(r"[Ss]eed(?:ing Python random module with| =|:)?\s*(\d+)",
                      log_p.read_text(encoding="utf-8", errors="replace"))
        res["seed"] = m.group(1) if m else ""
    return res


def report(unit: Path, sim: str, make_args: str) -> int:
    errs, warns, tests = check(unit, require_approved=False)
    arch_fm, acs, tp_fm, tp_body = load(unit)
    waivers = parse_waivers(tp_body)
    tdir = unit / "sim" / "tests"
    deps = arch_fm.get("dependencies") or []
    deps = deps if isinstance(deps, list) else [deps]
    newest = newest_source(unit, deps)
    rows = []
    for t in tests:
        r = read_result(tdir / f"{t['id']}.xml", tdir / f"{t['id']}.log", t["function"])
        xml_p = tdir / f"{t['id']}.xml"
        if r["result"] in ("PASS", "FAIL") and xml_p.exists() and xml_p.stat().st_mtime < newest:
            r["message"] = (f"was {r['result']}; sources changed since this run — re-run. " + r["message"]).strip()
            r["result"] = "STALE"
        r["waiver"] = waivers.get(t["id"], "") if r["result"] != "PASS" else ""
        rows.append({**t, **r})

    must = [r for r in rows if r["priority"] == "must"]
    should = [r for r in rows if r["priority"] == "should"]
    must_ok = sum(r["result"] == "PASS" for r in must)
    should_ok = sum(r["result"] == "PASS" for r in should)
    unwaived = [r["id"] for r in should if r["result"] != "PASS" and not r["waiver"]]
    approved = str(tp_fm.get("status", "")).lower() == "approved"
    gate = approved and not errs and must and must_ok == len(must) and not unwaived
    reasons = []
    if not approved:
        reasons.append("test plan not approved")
    if errs:
        reasons.append(f"{len(errs)} test-plan lint error(s)")
    if must_ok != len(must):
        reasons.append(f"{len(must) - must_ok} must test(s) not PASS")
    if unwaived:
        reasons.append("should test(s) without waiver: " + ", ".join(unwaived))
    verdict = "PASS — meets the validation gate" if gate else "FAIL — " + "; ".join(reasons)

    ac_rows = []
    for a in acs:
        cov = [r for r in rows if a in r["acs"]]
        mcov = [r for r in cov if r["priority"] == "must"]
        ok = bool(mcov) and all(r["result"] == "PASS" for r in mcov)
        ac_rows.append({"ac": a, "tests": [r["id"] for r in cov], "status": "PASS" if ok else "OPEN"})

    now = _dt.datetime.now().strftime("%Y-%m-%d %H:%M")
    name = arch_fm.get("name", unit.name)
    md = [f"# {name} — Test report", "",
          f"- **Generated:** {now} by `tools/make_report.py`",
          f"- **Simulator:** {sim}" + (f"  ·  **make args:** `{make_args}`" if make_args else "  ·  default testbench configuration"),
          f"- **Test plan:** {tp_fm.get('status', '?')}  ·  **Unit status:** {arch_fm.get('status', '?')}",
          f"- **Must:** {must_ok}/{len(must)} PASS  ·  **Should:** {should_ok}/{len(should)} PASS",
          f"- **Verdict:** {verdict}", "",
          "| ID | Function | Priority | AC | Result | Seed | Time (s) | Detail | Log |",
          "|---|---|---|---|---|---|---|---|---|"]
    for r in rows:
        detail = (r["message"] + (f" — waived: {r['waiver']}" if r["waiver"] else "")).replace("|", "\\|")
        log = f"[log](tests/{r['id']}.log)" if (tdir / f"{r['id']}.log").exists() else ""
        md.append(f"| {r['id']} | `{r['function']}` | {r['priority']} | {', '.join(r['acs'])} | "
                  f"**{r['result']}** | {r['seed']} | {r['time_s']} | {detail} | {log} |")
    md += ["", "## Acceptance-criteria coverage", "", "| AC | Tests | Status |", "|---|---|---|"]
    md += [f"| {a['ac']} | {', '.join(a['tests'])} | {a['status']} |" for a in ac_rows]
    if errs or warns:
        md += ["", "## Test-plan lint", ""] + [f"- ERROR: {e}" for e in errs] + [f"- warning: {w}" for w in warns]
    md += ["", "Reproduce a test: `RANDOM_SEED=<seed> COCOTB_RANDOM_SEED=<seed> "
               f"bash tools/run_tests.sh {name} {sim} <ID>`", ""]

    out = unit / "sim"
    out.mkdir(parents=True, exist_ok=True)
    (out / "test_report.md").write_text("\n".join(md), encoding="utf-8")
    (out / "test_report.json").write_text(json.dumps({
        "unit": name, "generated": now, "sim": sim, "make_args": make_args,
        "testplan_status": tp_fm.get("status"), "gate_pass": bool(gate), "verdict": verdict,
        "must": [must_ok, len(must)], "should": [should_ok, len(should)],
        "tests": rows, "acs": ac_rows, "lint_errors": errs, "lint_warnings": warns,
    }, indent=2), encoding="utf-8")
    print(f"REPORT {'PASS' if gate else 'FAIL'}: must {must_ok}/{len(must)}, "
          f"should {should_ok}/{len(should)} -> {out / 'test_report.md'}")
    return 0 if gate else 1

# ------------------------------------------------------------------- main ---


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--check", action="store_true")
    g.add_argument("--list", action="store_true")
    g.add_argument("--report", action="store_true")
    ap.add_argument("unit_dir", type=Path)
    ap.add_argument("--require-approved", action="store_true")
    ap.add_argument("--sim", default="questa")
    ap.add_argument("--make-args", default="")
    a = ap.parse_args()
    unit = a.unit_dir.resolve()

    if a.report:
        return report(unit, a.sim, a.make_args)
    errs, warns, tests = check(unit, a.require_approved)
    if a.list:
        if errs:
            print("\n".join(f"ERROR: {e}" for e in errs), file=sys.stderr)
            return 1
        for t in tests:
            print(t["id"], t["function"], t["priority"])
        return 0
    for w in warns:
        print(f"  warning: {w}")
    for e in errs:
        print(f"  ERROR:   {e}")
    n_must = sum(t["priority"] == "must" for t in tests)
    print(f"TESTPLAN {'FAIL' if errs else 'OK'}: {len(tests)} tests ({n_must} must), {len(errs)} error(s)")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
