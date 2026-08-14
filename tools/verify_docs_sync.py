#!/usr/bin/env python3
"""Doc/model divergence check (7th review, finding 6 -- fourth occurrence
of this defect class).

R60-PrintSettings.md and STL Files/Rocket60/README.md both PUBLISH flight
numbers (liftoff mass, rail-exit speed, static margin) that tools/
rocket60_model.py computes -- but as hand-typed literals, not generated
text. Every time the model changes (a station audit, a mass-model fix, a
retention redesign that moves the sled's own station) the published
numbers go stale until someone remembers to hand-resync them -- this has
now happened four times across this PR's review history. Rather than
attempt to make two Markdown documents literally generated from Python
(a bigger, riskier restructuring than this fix warrants), this script
runs the model once, extracts its own headline numbers, greps the same
figures out of both docs, and FAILS LOUDLY if they disagree -- so staleness
is caught by CI/a review pass, not by a human noticing a stale sentence.

This is a regression gate, not a source of truth: when it fails, fix the
DOCS to match the model's current output (never fudge the model to match
stale prose).
"""
import os, re, subprocess, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL = os.path.join(REPO, "tools", "rocket60_model.py")
DOCS = [
    os.path.join(REPO, "R60-PrintSettings.md"),
    os.path.join(REPO, "STL Files", "Rocket60", "README.md"),
]

_bad = 0


def bad(ok):
    global _bad
    if not ok:
        _bad += 1
    return "OK" if ok else "FAIL"


def run_model():
    r = subprocess.run([sys.executable, MODEL], capture_output=True,
                        text=True, cwd=os.path.dirname(MODEL), timeout=120)
    if r.returncode not in (0, 1):
        raise RuntimeError("rocket60_model.py crashed:\n%s" % r.stderr[-2000:])
    return r.stdout


def section(out, header, next_header):
    """Slice of `out` starting right after `header` and ending right
    before `next_header` (or end of string) -- the model prints THREE
    tables that all start their rows with the same 4 motor names, so a
    plain motor-name regex applied to the whole output is ambiguous
    (matched the T/W table's own liftoff-mass column as if it were the
    margin table's, a real bug caught while writing this check: 15.30/
    22.60/17.40 "cal" were actually that table's Vmax-column figures)."""
    i = out.index(header) + len(header)
    j = out.index(next_header, i) if next_header else len(out)
    return out[i:j]


def model_numbers(out):
    """(liftoff_g, margin_cal, rail_exit_ms) per motor, read off the
    model's own two summary tables -- not re-derived, just parsed, so this
    script can never silently drift from whatever the model actually
    prints the way the docs themselves did."""
    nums = {}
    margin_tbl = section(out, "marg_bo", "\n\n")
    for m in re.finditer(
            r"^(G80T-14A|H182R-14A|H135W-14A)\s+(\d+)\s+[\d.]+\s+([\d.]+)\s+",
            margin_tbl, re.M):
        nums[m.group(1)] = {"liftoff_g": int(m.group(2)),
                             "margin_cal": float(m.group(3))}
    rail_tbl = section(out, "Rail exit speed", "\n\n")
    for m in re.finditer(
            r"^\s*(G80T-14A|H182R-14A|H135W-14A)\s+([\d.]+) m/s\s+\(OK\)",
            rail_tbl, re.M):
        nums.setdefault(m.group(1), {})["rail_exit_ms"] = float(m.group(2))
    return nums


def doc_has(path, *needles):
    with open(path) as f:
        text = f.read()
    return [n for n in needles if n not in text]


def main():
    out = run_model()
    nums = model_numbers(out)
    for mo in ("G80T-14A", "H182R-14A", "H135W-14A"):
        if mo not in nums or "liftoff_g" not in nums[mo] or "margin_cal" not in nums[mo]:
            raise RuntimeError("could not parse %s out of rocket60_model.py's "
                                "own output -- its print format changed; "
                                "update model_numbers()'s own regex" % mo)

    g80t, h182r, h135w = nums["G80T-14A"], nums["H182R-14A"], nums["H135W-14A"]
    cal = lambda d: "%.2f cal" % d["margin_cal"]
    grams = lambda d: "%d g" % d["liftoff_g"]

    # The specific published figures this check exists to keep honest --
    # exact strings, so a doc that still says "871 g" or "1.45 cal" after
    # the model has moved on fails here instead of surviving to print.
    # Per (doc, motor): which of {mass, margin, rail-exit} that doc
    # actually publishes for that motor -- NOT every doc states every
    # figure for every motor (R60-PrintSettings.md, for instance, never
    # states the H182R's own liftoff mass, only its margin), so requiring
    # a figure absent from a doc's own prose BY DESIGN would be a false
    # failure, not a real one.
    CHECKS = {
        "R60-PrintSettings.md": [
            ("G80T-14A liftoff/margin/rail-exit",
             (grams(g80t), cal(g80t), "%.1f m/s" % g80t["rail_exit_ms"])),
            ("H182R-14A margin", (cal(h182r),)),
            ("H135W-14A margin", (cal(h135w),)),
        ],
        "STL Files/Rocket60/README.md": [
            ("G80T-14A liftoff/margin/rail-exit",
             (grams(g80t), cal(g80t), "%.1f m/s" % g80t["rail_exit_ms"])),
            ("H182R-14A liftoff/margin", (grams(h182r), cal(h182r))),
            ("H135W-14A liftoff/margin", (grams(h135w), cal(h135w))),
        ],
    }

    for path in DOCS:
        if not os.path.exists(path):
            continue
        rel = os.path.relpath(path, REPO)
        for label, needles in CHECKS.get(rel, []):
            missing = doc_has(path, *needles)
            ok = not missing
            print("%-4s %s: %s %s" % (bad(ok), rel, label,
                  "" if ok else "-- missing %s (model says %s)"
                  % (missing, needles)))

    print("\n%d check(s) failed" % _bad)
    return 1 if _bad else 0


if __name__ == "__main__":
    sys.exit(main())
