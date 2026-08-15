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

SCOPE (10th review, revising the 9th review's decision below): the three
tracked Markdown docs get the FULL positive-needle treatment (a doc must
contain the model's CURRENT figure, in the doc's own known phrasing).
Rocket60.scad/R60Lib.scad do NOT get that same treatment, for the reason
the 9th review gave and this docstring still keeps below -- but ARE now
covered by a narrower, DENY-LIST check (STALE_SCAD_NEEDLES): a short list
of specific, already-superseded number/phrase strings (e.g. "955 m/s",
"4.6x the H182R") that must never reappear in either file. This is the
honest middle ground the 10th review's own task asked for: a .scad
comment's freeform prose is still too unstructured for a POSITIVE
"contains the current figure" check to anchor on safely (the reason
below still holds), but a NEGATIVE "does not contain this specific,
already-dead number" check has no such ambiguity -- there is no
legitimate reason "955 m/s" (this file's own now-corrected flutter
figure) should ever appear in either .scad file again, in any sentence,
historical or current, once every existing occurrence is fixed (a
historical illustration can and does still cite the BARE number, e.g.
"63->0.869->955", without its unit suffix -- the deny string is scoped
to the exact "955 m/s"/"959 m/s" phrasing the stale CURRENT-claim
sentences used, confirmed zero false positives against the corpus as
fixed this round). This closes the SPECIFIC failure this task's own
review found (a 62% error surviving a correction commit) without
claiming the broader problem below is solved.

Original 9th-review reasoning, still the reason this file does not get
the full positive-needle treatment: unlike the three tracked docs, which
publish a small, closed set of figures in a fairly formulaic way (a
table row, a bolded headline number), .scad comments quote model numbers
embedded in long, freeform design-rationale prose with no consistent
delimiter this script could anchor a POSITIVE needle to without a real
risk of matching the wrong sentence (or missing the real one) -- the
CHECKS table's exact-string approach only works because the three
Markdown docs are edited with those exact strings in mind; a .scad
comment is not. Coverage of the CURRENT figure being present and correct
there is still manual: a reviewer reading a changed constant should
re-read the comments around it, the same expectation this codebase
already places on every other piece of restated-per-rule-4 commentary.
Numbers NOT covered by either mechanism (say honestly which): any
.scad-comment figure that was NEVER wrong (so never made this deny
list) but silently drifts in some FUTURE change -- e.g. if the G80T
margin moves again, "1.56 cal" in these files' comments could go stale
exactly the way "1.46"/"1.45" did twice before, and nothing here would
catch it until it is added to STALE_SCAD_NEEDLES retroactively, after a
review finds it. The deny list only ever grows by finding a NEW
staleness instance, the same way GENUS/STL_VOL entries in this repo's
own verify scripts are re-derived after the fact, not predicted in
advance.
"""
import os, re, shutil, subprocess, sys, tempfile

from scad_verify import render

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL = os.path.join(REPO, "tools", "rocket60_model.py")
SCAD = os.path.join(REPO, "Rocket60.scad")
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

# SCAD comment staleness -- deny list, not a positive-needle check (see
# this module's own SCOPE docstring for why). Each string is a figure
# already found stale in Rocket60.scad/R60Lib.scad's own freeform
# comments and fixed this round; it must never reappear in either file.
# Grows only when a NEW instance is found and fixed -- see the docstring.
SCAD_FILES = [
    os.path.join(REPO, "Rocket60.scad"),
    os.path.join(REPO, "R60Lib.scad"),
]
STALE_SCAD_NEEDLES = [
    "955 m/s",   # superseded Vf (mean-chord t/c bug) -- corrected 589 m/s
    "959 m/s",   # an even earlier superseded Vf, predating the 8th
                  # review's MMT_r correction
    "4.6x the H182R",   # superseded flutter ratio (was actually H182R's
                          # own ratio at the wrong Vf, per this file's own
                          # 10th-review fix)
    "4.9x the H135W",   # superseded flutter ratio, same fix
]

_bad = 0


def bad(ok):
    global _bad
    if not ok:
        _bad += 1
    return "OK" if ok else "FAIL"


def run_model():
    """Run rocket60_model.py once and return (stdout, returncode).

    (9th review, finding: this used to swallow returncode==1 as an
    acceptable outcome -- rocket60_model.py's OWN convention (its own
    `bad()` counter, `sys.exit(1 if _bad else 0)`) is that 1 means a REAL
    stability regression: margin below MIN_MARGIN_CAL, a rail-exit too
    slow, or insufficient flutter margin, the entire purpose that counter
    exists for. Treating 1 as "not a crash, carry on" meant this script
    happily parsed the FAILING run's own printed numbers, found them
    textually present in the docs (they are real numbers, just numbers a
    design should not ship with), and reported every doc-sync row OK and
    exited 0 -- a stability regression passed this gate silently.
    Mutation-tested: temporarily raising MIN_MARGIN_CAL 1.0->2.0 makes the
    model itself report "3 check(s) failed" (rc=1); this script, unfixed,
    still printed OK on all 17 rows and exited 0.
    Only an actual crash (any OTHER returncode -- a Python traceback also
    exits 1, so this alone can no longer tell "regression" from "crash",
    but main() below now reports the model's own rc regardless of which
    it was, so neither case reads as silent success) still raises here."""
    r = subprocess.run([sys.executable, MODEL], capture_output=True,
                        text=True, cwd=os.path.dirname(MODEL), timeout=120)
    if r.returncode not in (0, 1):
        raise RuntimeError("rocket60_model.py crashed:\n%s" % r.stderr[-2000:])
    return r.stdout, r.returncode


def vega_rod_length():
    """R60Lib.scad's own derived R60_Vega_RodLength (9th review, finding
    3), read off its echo() line by rendering Rocket60.scad once (part 0,
    the test ring -- the cheapest real part, chosen only to have a valid
    dispatch; R60Lib.scad's own echo() runs at file-scope so it fires
    regardless of which part is actually rendered) with
    scad_verify.render()'s return_log=True, same idiom
    verify_motordummy29.py already uses to cross-check MotorDummy29.scad's
    own echoed ballast masses. Deliberately NOT re-derived from
    R60_Vega_Rail_L/RodInsert_h/etc independently in Python: that would
    grow a second, drift-prone copy of the same four-term formula
    RodSweep_Sled() (r60_assembly.scad) and R60_Vega_RodLength
    (R60Lib.scad) already share -- parsing the ONE echo() the .scad file
    itself prints keeps this a read, not a re-derivation."""
    tmp = tempfile.mkdtemp(prefix="docsync-")
    try:
        out = os.path.join(tmp, "part0.stl")
        _, err = render(SCAD, 0, out, return_log=True)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    m = re.search(r"R60_Vega_RodLength[^:]*:\s*([\d.]+)\s*mm", err)
    if not m:
        raise RuntimeError(
            "could not find R60Lib.scad's own R60_Vega_RodLength echo in "
            "Rocket60.scad's render output -- its echo() text changed; "
            "update this regex")
    return float(m.group(1))


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
    # Flutter margin table format (task 5 fix -- flutter_Vf() itself, and
    # this gate, were re-scoped from a single "Per-motor: G80T Xx, H182R
    # Xx, H135W Xx" summary line to a per-motor floor table, one row per
    # motor: "   G80T-14A     Vmax= 123 m/s  Vf/Vmax= 4.8x  (OK)").
    nums["flutter_ratio"] = {}
    for m in re.finditer(
            r"^\s*(G80T-14A|H182R-14A|H135W-14A)\s+Vmax=\s*\d+ m/s\s+"
            r"Vf/Vmax=\s*([\d.]+)x", out, re.M):
        nums["flutter_ratio"][m.group(1)] = float(m.group(2))
    if not nums["flutter_ratio"]:
        del nums["flutter_ratio"]
    return nums


def doc_has(path, *needles):
    """(10th review) Whitespace-normalised: a needle that spans a line
    wrap in the doc's own hand-wrapped prose (confirmed real, not
    hypothetical -- "G80T 4.7×, H182R 2.9×, H135W 3.1×", this review's
    own new flutter needle, broke across exactly one such wrap in BOTH
    R60-PrintSettings.md and the STL README, at a different point in
    each) used to read as "missing" even though a human reads it as one
    unbroken sentence -- a false failure that would have forced prose
    reflowed around the checker's own literal newlines, backwards from
    what this gate is for. Collapsing all whitespace runs (spaces,
    newlines) to a single space in BOTH the doc text and each needle
    before comparing makes the check match what a reader sees, not the
    doc's own line-wrap column -- strictly safer than the old plain `in`
    check (a match here is always also a real match on the substance;
    only a spurious near-miss caused by wrapping start passing, never a
    genuinely absent figure)."""
    with open(path) as f:
        text = re.sub(r"\s+", " ", f.read())
    return [n for n in needles if re.sub(r"\s+", " ", n) not in text]


def stale_bold_cal(path, expected_cals):
    """Bold two-decimal ``**X.XX cal**`` static-margin figures in `path`
    that are NOT one of `expected_cals` (9th review, finding: doc_has()
    above is presence-only -- it only ever asserts the CURRENT figure
    exists somewhere in the doc, never that a SUPERSEDED one does not
    also survive, bolded, in an adjacent paragraph, both reading as "the
    current margin". This was not a hypothetical: R60-PrintSettings.md
    carried "**1.47 cal**" (the fin-sizing section) two paragraphs after
    "**1.46 cal**" (the model's real, current figure, correct at the top
    of the same doc) had already been corrected -- doc_has() passed every
    row regardless, because 1.46 cal WAS present somewhere.

    Scoped to bold two-decimal "cal" margin figures specifically, not
    every published number: inspection of all three tracked docs' own
    prose shows a consistent convention this check leans on --
    - the CURRENT headline figure is always **bolded**; a superseded one
      is always plain prose, usually explicitly labelled ("the
      previously-published 1.53 cal (itself already a correction of an
      inflated 1.61 cal)") -- so scanning bold-only, not every occurrence,
      does not flag legitimate historical narration;
    - every model margin prints to exactly two decimals (e.g. "1.46"),
      while the one PHYSICAL constant sharing the same "cal" unit (the
      1.0 cal minimum, a design floor, not a model output) prints to one
      ("1.0"), so `\\d\\.\\d\\d cal` cannot collide with it.
    Confirmed empirically against the current corpus: this pattern has
    zero false positives once the live 1.47 defect above is fixed (every
    other bolded two-decimal cal figure in all three docs is one of the
    six real margin_cal/marg_bo_cal values nums() parses).

    NOT extended to grams/mm/m-per-s/other units: those have no bold-vs-
    plain convention in these docs (R60-PrintSettings.md's own §9 "Fin
    sizing" narration bolds nothing there) and a blanket numeric scan
    across a doc this narrative would collide constantly with unrelated
    hardware dimensions (bolt lengths, wall thicknesses, rail sizes) that
    happen to share a unit suffix -- a check that fires on legitimate
    prose is worse than no check, so those stay outside this net; a
    reviewer auditing free-form staleness in those units has to read the
    prose, the same as before this fix."""
    with open(path) as f:
        text = f.read()
    found = set(float(m) for m in re.findall(r"\*\*(\d\.\d\d) cal\*\*", text))
    return sorted(found - expected_cals)


def main():
    out, model_rc = run_model()
    if model_rc != 0:
        m = re.search(r"\n(\d+) check\(s\) failed", out)
        n = m.group(1) if m else "an unknown number of"
        print("%s rocket60_model.py itself reports %s failing check(s) -- "
              "a real design regression (margin/rail-exit/flutter), not a "
              "doc/model text mismatch; the figures below may still read "
              "as textually in sync with the docs (they are real numbers "
              "the model printed), but do not trust any of them until the "
              "model's own run is clean"
              % (bad(False), n))
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
    # (10th review) Flutter Vf/per-motor-ratio needles for the OTHER two
    # tracked docs -- R60-PrintSettings.md and STL Files/Rocket60/
    # README.md both now publish Vf and a per-motor ratio line too (a
    # "G80T 4.7×, H182R 2.9×, H135W 3.1×" short form, not the spec doc's
    # own "4.7× the G80T's ~126 m/s Vmax" long form -- these are two
    # different prose conventions this gate has to match separately, not
    # one needle reused). Before this, a doc could publish a STALE Vf
    # (955 m/s survived one whole correction commit in
    # R60-PrintSettings.md's own §3, two sections away from its own
    # corrected §9 figure) with nothing here to catch it -- only the spec
    # doc's own per-motor ratio needles existed, and neither of THOSE
    # ever spelled out "589 m/s"/"955 m/s" as a bare figure to check
    # against.
    vf_needle = "%d m/s" % nums["Vf_ms"]
    short_ratio_needle = "G80T %.1f×, H182R %.1f×, H135W %.1f×" % (
        nums["flutter_ratio"]["G80T-14A"], nums["flutter_ratio"]["H182R-14A"],
        nums["flutter_ratio"]["H135W-14A"])

    # (9th review, finding 3) R60Lib.scad's own derived Vega rod length --
    # a SCAD echo, not a rocket60_model.py figure, so it is fetched
    # separately (vega_rod_length()) and folded into the same needle
    # convention as everything else nums() reads.
    rod_len = vega_rod_length()
    rod_len_needle = "%.1f mm" % rod_len

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
            ("Vega rod length (R60_Vega_RodLength)", (rod_len_needle,)),
            ("flutter: Vf and per-motor ratios",
             (vf_needle, short_ratio_needle)),
        ],
        "STL Files/Rocket60/README.md": [
            ("G80T-14A liftoff/margin/rail-exit",
             (grams(g80t), cal(g80t), "%.1f m/s" % g80t["rail_exit_ms"])),
            ("H182R-14A liftoff/margin", (grams(h182r), cal(h182r))),
            ("H135W-14A liftoff/margin", (grams(h135w), cal(h135w))),
            ("flutter: Vf and per-motor ratios",
             (vf_needle, short_ratio_needle)),
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

    # Every bolded two-decimal cal figure that is genuinely current, ANY
    # doc, ANY motor, loaded or burnout margin -- the union, not a per-doc
    # subset, since a doc may legitimately bold any of these six values
    # (see stale_bold_cal()'s own docstring for why this check is scoped
    # to this one unit/format).
    expected_cals = set()
    for mo in (g80t, h182r, h135w):
        expected_cals.add(round(mo["margin_cal"], 2))
        expected_cals.add(round(mo["marg_bo_cal"], 2))

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

        stale = stale_bold_cal(path, expected_cals)
        ok = not stale
        print("%-4s %s: no stale bold cal figures %s" % (bad(ok), rel,
              "" if ok else "-- found %s cal, bolded, not a current "
              "margin/marg_bo for any motor (stale/superseded figure "
              "still presented as current)" % stale))

    # SCAD deny-list (10th review) -- see this module's own SCOPE
    # docstring and STALE_SCAD_NEEDLES for what this does and does not
    # guarantee.
    for path in SCAD_FILES:
        rel = os.path.relpath(path, REPO)
        if not os.path.exists(path):
            print("%s %s: file not found -- cannot verify it" % (bad(False), rel))
            continue
        with open(path) as f:
            text = f.read()
        found = [n for n in STALE_SCAD_NEEDLES if n in text]
        ok = not found
        print("%-4s %s: no stale flutter figures %s" % (bad(ok), rel,
              "" if ok else "-- found %s (already-superseded figure(s) "
              "reappeared)" % found))

    print("\n%d check(s) failed" % _bad)
    return 1 if _bad else 0


if __name__ == "__main__":
    sys.exit(main())
