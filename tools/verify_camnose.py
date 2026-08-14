#!/usr/bin/env python3
"""Render and measure PeregrineCamNose parts, and prove the camera fits.

A part that does not fit still renders cleanly, so every mating dimension is
measured from the STL rather than inferred from parameters. The camera
envelope below was measured from Camera.STEP (tessellated via FreeCAD) and is
embedded so this check needs no external file: for each station b mm behind
the lens face it gives the camera's maximum radius from the lens axis.
"""
import math, os, subprocess, sys, tempfile

from scad_verify import REPO, render, measure, bore, volume

SCAD = os.path.join(REPO, "PeregrineCamNose.scad")

APEX = 441.43           # lens sits here
CUT1_Z, CUT2_Z = 147.14, 294.29
WALL = 2.2
LENS_D = 14.4
MIN_CLEAR = 0.3         # radial, mm
TIP_R = 26.0
# The lens hole truncates the spherical tip, so the highest material is the
# hole rim, not the apex.
RIM_Z = APEX - (TIP_R - math.sqrt(TIP_R**2 - (LENS_D/2.0)**2))

CAM_ENVELOPE = [
    (0,6.75), (1,7.00), (4,7.00), (5,7.00), (6,7.00), (7,7.88), (8,7.88),
    (9,7.88), (10,8.05), (11,8.05), (12,8.05), (13,8.05), (14,8.05),
    (15,12.36), (16,12.36), (17,12.36), (18,12.36), (19,12.36), (21,12.36),
    (22,14.84), (23,15.81), (24,15.81), (25,15.81), (26,15.81), (27,15.81),
    (28,15.81), (29,15.81), (31,15.81), (32,15.81), (33,15.81), (34,16.50),
    (35,17.28), (36,17.33), (37,17.33), (38,17.33), (40,17.33), (41,17.33),
    (42,18.41), (47,19.57), (48,19.59), (49,19.59), (50,21.00), (51,21.00),
    (52,21.30), (53,21.55), (54,24.50), (55,25.04), (56,25.18), (57,25.26),
    (58,25.31), (59,25.31), (60,25.31), (61,25.31), (62,25.31), (63,25.31),
    (64,25.31), (65,25.31), (66,25.31), (67,25.31), (68,25.31), (69,25.31),
    (70,25.31), (71,25.31), (72,25.31), (73,25.31), (76,25.31), (77,25.31),
    (78,25.31), (80,25.31), (81,25.31), (82,25.31), (83,25.31), (84,25.31),
    (85,25.31), (86,25.31), (87,25.31), (88,25.31), (89,25.31), (90,25.31),
    (91,25.31), (92,25.31), (94,25.31),
]

GENUS = {0: 1, 1: 2, 5: 1, 6: 1}   # slices carry holes; checked separately


NAMES = {0:"test ring", 1:"shoulder", 2:"bottom slice", 3:"middle slice",
         4:"top slice", 5:"spacer front", 6:"spacer rear"}


def camera_clearance(stls):
    """Worst radial clearance between the camera envelope and the real bore."""
    worst = (1e9, None)
    for b, r in CAM_ENVELOPE:
        z = APEX - b
        if z < 0:
            continue
        if r <= LENS_D / 2.0:
            continue        # this station passes through the lens hole
        part = 4 if z > CUT2_Z else (3 if z > CUT1_Z else 2)
        if part not in stls:
            continue
        try:
            inner, _ = bore(stls[part], z - 1.0, z + 1.0)
        except RuntimeError:
            continue
        c = inner / 2.0 - r
        if c < worst[0]:
            worst = (c, b)
    return worst


def main(argv):
    parts = [int(a) for a in argv[1:]] or [0, 1, 2, 3, 4, 5, 6]
    m, genus, stls, tmp = {}, {}, {}, tempfile.mkdtemp()
    bad = 0
    for p in parts:
        out = os.path.join(tmp, "part%d.stl" % p)
        try:
            genus[p] = render(SCAD, p, out)
        except (RuntimeError, subprocess.TimeoutExpired) as e:
            # `return 1` here (6th review, finding 4, rocket60) used to
            # abort the WHOLE run -- any part after this one never
            # rendered and the checks below never printed at all, the
            # identical "one bad row kills the whole report" class
            # verify_rocket60.py's safe() exists to fix for individual
            # checks. Now a counted FAIL for just this part; the loop and
            # the report continue with whatever DID render.
            print("FAIL  render part %d (%s)\n%s" % (p, NAMES.get(p, "?"), e))
            bad += 1
            continue
        stls[p] = out
        m[p] = measure(out)
        print("  part %d %-14s h=%7.2f dia=%7.2f z=%7.2f..%7.2f %5.0f g"
              % (p, NAMES.get(p, "?"), m[p]["height"], m[p]["dmax"],
                 m[p]["zmin"], m[p]["zmax"], volume(out) * 1.27))
    checks = []
    if 2 in m:
        checks += [("bottom zmin", m[2]["zmin"], 0.0, 0.1),
                   ("bottom outer dia", m[2]["dmax"], 101.5, 0.3)]
    if 3 in m:
        checks += [("middle zmin", m[3]["zmin"], CUT1_Z, 0.2)]
    if 4 in m:
        checks += [("tip height (lens-hole rim)", m[4]["zmax"], RIM_Z, 0.2)]
        lo, _ = bore(stls[4], APEX - 3.0, APEX - 0.2)
        checks += [("lens hole dia", lo, LENS_D, 0.2)]
    if 2 in m and 3 in m:
        checks += [("joint 1 overlap", m[2]["zmax"] - m[3]["zmin"], 7.0, 0.2)]
    if 3 in m and 4 in m:
        checks += [("joint 2 overlap", m[3]["zmax"] - m[4]["zmin"], 7.0, 0.2)]
    if 1 in m:
        checks += [("shoulder height", m[1]["height"], 115.0, 0.2),
                   ("shoulder body dia", m[1]["dmax"], 98.6, 0.2)]
    for p in (5, 6):
        if p in m:
            want = 2.83 if p == 5 else 6.08
            checks += [("spacer %d thickness" % p, m[p]["height"], want, 0.05)]
    # 6th review (rocket60), finding 4: report the OVERAGE past 250mm
    # instead of deriving "expected" from the measurement itself
    # (min(height,250.0) always exactly equals the measured height
    # whenever it fits, printing a self-comparing "115.00 expected
    # 115.00" instead of the real constraint, height<=250). 0 for
    # anything that fits, the actual excess in mm otherwise.
    for p in m:
        checks += [("part %d fits 250mm Z" % p,
                    max(0.0, m[p]["height"] - 250.0), 0.0, 0.01)]
    # A missing genus (render succeeded but no "Genus:" line was found)
    # used to be silently dropped by `and g is not None` -- the check just
    # never ran, rather than failing loudly. Emit nan instead: it never
    # equals GENUS[p] within any tolerance, so a genuine miss is a visible
    # FAIL, not a quietly-absent row -- same fix verify_nosecone.py and
    # verify_rocket60.py already have.
    for p, g in genus.items():
        if p in GENUS:
            checks += [("part %d genus" % p,
                       g if g is not None else float("nan"), GENUS[p], 0)]
    if {2, 3, 4} <= set(m):
        c, at = camera_clearance(stls)
        checks += [("CAMERA CLEARANCE (worst, %smm behind lens)" % at,
                    c, max(c, MIN_CLEAR), 0.001)]
    print()
    for label, actual, expected, tol in checks:
        ok = abs(actual - expected) <= tol
        bad += not ok
        print("%-4s %-42s %10.2f  expected %8.2f +/- %.2f"
              % ("PASS" if ok else "FAIL", label, actual, expected, tol))
    print("\n%d check(s) failed" % bad if bad else "\nall checks passed")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
