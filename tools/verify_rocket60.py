#!/usr/bin/env python3
"""Render and measure Rocket 60 parts.

A part that does not fit still renders cleanly, so every mating dimension is
measured from the STL rather than inferred from the parameter that was
supposed to produce it.
"""
import math, os, subprocess, sys, tempfile

from scad_verify import REPO, render, measure, bore, volume, tris

SCAD = os.path.join(REPO, "Rocket60.scad")

NAMES = {0: "test ring", 1: "neck", 2: "e-bay tube", 3: "chute bay tube",
         4: "ebay fwd bulkhead", 5: "ebay aft bulkhead", 6: "vega sled",
         7: "access door", 8: "spring carrier", 9: "fin can", 10: "fin",
         11: "motor retainer", 12: "motor spacer", 13: "tether latch",
         14: "thrust ring"}

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
# genus 0, each through-hole/handle adds 1). Each part's FINAL genus is
# assigned to GENUS[p] exactly once below -- defect 3e: this used to be
# five layers of silent reassignment (GENUS[9] set to 4 then overwritten
# to 6 113 lines later, GENUS[13] set to 2 then 4, etc.), so a part's
# actually-checked value was nowhere near its own definition. The
# derivation history -- why a value changed across rounds, what confirmed
# it on the rendered mesh each time -- is kept as comments, in order,
# ending at the one real assignment.
#
# part 0: open-centre ring (1) + 3 bolt holes (3) = 4
# part 1: open-centre spider (1) + 3 bolt holes (3) = 4
# part 4: disc + harness bore (1) = 1
# part 6: flat sled, 3 standoff bores (3) = 3
GENUS = {0: 4, 1: 4, 4: 1, 6: 3}
#   part 10 is DELIBERATELY not in GENUS: it renders as a convex PolySet
#   (OpenSCAD reports "Convex: yes", no "Genus:" line at all -- flat
#   2D-extruded stock, no holes), and that is true every time, not an
#   intermittent tool quirk. A convex solid is provably genus 0 by
#   definition, so there is nothing here for the defect 3a fix (a genus
#   that SHOULD have been reported but silently wasn't) to catch -- adding
#   it back with a loud-failure check would just be a permanent, never-
#   fixable FAIL for a part that was never wrong. See main()/checks()'s
#   genus loop for the defect 3a fix itself.

#   part 2: e-bay tube. Started at 3 (tube(1) + door opening(1) + switch
#   hole(1)). RE-DERIVED (defect 1d/1g fix) after 2 zip-tie slots were
#   added (Vega sled retention): rendered `Genus: 5`, confirmed each
#   zip-tie slot is a clean through-cut (both the OD-side and ID-side
#   faces are cut, same "full wall thickness gap" check as part 3's shear
#   pins) -- the retention rails themselves are ADDED material (no new
#   voids) and the door screw bosses/pilot holes are blind (open at one
#   face only), so neither changes the count. RE-CONFIRMED this round
#   after the door-boss-reach fix (2a) and the rail-angle fix (1b) --
#   neither changes hole COUNT, only position/reach; re-rendered, still
#   `Genus: 5`. RE-DERIVED again (3rd review, defect 11): the 2 zip-tie
#   slots became 4 (one pair per Z station now, straddling the sled
#   tangentially instead of both sharing one azimuth) -- rendered `Genus:
#   7` (5+2, the expected count for 2 more independent through-cuts). An
#   earlier draft that only cut the rail's OUTER portion at each new hole
#   (leaving its inner, sled-facing face standing as a thin bridge across
#   the gap) rendered `Genus: 11` instead -- a real, if unwanted, extra
#   handle per hole from that leftover bridge, not a modelling error;
#   redesigned to cut the rail's full cross-section locally instead (see
#   R60_EBayTube()'s own Tie_X0/Tie_Depth comment), which returned the
#   count to the expected +1-per-hole.
GENUS[2] = 7

#   part 3: chute bay tube. Started at 1 (plain tube), then 3 after the 2
#   shear pin holes were added (rendered `Genus: 3`, confirmed on a thin
#   Z-band section slice at the pin holes' Z: each is a clean full-wall
#   through-cut, not a blind mark). RE-DERIVED AGAIN (Task 8) after adding
#   the tether tie-off lug + its lashing hole (`Genus: 4`, confirmed on a
#   thin X-slice through the lug: the hole is a clean opening straight
#   through the lug's material, a genuine 4th handle -- the pin holes and
#   tube bore are unaffected, different azimuth, no shared geometry).
#   1 (tube) + 2 (pin holes) + 1 (lug lashing hole) = 4.
GENUS[3] = 4

#   part 5: e-bay aft bulkhead. Started at 1 (disc + harness-analogue
#   bore), grew through the upright-servo redesign; RE-CONFIRMED at 4
#   after adding the aft skirt + 2 shear pin holes (rendered `Genus: 4`; a
#   sliced side-profile diagnostic confirms the 2 new pin holes are blind
#   -- add zero handles). This render also CAUGHT a real defect first:
#   the first skirt draft left servo 2's horn slot dead-ending under the
#   new solid skirt material (observed genus 3, not 4) -- fixed by
#   extending the horn slot cut through the skirt to the new aft face,
#   same treatment the shaft bore already had; re-rendering then gave 4
#   back. Servo 1's pocket+shaft (1) + servo 2's pocket+horn, reaching the
#   aft face (1) + 2 cord holes, also extended through the skirt (2) = 4.
GENUS[5] = 4

#   part 7: curved door cover. 4 bolt holes = 4. Unchanged across the
#   defect 1a azimuth fix -- that fix repositions each hole's AXIS, not
#   its count or through/blind nature; re-rendered, still `Genus: 4`.
GENUS[7] = 4

#   part 8: spring carrier. First rendered without the forward counterbore
#   or shock-cord channels (Genus: 1, a single spring-bore passage with
#   blind ball pockets). Adding the counterbore + 2 cord channels (Task 7
#   fix) changed this to Genus: 3, RE-DERIVED rather than assumed: a
#   horizontal slice through the diaphragm (z~21.5) shows 3 SEPARATE round
#   breaches through it -- the Ø8 driveshaft hole and the 2 Ø5 cord holes
#   -- each independently connecting "forward of diaphragm" to "aft of
#   diaphragm": 1 (main bore/driveshaft passage) + 2 (cord passages) = 3.
#   A second slice confirms the 3 ball pockets stay enclosed/blind and
#   clear of the 2 cord grooves -- this render also CAUGHT a
#   rotation-math defect first: a first draft placed a ball pocket
#   azimuth 90deg off (forgot the pocket's own pre-rotation offset),
#   landing it inside the cord-groove sector (still genus 3 -- the defect
#   was in ball placement, not count); fixed by correcting the rotate
#   angle. RE-CONFIRMED this round after the notch-width fix (2c,
#   Rocket60.scad's R60_SpringCarrier()): the notch is wider (8->9.2mm)
#   but still a single blind-from-the-side cut through the OD-to-CB_D rim
#   annulus, no new through-passage; rendered, still `Genus: 3`.
GENUS[8] = 3

#   part 9: fin can. Rendered 4 (1 MMT bore + 3 fin slots) after the
#   retainer bolt bosses were added (confirmed blind via top/bottom/
#   isometric renders: bosses visible on the aft face only, not the
#   forward face). RE-DERIVED (defect 1j fix) after 2 shock-cord anchor
#   holes were added through the forward centring ring: rendered
#   `Genus: 6`, confirmed each cord hole is a genuine through-hole
#   (isolated on a Z-band probe at the forward ring, distinct circular
#   edge loops at r~20..25mm, clear of the MMT bore and all 3 fin slots).
GENUS[9] = 6

#   part 11: retainer. 1 (centre bore) + 3 (through bolt clearance holes,
#   confirmed genuine through-openings on BOTH top and bottom faces, not
#   part 9's blind boss pattern) = 4.
GENUS[11] = 4

#   part 12: spacer tube = 1. Length changed this round (3rd review,
#   defect 3 corollary -- shortened by R60_ThrustRing_T=6mm so the new
#   part 14 has somewhere to sit without sharing space with this one) but
#   the topology (a plain tube) did not; rendered, still `Genus: 1`.
GENUS[12] = 1

#   part 13: tether latch. FIRST rendered (pre-fix, +-11mm hole spacing)
#   at Genus: 2 -- lower than the naive per-feature sum (2 mount holes + 2
#   post-tunnels = 4) because that hole placement shared boundary geometry
#   with the posts, collapsing two handles into one (five isolated
#   variants reproduced this consistently -- not a rendering fluke).
#   RE-DERIVED (defect 1b/1h fix) after the mounting holes moved to
#   +-R60_TetherLatch_HoleX (16mm, clear of the horn-slot void) and
#   Base_L widened to fit: rendered `Genus: 4`, now matching the naive
#   per-feature sum, confirmed on the same base-slice/front-on-post
#   diagnostics (both mount holes still clean through-holes, pin bore
#   still a genuine tunnel through each post) -- with the mount holes well
#   clear of the posts (+-16 vs. posts at +-9) they no longer share a
#   boundary that collapses two handles into one. RE-CONFIRMED this round
#   after the Base_L/wall-margin fix (2b): base grew again (36->38.6mm)
#   but the hole/post topology is unchanged; rendered, still `Genus: 4`.
GENUS[13] = 4

#   part 14: forward thrust ring (new this round, 3rd review defect 3) =
#   1 (a plain annulus -- one through-hole, same class as part 12's
#   spacer tube). Rendered `Genus: 1`.
GENUS[14] = 1

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

# Parts 12 (spacer) and 14 (thrust ring), both plain untapered tubes with
# no Z-varying features, so a base-face band gives the true OD/bore
# either way -- same convention as every other *_BAND above.
THRUST_RING_BAND = (-0.01, 0.5)

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

# --- this round's fixes (PR #23, 2nd review) --------------------------

# Door screw axis vs. tube boss axis -- defect 1a (2nd review). Both are
# restated as literals per this file's rule 4 convention, matching
# R60Lib.scad's R60_Body_OD/R60_Door_Open_W/R60_Door_Hole_Clear and
# R60_EBayTube()/R60_Door()'s own Door_Z0/Door_Overlap/T.
DOOR_HOLE_X_AXIS = 21.0     # R60_Door_Open_W/2 + R60_Door_Hole_Clear
BODY_R           = 30.0     # R60_Body_OD/2 -- tube's true OD, and the
                              # radius the door boss's flush face sits at
DOOR_COVER_T     = 2.0      # R60_Door()'s own cover shell thickness
COVER_OUTER_R    = BODY_R + DOOR_COVER_T   # cover's own outer face
# R60_Door()'s own z=0 (cover base) lands at tube-frame z = Door_Z0 -
# R60_Door_Overlap = 40 - 6 = 34.0 once assembled; DOOR_HOLE_Z_TUBE is
# R60_EBayTube()'s own Door_Hole_Z, in the TUBE's frame.
DOOR_Z_OFFSET     = 34.0
DOOR_HOLE_Z_TUBE  = (37.0, 128.0)

# Vega sled retention rails -- defect 1b (2nd review). Rail_Inner_R is the
# rails' own exposed, functional radius (see R60_EBayTube()'s Rail_Inner_R
# comment) -- NOT the tube ID, which is what the pre-fix formula used.
RAIL_INNER_R = 24.0    # R60_Body_ID/2 - R60_Vega_RailH (28.4 - 4.4)
# Rail_Z0 (3rd review, defect 2 fix) -- the rail's own start-cap Z, where
# its cross-section (and so its facing corners) is exposed as an edge
# loop. Was the old flat Rail_Margin=5; now derived per-end
# (R60_AftBulk_T + Rail_Clear = 12+2) so the rails actually clear the
# aft bulkhead's disc and the neck skirt/forward bulkhead -- see
# R60_EBayTube()'s own Rail_Z0/Rail_Z1 comment.
RAIL_Z_CAP   = 14.0

# Door boss OD stations -- defect 2a. TUBE_BAND only reads the tube's
# plain base face (z~0); the door bosses sit at DOOR_HOLE_Z_TUBE, which
# TUBE_BAND never touches, so a boss protruding past the true OD there
# was invisible to every existing OD check.
BOSS_OD_BAND_HALF = 0.05

# Arming switch Z window -- defect 2d. SW_Z_EXPECT is R60_EBayTube()'s own
# (Sw_Z0+Sw_Z1)/2 = (134.0+137.0)/2, restated as a literal so the check
# reads the window's actual measured centre, not the formula that
# produced it. R60_EBay_L carries 5mm of headroom above the bare
# minimum (3rd review, defect 2d fix) specifically so this window is a
# genuine 3mm wide instead of a 0.5mm hair gap.
SW_Z_EXPECT = 135.5


def pin_hole_diameter(stl, x_side, z_center, r_expected, half_window=3.0):
    """Diameter of a small radial shear-pin hole, read from the STL's own
    edge-loop vertices where the hole cuts the surface near
    x = x_side * r_expected, z = z_center. x_side isolates one hole from
    its mirror at -x_side (the two pins are 180deg apart, at +-X); the z
    window isolates it from unrelated geometry. Pin_d is tiny relative to
    the tube's own radius of curvature, so the hole's local Z-extent is a
    direct read of its diameter -- same "measure the real edge loop, don't
    infer from the constant that cut it" approach as fincan_slot_*()."""
    zs = [z for tri in tris(stl) for (x, y, z) in tri
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
    ys = [y for tri in tris(stl) for (x, y, z) in tri
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
    zs = [z for tri in tris(stl) for (x, y, z) in tri
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
    for tri in tris(stl):
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
    ds = [math.hypot(x - cx, y - cy) for tri in tris(stl) for (x, y, z) in tri
          if abs(z - z_at) <= zwin and math.hypot(x - cx, y - cy) <= search_r]
    if not ds:
        raise RuntimeError(
            "no geometry near hole (%.1f,%.1f) z=%.1f of %s" % (cx, cy, z_at, stl))
    return max(ds)


def hole_azimuth_at_r(stl, cx, cy, z_at, r_target, search_r=4.0, zwin=2.0,
                       r_win=0.15):
    """Mean azimuth (deg, atan2(y,x)) of vertices near (cx, cy) at Z-plane
    z_at whose own distance from the Z axis is within r_win of r_target --
    isolates a hole's edge loop specifically where it breaches a given
    cylindrical face (a boss's flush face, a cover's outer surface),
    rather than averaging in vertices from a different radius entirely.
    Used to confirm two mating parts' screw axes are genuinely on the same
    radial line (defect 1a): a hole bored along a flat axis instead of the
    wall's true local radial direction reads a materially different
    azimuth from its mating part's hole at the SAME nominal (x, z), even
    though both were built from the identical Hole_X."""
    azs = [math.degrees(math.atan2(y, x)) for tri in tris(stl)
           for (x, y, z) in tri
           if abs(z - z_at) <= zwin and math.hypot(x - cx, y - cy) <= search_r
           and abs(math.hypot(x, y) - r_target) <= r_win]
    if not azs:
        raise RuntimeError(
            "no geometry near (%.2f,%.2f) r=%.1f z=%.1f of %s"
            % (cx, cy, r_target, z_at, stl))
    return sum(azs) / len(azs)


def rail_facing_gap(stl, r_inner, z_at, r_win=0.3, zwin=0.1):
    """Measured tangential gap between the Vega-sled retention rails'
    FACING (toward each other) corners, and that corner's own Y depth,
    read from the rails' own rendered geometry at their innermost exposed
    radius (r_inner) -- not computed from the angle that was supposed to
    produce it (defect 1b). Each rail's cross-section at r_inner has two
    corners, offset +-RailW/2 tangentially from its own centreline; for
    both rails sitting in the -Y hemisphere the corner facing the OTHER
    rail (the one that actually bounds the capture gap) is always the one
    with the more negative y -- true for both a too-narrow (pre-fix) and a
    properly-spread rail, confirmed against the rendered mesh of each."""
    xs_pos, xs_neg = [], []
    for tri in tris(stl):
        for (x, y, z) in tri:
            if (y < 0 and abs(z - z_at) <= zwin
                    and abs(math.hypot(x, y) - r_inner) <= r_win):
                (xs_pos if x > 0 else xs_neg).append((x, y))
    if not xs_pos or not xs_neg:
        raise RuntimeError(
            "rail corners not found near r=%.2f z=%.2f of %s"
            % (r_inner, z_at, stl))
    facing_pos = min(xs_pos, key=lambda p: p[1])   # most negative y = facing
    facing_neg = min(xs_neg, key=lambda p: p[1])
    return facing_pos[0] - facing_neg[0], facing_pos[1]


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

    for p, want_len in ((2, 165.0), (3, 186.0)):
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

    if 2 in m:
        # Door boss OD stations -- defect 2a. TUBE_BAND (z~0) never sees
        # the door bosses, which sit at DOOR_HOLE_Z_TUBE -- a boss
        # protruding past the true OD there (measured dmax 60.40 vs the
        # tube's own 60.00, pre-fix) was invisible to the plain "part 2 OD"
        # check above. Measured at each boss Z station directly.
        for z_boss in DOOR_HOLE_Z_TUBE:
            _, boss_od = bore(a(2, "stl"), z_boss - BOSS_OD_BAND_HALF,
                               z_boss + BOSS_OD_BAND_HALF)
            c += [("part 2 OD at door boss station (z=%.1f)" % z_boss,
                   boss_od, 60.0, 0.1)]

        # Arming switch Z -- defect 2d: nothing measured this before.
        # R60_EBayTube()'s own assert (added this round) is the load-
        # bearing guard against Sw_Z0/Sw_Z1 inverting outright; this reads
        # the switch hole's own Z-span directly off its rendered edge loop
        # (a Ø12 hole cut straight through the +Y wall, so its boundary is
        # an ellipse-ish curve spanning roughly Sw_Z+-Sw_d/2 in Z) and
        # checks the MEASURED centre against the stated literal window,
        # catching silent drift even where the render still succeeds. The
        # z pre-filter (126..164) excludes the tube's own end caps
        # (z=0/165) and the door aperture's edge loop (z=125.0), which
        # would otherwise contaminate a naive "nearest to the +Y wall"
        # search -- confirmed empirically before use here.
        sw_zs = [z for tri in tris(a(2, "stl")) for (x, y, z) in tri
                 if abs(x) < 6.0 and y > 29.0 and 126.0 < z < 164.0]
        # Was `if sw_zs:` -- an empty scan (hole missing, moved outside
        # the pre-filter band, or the wall/hole geometry changed shape)
        # silently skipped this check entirely instead of failing it, the
        # same "quietly absent row" defect as the genus checks above.
        # nan never falls within any tolerance, so an empty scan is now a
        # loud FAIL instead of a check that just never appears.
        sw_center = (min(sw_zs) + max(sw_zs)) / 2.0 if sw_zs else float("nan")
        c += [("arming switch hole Z centre", sw_center, SW_Z_EXPECT, 0.3)]

    if 6 in m:
        c += [("sled length", a(6, "ymax") - a(6, "ymin"), 112.0, 0.2),
              ("sled width", a(6, "xmax") - a(6, "xmin"), 44.0, 0.2)]

        if 2 in m:
            # Rails actually capture the sled -- defect 1b (2nd review),
            # checked mesh against mesh: the gap MEASURED between the two
            # rails' own facing corners (rail_facing_gap(), on part 2's
            # rendered geometry) must be at least as wide as the sled's
            # own MEASURED width (part 6), not merely both existing.
            # Nothing covered the rails themselves before this check --
            # the pre-fix rails measured a 35.65mm gap against a 44.0mm
            # sled and passed every existing check, because none of them
            # looked at the rails at all.
            gap, facing_y = rail_facing_gap(a(2, "stl"), RAIL_INNER_R, RAIL_Z_CAP)
            sled_w = a(6, "xmax") - a(6, "xmin")
            c += [("vega rails capture gap vs measured sled width",
                   gap - sled_w, 0.4, 0.3)]

            # The board must physically fit the tube bore lying on the
            # sled. FIXED (defect 1g, prior round): the sled sits as a
            # flat plate against the rails, not centred through the axis.
            # FIXED AGAIN (defect 1b corollary, this round): the prior
            # formula (chord_dist = sqrt(tube_r**2-(sled_w/2)**2) = 17.96)
            # assumed the sled's edges rest against the tube ID itself --
            # they do not, they rest against the RAILS, which (once
            # correctly captured) sit at facing_y (~9.24mm from the axis,
            # not 17.96mm), overstating available depth by ~8.7mm. Uses
            # the SAME measured facing_y from the rail-capture check
            # above rather than a second, independently-derived formula.
            tube_id, _ = bore(a(2, "stl"), *TUBE_BAND)
            tube_r = tube_id / 2.0
            avail = tube_r + abs(facing_y)
            # stack: T+Standoff_h (a(6,"height")=8, MEASURED off part 6's
            # own rendered mesh) + Vega_H (21, a restated hardware
            # literal -- there is no STL for the board itself). Spelled
            # out here on purpose (defect 15): "sled height + Vega_H"
            # reads like it could double-count the plate's own T=4mm --
            # it does not, R60_Vega_H=21 is the board's OWN total height
            # alone (R60Lib.scad: "Manual says 15mm total height,
            # catsystems.io says 21mm. Cut for 21." -- a component spec,
            # not an installed-including-standoffs figure), and
            # a(6,"height") already correctly covers T+Standoff_h, once.
            stack = a(6, "height") + 21.0   # (T+Standoff_h, measured) + Vega_H
            # want/tol (defect 15): was (15.0, 10.0) -- a window
            # ([5,25]) wide enough that this check could not fail for any
            # plausible geometry (confirmed: even a 5mm swing in EBay_L,
            # a materially different rail angle, or a wrong board height
            # would all still land inside it). CLEAR_EXPECT is the same
            # calculation, restated as a literal per this file's rule-4
            # convention -- TUBE_R_EXPECT=28.4 (=R60_Body_ID/2, matches
            # the "part 2 bore" check above) and FACING_Y_EXPECT=-9.24
            # (the rail corner's own measured depth -- restated, not a
            # closed-form constant: the sled's flat plate meets the
            # tube's CURVED rail corners, and rail_facing_gap()'s own
            # docstring is why that has no clean closed form). A real
            # +-0.5mm tolerance actually catches a regression in any of
            # these instead of absorbing it.
            TUBE_R_EXPECT = 28.4
            FACING_Y_EXPECT = -9.24
            STACK_EXPECT = 4.0 + 4.0 + 21.0   # Sled_T + Standoff_h + Vega_H
            CLEAR_EXPECT = TUBE_R_EXPECT + abs(FACING_Y_EXPECT) - STACK_EXPECT
            c += [("sled + Vega clears e-bay bore (rail-corrected)",
                   avail - stack, CLEAR_EXPECT, 0.5)]

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

            # Screw axis actually passes through both parts -- defect 1a
            # (2nd review). A screw hole bored along the wall's true local
            # radial direction has the SAME azimuth at every radius; the
            # pre-fix R60_Door() bored along flat global Y instead, which
            # only agreed with the tube boss's azimuth at r=R60_Body_OD/2
            # and diverged further out (measured ~1.6deg/1.3mm of solid
            # cover material in the way at the cover's own outer face).
            # Checked mesh against mesh: the tube boss's own flush-face
            # azimuth (part 2) vs. the door cover's own outer-face azimuth
            # (part 7), both read directly off their rendered geometry, not
            # from the parameter that was supposed to align them.
            for x_side in (1, -1):
                tx = x_side * DOOR_HOLE_X_AXIS
                ty = math.sqrt(BODY_R ** 2 - tx ** 2)
                target_az = math.degrees(math.atan2(ty, tx))
                for z_tube in DOOR_HOLE_Z_TUBE:
                    tube_az = hole_azimuth_at_r(a(2, "stl"), tx, ty, z_tube,
                                                 BODY_R)
                    door_az = hole_azimuth_at_r(a(7, "stl"), tx, ty,
                                                 z_tube - DOOR_Z_OFFSET,
                                                 COVER_OUTER_R)
                    c += [("tube boss axis azimuth (x=%+.0f z=%.1f)"
                           % (tx, z_tube), tube_az, target_az, 1.0),
                          ("door hole axis azimuth (x=%+.0f z=%.1f)"
                           % (tx, z_tube), door_az, target_az, 1.0)]

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
        # search_r (defect 3e): the horn slot's nearest corner to the
        # insert hole centre is R60_Horn_L/2=12 in X and Horn_W/2=4.5 in Y
        # from (R60_TetherLatch_HoleX, R60_Tether_Y) = (16, 13.6), i.e.
        # hypot(4, 4.5) = 6.02mm away -- search_r=6.0 left only 0.02mm of
        # margin before the search circle would itself reach into the
        # horn slot's own void and read a false-positive large "reach"
        # (one stray tessellation vertex from a spurious FAIL, not a real
        # defect). Widened to 5.0 (~1mm of real margin), still comfortably
        # bigger than the insert hole's own Ø4 (radius 2.0) edge loop.
        for x_side in (1, -1):
            reach = hole_max_reach(a(5, "stl"), x_side * insert_x,
                                    R60_TETHER_Y, total_h, search_r=5.0)
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
        # (defect 3e: "fin can fits 250mm Z" used to be emitted here too,
        # hardcoded to 250.0 -- a duplicate of the generic "part %d fits
        # %.0fmm Z" loop below, which already covers every part
        # (including 9) off the single MAX_Z constant. Removed rather than
        # kept in sync twice.)
        c += [("fin can length", a(9, "height"), 228.0, 0.2),
              ("fin can OD", can_od, 60.0, 0.1),
              ("MMT bore takes 29mm motor", mmt_id, 29.3, 0.15)]
    if 10 in m:
        # Span (3rd review, should-fix 7): nothing checked this before --
        # root chord and thickness were, but the dimension the flutter/
        # stability tradeoff actually turns on (tools/rocket60_model.py's
        # own comment: "span is the most mass-efficient lever... do NOT
        # ... extend the span further without recomputing BOTH stability
        # AND flutter") had no guard against silently drifting away from
        # R60Lib.scad's own R60_Fin_Span, or from the literal
        # `span = 63.0` tools/rocket60_model.py's stability/flutter
        # analysis is hardcoded to (restated there per this file's own
        # rule 4, with no check tying it back to the rendered mesh).
        # R60_Fin()'s polygon puts the span along Y.
        c += [("fin root chord", a(10, "xmax") - a(10, "xmin"), 90.0, 0.2),
              ("fin span", a(10, "ymax") - a(10, "ymin"), 63.0, 0.2),
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
        #
        # 3rd review, defect 3 corollary: the spacer now stops
        # THRUST_RING_T (6.0mm) short of the fin can's own measured MMT
        # depth, not flush with it -- R60_ThrustRing() (part 14) occupies
        # that last 6mm. Restated as a literal per this file's own rule 4,
        # matching R60Lib.scad's R60_ThrustRing_T.
        motor_len = 124.0   # G80T-14A, Motor_Class default 0
        thrust_ring_t = 6.0
        if 9 in m:
            mmt_depth = a(9, "height")
            c += [("G80T spacer length (from fin can's measured MMT depth)",
                   a(12, "height"), mmt_depth - thrust_ring_t - motor_len, 0.1)]
        else:
            c += [("G80T spacer length", a(12, "height"), 98.0, 0.1)]
    if 11 in m:
        _, ret_od = bore(a(11, "stl"), *RETAINER_BAND)
        c += [("retainer OD", ret_od, 60.0, 0.1)]

    if 14 in m:
        # Forward thrust ring (3rd review, defect 3): a part that is
        # missing is invisible to a per-part dimension check by
        # definition, so the load-bearing proof that it actually
        # obstructs the bore is the mesh-against-mesh assembly probe in
        # tools/verify_rocket60_assembly.py (pairs 10/11: flush position
        # clear, simulated overtravel shows real solid contact in BOTH
        # directions). This is the ordinary per-part geometry check every
        # other part gets, not a substitute for that proof.
        ring_bore, ring_od = bore(a(14, "stl"), *THRUST_RING_BAND)
        c += [("thrust ring height", a(14, "height"), 6.0, 0.1),
              ("thrust ring OD", ring_od, 28.9, 0.1),
              ("thrust ring bore", ring_bore, 26.8, 0.1)]
        if 9 in m:
            mmt_id, _ = bore(a(9, "stl"), *FINCAN_BAND)
            c += [("thrust ring fits MMT bore", mmt_id - ring_od, 0.4, 0.15)]
        if 12 in m:
            _, spacer_od = bore(a(12, "stl"), *THRUST_RING_BAND)
            # Dimensional half of the obstruction proof: the ring's own
            # bore must be genuinely smaller than the spacer's own OD, or
            # there is no lip for anything to catch on regardless of what
            # the assembly probe finds.
            c += [("thrust ring bore obstructs spacer OD",
                   spacer_od - ring_bore, 2.2, 0.3)]

    if 13 in m:
        # FIXED (defect 1b/1h): base length grew to fit the mounting holes'
        # new +-R60_TetherLatch_HoleX spacing (was 26mm/+-11mm, landing the
        # inserts in the horn slot's void); hole diameter is checked
        # against part 5's insert holes below, not restated here.
        # FIXED AGAIN (defect 2b): base length grew again, from
        # 2*(R60_TetherLatch_HoleX+2) [a hole-CENTRE-to-edge margin] to
        # 2*(R60_TetherLatch_HoleX + Mount_Hole_d/2 + Mount_Wall_Min) [a
        # real edge-of-hole-to-edge-of-part wall] -- 16+1.7+1.6=19.3 each
        # side, 38.6 total; restated here as a literal per this file's
        # convention, matching R60_TetherLatch()'s own derivation.
        c += [("latch base length", a(13, "xmax") - a(13, "xmin"), 38.6, 0.2),
              ("latch height", a(13, "height"), 16.0, 0.2),
              ("latch zmin", a(13, "zmin"), 0.0, 0.05)]
        # Wall beyond the mounting hole's own edge (defect 2b): must clear
        # a stated print-safe minimum, not just a hole-centre margin.
        # Measured directly off the rendered mesh at the hole's own Z band
        # (the base is a plain slab 0..Base_T, so a low band reads its
        # full X extent) rather than re-deriving the same arithmetic the
        # SCAD file already got wrong once.
        base_xmax = a(13, "xmax")
        insert_x_latch = 16.0    # R60_TetherLatch_HoleX
        mount_hole_r = 1.7       # Mount_Hole_d/2
        c += [("latch wall beyond mounting hole edge",
               base_xmax - (insert_x_latch + mount_hole_r), 1.6, 0.2)]

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
