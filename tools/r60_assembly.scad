// ***********************************
// Assembly-interference probe for Rocket 60.
//
// Renders intersection(A, B) for ONE mating pair from the printed stack,
// with both parts placed in their real assembled relative position (not
// just each part's own isolated local frame). A genuinely clear mating
// fit renders an EMPTY solid; a colliding one renders a real, measurable
// volume -- see tools/verify_rocket60_assembly.py, which drives this file
// and measures that volume from the exported mesh.
//
// This exists because three rounds of review found interference that no
// per-part check can see: two parts can each individually pass every
// dimension check and still collide once actually assembled, because the
// collision only exists in the RELATIVE position between them. The only
// way to catch that is to build both parts in one scene and measure the
// overlap, not infer it from separately-checked numbers.
//
// -D Pair=N selects the mating pair (see the table below).
// -D Ins=nn (mm) sweeps the insertion stroke for Pair 5, where the
//   deployment bay tube telescopes over the e-bay aft bulkhead's skirt
//   (petal-deployment transplant -- no carrier/pins any more, see that
//   pair's own comment): Ins=0 is first contact, Ins=15 (Skirt_L) is
//   fully seated.
// The Vega sled's own radial position (Pairs 3, 21-24) used to be a
// driver-measured "-D Facing_Y=nn" (rail_facing_gap() in
// verify_rocket60.py, per this repo's own rule 4) -- REMOVED, 6th review,
// finding 1: the rails it measured are gone, and the sled's radial
// position is now a closed-form R60Lib.scad constant
// (R60_Vega_Facing_Y_Nom), included live like every other shared constant
// this file already uses directly.
//
// Frame convention: every pair is rendered in PART B's own local frame
// (the physically larger/fixed part, second in each comment below); part
// A is transformed into that frame. Each transform is derived from the
// two modules' own comments/constants, not eyeballed -- see the comment
// above each pair.

include<R60Lib.scad>
use<Rocket60.scad>
// use<CableReleaseBBMicro.scad> (Pair 33/34): Rocket60.scad's own
// `use<CableReleaseBBMicro.scad>` does not transitively export that
// file's functions here -- use<> is not chained, only the file directly
// named in it -- so Pair 34's own ActBoltSweep() needs its own direct
// use<> for CRBBm_EBayTopPlate_BC_d()/_BossAz()/_Thread_d(), the SAME 3
// accessors R60_EBayAftBulkhead() itself calls (rule 4: this reads the
// real functions live, not a second hand-typed copy of their formulas).
use<CableReleaseBBMicro.scad>

// use<> imports Rocket60.scad's modules but NOT its top-level variables
// (Motor_Class=0 there is invisible here) -- module BODIES still resolve
// Motor_Class correctly (lexical scoping binds it to Rocket60.scad's own
// top level, where they were written), but any use of Motor_Class
// directly IN THIS FILE (Pair 10/11's own transforms) needs its own
// definition, matching Rocket60.scad's default. First caught as a
// silently-ignored "translate([0,0,undef])" (OpenSCAD warns and no-ops
// it), which left Pair 10 comparing the ring against an UNTRANSLATED
// spacer sitting exactly on top of it -- a 0.55 cm3 "interference" that
// was a probe bug, not the real assembled position.
Motor_Class = 0;

Pair = 0;
Ins  = 80;
Push = 0;            // overtravel probe distance, mm -- Pairs 10/11 only

// Pair 0: neck (part 1) <-> e-bay tube (part 2), in the tube's frame.
// The neck's own local z=0 is its FORWARD (nosecone) flange face; z=5
// (Flange_T) is its AFT face -- R60_Neck()'s own comment: "the aft face
// (z=Flange_T) is inside the airframe... the e-bay tube's end lands at
// r=28.4..30" there. So the neck's aft face lands on the tube's own top
// rim (tube z=R60_EBay_L), and the skirt (neck z=5..24) plugs DOWN into
// the tube from there, ending at R60_EBay_L-R60_Neck_Skirt_L. A proper
// end-for-end FLIP is needed here (rotate, not mirror -- 7th review,
// finding 5: mirror([0,0,1]) only negates Z, which is CHIRAL for any
// part with an off-axis feature -- R60_Neck()'s own camera bolt pattern,
// R60_Cam_Ang=[52.2,-52.2,180], is exactly such a feature. rotate([0,180,0])
// is the genuine rigid-body rotation a real part undergoes when installed
// pointing the other way: it reverses the skirt's growth direction (built
// toward +z from the flange; assembled, it must run toward -z from the
// tube's top) the same way mirror did, but ALSO correctly flips X, not
// just Z, matching what physically happens when you turn the same
// printed part around).
module Pair0_A(){ translate([0,0,R60_EBay_L+5]) rotate([0,180,0]) R60_Neck(); }
module Pair0_B(){ R60_EBayTube(); }

// Pair 1: e-bay forward bulkhead (part 4) <-> e-bay tube (part 2).
// R60_EBayFwdBulkhead() "closes the top of the e-bay" -- placed flush
// against the underside of the neck skirt's own tip
// (R60_EBay_L-R60_Neck_Skirt_L), its own T=R60_FwdBulk_T thick, extending
// aft from there (restated from the shared constant, not a bare literal
// -- this file already include<>s R60Lib.scad, rule 4; a bare "6" here
// and R60_FwdBulk_T elsewhere give the same part two different stations
// the moment either one changes). NOT symmetric front/back since the 7th
// review's rod-anchor inserts (R60_Vega_RodBoss_*): the boss/insert face
// MUST be the aft (e-bay-facing) face -- matching that module's own
// current comment -- so no flip is applied here either (this module's
// own local z=0 IS its aft face already).
module Pair1_A(){ translate([0,0,R60_EBay_L-R60_Neck_Skirt_L-R60_FwdBulk_T]) R60_EBayFwdBulkhead(); }
module Pair1_B(){ R60_EBayTube(); }

// Pair 2: e-bay aft bulkhead (part 5) <-> e-bay tube (part 2).
// R60_EBayAftBulkhead()'s own local z=0 is the servo pockets' FORWARD
// (pocket-opening) face; z=T=12 is its AFT face, where "3mm of aft
// material" remains under the P_D=9mm-deep pockets -- i.e. z=T is the
// disc's own aft-most point before the skirt continues further aft to
// z=Total_H=27. The disc glues inside the tube's own aft opening
// (tube z=0), pocket-face pointing into the e-bay (+tube z), so the
// disc occupies tube z=0..12 and the skirt projects tube z=-15..0,
// past the tube's own aft rim -- matching R60_EBayAftBulkhead()'s own
// comment ("projects aft, past the e-bay tube's cut end") and the
// review's own reported footprint ("aft bulkhead disc 12mm (z=0..12)")
// exactly. Same end-for-end-rotation idiom as Pair 0, for the same
// reason (7th review, finding 5): this part's servo pockets/horn slot
// are off-axis (servo-1 pocket spans local x=-17.1..6.1), so a Z-only
// mirror rendered a MIRROR IMAGE of the real part here (and at Pair 23,
// which reuses this same placement) while Pair 5's plain-translate frame
// rendered the true part -- the same physical bulkhead modelled with two
// different handednesses in one harness. rotate([0,180,0]) fixes both.
module Pair2_A(){ translate([0,0,12]) rotate([0,180,0]) R60_EBayAftBulkhead(); }
module Pair2_B(){ R60_EBayTube(); }

// Pair 3: Vega sled (part 6) <-> e-bay tube (part 2).
// The sled now BRIDGES the full window between the two bulkheads
// (R60Lib.scad's R60_Vega_Window_Z0/Z1, 6th review finding 1) instead of
// floating centred with slack -- its own local Y=0 (mid-length) lands at
// the window's own midpoint, R60_Vega_AxialCenter, NOT R60_EBay_L/2 (the
// window is not centred on the tube: the aft bulkhead alone is 12mm, the
// forward bulkhead + neck skirt together are 25mm). Local Z (thickness)
// is the radial direction once assembled, with its back face at
// R60_Vega_Facing_Y_Nom (closed-form now, not driver-measured -- see the
// file header) and increasing local Z moving toward +Y (into the open
// bore, where the Vega board stacks on the standoffs). Local Y (length,
// including the rod-carrying rails) becomes the tube's axial (global Z)
// direction. Factored into its own module: Pairs 21-24 below all place
// the sled (or its board envelope) the SAME way.
module VegaSledPlaced(){
    translate([0, R60_Vega_Facing_Y_Nom, R60_Vega_AxialCenter])
        rotate([-90,0,0])
            R60_VegaSled();
}
module Pair3_A(){ VegaSledPlaced(); }
module Pair3_B(){ R60_EBayTube(); }

// Pairs 23/24: Vega sled's RAILS (part 6) <-> the aft/forward bulkheads
// they mount to (parts 5/4) -- 6th review, finding 1; rod-based retention,
// 7th review, finding 1/2. A flush-fit interference probe proves the
// rails do not COLLIDE with their bulkhead; it does not by itself prove
// the rod holes land ON the insert/pocket bosses -- that coaxiality is
// checked mesh-against-mesh in verify_rocket60.py (rail_bulkhead_hole_
// offset(), matching this file's own hole_azimuth_at_r() idiom). Both
// bulkheads placed in the SAME tube frame Pairs 1/2 already use, but via
// the shared R60_Vega_Window_Z0/Z1 constants instead of restating
// "12"/"R60_EBay_L-R60_Neck_Skirt_L-R60_FwdBulk_T" a second time (this
// file already include<>s R60Lib.scad -- rule 4). Same rotate([0,180,0])
// end-for-end fix as Pair 2 (7th review, finding 5) -- this reuses that
// exact placement, so it inherited the same chirality bug.
module Pair23_A(){ VegaSledPlaced(); }
module Pair23_B(){ translate([0,0,R60_Vega_Window_Z0]) rotate([0,180,0]) R60_EBayAftBulkhead(); }
module Pair24_A(){ VegaSledPlaced(); }
// R60_FwdBulkhead_TubeZ0, NOT R60_Vega_Window_Z1: the bulkhead's own disc
// still sits at its TRUE tube position regardless of where its foot boss
// reaches -- see R60Lib.scad's own R60_FwdBulkhead_TubeZ0 comment for the
// bug this distinction fixes (translating the whole module to the
// boss-tip position moved the disc itself, and the boss along with it).
module Pair24_B(){ translate([0,0,R60_FwdBulkhead_TubeZ0]) R60_EBayFwdBulkhead(); }

// Pair 4: access door (part 7) <-> e-bay tube (part 2).
// R60_Door() is already built directly in the tube's own XY convention
// (centred on the same axis, covering the same +Y aperture azimuth) --
// no rotation needed. R60_Door()'s own local z=0 (cover base) lands in
// the tube's frame at Door_Z0-R60_Door_Overlap, where Door_Z0 is
// R60_EBayTube()'s own LOCAL aperture-bottom expression -- not a
// top-level R60Lib.scad constant, so it cannot be referenced live the
// way R60_EBay_L is in Pairs 0/1/3 above; computed here from the SAME
// shared constants that module builds it from (this file's include<>
// gives it live access to those), not a hand-restated literal that can
// silently go stale the way verify_rocket60.py's own DOOR_Z_OFFSET did
// across the R60_EBay_L 160->165->177 growths (see that file's rule-4
// convention for why IT still restates -- a Python file has no `include`
// to fall back on).
Door_Z0_ = (R60_EBay_L - R60_Door_Open_H) / 2;
module Pair4_A(){ translate([0,0,Door_Z0_ - R60_Door_Overlap]) R60_Door(); }
module Pair4_B(){ R60_EBayTube(); }

// Pair 5: e-bay aft bulkhead's SKIRT (part 5) <-> deployment bay tube
// (part 3), along the insertion stroke -- a plain glue joint (petal-
// deployment transplant: no carrier/pins any more, see R60_ChuteTube()'s
// own module comment). Stack frame: stack_z=0 at the skirt's own start
// (bulkhead local z=T=12), running to stack_z=Skirt_L=15 (skirt tip) --
// same derivation as the pre-transplant frame, just without the 65mm
// carrier span appended. chute_z = stack_z+Ins-15 = (bulkhead_z-12)+Ins-15
// = bulkhead_z+Ins-27 (Ins=0 first contact, Ins=15 fully seated). Both
// parts being plain, featureless cylinders now (R60_EBayAftBulkhead()'s
// skirt is a bare OD, R60_ChuteTube() has no internal cuts left at all),
// this pair necessarily reads a clean 0.0 across the whole stroke -- it
// is a sanity check on the frame math, not a defect-finding probe any
// more (that role moved to verify_rocket60.py's own OD/bore checks and
// the max-radius-vs-bore check for the petal cage/release stack).
module Pair5_A(){ translate([0,0,Ins-27]) R60_EBayAftBulkhead(); }
module Pair5_B(){ R60_ChuteTube(); }

// Pair 7: chute tube (part 3) <-> fin can (part 9).
// Plain butt joint (assembly step 11: "Bond the chute bay tube to the
// fin can's forward end"). Fin can z=0 is its AFT (retainer) end (fin
// slots/retainer bosses near z=0, forward centring ring near
// z=R60_FinCan_L); chute tube z=R60_Chute_L is ITS aft end (bonds to the
// fin can) -- i.e. the fin can's own "more aft" direction is DECREASING
// local z, while the chute tube's is INCREASING local z (opposite
// conventions, like Pair 0/2's neck/bulkhead), so this needs the same
// end-for-end-rotation idiom (7th review, finding 5), not a plain
// translate (a first draft used a plain translate here and got a 51.8
// cm3 "overlap" -- the two tubes' ENTIRE bodies stacked on the same
// axial span instead of meeting at one boundary plane, caught by
// sanity-checking the reported volume against the physical joint, which
// is a razor-thin butt joint, not a 51.8 cm3 interference), and NOT a
// Z-only mirror (same chirality bug as Pairs 0/2/23 -- a mirror is not a
// rotation any real print can undergo). rotate([0,180,0]) reverses the
// fin can's own +z growth direction so it runs aft from the chute tube's
// own aft rim, matching physical reality: chute_z = R60_Chute_L+R60_FinCan_L
// - fincan_z, with X also correctly flipping this time.
module Pair7_A(){ translate([0,0,R60_Chute_L+R60_FinCan_L]) rotate([0,180,0]) R60_FinCan(); }
module Pair7_B(){ R60_ChuteTube(); }

// Pair 8: motor spacer (part 12) <-> fin can's MMT (part 9, built into
// R60_FinCan()). "Forward spacer so a motor shorter than R60_MMT_L still
// sits flush at the aft end" -- the motor occupies the fin can's own aft
// portion (fincan z=0..motor length), the spacer fills the rest forward
// of it, fincan z=motor_length..R60_MMT_L. R60_Motor_L[Motor_Class] (7th
// review, finding 5), not a bare "124" -- the old hardcode matched only
// the G80T-14A default (Motor_Class=0); probing -D Motor_Class=1 or 2
// left the spacer at the G80T's own 124mm station instead of the H182R's
// 203mm or the H135W's 216mm, so this pair never actually checked the
// spacer against the position it occupies for either H motor.
module Pair8_A(){ translate([0,0,R60_Motor_L[Motor_Class]]) R60_MotorSpacer(); }
module Pair8_B(){ R60_FinCan(); }

// Pair 9: RETIRED (petal-deployment transplant) -- was tether latch
// (part 13, deleted) <-> e-bay aft bulkhead. See tasks/lessons.md.

// Pair 10: forward thrust ring (part 14) vs. the motor+spacer stack --
// 3rd review defect 3's own required proof "that it actually obstructs
// the MMT bore", not merely that its bore is numerically smaller.
// R60_ThrustRing()'s own frame has its AFT face (the one the spacer's
// forward face butts against in normal assembly) at z=0. Push=0 is that
// normal, flush assembled position (must be clear -- a proper butt
// contact, not a modelling overlap). Push>0 simulates the motor+spacer
// stack being driven Push mm further forward under thrust than its
// resting position -- if the ring's own bore is genuinely narrower than
// the spacer's OD, real solid material now collides (a positive volume);
// if the ring did nothing (its bore no smaller than the spacer, or not
// there at all, as before this fix), the spacer would pass straight
// through into the space the ring occupies with zero overlap regardless
// of Push. R60_MotorSpacer()'s own L is restated here (R60_MMT_L -
// R60_ThrustRing_T - R60_Motor_L[Motor_Class]) to translate it the same
// way that module positions itself.
module Pair10_A(){ R60_ThrustRing(); }
module Pair10_B(){
    translate([0,0,Push-(R60_MMT_L-R60_ThrustRing_T-R60_Motor_L[Motor_Class])]) R60_MotorSpacer();
}

// Pair 11: aft motor retainer (part 11) vs. the motor's own aft rim --
// the OTHER direction of the same "trapped in both directions" proof.
// Not a new fix (R60_MotorRetainer() is unchanged by this task), but
// the task asks the trap be confirmed at both ends, not assumed at the
// one that was not the defect. No printed "motor" part exists in this
// file to render, so a plain Ø29mm (R60_Motor_L[Motor_Class] long)
// cylinder stands in for the real motor case's own known OD -- the same
// number R60_MMT_ID (29.0+0.3 slip fit) is itself built from, restated
// as a literal per this repo's rule 4, not a printed/rendered part.
// R60_MotorRetainer()'s own frame has its INNER (motor-facing) face at
// z=0; Push=0 is the motor's aft rim flush against it (clear); Push>0
// simulates the motor being driven Push mm aft past that face.
module Pair11_A(){ R60_MotorRetainer(); }
module Pair11_B(){
    translate([0,0,Push-R60_Motor_L[Motor_Class]]) cylinder(d=29.0, h=R60_Motor_L[Motor_Class]);
}

// Pair 33: release activator (part 15) <-> e-bay aft bulkhead (part 5) --
// CRITICAL FIX, this review (Rocket60.scad's own R60_EBayAftBulkhead()
// module comment has the full defect writeup, and tasks/lessons.md
// records the mutation test below). Closes a KNOWN GAP the pair-
// enumeration comment (below) used to carry for parts 15-23: this is the
// one dimensional question that gap left uncovered ("does each part fit
// inside the bore") that actually mattered here -- whether part 15
// bolts to anything real on part 5's aft face at all.
//
// The activator's own host-mount feature (CRBBm_Activator()'s nested
// EBay_TopPlate() ring) is its AFT-most feature, local z=-19
// (CRBBm_EBayTopPlate_Z0(), CableReleaseBBMicro.scad) -- it butts flush
// against the bulkhead's own aft face, bulkhead-local z=Total_H=27
// (R60_AftBulk_T=12 + Skirt_L=15 -- Skirt_L is LOCAL to
// R60_EBayAftBulkhead(), restated here per rule 4, matching that
// module's own literal). Placing the activator's own z=0 at
// bulkhead-local z=Total_H-(-19)=46 lands the ring exactly there. No X/Y
// flip (unlike Pairs 0/2/23's end-for-end idiom): this part's own local
// -Z is already its aft-facing feature (R60_ReleaseActivator()'s own
// module comment), so a plain z-translate is the correct rigid-body
// placement.
//
// Mutation-tested (this review): rendered at the OLD code's own IMPLIED
// placement instead (bulkhead-local z=Total_H=27, i.e. no +19 correction
// -- what R60_EBayAftBulkhead()'s previous 3x-M3-at-BottomBoltCircle_d
// mount silently assumed by bolting straight to the aft face with zero
// gap) -- 19mm of the activator's own ring/servo body buries itself
// inside the bulkhead's own solid disc: a real, measured 3.7277cm3
// collision. At the correct z=46 (this file, as committed) it renders
// empty, 0.0000cm3.
module Pair33_A(){ translate([0,0,46]) R60_ReleaseActivator(); }
module Pair33_B(){ R60_EBayAftBulkhead(); }

// Pair 34: release activator mounting screws (2x #10-24, Pair 33's own
// frame) -- fastener INSERTION check, same class as Pairs 25-32 below.
// ACCESS: from the bulkhead's own open forward face (assembly step 9,
// before the deployment bay tube/release stack go anywhere near a
// completed cartridge) -- Travel swept well past that. Engage reaches
// through the bulkhead's own Total_H=27 plus into the activator's own
// boss, CRBBm_EBayTopPlate_Z1()-CRBBm_EBayTopPlate_Z0()=8mm of donor
// thread -- Engage=27+8=35, matching the module comment's own stated
// ~1-3/8in screw length. Az/BC_d read the SAME live accessors
// R60_EBayAftBulkhead() itself cuts from (rule 4), not a second
// hand-typed copy.
//
// Mutation-tested (this review, the OLD code's OTHER defect -- wrong
// bolt circle, not just wrong offset): with R60_EBayAftBulkhead()'s own
// Act_BC_d temporarily forced back to the old CRBBm_BottomBoltCircle_d()
// (r=5.5, the activator's own INTERNAL joint radius, not this real
// host-mount ring's r=21.775) -- this pair's own sweep (still aimed at
// the real boss, r=21.775) finds solid, undrilled bulkhead material in
// its path: a real 0.5717cm3 collision, confirming "no free hole to bolt
// to" is a genuine, mutation-catchable defect, not a paper one. At the
// real Act_BC_d (this file, as committed) it renders empty, 0.0000cm3.
module ActBoltSweep(){
    Act_BC_d = CRBBm_EBayTopPlate_BC_d(OD=R60_Coupler_OD);
    for (az=[CRBBm_EBayTopPlate_BossAz()+R60_Act_Clock_a,
             CRBBm_EBayTopPlate_BossAz()+R60_Act_Clock_a+180])
        rotate([0,0,az])
            translate([0, Act_BC_d/2, 0])
                FastenerSweep(Shank_d=CRBBm_EBayTopPlate_Thread_d()+0.4,
                               Head_d=8.0, Travel=20, Engage=35);
}
module Pair34_A(){ ActBoltSweep(); }
module Pair34_B(){
    union(){
        R60_EBayAftBulkhead();
        translate([0,0,46]) R60_ReleaseActivator();
    }
}

// Pair 35: petal hub (part 8) <-> petals (part 13) -- 11th review,
// critical fix 1 (the upside-down hub, tasks/lessons.md). Confirms the
// donor's own relative offset (R60_PetalHub()'s own module comment:
// petal frame = hub frame - 9.5mm, Rocket6551.scad ShowRocket()'s hub
// at NC-5/petals at NC-14.5) no longer collides now the spigot has moved
// off the petal-mating face.
//
// Mutation-tested: at the OLD (pre-fix) spigot placement this read a
// real, measured 1.3094cm3 at hub-local Z[16.70,21.50] -- exactly the
// spigot band, confirming the review's own defect report. At the
// corrected placement (this file, as committed) it renders empty,
// 0.0000cm3.
module Pair35_A(){ translate([0,0,9.5]) R60_Petals(); }
module Pair35_B(){ R60_PetalHub(); }

// Pair 36: petal spring holder (part 24) <-> petal hub (part 8) -- 11th
// review, critical fix 2 (the missing hinge, tasks/lessons.md).
// R60_PSH_Placed()'s own module comment (Rocket60.scad) has the full
// placement derivation. NOT held to EPS_CM3 like every other pair here:
// this is a moving hinge joint (the holder's axle rides in the hub's
// pivot socket), not two static faces meant to sit flush -- a small,
// real residual at the hinge boss/clearance-cut interface is ordinary
// FDM print-fit tolerance, not a placement defect, and this pair's own
// threshold (HINGE_MAX_CM3, verify_rocket60_assembly.py) is set an order
// of magnitude above the measured ~0.007-0.009cm3 range for exactly that
// reason -- see that constant's own comment for the mutation test
// proving it still catches a genuinely wrong placement.
module Pair36_A(){ R60_PSH_Placed(0); }
module Pair36_B(){ R60_PetalHub(); }

// Pair 37: petal spring holder (part 24) <-> petals (part 13) -- the
// OTHER half of Pair 36's own joint, the bolted (not hinged) interface.
// Held to the normal EPS_CM3 tolerance (a bolted flush face, not a
// moving joint): measured 6.8e-17cm3 (floating-point noise, genuinely
// zero) at the placement R60_PSH_Placed() uses -- confirms the bolt-hole
// alignment derivation (Rocket60.scad's own module comment) independent
// of Pair 36's hinge-side residual.
module Pair37_A(){ translate([0,0,9.5]) R60_Petals(); }
module Pair37_B(){ R60_PSH_Placed(0); }

// Pair 38: spring centering ring mount (part 25) <-> release top
// retainer (part 16) -- 11th review, fix 4 (CS4323 seat,
// tasks/lessons.md). The mount bolts to the retainer via
// CRBBm_MountingBoltPattern (both parts' own shared donor joint,
// CableReleaseBBMicro.scad); offset -12.7 restates the donor's own
// relative placement for this joint (Rocket6551.scad ShowCableRelease():
// translate([0,0,TopRetainerFlange_t+8.7]) off the SCR stack's own
// z=0 reference, at this design's own TopRetainerFlange_t=4 -> 12.7mm)
// -- sign found by direct render (the OTHER sign gives a real 0.1435cm3
// collision at the bolt-boss region; this one renders empty and leaves
// the two parts ~1.2mm apart, consistent with a bolted-not-flush joint).
module Pair38_A(){ translate([0,0,-12.7]) R60_CenteringRingMount(); }
module Pair38_B(){ R60_ReleaseTopRetainer(); }

// Pair 39: NOT a collision probe (11th review, fix 7 -- deployment-bay
// axial closure, tasks/lessons.md's own "mutation R60_Petal_Len=200
// passes both suites with exit 0" finding). Every other pair in this
// file intersects two parts and expects empty; this one UNIONS the
// petal cage (hub + petals, the SAME real relative offset every other
// petal-cage pair here uses) so verify_rocket60_assembly.py's own
// closure check can measure its real, assembled, mesh-derived depth --
// mesh-against-mesh, not the restated-constants version
// tools/rocket60_model.py's own HUB_TAIL_OFFSET closure assert already
// carries (this is the second, independent proof of the same fact, not
// a duplicate: the Python assert can drift from the SCAD it restates,
// this cannot, because it renders the SCAD directly).
module Pair39_A(){ translate([0,0,9.5]) R60_Petals(); }
module Pair39_B(){ R60_PetalHub(); }

// ===========================================================================
// Pair enumeration (4th review, harden-the-harness item 2; UPDATED for the
// petal-deployment transplant -- see tasks/lessons.md). Every part
// (0..24) is listed below with what it physically mates with, so a missing
// pair is a visible gap in this table, not a silent omission.
//
//  0  test ring       -- standalone print-fit GAUGE, not a flight part.
//                         EXCLUDED: mates with nothing else by design.
//  1  neck            -- e-bay tube(2)[0].
//  2  e-bay tube      -- neck(1)[0], fwd bulkhead(4)[1], aft bulkhead(5)[2],
//                         Vega sled(6)[3], door(7)[4]; arming switch's own
//                         envelope[22]; Vega board's own envelope[21].
//  3  deployment bay tube -- aft bulkhead skirt(5)[5, stroke]. Plain
//                         featureless tube now (R60_ChuteTube()'s own
//                         module comment) -- no other mating feature; the
//                         petal cage (8/13) SLIDES inside it as a plain
//                         clearance fit, not a bonded joint, so there is no
//                         meaningful interference pair to enumerate there
//                         (covered instead by verify_rocket60.py's max-
//                         radius-vs-bore check).
//  4  fwd bulkhead    -- e-bay tube(2)[1]. EXCLUDED as a direct pair vs.
//                         the neck skirt above it: both round, axis-
//                         centred profiles, no off-axis feature.
//  5  aft bulkhead    -- e-bay tube(2)[2], deployment bay tube(3)[5,
//                         stroke]. Release activator(15) bolts to this
//                         part's aft face -- pair 33 (mating fit) + pair
//                         34 (fastener sweep, 10th review, critical fix
//                         1 -- CLOSES the gap this comment used to record
//                         here); its bolt circle is DERIVED from
//                         CRBBm_EBayTopPlate_BC_d() (this part's own
//                         module comment), not hand-matched.
//  6  Vega sled       -- e-bay tube(2)[3]; arming switch's own envelope[20,
//                         retired -- see below]. CATS Vega board itself is
//                         external hardware, probed via BoardProbe[21].
//  7  access door     -- e-bay tube(2)[4]. Panel-mount switch cut into
//                         this part.
//  8  petal hub       -- fin can(9)[new spigot check, verify_rocket60.py],
//                         petals(13, bolted, not mesh-checked -- known
//                         gap, see below).
//  9  fin can         -- petal hub(8)[spigot], motor spacer(12)[8]. Motor
//                         retainer(11)/thrust ring(14) glue into this
//                         part's own bore ends -- EXCLUDED, already fully
//                         covered by verify_rocket60.py's dimensional
//                         checks (no off-axis feature). Fin(10) mates via
//                         a plain prismatic slot -- EXCLUDED for the same
//                         reason (fincan_slot_width/length already compare
//                         real edge loops mesh-against-mesh).
// 10  fin             -- fin can(9), excluded above.
// 11  motor retainer  -- fin can(9), excluded above; motor(probe)[11].
// 12  motor spacer    -- fin can/MMT(9)[8]; thrust ring(14), covered by
//                         pair 10's own flush (Push=0) check.
// 13  petals          -- petal hub(8), bolted (known gap, see below); the
//                         old chute-tube/spring-carrier stroke pairs this
//                         part's predecessor (tether latch) needed are
//                         retired -- petals ride freely inside the fixed
//                         deployment bay tube, not telescoped over a fixed
//                         insert the way the old skirt+carrier was.
// 14  thrust ring     -- motor+spacer(12)[10, obstruction]; fin can(9),
//                         excluded above.
// 15-23 release hardware -- `use<>`-instantiated library parts
//                         (CableReleaseBBMicro.scad/R65Lib.scad), each
//                         bolting/stacking onto its immediate neighbour in
//                         the release chain (part 15's own module comment
//                         in Rocket60.scad states the full stack order).
//                         Part 15's OWN mount to the airframe (part 5) is
//                         now covered -- pairs 33/34, above. The REST of
//                         the internal chain (16<->15, 17<->16, etc, all
//                         donor-native CableReleaseBBMicro.scad hardware,
//                         unmodified by this transplant) remains a KNOWN
//                         GAP, not silently dropped: this task's own
//                         binding dimensional question (does each part fit
//                         inside the airframe's own bore) is covered by
//                         verify_rocket60.py's max-radius-vs-bore check,
//                         which is what actually decided BBMini vs BBMicro
//                         (see that check's own comment); a full bolt-to-
//                         bolt mounting-interference model for the REST of
//                         the release chain has not been built this
//                         session and belongs in R60-PrintSettings.md's
//                         known-gaps list.
// 21  Vega BOARD's own envelope vs. e-bay tube(2).
// 22  fitted arming switch's own envelope vs. the Vega BOARD's own
//     envelope (pair 21's BoardProbe).
// 23  Vega sled's FEET (part 6) vs. the aft bulkhead (part 5) they bolt to.
// 24  same feet vs. the forward bulkhead (part 4).
//
// RETIRED (petal-deployment transplant): pairs 6, 9, 12, 13, 14, 15, 17,
// 19, 31 -- all checked the deleted spring-carrier/tether-latch/servo-2
// design (parts 8/13's own predecessors, plus the servo-2 horn/pin path).
// See tasks/lessons.md.
//
// RETIRED (6th review, finding 2 -- probes that cannot fail, kept here for
// history): pairs 16 (switch vs tube) and 20 (switch vs sled) were
// structurally incapable of failing under any change plausible in this
// codebase.
// ===========================================================================

// Pairs 12, 13, 14, 15: RETIRED (petal-deployment transplant) -- were the
// tether latch/spring carrier's own mutual mounting and servo-2-horn/
// pin-release path checks (parts 8/13, both deleted; servo 2 deleted
// outright). See tasks/lessons.md.

// Pair 22: arming switch's own physical envelope (5th review, finding 1:
// fitted IN the access door, part 7, not the tube) vs. the Vega BOARD's
// own envelope (Pair 21's BoardProbe) -- harness item 4 ("model the
// fitted switch"). Checking it against the door it is CUT INTO would
// prove nothing (a probe built from the same cut it stands in for is
// tautologically clear); the board is the nearest real hardware it can
// reach (6th review, finding 2: pairs 16/20, switch vs tube/sled, are
// DELETED -- see the pair-enumeration comment above for why neither could
// ever fail).
//
// SW_REACH (6th review, finding 2 -- was circular): used to be DERIVED
// from R60_Vega_Board_Inner_Y minus a stated clearance, which means
// growing R60_Vega_H (or the standoff height, or anything else that
// shifts the board) moved BOTH the probe's own reach and the board's
// position together, by construction leaving the same 2mm gap regardless
// -- a check that cannot fail no matter how the board stack changes. Now
// a STATED HARDWARE ENVELOPE instead: no datasheet exists for the actual
// switch part, so this is the maximum installed depth (threaded bushing +
// body/lugs) a purchased panel-mount toggle switch of this bushing
// diameter is assumed to need -- a stated hardware envelope, FIXED,
// independent of the board's own position, so this pair can genuinely
// fail if a future change to the Vega stack lets the board encroach on
// it. Re-mutation-tested (7th review, after the rail retention redesign
// moved R60_Vega_Facing_Y_Nom from -17.32 to ~-16.25 -- growing
// R60_Vega_Sled_W to fit the new rail pushed the whole board stack
// ~1mm closer to the door/switch side): growing SW_REACH itself past
// ~17.3mm now collides (was governed by R60_Vega_H before, which this
// design can never actually grow -- SW_REACH is the genuinely uncertain
// one of the two, being an assumed hardware envelope with no datasheet,
// so this is the more meaningful of the two possible mutations and this
// pair is no longer a check that cannot fail).
// SwitchProbe is a PROBE-ONLY solid: SW_D matches R60_Door()'s own Sw_d
// exactly (rule 4). Built directly in the DOOR's own local frame
// (matching R60_Door()'s own Sw_X/Sw_Z exactly, both READ here -- 6th
// review, finding 4: SW_X used to be declared and never consumed,
// SwitchProbe() hardcoded 0 -- a restated constant nothing reads is
// coverage that does not exist), so it drops into the SAME Pair4-style
// door-placement transform below.
SW_D = 12.0;        // R60_Door()'s own Sw_d, restated (rule 4)
SW_REACH = 10.0;     // stated hardware envelope -- typical mini panel-
                       // mount toggle switch installed depth (threaded
                       // bushing + body/lugs) behind a 2mm-thick panel
SW_X = 0;           // R60_Door()'s own Sw_X -- the cover's own crown
SW_Z = R60_Door_Overlap + R60_Door_Open_H/2;   // R60_Door()'s own Sw_Z, 48.5
// 9th review: rotate([-90,0,0]) here mapped the cylinder's local +Z (its
// own h=0..SW_REACH span) to GLOBAL +Y -- the envelope swept OUTWARD from
// the tube wall (Y=30..40 at the stated SW_REACH=10), off the airframe
// entirely and away from BoardProbe (Y=-8.25..12.75), so this pair could
// never intersect anything regardless of SW_REACH: confirmed by mutation,
// -D Pair=22 -D SW_REACH=100 (10x the stated hardware) still rendered
// "Current top level object is empty". The switch's installed hardware
// reaches INWARD from the door (toward the board), matching this file's
// own "~17.3mm" threshold comment two paragraphs up
// (R60_Body_OD/2 - R60_Vega_Board_Inner_Y), which is only the right
// number for an inward sweep. rotate([90,0,0]) maps local +Z to GLOBAL
// -Y instead, sweeping from the tube wall INWARD -- re-tested with the
// same mutation: SW_REACH=100 now measures a real, non-zero collision
// against BoardProbe.
module SwitchProbe(){
    translate([SW_X, R60_Body_OD/2, SW_Z])
        rotate([90,0,0])
            cylinder(d=SW_D, h=SW_REACH);
}

// Pair 21: Vega BOARD's own envelope (5th review, finding 2) vs. e-bay
// tube (part 7's door bosses live in part 2, R60_EBayTube()). Pair 3
// above only ever modelled the SLED (part 6) -- the real collision
// finding 2 found was between the door bosses and the BOARD, which sits
// on TOP of the sled and was never rendered anywhere in this harness.
// BoardProbe is a PROBE-ONLY solid: the board's own footprint
// (R60_Vega_L x R60_Vega_W x R60_Vega_H, no mounting/standoff detail --
// none of that is load-bearing for a clearance check), positioned the
// SAME way Pair 3 positions the sled (VegaSledPlaced()'s own frame) plus
// the stack height (sled T+Standoff_h+Vega_H) that sits between the
// sled's back and the board's own inner face.
// Board_Y0 (10th review): this probe used to assume the board is
// centred on the SLED PLATE's own symmetric printed margin
// (R60_VegaSled()'s L=R60_Vega_L+12, a 6mm margin each end) -- but the
// board's REAL mounting-hole pattern (R60_Vega_Holes, "L-shaped M3
// pattern... 60mm apart along the length", the manual-sourced physical
// anchor for where the standoffs are actually built) is NOT itself
// centred at local Y=0: its own Y span (-25..+35) centres at +5. The
// standoffs sit at the hole positions regardless of what this probe
// assumes about the board's own outline, so the correct placement for a
// clearance probe is centred on the real mounting pattern, not the
// plate's own arbitrary margin choice -- DERIVED here (from
// R60_Vega_Holes directly), not hand-typed, so the two can never
// silently disagree again.
Board_Y0 = (max([for (h=R60_Vega_Holes) h[1]])
            + min([for (h=R60_Vega_Holes) h[1]])) / 2;
// Check (rule "add a check comparing them"): does the real board, sited
// on its OWN hole pattern, still fit within the plate's own printed
// span (R60_VegaSled()'s L=R60_Vega_L+12, restated per rule 4)? At
// Board_Y0=+5 it does, but only by 1mm at the forward end (55 of 56) --
// tight, not a defect, but exactly the kind of margin a future
// R60_Vega_Holes or plate-margin change could erase silently without
// this assert.
Vega_Plate_L = R60_Vega_L + 12;
assert(Board_Y0 + R60_Vega_L/2 <= Vega_Plate_L/2
    && Board_Y0 - R60_Vega_L/2 >= -Vega_Plate_L/2,
    str("BoardProbe: the real board, centred on its own R60_Vega_Holes ",
        "pattern (Y0=", Board_Y0, "), overhangs the sled plate's own ",
        "printed span (+/-", Vega_Plate_L/2, ")"));
module BoardProbe(){
    translate([0, R60_Vega_Facing_Y_Nom + (R60_Vega_Sled_T+R60_Vega_Standoff_h),
               R60_Vega_AxialCenter])
        rotate([-90,0,0])
            translate([-R60_Vega_W/2, Board_Y0-R60_Vega_L/2, 0])
                cube([R60_Vega_W, R60_Vega_L, R60_Vega_H]);
}
module Pair21_A(){ BoardProbe(); }
module Pair21_B(){ R60_EBayTube(); }
module Pair22_A(){ translate([0,0,Door_Z0_ - R60_Door_Overlap]) SwitchProbe(); }
module Pair22_B(){ BoardProbe(); }

// Pairs 17/19: RETIRED (petal-deployment transplant) -- were the tether
// latch's own pin-withdrawal path vs. the spring carrier/chute tube
// (both deleted). See tasks/lessons.md.

// ===========================================================================
// FASTENER INSERTION CHECK (7th review, finding 1). Every check above
// this point asks "do two SOLIDS overlap once assembled" -- but a bore or
// clearance dimension can be correctly sized and STILL be unreachable:
// the Vega sled's own retired bolted feet (6th review) were exactly this
// -- the M3 screw's Ø3.4 clearance hole was the right diameter everywhere
// it existed, it just didn't exist along the screw's own approach path.
// Confirmed by mutation test (this review): sweeping the retired Ø3.4
// shank + Ø5.5 SHCS head along its own insertion axis from the tube's
// open end and intersecting against R60_VegaSled()'s own rendered mesh
// gave a real, solid 3.91cm3 collision -- not a marginal near-miss, and
// invisible to every dimensional/bore check in verify_rocket60.py and
// every mating-fit pair above, because those all measure the FINAL
// position, never the path TO it.
//
// FastenerSweep(Shank_d, Head_d, Travel, Engage) models the swept CLEAR
// VOLUME a fastener genuinely needs, built in its own frame: local
// (0,0,0) is the SEATED head/nut-bearing plane, +Z is the direction
// driven IN. The head/nut drags the SAME corridor the whole way in (it
// does not suddenly appear at the seat), so it sweeps the FULL approach,
// -Travel..0; the shank continues narrower past the seated plane, into
// its own thread/insert/pocket engagement, 0..Engage. A working fastener
// renders intersection(){FastenerSweep_placed(); real_part();} EMPTY;
// one that cannot be installed renders a measurable collision, the same
// pass/fail idiom this file already uses for mating-fit interference.
//
// ACCESS ROUTE is stated per fastener below, in the real assembly order
// (R60-PrintSettings.md section 6) -- "reachable" means reachable at the
// step it is actually installed, not merely unobstructed in an empty
// scene. Travel is always generous (>=15mm) past that accessible point,
// never tuned to the one part being checked.
// FS_SEAM (not this file's own Overlap=0.05mm): the tiny lap between the
// head and shank cylinders below exists only so their shared z=0 face
// unions cleanly -- Overlap is sized for PRINTED geometry (0.05mm is
// nothing next to a 1.6mm wall); reused here it would itself register as
// a false collision against real material at the exact seat plane
// whenever Head_d is meaningfully wider than what surrounds the shank
// there (measured on Pair 27's nut sweep: 0.003cm3 of pure Overlap
// artifact, three orders of magnitude over EPS_CM3, before this was
// separated out). 1e-6mm is far below anything this check needs to
// resolve.
FS_SEAM = 0.000001;
module FastenerSweep(Shank_d, Head_d, Travel, Engage){
    translate([0,0,-Travel]) cylinder(d=Head_d, h=Travel+FS_SEAM);
    cylinder(d=Shank_d, h=Engage+FS_SEAM);
}

// Pair 25: Vega sled retention ROD (7th review, finding 1/2 -- REPLACES
// the retired bolted feet this whole check class exists because of).
// ACCESS: bench-built cartridge (R60Lib.scad's own "Sled retention"
// comment) -- the rod's forward end is already fixed in
// R60_EBayFwdBulkhead()'s insert; R60_VegaSled() is then SLID onto the
// rod's free aft end, in open bench space, well before anything is
// inside a tube. This is the direct, corrected re-run of the mutation
// test above: same shape of check (rod swept the rail's own full length
// plus its forward insert engagement), same real part (R60_VegaSled()),
// now against the rail instead of the retired foot pad. Renders EMPTY
// only because the rail's hole is now bored its FULL length -- there is
// no axial position along it the retired design's own hole skipped.
// 8th review, finding 1: Y0/Y1 now read R60Lib.scad's own
// R60_Vega_Rail_FwdTip_Y/AftTip_Y directly instead of re-deriving
// RailFwd_L/RailAft_L against this module's own L -- that independent
// re-derivation was the SAME swapped arithmetic R60_VegaSled() itself had,
// so this probe silently agreed with the sled's own mistake instead of
// catching it. Origin sits RodInsert_h BEFORE the fwd tip (inside the fwd
// bulkhead's own insert, where the rod's fixed end actually threads in).
//
// 9th review, finding 1: Engage used to stop at R60_Vega_Rail_L +
// R60_Vega_RodInsert_h -- exactly the rail's own aft tip (the nut's
// bearing face) and NO FURTHER. That is the right reach for Pair 25
// (this module vs. R60_VegaSled() alone, which has no material past that
// tip anyway), but the SAME Engage was also reused for Pair 26 (this
// module vs. BOTH bulkheads, in the assembled tube frame -- see below),
// where it left the rod's own modelled tip 5mm short of the aft
// bulkhead's pocket-opening face and nowhere near the pocket floor.
// Mutation-tested: with the old Engage, `-D Pair=26
// -D R60_Vega_RodPocket_Depth=0` (the pocket deleted entirely) still
// rendered "Current top level object is empty" -- Pair 26's own stated
// purpose ("proves ... the fwd insert and aft pocket are genuinely
// coaxial") held only for the forward insert; the whole nut-face-to-
// pocket-floor segment was unmodelled and the pocket's own existence or
// depth was provably irrelevant to the check's result.
//
// Engage now reads R60Lib.scad's own R60_Vega_RodLength directly (rule
// 4): RodInsert_h + Rail_L + Rail_AftClear + RodPocket_Depth, the SAME
// four terms that constant derives the physical rod's own cut length
// from, so the rod modelled here and the rod a builder actually cuts can
// never silently disagree on how far it is supposed to reach. Ends
// exactly at the aft pocket's own floor (Pair 26's own frame), 5mm
// further than the rail's aft tip alone (Pair 25 stays clear either way
// -- R60_VegaSled() has no material past the rail's own tip regardless
// of how far past it this sweeps).
module RodSweep_Sled(){
    Y0 = R60_Vega_Rail_FwdTip_Y - R60_Vega_RodInsert_h;   // rod's fixed
                                                             // end, inside
                                                             // the fwd
                                                             // insert
    Engage = R60_Vega_RodLength;   // reaches the aft pocket's own floor
    for (s=[-1,1])
        translate([s*R60_Vega_Rail_X, Y0, R60_Vega_Rail_Z_Local])
            rotate([-90,0,0])
                // No separate head here -- a threaded ROD (unlike a
                // screw) is one constant diameter its whole length, so
                // Head_d=Shank_d and Travel=0 collapse FastenerSweep to a
                // plain full-length cylinder; the real "head" analog (the
                // aft nut) is checked separately below (Pair 26), since
                // IT does have its own wider envelope.
                FastenerSweep(Shank_d=R60_Vega_Rail_d, Head_d=R60_Vega_Rail_d,
                               Travel=0, Engage=Engage);
}
module Pair25_A(){ RodSweep_Sled(); }
module Pair25_B(){ R60_VegaSled(); }

// Pair 26: same rod, checked in the ASSEMBLED tube frame against BOTH
// bulkheads (VegaSledPlaced()'s own transform) -- proves the rod's full
// path also clears the bulkheads' own material (not just the rail
// itself), e.g. that the fwd insert and aft pocket are genuinely coaxial
// with the rail's own hole once everything is really assembled, not just
// independently correct in each part's own local frame.
module Pair26_A(){
    translate([0, R60_Vega_Facing_Y_Nom, R60_Vega_AxialCenter])
        rotate([-90,0,0])
            RodSweep_Sled();
}
module Pair26_B(){
    union(){
        translate([0,0,R60_Vega_Window_Z0]) rotate([0,180,0]) R60_EBayAftBulkhead();
        translate([0,0,R60_FwdBulkhead_TubeZ0]) R60_EBayFwdBulkhead();
    }
}

// Pair 27: Vega sled retention NUT (+washer). ACCESS: same bench
// cartridge step as Pair 25 -- threaded onto the rod's free aft end,
// bearing on the rail's own flat aft face (no counterbore needed: an M3
// nut's 6.35mm across-corners fits within the rail's 6.6mm square face
// with real, if tight, margin). NUT_HEAD_D is a stated generous nut+
// washer envelope, not a tight fit -- swept from open bench space
// (well aft of the rail) to the seated position.
NUT_HEAD_D = 7.5;
NUT_TRAVEL = 15.0;
// 8th review, finding 1: Y0 now reads R60Lib.scad's own
// R60_Vega_Rail_AftTip_Y directly (the nut's real seated position, local
// +Y = aft) instead of re-deriving RailAft_L against this module's own L
// -- the same independently-retyped, swapped arithmetic R60_VegaSled()
// itself had. Also flips rotate([-90,0,0]) -> rotate([90,0,0]): the sign
// controls which direction FastenerSweep's own head corridor (its
// "approach from open space" reach, -Travel..0) points once mapped into
// the sled's local Y -- with the OLD sign the head swept INTO the rail
// (y in [Y0-Travel, Y0], overlapping real material -- confirmed by mutation
// test, a real 0.9461cm3 collision against the now-correctly-positioned
// rail); with rotate([90,0,0]) it sweeps y in [Y0, Y0+Travel], the
// genuinely open bench space AFT of the rail's own tip, matching how a
// nut is actually driven onto the rod's free end.
module NutSweep_Sled(){
    Y0 = R60_Vega_Rail_AftTip_Y;   // rail's own aft tip = nut's seated position
    for (s=[-1,1])
        translate([s*R60_Vega_Rail_X, Y0, R60_Vega_Rail_Z_Local])
            rotate([90,0,0])
                FastenerSweep(Shank_d=R60_Vega_Rail_d, Head_d=NUT_HEAD_D,
                               Travel=NUT_TRAVEL, Engage=0);
}
module Pair27_A(){ NutSweep_Sled(); }
module Pair27_B(){ R60_VegaSled(); }

// Pair 28: camera bolts (3x M3x10 SHCS, R60_Neck()/R60_TestRing()'s own
// R60_CameraBoltPattern()). ACCESS: from OUTSIDE the airframe (the
// nosecone/camera end), before the neck is joined to anything (assembly
// step 7) -- always open, unobstructed air on that side. Head bears on
// the neck's own forward flange face (local z=0); shank continues
// through Flange_T(5) into the camera's own insert (5.0mm engagement,
// "does not bottom out" per that module's comment) -- Engage=10, matching
// the M3x10 screw length exactly.
module CamBoltSweep(){
    R60_CameraBoltPattern()
        FastenerSweep(Shank_d=R60_Cam_Bolt_d, Head_d=5.5, Travel=20, Engage=10);
}
module Pair28_A(){ CamBoltSweep(); }
module Pair28_B(){ R60_Neck(); }

// Pair 29: access door screws (4x M2.5 self-tap, R60_Door()/
// R60_EBayTube()'s own boss/pilot pattern). ACCESS: from OUTSIDE the
// airframe, radially -- always open (assembly step 8, and for the life
// of the rocket: this is the one fastener meant to be removed/replaced
// repeatedly). Radial axis, not axial: same Door_Boss_Az() idiom Pair 4's
// own header comment and R60_EBayTube()/R60_Door() already use for a
// hole bored along the wall's true local radial direction, restated here
// (rule 4, this file cannot call a function local to another module).
// Head bears on the door cover's own outer face (r=R60_Body_OD/2+T);
// shank continues through the cover's own T(2) at the clearance
// diameter (Door_Hole_d=2.7). Past that, the engagement is NOT the same
// diameter: R60_EBayTube()'s own pilot hole (Door_Pilot_d=2.0mm) is
// deliberately NARROWER than the clearance shank -- a self-tapping M2.5
// is meant to CUT its own thread into that pilot, not pass through it
// with clearance, so a straight 2.7mm sweep through the pilot's own
// depth would read as a false collision against material the screw is
// designed to displace (measured before this split: 0.065cm3, the
// pilot's own annulus). Modelled as two stages, not one FastenerSweep
// call: 2.7mm through the cover's own T(2), then 2.0mm for the pilot's
// own Door_Pilot_Depth(6).
function DoorBoltAz(x) = acos(x/(R60_Body_OD/2));
// $fn=32 (not the file-wide 180): R60_Door()'s own switch/screw holes and
// R60_EBayTube()'s own door boss/pilot cuts are ALL bored at a local
// $fn=32 (both modules' own comments: the fine 180-facet tessellation at
// this off-axis azimuth produced a numerically degenerate boolean). A
// sweep cylinder left at the file-wide $fn=180 is a rounder, LARGER-area
// polygon than the real $fn=32 hole it is being checked against, so it
// pokes past the coarse hole's own flat facets into real material that
// was never actually removed -- measured before this fix: 0.00075cm3 of
// pure tessellation-mismatch artifact, matching neither Pair 27's
// FS_SEAM class nor a real defect.
module DoorBoltSweep(){
    Hole_X = R60_Door_Open_W/2 + R60_Door_Hole_Clear;
    Hole_Z = [Door_Z0_ - R60_Door_Hole_Clear, Door_Z0_ + R60_Door_Open_H + R60_Door_Hole_Clear];
    for (x=[-Hole_X, Hole_X], z=Hole_Z)
        rotate([0,0,DoorBoltAz(x)])
            translate([R60_Body_OD/2 + 2, 0, z])
                rotate([0,-90,0])
                    union(){
                        FastenerSweep(Shank_d=2.7, Head_d=5.0, Travel=20, Engage=2.0, $fn=32);
                        translate([0,0,2.0]) cylinder(d=2.0, h=6.0+FS_SEAM, $fn=32);
                    }
}
module Pair29_A(){ DoorBoltSweep(); }
module Pair29_B(){ union(){ translate([0,0,Door_Z0_ - R60_Door_Overlap]) R60_Door(); R60_EBayTube(); } }

// Pair 30: motor retainer bolts (3x M3, R60_MotorRetainer()/
// R60_FinCan()'s own Boss_BC_R=24 pattern, 60deg off the fins). ACCESS:
// from OUTSIDE, the fin can's fully open aft end (assembly step 10) --
// never inside a tube. Head bears on the retainer's own EXPOSED aft face
// -- local z=T(6), NOT z=0 as this comment used to say: Pair 11's own
// comment (above) already establishes R60_MotorRetainer()'s local z=0 as
// its INNER, motor-facing side, and this pair contradicted it. Shank
// continues from the exposed face through the retainer's own T(6) into
// the fin can's own insert (6.7mm engagement) -- Engage=12.7=T+Insert_h.
//
// 9th review, finding 1: with no translate/rotate at all, FastenerSweep's
// own local (0,0,0) (its seated head/nut-bearing plane) landed directly
// on the retainer's local z=0 -- its INNER face, not the exposed one --
// so the head corridor (z=-20..0) swept pure air on the wrong side while
// the shank (z=0..12.7) only ever overlapped the retainer's own
// ALREADY-CUT Bolt_d=3.4 clearance hole (a degenerate, zero-clearance
// tangent) before running 6.7mm PAST the retainer's own material (z>6)
// into open space -- Pair30_B never rendered the fin can at all, so that
// final 6.7mm could not have found the insert even if it had been aimed
// correctly. Confirmed: Pair 30 at defaults (both before and after this
// fix's frame correction, with Pair30_B still retainer-only) measures
// 0.0000 cm3 -- proving nothing about the insert engagement, since there
// is no insert geometry in the scene to fail against.
//
// Fixed two ways together: (1) translate to the retainer's own EXPOSED
// face (z=6) and rotate([180,0,0]) to flip FastenerSweep's own driven-in
// direction -- the AXIS chosen for this specific flip does not matter
// (FastenerSweep is two coaxial cylinders with no off-axis feature, so a
// 180deg rotation about any axis in its own XY plane is the same
// non-chiral flip), it is written [180,0,0] only to match the OTHER flip
// below, which is NOT axis-interchangeable. (2) Pair30_B now unions in
// R60_FinCan() itself (Pair 29's own union(){door; tube} is the
// precedent for a bolt sweep needing more than the one part its head
// bears on), placed with rotate([180,0,0]) -- an X-axis flip, NOT a
// Y-axis flip: unlike FastenerSweep, R60_FinCan()
// is NOT axisymmetric -- its 3-boss pattern only maps onto itself under
// the RIGHT axis. Negating Y (X-axis flip) maps angle set {60,180,300} to
// {300,180,60}, the SAME set; negating X (Y-axis flip) maps it to
// {120,0,240}, a DIFFERENT set 60deg off every real boss. Confirmed
// empirically, NOT merely reasoned: substituting rotate([0,180,0]) here
// renders a SPURIOUS 0.0191cm3 collision at DEFAULT parameters on the
// otherwise-correct design (the misaligned boss pattern clips real
// material nowhere the true assembly does) -- i.e. the wrong axis does
// not fail safe as a second vacuous check, it actively breaks the gate on
// a clean build, which is the more falsifiable proof that axis choice
// here is a real geometric fact, not a stylistic pick.
//
// NO translate on the fin can placement -- tools/rocket60_model.py's own
// station-audit comment is the authority: "R60_MotorRetainer()'s own
// local z=0, its INNER motor-facing side, MEETS the fin can's aft tip
// [i.e. the SAME point, not offset], and its solid material -- z=0..T --
// grows AWAY from the motor, i.e. AFT of that tip, not back into the fin
// can." So retainer z=0 and fin can z=0 (its own aft tip, where the
// boss/insert cut starts) are the SAME global point; a flip with no added
// offset is what makes them coincide. (First attempt added
// translate([0,0,6]) here, reasoning the retainer's z=6 exposed face was
// the shared point instead -- caught by the mutation below: it rendered
// a real 0.0626cm3 collision at DEFAULT parameters, no mutation needed,
// because it planted 6mm of fin can boss material inside the bolt's own
// modelled travel that the real assembly does not have there.)
//
// Mutation-tested: temporarily shrinking R60_FinCan()'s own Insert_h
// 6.7->3 (a boss whose insert no longer reaches as deep as the retainer
// assumes) rendered EMPTY under the OLD (retainer-only, wrong-frame)
// dispatch regardless of Insert_h -- the fin can was never in the scene,
// so no value of Insert_h could ever matter. With this fix, the same
// mutation gives a real, robust collision (fixed diameter path 3.4mm
// finds only 3mm of insert depth where it expects 6.7); at the real
// Insert_h=6.7 this pair renders empty (clean, real margin against the
// Ø4.0 insert bore), confirming the fix does not false-positive on the
// real design.
module RetainerBoltSweep(){
    for (i=[0:R60_nFins-1])
        rotate([0,0,i*360/R60_nFins + 180/R60_nFins])
            translate([24,0,6])
                rotate([180,0,0])
                    FastenerSweep(Shank_d=3.4, Head_d=5.5, Travel=20, Engage=12.7);
}
module Pair30_A(){ RetainerBoltSweep(); }
module Pair30_B(){
    union(){
        R60_MotorRetainer();
        rotate([180,0,0]) R60_FinCan();
    }
}

// Pair 31: RETIRED (petal-deployment transplant) -- was the tether
// latch's own mounting bolts (part 13's predecessor). See
// tasks/lessons.md. The release activator's (part 15) own mounting
// bolts into this bulkhead are a known gap, not yet given an equivalent
// sweep check -- see the pair-enumeration comment above.

// Pair 32: Vega board mounting screws (3x M3, R60_Vega_Holes into
// R60_VegaSled()'s own standoffs). ACCESS: entirely on the bench -- the
// board is mounted to the sled BEFORE the sled goes anywhere near a rod
// or a tube (R60-PrintSettings.md step 2). Included for completeness
// (the review's own fastener list names it explicitly), even though a
// bench-only fastener with open access on both sides is the least likely
// of this whole list to ever fail. Shank travels through the standoff's
// own T+Standoff_h(8mm) -- Engage=8, no separate thread engagement (the
// board's own hole is a plain clearance hole, capped with a nut, not
// threaded into the standoff). Driven from BELOW the plate (its own
// underside, z=0, open bench air before the board is mounted) UP through
// the standoff to the board, where a nut on top captures it -- the seat
// is the plate's own bottom face, z=0, not the standoff's own top.
module BoardBoltSweep(){
    for (h=R60_Vega_Holes)
        translate([h[0], h[1], 0])
            FastenerSweep(Shank_d=R60_Vega_BoardHole_d, Head_d=5.5, Travel=20, Engage=8);
}
module Pair32_A(){ BoardBoltSweep(); }
module Pair32_B(){ R60_VegaSled(); }

// R60_ThrustRing() (part 14) carries NO fastener at all -- it is bonded
// (glued) into the MMT's forward opening, flush with the fin can's own
// forward tip, "the last step before bonding the chute bay tube on" (its
// own module comment) -- i.e. installed at the fin can's own fully open
// forward end, the shortest and most directly accessible reach in this
// entire design, not a fastener travelling any real distance at all. A
// FastenerSweep() here would be checking a hardware class this part does
// not use; its own installation reachability is already the direct
// consequence of R60_MotorSpacer()'s length derivation (that module's
// comment) and Pair 10's own obstruction-proof, not a gap this check
// class needs to fill.

// Dispatch. Pairs 16/18/20 are intentionally ABSENT (6th review, finding
// 2 -- deleted, not renumbered away, so the gap in the sequence itself is
// a visible record of what was removed and why -- see the pair-
// enumeration comment above each deletion for the reason).
//
// KNOWN_PAIRS + the trailing assert (6th review, finding 2, "render_probe
// still passes empty renders"): a Pair value with NO matching `if` below
// renders NOTHING, and OpenSCAD's own "Current top level object is
// empty" message is IDENTICAL whether that happened because nothing
// matched or because two real, correctly-transformed solids truly do not
// overlap -- verify_rocket60_assembly.py's render_probe() cannot tell
// those apart from the console output alone no matter what order it
// checks strings in. The actual fix has to live HERE, in the one place
// that knows which Pair values are real: assert it explicitly, so a pair
// added to PAIRS (the Python side) but never wired into an `if` below
// halts with a real ERROR instead of silently reading "OK 0.0000 cm3"
// forever. A separate hand-maintained list (rather than reusing the `if`
// conditions themselves) is deliberate -- it is the SAME kind of
// restatement rule 4 already accepts (Python cannot execute this file's
// own `if` chain to ask it), and unlike a totally silent gap, a value
// missing from BOTH this list and the dispatch below is caught anyway:
// the run simply asks for a Pair number verify_rocket60_assembly.py's own
// PAIRS dict never requested.
// Pairs 6, 9, 12, 13, 14, 15, 17, 19, 31 RETIRED (petal-deployment
// transplant, see tasks/lessons.md) -- removed from this list too, not
// just their own `if` dispatch line below, per this comment's own rule.
KNOWN_PAIRS = [0,1,2,3,4,5,7,8,10,11,21,22,23,24,
               25,26,27,28,29,30,32,33,34,35,36,37,38,39];
assert(search([Pair], KNOWN_PAIRS)[0] != [],
    str("r60_assembly.scad: Pair=", Pair, " has no dispatch entry below ",
        "(or was deleted and should be removed from verify_rocket60_",
        "assembly.py's PAIRS dict too)"));

if (Pair==0) intersection(){ Pair0_A(); Pair0_B(); }
if (Pair==1) intersection(){ Pair1_A(); Pair1_B(); }
if (Pair==2) intersection(){ Pair2_A(); Pair2_B(); }
if (Pair==3) intersection(){ Pair3_A(); Pair3_B(); }
if (Pair==4) intersection(){ Pair4_A(); Pair4_B(); }
if (Pair==5) intersection(){ Pair5_A(); Pair5_B(); }
if (Pair==7) intersection(){ Pair7_A(); Pair7_B(); }
if (Pair==8) intersection(){ Pair8_A(); Pair8_B(); }
if (Pair==10) intersection(){ Pair10_A(); Pair10_B(); }
if (Pair==11) intersection(){ Pair11_A(); Pair11_B(); }
if (Pair==21) intersection(){ Pair21_A(); Pair21_B(); }
if (Pair==22) intersection(){ Pair22_A(); Pair22_B(); }
if (Pair==23) intersection(){ Pair23_A(); Pair23_B(); }
if (Pair==24) intersection(){ Pair24_A(); Pair24_B(); }
if (Pair==25) intersection(){ Pair25_A(); Pair25_B(); }
if (Pair==26) intersection(){ Pair26_A(); Pair26_B(); }
if (Pair==27) intersection(){ Pair27_A(); Pair27_B(); }
if (Pair==28) intersection(){ Pair28_A(); Pair28_B(); }
if (Pair==29) intersection(){ Pair29_A(); Pair29_B(); }
if (Pair==30) intersection(){ Pair30_A(); Pair30_B(); }
if (Pair==32) intersection(){ Pair32_A(); Pair32_B(); }
if (Pair==33) intersection(){ Pair33_A(); Pair33_B(); }
if (Pair==34) intersection(){ Pair34_A(); Pair34_B(); }
if (Pair==35) intersection(){ Pair35_A(); Pair35_B(); }
if (Pair==36) intersection(){ Pair36_A(); Pair36_B(); }
if (Pair==37) intersection(){ Pair37_A(); Pair37_B(); }
if (Pair==38) intersection(){ Pair38_A(); Pair38_B(); }
// Pair 39: UNION, not intersection -- see Pair39_A/B's own comment above.
if (Pair==39) union(){ Pair39_A(); Pair39_B(); }
