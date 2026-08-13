#!/usr/bin/env python3
"""Render and measure Rocket 60 parts.

A part that does not fit still renders cleanly, so every mating dimension is
measured from the STL rather than inferred from the parameter that was
supposed to produce it.
"""
import os, sys, tempfile

from scad_verify import REPO, render, measure, bore, volume, _tris

SCAD = os.path.join(REPO, "Rocket60.scad")

NAMES = {0: "test ring", 1: "neck", 2: "e-bay tube", 3: "chute bay tube",
         4: "ebay fwd bulkhead", 5: "ebay aft bulkhead", 6: "vega sled",
         7: "access door", 9: "fin can", 10: "fin",
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
GENUS = {0: 4, 1: 4, 2: 3, 3: 1, 4: 1, 5: 4, 6: 3, 7: 4}
#   part 10: flat plate, no holes = 0
GENUS[10] = 0
#   part 9: fin can. NOT predicted -- rendered first (OpenSCAD stderr:
#   `Genus: 4`), then visually confirmed via top/bottom/isometric/half-
#   section PNG renders (openscad --render --projection=ortho): the MMT
#   bore is a genuine through-hole (top and bottom faces show the same
#   annulus+hole), and each of the 3 fin slots is a real window clean
#   through the outer wall (visible as an opening onto the tube's interior
#   in the isometric view, and cut on both sides in the half-section). 1
#   (MMT bore) + 3 (fin slots) = 4. The slot's inner face sits exactly at
#   x=R60_MMT_OD/2, tangent to the MMT wall with zero overlap; confirmed
#   this did not breach the MMT (render completed with CGAL Status:
#   NoError, and "MMT bore takes 29mm motor" below reads exactly 29.300,
#   not fattened or thinned by a stray cut). The two other centering rings
#   (mid, forward) are outside the slot's Z-span and add no extra handles.
GENUS[9] = 4

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
# Part 9's base face carries BOTH the outer tube (60/56.8) and the MMT
# (32/29.3), so one band yields both measurements: bore() returns
# (min_dia, max_dia) = (MMT bore, fin can OD).
FINCAN_BAND = (-0.01, 0.5)
# Slot Z-extent inside R60_FinCan() is Slot_Z=8 .. Slot_Z+Slot_L=8+90=98 (not
# exposed as R60Lib constants). The z=98 edge loop is where the slot cut
# meets the outer wall; filtering x>0 isolates the i=0 slot (the other two
# sit at 120/240deg, all x<0 there), and it's clear of both the aft
# centering ring (z=6..9) and the mid ring (z=114), so nothing else
# contaminates the loop. See FINCAN_SLOT_WIDTH below.
FINCAN_SLOT_TOP_Z = 98.0


def fincan_slot_width(stl):
    """Measured width of the un-rotated (i=0) fin slot, read directly off
    the z=FINCAN_SLOT_TOP_Z edge loop where the cut meets the outer wall.
    x>0 isolates the i=0 slot from the other two (120/240deg, all x<0
    there)."""
    ys = [y for tri in _tris(stl) for (x, y, z) in tri
          if abs(z - FINCAN_SLOT_TOP_Z) <= 0.1 and x > 0]
    if not ys:
        raise RuntimeError(
            "no geometry at fin can slot edge loop z=%.1f" % FINCAN_SLOT_TOP_Z)
    return 2 * max(abs(y) for y in ys)


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

    if 9 in m:
        mmt_id, can_od = bore(a(9, "stl"), *FINCAN_BAND)
        c += [("fin can length", a(9, "height"), 228.0, 0.2),
              ("fin can OD", can_od, 60.0, 0.1),
              ("MMT bore takes 29mm motor", mmt_id, 29.3, 0.15),
              ("fin can fits 250mm Z", a(9, "height"), min(a(9, "height"), 250.0), 0.01)]
    if 10 in m:
        c += [("fin root chord", a(10, "xmax") - a(10, "xmin"), 90.0, 0.2),
              ("fin thickness", a(10, "zmax") - a(10, "zmin"), 4.0, 0.1)]

    if 9 in m and 10 in m:
        # The brief promises "the measured tab-vs-slot check" but its own
        # checks() snippet only compares fin dimensions to the constants
        # that produced them (rule 4 violation). bore() cannot answer this
        # -- it treats a Z-band as one (bore, OD) pair about the axis, not
        # a Y-extent -- so read the slot's actual edge-loop vertices and
        # compare the fin can's real slot to the fin's real thickness.
        slot_w = fincan_slot_width(a(9, "stl"))
        c += [("fin slot width fits fin thickness",
               slot_w - a(10, "height"), 0.2, 0.1)]

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
