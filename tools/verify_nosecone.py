#!/usr/bin/env python3
"""Render and measure PeregrineNoseCone parts.

A part that does not fit still renders cleanly, so every mating dimension
is measured from the STL rather than inferred from parameters.
"""
import os, subprocess, sys, tempfile

from scad_verify import REPO, render, measure, bore, volume, overshoot

SCAD = os.path.join(REPO, "PeregrineNoseCone.scad")


NAMES = {0: "test ring", 1: "shoulder", 2: "bottom slice",
         3: "middle slice", 4: "top slice", 5: "ring lower", 6: "ring upper"}

# Expected genus per part (topological invariant, immune to the
# "bit-identical bounding box, wrong interior" failure mode: a solid
# is genus 0, each through-hole/handle adds 1). Ring genus 4 = 3 spoke
# gaps + 1 eyelet; a webbed eyelet collapses two of those gaps into
# the eyelet cavity and reads 6 instead.
GENUS = {0: 1, 1: 2, 2: 1, 3: 1, 4: 0, 5: 4, 6: 4}

# Z bands (in each part's own exported frame) used to measure real mating
# surfaces instead of trusting the design constants they are supposed to
# match. Chosen to sit within a single wall/flange span so bore() sees a
# clean, near-constant diameter rather than a taper.
FLANGE_TOP_BAND = {2: (189.0, 190.4), 3: (372.0, 373.7)}  # ring seats here
SHOULDER_SPIGOT_BAND = (105.0, 115.0)   # part 1: spigot OD
BOTTOM_SLICE_BASE_BAND = (0.0, 5.0)     # part 2: coupler bore at the base


def checks(m):
    """Return list of (label, actual, expected, tolerance)."""
    c = []
    a = lambda p, k: m[p][k]
    if 2 in m:
        c += [("bottom zmin", a(2, "zmin"), 0.0, 0.1),
              ("bottom outer dia", a(2, "dmax"), 101.5, 0.3)]
    if 3 in m:
        c += [("middle zmin", a(3, "zmin"), 183.33, 0.2)]
    if 4 in m:
        c += [("APEX HEIGHT", a(4, "zmax"), 550.0, 0.15)]
    if 2 in m and 3 in m:
        c += [("joint 1 overlap", a(2, "zmax") - a(3, "zmin"), 7.0, 0.2)]
    if 3 in m and 4 in m:
        c += [("joint 2 overlap", a(3, "zmax") - a(4, "zmin"), 7.0, 0.2)]
    if 1 in m:
        c += [("shoulder height", a(1, "height"), 115.0, 0.2),
              ("shoulder body dia", a(1, "dmax"), 98.6, 0.2)]
    if 5 in m:
        c += [("ring lower dia", a(5, "dmax"), 82.0, 0.2)]
    if 6 in m:
        c += [("ring upper dia", a(6, "dmax"), 52.0, 0.2)]
    # 6th review (rocket60), finding 4: report the OVERAGE past 250mm
    # instead of deriving "expected" from the measurement itself
    # (min(height,250.0) is always exactly the measured height whenever it
    # fits, so a healthy part printed a self-comparing "177.000 want
    # 177.000" instead of the real constraint, height<=250). 0 for
    # anything that fits, the actual excess in mm otherwise -- legible
    # either way. overshoot() (scad_verify) instead of a bare
    # max(0.0, ...): a nan height (a degenerate, zero-triangle mesh,
    # measure()'s own convention) must fail this loudly, not silently
    # compare as a 0mm overshoot -- see that helper's own docstring.
    for p in m:
        c += [("part %d fits 250mm Z" % p, overshoot(m[p]["height"], 250.0), 0.0, 0.01)]

    # --- interior checks: bounding box / OD alone cannot see these ---

    # 1. Genus per part. Catches an interior defect (e.g. a webbed
    # eyelet) that leaves every zmin/zmax/height/dmax check untouched.
    # FIXED (defect 3a): scad_verify.measure() now always injects a
    # "genus" key (defaulting to None when render() found no "Genus:"
    # line), so the old `"genus" in m[p]` guard was always True regardless
    # of whether a real value was found, and `abs(None - GENUS[p])` raised
    # TypeError instead of failing cleanly. A missing genus is now a loud
    # FAIL (actual=nan, never <= any tolerance) instead of a crash or a
    # silently-skipped check -- same fix verify_rocket60.py already has.
    for p in m:
        if p in GENUS:
            g = m[p].get("genus")
            c += [("part %d genus" % p,
                   g if g is not None else float("nan"), GENUS[p], 0)]

    # 2. Ring-in-flange clearance, MEASURED bore vs MEASURED ring OD
    # (never against the hardcoded 82.0/52.0 design constants, which is
    # exactly what let an interference fit pass the old gate).
    if 2 in m and 5 in m:
        zlo, zhi = FLANGE_TOP_BAND[2]
        flange_bore, _ = bore(a(2, "stl"), zlo, zhi)
        c += [("ring5-in-flange clearance", flange_bore - a(5, "dmax"), 0.45, 0.15)]
    if 3 in m and 6 in m:
        zlo, zhi = FLANGE_TOP_BAND[3]
        flange_bore, _ = bore(a(3, "stl"), zlo, zhi)
        c += [("ring6-in-flange clearance", flange_bore - a(6, "dmax"), 0.45, 0.15)]

    # 3. Shoulder spigot: its own OD, and its measured clearance in the
    # bottom slice's actual coupler bore (not the Peregrine_Coupler_OD
    # constant it is only supposed to match).
    if 1 in m:
        _, spigot_od = bore(a(1, "stl"), *SHOULDER_SPIGOT_BAND)
        c += [("shoulder spigot dia", spigot_od, 96.7, 0.1)]
        if 2 in m:
            bottom_bore, _ = bore(a(2, "stl"), *BOTTOM_SLICE_BASE_BAND)
            c += [("spigot-in-bottom-bore clearance", bottom_bore - spigot_od, 0.4, 0.1)]
    return c


def main(argv):
    parts = [int(a) for a in argv[1:]] or [0, 1, 2, 3, 4, 5, 6]
    m, tmp = {}, tempfile.mkdtemp()
    bad = 0
    for p in parts:
        out = os.path.join(tmp, "part%d.stl" % p)
        try:
            genus = render(SCAD, p, out)
        except (RuntimeError, subprocess.TimeoutExpired) as e:
            # FIXED (defect 3c): consolidation gave render() a 900s
            # subprocess timeout it never had before, but this handler
            # only caught RuntimeError -- a slow render now raises
            # subprocess.TimeoutExpired instead, and this module didn't
            # even import subprocess to name it in an except clause. A
            # slow render died on a raw traceback rather than this FAIL.
            # `return 1` here (6th review, finding 4, rocket60) used to
            # abort the WHOLE run -- any part after this one never
            # rendered and checks() never printed at all, the identical
            # "one bad row kills the whole report" class safe() exists to
            # fix for individual checks. Now a counted FAIL for just this
            # part; the loop and the report continue.
            print("FAIL  render part %d (%s)\n%s" % (p, NAMES.get(p, "?"), e))
            bad += 1
            continue
        # genus passed straight to measure() (defect 3a) -- it already
        # sets "genus": genus (None when render() found no "Genus:" line)
        # and "stl": stl in its own return dict, so the two follow-up
        # assignments this used to do here (`m[p]["stl"] = out`,
        # `if genus is not None: m[p]["genus"] = genus`) were redundant at
        # best and, for "genus", part of why a missing value was
        # indistinguishable from a found one downstream.
        m[p] = measure(out, genus)
        m[p]["vol"] = volume(out)
        print("  part %d %-14s h=%7.2f  dia=%7.2f  z=%7.2f..%7.2f  %5.0f g PETG"
              % (p, NAMES.get(p, "?"), m[p]["height"], m[p]["dmax"],
                 m[p]["zmin"], m[p]["zmax"], m[p]["vol"] * 1.27))
    print()
    for label, actual, expected, tol in checks(m):
        ok = abs(actual - expected) <= tol
        bad += not ok
        print("%-4s %-26s %10.2f  expected %8.2f +/- %.2f"
              % ("PASS" if ok else "FAIL", label, actual, expected, tol))
    print("\n%d check(s) failed" % bad if bad else "\nall checks passed")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
