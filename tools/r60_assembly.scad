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
// -D Ins=nn (mm) sweeps the insertion stroke for the two pairs where the
//   chute tube telescopes over the e-bay aft bulkhead's skirt + the
//   spring carrier (bonded together as one continuous insert): Ins=0 is
//   first contact (the chute tube's forward rim just touches the
//   carrier's own free/aft tip); Ins=80 is fully seated (shear pins
//   aligned). See the Pair 5/6 comments for the derivation -- at Ins=80
//   the carrier's own tip lands exactly at R60_ChuteTube()'s own
//   Stop_Z = R60_Pin_Skirt_L+65 = 80, which is that module's own
//   independent statement of where the carrier ends once assembled, and
//   is the cross-check that this frame is built correctly.
// -D Facing_Y=nn (mm) is the Vega sled's measured rail-contact Y
//   (Pair 3 only) -- MEASURED off part 2's own rendered rails by the
//   Python driver (rail_facing_gap() in verify_rocket60.py), not a
//   formula restated here, per this repo's own rule 4.
//
// Frame convention: every pair is rendered in PART B's own local frame
// (the physically larger/fixed part, second in each comment below); part
// A is transformed into that frame. Each transform is derived from the
// two modules' own comments/constants, not eyeballed -- see the comment
// above each pair.

include<R60Lib.scad>
use<Rocket60.scad>

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
Facing_Y = -9.24;   // documented fallback for standalone rendering; the
                     // driver always overrides this with a measured value
Push = 0;            // overtravel probe distance, mm -- Pairs 10/11 only

// Pair 0: neck (part 1) <-> e-bay tube (part 2), in the tube's frame.
// The neck's own local z=0 is its FORWARD (nosecone) flange face; z=5
// (Flange_T) is its AFT face -- R60_Neck()'s own comment: "the aft face
// (z=Flange_T) is inside the airframe... the e-bay tube's end lands at
// r=28.4..30" there. So the neck's aft face lands on the tube's own top
// rim (tube z=R60_EBay_L), and the skirt (neck z=5..24) plugs DOWN into
// the tube from there, ending at R60_EBay_L-R60_Neck_Skirt_L. A Z-only
// mirror reverses the direction the skirt grows (built toward +z from
// the flange; assembled, it must run toward -z from the tube's top)
// while leaving every X/Y (azimuthal) feature untouched.
module Pair0_A(){ translate([0,0,R60_EBay_L+5]) mirror([0,0,1]) R60_Neck(); }
module Pair0_B(){ R60_EBayTube(); }

// Pair 1: e-bay forward bulkhead (part 4) <-> e-bay tube (part 2).
// R60_EBayFwdBulkhead() "closes the top of the e-bay" -- placed flush
// against the underside of the neck skirt's own tip
// (R60_EBay_L-R60_Neck_Skirt_L), its own T=6mm thick, extending aft from
// there. Symmetric front/back (a plain disc + centred bore), so no flip
// is needed -- either orientation is the identical shape.
module Pair1_A(){ translate([0,0,R60_EBay_L-R60_Neck_Skirt_L-6]) R60_EBayFwdBulkhead(); }
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
// exactly. Same Z-only-mirror idiom as Pair 0, for the same reason.
module Pair2_A(){ translate([0,0,12]) mirror([0,0,1]) R60_EBayAftBulkhead(); }
module Pair2_B(){ R60_EBayTube(); }

// Pair 3: Vega sled (part 6) <-> e-bay tube (part 2).
// The sled is a FLAT plate captured by the two rails at its two long
// edges (R60_VegaSled()'s own comment), not built in a frame that maps
// onto the tube's curved wall directly. Its local Z (thickness, 0..T)
// is the radial direction once assembled, with its rail-contact face at
// the rails' own measured facing-corner Y (Facing_Y, driver-supplied --
// see rail_facing_gap() in verify_rocket60.py) and increasing local Z
// moving toward +Y (into the open bore, where the Vega board stacks on
// the standoffs). Its local Y (length, +-L/2) becomes the tube's axial
// (global Z) direction; centred at R60_EBay_L/2, well inside the rails'
// own span, for a representative check.
module Pair3_A(){ translate([0,Facing_Y,R60_EBay_L/2]) rotate([-90,0,0]) R60_VegaSled(); }
module Pair3_B(){ R60_EBayTube(); }

// Pair 4: access door (part 7) <-> e-bay tube (part 2).
// R60_Door() is already built directly in the tube's own XY convention
// (centred on the same axis, covering the same +Y aperture azimuth) --
// no rotation needed. DOOR_Z_OFFSET=34.0 is verify_rocket60.py's own
// literal for R60_Door()'s local z=0 (cover base) in the tube's frame
// (Door_Z0 - R60_Door_Overlap = 40-6, following the 3rd review's
// R60_EBay_L 160->165 growth), restated here for the same reason that
// file restates it (rule 4).
module Pair4_A(){ translate([0,0,34.0]) R60_Door(); }
module Pair4_B(){ R60_EBayTube(); }

// Pair 5: e-bay aft bulkhead's SKIRT (part 5) <-> chute tube (part 3),
// along the insertion stroke.
//
// The skirt+carrier are bonded as one continuous insert that the chute
// tube telescopes over during assembly. Define a fixed "stack" frame on
// that bonded pair: stack_z=0 at the skirt's own start (R60_AftBulk_T in
// the bulkhead's own frame -- 12, restated as a literal here, matching
// the module's own local T), running to stack_z=15 (skirt tip,
// R60_Pin_Skirt_L) then stack_z=15..80 for the carrier (its own 65mm
// length, R60_SpringCarrier()'s L). At full seating the chute tube's own
// frame COINCIDES with the stack frame (chute_z=stack_z) -- the shear
// pin at chute z=8 (R60_Pin_Z_FromJoint) then lines up with the skirt's
// own pin at bulkhead z=T+8=20, i.e. stack_z=8, and the carrier's tip
// (stack_z=80) lands exactly at R60_ChuteTube()'s own
// Stop_Z=R60_Pin_Skirt_L+65=80 -- both independent, cross-checking this
// frame is right.
//
// During the stroke, the chute tube's forward rim (its own z=0) sits at
// stack position (80-Ins): at Ins=0 (first contact) that is stack_z=80,
// the carrier's own free tip; at Ins=80 (fully seated) it is stack_z=0,
// the skirt's own start. So chute_z = stack_z - (80-Ins) = stack_z+Ins-80.
// Expressed on the aft bulkhead's OWN frame (stack_z = bulkhead_z-12):
// chute_z = bulkhead_z + Ins - 92.
module Pair5_A(){ translate([0,0,Ins-92]) R60_EBayAftBulkhead(); }
module Pair5_B(){ R60_ChuteTube(); }

// Pair 6: spring carrier (part 8) <-> chute tube (part 3), along the
// SAME insertion stroke and stack frame as Pair 5 (see that comment).
// Carrier occupies stack_z=15..80 (stack_z = carrier_z+15), so
// chute_z = stack_z+Ins-80 = carrier_z+Ins-65.
//
// This is defect 1 (3rd review): the carrier's tether relief notch only
// clears its own local z=0..5, but the chute tube's tether lug is FIXED
// at chute z=4..9 for the entire stroke (it belongs to the chute tube,
// not the stack) -- as Ins sweeps, the lug's corresponding position
// travels the length of the WHOLE carrier before finally settling into
// the skirt's own (already-relieved) span, so the notch has to clear
// very nearly the carrier's full 65mm length, not just 5mm of it, or
// the lug jams against solid wall partway through the stroke.
module Pair6_A(){ translate([0,0,Ins-65]) R60_SpringCarrier(); }
module Pair6_B(){ R60_ChuteTube(); }

// Pair 7: chute tube (part 3) <-> fin can (part 9).
// Plain butt joint (assembly step 10: "Bond the chute bay tube to the
// fin can's forward end"). Fin can z=0 is its AFT (retainer) end (fin
// slots/retainer bosses near z=0, forward centring ring near
// z=R60_FinCan_L); chute tube z=R60_Chute_L is ITS aft end (bonds to the
// fin can) -- i.e. the fin can's own "more aft" direction is DECREASING
// local z, while the chute tube's is INCREASING local z (opposite
// conventions, like Pair 0/2's neck/bulkhead), so this needs the same
// Z-only-mirror idiom, not a plain translate (a first draft used a plain
// translate here and got a 51.8 cm3 "overlap" -- the two tubes' ENTIRE
// bodies stacked on the same axial span instead of meeting at one
// boundary plane, caught by sanity-checking the reported volume against
// the physical joint, which is a razor-thin butt joint, not a 51.8 cm3
// interference). Mirror reverses the fin can's own +z growth direction
// so it runs aft from the chute tube's own aft rim, matching physical
// reality: chute_z = R60_Chute_L+R60_FinCan_L - fincan_z.
module Pair7_A(){ translate([0,0,R60_Chute_L+R60_FinCan_L]) mirror([0,0,1]) R60_FinCan(); }
module Pair7_B(){ R60_ChuteTube(); }

// Pair 8: motor spacer (part 12) <-> fin can's MMT (part 9, built into
// R60_FinCan()). "Forward spacer so a motor shorter than R60_MMT_L still
// sits flush at the aft end" -- the motor occupies the fin can's own aft
// portion (fincan z=0..motor length), the spacer fills the rest forward
// of it, fincan z=motor_length..R60_MMT_L. Motor_Class default (0,
// G80T-14A, 124mm) matches R60_MotorSpacer()'s own default.
module Pair8_A(){ translate([0,0,124]) R60_MotorSpacer(); }
module Pair8_B(){ R60_FinCan(); }

// Pair 9: tether latch (part 13) <-> e-bay aft bulkhead (part 5).
// R60_TetherLatch()'s own module comment: "This module itself is
// unchanged from a plain flat-mount design (own local frame, own
// zmin=0 base) -- the offset is applied by WHERE R60_EBayAftBulkhead()
// cuts its mounting holes, not by moving this module's own geometry." So
// the latch's own z=0 mount face is translated to R60_Tether_Y (not
// built there itself) and lands on the bulkhead's own aft-most face,
// z=T+R60_Pin_Skirt_L=27 (12+15, T restated per Pair 2's own comment).
// The latch's posts grow the SAME +z direction the bulkhead's own skirt
// already grows in (further aft) -- no flip needed, a plain translate.
module Pair9_A(){ translate([0,R60_Tether_Y,12+R60_Pin_Skirt_L]) R60_TetherLatch(); }
module Pair9_B(){ R60_EBayAftBulkhead(); }

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

if (Pair==0) intersection(){ Pair0_A(); Pair0_B(); }
if (Pair==1) intersection(){ Pair1_A(); Pair1_B(); }
if (Pair==2) intersection(){ Pair2_A(); Pair2_B(); }
if (Pair==3) intersection(){ Pair3_A(); Pair3_B(); }
if (Pair==4) intersection(){ Pair4_A(); Pair4_B(); }
if (Pair==5) intersection(){ Pair5_A(); Pair5_B(); }
if (Pair==6) intersection(){ Pair6_A(); Pair6_B(); }
if (Pair==7) intersection(){ Pair7_A(); Pair7_B(); }
if (Pair==8) intersection(){ Pair8_A(); Pair8_B(); }
if (Pair==9) intersection(){ Pair9_A(); Pair9_B(); }
if (Pair==10) intersection(){ Pair10_A(); Pair10_B(); }
if (Pair==11) intersection(){ Pair11_A(); Pair11_B(); }
