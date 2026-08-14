#!/usr/bin/env python3
"""Render and measure Rocket 60 parts.

A part that does not fit still renders cleanly, so every mating dimension is
measured from the STL rather than inferred from the parameter that was
supposed to produce it.
"""
import math, os, subprocess, sys, tempfile

from scad_verify import REPO, render, measure, bore, volume, tris, components, overshoot

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
GENUS = {0: 4, 1: 4}
#   part 10 is DELIBERATELY not in GENUS: it renders as a convex PolySet
#   (OpenSCAD reports "Convex: yes", no "Genus:" line at all -- flat
#   2D-extruded stock, no holes), and that is true every time, not an
#   intermittent tool quirk. A convex solid is provably genus 0 by
#   definition, so there is nothing here for the defect 3a fix (a genus
#   that SHOULD have been reported but silently wasn't) to catch -- adding
#   it back with a loud-failure check would just be a permanent, never-
#   fixable FAIL for a part that was never wrong. See main()/checks()'s
#   genus loop for the defect 3a fix itself.

#   part 4: forward bulkhead. Started at 1 (disc + harness bore). RE-
#   DERIVED (6th review, finding 1): 2 ruthex insert holes added for the
#   Vega sled's forward foot, both BLIND (bored from the boss's own new
#   outer face partway into the disc, never breaking through the far
#   side) -- a blind pocket adds no handle, so the count is unchanged;
#   rendered, still `Genus: 1`, confirmed.
GENUS[4] = 1

#   part 6: Vega sled. Started at 3 (flat plate, 3 standoff bores).
#   RE-DERIVED (6th review, finding 1): the rail/zip-tie retention scheme
#   is retired (see R60Lib.scad's own "Sled retention" comment) --
#   REPLACED (7th review, finding 1/2, superseding the 6th review's own
#   4-foot-hole bolted bridge, which could not be inserted) by 2
#   continuous rails, ONE M3 rod clearance hole each (2 total, the full
#   rail length, not 4 short foot holes), so +2 handles; rendered,
#   `Genus: 5` (3+2), confirmed.
GENUS[6] = 5

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
#   count to the expected +1-per-hole. RE-DERIVED again (5th review,
#   finding 1): the arming switch hole moved off this tube entirely, onto
#   the access door (R60_Door()'s own module comment) -- one fewer
#   through-hole here, 7-1=6; rendered, `Genus: 6`. RE-DERIVED again (6th
#   review, finding 1): the rail/zip-tie retention scheme is retired
#   entirely (see R60Lib.scad's own "Sled retention" comment) -- the 2
#   rails were ADDED material (no genus contribution either way) and the
#   4 zip-tie slots were clean through-cuts (+1 each); removing all 4
#   drops the count 6-4=2; rendered, confirmed `Genus: 2`.
GENUS[2] = 2

#   part 3: chute bay tube. Started at 1 (plain tube), then 3 after the 2
#   shear pin holes were added (rendered `Genus: 3`, confirmed on a thin
#   Z-band section slice at the pin holes' Z: each is a clean full-wall
#   through-cut, not a blind mark). RE-DERIVED AGAIN (Task 8) after adding
#   the tether tie-off lug + its lashing hole (`Genus: 4`, confirmed on a
#   thin X-slice through the lug: the hole is a clean opening straight
#   through the lug's material, a genuine 4th handle -- the pin holes and
#   tube bore are unaffected, different azimuth, no shared geometry).
#   1 (tube) + 2 (pin holes) + 1 (lug lashing hole) = 4.
#   RE-CONFIRMED (4th review, critical 1/4): the weld ring bridging the
#   spigot to the main wall is a solid annular ADDITION (no new void) and
#   the lug/tab embedding just deepens two ALREADY-solid features into
#   the wall -- neither changes hole count. Rendered, still `Genus: 4`;
#   components() (new this round, see that function's own docstring)
#   changed from 2 to 1 -- the actual defect genus could never see.
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
#   RE-DERIVED (5th review, finding 1): the arming switch moved onto this
#   cover from the e-bay tube -- one more clean through-hole (same
#   through-the-shell-only cut as the 4 bolt holes), 4+1=5; rendered,
#   `Genus: 5`.
GENUS[7] = 5

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
#   RE-DERIVED (4th review, critical 2/5): the corner clip (critical 2)
#   reshapes the outer boundary only -- no new handle, confirmed still
#   `Genus: 4` with just that change applied. The base pass-through
#   (critical 5) is a genuine new through-hole (base_pass_w x
#   R60_Horn_W straight through Base_T, clear of every existing hole):
#   rendered with both fixes, `Genus: 5`, matching the naive +1.
GENUS[13] = 5

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

# Chute-tube-to-fin-can spigot joint (5th review, finding 9) -- the only
# internal coupler joint with no measured mesh-against-mesh clearance
# check before this. Part 9's own forward tip (z=R60_FinCan_L=228) is the
# ONLY Z where the fin can's OWN body ID (28.4) is isolable from the MMT
# that runs the fin can's full length underneath it -- confirmed
# empirically: at z~228 the ONLY 4 radii present are {14.65, 16.15 (MMT
# bore/OD), 28.4, 30.0 (body ID/OD)}, so bore_annulus()'s r_lo=20 cleanly
# keeps just the body pair (a plain bore() call would read the MMT's
# 29.3mm bore as the "min", not the body's own 56.8mm ID). Part 3's own
# spigot tip (z=185.5, its own measured height) is likewise the only Z
# where the spigot's own {26.6, 28.2} pair stands alone, clear of the
# weld-ring transition just below it (z=178..180).
FINCAN_SPIGOT_BAND  = (227.5, 228.01)   # part 9: fin can's forward-open bore
FINCAN_SPIGOT_R_LO  = 20.0               # excludes the MMT (r<=16.15)
CHUTE_SPIGOT_BAND   = (184.5, 185.51)   # part 3: spigot's own tip
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
# TETHER_NOTCH_YHI (6th review, finding 2): the notch cuts ALL THE WAY
# THROUGH the skirt's own curved OD (R60_Coupler_OD/2=28.2, R60Lib.scad's
# Tether_Notch_MinR..R60_Coupler_OD/2+Overlap span) rather than stopping
# blind inside it -- so an UNBOUNDED-above Y window (the old ylo-only
# filter) picks up the OD's own dense $fn=180 tessellation vertices right
# where the flat notch wall merges into the curve, not just the notch
# wall itself. Measured: the old window read 0.897/0.901mm where the
# lug/notch clearance actually built is 0.6mm (R60_Tether_Clear) -- and at
# R60_Tether_Clear=0 (mutation, the notch cut exactly the lug's own
# footprint with zero clearance -- the original defect this check exists
# to catch) it STILL read ~0.9mm and passed, because the number it was
# actually measuring was never the notch's own width at all, it was how
# far the round OD's tessellation happens to spread near that azimuth --
# a quantity R60_Tether_Clear does not touch. Capped comfortably below
# the OD's own radius (28.2) so the window sees only the notch's flat
# side walls, confirmed to still isolate real notch-wall vertices with
# TETHER_NOTCH_YLO (Tether_Notch_MinR sits at ~23.8-24.4 across the
# R60_Tether_Clear range tested).
TETHER_NOTCH_YHI = 27.0

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
# R60_Door_Overlap once assembled; DOOR_HOLE_Z_TUBE is R60_EBayTube()'s
# own Door_Hole_Z, in the TUBE's frame. Both derive from Door_Z0/Door_Z1,
# which move with R60_EBay_L -- restated here at R60_EBay_L=177 (4th
# review, critical 3): Door_Z0=(177-85)/2=46, Door_Z1=46+85=131, so
# DOOR_Z_OFFSET=46-6=40.0 and DOOR_HOLE_Z_TUBE=(46-3, 131+3).
DOOR_Z_OFFSET     = 40.0
DOOR_HOLE_Z_TUBE  = (43.0, 134.0)

# Vega sled retention -- 6th review, finding 1: the rail/zip-tie scheme
# is RETIRED (see R60Lib.scad's "Sled retention" comment). 7th review,
# finding 1/2: the 6th review's own bolted-feet replacement is ALSO
# retired -- it could not physically be inserted (mutation test: a
# real 3.91cm3 collision between the retired foot screw's own swept
# insertion path and the sled's own plate). Replaced by 2 threaded rods
# through continuous rails; see RAIL_X/HOLE_Z_LOCAL/vega_facing_y()/
# rail_hole_center() below.
#
# R60_Vega_Rail_X (R60Lib.scad), restated (rule 4).
RAIL_X = 17.9
# R60_Vega_Rail_d (rail's own rod-clearance hole, both ends) / R60_Vega_
# RodInsert_d (fwd bulkhead's insert, M3-class ~3.4/4.0mm) -- search radii
# below are sized off these, not restated as their own name. The AFT
# bulkhead's own rod pocket is Rail_d (3.4mm), NOT RodInsert_d (4.0mm) --
# it is an unthreaded guide pocket, not a second insert (see R60Lib.scad's
# R60_Vega_RodPocket_Depth comment) -- so it shares RAIL_HOLE_SEARCH_R
# with the rail's own hole, not FWD_INSERT_SEARCH_R.
RAIL_HOLE_SEARCH_R = 2.4     # > Rail_d/2=1.7, < the rail's own edge
FWD_INSERT_SEARCH_R = 2.6    # > RodInsert_d/2=2.0, < the boss edge


def vega_facing_y():
    """R60_Vega_Facing_Y_Nom (R60Lib.scad), restated as the SAME closed
    form (rule 4: a Python file cannot include<> a .scad file) -- the
    deepest the sled's flat back can sit while its own two long back
    corners still clear the tube ID by R60_Vega_Wall_Clear=0.4mm. Body
    ID/2=28.4, Sled_W/2=22.8 (7th review: grew from 22.0 -- the rail now
    has to physically fit on the plate outboard of the board's own mount
    holes, see R60Lib.scad's R60_Vega_Sled_W comment)."""
    return -math.sqrt((28.4 - 0.4) ** 2 - 22.8 ** 2)


def rail_hole_center(stl, band_axis, band_at, cx, cy, search_r, band_win=0.4):
    """Measured (u, v) centre of a round hole's own edge loop, exposed in
    a plane normal to band_axis ('x'/'y'/'z') at band_at, read from
    vertices near (cx, cy) in the OTHER two axes (natural x,y,z order)
    within search_r of it -- same "read the real edge loop, don't infer
    from the constant that cut it" idiom as hole_azimuth_at_r()/
    door_switch_hole(), generalised so ONE function covers both the
    sled's own local frame (band_axis='y', an axially-bored through-hole
    exposed at its own printed tip) and the bulkheads' (band_axis='z', a
    blind hole exposed at a fixed Z face) instead of two near-duplicates."""
    idx = {"x": 0, "y": 1, "z": 2}[band_axis]
    others = [i for i in range(3) if i != idx]
    pts = []
    for tri in tris(stl):
        for p in tri:
            if abs(p[idx] - band_at) <= band_win:
                u, v = p[others[0]], p[others[1]]
                if math.hypot(u - cx, v - cy) <= search_r:
                    pts.append((u, v))
    if not pts:
        raise RuntimeError(
            "no geometry near hole (%.2f,%.2f) %s=%.2f of %s"
            % (cx, cy, band_axis, band_at, stl))
    us = [p[0] for p in pts]
    vs = [p[1] for p in pts]
    return (min(us) + max(us)) / 2.0, (min(vs) + max(vs)) / 2.0

# Door boss OD stations -- defect 2a. TUBE_BAND only reads the tube's
# plain base face (z~0); the door bosses sit at DOOR_HOLE_Z_TUBE, which
# TUBE_BAND never touches, so a boss protruding past the true OD there
# was invisible to every existing OD check.
BOSS_OD_BAND_HALF = 0.05

# Arming switch position -- 5th review, finding 1: MOVED off the tube
# wall onto the access door (part 7). The old defect-2d/4th-review-
# critical-3 Z WINDOW (Sw_Z0/Sw_Z1 on the tube, forever squeezed between
# the door cover's footprint and the neck skirt, and which inverted twice)
# no longer exists -- the switch's position on the door is now a fixed
# LOCAL constant (R60_Door()'s own Sw_X/Sw_Z), independent of R60_EBay_L,
# the neck skirt or the forward bulkhead. DOOR_SW_X_EXPECT/DOOR_SW_Z_EXPECT
# are that module's own Sw_X/Sw_Z, restated as literals (rule 4) --
# confirmed against the rendered part 7 mesh's own switch-hole edge loop
# (x=-6.0..6.0, z=42.5..54.5) before use here.
DOOR_SW_X_EXPECT = 0.0
DOOR_SW_Z_EXPECT = 48.5   # R60_Door_Overlap + R60_Door_Open_H/2 = 6+42.5


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


def door_switch_hole(stl, xhalf=6.5, zlo=20.0, zhi=80.0):
    """Arming-switch hole's own measured (X centre, Z centre), off part 7
    (door cover)'s rendered edge loop (a Ø12 hole cut through the cover's
    own T=2mm shell at its crown, x=0). 5th review, finding 1: this used
    to scan part 2 (the switch lived on the tube wall); the switch has
    since moved to the door, and its position there is a fixed LOCAL
    constant, no longer a derived Z window squeezed against the door
    cover's own footprint and the neck skirt. Factored out of checks()'s
    own inline scan, same reasoning as the old switch_hole_z() it
    replaces, so tools/verify_rocket60_assembly.py's switch-envelope
    probes (r60_assembly.scad) could reuse this measurement too if a
    future round needs it -- they do not currently (the door position has
    no complex derivation left to keep in sync, so they use the SAME fixed
    literal directly). xhalf/zlo/zhi default to a window that isolates the
    switch hole from the door's 4 corner bolt holes (x=+-21) and its own
    top/bottom edges (z=0/97) -- confirmed empirically (x=-6.0..6.0,
    z=42.5..54.5) before use here."""
    pts = [(x, z) for tri in tris(stl) for (x, y, z) in tri
           if abs(x) < xhalf and y > 29.0 and zlo < z < zhi]
    if not pts:
        raise RuntimeError("no switch-hole geometry near the door's crown of %s"
                            % stl)
    xs = [p[0] for p in pts]
    zs = [p[1] for p in pts]
    return (min(xs) + max(xs)) / 2.0, (min(zs) + max(zs)) / 2.0


def hole_flat_max_x(stl, r_at, z_at, x_side=1, r_win=0.02, zwin=1.5):
    """Max flat X reach (x_side>0: +X, else -X) of a hole's own edge loop
    exposed on a cylindrical face at radius r_at, near Z-plane z_at --
    6th review, finding 3.2: a hole bored along the wall's own RADIAL
    direction (not a flat axis) through a CURVED shell sweeps further in
    flat X than its own diameter alone suggests, the same curved-vs-flat
    effect defect 1a (2nd review) fixed for hole AZIMUTH -- so the real
    wall margin past such a hole has to be MEASURED here, not estimated
    from Hole_X + hole radius alone (confirmed: naive predicts ~1.65mm on
    R60_Door()'s own screw holes, the rendered mesh reads ~0.6mm, a real
    ~1mm gap the old check never saw because it never looked at the
    hole's own edge loop at all)."""
    xs = [x for tri in tris(stl) for (x, y, z) in tri
          if abs(math.hypot(x, y) - r_at) <= r_win and abs(z - z_at) <= zwin
          and (x > 0 if x_side > 0 else x < 0)]
    if not xs:
        raise RuntimeError(
            "no hole edge geometry near r=%.2f z=%.2f (x_side=%+d) of %s"
            % (r_at, z_at, x_side, stl))
    return max(xs) if x_side > 0 else min(xs)


def bore_annulus(stl, zlo, zhi, r_lo):
    """Like scad_verify.bore(), but ignores vertices with radius < r_lo
    (5th review, finding 9). bore() returns the GLOBAL min/max radius in a
    Z band -- fine for a plain tube, but R60_FinCan() runs its MMT the
    part's FULL length concentric with the body wall, so a plain bore()
    call at the fin can's forward-open annulus would read the MMT's own
    bore/OD (14.65/16.15mm) as the min/max, not the body's own ID/OD
    (28.4/30.0mm) -- the surface actually mating with the chute tube's
    spigot. r_lo excludes the MMT's own radius range; see
    FINCAN_SPIGOT_BAND/FINCAN_SPIGOT_R_LO's own comment for the
    empirical confirmation this isolates the right pair."""
    rmin, rmax = None, 0.0
    for tri in tris(stl):
        for (x, y, z) in tri:
            if zlo <= z <= zhi:
                r = math.hypot(x, y)
                if r >= r_lo:
                    rmin = r if rmin is None else min(rmin, r)
                    rmax = max(rmax, r)
    if rmin is None:
        raise RuntimeError("no geometry with r>=%.2f in Z band %.2f..%.2f of %s"
                            % (r_lo, zlo, zhi, stl))
    return 2.0 * rmin, 2.0 * rmax


def safe(fn, *args, nvals=1, **kwargs):
    """Call fn(*args, **kwargs); a RuntimeError becomes nan(s) of the same
    shape, not a crash (5th review, finding 6). Every scanner checks()
    calls reads geometry off a rendered mesh and can raise RuntimeError on
    missing/moved features (bore() in scad_verify.py; hole_azimuth_at_r(),
    hole_max_reach(), pin_hole_diameter(), xy_extent_in_window(),
    fincan_slot_width/length(), door_switch_hole(), rail_hole_center()
    in this file) -- only switch_hole_z() (now door_switch_hole()) was
    ever wrapped before this fix. Every OTHER call sat bare in checks(),
    so a single missing/moved feature raised straight out of checks(),
    aborting the WHOLE run with a traceback before any check printed --
    the identical "one bad row kills the whole report" failure class the
    genus loop and the arming-switch check were already fixed for.
    nvals controls how many nan values are returned, matching how many
    the call site unpacks (bore() and rail_hole_center() return 2;
    xy_extent_in_window() returns 4; everything else returns 1) -- nan
    compares false against every tolerance (same convention as a missing
    genus), so a failure here is a loud FAIL on just the checks that
    needed this measurement, not a silent skip or a crash."""
    try:
        return fn(*args, **kwargs)
    except RuntimeError:
        nan = float("nan")
        return nan if nvals == 1 else (nan,) * nvals


def checks(m):
    """Return list of (label, actual, expected, tolerance)."""
    c = []
    a = lambda p, k: m[p][k]

    if 0 in m:
        _, flange_od = safe(bore, a(0, "stl"), *TESTRING_FLANGE_BAND, nvals=2)
        _, spigot_od = safe(bore, a(0, "stl"), *TESTRING_SPIGOT_BAND, nvals=2)
        c += [("test ring flange OD vs nosecone base", flange_od, 59.98, 0.15),
              ("test ring coupler OD", spigot_od, 56.40, 0.15),
              ("test ring height", a(0, "height"), 10.0, 0.1),
              ("test ring zmin", a(0, "zmin"), 0.0, 0.05)]

    if 1 in m:
        _, flange_od = safe(bore, a(1, "stl"), *NECK_FLANGE_BAND, nvals=2)
        _, skirt_od = safe(bore, a(1, "stl"), *NECK_SKIRT_BAND, nvals=2)
        c += [("neck flange OD vs nosecone base", flange_od, 59.98, 0.15),
              ("neck height", a(1, "height"), 24.0, 0.1),
              ("neck zmin", a(1, "zmin"), 0.0, 0.05)]
        # Skirt must actually enter a body tube: measured skirt OD against
        # the measured test-ring coupler OD, never against R60_Coupler_OD.
        if 0 in m:
            _, ring_spigot = safe(bore, a(0, "stl"), *TESTRING_SPIGOT_BAND, nvals=2)
            c += [("neck skirt matches test ring spigot",
                   skirt_od, ring_spigot, 0.10)]

    for p, want_len in ((2, 177.0), (3, 185.5)):
        if p in m:
            tube_id, tube_od = safe(bore, a(p, "stl"), *TUBE_BAND, nvals=2)
            c += [("part %d length" % p, a(p, "height"), want_len, 0.1),
                  ("part %d OD" % p, tube_od, 60.0, 0.1),
                  ("part %d bore" % p, tube_id, 56.8, 0.1)]
            # A tube that will not accept the neck skirt is useless.
            if 1 in m:
                _, skirt_od = safe(bore, a(1, "stl"), *NECK_SKIRT_BAND, nvals=2)
                c += [("part %d bore clears neck skirt" % p,
                       tube_id - skirt_od, 0.4, 0.15)]

    if 2 in m:
        # Door boss OD stations -- defect 2a. TUBE_BAND (z~0) never sees
        # the door bosses, which sit at DOOR_HOLE_Z_TUBE -- a boss
        # protruding past the true OD there (measured dmax 60.40 vs the
        # tube's own 60.00, pre-fix) was invisible to the plain "part 2 OD"
        # check above. Measured at each boss Z station directly.
        for z_boss in DOOR_HOLE_Z_TUBE:
            _, boss_od = safe(bore, a(2, "stl"), z_boss - BOSS_OD_BAND_HALF,
                              z_boss + BOSS_OD_BAND_HALF, nvals=2)
            c += [("part 2 OD at door boss station (z=%.1f)" % z_boss,
                   boss_od, 60.0, 0.1)]

    if 6 in m:
        # sled length: 7th review, finding 1/2 -- now 2 continuous RAILS
        # (constant cross-section, full window length) instead of a plate
        # plus 2 short end feet, but the OVERALL printed length is the
        # same shape of quantity: the full window minus the two (now
        # independently stated) end clearances. Restated per this file's
        # rule 4: R60Lib.scad's R60_Vega_Window_Z1(150.3) -
        # R60_Vega_Window_Z0(12) - R60_Vega_Rail_FwdClear(0.2) -
        # R60_Vega_Rail_AftClear(5.0) = 133.1mm (R60_Vega_Rail_L).
        c += [("sled length", a(6, "ymax") - a(6, "ymin"), 133.1, 0.2),
              ("sled width", a(6, "xmax") - a(6, "xmin"), 45.6, 0.2)]

        if 2 in m:
            # Sled's own back corners clear the e-bay bore -- cross-
            # checked against the MEASURED tube ID (part 2) and MEASURED
            # sled width (part 6), not just trusted from
            # R60_Vega_Facing_Y_Nom's own closed form (vega_facing_y(),
            # restated per rule 4).
            facing_y = vega_facing_y()
            sled_w = a(6, "xmax") - a(6, "xmin")
            tube_id, _ = safe(bore, a(2, "stl"), *TUBE_BAND, nvals=2)
            corner_r = math.hypot(sled_w / 2.0, facing_y)
            c += [("sled back corners clear e-bay bore (radial)",
                   tube_id / 2.0 - corner_r, 0.4, 0.15)]

        # Rail/rod coaxiality (6th review, finding 1 -- REPLACES the
        # rail-capture check, which measured a rail geometry that turned
        # out to be unable to capture anything; 7th review, finding 1/2:
        # feet -> continuous rails; 7th review, finding 5: ymin/ymax
        # pairing FIXED, see below). The sled's own rod-clearance holes
        # must land ON each bulkhead's insert/pocket, not merely both
        # exist: the sled's MEASURED local hole position (X, local Z) is
        # transformed the SAME way R60_VegaSled()'s own assembly placement
        # does (global Y = facing_y + local Z, VegaSledPlaced() in
        # r60_assembly.scad) and compared DIRECTLY against the bulkhead's
        # own MEASURED global hole position -- not against a shared
        # constant either module could independently drift away from
        # while still matching it (a restated literal proves the DESIGN
        # intent agrees, not that either module's IMPLEMENTATION actually
        # builds it there).
        #
        # end<->ymin/ymax pairing (7th review, finding 5): VegaSledPlaced()
        # is `translate([0,facing_y,AxialCenter]) rotate([-90,0,0])
        # R60_VegaSled()` -- rotate([-90,0,0]) maps local (x,y,z) to
        # (x,z,-y), so global_z = AxialCenter - local_y. The sled's own
        # local ymin (most negative -- the rail reaching furthest AWAY
        # from the plate's own centre on the low-Y side) therefore maps to
        # the LARGEST global z (forward, near the neck), and local ymax
        # maps to the SMALLEST global z (aft, near the tube's open end) --
        # the OPPOSITE of what a naive "ymin sounds aft" reading suggests.
        # This file previously paired ("aft", ymin) and ("fwd", ymax),
        # backwards; masked only because both bulkheads' own X/Y hole
        # patterns happen to be identical, so swapping WHICH measured
        # sled-end value got compared against WHICH bulkhead's measured
        # hole never actually changed the arithmetic's result.
        if 4 in m or 5 in m:
            facing_y = vega_facing_y()
            HOLE_Z_LOCAL = 3.3   # R60_Vega_Rail_Z_Local (R60Lib.scad)
            for end, sled_y, bulk_p, search_r in (
                    ("fwd", a(6, "ymin"), 4, FWD_INSERT_SEARCH_R),
                    ("aft", a(6, "ymax"), 5, RAIL_HOLE_SEARCH_R)):
                if bulk_p not in m:
                    continue
                bulk_z = a(bulk_p, "zmin")   # each bulkhead's own hole-
                                               # exposure face (0 for the
                                               # aft disc; the boss tip,
                                               # ~-1.7, for the forward one)
                for x_side in (1, -1):
                    hx, hz = safe(rail_hole_center, a(6, "stl"), "y", sled_y,
                                  x_side * RAIL_X, HOLE_Z_LOCAL,
                                  RAIL_HOLE_SEARCH_R, nvals=2)
                    sled_global_y = facing_y + hz
                    bx, by = safe(rail_hole_center, a(bulk_p, "stl"), "z",
                                  bulk_z, x_side * RAIL_X,
                                  facing_y + HOLE_Z_LOCAL,
                                  search_r, nvals=2)
                    c += [("%s rail/insert coaxial X (x=%+.0f side)"
                           % (end, x_side * RAIL_X), hx - bx, 0.0, 0.4),
                          ("%s rail/insert coaxial Y (x=%+.0f side)"
                           % (end, x_side * RAIL_X),
                           sled_global_y - by, 0.0, 0.4)]

    if 7 in m:
        # FIXED (defect 1d): R60_Door() is now a COVER, DOOR_OVERLAP larger
        # than the aperture on every side (not a plug DOOR_GAP smaller),
        # resting on solid tube material with 4 screws into real bosses --
        # see R60_Door()'s module comment. The door's 85mm dimension runs
        # along Z; its Y extent is only the chord depth of the curved
        # cover, so measure height, not ymax-ymin.
        #
        # DOOR_COVER_W_EXPECT (6th review, finding 3.2): the X width is no
        # longer just DOOR_OPEN_W+2*DOOR_OVERLAP -- R60_Door()'s own
        # Cover_W now also has to leave a real wall past the screw hole's
        # own edge (its module comment), and that requirement is the
        # larger of the two here at the current dimensions:
        # max(18+6, 21+1.35+1.6+1.5) = max(24, 25.45) = 25.45, so
        # Cover_W = 2*25.45 = 50.9. Restated as a literal per this file's
        # rule 4, matching R60_Door()'s own Cover_HalfW formula.
        DOOR_COVER_W_EXPECT = 50.9
        c += [("door cover height", a(7, "height"),
               DOOR_OPEN_H + 2 * DOOR_OVERLAP, 0.15),
              ("door cover chord width", a(7, "xmax") - a(7, "xmin"),
               DOOR_COVER_W_EXPECT, 0.15)]

        # Screw hole wall margin (6th review, finding 3.2) -- see
        # hole_flat_max_x()'s own docstring. Checked MESH AGAINST MESH,
        # both sides off this SAME render: the hole's own edge loop (at
        # the cover's outer face, r=R60_Body_OD/2+T=32, near the bottom
        # hole's own Z) against the part's own overall measured xmax
        # (a(7,"xmax"), the SAME quantity the "door cover chord width"
        # check above already reads) -- not against DOOR_COVER_W_EXPECT/2,
        # a hand-typed literal a regression in R60_Door()'s own Cover_W
        # formula could silently drift away from while this check kept
        # comparing against the OLD, no-longer-true value (confirmed:
        # reverting Cover_HalfW to its pre-fix formula while leaving a
        # literal-based version of this check untouched still read the
        # ORIGINAL 2.109mm margin -- a check that cannot see the part it
        # is supposed to be measuring is exactly finding 2's "cannot
        # fail" class, so this reads the mesh's own actual edge instead).
        # want/tol matches the rendered margin (~2.11mm) with real room to
        # catch a regression toward the old ~0.6mm defect.
        hole_max_x = safe(hole_flat_max_x, a(7, "stl"), BODY_R + 2.0, 3.0)
        c += [("door cover screw hole wall margin",
               a(7, "xmax") - hole_max_x, 2.1, 0.6)]

        # Arming switch position -- 5th review, finding 1: nothing checked
        # this on the door before (it did not live there); this reads the
        # switch hole's own measured (X, Z) centre directly off its
        # rendered edge loop and checks it against the door's own stated
        # local position, catching silent drift even where the render
        # still succeeds. An empty scan (hole missing or moved outside the
        # pre-filter window) is a loud FAIL (nan against any tolerance),
        # not a silently-skipped row -- same convention as every other
        # try/except RuntimeError -> nan in this file.
        try:
            sw_x, sw_z = door_switch_hole(a(7, "stl"))
        except RuntimeError:
            sw_x, sw_z = float("nan"), float("nan")
        c += [("door switch hole X centre", sw_x, DOOR_SW_X_EXPECT, 0.3),
              ("door switch hole Z centre", sw_z, DOOR_SW_Z_EXPECT, 0.3)]

        # Retention: the cover must be LARGER than the aperture it covers
        # on every side (defect 1d's actual fix -- a plug smaller than its
        # own hole cannot be retained no matter what else is added).
        if 2 in m:
            door_h = a(7, "height")
            door_w = a(7, "xmax") - a(7, "xmin")
            # Width overlap grew past 2*DOOR_OVERLAP (6th review, finding
            # 3.2 -- see DOOR_COVER_W_EXPECT's own comment above): still a
            # real, checked minimum, just no longer exactly 2*DOOR_OVERLAP
            # on this axis now that the screw-hole wall requirement binds
            # instead of the plain retention-overlap one.
            c += [("door cover overlaps aperture height",
                   door_h - DOOR_OPEN_H, 2 * DOOR_OVERLAP, 0.3),
                  ("door cover overlaps aperture width",
                   door_w - DOOR_OPEN_W, DOOR_COVER_W_EXPECT - DOOR_OPEN_W, 0.3)]

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
                    tube_az = safe(hole_azimuth_at_r, a(2, "stl"), tx, ty,
                                   z_tube, BODY_R)
                    door_az = safe(hole_azimuth_at_r, a(7, "stl"), tx, ty,
                                   z_tube - DOOR_Z_OFFSET, COVER_OUTER_R)
                    c += [("tube boss axis azimuth (x=%+.0f z=%.1f)"
                           % (tx, z_tube), tube_az, target_az, 1.0),
                          ("door hole axis azimuth (x=%+.0f z=%.1f)"
                           % (tx, z_tube), door_az, target_az, 1.0)]

    # Part 5's height grew from a plain 12mm disc to 12 + a 15mm aft skirt
    # (SKIRT_T + 15 = 27) that carries the shear pins into the real joint --
    # see R60_EBayAftBulkhead()'s module comment. Part 4's height grew
    # from a plain 6mm disc to 6 + a 1.7mm foot boss that reaches AFT of
    # (past) its own z=0 face (6th review, finding 1) -- see
    # R60_EBayFwdBulkhead()'s own module comment for why T=6mm alone is
    # too shallow for the ruthex insert this boss exists to host.
    for p, want_h in ((4, 7.7), (5, 27.0)):
        if p in m:
            _, bulk_od = safe(bore, a(p, "stl"), *BULK_BAND, nvals=2)
            c += [("part %d height" % p, a(p, "height"), want_h, 0.1)]
            # Must drop into a tube bore, measured against the real tube.
            if 2 in m:
                tube_id, _ = safe(bore, a(2, "stl"), *TUBE_BAND, nvals=2)
                c += [("part %d fits e-bay bore" % p,
                       tube_id - bulk_od, 0.4, 0.15)]

    # Shear pins bridge the ACTUAL separable joint: chute tube (part 3) and
    # the aft bulkhead's skirt (part 5), not the spring carrier (part 8).
    # Both holes are read straight off the rendered mesh at the Z each part
    # was cut at, so a hole that silently didn't break through, or landed
    # off-target, fails here rather than in the report.
    if 3 in m:
        for x_side in (1, -1):
            d = safe(pin_hole_diameter, a(3, "stl"), x_side, PIN_Z_CHUTE, PIN_R_CHUTE)
            c += [("chute tube shear pin dia (x=%+d side)" % x_side,
                   d, PIN_D, 0.3)]
    if 5 in m:
        for x_side in (1, -1):
            d = safe(pin_hole_diameter, a(5, "stl"), x_side, PIN_Z_SKIRT, PIN_R_SKIRT)
            c += [("aft bulkhead skirt shear pin dia (x=%+d side)" % x_side,
                   d, PIN_D, 0.3)]

        # Cross-part interference (defect 1a): part 3's tether lug vs.
        # part 5's relief notch through the skirt it inserts into. This
        # class of defect -- both parts individually correct, colliding
        # only once mated -- is invisible to any single-part measurement
        # above, which is exactly why it shipped once already.
        if 3 in m:
            lug_xmin, lug_xmax, lug_ymin, _ = safe(xy_extent_in_window,
                a(3, "stl"), *TETHER_LUG_XZ, nvals=4)
            notch_xmin, notch_xmax, notch_ymin, _ = safe(xy_extent_in_window,
                a(5, "stl"), *TETHER_NOTCH_XZ, ylo=TETHER_NOTCH_YLO,
                yhi=TETHER_NOTCH_YHI, nvals=4)
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
        # defect). NARROWED to 5.0 (5th review, finding 13: this comment
        # used to say "widened", the wrong direction for the 6.0->5.0
        # change it describes -- a reader trusting "widened" would push it
        # back up and reintroduce the 0.02mm near-miss), giving ~1mm of
        # real margin (6.02-5.0) before the search circle reaches the horn
        # slot's own void, while still comfortably bigger than the insert
        # hole's own Ø4 (radius 2.0) edge loop.
        for x_side in (1, -1):
            reach = safe(hole_max_reach, a(5, "stl"), x_side * insert_x,
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
        tab_inner_r, _ = safe(bore, a(3, "stl"), *STOPTAB_BAND, nvals=2)
        tab_inner_r /= 2.0
        c += [("spring tab overlaps spring OD (radial)",
               SPRING_OD / 2.0 - tab_inner_r, 2.0, 1.3)]

    if 8 in m:
        _, carrier_od = safe(bore, a(8, "stl"), *SHEARPIN_BAND, nvals=2)
        carrier_bore, _ = safe(bore, a(8, "stl"), *CARRIER_STEP_BAND, nvals=2)
        c += [("spring carrier OD", carrier_od, 56.40, 0.15),
              ("spring carrier bore takes CS4323", carrier_bore, 44.80, 0.30)]
        if 3 in m:
            tube_id, _ = safe(bore, a(3, "stl"), *TUBE_BAND, nvals=2)
            c += [("carrier clears chute bore", tube_id - carrier_od, 0.4, 0.15)]

    if 9 in m:
        mmt_id, can_od = safe(bore, a(9, "stl"), *FINCAN_BAND, nvals=2)
        # (defect 3e: "fin can fits 250mm Z" used to be emitted here too,
        # hardcoded to 250.0 -- a duplicate of the generic "part %d fits
        # %.0fmm Z" loop below, which already covers every part
        # (including 9) off the single MAX_Z constant. Removed rather than
        # kept in sync twice.)
        c += [("fin can length", a(9, "height"), 228.0, 0.2),
              ("fin can OD", can_od, 60.0, 0.1),
              ("MMT bore takes 29mm motor", mmt_id, 29.3, 0.15)]

        # Chute-tube-to-fin-can spigot (5th review, finding 9) -- the only
        # internal coupler joint that had no measured clearance check.
        # Mesh-against-mesh, same 0.4+-0.15mm convention as every other
        # internal spigot-into-bore joint in this file (e.g. "part %d bore
        # clears neck skirt" above): the fin can's own forward-open bore
        # (its body ID, isolated from the full-length MMT by
        # bore_annulus()) measured against the chute tube's own spigot OD.
        if 3 in m:
            fincan_bore, _ = safe(bore_annulus, a(9, "stl"),
                                   *FINCAN_SPIGOT_BAND, FINCAN_SPIGOT_R_LO,
                                   nvals=2)
            _, spigot_od = safe(bore, a(3, "stl"), *CHUTE_SPIGOT_BAND, nvals=2)
            c += [("chute tube spigot clears fin can forward bore",
                   fincan_bore - spigot_od, 0.4, 0.15)]
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
        slot_w = safe(fincan_slot_width, a(9, "stl"))
        c += [("fin slot width fits fin thickness",
               slot_w - a(10, "height"), 0.2, 0.1)]
        # Length clearance added after a coordinator review: the original
        # slot was line-to-line with the fin's 90mm root chord (0 printed
        # clearance over 90mm -- not assemblable). Same mesh-against-mesh
        # method as the width check: fin root chord read from part 10's own
        # STL, slot length read from part 9's, no shared inputs.
        slot_l = safe(fincan_slot_length, a(9, "stl"))
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
        _, ret_od = safe(bore, a(11, "stl"), *RETAINER_BAND, nvals=2)
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
        ring_bore, ring_od = safe(bore, a(14, "stl"), *THRUST_RING_BAND, nvals=2)
        c += [("thrust ring height", a(14, "height"), 6.0, 0.1),
              ("thrust ring OD", ring_od, 28.9, 0.1),
              ("thrust ring bore", ring_bore, 26.8, 0.1)]
        if 9 in m:
            mmt_id, _ = safe(bore, a(9, "stl"), *FINCAN_BAND, nvals=2)
            c += [("thrust ring fits MMT bore", mmt_id - ring_od, 0.4, 0.15)]
        if 12 in m:
            _, spacer_od = safe(bore, a(12, "stl"), *THRUST_RING_BAND, nvals=2)
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

    # Build volume, every part -- 6th review, finding 4: this used to
    # derive its own "expected" FROM the measurement (min(height, MAX_Z)),
    # so a part comfortably under budget printed "177.000  want 177.000"
    # -- a passing row that looks like a no-op self-comparison rather than
    # the real constraint (height <= MAX_Z) it was supposed to state.
    # Reports the OVERAGE past MAX_Z instead (0 for anything that fits,
    # the actual excess in mm otherwise) against a stated 0 -- legible
    # either way, and still fails loudly (and more usefully, by how much)
    # for a part that does not fit.
    for p in m:
        c += [("part %d fits %.0fmm Z" % (p, MAX_Z),
               overshoot(m[p]["height"], MAX_Z), 0.0, 0.01)]

    # Connected components, every part (4th review, harden-the-harness
    # item 1). A part that exports as N disjoint solids is unprintable as
    # ONE part (finding 1: the chute tube's fin-can spigot, floating
    # entirely inside the tube's own bore with a 0.2mm gap and zero shared
    # geometry) -- genus cannot see this (see components()'s own
    # docstring), so this is a real, independent check, not a restatement
    # of the genus checks below.
    for p in m:
        c += [("part %d connected components" % p,
               components(m[p]["stl"]), 1, 0)]

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
    bad = 0
    # `return 1` on a failed render (6th review, finding 4) used to abort
    # the WHOLE run: any part after the failed one never rendered, and
    # checks() -- and every one of its ~90 rows -- never printed at all,
    # the identical "one bad row kills the whole report" failure class
    # safe() was introduced to fix for individual checks, one level up.
    # A failed/slow render is now a counted FAIL for just that part, and
    # the loop (and the report) continues with whatever DID render.
    for p in parts:
        out = os.path.join(tmp, "part%d.stl" % p)
        try:
            g = render(SCAD, p, out)
        except (RuntimeError, subprocess.TimeoutExpired) as e:
            print("FAIL  render part %d (%s)\n%s" % (p, NAMES.get(p, "?"), e))
            bad += 1
            continue
        m[p] = measure(out, g)
        print("rendered %-2d %-20s  %.2f x %.2f x %.2f mm  %.1f cm3"
              % (p, NAMES.get(p, "?"), m[p]["xmax"] - m[p]["xmin"],
                 m[p]["ymax"] - m[p]["ymin"], m[p]["height"], volume(out)))
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
