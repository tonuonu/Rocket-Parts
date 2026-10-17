#!/usr/bin/env python3
"""Assembly-interference check for Rocket 60: for every mating pair in the
printed stack, render BOTH parts in their real assembled relative position
(tools/r60_assembly.scad) and assert the intersection() volume is zero.

This exists because three rounds of review found interference that no
per-part dimension check can see: two parts can each individually pass
every check in verify_rocket60.py and still collide once actually
assembled, because the collision only exists in the RELATIVE position
between them (a rail that runs the tube's full length is fine on its own;
it only fails once you also place the neck's skirt where it actually
seats). intersection() + measured volume is the only check that is
looking at the same thing an assembler's hands would find.

Where a joint has a stroke -- the deployment bay tube telescopes over the
e-bay aft bulkhead's skirt during assembly -- checked ALONG the stroke
(Ins=0..15mm), not only at the final seated position: a joint can be
clear when fully seated and still jam partway through assembly. (The
petal-deployment transplant removed the deeper stroke this used to sweep
-- the old chute tube telescoped over a skirt+carrier insert, and a
defect there once jammed mid-stroke while clearing at both ends; the
carrier is gone, so this joint is now a plain tube over a plain skirt.)
"""
import os, shutil, subprocess, sys, tempfile

from scad_verify import REPO, OPENSCAD, volume, measure, render

SCAD = os.path.join(REPO, "tools", "r60_assembly.scad")
# check_closure() (11th review, fix 7) renders part 3 directly off the
# main file -- r60_assembly.scad's own Pair dispatch has no part-3-alone
# mode, and adding one would duplicate scad_verify.render()'s own
# per-part convention for no reason.
SCAD_MAIN = os.path.join(REPO, "Rocket60.scad")

# Zero-volume tolerance. A genuinely clear fit renders a truly EMPTY
# solid (OpenSCAD: "Current top level object is empty", no output file at
# all) -- there is no meshing/triangulation noise to tolerate the way
# there can be for two independently-rendered, non-intersected meshes.
#
# Re-derived (5th review, finding 3): the old 0.001 cm3 (1 mm3) was sized
# against this file's LARGEST defects (0.0211-0.42 cm3) and never checked
# against its SMALLEST feature. Measured by mutation on the tether-latch
# pin path (PIN_D=3.2mm) -- the smallest-diameter feature any pair here
# checks -- pushing PIN_REACH past its true safe ceiling (20.47mm) by a
# stated depth gives:
#   depth 0.13mm -> 0.0000173 cm3      depth 0.58mm -> 0.000749 cm3
#   depth 0.23mm -> 0.0000728 cm3      depth 0.63mm -> 0.000920 cm3
#   depth 0.53mm -> 0.000599  cm3      depth 0.68mm -> 0.001110 cm3
# i.e. the OLD 0.001 cm3 threshold went blind to as much as ~0.68mm of
# REAL geometric overlap on a Ø3.2mm feature -- confirming finding 3's own
# "~0.7mm of genuine interference" claim to within 0.02mm. A Ø3 dowel that
# must be inserted and withdrawn cares about tenths of a millimetre, not
# two-thirds of one. 0.00001 cm3 (1e-5, one hundredth of a mm3) sits just
# below the smallest measured real defect above (0.0000173 cm3 at 0.13mm
# depth) -- comfortably resolves anything on the order of a tenth of a
# millimetre on this feature class, while every genuinely clear pair in
# this file (including the pin-path pairs themselves, post-fix) still
# renders literally "Current top level object is empty" -- an exact CGAL
# zero, not a small positive number -- so there is no meshing-noise floor
# this threshold risks tripping over.
EPS_CM3 = 0.00001

PAIRS = {
    0: "neck vs e-bay tube",
    1: "e-bay fwd bulkhead vs e-bay tube",
    2: "e-bay aft bulkhead vs e-bay tube",
    3: "vega sled vs e-bay tube",
    4: "access door vs e-bay tube",
    5: "aft bulkhead skirt vs deployment bay tube (stroke)",
    # Pair 7 (was "deployment bay tube vs fin can") RETIRED, 12th review --
    # see tools/r60_assembly.scad's own Pair 7 comment: that joint does
    # not exist any more (part 8's own glued spigot replaced it, 11th
    # review), found stale by this session's own tube split.
    8: "motor spacer vs MMT (fin can)",
    10: "thrust ring obstructs motor+spacer (forward trap)",
    11: "motor retainer obstructs motor (aft trap)",
    # 4th review, harness item 2 (complete the pair matrix) -- see
    # r60_assembly.scad's own pair-enumeration comment block for the full
    # part-by-part table this was read off, including what was
    # deliberately excluded and why.
    #
    # Pairs 6, 9, 12-15, 17, 19, 31 RETIRED (petal-deployment transplant --
    # tasks/lessons.md): all checked the deleted spring-carrier/tether-
    # latch/servo-2 design.
    #
    # 11th review: the petal cage's own mechanism (hub/petals/spring
    # holder, parts 8/13/24) is no longer a silent gap -- Pairs 35-37
    # cover it (lesson: "the hub went in inverted and its hinge parts
    # were never noticed missing because no check models the mechanism
    # as a mechanism", tasks/lessons.md). The release hardware's own
    # INTERNAL joints (parts 16-22, the donor's proven, unmodified
    # bearing/lock-ring/pin stack) remain a known gap -- their binding
    # dimensional question (fits inside the airframe's bore) is covered
    # instead by verify_rocket60.py's max-radius-vs-bore check, same as
    # before.
    #
    # 6th review, finding 2: pairs 16 (switch vs tube), 18 (pin path vs
    # aft bulkhead) and 20 (switch vs Vega sled) are DELETED, not merely
    # unlisted here -- each was structurally incapable of failing under
    # any plausible change. See r60_assembly.scad's own pair-enumeration
    # comment for the specific reason each one was removed rather than
    # "fixed" into a check that would still never fire.
    # 5th review, finding 2: pair 3 only ever modelled the SLED -- the
    # real collision was between the door bosses and the Vega BOARD
    # sitting on top of it, which nothing in this harness had ever
    # rendered.
    21: "Vega board envelope vs e-bay tube (door bosses)",
    # Discovered fixing finding 1: the board's own Z span overlaps the
    # door aperture by construction, so the switch's own installed
    # hardware can reach the board even where it clears the thin sled --
    # a real risk, not a hypothetical one. SW_REACH is now a stated
    # hardware envelope (6th review, finding 2: it used to be derived FROM
    # the board's own position, which could never fail regardless of how
    # the board stack changed).
    22: "fitted arming switch envelope vs Vega board",
    # 6th review, finding 1 -- rod retention, 7th review, finding 1/2:
    # the Vega sled's rails, flush-fit interference against each bulkhead
    # they mount to.
    23: "vega sled rails vs aft bulkhead",
    24: "vega sled rails vs fwd bulkhead",
    # 7th review, finding 1: fastener INSERTION checks (r60_assembly.scad's
    # own FastenerSweep() header comment) -- a bore/clearance check proves
    # a hole is the right size; these prove a fastener can actually travel
    # from an accessible point to its seated position without solid
    # material in the way. This is the check that would have caught (and,
    # via mutation test, did catch: 3.91cm3) the retired bolted-foot
    # design's own defect before it shipped.
    25: "vega sled rod sweep vs sled rail (mutation-test regression)",
    26: "vega sled rod sweep vs both bulkheads",
    27: "vega sled rod nut sweep vs sled rail",
    28: "camera bolts sweep vs neck",
    29: "access door screws sweep vs door+tube",
    30: "motor retainer bolts sweep vs retainer + fin can insert",
    # 31 RETIRED (petal-deployment transplant) -- was tether latch
    # mounting bolts vs aft bulkhead.
    32: "Vega board mounting screws sweep vs sled",
    # 10th review, critical fix 1: release activator's (part 15) own
    # mount to the aft bulkhead (part 5) -- was a known gap (the OLD
    # mount bolted through the activator's own INTERNAL joint to the
    # top retainer, on the wrong face, with the wrong fastener standard
    # -- see r60_assembly.scad's own Pair 33/34 comments and
    # Rocket60.scad's R60_EBayAftBulkhead() module comment for the full
    # writeup, and tasks/lessons.md for the mutation-test record).
    33: "release activator vs aft bulkhead (mating fit)",
    34: "release activator mounting screws sweep vs bulkhead+activator",
    # 11th review: the hinge subsystem (tasks/lessons.md) -- dropped
    # entirely from the first transplant attempt. See
    # Rocket60.scad's R60_PSH_Placed() for the placement derivation.
    35: "petal hub vs petals (upside-down-hub fix)",
    36: "petal spring holder (hinge) vs petal hub",
    37: "petal spring holder vs petals (bolted face)",
    38: "spring centering ring mount vs release top retainer",
    # 12th review: the deployment bay tube split (owner's ruling -- 275mm
    # exceeds the print envelope as one piece). Pairs 39/41/42/43 are NOT
    # in this dict -- like 39 before them, they are union/volume probes
    # for check_closure()/check_packing(), not expect-empty mating pairs,
    # and are driven directly by those functions in main(), not this
    # loop.
    40: "deployment bay tube fwd (part 3) vs aft (part 26) joint",
}
STROKE_PAIRS = (5,)
# Insertion stroke sweep -- 0 (first contact) through 15 (fully seated,
# petal-deployment transplant: Skirt_L=15, no carrier any more -- see
# r60_assembly.scad's Pair 5 comment for the derivation).
#
# 4th review, harness item 5: this used to be a fixed 5mm grid while the
# comment here claimed a "closing to 1mm near the transition" refinement
# pass that did not exist anywhere in this file -- a jam narrower than
# 5mm, sitting entirely BETWEEN two clean coarse samples, would read a
# clean pass at every one of them (finding 1, 3rd review, was exactly
# this shape: clear at Ins=0 and at full seating, solid for most of the
# middle of the stroke). A refine-near-hits scheme cannot fix this
# either: there is no hit to refine around when both flanking coarse
# samples are already clean. The only sweep that can actually promise
# "nothing narrower than Xmm slips through" is one sampled AT Xmm
# throughout -- so this is a genuine, unconditional 1mm sweep, not a
# coarse pass with a refinement step. Range shrank 0..80 -> 0..15
# (petal-deployment transplant: the stroke is now just the skirt's own
# Skirt_L=15mm, no 65mm carrier appended) -- 16 samples for the one
# remaining stroke pair (5), not 81.
INS_SWEEP = list(range(0, 16, 1))

# Obstruction-proof pairs (defect 3, the missing forward thrust ring):
# INVERTED polarity from every other pair here. Push=0 is the normal
# assembled (flush, touching) position and must be clear, same as every
# other pair; Push=OVERTRAVEL_MM simulates the motor+spacer stack (10) or
# the motor (11) being driven a few mm past its resting position under
# load, and for a joint that actually obstructs, THAT must come back
# NON-zero -- solid material genuinely colliding, not passing through an
# oversized bore. OBSTRUCT_MIN_CM3 is deliberately far above EPS_CM3 (by
# 1-2 orders of magnitude, matching every real defect this file has
# found) so this cannot pass on meshing noise.
OBSTRUCTION_PAIRS = (10, 11)
OVERTRAVEL_MM = 2.0
OBSTRUCT_MIN_CM3 = 0.01

# Hinge pair (11th review, the petal spring holder's own axle vs. the
# petal hub's pivot socket -- Pair 36). NOT held to EPS_CM3 like a static
# mating pair: this joint is a MOVING pivot, not two faces meant to sit
# flush, and the axle/socket clearance geometry (PetalDeploymentLib.scad,
# unmodified donor source) leaves a small, real residual at the hinge
# boss where it meets the socket's own clearance-cut edge -- measured
# 0.0066-0.0087 cm3 across the placements this file's own header comment
# derives from (Rocket60.scad's R60_PSH_Placed()), two orders of
# magnitude below every REAL defect this harness has ever found (the
# upside-down hub alone was 1.31cm3). HINGE_MAX_CM3 is set an order of
# magnitude above that measured range -- comfortably clears ordinary FDM
# hinge-fit tolerance while still catching a genuinely wrong placement:
# mutation-tested (dz=0, i.e. the holder left at the hub's own local
# origin instead of R60_PSH_Placed()'s derived offset) reads 0.6110cm3,
# >12x over this threshold.
HINGE_PAIRS = (36,)
HINGE_MAX_CM3 = 0.05

# Deployment-bay axial closure (11th review, fix 7 -- tasks/lessons.md's
# own "R60_Petal_Len=200 passes both suites with exit 0" finding: NOTHING
# checked whether the petal cage the file's own Render_Part=13 built
# could physically fit inside the tube it is stated to fit inside).
# Mesh-based, not the restated-constants version tools/rocket60_model.py
# also carries (that script's own HUB_TAIL_OFFSET assert is the SAME
# fact from restated numbers -- this is independent proof, rendering the
# real SCAD instead of trusting a Python copy of it not to drift).
#
# CLOSURE_RESERVE_MM restates (rule 4) the release-stack's own footprint
# ahead of the petal cage, in the SAME reference tools/rocket60_model.py
# already establishes and documents (S_ACT0's own SKIRT_L=15 +
# ACT_MOUNT_GAP=19, restated matching Rocket60.scad's own
# R60_EBayAftBulkhead()/R60_ReleaseActivator() module comments) plus
# PETALS_OFFSET=76.5 (the petals' own forward/tip station past S_ACT0,
# same file, same session's own mesh measurement) -- none of these three
# numbers depend on R60_Petal_Len, so a mutation to that ONE constant
# changes only the measured Pair-39 span this check renders fresh, not
# this reserve.
CLOSURE_RESERVE_MM = 15 + 19 + 76.5   # = 110.5
CLOSURE_TOL_MM = 5.5   # R60_FinCanSpigot_L (R60Lib.scad), same spigot-
                         # length tolerance rocket60_model.py's own
                         # closure assert uses

# Neighbouring blind spots (11th review, fix 7's own "say what remains
# uncovered" instruction) -- this closure check answers ONE geometric
# question (does the cage's own printed length fit the tube it is stated
# to fit inside); it does NOT answer any of these, still uncovered by
# anything in this repo:
#   1. Spring throw vs. insertion depth -- the CS4323's own free length
#      (200mm, R60Lib.scad) minus coil-bound length (22mm) gives ~178mm
#      of throw; nothing checks that is actually enough to drive
#      R65_FwdSpringEnd() through the real mechanical travel needed to
#      pop the lock nubs and fully open the petals (a stroke-sweep pair,
#      same style as Pair 5's STROKE_PAIRS, over the piston's real path
#      -- not built here).
#   2. Lock-nub engagement force -- Lock_Span_a=30 (this review, fix 3)
#      sets the geometric engagement ARC, but whether the spring can
#      actually overcome that engagement is a FORCE question no mesh
#      check can answer without a stated CS4323 spring-rate figure
#      (spec A11, still undocumented).
#   3. Hinge rotation clearance through its full swing -- Pair 36 checks
#      the axle/socket fit at the CLOSED (rest) position only; nothing
#      sweeps the spring-holder's own hinge boss through the petal's
#      full open-swing arc to confirm PD_PetalHub()'s own "Petal
#      clearance" hull actually clears it throughout, not just at rest.
#   4. The hinge's own 5/16in preload spring -- fix 4 seated the CS4323
#      (the main release spring); the three SMALLER coil springs inside
#      each PD_PetalSpringHolder() have no geometry check of their own
#      (free/compressed length vs. the holder's own receiver pocket).
#   5. Shock-cord route clearance -- the route this review documented
#      (spec §4.1: bulkhead -> piston rope holes -> hub Ø5 -> fin-can
#      ring) has never been checked against the spring-holders or
#      rotating release-stack parts it passes near for pinch/sever risk.


def check_closure(tmp):
    """Deployment-bay axial closure: renders Pair 39 (the ACTUAL hub+
    petals union) and Pair 41 (the ACTUAL deployment-bay tube union, both
    pieces -- 12th review, the tube split) fresh and measures each one's
    own real span, then checks CLOSURE_RESERVE_MM + the cage's span lands
    within CLOSURE_TOL_MM of the tube's own assembled length -- BOTH
    directions (12th review, fix: this used to be one-sided).

    12th review, trap avoided: part 3 alone is no longer the whole tube
    (the split added part 26) -- reading part 3's own rendered height,
    the way this function used to, would silently measure the FORWARD
    piece only and report a ~138mm-short false failure after a genuinely
    correct split. Pair 41 unions both pieces at their real relative
    offset instead, so this reads the assembled tube's real length
    regardless of how many pieces it is printed as.

    Returns (ok, message). Symmetric now (12th review, fix 3 -- the one-
    sided defect this session's own advisory found): `over` used to only
    fail when POSITIVE (tube too short); a tube grown too LONG (over
    strongly negative) used to read as "clears" even though the hub's
    spigot then falls short of ever reaching the fin can at all -- the
    SAME physical defect from the other direction, and rocket60_model.py's
    own abs()-based closure assert already caught it independently (a
    288mm tube read a genuine 10.3mm gap there, TWO 5.5mm-tolerances past
    tangent) while this check would have passed it silently. Fixed by
    comparing abs(over) instead of over, matching that script exactly.

    Mutation-tested, both directions (this session, actually run --
    both figures below are measured, not estimated):
      - too SHORT: R60_Petal_Len=200 (edit R60Lib.scad, R60_Chute_L
        unchanged) grows the cage span 167.2->227.2mm (+80mm, the SAME
        constant this file's own HINGE_MAX_CM3 comment and tasks/
        lessons.md's own finding used) with the tube fixed at 275 --
        needed grows to 337.7, reads SHORT by 57.2mm net of the 5.5mm
        tolerance. Correctly FAILs.
      - too LONG: R60_Chute_L=290 (edit R60Lib.scad, R60_Petal_Len
        unchanged) leaves needed at 277.7 but chute_len at 290 -- over =
        277.7-290 = -12.3, GAP of 6.8mm net of the 5.5mm tolerance.
        Correctly FAILs on the abs() check; the OLD one-sided formula
        (`ok = over <= CLOSURE_TOL_MM`, no abs()) would have silently
        PASSED this exact mutation (-12.3 <= 5.5 is true) -- this is the
        specific defect fix 3 closes, confirmed by re-deriving the old
        formula against this same mutation, not just asserted."""
    out41 = os.path.join(tmp, "pair41.stl")
    render_probe(41, None, out41)
    chute_len = measure(out41)["height"]

    out39 = os.path.join(tmp, "pair39.stl")
    render_probe(39, None, out39)
    cage_span = measure(out39)["height"]

    needed = CLOSURE_RESERVE_MM + cage_span
    over = needed - chute_len   # + : cage reaches PAST the tube (too short
                                  # a tube / too long a cage); - : cage
                                  # falls SHORT of the tube's own end (too
                                  # long a tube) -- both are real defects
    ok = abs(over) <= CLOSURE_TOL_MM
    msg = ("cage span %.1f + reserve %.1f = %.1f needed vs assembled tube "
           "length %.1f -- %s" % (cage_span, CLOSURE_RESERVE_MM, needed,
                                    chute_len,
                            ("clears (%.1fmm %s tangent)"
                             % (abs(over), "past" if over >= 0 else "short of")
                             if ok else
                             ("SHORT by %.1fmm net of %.1fmm spigot tolerance"
                              % (over - CLOSURE_TOL_MM, CLOSURE_TOL_MM)
                              if over > 0 else
                              "GAP of %.1fmm net of %.1fmm spigot tolerance "
                              "-- tube too LONG, hub spigot does not reach "
                              "the fin can"
                              % (-over - CLOSURE_TOL_MM, CLOSURE_TOL_MM)))))
    return ok, msg


# Packing-volume net check (12th review, promoting this session's own
# /tmp bore-probe measurement into the harness -- R60_Petal_Len's own
# module comment, R60Lib.scad, has the full derivation and is the
# authority for the numbers restated here). Pairs 42/43 (r60_assembly.
# scad) measure how much of the hub/spring-holder/piston's own real
# material sits inside the SAME 53.2mm-diameter bore PD_Petals() itself
# uses -- this function nets that off the gross bore volume and checks
# the stated ~250 cm^3 requirement (24in main + Nomex protector + shroud
# lines, ~50g at ~0.20 g/cm^3).
PACKING_BORE_D_MM = 53.2   # PD_Petals' own tube ID at Wall_t=1.6,
                            # R60_Coupler_OD-2*1.6 -- restated (rule 4),
                            # matches r60_assembly.scad's own Pair 42/43
PACKING_REQUIRED_CM3 = 250.0

# NOT yet netted out (13th review, found while checking a DIFFERENT
# fix -- AntiClimber_h -- reported, not silently absorbed into this
# check's own scope this round): PD_Petals()'s own AntiClimber() ridges
# (R60_Petals()'s AntiClimber_h=4, corrected this session -- Rocket60.
# scad's own module comment) reach inward to a measured r=22.26mm at
# two petal-local Z-bands per petal (~7.2-15.2 and ~121.2-129.2) --
# DEEPER than the lock nubs' own r=24.2mm minimum, and at azimuths the
# hub/spring-holder/piston probes (Pairs 42/43) do not cover, since
# those measure hub/piston material, not petal material. The net
# packing figure above (net_cm3) does not charge for this third
# obstruction source; the true usable volume is somewhat LESS than
# net_cm3 states, by an unmeasured amount (a thin ridge, not a slab --
# likely small next to the ~45cm3 of margin over PACKING_REQUIRED_CM3,
# but not measured, so not asserted here as small). A Pair 44 probing
# PD_Petals() itself the same way 42/43 probe the hub/piston would
# close this -- not built this round.


def check_packing(tmp):
    """Net packing volume: bore cross-section area (from PACKING_BORE_D_MM)
    times R60_Petal_Len, minus Pairs 42+43+44's own measured obstruction
    volume, checked against PACKING_REQUIRED_CM3.

    Pair 44 (14th review) closes the gap the 13th review's own
    AntiClimber_h fix exposed and reported rather than fixed: PD_Petals()
    itself has TWO real inward intrusions into this same bore -- the
    lock nubs (r=24.2mm minimum) and the AntiClimber ridges (r=22.26mm,
    deeper) -- neither netted out before this pair existed. A single
    intersection of the WHOLE petals mesh against the bore, at its real
    hub-relative offset, captures both at once (2.74cm3 measured, not
    estimated -- the SAME defect class, "an obstruction estimated
    rather than measured", that produced the original false "13%
    shortfall" this whole packing check exists to never repeat).
    Summing Pairs 42/43/44 rather than unioning them first is valid
    because none of the three collide with each other (Pair 35: hub vs
    petals, Pair 36/37: spring holder vs hub/petals, all ~0cm3) -- their
    solid volumes do not overlap, so their bore-obstruction volumes
    don't either, and summing independent measurements does not double-
    count. Piston-vs-petals non-collision is assumed (the same physical
    requirement as the checked pairs, not independently re-probed at
    the piston's own real relative offset this round -- a genuine
    residual gap, not silently claimed as closed; see the "still
    uncovered" list this file already carries elsewhere).

    Mutation-tested (this session, actually run): at R60_Petal_Len=100
    (edit R60Lib.scad) net drops well under 250cm3 -- correctly FAILs
    (and check_closure() ALSO correctly fails at this same mutation,
    from the other direction -- a shorter cage leaves the tube too long
    relative to it, the same too-long defect class fix 3 added coverage
    for). At the current R60_Petal_Len=140 (owner's ruling) net is
    292.2 cm^3 (14th review, corrected from the pre-Pair-44 294.9 cm^3
    -- the 2.74cm3 AntiClimber/lock-nub intrusion, now netted, not
    estimated), correctly PASSes with ~17% real margin."""
    import math
    # R60_Petal_Len itself is not carried in this file (rule 4 would
    # otherwise duplicate it a third time, after R60Lib.scad and
    # tools/rocket60_model.py) -- read it straight off part 13's own
    # rendered height instead, since PD_Petals()'s own printed length IS
    # R60_Petal_Len by construction (Rocket60.scad's R60_Petals()).
    out13 = os.path.join(tmp, "part13.stl")
    render(SCAD_MAIN, 13, out13)
    petal_len_mm = measure(out13)["height"]

    bore_area_cm2 = math.pi * (PACKING_BORE_D_MM / 20.0) ** 2
    gross_cm3 = bore_area_cm2 * (petal_len_mm / 10.0)

    out42 = os.path.join(tmp, "pair42.stl")
    render_probe(42, None, out42)
    hub_end_cm3 = volume(out42)

    out43 = os.path.join(tmp, "pair43.stl")
    render_probe(43, None, out43)
    piston_end_cm3 = volume(out43)

    out44 = os.path.join(tmp, "pair44.stl")
    render_probe(44, None, out44)
    petal_own_cm3 = volume(out44)

    net_cm3 = gross_cm3 - hub_end_cm3 - piston_end_cm3 - petal_own_cm3
    ok = net_cm3 >= PACKING_REQUIRED_CM3
    msg = ("Petal_Len %.0fmm: gross %.1f - hub/PSH %.1f - piston %.1f - "
           "petal locks/AntiClimber %.1f = net %.1f cm3 vs %.0f cm3 "
           "required -- %s"
           % (petal_len_mm, gross_cm3, hub_end_cm3, piston_end_cm3,
              petal_own_cm3, net_cm3, PACKING_REQUIRED_CM3,
              "clears (%.0f%% margin)" % (100.0 * (net_cm3 / PACKING_REQUIRED_CM3 - 1.0))
              if ok else
              "SHORT by %.1f cm3" % (PACKING_REQUIRED_CM3 - net_cm3)))
    return ok, msg


# Neighbouring one-sidedness scan (12th review, fix 3's own "say whether
# any neighbouring check has the same one-sidedness" instruction). The
# closure bug had a specific shape: a SIGNED quantity (over = needed -
# chute_len) where BOTH signs are real, physical, opposite defects (tube
# too short OR too long), but only one sign was ever compared. Scanned
# every other check in this file and verify_rocket60.py for the same
# shape:
#   - STROKE_PAIRS/the default per-pair loop (`vol <= EPS_CM3`): one-
#     sided BY NATURE, not a bug -- a mating fit with too much CLEARANCE
#     is not a defect this probe exists to catch (that is a dimensional
#     question, verify_rocket60.py's own job), only genuine interference
#     is. No opposite sign to miss.
#   - OBSTRUCTION_PAIRS (10, 11): already effectively two-sided --
#     checks flush-must-be-clear (vol0<=EPS_CM3) AND overtravel-must-
#     obstruct (vol1>=OBSTRUCT_MIN_CM3) as a PAIR, catching both "an
#     obstruction that isn't there" and "solid material where flush
#     travel should be clear".
#   - HINGE_PAIRS (36, `vol <= HINGE_MAX_CM3`): one-sided, and NOT the
#     same bug -- but a genuinely different, still-open gap, worth
#     recording here rather than conflating with the fixed one: an
#     intersection-volume probe structurally CANNOT see "too much
#     clearance" at all (a sloppy, oversized hinge fit still reads
#     ~0cm3, identical to a snug one), so there is no discarded sign to
#     restore -- this would need a different check entirely (e.g. a
#     stated max-play dimension read off the axle/socket edge loops,
#     bore()-style), not a formula fix. Related to, but distinct from,
#     the closure check's own "Neighbouring blind spots" item 3 above
#     (hinge SWING clearance) -- this is REST-position fit slop, not
#     swing-arc clearance.
#   - check_packing() (`net_cm3 >= PACKING_REQUIRED_CM3`): one-sided by
#     nature, same as MAX_Z below -- more usable volume is never a
#     defect, so there is no opposite sign to check.
#   - verify_rocket60.py's own dimensional checks: the main loop compares
#     every (label, actual, expected, tol) tuple via `abs(actual-
#     expected) <= tol` -- already symmetric, including the spigot-
#     clearance checks that share this file's own 0.4mm convention.
#     overshoot()/shortfall() (scad_verify.py) are used only for
#     genuinely one-directional physical constraints (MAX_Z: shorter is
#     never bad; a stated minimum clearance: more is never bad) -- one-
#     sided by nature, not the closure bug's shape.
#   - rocket60_model.py's own closure assert (`abs(_hub_tail - S_FIN) <=
#     R60_FinCanSpigot_L_restated`) was ALREADY symmetric before this
#     review -- the bug was an inconsistency between this file's mesh-
#     based check and that one's restated-constants check, not a
#     systemic pattern repeated across the codebase.
# Conclusion: the closure fix was the only instance of this specific
# defect shape found in this repo's own verification tooling.


def render_probe(pair, ins, out, push=0.0):
    """Render one assembly-probe pair to ASCII STL. Returns the measured
    intersection volume in cm3 -- 0.0 for a genuinely empty intersection
    (OpenSCAD's own "Current top level object is empty", the expected
    result for a clean mating fit), not an error: a per-part render
    failing empty (scad_verify.render()'s convention) means something
    went wrong, but an assembly PROBE failing empty means the fit is
    clean, which is the good outcome, not a bug.

    Asserts the render actually BUILT something otherwise (5th review,
    finding 5; ORDER fixed 6th review, finding 2 -- the 5th-review fix did
    not take): this used to return 0.0 (PASS) both for a genuinely empty
    top-level object AND for a missing/too-short output file with no
    "empty" message at all -- the second case is exactly what
    OpenSCAD's warn-and-no-op on an undefined variable produces (this
    file's own header comment documents the historical instance: a
    silently-ignored `translate([0,0,undef])` that used to make Pair 10
    compare against an untransformed part). A pair added to PAIRS but
    never wired into the dispatch `if` chain at the bottom of
    r60_assembly.scad renders NOTHING, and OpenSCAD's "Current top level
    object is empty" message is IDENTICAL whether that happened because
    nothing matched or because two real, correctly-transformed solids
    truly do not overlap -- there is no string in OpenSCAD's own output
    that tells the two apart. Checking "Current top level object is
    empty" FIRST (the 5th-review order) meant an undispatched pair, or
    r60_assembly.scad's own new dispatch-guard `assert()` firing (added
    alongside this fix), read as a clean pass: confirmed empirically --
    OpenSCAD prints BOTH "ERROR: Assertion ... failed" AND "Current top
    level object is empty" for a failed assert (exit code 1 either way,
    an empty top-level object is EXPECTED to exit non-zero too, so
    returncode alone cannot distinguish them), so whichever check runs
    first wins. ERROR/WARNING strings are now checked FIRST -- a real
    error is never masked by the empty-object message that follows it --
    and only once none of those match does "Current top level object is
    empty" mean what it is supposed to mean: a clean, genuinely
    non-overlapping fit. A missing/short output file that was NOT
    accompanied by the genuine "empty" message still raises -- matching
    scad_verify.render()'s own convention for per-part renders."""
    env = dict(os.environ, OPENSCADPATH=REPO)
    args = [OPENSCAD, "--export-format", "asciistl", "-o", out,
            "-D", "Pair=%d" % pair]
    if pair in STROKE_PAIRS:
        args += ["-D", "Ins=%d" % ins]
    if pair in OBSTRUCTION_PAIRS:
        args += ["-D", "Push=%.3f" % push]
    args += [SCAD]
    r = subprocess.run(args, capture_output=True, text=True, env=env,
                        timeout=900)
    err = r.stdout + r.stderr
    # Real failures checked FIRST -- see the docstring above for why this
    # order is the actual fix, not the "Current top level object is
    # empty" string itself.
    if ("ERROR:" in err.upper()
            or "Can't find include file" in err
            or "Ignoring unknown module" in err
            or "Ignoring unknown variable" in err
            or "Unable to convert" in err):
        raise RuntimeError("render of pair %d (Ins=%s) failed:\n%s"
                            % (pair, ins, err[-2000:]))
    # A genuinely empty top-level object is the EXPECTED result for a
    # clean mating fit -- only reached once none of the error strings
    # above matched.
    if "Current top level object is empty" in err:
        return 0.0
    if r.returncode != 0:
        raise RuntimeError("render of pair %d (Ins=%s) failed:\n%s"
                            % (pair, ins, err[-2000:]))
    if not os.path.exists(out) or os.path.getsize(out) < 10:
        raise RuntimeError(
            "render of pair %d (Ins=%s) produced no usable output and did "
            "not report an empty top-level object either:\n%s"
            % (pair, ins, err[-2000:]))
    return volume(out)


def main(argv):
    pairs = [int(x) for x in argv[1:]] or sorted(PAIRS)
    tmp = tempfile.mkdtemp(prefix="r60asm-")
    # (9th review) try/finally: this used to mkdtemp() and never clean up
    # -- see verify_rocket60.py's own main() comment for the measured
    # 16-27 MB/run figure and the two files sharing this same gap.
    try:
        bad = 0

        for p in pairs:
            name = PAIRS.get(p, "?")
            if p in STROKE_PAIRS:
                worst = (0.0, None)
                for ins in INS_SWEEP:
                    out = os.path.join(tmp, "pair%d_ins%d.stl" % (p, ins))
                    try:
                        vol = render_probe(p, ins, out)
                    except (RuntimeError, subprocess.TimeoutExpired) as e:
                        print("FAIL  pair %d %-42s Ins=%3d  render error: %s"
                              % (p, name, ins, e))
                        bad += 1
                        continue
                    ok = vol <= EPS_CM3
                    bad += 0 if ok else 1
                    print("%-4s pair %d %-42s Ins=%3dmm  %.4f cm3"
                          % ("OK" if ok else "FAIL", p, name, ins, vol))
                    if vol > worst[0]:
                        worst = (vol, ins)
                print("      -> worst along stroke: %.4f cm3 at Ins=%s\n"
                      % worst)
            elif p in OBSTRUCTION_PAIRS:
                try:
                    out0 = os.path.join(tmp, "pair%d_push0.stl" % p)
                    vol0 = render_probe(p, None, out0, push=0.0)
                    out1 = os.path.join(tmp, "pair%d_push.stl" % p)
                    vol1 = render_probe(p, None, out1, push=OVERTRAVEL_MM)
                except (RuntimeError, subprocess.TimeoutExpired) as e:
                    print("FAIL  pair %d %-42s  render error: %s" % (p, name, e))
                    bad += 1
                    continue
                ok0 = vol0 <= EPS_CM3
                ok1 = vol1 >= OBSTRUCT_MIN_CM3
                bad += 0 if ok0 else 1
                bad += 0 if ok1 else 1
                print("%-4s pair %2d %-42s  flush (Push=0):    %.4f cm3"
                      % ("OK" if ok0 else "FAIL", p, name, vol0))
                print("%-4s pair %2d %-42s  overtravel (%.0fmm): %.4f cm3"
                      % ("OK" if ok1 else "FAIL", p, name, OVERTRAVEL_MM, vol1))
            else:
                out = os.path.join(tmp, "pair%d.stl" % p)
                try:
                    vol = render_probe(p, None, out)
                except (RuntimeError, subprocess.TimeoutExpired) as e:
                    print("FAIL  pair %d %-42s  render error: %s" % (p, name, e))
                    bad += 1
                    continue
                # HINGE_PAIRS (11th review): a moving pivot, not a static
                # mating face -- see HINGE_MAX_CM3's own comment for why
                # this pair alone is not held to EPS_CM3.
                limit = HINGE_MAX_CM3 if p in HINGE_PAIRS else EPS_CM3
                ok = vol <= limit
                bad += 0 if ok else 1
                print("%-4s pair %d %-42s  %.4f cm3%s"
                      % ("OK" if ok else "FAIL", p, name, vol,
                         "  (hinge, limit %.4f)" % limit if p in HINGE_PAIRS else ""))

        # Deployment-bay axial closure (11th review, fix 7) -- see
        # check_closure()'s own docstring. Not gated on `pairs` (it does
        # not accept a Pair-style selector; it always runs) since it is
        # the one check this whole task exists to add, not an optional
        # extra a caller might want to skip.
        try:
            ok, msg = check_closure(tmp)
        except (RuntimeError, subprocess.TimeoutExpired) as e:
            print("FAIL  closure  deployment-bay axial closure (fix 7)  render error: %s" % e)
            bad += 1
        else:
            bad += 0 if ok else 1
            print("%-4s closure deployment-bay axial closure (fix 7)  %s"
                  % ("OK" if ok else "FAIL", msg))

        # Net packing volume (12th review) -- see check_packing()'s own
        # docstring. Not gated on `pairs`, same reasoning as check_closure()
        # above: this is the checked version of a number the spec now
        # cites, not an optional extra.
        try:
            ok, msg = check_packing(tmp)
        except (RuntimeError, subprocess.TimeoutExpired) as e:
            print("FAIL  packing  net chute-packing volume (12th review)  render error: %s" % e)
            bad += 1
        else:
            bad += 0 if ok else 1
            print("%-4s packing net chute-packing volume (12th review)  %s"
                  % ("OK" if ok else "FAIL", msg))

        print("\n%d check(s) failed" % bad)
        return 1 if bad else 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
