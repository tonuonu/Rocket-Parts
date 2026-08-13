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
         7: "access door", 8: "spring carrier", 9: "fin can", 10: "fin",
         11: "motor retainer", 12: "motor spacer"}

DOOR_W, DOOR_L = 36.0, 85.0
DOOR_GAP = 0.35   # per side

# Expected genus per part (topological invariant, immune to the
# "bit-identical bounding box, wrong interior" failure mode: a solid is
# genus 0, each through-hole/handle adds 1).
#   part 0: open-centre ring (1) + 3 bolt holes (3) = 4
#   part 1: open-centre spider (1) + 3 bolt holes (3) = 4
#   parts 2,3: plain tube = 1 (part 3's original value -- superseded below,
#   after the shear pin holes were added)
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
#   part 9: fin can, RE-DERIVED after adding the retainer bolt bosses (was
#   4 before the bosses too, but re-checked rather than carried forward, per
#   instruction). Rendered first (OpenSCAD stderr: `Genus: 4`, unchanged),
#   then visually re-confirmed via fresh top/bottom/isometric PNG renders:
#   top face (forward end) shows only the plain MMT-bore ring, no boss
#   holes visible there at all; bottom face (aft end) shows that same ring
#   PLUS 3 small dots at the bolt circle -- present on one face, absent
#   from the other, confirming the boss inserts are blind pockets, not
#   through-holes, so they add zero handles. The MMT bore (open top-to-
#   bottom, confirmed by the identical hole on both end faces) and the 3
#   fin slots (confirmed as real through-windows previously) are unchanged
#   by this edit. 1 (MMT bore) + 3 (fin slots) + 0 (3 blind boss inserts)
#   = 4.
GENUS[9] = 4
#   part 11: retainer, RE-DERIVED after adding the 3 bolt clearance holes
#   (was 1 before them). Rendered first (OpenSCAD stderr: `Genus: 4`), then
#   visually confirmed via top/bottom/isometric PNG renders: unlike part
#   9's blind bosses, all 3 bolt holes appear as see-through openings on
#   BOTH the top and bottom face at matching positions -- genuine through-
#   holes, not blind pockets. 1 (centre bore) + 3 (through bolt holes) = 4.
GENUS[11] = 4
#   part 12: spacer tube = 1 (unchanged, not touched by this round)
GENUS[12] = 1
#   part 3: chute bay tube, RE-DERIVED after adding the 2 shear pin holes
#   (was 1, a plain tube). Rendered first (OpenSCAD stderr: `Genus: 3`),
#   then visually confirmed on a thin Z-band section slice at the pin
#   holes' Z (diag, not part of the deliverable): the wall segment at each
#   +-X hole location is split into two disconnected pieces by a clean
#   gap spanning the FULL wall thickness (both the bore-side and OD-side
#   faces are cut), confirming each is a genuine through-hole, not a
#   surface scratch or blind mark. 1 (tube) + 2 (through pin holes) = 3.
GENUS[3] = 3
#   part 5: e-bay aft bulkhead, RE-CONFIRMED after adding the aft skirt +
#   2 shear pin holes (stayed 4, same as the prior upright-servo design --
#   NOT carried forward blindly, re-rendered and re-checked because the
#   geometry changed even though the number didn't). Rendered (OpenSCAD
#   stderr: `Genus: 4`), then visually confirmed on a sliced side-profile
#   diagnostic: the 2 new pin holes are blind (do not reach the shaft
#   bore, the horn slot, or each other), so they add zero handles, same
#   as part 9's blind boss inserts. This render also CAUGHT a real defect
#   before this value was recorded: the first skirt draft left servo 2's
#   horn slot dead-ending under the new solid skirt material (observed
#   genus 3, not 4, on that draft) -- fixed by extending the horn slot cut
#   through the skirt to the new aft face, same treatment as the shaft
#   bore already had; re-rendering then gave 4 back. Servo 1's pocket+
#   shaft (1) + servo 2's pocket+horn, now reaching the aft face (1) + 2
#   cord holes, also extended through the skirt (2) = 4.
GENUS[5] = 4
#   part 8: spring carrier. First rendered without the forward counterbore
#   or shock-cord channels (Genus: 1, matching a single spring-bore
#   passage with blind ball pockets, same reasoning as below). Adding the
#   counterbore + 2 cord channels (Task 7 fix, see module comment) changed
#   this to Genus: 3, RE-DERIVED rather than assumed: a horizontal slice
#   through the diaphragm (z~21.5, diag, not part of the deliverable)
#   shows 3 SEPARATE round breaches through it -- the Ø8 driveshaft hole
#   and the 2 Ø5 cord holes -- each independently connecting "forward of
#   diaphragm" to "aft of diaphragm", so each is its own handle: 1 (main
#   bore/driveshaft passage) + 2 (the 2 cord passages, each breaching the
#   diaphragm separately from the driveshaft hole) = 3. A second slice
#   through the bore/ball-pocket region confirms the 3 ball pockets stay
#   enclosed/blind (do not breach the OD) and clear of the 2 cord grooves
#   -- this render also CAUGHT a rotation-math defect first: a first
#   draft placed a ball pocket azimuth 90deg off from its intended
#   position (forgot the pocket's own pre-rotation offset), landing it
#   inside the cord-groove sector (observed as a merged shape on the same
#   slice, still genus 3 -- the defect was in ball placement, not count);
#   fixed by correcting the rotate angle, re-rendered, re-confirmed clear.
GENUS[8] = 3

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
# Slot Z-extent inside R60_FinCan() is Slot_Z=8-IDXtra .. Slot_Z+Slot_L=
# 7.8..98.2 (not exposed as R60Lib constants; IDXtra=0.2 is the length
# clearance added at each end, so the slot is 90.4mm for a 90mm root). The
# z=98.2 edge loop is where the slot cut meets the outer wall; filtering
# x>0 isolates the i=0 slot (the other two sit at 120/240deg, all x<0
# there), and it's clear of both the aft centering ring (z=6..9) and the
# mid ring (z=114), so nothing else contaminates the loop.
# See fincan_slot_width()/fincan_slot_length() below.
FINCAN_SLOT_TOP_Z = 98.2
# Half-width of the slot's cut planes (R60_Fin_T/2 + IDXtra/2 = 2.0+0.1).
# Used to isolate the slot's two long vertical edges (which run the full
# 7.8..98.2 Z-span, as straight lines with vertices ONLY at their two
# endpoints -- confirmed on a standalone probe before use here) from the
# tube's own end-cap boundary circles at z=0/228, which pass through the
# same (x,y) coordinates and would otherwise contaminate a length reading.
FINCAN_SLOT_HALF_W = 2.1
# Part 11 is a plain 6mm disc (no cuts between z=0 and z=6), so it has
# vertices only at those two faces. The brief's band, (0.5, 3.5), lands
# mid-span with no edge loop there and made bore() raise "no geometry in Z
# band" -- confirmed by running the brief's code verbatim before changing
# it. Moved to the base face, same convention as every other *_BAND above.
RETAINER_BAND = (-0.01, 0.5)

# Part 8 (spring carrier): base face is a plain tube rim, OD=Coupler_OD.
# From the brief verbatim -- originally also carried the 44.8mm spring-bore
# reading, but a Task 7 fix added a CB_D=51mm forward counterbore (tether
# latch clearance, part 13/Task 8) ahead of it, so the base band now reads
# CB_D there instead; the 44.8mm reading moved to CARRIER_STEP_BAND below,
# at the step where the counterbore narrows to the actual spring bore.
SHEARPIN_BAND = (-0.01, 0.5)
CARRIER_STEP_BAND = (16.5, 17.5)   # straddles the CB_D->Bore step at z=17

# Shear-pin joint geometry (R60Lib.scad's R60_Pin_d/R60_Pin_Z_FromJoint,
# restated here as literals per this file's existing convention of checking
# against measured mesh geometry, not the constant that produced it -- see
# rule 4). Two pins land at the SAME Z offset from the joint on both sides
# (chute tube's forward rim, and the aft bulkhead's skirt, offset by the
# skirt's own T=12mm start), so a single physical pin lines up through both
# once assembled -- see R60_EBayAftBulkhead()'s module comment.
PIN_D            = 2.2    # nylon 2-56 clearance
PIN_Z_FROM_JOINT = 8.0
SKIRT_T          = 12.0   # part 5's original disc height, before the skirt
PIN_Z_CHUTE       = PIN_Z_FROM_JOINT
PIN_Z_SKIRT       = SKIRT_T + PIN_Z_FROM_JOINT
PIN_R_CHUTE       = 30.0   # R60_Body_OD/2 -- chute tube's outer wall
PIN_R_SKIRT       = 28.2   # R60_Coupler_OD/2 -- skirt's outer surface


def pin_hole_diameter(stl, x_side, z_center, r_expected, half_window=3.0):
    """Diameter of a small radial shear-pin hole, read from the STL's own
    edge-loop vertices where the hole cuts the surface near
    x = x_side * r_expected, z = z_center. x_side isolates one hole from
    its mirror at -x_side (the two pins are 180deg apart, at +-X); the z
    window isolates it from unrelated geometry. Pin_d is tiny relative to
    the tube's own radius of curvature, so the hole's local Z-extent is a
    direct read of its diameter -- same "measure the real edge loop, don't
    infer from the constant that cut it" approach as fincan_slot_*()."""
    zs = [z for tri in _tris(stl) for (x, y, z) in tri
          if x_side * x > 0 and abs(abs(x) - r_expected) < half_window
          and abs(z - z_center) < half_window]
    if not zs:
        raise RuntimeError(
            "no geometry near pin hole x=%+.0f*r, z=%.1f of %s"
            % (x_side, z_center, stl))
    return max(zs) - min(zs)


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


def fincan_slot_length(stl):
    """Measured length (Z-span) of the un-rotated (i=0) fin slot. The
    slot's two long vertical edges run the full Slot_Z..Slot_Z+Slot_L span
    as straight lines -- confirmed on a standalone probe to carry vertices
    ONLY at their two endpoints, nowhere mid-span (rule 3). Filtering to
    |y|==FINCAN_SLOT_HALF_W isolates those two edges; x>0 isolates the i=0
    slot; excluding z<=1 and z>=227 drops the tube's own end-cap boundary
    circles, which pass through the same (x,y) at z=0/228 and would
    otherwise be mistaken for the slot's edges (confirmed empirically --
    the naive filter without this exclusion returns the full 228mm)."""
    zs = [z for tri in _tris(stl) for (x, y, z) in tri
          if abs(abs(y) - FINCAN_SLOT_HALF_W) <= 0.01 and x > 0
          and 1 < z < 227]
    if not zs:
        raise RuntimeError("no geometry at fin can slot side edges")
    return max(zs) - min(zs)


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

    # Part 5's height grew from a plain 12mm disc to 12 + a 15mm aft skirt
    # (SKIRT_T + 15 = 27) that carries the shear pins into the real joint --
    # see R60_EBayAftBulkhead()'s module comment.
    for p, want_h in ((4, 6.0), (5, 27.0)):
        if p in m:
            _, bulk_od = bore(a(p, "stl"), *BULK_BAND)
            c += [("part %d height" % p, a(p, "height"), want_h, 0.1)]
            # Must drop into a tube bore, measured against the real tube.
            if 2 in m:
                tube_id, _ = bore(a(2, "stl"), *TUBE_BAND)
                c += [("part %d fits e-bay bore" % p,
                       tube_id - bulk_od, 0.4, 0.15)]

    # Shear pins bridge the ACTUAL separable joint: chute tube (part 3) and
    # the aft bulkhead's skirt (part 5), not the spring carrier (part 8).
    # Both holes are read straight off the rendered mesh at the Z each part
    # was cut at, so a hole that silently didn't break through, or landed
    # off-target, fails here rather than in the report.
    if 3 in m:
        for x_side in (1, -1):
            d = pin_hole_diameter(a(3, "stl"), x_side, PIN_Z_CHUTE, PIN_R_CHUTE)
            c += [("chute tube shear pin dia (x=%+d side)" % x_side,
                   d, PIN_D, 0.3)]
    if 5 in m:
        for x_side in (1, -1):
            d = pin_hole_diameter(a(5, "stl"), x_side, PIN_Z_SKIRT, PIN_R_SKIRT)
            c += [("aft bulkhead skirt shear pin dia (x=%+d side)" % x_side,
                   d, PIN_D, 0.3)]

    if 8 in m:
        _, carrier_od = bore(a(8, "stl"), *SHEARPIN_BAND)
        carrier_bore, _ = bore(a(8, "stl"), *CARRIER_STEP_BAND)
        c += [("spring carrier OD", carrier_od, 56.40, 0.15),
              ("spring carrier bore takes CS4323", carrier_bore, 44.80, 0.30)]
        if 3 in m:
            tube_id, _ = bore(a(3, "stl"), *TUBE_BAND)
            c += [("carrier clears chute bore", tube_id - carrier_od, 0.4, 0.15)]

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
        # Length clearance added after a coordinator review: the original
        # slot was line-to-line with the fin's 90mm root chord (0 printed
        # clearance over 90mm -- not assemblable). Same mesh-against-mesh
        # method as the width check: fin root chord read from part 10's own
        # STL, slot length read from part 9's, no shared inputs.
        slot_l = fincan_slot_length(a(9, "stl"))
        fin_chord = a(10, "xmax") - a(10, "xmin")
        c += [("fin slot length fits fin root chord",
               slot_l - fin_chord, 0.4, 0.1)]

    if 12 in m:
        # Default Motor_Class=0 is the G80T: 223mm MMT - 124mm motor = 99mm.
        c += [("G80T spacer length", a(12, "height"), 99.0, 0.1)]
    if 11 in m:
        _, ret_od = bore(a(11, "stl"), *RETAINER_BAND)
        c += [("retainer OD", ret_od, 60.0, 0.1)]

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
