#!/usr/bin/env python3
"""Render and measure Rocket 60 parts.

A part that does not fit still renders cleanly, so every mating dimension is
measured from the STL rather than inferred from the parameter that was
supposed to produce it.
"""
import os, sys, tempfile

from scad_verify import REPO, render, measure, bore, volume

SCAD = os.path.join(REPO, "Rocket60.scad")

NAMES = {0: "test ring", 1: "neck", 2: "e-bay tube", 3: "chute bay tube",
         4: "ebay fwd bulkhead", 5: "ebay aft bulkhead", 6: "vega sled",
         7: "access door", 8: "bayonet ring", 9: "fin can", 10: "fin",
         11: "motor retainer", 12: "motor spacer"}

DOOR_W, DOOR_L = 36.0, 85.0
DOOR_GAP = 0.35   # per side

# Expected genus per part (topological invariant, immune to the
# "bit-identical bounding box, wrong interior" failure mode: a solid is
# genus 0, each through-hole/handle adds 1).
#   part 0: open-centre ring (1) + 3 bolt holes (3) = 4
#   part 1: open-centre spider (1) + 3 bolt holes (3) = 4
#   parts 2,3: plain tube = 1
#   part 4: disc + harness bore (1) = 1
#   part 5 (upright-servo redesign): disc + 4 through-passages = 4. Confirmed
#   by rendered top/bottom faces and the OpenSCAD Genus statistic: servo 1's
#   offset pocket (z=0..9) connects to the centred Ø12 shaft bore (z=8.95..12)
#   into one passage; servo 2's pocket connects to its horn slot the same
#   way into a second passage; the two Ø5 cord holes are clean, isolated
#   through-holes each. 4 distinct openings visible on both faces, matching
#   Genus: 4 from `openscad --export-format asciistl` stderr.
#   part 6: flat sled, 3 standoff bores (3) = 3
#   part 2 CHANGES: tube (1) + door opening (1) + switch hole (1) = 3
#   part 7: curved panel, 4 bolt holes (4) = 4
#   part 8: disc + 3 lug wedges + 1 through-bore (1) = 1. Confirmed by
#   rendered top/bottom views and a meridional-slice probe render: the
#   central Ø12 drive bore is the only opening (visible clean through both
#   faces), and each of the 3 lugs is solid material proud of the disc's
#   OD, not a hole or a separate shell - matching Genus: 1 from
#   `openscad --export-format asciistl` stderr.
GENUS = {0: 4, 1: 4, 2: 3, 3: 1, 4: 1, 5: 4, 6: 3, 7: 4, 8: 1}

MAX_Z = 250.0   # Bambu P1S usable Z, repo convention


# --- Z bands used to measure real mating surfaces -------------------------
# OpenSCAD's STL export puts vertices only at edge loops (Z-transitions),
# never mid-span on a plain cylinder wall, so a band must straddle the edge
# loop of the span it measures or bore() sees nothing there at all. Each
# band below reaches one true boundary of its span (z=0 base / z=10 top)
# while stopping short of the *other* span's boundary, so the reading isn't
# contaminated by a neighbouring diameter. Same convention as
# SHOULDER_SPIGOT_BAND/BOTTOM_SLICE_BASE_BAND in verify_nosecone.py, which
# likewise reach the spigot top (Z=115) and the base (Z=0) respectively.
TESTRING_FLANGE_BAND = (-0.01, 3.5)  # part 0: OD against the nosecone base
TESTRING_SPIGOT_BAND = (5.5, 10.01)  # part 0: coupler OD against a tube bore
NECK_FLANGE_BAND = (-0.01, 0.5)    # part 1: base face - flange OD and bore
NECK_SKIRT_BAND  = (23.5, 24.01)   # part 1: skirt top face - skirt OD
TUBE_BAND = (-0.01, 0.5)   # parts 2,3: base face carries both OD and bore
BULK_BAND = (-0.01, 0.5)   # parts 4,5: base face of the disc
RING_BAND = (-0.01, 0.5)   # part 8: base face, where the lug OD is widest


def checks(m):
    """Return list of (label, actual, expected, tolerance)."""
    c = []
    a = lambda p, k: m[p][k]

    if 0 in m:
        _, flange_od = bore(a(0, "stl"), *TESTRING_FLANGE_BAND)
        _, spigot_od = bore(a(0, "stl"), *TESTRING_SPIGOT_BAND)
        c += [("test ring flange OD vs nosecone base", flange_od, 59.98, 0.15),
              ("test ring coupler OD", spigot_od, 56.40, 0.15),
              ("test ring height", a(0, "height"), 10.0, 0.1),
              ("test ring zmin", a(0, "zmin"), 0.0, 0.05)]

    if 1 in m:
        _, flange_od = bore(a(1, "stl"), *NECK_FLANGE_BAND)
        _, skirt_od = bore(a(1, "stl"), *NECK_SKIRT_BAND)
        c += [("neck flange OD vs nosecone base", flange_od, 59.98, 0.15),
              ("neck height", a(1, "height"), 24.0, 0.1),
              ("neck zmin", a(1, "zmin"), 0.0, 0.05)]
        # Skirt must actually enter a body tube: measured skirt OD against
        # the measured test-ring coupler OD, never against R60_Coupler_OD.
        if 0 in m:
            _, ring_spigot = bore(a(0, "stl"), *TESTRING_SPIGOT_BAND)
            c += [("neck skirt matches test ring spigot",
                   skirt_od, ring_spigot, 0.10)]

    for p, want_len in ((2, 160.0), (3, 180.0)):
        if p in m:
            tube_id, tube_od = bore(a(p, "stl"), *TUBE_BAND)
            c += [("part %d length" % p, a(p, "height"), want_len, 0.1),
                  ("part %d OD" % p, tube_od, 60.0, 0.1),
                  ("part %d bore" % p, tube_id, 56.8, 0.1)]
            # A tube that will not accept the neck skirt is useless.
            if 1 in m:
                _, skirt_od = bore(a(1, "stl"), *NECK_SKIRT_BAND)
                c += [("part %d bore clears neck skirt" % p,
                       tube_id - skirt_od, 0.4, 0.15)]

    if 6 in m:
        c += [("sled length", a(6, "ymax") - a(6, "ymin"), 112.0, 0.2),
              ("sled width", a(6, "xmax") - a(6, "xmin"), 44.0, 0.2)]
        # The board must physically fit the tube bore lying on the sled.
        if 2 in m:
            tube_id, _ = bore(a(2, "stl"), *TUBE_BAND)
            stack = a(6, "height") + 21.0    # sled + Vega envelope
            c += [("sled + Vega clears e-bay bore", tube_id - stack, 27.8, 1.0)]

    if 7 in m:
        # The door's 85mm dimension runs along Z. Its Y extent is only the
        # chord depth of the curved panel (~8mm), so measure height, not ymax-ymin.
        c += [("door height", a(7, "height"), DOOR_L - 2 * DOOR_GAP, 0.15),
              ("door chord width", a(7, "xmax") - a(7, "xmin"),
               DOOR_W - 2 * DOOR_GAP, 0.15)]

    for p, want_h in ((4, 6.0), (5, 12.0)):
        if p in m:
            _, bulk_od = bore(a(p, "stl"), *BULK_BAND)
            c += [("part %d height" % p, a(p, "height"), want_h, 0.1)]
            # Must drop into a tube bore, measured against the real tube.
            if 2 in m:
                tube_id, _ = bore(a(2, "stl"), *TUBE_BAND)
                c += [("part %d fits e-bay bore" % p,
                       tube_id - bulk_od, 0.4, 0.15)]

    if 8 in m:
        _, ring_od = bore(a(8, "stl"), *RING_BAND)
        c += [("bayonet ring lug OD", ring_od, 58.0, 0.3)]
        if 3 in m:
            tube_id, _ = bore(a(3, "stl"), *TUBE_BAND)
            # Lugs must ENGAGE the chute tube bore, i.e. be larger than it.
            c += [("bayonet lugs engage chute bore",
                   ring_od - tube_id, 1.2, 0.4)]

    # Build volume, every part.
    for p in m:
        c += [("part %d fits %.0fmm Z" % (p, MAX_Z),
               m[p]["height"], min(m[p]["height"], MAX_Z), 0.01)]

    # Topology, every part with a recorded expectation.
    for p in m:
        if m[p].get("genus") is not None and p in GENUS:
            c += [("part %d genus" % p, m[p]["genus"], GENUS[p], 0)]

    return c


def main(argv):
    parts = [int(x) for x in argv[1:]] or sorted(NAMES)
    m = {}
    tmp = tempfile.mkdtemp(prefix="r60-")
    for p in parts:
        out = os.path.join(tmp, "part%d.stl" % p)
        g = render(SCAD, p, out)
        m[p] = measure(out, g)
        print("rendered %-2d %-20s  %.2f x %.2f x %.2f mm  %.1f cm3"
              % (p, NAMES.get(p, "?"), m[p]["xmax"] - m[p]["xmin"],
                 m[p]["ymax"] - m[p]["ymin"], m[p]["height"], volume(out)))
    bad = 0
    print()
    for (label, actual, expected, tol) in checks(m):
        ok = abs(actual - expected) <= tol
        bad += 0 if ok else 1
        print("%-4s %-42s %10.3f  want %.3f +/- %.3f"
              % ("OK" if ok else "FAIL", label, actual, expected, tol))
    print("\n%d check(s) failed" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
