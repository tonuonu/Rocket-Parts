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
    # 8th review, finding 3b: the design spec was the FOURTH doc that
    # publishes these same model figures (it carries the sec 6.1 stability
    # ruling the whole design turns on) and the one this gate never
    # covered -- it was already stale on the branch that added this very
    # check, exempt from the check whose own docstring calls staleness
    # "the fourth occurrence of this defect class".
    os.path.join(REPO, "docs", "superpowers", "specs",
                  "2026-08-13-rocket60-design.md"),
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
    before `next_header` (or end of string) -- the model prints several
    tables that all start their rows with the same 4 motor names, so a
    plain motor-name regex applied to the whole output is ambiguous
    (matched the T/W table's own liftoff-mass column as if it were the
    margin table's, a real bug caught while writing this check: 15.30/
    22.60/17.40 "cal" were actually that table's Vmax-column figures)."""
    i = out.index(header) + len(header)
    j = out.index(next_header, i) if next_header else len(out)
    return out[i:j]


def model_numbers(out):
    """Per-motor figures read off the model's own summary tables/print
    lines -- not re-derived, just parsed, so this script can never
    silently drift from whatever the model actually prints the way the
    docs themselves did.

    Coordinator follow-up (8th review): this used to capture only
    liftoff_g/margin_cal/rail_exit_ms -- every OTHER number hand-corrected
    in the docs-sync commit (CG loaded/burnout, margin burnout, the fin's
    Barrowman application station, the per-motor flutter ratios) was
    still just as unguarded as the numbers finding 3b fixed, because
    nothing parsed them. Extended to cover all of it, plus Vf/Xf/vmax
    themselves as standalone entries (`flutter` key) since they are not
    per-motor."""
    nums = {}
    margin_tbl = section(out, "marg_bo", "\n\n")
    for m in re.finditer(
            r"^(G80T-14A|H182R-14A|H135W-14A)\s+(\d+)\s+([\d.]+)\s+([\d.]+)\s+"
            r"(\d+)\s+([\d.]+)\s+([\d.]+)\s+",
            margin_tbl, re.M):
        nums[m.group(1)] = {"liftoff_g": int(m.group(2)),
                             "cg_mm": float(m.group(3)),
                             "margin_cal": float(m.group(4)),
                             "burnout_g": int(m.group(5)),
                             "cg_bo_mm": float(m.group(6)),
                             "marg_bo_cal": float(m.group(7))}
    # T/W table -- Vmax per motor, needed to check the flutter section's
    # own "~131 m/s Vmax"-style figures below.
    tw_tbl = section(out, "v@1m rail", "\n\n")
    for m in re.finditer(
            r"^(G80T-14A|H182R-14A|H135W-14A)\s+\d+\s+[\d.]+\s+[\d.]+\s+(\d+)\s+",
            tw_tbl, re.M):
        nums.setdefault(m.group(1), {})["vmax_ms"] = int(m.group(2))
    # (8th review, finding 3a) the model's rail-exit line has THREE shapes,
    # not one: a clean exit ("16.2 m/s   (OK)"), a genuine-but-slow exit
    # ("12.1 m/s   (FAIL - want >15 m/s)"), or a burnout that never left
    # the rail at all ("BURNOUT ON RAIL -- ... burnout velocity was 12.1
    # m/s at 1.20 m   (FAIL)"). The old regex only matched the first shape
    # -- for either of the other two, rail_exit_ms was silently never set
    # for that motor, and this function returned cleanly; the crash
    # happened later, in main()'s own g80t["rail_exit_ms"] lookup, as an
    # unrelated bare KeyError instead of the loud, actionable RuntimeError
    # this file's own sanity guard exists to raise. Both extra shapes are
    # now parsed too (a FAIL/EXCLUDED status is still a real velocity
    # reading; a burnout's own "never reached the rail-exit height" is
    # reported via its OWN separate rail_burnout flag, not silently
    # coerced into looking like a normal exit).
    rail_tbl = section(out, "Rail exit speed", "\n\n")
    for m in re.finditer(
            r"^\s*(G80T-14A|H182R-14A|H135W-14A)\s+([\d.]+) m/s\s+"
            r"\((?:OK|FAIL[^)]*|EXCLUDED[^)]*)\)",
            rail_tbl, re.M):
        nums.setdefault(m.group(1), {})["rail_exit_ms"] = float(m.group(2))
    for m in re.finditer(
            r"^\s*(G80T-14A|H182R-14A|H135W-14A)\s+BURNOUT ON RAIL.*?"
            r"burnout velocity was ([\d.]+) m/s",
            rail_tbl, re.M):
        d = nums.setdefault(m.group(1), {})
        d["rail_exit_ms"] = float(m.group(2))
        d["rail_burnout"] = True

    # Flutter/Barrowman figures (coordinator follow-up, 8th review): the
    # spec's own "CN(fins) = ... at ~493mm" and "4.6x the G80T's ... Vmax"
    # sentences were never checked against anything -- both turned out to
    # be stale (Xf recomputes to ~626mm from the model's own exposed-panel
    # geometry, self-consistently reproducing the model's own printed CP;
    # the "4.6x" figure is actually H182R's ratio, not G80T's, whose real
    # ratio is ~7.3x). Not per-motor (Xf/Vf are single, whole-airframe
    # figures), so stored under their own top-level keys, not nums[motor].
    fx = re.search(r"CN_fins [\d.]+ at ([\d.]+)mm", out)
    if fx:
        nums["Xf_mm"] = float(fx.group(1))
    vf = re.search(r"Flutter Vf = (\d+) m/s", out)
    if vf:
        nums["Vf_ms"] = int(vf.group(1))
    pm = re.search(
        r"Per-motor: G80T ([\d.]+)x, H182R ([\d.]+)x, H135W ([\d.]+)x", out)
    if pm:
        nums["flutter_ratio"] = {"G80T-14A": float(pm.group(1)),
                                  "H182R-14A": float(pm.group(2)),
                                  "H135W-14A": float(pm.group(3))}
    return nums


def doc_has(path, *needles):
    with open(path) as f:
        text = f.read()
    return [n for n in needles if n not in text]


def main():
    out = run_model()
    nums = model_numbers(out)
    # (8th review, finding 3a) rail_exit_ms is now required here too -- it
    # used to be validated nowhere, so a genuine parse gap (this model
    # output growing a FOURTH rail-exit shape neither regex above
    # recognises) surfaced 40 lines further down as a bare KeyError on
    # g80t["rail_exit_ms"], not this loud, actionable RuntimeError. Every
    # future parse gap in ANY of the three fields now fails the same way.
    # Extended (coordinator follow-up) to also require the columns/
    # flutter figures the checks below now depend on.
    REQUIRED_PER_MOTOR = ("liftoff_g", "cg_mm", "margin_cal", "burnout_g",
                           "cg_bo_mm", "marg_bo_cal", "rail_exit_ms",
                           "vmax_ms")
    for mo in ("G80T-14A", "H182R-14A", "H135W-14A"):
        if mo not in nums or any(k not in nums[mo] for k in REQUIRED_PER_MOTOR):
            raise RuntimeError("could not parse %s out of rocket60_model.py's "
                                "own output -- its print format changed; "
                                "update model_numbers()'s own regex" % mo)
    for k in ("Xf_mm", "Vf_ms", "flutter_ratio"):
        if k not in nums:
            raise RuntimeError("could not parse %s out of rocket60_model.py's "
                                "own output -- its print format changed; "
                                "update model_numbers()'s own regex" % k)

    g80t, h182r, h135w = nums["G80T-14A"], nums["H182R-14A"], nums["H135W-14A"]
    cal = lambda d: "%.2f cal" % d["margin_cal"]
    cal_bo = lambda d: "%.2f cal" % d["marg_bo_cal"]
    grams = lambda d: "%d g" % d["liftoff_g"]
    cg = lambda d: "%.1f mm" % d["cg_mm"]
    cg_bo = lambda d: "%.1f mm" % d["cg_bo_mm"]
    ratio_needle = lambda mo, label: "%.1f× the %s's ~%d m/s Vmax" % (
        nums["flutter_ratio"][mo], label, nums[mo]["vmax_ms"])

    # The specific published figures this check exists to keep honest --
    # exact strings, so a doc that still says "871 g" or "1.45 cal" after
    # the model has moved on fails here instead of surviving to print.
    # Per (doc, motor): which of {mass, margin, rail-exit, CG, flutter}
    # that doc actually publishes for that motor -- NOT every doc states
    # every figure for every motor (R60-PrintSettings.md, for instance,
    # never states the H182R's own liftoff mass, only its margin), so
    # requiring a figure absent from a doc's own prose BY DESIGN would be
    # a false failure, not a real one.
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
        # 8th review, finding 3b; CG/burnout/flutter columns added per
        # coordinator follow-up in the same review round -- this is now
        # the one doc that publishes the FULL per-motor table plus the
        # flutter section, so it is the one doc with the full check list.
        "docs/superpowers/specs/2026-08-13-rocket60-design.md": [
            ("G80T-14A liftoff/margin/rail-exit",
             (grams(g80t), cal(g80t), "%.1f m/s" % g80t["rail_exit_ms"])),
            ("G80T-14A CG loaded/burnout", (cg(g80t), cg_bo(g80t))),
            ("G80T-14A margin burnout", (cal_bo(g80t),)),
            ("H182R-14A margin", (cal(h182r),)),
            ("H182R-14A CG loaded/burnout", (cg(h182r), cg_bo(h182r))),
            ("H182R-14A margin burnout", (cal_bo(h182r),)),
            ("H135W-14A margin", (cal(h135w),)),
            ("H135W-14A CG loaded/burnout", (cg(h135w), cg_bo(h135w))),
            ("H135W-14A margin burnout", (cal_bo(h135w),)),
            ("flutter: CN(fins) application point",
             ("~%d mm" % round(nums["Xf_mm"]),)),
            ("flutter: per-motor ratios",
             (ratio_needle("G80T-14A", "G80T"),
              ratio_needle("H182R-14A", "H182R"),
              ratio_needle("H135W-14A", "H135W"))),
        ],
    }

    for path in DOCS:
        rel = os.path.relpath(path, REPO)
        if not os.path.exists(path):
            # Coordinator follow-up (8th review): this used to `continue`
            # -- a missing document silently dropped out of the report
            # with the run still exiting 0, the SAME silent-skip shape as
            # finding 3 (a check that should be able to fail instead
            # produces no row at all). A doc that gets renamed or moved
            # stops being checked while this gate keeps reporting success
            # -- indistinguishable, to anything reading the exit code,
            # from every figure in it still being in sync. Every path in
            # DOCS is a repo file this gate is supposed to guarantee
            # agreement for; one that cannot be found is that guarantee
            # already broken, not a reason to skip checking it.
            print("%s %s: file not found -- cannot verify it agrees "
                  "with the model" % (bad(False), rel))
            continue
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
