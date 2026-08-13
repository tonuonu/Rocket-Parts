#!/usr/bin/env python3
"""Render and measure Rocket 60 parts.

A part that does not fit still renders cleanly, so every mating dimension is
measured from the STL rather than inferred from the parameter that was
supposed to produce it.
"""
import math, os, subprocess, sys, tempfile

from scad_verify import REPO, render, measure, bore, volume, _tris

SCAD = os.path.join(REPO, "Rocket60.scad")

NAMES = {0: "test ring", 1: "neck", 2: "e-bay tube", 3: "chute bay tube",
         4: "ebay fwd bulkhead", 5: "ebay aft bulkhead", 6: "vega sled",
         7: "access door", 8: "spring carrier", 9: "fin can", 10: "fin",
         11: "motor retainer", 12: "motor spacer", 13: "tether latch"}

# Door aperture (R60_EBayTube()) / cover (R60_Door()) -- defect 1d fix.
# R60_Door() used to be a flush plug 2*DOOR_GAP smaller than the aperture
# on every side; it is now a COVER, 2*DOOR_OVERLAP LARGER than the
# aperture on every side, resting on solid tube material instead of
# dropping through it. Restated here as literals per this file's
# convention (rule 4), matching R60Lib.scad's R60_Door_Open_W/H/Overlap.
DOOR_OPEN_W, DOOR_OPEN_H = 36.0, 85.0
DOOR_OVERLAP = 6.0
DOOR_HOLE_CLEAR = 3.0

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
#   part 10 is DELIBERATELY not in GENUS: it renders as a convex PolySet
#   (OpenSCAD reports "Convex: yes", no "Genus:" line at all -- flat
#   2D-extruded stock, no holes), and that is true every time, not an
#   intermittent tool quirk. A convex solid is provably genus 0 by
#   definition, so there is nothing here for the defect 3a fix (a genus
#   that SHOULD have been reported but silently wasn't) to catch -- adding
#   it back with a loud-failure check would just be a permanent, never-
#   fixable FAIL for a part that was never wrong. See main()/checks()'s
#   genus loop for the defect 3a fix itself.
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
#   RE-DERIVED AGAIN (Task 8) after adding the tether tie-off lug + its
#   lashing hole (Genus: 4). Visually confirmed on a thin X-slice through
#   the lug (diag): the hole is a clean opening straight through the
#   lug's material, a genuine 4th handle, not a blind mark -- the pin
#   holes and tube bore are unaffected (different azimuth, no shared
#   geometry). 1 (tube) + 2 (pin holes) + 1 (lug lashing hole) = 4.
GENUS[3] = 4
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
#   part 13: tether latch. Per the brief, NOT predicted -- rendered first
#   (OpenSCAD stderr: `Genus: 2`). A base-slice diagnostic confirms both
#   M3 mounting holes are clean through-holes (open circles in a mid-base
#   slice). A front-on diagnostic (sighting straight down the pin bore's
#   own axis) confirms the pin bore is a real hole cut into a post's
#   material, and an isolated single-post reproduction (post + pin bore,
#   no base holes, no second post, no slot -- diag, not part of the
#   deliverable) independently renders Genus: 1, confirming that hole
#   is a genuine through-tunnel on its own. So every intended feature
#   (2 mount holes, pin bore through the posts, loop slot) is confirmed
#   real, not missing or blind -- BUT the full assembly's genus (2) is
#   LOWER than a naive per-feature sum (2 mount holes + 2 post-tunnels =
#   4 expected). Isolating combinations pins this to how they combine on
#   a shared base, not a broken feature: base+2 mount holes alone = 2;
#   1 post+bore alone = 1; 1 post+bore+2 mount holes together = 2 (not
#   3); both posts+bore alone (no mount holes at all) = 2; the real part
#   (everything) = 2. Genus does not simply sum across independently-
#   verified through-features once they share a base with other holes --
#   a real topological property of this connect-sum, reproduced
#   consistently across five isolated variants, not a rendering fluke or
#   a missing cut. Recording the observed value per the brief's
#   instruction to measure, not predict.
GENUS[13] = 2
#   part 13 RE-DERIVED (defect 1b/1h fix): mounting holes moved from +-11mm
#   to +-R60_TetherLatch_HoleX (16mm, clear of the horn-slot void) and
#   widened Base_L to fit; the merging behaviour documented above (2, not
#   the naive-sum 4) was specific to the OLD hole placement sharing
#   boundary geometry with the posts. Rendered post-fix (OpenSCAD stderr:
#   `Genus: 4`) -- now matches the naive per-feature sum (2 mount holes +
#   2 post/pin-bore tunnels), confirmed on the same base-slice /
#   front-on-post diagnostics as above: both mount holes are still clean
#   through-holes, the pin bore is still a genuine tunnel through each
#   post, and with the mount holes now well clear of the posts (moved from
#   +-11 to +-16, vs. posts at +-9) they no longer share a boundary that
#   collapses two handles into one.
GENUS[13] = 4
#   part 2 RE-DERIVED (defect 1d/1g fix): 2 zip-tie slots added (Vega sled
#   retention) on top of the door opening (1) + switch hole (1) + tube (1)
#   already counted in GENUS[2]=3 above. Rendered (OpenSCAD stderr:
#   `Genus: 5`), confirmed each zip-tie slot is a clean through-cut (both
#   the OD-side and ID-side faces are cut, same "full wall thickness gap"
#   check as part 3's shear pins) -- the retention rails themselves are
#   ADDED material (no new voids) and the door screw bosses/pilot holes
#   are blind (open at one face only, same "adds zero handles" reasoning
#   as part 9's boss inserts below), so neither changes the count.
GENUS[2] = 5
#   part 9 RE-DERIVED (defect 1j fix): 2 shock-cord anchor holes added
#   through the forward centring ring on top of GENUS[9]=4 above (1 MMT
#   bore + 3 fin slots). Rendered (OpenSCAD stderr: `Genus: 6`), confirmed
#   each cord hole is a genuine through-hole (isolated on a Z-band probe
#   at the forward ring, distinct circular edge loops at r~20..25mm,
#   clear of the MMT bore and all 3 fin slots).
GENUS[9] = 6

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

# Tether lug (part 3) vs. the skirt's relief notch (part 5) -- defect 1a.
# Both parts share the rocket's own Z axis with no radial offset once
# assembled, so their (x, y) footprints are directly comparable with no
# assembly-frame transform -- only Z differs, and Z is irrelevant to a
# radius/width clearance check (the notch runs the skirt's FULL length).
# Windows restated as literals per this file's convention; see
# R60Lib.scad's R60_TetherLug_*/R60_Tether_Clear for what produced them.
TETHER_LUG_XZ = (-4.5, 4.5, 3.5, 9.5)          # part 3, lug's own X/Z span + margin
TETHER_NOTCH_XZ = (-5.5, 5.5, 11.5, 27.5)      # part 5, notch's full skirt-length span
TETHER_NOTCH_YLO = 19.0   # excludes the shaft bore (max y=6) and servo 2's
                           # horn slot (max y=18.1), both of which also
                           # fall inside the X/Z window above

# Spring reaction tabs (part 3) vs. the CS4323 spring -- defect 1c.
SPRING_OD = 44.30
STOPTAB_BAND = (79.99, 80.5)   # straddles the tabs' own base edge loop (z=80)

R60_TETHER_Y = 13.6   # = R60_Tether_Y (R60Lib.scad)


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


def xy_extent_in_window(stl, xlo, xhi, zlo, zhi, ylo=-1e9, yhi=1e9):
    """(xmin, xmax, ymin, ymax) of vertices within an X/Z window (and an
    optional Y prefilter) -- isolates one small feature (a lug, a notch, a
    boss) from the rest of a part's mesh, same idea as pin_hole_diameter()
    and fincan_slot_*() above."""
    xs, ys = [], []
    for tri in _tris(stl):
        for (x, y, z) in tri:
            if xlo <= x <= xhi and zlo <= z <= zhi and ylo <= y <= yhi:
                xs.append(x); ys.append(y)
    if not xs:
        raise RuntimeError(
            "no geometry in window x=%.1f..%.1f z=%.1f..%.1f of %s"
            % (xlo, xhi, zlo, zhi, stl))
    return min(xs), max(xs), min(ys), max(ys)


def hole_max_reach(stl, cx, cy, z_at, search_r, zwin=0.5):
    """Max in-plane distance from (cx, cy) of any vertex within search_r of
    it, at the Z-plane z_at (an exposed hole edge). A hole that is fully
    surrounded by solid material out to search_r reads close to its own
    true radius -- nothing else is close enough to contribute a vertex. A
    hole that breaks into an adjacent void (a slot, a pocket) reads much
    larger, because the merged opening's edge is that void's own, farther
    -out boundary instead (defect 1b: the old +-11mm tether latch insert
    holes broke into the horn slot's void this way)."""
    ds = [math.hypot(x - cx, y - cy) for tri in _tris(stl) for (x, y, z) in tri
          if abs(z - z_at) <= zwin and math.hypot(x - cx, y - cy) <= search_r]
    if not ds:
        raise RuntimeError(
            "no geometry near hole (%.1f,%.1f) z=%.1f of %s" % (cx, cy, z_at, stl))
    return max(ds)


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
        # FIXED (defect 1g): the sled sits as a flat CHORD against the
        # tube's round ID (both long edges touch it, captured by
        # R60_EBayTube()'s retention rails -- see that module's comment),
        # not centred through the axis, so the naive "subtract from the
        # full bore diameter" comparison used before ignored how far off
        # axis that chord actually sits. Available depth is measured from
        # the chord line (tube_r - chord_dist BELOW the axis, so tube_r +
        # chord_dist across to the far wall) rather than the raw diameter.
        if 2 in m:
            tube_id, _ = bore(a(2, "stl"), *TUBE_BAND)
            tube_r = tube_id / 2.0
            sled_w = a(6, "xmax") - a(6, "xmin")
            chord_dist = math.sqrt(max(0.0, tube_r ** 2 - (sled_w / 2.0) ** 2))
            avail = tube_r + chord_dist
            stack = a(6, "height") + 21.0    # sled + Vega envelope
            c += [("sled + Vega clears e-bay bore (chord-corrected)",
                   avail - stack, 15.0, 10.0)]

    if 7 in m:
        # FIXED (defect 1d): R60_Door() is now a COVER, DOOR_OVERLAP larger
        # than the aperture on every side (not a plug DOOR_GAP smaller),
        # resting on solid tube material with 4 screws into real bosses --
        # see R60_Door()'s module comment. The door's 85mm dimension runs
        # along Z; its Y extent is only the chord depth of the curved
        # cover, so measure height, not ymax-ymin.
        c += [("door cover height", a(7, "height"),
               DOOR_OPEN_H + 2 * DOOR_OVERLAP, 0.15),
              ("door cover chord width", a(7, "xmax") - a(7, "xmin"),
               DOOR_OPEN_W + 2 * DOOR_OVERLAP, 0.15)]
        # Retention: the cover must be LARGER than the aperture it covers
        # on every side (defect 1d's actual fix -- a plug smaller than its
        # own hole cannot be retained no matter what else is added).
        if 2 in m:
            door_h = a(7, "height")
            door_w = a(7, "xmax") - a(7, "xmin")
            c += [("door cover overlaps aperture height",
                   door_h - DOOR_OPEN_H, 2 * DOOR_OVERLAP, 0.3),
                  ("door cover overlaps aperture width",
                   door_w - DOOR_OPEN_W, 2 * DOOR_OVERLAP, 0.3)]

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

        # Cross-part interference (defect 1a): part 3's tether lug vs.
        # part 5's relief notch through the skirt it inserts into. This
        # class of defect -- both parts individually correct, colliding
        # only once mated -- is invisible to any single-part measurement
        # above, which is exactly why it shipped once already.
        if 3 in m:
            lug_xmin, lug_xmax, lug_ymin, _ = xy_extent_in_window(
                a(3, "stl"), *TETHER_LUG_XZ)
            notch_xmin, notch_xmax, notch_ymin, _ = xy_extent_in_window(
                a(5, "stl"), *TETHER_NOTCH_XZ, ylo=TETHER_NOTCH_YLO)
            # Radial: the notch's back wall (smaller y) must sit farther
            # in than the lug's own tip (larger y) -- a POSITIVE gap.
            c += [("tether lug clears skirt notch (radius)",
                   lug_ymin - notch_ymin, 0.6, 0.4)]
            # Width: the notch must be wider than the lug on both sides.
            c += [("tether lug clears skirt notch (-X width)",
                   lug_xmin - notch_xmin, 0.6, 0.5),
                  ("tether lug clears skirt notch (+X width)",
                   notch_xmax - lug_xmax, 0.6, 0.5)]

        # Bore fully surrounded (defect 1b): the tether latch's mounting
        # inserts must land in solid material, not the horn slot's void.
        # A hole that breaks into an adjacent void reads a much larger
        # max-reach than its own true radius -- see hole_max_reach()'s
        # docstring; TETHER_INSERT_R/D restated as literals matching
        # R60Lib.scad's R60_TetherLatch_HoleX/R60_TetherInsert_d, and
        # SKIRT_T+R60_Pin_Skirt_L(15)=27 (part 5's own Total_H) is where
        # the insert holes open, on the aft face.
        insert_x = 16.0
        insert_r = 2.0
        total_h = 27.0
        for x_side in (1, -1):
            reach = hole_max_reach(a(5, "stl"), x_side * insert_x,
                                    R60_TETHER_Y, total_h, search_r=6.0)
            c += [("tether insert hole fully surrounded (x=%+d side)"
                   % x_side, reach, insert_r, 0.3)]

    # Spring reaction tabs (defect 1c) actually reached by the CS4323
    # spring: radial overlap between the tabs' measured inner radius and
    # the spring's own OD, not merely that both parts exist. bore()'s
    # corner-vs-true-edge bias on a flat cube tab reads slightly larger
    # than the tab's true inner radius (confirmed ~0.4mm on this
    # geometry) -- tolerance is widened to cover that, not to hide a
    # regression: the old (broken) value misses by 0.6-0.85mm, well
    # outside it.
    if 3 in m:
        tab_inner_r, _ = bore(a(3, "stl"), *STOPTAB_BAND)
        tab_inner_r /= 2.0
        c += [("spring tab overlaps spring OD (radial)",
               SPRING_OD / 2.0 - tab_inner_r, 2.0, 1.3)]

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
        # FIXED (defect 1f): the spacer length used to be checked against
        # the literal 99.0 -- the constant that produced it -- rather than
        # the fin can's own MEASURED MMT depth, the exact "compare the
        # mesh to the constant that produced it" violation this file's own
        # rule (4) forbids. That is why a 5mm drift (R60_MMT_L=223 vs.
        # R60_FinCan()'s actual 228mm build depth) passed silently. Now
        # derived from part 9's rendered height whenever it is available;
        # the literal survives only as a fallback for a part-12-only run.
        motor_len = 124.0   # G80T-14A, Motor_Class default 0
        if 9 in m:
            mmt_depth = a(9, "height")
            c += [("G80T spacer length (from fin can's measured MMT depth)",
                   a(12, "height"), mmt_depth - motor_len, 0.1)]
        else:
            c += [("G80T spacer length", a(12, "height"), 104.0, 0.1)]
    if 11 in m:
        _, ret_od = bore(a(11, "stl"), *RETAINER_BAND)
        c += [("retainer OD", ret_od, 60.0, 0.1)]

    if 13 in m:
        # FIXED (defect 1b/1h): base length grew to fit the mounting holes'
        # new +-R60_TetherLatch_HoleX spacing (was 26mm/+-11mm, landing the
        # inserts in the horn slot's void); hole diameter is checked
        # against part 5's insert holes below, not restated here.
        c += [("latch base length", a(13, "xmax") - a(13, "xmin"), 36.0, 0.2),
              ("latch height", a(13, "height"), 16.0, 0.2),
              ("latch zmin", a(13, "zmin"), 0.0, 0.05)]

    # Build volume, every part.
    for p in m:
        c += [("part %d fits %.0fmm Z" % (p, MAX_Z),
               m[p]["height"], min(m[p]["height"], MAX_Z), 0.01)]

    # Topology, every part with a recorded expectation. FIXED (defect 3a):
    # a missing genus (render() found no "Genus:" line -- a version
    # change, a quieter render) used to silently DROP the check via
    # `if m[p].get("genus") is not None`, so a genus regression on that
    # part produced no FAIL at all and the run still printed "0 check(s)
    # failed". A missing genus is now itself a loud failure (actual=nan,
    # which is never <= any tolerance) instead of a silently-skipped
    # check.
    for p in m:
        if p in GENUS:
            g = m[p].get("genus")
            c += [("part %d genus" % p,
                   g if g is not None else float("nan"), GENUS[p], 0)]

    return c


def main(argv):
    parts = [int(x) for x in argv[1:]] or sorted(NAMES)
    m = {}
    tmp = tempfile.mkdtemp(prefix="r60-")
    for p in parts:
        out = os.path.join(tmp, "part%d.stl" % p)
        # FIXED (defect 3c): render() carries a 900s subprocess timeout
        # (scad_verify.py) but this loop used to catch nothing at all, so
        # either a failed render (RuntimeError) or a slow one
        # (subprocess.TimeoutExpired) died on a raw traceback instead of a
        # clear FAIL. Same fix as verify_nosecone.py.
        try:
            g = render(SCAD, p, out)
        except (RuntimeError, subprocess.TimeoutExpired) as e:
            print("FAIL  render part %d (%s)\n%s" % (p, NAMES.get(p, "?"), e))
            return 1
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
