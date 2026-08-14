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

// ===========================================================================
// Pair enumeration (4th review, harden-the-harness item 2). Every part
// (0..14) is listed below with what it physically mates with, so a missing
// pair is a visible gap in this table, not a silent omission the way
// finding 2 (13 <-> 8) was: that collision was real (0.0973cm3) and went
// completely unchecked because nothing in the pre-4th-review matrix ever
// examined that pair. This is not a re-derivation from first principles of
// "what could possibly touch" -- it is read off each module's own comment
// in Rocket60.scad, which already states what it mounts to/mates with.
//
//  0  test ring     -- standalone print-fit GAUGE (R60_TestRing()'s own
//                       module comment), not a flight part. EXCLUDED: mates
//                       with nothing else in the assembly by design.
//  1  neck          -- e-bay tube(2) [pair 0]. Nosecone/camera are external
//                       hardware, not Rocket60.scad modules -- EXCLUDED,
//                       nothing to render.
//  2  e-bay tube     -- neck(1)[0], fwd bulkhead(4)[1], aft bulkhead(5)[2],
//                       Vega sled(6)[3], door(7)[4]; the fitted arming
//                       switch's own envelope[16, new -- finding 1, the
//                       switch now lives in the door, part 7, and reaches
//                       INTO this tube once installed] and the Vega
//                       board's own envelope[21, new -- finding 2].
//  3  chute tube     -- aft bulkhead skirt(5)[5, stroke], carrier(8)[6,
//                       stroke], fin can(9)[7], tether latch(13)[13, new].
//  4  fwd bulkhead   -- e-bay tube(2)[1]. Also sits immediately below the
//                       neck's own skirt (R60_EBayTube()'s Rail_Z1 comment)
//                       -- EXCLUDED as a direct pair: both are ROUND,
//                       axis-centred profiles capped by the SAME Z-window
//                       derivation already asserted in R60_EBayTube() (the
//                       Rail_Z1 empty/inverted guard) and cross-checked by
//                       pairs 0/1 each individually clearing the tube; no
//                       off-axis feature exists on either part that a
//                       concentric abutment could hide (unlike findings 1/2/
//                       5, which are ALL off-axis or hidden-behind-a-face).
//  5  aft bulkhead   -- e-bay tube(2)[2], chute tube(3)[5, stroke], tether
//                       latch(13)[9], spring carrier(8)[14, new -- both
//                       bond to this part's SAME aft face].
//  6  Vega sled      -- e-bay tube(2)[3]; the fitted arming switch's own
//                       envelope[20, new -- finding 1]. CATS Vega board
//                       itself is external hardware, not a rendered part
//                       -- but its envelope IS probed (BoardProbe, pair
//                       21) against part 2, since Pair 3 above only ever
//                       modelled this sled, never the board that mounts
//                       on top of it (finding 2).
//  7  access door     -- e-bay tube(2)[4]. The panel-mount switch is now
//                       CUT INTO this part (finding 1) rather than a hole
//                       in the tube -- see pairs 16/20 (switch envelope
//                       vs. tube/sled) below; a switch-vs-its-own-host-
//                       door pair would be tautological.
//  8  spring carrier -- chute tube(3)[6, stroke], aft bulkhead(5)[14, new],
//                       tether latch(13)[12, new -- finding 2].
//  9  fin can        -- chute tube(3)[7], motor spacer(12)[8]. Motor
//                       retainer(11) and thrust ring(14) both glue directly
//                       into this part's own bore ends -- EXCLUDED as
//                       separate pairs: both are plain concentric
//                       cylinder-in-bore fits (retainer OD/bolt-circle,
//                       ring OD) already fully covered by
//                       verify_rocket60.py's own "retainer OD"/"thrust ring
//                       fits MMT bore" dimensional checks, with no off-axis
//                       feature on either part an intersection probe could
//                       catch that those checks would not. Fin(10) mates
//                       via a plain prismatic slot -- EXCLUDED for the same
//                       reason (fincan_slot_width/fincan_slot_length
//                       already compare the slot's real edge loop against
//                       the fin's real edge loop mesh-against-mesh; no
//                       rotation/offset ambiguity exists for a probe to add
//                       rigor to).
// 10  fin            -- fin can(9), excluded above.
// 11  motor retainer -- fin can(9), excluded above; motor(probe)[11].
// 12  motor spacer   -- fin can/MMT(9)[8]; thrust ring(14), covered by
//                       pair 10's own flush (Push=0) check.
// 13  tether latch   -- aft bulkhead(5)[9]; spring carrier(8)[12, new];
//                       chute tube(3)[13, new] -- discovered while fixing
//                       finding 2: the SAME off-axis base corners
//                       (r=28.97mm from the shared axis) that hit the
//                       carrier's counterbore rim also reach 0.57mm past
//                       the chute tube's own 28.4mm bore.
// 14  thrust ring    -- motor+spacer(12)[10, obstruction]; fin can(9),
//                       excluded above (plain concentric bore fit).
//
// Two further checks (15, 17, 19) are NOT part-vs-part pairs at all -- they
// assert a DECLARED MOVING ELEMENT's required path is not obstructed by
// any real part (harness item 3), which no static dimension check or the
// pairs above can express. Pair 21 IS part-vs-part (the board is a real,
// if unmodelled-in-detail, hardware appendage of a real part, not an
// abstract path):
// 15  servo-2-horn/pin-release actuation path vs. tether latch(13) --
//     finding 5.
// 21  Vega BOARD's own envelope (not modelled by Pair 3's sled-only probe)
//     vs. e-bay tube(2) -- finding 2.
// 22  fitted arming switch's own envelope (in the door, part 7) vs. the
//     Vega BOARD's own envelope (pair 21's BoardProbe) -- the board's own
//     Z span overlaps the door's aperture by construction, so this is a
//     real reach, not a hypothetical one.
// 23  Vega sled's FEET (part 6) vs. the aft bulkhead (part 5) they bolt
//     to -- 6th review, finding 1 (the retention scheme that replaced the
//     rails/zip-ties).
// 24  same feet vs. the forward bulkhead (part 4).
//
// 6th review, finding 2 (probes that cannot fail): pairs 16 (switch vs
// tube) and 20 (switch vs sled) are DELETED, not fixed -- both were
// structurally incapable of failing under any change plausible in this
// codebase, not merely passing with some margin:
//   - Pair 16: the switch's own X reach (governed by SW_D=12mm, a fixed
//     hardware dimension) is 15mm short of the nearest solid tube
//     material (the door boss at x~21mm) even at the aperture's own edge
//     (x=18mm) -- SW_D would need to more than double before this could
//     ever register, and nothing else in this design moves that boundary.
//   - Pair 20: even correctly placed (it never was -- Pair20_B rendered
//     R60_VegaSled() in its own raw, unplaced local frame, so the "pass"
//     it read was two unrelated Z ranges never overlapping at all, not a
//     real clearance result), the switch's reach and the sled's position
//     are governed by entirely independent constants ~31mm apart; nothing
//     the switch can plausibly reach that clears the much-nearer Vega
//     BOARD (pair 22, which strictly shadows the sled from the switch's
//     approach and always fails first) leaves any way for this pair to
//     fail either. A probe that cannot fail is worse than no probe -- see
//     the review round's own framing -- so both rows are removed rather
//     than kept "passing".
//
// Harness item 3 names three moving elements: "servo horn, pin, cord".
// The CORD path (chute tube lug -> aft bulkhead notch -> carrier notch)
// IS covered, just not by a dedicated pair: the lug/notch mesh-vs-mesh
// clearance checks in verify_rocket60.py, the full-stroke pairs 6/13
// (which sweep the exact geometry the cord's own channel runs through),
// and the aligned (+-6,-22) cord holes across the bulkhead/carrier
// together assert the same thing a standalone probe would. The PIN
// itself -- the "3mm steel dowel, not printed" that is the tether
// latch's actual load path (R60_TetherLatch()'s own comment) -- is now
// covered by pairs 17-19 (coordinator override, same review round):
// PinPath(), the SAME bore R60_TetherLatch() cuts for it, checked
// against the spring carrier, the aft bulkhead and the chute tube. All
// three pass (0.0000cm3). Corrected (5th review, finding 3): the pin's
// own designed travel clears the carrier's own counterbore rim (the
// binding constraint, r=CB_D/2=25.5mm) with real headroom, but the
// PREVIOUS claim above ("1.27mm of real margin") only checked the pin's
// CENTRELINE against the rim -- sqrt(25.5^2-13.6^2)=21.57mm -- ignoring
// the pin's own 1.6mm radius, which offsets its farthest point to
// R60_Tether_Y+Pin_d/2=15.2mm. Correctly counted,
// sqrt(25.5^2-15.2^2)=20.47mm was available, and the old PIN_BASE_L+2
// reach (half-length 20.3mm) had only 0.15mm of real margin -- confirmed
// by mutation, first contact between half-reach 20.45 and 20.6mm, not the
// "+3.4mm" the old claim implied (that mutation probed ~20x past the real
// threshold). PIN_REACH is now derived from the pin's actual functional
// withdrawal need (clear both posts + a stated grip allowance) capped
// with a stated 1.5mm minimum clearance to the rim -- see
// R60_TetherLatch()'s own Pin_Reach comment (Rocket60.scad) for the
// derivation this file restates below.
// ===========================================================================

// Pair 12: tether latch (part 13) <-> spring carrier (part 8) -- finding 2.
// Both mount flush on the SAME e-bay aft bulkhead aft face (see Pair 9's
// own comment for the latch; R60_SpringCarrier()'s own module comment:
// "glued to this skirt's aft face" for the carrier) -- i.e. both parts'
// own local z=0 coincide once assembled. No flip needed for either (both
// already grow away from that shared mount face in their own +z).
module Pair12_A(){ translate([0,R60_Tether_Y,0]) R60_TetherLatch(); }
module Pair12_B(){ R60_SpringCarrier(); }

// Pair 13: tether latch (part 13) <-> chute tube (part 3), along the SAME
// insertion stroke/stack frame as Pairs 5/6 (see Pair 5's comment). The
// latch mounts at the SAME location as the carrier's own local z=0 (both
// glued to the skirt's aft-most tip, stack_z=15) -- so it needs the exact
// same Ins-65 stroke transform Pair 6 uses for the carrier, not a fixed
// placement: as the chute tube slides on, the latch (a fixed appendage of
// the skirt+carrier insert, like the tether lug it was found alongside) can
// jam against the tube's own wall partway through the stroke even where it
// clears at full seating, the same failure class finding 1 (3rd review) was.
module Pair13_A(){ translate([0,R60_Tether_Y,Ins-65]) R60_TetherLatch(); }
module Pair13_B(){ R60_ChuteTube(); }

// Pair 14: spring carrier (part 8) <-> e-bay aft bulkhead (part 5) --
// enumeration completeness (harness item 2): both bond to the SAME aft
// face the latch does (Pairs 9/12 above), so this is the third leg of that
// same shared-mount-face relationship. Same "plain translate, no flip"
// frame as Pair 9 (carrier's own +z already grows aft, the same direction
// the bulkhead's own skirt does).
module Pair14_A(){ translate([0,0,12+R60_Pin_Skirt_L]) R60_SpringCarrier(); }
module Pair14_B(){ R60_EBayAftBulkhead(); }

// Pair 15: servo-2-horn/pin-release actuation path vs. tether latch (part
// 13) -- finding 5, harness item 3 ("for every declared moving element...
// assert its required path is not obstructed"). R60_EBayAftBulkhead()'s
// horn slot was extended through its own skirt specifically so servo 2's
// (unmodelled, see R60_TetherLatch()'s own module comment) actuation
// linkage can reach this latch -- but the latch's solid 4mm base used to be
// bolted flat over that exact opening. HornPath is a PROBE-ONLY solid, not
// one of the 15 real parts: it stands in for "the volume that linkage must
// be free to occupy", sized/positioned identically to the pass-through
// R60_TetherLatch() itself now cuts (Base_Pass_W x R60_Horn_W -- see that
// module's own comment for why this is narrower than the bulkhead's full
// R60_Horn_L: the two posts, the pin's own load path, cannot be cut
// through) so a regression in EITHER part's own opening shows up here.
// Positioned in the aft bulkhead's own frame, spanning from well inside
// its servo-2 pocket (z=P_D=9, restated) through to past the latch's own
// pin (bulkhead z=12+R60_Pin_Skirt_L+Base_T+Post_H=27+4+12=43).
Post_X_ = 9; Post_d_ = 8;
HornPath_W = 2*(Post_X_ - Post_d_/2);   // 10, matching R60_TetherLatch()'s
                                          // own Base_Pass_W derivation
module HornPath(){
    translate([-HornPath_W/2, R60_Tether_Y-R60_Horn_W/2, 9])
        cube([HornPath_W, R60_Horn_W, 43-9]);
}
module Pair15_A(){ HornPath(); }
module Pair15_B(){ translate([0,R60_Tether_Y,12+R60_Pin_Skirt_L]) R60_TetherLatch(); }

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
// diameter is assumed to need, same "unmodelled companion hardware"
// treatment as R60_SpringCarrier()'s plunger/lock ring -- but FIXED,
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
module BoardProbe(){
    translate([0, R60_Vega_Facing_Y_Nom + (R60_Vega_Sled_T+R60_Vega_Standoff_h),
               R60_Vega_AxialCenter])
        rotate([-90,0,0])
            translate([-R60_Vega_W/2, -R60_Vega_L/2, 0])
                cube([R60_Vega_W, R60_Vega_L, R60_Vega_H]);
}
module Pair21_A(){ BoardProbe(); }
module Pair21_B(){ R60_EBayTube(); }
module Pair22_A(){ translate([0,0,Door_Z0_ - R60_Door_Overlap]) SwitchProbe(); }
module Pair22_B(){ BoardProbe(); }

// Pairs 17/19: tether latch PIN withdrawal path vs. every real part
// around it once assembled -- coordinator override (same review round).
// Pair 18 (vs. the aft bulkhead itself) is DELETED (6th review, finding
// 2): the latch mounts FLUSH on the bulkhead's own aft-most face (bulkhead
// z=Total_H=27, Pair9's own transform), and the pin lives entirely inside
// the latch's own posts, 4-16mm PAST that face -- by construction there is
// no bulkhead-frame Z the pin can ever reach (checked: pin z=27+12=39,
// bulkhead's own material stops at z=27, no shared Z under any change to
// Pin_d/Pin_Reach/Post_H plausible in this design). Not a coverage gap:
// the geometry that would make this pair meaningful (the pin reaching
// back INTO the bulkhead) cannot occur given how the latch is mounted.
// Flagged in this file's own pair-enumeration comment above as
// unverified; the same "geometry fits but cannot function" failure
// class the horn-path check (pair 15) already caught, so it gets the
// same treatment: a probe-only solid, not an invented extra reach, but
// the SAME cylinder R60_TetherLatch() itself already cuts for the pin
// bore (Pin_d, Base_L+2, centred at local z=Base_T+Post_H-4) -- the
// space the design ALREADY provides for the "3mm steel dowel, not
// printed" that is this latch's actual load path. Restated as literals
// (rule 4), matching R60_TetherLatch()'s own Pin_d/Base_L/Base_T/Post_H.
//
// PinPath() is built in the SAME local frame R60_TetherLatch() itself
// uses (mount face at local z=0), so it can be dropped into each pair's
// EXISTING latch transform (Pair9/12/13's own translates) directly,
// rather than a fourth, independently-derived placement -- if any of
// those three transforms is ever wrong, the corresponding latch pair
// (9/12/13) fails right along with the pin-path pair checking the same
// frame, rather than silently disagreeing with it.
PIN_D = 3.2;         // R60_TetherLatch()'s own Pin_d (3.0+IDXtra)
PIN_REACH = 17.0;    // R60_TetherLatch()'s own Pin_Reach (Post_X+Post_d/2+
                       // Pin_Reach_Grip = 9+4+4) -- was PIN_BASE_L+2 (the
                       // latch's own full base width, half-reach 20.3mm),
                       // the latch's own functional need, not its base
                       // width (5th review, finding 3)
PIN_Z_LOCAL = 12;    // R60_TetherLatch()'s own Base_T+Post_H-4 (4+12-4)
module PinPath(){
    translate([0, 0, PIN_Z_LOCAL])
        rotate([0,90,0])
            cylinder(d=PIN_D, h=2*PIN_REACH, center=true);
}
// vs. spring carrier -- same frame as Pair12.
module Pair17_A(){ translate([0,R60_Tether_Y,0]) PinPath(); }
module Pair17_B(){ R60_SpringCarrier(); }
// vs. chute tube, at full seating -- same frame as Pair13 (Ins=80 default).
module Pair19_A(){ translate([0,R60_Tether_Y,Ins-65]) PinPath(); }
module Pair19_B(){ R60_ChuteTube(); }

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
module RodSweep_Sled(){
    L = R60_Vega_L + 12;
    RailFwd_L = (R60_Vega_Window_Z1 - R60_Vega_Rail_FwdClear) - (R60_Vega_AxialCenter + L/2);
    RailAft_L = (R60_Vega_AxialCenter - L/2) - (R60_Vega_Window_Z0 + R60_Vega_Rail_AftClear);
    Y0 = -L/2 - RailAft_L;   // rail's own aft tip -- rod enters here
    Y1 = L/2 + RailFwd_L;    // rail's own fwd tip -- rod continues past
                               // this into the fwd bulkhead's own insert
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
                               Travel=0, Engage=(Y1-Y0)+R60_Vega_RodInsert_h);
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
module NutSweep_Sled(){
    L = R60_Vega_L + 12;
    RailAft_L = (R60_Vega_AxialCenter - L/2) - (R60_Vega_Window_Z0 + R60_Vega_Rail_AftClear);
    Y0 = -L/2 - RailAft_L;   // rail's own aft tip = nut's seated position
    for (s=[-1,1])
        translate([s*R60_Vega_Rail_X, Y0, R60_Vega_Rail_Z_Local])
            rotate([-90,0,0])
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
// never inside a tube. Head bears on the retainer's own exposed aft
// face (local z=0); shank continues through the retainer's own T(6)
// into the fin can's own insert (6.7mm engagement) -- Engage=12.7.
module RetainerBoltSweep(){
    for (i=[0:R60_nFins-1])
        rotate([0,0,i*360/R60_nFins + 180/R60_nFins])
            translate([24,0,0])
                FastenerSweep(Shank_d=3.4, Head_d=5.5, Travel=20, Engage=12.7);
}
module Pair30_A(){ RetainerBoltSweep(); }
module Pair30_B(){ R60_MotorRetainer(); }

// Pair 31: tether latch mounting bolts (2x M3, R60_TetherLatch()'s own
// Mount_Hole_d pattern into R60_EBayAftBulkhead()'s inserts). ACCESS:
// this bulkhead's TRUE aft face (bulkhead z=Total_H=27) is fully exposed
// on the bench at assembly step 4 -- servos/latch are mounted well
// before the e-bay is closed up, let alone before the chute tube/spring
// carrier are bonded over this same face at step 9. Checked against the
// BULKHEAD only, so Engage is that part's own insert depth (6.7mm) --
// NOT stacked with the latch's own Base_T(4mm), which is a hole through
// a DIFFERENT part (R60_TetherLatch() itself) this pair does not render;
// a first version double-counted that 4mm as if the bulkhead needed
// clearance for it too, and got a real (if self-inflicted) 0.073cm3
// collision against the bulkhead's own solid disc material beyond its
// insert's true 6.7mm depth. The
// bulkhead's own material lies BELOW this seat (bulkhead z=27 down to
// 20.3, not upward -- Total_H=27 is this part's own aft-most extent), so
// FastenerSweep's default +Z convention needs flipping here.
// rotate([0,180,0]) is safe on this specific shape (unlike the mirror
// bug this same review round fixed elsewhere, 7th review finding 5):
// FastenerSweep is two coaxial cylinders with no off-axis feature, so a
// 180deg rotation about ANY axis in its own XY plane is a real,
// non-chiral symmetry of the shape itself, not an approximation of one.
module TetherBoltSweep(){
    for (x=[-R60_TetherLatch_HoleX, R60_TetherLatch_HoleX])
        translate([x, R60_Tether_Y, 12+R60_Pin_Skirt_L])
            rotate([0,180,0])
                FastenerSweep(Shank_d=3.4, Head_d=5.5, Travel=20, Engage=6.7);
}
module Pair31_A(){ TetherBoltSweep(); }
module Pair31_B(){ R60_EBayAftBulkhead(); }

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
KNOWN_PAIRS = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,17,19,21,22,23,24,
               25,26,27,28,29,30,31,32];
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
if (Pair==6) intersection(){ Pair6_A(); Pair6_B(); }
if (Pair==7) intersection(){ Pair7_A(); Pair7_B(); }
if (Pair==8) intersection(){ Pair8_A(); Pair8_B(); }
if (Pair==9) intersection(){ Pair9_A(); Pair9_B(); }
if (Pair==10) intersection(){ Pair10_A(); Pair10_B(); }
if (Pair==11) intersection(){ Pair11_A(); Pair11_B(); }
if (Pair==12) intersection(){ Pair12_A(); Pair12_B(); }
if (Pair==13) intersection(){ Pair13_A(); Pair13_B(); }
if (Pair==14) intersection(){ Pair14_A(); Pair14_B(); }
if (Pair==15) intersection(){ Pair15_A(); Pair15_B(); }
if (Pair==17) intersection(){ Pair17_A(); Pair17_B(); }
if (Pair==19) intersection(){ Pair19_A(); Pair19_B(); }
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
if (Pair==31) intersection(){ Pair31_A(); Pair31_B(); }
if (Pair==32) intersection(){ Pair32_A(); Pair32_B(); }
