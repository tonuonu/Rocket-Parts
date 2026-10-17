#!/usr/bin/env python3
"""Render and measure Rocket 60 parts.

A part that does not fit still renders cleanly, so every mating dimension is
measured from the STL rather than inferred from the parameter that was
supposed to produce it.
"""
import math, os, shutil, subprocess, sys, tempfile

from scad_verify import REPO, render, measure, bore, volume, tris, components, overshoot, safe, shortfall

SCAD = os.path.join(REPO, "Rocket60.scad")

NAMES = {0: "test ring", 1: "neck", 2: "e-bay tube",
         3: "deployment bay tube fwd",
         4: "ebay fwd bulkhead", 5: "ebay aft bulkhead", 6: "vega sled",
         7: "access door", 8: "petal hub", 9: "fin can", 10: "fin",
         11: "motor retainer", 12: "motor spacer", 13: "petals",
         14: "thrust ring", 15: "release activator", 16: "release top retainer",
         17: "release lock ring", 18: "release outer bearing retainer",
         19: "release trigger post", 20: "release magnet bracket",
         21: "release extension rod", 22: "release locking pin",
         23: "forward spring end", 24: "petal spring holder",
         25: "spring centering ring mount", 26: "deployment bay tube aft"}

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
#   drops the count 6-4=2; rendered, confirmed `Genus: 2`. RE-DERIVED
#   (task 6, static vent port): 3 plain radial through-holes at 120deg
#   added (R60Lib.scad's R60_Vent_d/R60_Vent_Z comment) -- +3 handles;
#   rendered, confirmed `Genus: 5`.
GENUS[2] = 5

#   part 3: deployment bay tube (petal-deployment transplant). The
#   separable joint (and everything that used to punch through this
#   tube's wall for it -- shear pins, the tether lug/lashing hole, the
#   weld ring/spigot) moved entirely to the petal cage (parts 8/13); this
#   is now a genuinely plain tube -- R60_Tube() alone, one bore, no other
#   feature. Rendered `Genus: 1`. 12th review: now the FORWARD piece of
#   the split tube (R60_ChuteTubeFwd(), part 26 is the aft piece) -- the
#   spigot at its own aft end is still topologically a plain hollow tube
#   (no added holes/handles), genus unchanged, confirmed by re-rendering.
GENUS[3] = 1

#   part 5: e-bay aft bulkhead (petal-deployment transplant). Servo 2's
#   pocket+horn, both shear pins, the tether relief channel and the
#   tether-latch insert holes are all deleted outright (single deploy has
#   no second servo/tether phase; the joint moved to the petal cage) --
#   servo 1 itself also moved OFF this part, onto part 15's own Activator
#   print, so there is no shaft bore here either. What remained: 2 shock-
#   cord through-holes (+2 handles on the plain disc+skirt solid, which
#   is otherwise a solid puck -- no bore of its own, confirmed on the
#   rendered mesh) + 2 blind Vega rod pockets (0, blind -- this file used
#   to say 3 here; the code (`for (x=[-R60_Vega_Rail_X,
#   R60_Vega_Rail_X])`) only ever cut 2, a stale-comment mismatch this
#   review fixed, harmless to the total either way since a blind pocket
#   contributes 0 regardless of count) + 3 blind Activator mounting
#   inserts (0, blind) = 2. Rendered `Genus: 2`.
#
#   RE-DERIVED (10th review, critical fix 1): the 3 blind M3 inserts
#   above were the wrong mounting interface entirely (R60_EBayAftBulkhead()'s
#   own module comment) -- replaced with 2 THROUGH #10-24 clearance holes
#   (+2, both ends now genuinely open: this disc's forward face and the
#   skirt's own aft tip) into CRBBm_Activator()'s real host-mount ring. The
#   same fix hollows the skirt's own middle span to a plain tube, capped
#   both ends by solid material (the disc at the forward end, a new Web_T
#   web at the aft tip) -- a fully SEALED internal cavity with no opening
#   to either exterior face, which this file's own convention (immune to
#   a print's "how many voids" question by construction, per this
#   function's own docstring) counts as ONE additional handle, the same
#   way OpenSCAD's own Genus already counts every other through-feature
#   here. Total: 2 (cord) + 0 (rod pockets) + 2 (activator screws,
#   through) + 1 (sealed skirt cavity) = 5. Rendered, confirmed `Genus: 5`.
GENUS[5] = 5

#   part 7: curved door cover. 4 bolt holes = 4. Unchanged across the
#   defect 1a azimuth fix -- that fix repositions each hole's AXIS, not
#   its count or through/blind nature; re-rendered, still `Genus: 4`.
#   RE-DERIVED (5th review, finding 1): the arming switch moved onto this
#   cover from the e-bay tube -- one more clean through-hole (same
#   through-the-shell-only cut as the 4 bolt holes), 4+1=5; rendered,
#   `Genus: 5`.
GENUS[7] = 5

#   part 8: petal hub (petal-deployment transplant, replaces the spring
#   carrier). R65_PetalHub() (R65Lib.scad) plus this task's own added aft
#   spigot into the fin can -- library geometry, not feature-counted by
#   hand here the way this file's own hand-built parts are (see file
#   docstring: measured off the rendered mesh, not inferred).
#   RE-DERIVED (11th review, critical fix 1): the spigot moved off the
#   petal-mating face onto the skirt/-z face (tasks/lessons.md -- the
#   OLD placement put the spigot inside the petals' own envelope, a
#   1.31cm3 collision, not merely a different genus). The spigot now
#   welds onto the skirt's OWN existing bolt-hole face instead of the
#   plain PD_PetalHub() body, changing which topological holes merge --
#   re-rendered, `Genus: 16`.
GENUS[8] = 16

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

#   part 13: petals (petal-deployment transplant, replaces the tether
#   latch). PD_Petals() (PetalDeploymentLib.scad), HasLocks=true --
#   library geometry, same "measured, not hand-counted" treatment as
#   part 8. Rendered `Genus: 7`.
GENUS[13] = 7

#   part 14: forward thrust ring (3rd review defect 3) =
#   1 (a plain annulus -- one through-hole, same class as part 12's
#   spacer tube). Rendered `Genus: 1`.
GENUS[14] = 1

#   parts 15-23: release hardware (petal-deployment transplant),
#   `use<>`-instantiated from CableReleaseBBMicro.scad/R65Lib.scad -- all
#   library geometry, measured off each rendered mesh this session, same
#   treatment as parts 8/13 above.
GENUS[15] = 25   # release activator
GENUS[16] = 10   # release top retainer
GENUS[17] = 10   # release lock ring
GENUS[18] = 8    # release outer bearing retainer
GENUS[19] = 2    # release trigger post
GENUS[20] = 3    # release magnet bracket
GENUS[21] = 1    # release extension rod
GENUS[22] = 1    # release locking pin
GENUS[23] = 7    # forward spring end

#   part 24: petal spring holder (11th review, critical fix 2 -- the
#   hinge subsystem, missing entirely from the first transplant attempt,
#   tasks/lessons.md). `use<>`-instantiated from PetalDeploymentLib.scad's
#   own PD_PetalSpringHolder(), un-parameterised library geometry --
#   measured off the rendered mesh, same treatment as parts 8/13/15-23
#   above. Rendered `Genus: 3`.
GENUS[24] = 3    # petal spring holder

#   part 25: spring centering ring mount (11th review, fix 4 -- gives the
#   CS4323 a real seat, see R60_CenteringRingMount()'s own module
#   comment). `use<>`-instantiated from CableReleaseBBMicro.scad's own
#   CRBBm_CenteringRingMount(), parameterised for the CS4323 -- library
#   geometry, measured off the rendered mesh, same treatment as every
#   other use<>'d part above. RE-DERIVED (same session): nRopes=0 first
#   read Genus 4 but `components()`==3 -- nRopes also controls this
#   part's own structural spokes, not just the (unneeded) rope holes,
#   and 0 deleted both, splitting the part into 3 disconnected pieces
#   (caught by this file's own connected-components check). nRopes=6
#   restores the spokes (rope holes unused but harmless -- see
#   R60_CenteringRingMount()'s own module comment); re-rendered,
#   `Genus: 22`, `components()`==1.
GENUS[25] = 22   # spring centering ring mount

#   part 26: deployment bay tube, AFT piece (12th review, the tube
#   split -- owner's ruling, R60_Chute_L=275 exceeds the print envelope
#   as one piece). Same topology as part 3 (a plain hollow tube, socket
#   bored into one end): rendered `Genus: 1`.
GENUS[26] = 1

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
# 12th review, the tube split: part 3's spigot (near its own top, not its
# base -- R60_ChuteSplit_Z=137 in) and part 26's socket (at its own base)
# and true aft-end tube cross-section (past the socket+taper). Bands
# reach real edge loops (spigot tip Z=143, socket taper end Z=7) per this
# section's own convention above.
CHUTE_SPIGOT_BAND = (142.5, 143.01)     # part 3: spigot OD near its tip
CHUTE_SOCKET_BAND = (-0.01, 0.5)        # part 26: socket ID/OD at its base
CHUTE_AFT_TOP_BAND = (137.5, 138.01)    # part 26: true aft-end, past the
                                          # socket+taper -- normal tube
R60_ChuteSplit_SocketID_restated = 58.8   # R60Lib.scad's own
                                            # R60_ChuteSplit_SocketID --
                                            # restated (rule 4)

# Spring pocket entry clearance (coordinator fix 1 -- the CS4323's real
# catalog OD (44.45mm) does not fit the pre-fix pocket, cut at exactly
# R60_Spring_OD with zero clearance). R60Lib.scad's own R60_Spring_OD/
# R60_Spring_Clear, restated (rule 4). Band picks the pocket's own true
# entry-face ring: CRBBm_CenteringRingMount()'s local z=Thickness=6 (the
# part's own open/outer face) maps to global z=-6 here because
# R60_CenteringRingMount() wraps it in rotate([180,0,0]) -- confirmed by
# rendering: a global-z scan of the rendered mesh finds a clean, isolated
# 44.839mm ring right at z=-6..-5.6 (vs the intended 44.85mm nominal --
# the same ~0.01mm $fn-faceting undershoot this part's own module comment
# already documents for its pre-fix 44.30-nominal/44.29-measured pocket).
SPRING_POCKET_BAND = (-6.0, -5.6)   # part 25: entry-bore ring at the
                                      # part's own open face
R60_Spring_OD_restated = 44.45      # R60Lib.scad's own R60_Spring_OD
                                      # (catalog), restated (rule 4)

# Petal lock nub arc scan (13th review) -- r_thresh sits cleanly below
# both of PD_Petals()' own plain-wall radii at this OD (ID/2=26.6,
# OD/2=28.2) and above the transitional hull faces of PD_PetalLocks()'s
# own nub geometry, isolating just the nub tips (measured minimum
# r=24.2 this session) -- see petal_lock_arcs()'s own docstring.
PETAL_LOCK_R_THRESH = 25.5
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
# bore/OD), 28.4, 30.0 (body ID/OD)}, so bore()'s own r_lo=20 (9th review:
# was a separate bore_annulus() wrapper, now bore()'s own optional
# parameter) cleanly keeps just the body pair (a plain r_lo=0.0 bore()
# call would read the MMT's 29.3mm bore as the "min", not the body's own
# 56.8mm ID).
FINCAN_SPIGOT_BAND  = (227.5, 228.01)   # part 9: fin can's forward-open bore
FINCAN_SPIGOT_R_LO  = 20.0               # excludes the MMT (r<=16.15)
# Petal hub's own aft spigot (petal-deployment transplant -- this joint
# used to be made by the chute tube's own spigot, now by part 8 instead,
# R60Lib.scad's R60_PetalHubSpigot_L comment). 11th review: moved off the
# petal-mating face (was translate([0,0,16]), the same band the petals'
# own root collided with -- tasks/lessons.md) onto the skirt/-z face:
# translate([0,0,-5-R60_PetalHubSpigot_L(5.5)]) = tip at z=-10.5, part 8's
# own measured minimum Z (R60_PetalHub() re-rendered this session:
# Z[-10.5,16]).
PETALHUB_SPIGOT_BAND = (-10.51, -10.0)
R60_Coupler_OD = 56.4   # restated literal (rule 4), matching R60Lib.scad
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

# Part 8 (petal hub) / part 13 (petals): no dimensional bands of their
# own here -- they are library geometry (R65Lib.scad/PetalDeploymentLib.scad),
# checked instead by BORE_CHECKS' generic max-radius-vs-bore probe below
# (the fit question this transplant actually turns on) rather than by
# hand-picked Z-bands into features this file did not design.
#
# Deleted outright (petal-deployment transplant): SHEARPIN_BAND,
# CARRIER_STEP_BAND, PIN_D/PIN_Z_FROM_JOINT/SKIRT_T/PIN_Z_CHUTE/
# PIN_Z_SKIRT/PIN_R_CHUTE/PIN_R_SKIRT, TETHER_LUG_XZ/TETHER_NOTCH_XZ/
# TETHER_NOTCH_YLO/TETHER_NOTCH_YHI, SPRING_OD/STOPTAB_BAND,
# R60_TETHER_Y -- every one of these fed a check for a feature (shear
# pins, spring reaction tabs, tether lug/notch/insert) that no longer
# exists anywhere in this design. See tasks/lessons.md.

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

# R60Lib.scad's own R60_Vega_Rail_FwdTip_Y/AftTip_Y (8th review, finding
# 1), restated (rule 4): the rail's two tip positions in the sled's own
# local Y frame, local -Y = fwd (hard stop against the fwd bulkhead's
# rod-boss face), local +Y = aft (nut+washer bearing face) -- see that
# constant's own R60Lib.scad comment for the full local-Y-to-global-Z
# derivation. Checked directly against the sled's own measured ymin/ymax
# below (not just their DIFFERENCE, which is the "sled length" check
# above and cannot tell a swapped-ends sled from a correct one).
RAIL_FWDTIP_Y = -68.95
RAIL_AFTTIP_Y = 64.15


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
    though both were built from the identical Hole_X.

    (9th review) Circular mean, not a plain arithmetic mean of the degree
    values: this file's own probed features all sit near +Y (well away
    from the +-180 seam), so the bug was latent, not live, but a plain
    mean is simply wrong across that wrap -- +179 and -179 average to
    ~0 (confirmed: sum([179.0,-179.0])/2 == 0.0), nowhere near either
    input, because degrees restart at -180 rather than continuing past
    +180. Summing each vertex's own unit vector and taking atan2 of the
    total is the standard fix -- equivalent to a plain mean far from the
    seam (where it agrees with the old code to the last decimal on every
    real check this file runs today) and correct AT the seam, so this is
    a pure robustness fix with no effect on any current passing check."""
    pts = [(x, y) for tri in tris(stl)
           for (x, y, z) in tri
           if abs(z - z_at) <= zwin and math.hypot(x - cx, y - cy) <= search_r
           and abs(math.hypot(x, y) - r_target) <= r_win]
    if not pts:
        raise RuntimeError(
            "no geometry near (%.2f,%.2f) r=%.1f z=%.1f of %s"
            % (cx, cy, r_target, z_at, stl))
    sx = sum(x / math.hypot(x, y) for (x, y) in pts)
    sy = sum(y / math.hypot(x, y) for (x, y) in pts)
    return math.degrees(math.atan2(sy, sx))


def vent_hole(stl, y_half=3.0, r_target=30.0, r_win=0.05, zlo=15.0, zhi=45.0):
    """Static vent hole's own measured (diameter, Z centre), off part 2's
    rendered OD-breakthrough edge loop for the i=0 hole (R60Lib.scad's
    R60_Vent_d/R60_Vent_Z, R60_EBayTube()'s own cut) -- 10th review: this
    constant was previously UNCHECKED against the rendered part at all,
    the same "restated but never measured" gap this file's own rule 4
    exists to close. Isolates the i=0 hole (the other two sit at +-120deg,
    well outside |y|<y_half) at the OD (r_target=R60_Body_OD/2), not the
    ID breakthrough -- the OD loop is what actually reads as a clean
    round hole (or does not) from outside the part."""
    pts = [(x, y, z) for tri in tris(stl) for (x, y, z) in tri
           if abs(math.hypot(x, y) - r_target) < r_win and abs(y) < y_half
           and zlo < z < zhi]
    if not pts:
        raise RuntimeError("no vent-hole geometry near r=%.1f of %s"
                            % (r_target, stl))
    zs = [p[2] for p in pts]
    return max(zs) - min(zs), (min(zs) + max(zs)) / 2.0


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


def petal_lock_arcs(stl, zlo, zhi, r_thresh, gap_deg=2.0):
    """Azimuthal arcs (list of (start_deg, end_deg), 0..360, wraparound
    merged) of INWARD-projecting lock-nub material in a petal's own
    rendered mesh, within Z-band [zlo,zhi] and radius <= r_thresh -- the
    mesh-level guard for `Lock_Span_a` (13th review: this constant
    regressed to the library default 0 -- full-circumference lock
    ridges, ~4x the donor's flown engagement -- once already, silently,
    because nothing checked the RENDERED part, only the source line
    that sets it). PD_PetalLocks()'s own geometry (PetalDeploymentLib.
    scad) is a hull of small cylinders/cube corners dipping inward from
    the petal's plain wall surfaces (which sit at r=ID/2=26.6 and
    r=OD/2=28.2 in this design) down to a real, measured minimum around
    r=24.2 -- r_thresh=25.5 (PETAL_LOCK_R_THRESH below) sits cleanly
    below both plain-wall radii and above the transitional hull faces,
    isolating just the nub tips, confirmed empirically (this session:
    the same scan at Lock_Span_a=0 -- full-circumference -- returns
    exactly ONE arc spanning the full 360 degrees, not three).

    Vertices are bucketed to whole-degree azimuth and merged into arcs
    wherever the gap to the next occupied bin exceeds gap_deg (a real
    nub is a contiguous cluster; ordinary mesh sampling noise is not) --
    same "reachable edge loop, not an inferred value" idiom as this
    file's own hole_azimuth_at_r()/fincan_slot_width(), generalised to
    return every contiguous arc instead of one hole's mean position,
    since the defect this check exists to catch is about arc COUNT and
    SPACING, not a single position."""
    pts = []
    for tri in tris(stl):
        for (x, y, z) in tri:
            if zlo <= z <= zhi:
                r = math.hypot(x, y)
                if r <= r_thresh:
                    pts.append(math.degrees(math.atan2(y, x)) % 360.0)
    if not pts:
        return []
    pts.sort()
    arcs = []
    start = prev = pts[0]
    for t in pts[1:]:
        if t - prev > gap_deg:
            arcs.append((start, prev))
            start = t
        prev = t
    arcs.append((start, prev))
    # Merge wraparound (an arc that straddles the 0/360 seam splits into
    # a piece at the start of the sorted list and a piece at the end).
    if len(arcs) > 1 and arcs[0][0] < gap_deg and (360.0 - arcs[-1][1]) < gap_deg:
        first = arcs.pop(0)
        last = arcs.pop(-1)
        arcs.append((last[0] - 360.0, first[1]))
        arcs.sort()
    return arcs


def petal_lock_metrics(stl, zlo, zhi, r_thresh, gap_deg=2.0):
    """(n_arcs, avg_span, max_spacing_dev_from_120) -- a fixed-size
    numeric summary of petal_lock_arcs(), so it fits this file's own
    (label, actual, expected, tol) checks() convention (a variable-
    length arc list does not). max_spacing_dev_from_120 is nan-safe-
    sentinelled to a large, obviously-failing value (999.0) whenever
    there are not at least 2 arcs to measure spacing between at all --
    same "cannot silently read as a pass" reasoning as scad_verify.py's
    own overshoot()/shortfall() nan handling, so a Lock_Span_a=0
    regression (1 merged arc, no spacing to compute) fails the spacing
    check for an honest reason (no arcs to space out) instead of a
    division/indexing error, or worse, a vacuous skip."""
    arcs = petal_lock_arcs(stl, zlo, zhi, r_thresh, gap_deg)
    n = len(arcs)
    if n == 0:
        return (0, 0.0, 999.0)
    spans = [b - a for (a, b) in arcs]
    avg_span = sum(spans) / n
    if n < 2:
        return (n, avg_span, 999.0)
    centers = sorted((a + b) / 2.0 % 360.0 for (a, b) in arcs)
    spacings = [(centers[(i + 1) % n] - centers[i]) % 360.0 for i in range(n)]
    max_dev = max(abs(s - 360.0 / n) for s in spacings)
    return (n, avg_span, max_dev)


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


# bore_annulus()/safe() moved to scad_verify.py (9th review): bore_annulus
# duplicated bore()'s ENTIRE scan body just to add the r_lo filter, and
# lost bore()'s own memoisation doing it -- bore() itself now takes an
# optional r_lo (same filter, same cache key), and safe() moved there too
# so verify_nosecone.py's own bare bore() calls -- the same "one bad row
# kills the whole report" class this exists to fix -- can use it without
# growing a second copy. See scad_verify.bore()/safe()'s own docstrings.


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

    # Part 2's own length is the plain R60_EBay_L=177. Part 3 (12th
    # review, the tube split -- owner's ruling, R60_Chute_L=275 exceeds
    # the print envelope as one piece): no longer R60_Chute_L outright --
    # it is R60_ChuteSplit_Z + (R60_ChuteSplit_Engage-Taper), the fwd
    # piece's own length INCLUDING its spigot (137+6=143), restated (rule
    # 4) matching Rocket60.scad's own R60_ChuteTubeFwd()/R60_ChuteTubeAft().
    for p, want_len in ((2, 177.0), (3, 143.0)):
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

    # Part 26: deployment bay tube, AFT piece (12th review, the tube
    # split). Its own base (Z~0) is the SOCKET, not a plain tube cross-
    # section -- TUBE_BAND would read the wrong numbers there, so this
    # gets its own bands: CHUTE_SOCKET_BAND at the base (bore=
    # R60_ChuteSplit_SocketID, not 56.8 -- the socket is bored out to
    # receive part 3's own spigot) and CHUTE_AFT_TOP_BAND at the piece's
    # own true aft/open end (past the socket+taper, a normal tube cross-
    # section again, same 56.8/60.0 as everywhere else).
    if 26 in m:
        socket_id, socket_od = safe(bore, a(26, "stl"), *CHUTE_SOCKET_BAND, nvals=2)
        top_id, top_od = safe(bore, a(26, "stl"), *CHUTE_AFT_TOP_BAND, nvals=2)
        c += [("part 26 length", a(26, "height"), 138.0, 0.1),
              ("part 26 socket ID", socket_id, R60_ChuteSplit_SocketID_restated, 0.1),
              ("part 26 socket OD", socket_od, 60.0, 0.1),
              ("part 26 aft-end OD", top_od, 60.0, 0.1),
              ("part 26 aft-end bore", top_id, 56.8, 0.1)]
        # The joint's own mating clearance -- same 0.4+-0.15mm convention
        # as every other internal spigot in this design (the petal hub
        # spigot into the fin can, the neck skirt into the e-bay tube):
        # socket ID minus spigot OD, mesh-against-mesh, not two restated
        # literals compared to each other.
        if 3 in m:
            spigot_id, spigot_od = safe(bore, a(3, "stl"), *CHUTE_SPIGOT_BAND, nvals=2)
            c += [("part 26 socket clears part 3 spigot",
                   socket_id - spigot_od, 0.4, 0.15)]

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

        # Static vent hole (10th review) -- see vent_hole()'s own
        # docstring. Diameter confirms a clean round Ø4.5 hole (the
        # crescent-edge defect this review fixed would read short here);
        # Z centre confirms R60_Vent_Z (29.0, R60Lib.scad's corrected,
        # own-frame derivation) actually landed where the SCAD source
        # says it did, not just that some formula produced a number.
        try:
            vent_d, vent_z = vent_hole(a(2, "stl"))
        except RuntimeError:
            vent_d, vent_z = float("nan"), float("nan")
        c += [("part 2 vent hole diameter", vent_d, 4.5, 0.1),
              ("part 2 vent hole Z centre", vent_z, 29.0, 0.3)]

        # Rail button boss (coordinator fix 2) -- R60_RailButton_Fwd_Z/
        # _Az were placement-only before this fix; nothing rendered a
        # boss or insert there at all -- a button screw would have gone
        # straight into a plain 1.6mm wall and pulled through. Two
        # checks: (1) OD at the boss's own Z station stays 60.0 -- same
        # defect-2a tangential-bulge check DOOR_HOLE_Z_TUBE already gets,
        # confirming the boss's outer cap stops short of the true OD;
        # (2) the boss's own inner face (where its thickened material
        # ends and the insert pocket begins) reads at the expected tip
        # radius, not the plain wall's own r=28.4 -- proving real
        # reinforcement material exists at this station, not just a
        # bulge-free wall. (Not bore()'d for the insert's own Ø4.0
        # separately -- bore() reads radius from the TUBE's central axis,
        # and the insert sits off-axis at r=23.3..30, so its own small
        # local diameter does not show up as a small bore() reading the
        # way an axisymmetric hole would; the boss-tip depth below is
        # the meaningful, correctly-axis-relative proof instead.)
        RAILBTN_FWD_Z_TUBE = 143.0   # R60_RailButton_Fwd_Z(242) -
                                       # S_EBAY_restated(99), restated
                                       # (rule 4)
        RAILBTN_TIP_R_restated = 22.6   # R60_Body_OD/2(30) -
                                          # RailBtn_Boss_h(7.4), restated
                                          # (rule 4)
        _, railbtn_boss_od = safe(bore, a(2, "stl"),
                                   RAILBTN_FWD_Z_TUBE - BOSS_OD_BAND_HALF,
                                   RAILBTN_FWD_Z_TUBE + BOSS_OD_BAND_HALF,
                                   nvals=2)
        railbtn_tip_min, _ = safe(
            bore, a(2, "stl"), RAILBTN_FWD_Z_TUBE - 3.0,
            RAILBTN_FWD_Z_TUBE + 3.0, nvals=2)
        c += [("part 2 OD at rail button boss station",
               railbtn_boss_od, 60.0, 0.1),
              ("part 2 rail button boss reaches its own tip radius",
               railbtn_tip_min, 2 * RAILBTN_TIP_R_restated, 0.2)]

    if 6 in m:
        # sled length: 7th review, finding 1/2 -- now 2 continuous RAILS
        # (constant cross-section, full window length) instead of a plate
        # plus 2 short end feet, but the OVERALL printed length is the
        # same shape of quantity: the full window minus the two (now
        # independently stated) end clearances. Restated per this file's
        # rule 4: R60Lib.scad's R60_Vega_Window_Z1(150.3) -
        # R60_Vega_Window_Z0(12) - R60_Vega_Rail_FwdClear(0.2) -
        # R60_Vega_Rail_AftClear(5.0) = 133.1mm (R60_Vega_Rail_L).
        #
        # 8th review, finding 1: this SPAN check cannot discriminate a
        # swapped-ends sled from a correct one -- ymax-ymin is invariant
        # under swapping which end gets which clearance budget (FwdClear
        # + AftClear sums to the same 133.1mm either way), which is
        # exactly how the 7th-review sled shipped with its rail ends
        # reversed and still read "sled length 133.1, OK" here. The two
        # ABSOLUTE tip positions below (RAIL_FWDTIP_Y/RAIL_AFTTIP_Y) DO
        # move under the swap: the pre-fix sled measured ymin=-64.15/
        # ymax=+68.95 (RailAft_L/RailFwd_L applied to the wrong ends),
        # 4.8mm off the correct -68.95/+64.15 at BOTH ends (the FwdClear/
        # AftClear difference) -- well outside this check's own 0.2mm
        # tolerance, so this is the pair of checks that actually catches
        # the swap the span check above cannot.
        c += [("sled length", a(6, "ymax") - a(6, "ymin"), 133.1, 0.2),
              ("sled width", a(6, "xmax") - a(6, "xmin"), 45.6, 0.2),
              ("sled fwd rail tip (local ymin)", a(6, "ymin"), RAIL_FWDTIP_Y, 0.2),
              ("sled aft rail tip (local ymax)", a(6, "ymax"), RAIL_AFTTIP_Y, 0.2)]

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

    # Release hardware (parts 8, 13, 15-23) clears the deployment bay's own
    # bore -- petal-deployment transplant, replaces every shear-pin/tether
    # check above (deleted outright, see tasks/lessons.md: the feature
    # they checked no longer exists in this design).
    #
    # This IS the load-bearing finding of the whole transplant: the task's
    # own choice between CableReleaseBBMini (the family the donor design
    # actually flies) and CableReleaseBBMicro turned entirely on whether
    # each family's own Activator (part 15) fits this airframe's bore --
    # BBMini's does not (measures r=31.8mm, past R60_Body_ID/2=28.4mm; its
    # own file warns "Designed and works for Loc65 tube, may not scale" on
    # this exact module), BBMicro's does (r=28.2mm, landing exactly on
    # R60_Coupler_OD/2). This check is what a regression to BBMini (or any
    # future change that grows a release part past the bore) actually
    # fails on -- mutation-tested: pointing this check's own tolerance
    # window to include BBMini's measured r=31.8mm (i.e. relaxing max_r_ok
    # to 32.0) is the only way to make it pass BBMini, confirming the
    # check is genuinely discriminating between the two, not a tautology.
    max_r_ok = R60_Coupler_OD / 2.0 + 0.05   # +0.05mm tessellation slack
    for p in (8, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23):
        if p in m:
            xs = [x for tri in tris(a(p, "stl")) for (x, y, z) in tri]
            ys = [y for tri in tris(a(p, "stl")) for (x, y, z) in tri]
            max_r = max(math.hypot(x, y) for x, y in zip(xs, ys))
            # Same "overage past a ceiling" idiom as the build-volume
            # check below (overshoot()): 0 for anything that fits, the
            # actual excess in mm otherwise, against a tight tolerance --
            # not a wide equality window a real defect could hide inside.
            c += [("part %d max radius clears the coupler bore" % p,
                   overshoot(max_r, max_r_ok), 0.0, 0.01)]

    if 8 in m and 9 in m:
        # Petal hub's own aft spigot into the fin can's forward-open bore
        # -- the SAME joint the chute tube used to make before this
        # transplant, now carried by part 8 instead (R60Lib.scad's
        # R60_PetalHubSpigot_L comment). Mesh-against-mesh, same
        # 0.4+-0.15mm convention as every other internal spigot-into-bore
        # joint in this file.
        fincan_bore, _ = safe(bore, a(9, "stl"), *FINCAN_SPIGOT_BAND,
                               r_lo=FINCAN_SPIGOT_R_LO, nvals=2)
        _, spigot_od = safe(bore, a(8, "stl"), *PETALHUB_SPIGOT_BAND, nvals=2)
        c += [("petal hub spigot clears fin can forward bore",
               fincan_bore - spigot_od, 0.4, 0.15)]

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
        # Chute-tube-to-fin-can spigot check moved: that joint is now made
        # by the petal hub (part 8), not the chute tube -- see the
        # "petal hub spigot clears fin can forward bore" check above.

        # Aft rail button boss (coordinator fix, this session -- rebased
        # from a stale 630mm literal onto the mid ring's own real
        # position, 665mm global / 114mm local). Same pair of checks the
        # forward button (part 2) gets: (1) OD stays true across the
        # boss's own Z footprint -- no tangential bulge past the true OD
        # (defect-2a class); (2) the boss's own material reaches its
        # calculated tip radius. r_lo=20 (AFTBTN_R_LO) is REQUIRED here,
        # unlike the forward button's own check -- this boss sits right
        # at the mid centring ring, and the MMT's own r=16.15 surface is
        # exposed at the ring's exact Z boundaries (114/117), which would
        # otherwise dominate a plain bore()-min reading and mask whether
        # the boss itself is even there. Scanned over the boss's FULL own
        # Z footprint (AFTBTN_Z_BAND, +-4mm = Boss_d/2), not a narrow
        # slice at its centre -- a round boss's own reach varies smoothly
        # across its own curved profile (measured this session: 44.60mm
        # at the footprint's outer edges, 45.3-46.7mm nearer its centre,
        # all consistent with one continuous round boss, no anomaly) --
        # the TRUE tip (44.60mm, exact match to the constants below) only
        # shows up as the band's own MINIMUM, not at any single Z.
        AFTBTN_Z_TUBE = 114.0    # R60_RailButton_Aft_Z(665) -
                                   # S_FIN_restated(551), restated (rule 4)
        AFTBTN_Z_HALF = 4.0       # Boss_d/2 -- restated (rule 4)
        AFTBTN_R_LO = 20.0        # comfortably above the MMT's own
                                    # r=16.15, comfortably below the
                                    # boss's own target r=22.3
        AFTBTN_TIP_R_restated = 22.3   # R60_Body_OD/2(30) -
                                         # AftBtn_Boss_h(7.7), restated
                                         # (rule 4)
        _, aftbtn_boss_od = safe(bore, a(9, "stl"),
                                   AFTBTN_Z_TUBE - BOSS_OD_BAND_HALF,
                                   AFTBTN_Z_TUBE + BOSS_OD_BAND_HALF,
                                   nvals=2)
        aftbtn_tip_min, _ = safe(
            bore, a(9, "stl"), AFTBTN_Z_TUBE - AFTBTN_Z_HALF,
            AFTBTN_Z_TUBE + AFTBTN_Z_HALF, AFTBTN_R_LO, nvals=2)
        c += [("part 9 OD at aft rail button boss station",
               aftbtn_boss_od, 60.0, 0.1),
              ("part 9 aft rail button boss reaches its own tip radius",
               aftbtn_tip_min, 2 * AFTBTN_TIP_R_restated, 0.3)]
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

    # Old part-13 (tether latch) dimensional checks deleted outright --
    # petal-deployment transplant, see tasks/lessons.md. Part 13 is now
    # R60_Petals() (PetalDeploymentLib.scad), covered by the max-radius-
    # vs-bore check above, same as parts 8/15-23.
    #
    # 13th review: `Lock_Span_a` (Rocket60.scad's own R60_Petals() call)
    # regressed to the library default (0, full-circumference lock
    # ridges) once already, silently -- a 3rd-party review caught it,
    # not this file, because nothing here checked the RENDERED mesh,
    # only trusted the source line that sets it. petal_lock_arcs() reads
    # the real geometry: PD_PetalLocks()'s own BaseOffset+Len-Lock_h to
    # BaseOffset+Len band (7.2+140-1.5=145.7 to 7.2+140=147.2 at the
    # CURRENT R60_Petal_Len -- restated below, rule 4) for inward-
    # projecting nub material. Correct (Lock_Span_a=30): 3 arcs, ~38deg
    # each, 120deg apart. Mutation-tested (this session): Lock_Span_a=0
    # collapses this to ONE arc spanning the full 360deg -- n_arcs=1
    # (want 3), avg_span=360 (want ~38), spacing metric hits its own
    # 999.0 not-enough-arcs-to-space sentinel (want ~0) -- all three
    # fail loudly, not just one.
    if 13 in m:
        petal_len = a(13, "height")   # PD_Petals()'s own printed length
                                        # IS R60_Petal_Len by construction
                                        # -- read off the mesh, not
                                        # restated, so this band tracks
                                        # a future Petal_Len change
                                        # automatically
        PETAL_LOCK_BASE_OFFSET = 7.2   # PD_PetalLocks()'s own BaseOffset
                                         # (PetalDeploymentLib.scad) --
                                         # restated (rule 4)
        PETAL_LOCK_H = 1.5              # PD_PetalLocks()'s own Lock_h --
                                         # restated (rule 4)
        zlo = PETAL_LOCK_BASE_OFFSET + petal_len - PETAL_LOCK_H
        zhi = PETAL_LOCK_BASE_OFFSET + petal_len
        n_arcs, avg_span, spacing_dev = safe(
            petal_lock_metrics, a(13, "stl"), zlo, zhi,
            PETAL_LOCK_R_THRESH, nvals=3)
        c += [("petal lock nub arc count", n_arcs, 3, 0.4),
              ("petal lock nub arc span (deg)", avg_span, 38.2, 8.0),
              ("petal lock nub arc spacing (deg from 120)", spacing_dev, 0.0, 2.0)]

    # Spring pocket entry clearance (coordinator fix 1). The spring must
    # physically ENTER this pocket, not just meet it tangent -- the same
    # "measure it, don't assert it" standard every other mating dimension
    # in this file already gets, applied to the one that was never
    # checked at all before this fix (found by a coordinator review
    # reading Century Spring's own published CS4323 catalog, not by
    # anything in this harness). shortfall() floor: R60_Spring_OD+0.2 --
    # half the intended 0.4mm R60_Spring_Clear, a real floor a print's
    # own faceting/tolerance can still clear (the measured ring already
    # reads ~0.01mm under its own nominal -- see SPRING_POCKET_BAND's own
    # comment), not the full nominal, which would flag a healthy print as
    # a false failure. Mutation-tested: forcing Spring_Clear back to 0 in
    # Rocket60.scad's own R60_CenteringRingMount() call (the exact pre-fix
    # state) re-renders the pocket at 44.45mm -- shortfall against the
    # 44.65mm floor is then 0.20mm, FAILS; reverted (Spring_Clear=0.4),
    # the real 44.84mm pocket gives shortfall 0.0, PASSES. Not mutating
    # R60_Spring_OD itself (5th-review-class trap): the floor is DERIVED
    # from that same constant, so moving it moves both sides of the
    # check together and proves nothing -- only Spring_Clear, the actual
    # fix, is mutated.
    if 25 in m:
        pocket_min, _ = safe(bore, a(25, "stl"), *SPRING_POCKET_BAND, nvals=2)
        c += [("part 25 spring pocket clears catalog OD",
               shortfall(pocket_min, R60_Spring_OD_restated + 0.2), 0.0, 0.01)]

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
    # (9th review) try/finally: this used to mkdtemp() and never clean up
    # -- measured 16-27 MB left behind per run, one abandoned tree per
    # invocation (this file, verify_rocket60_assembly.py and
    # verify_motordummy29.py all had the identical gap; verify_nosecone.py
    # and verify_camnose.py, predating this PR, are the same latent
    # pattern but outside this fix's scope). finally (not a plain rmtree
    # call after the loop) so a raised exception -- checks() itself
    # raising, an unexpected error a `safe()`/try-except somewhere below
    # did not anticipate -- still cleans up on the way out.
    try:
        bad = 0
        # `return 1` on a failed render (6th review, finding 4) used to
        # abort the WHOLE run: any part after the failed one never
        # rendered, and checks() -- and every one of its ~90 rows -- never
        # printed at all, the identical "one bad row kills the whole
        # report" failure class safe() was introduced to fix for
        # individual checks, one level up. A failed/slow render is now a
        # counted FAIL for just that part, and the loop (and the report)
        # continues with whatever DID render.
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
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
