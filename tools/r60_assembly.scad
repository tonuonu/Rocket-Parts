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
//   (Pairs 3 and 21) -- MEASURED off part 2's own rendered rails by the
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
// Two further checks (15, 17-19) are NOT part-vs-part pairs at all -- they
// assert a DECLARED MOVING ELEMENT's required path is not obstructed by
// any real part (harness item 3), which no static dimension check or the
// pairs above can express. Pairs 16/20/21 ARE part-vs-part (the switch
// and board are now real, if unmodelled-in-detail, hardware appendages of
// real parts, not abstract paths), but are grouped here since they arose
// from the same "model what's actually there, not what a dimension check
// alone can see" instruction:
// 15  servo-2-horn/pin-release actuation path vs. tether latch(13) --
//     finding 5.
// 16  fitted arming switch's own envelope (in the door, part 7) vs. e-bay
//     tube(2) -- finding 1, harness item 4 ("model the fitted switch").
// 20  same switch envelope vs. Vega sled(6) -- another part it could
//     reach once installed.
// 21  Vega BOARD's own envelope (not modelled by Pair 3's sled-only probe)
//     vs. e-bay tube(2) -- finding 2.
// 22  same switch envelope vs. the Vega BOARD's own envelope (pair 21's
//     BoardProbe) -- the board's own Z span overlaps the door's aperture
//     by construction, so this is a real reach, not a hypothetical one.
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

// Pairs 16/20/22: arming switch's own physical envelope (5th review,
// finding 1: now fitted IN the access door, part 7, not the tube) vs.
// every part it could reach once installed -- harness item 4 ("model the
// fitted switch"), extended per finding 1's own instruction ("add an
// assembly-probe pair for the fitted switch against every part it could
// reach") now that the switch is a real appendage of a real part rather
// than a hole in one. Checking it against the door it is CUT INTO would
// prove nothing (a probe built from the same cut it stands in for is
// tautologically clear); the parts/hardware actually reachable from the
// door's own crown position, aimed inward into the open bore, are the
// e-bay tube itself (whatever is NOT open aperture there -- the door
// bosses, the tube wall either side of the opening), the Vega sled on the
// far (-Y) wall, and the Vega BOARD (Pair 22, using the SAME BoardProbe
// Pair 21 uses below) -- the board's own Z span (its full R60_Vega_L,
// centred the same as the sled) overlaps the door's own aperture Z range
// by construction, so a switch reaching far enough inward can hit the
// board even though it clears the thin sled itself (Pair 20) with room to
// spare; this was caught DURING this fix, not assumed clear (a first
// draft's SW_REACH=15 read a genuine 0.538cm^3 collision against
// BoardProbe before SW_REACH was derived against it below).
//
// SwitchProbe is a PROBE-ONLY solid standing in for the installed switch
// hardware: SW_D matches R60_Door()'s own Sw_d exactly (rule 4); SW_REACH
// is DERIVED (not a free hand-picked number) as the largest reach that
// still clears the board's own inner face (R60_Vega_Board_Inner_Y,
// R60Lib.scad) by a stated minimum -- no datasheet exists for the actual
// switch part, so "as deep as the installation allows, not deeper" is the
// honest envelope, same "unmodelled companion hardware" treatment as
// R60_SpringCarrier()'s plunger/lock ring. Built directly in the DOOR's
// own local frame (matching R60_Door()'s own Sw_X/Sw_Z exactly), so it
// drops into the SAME Pair4/Pair16-style door-placement transform below.
SW_D = 12.0;        // R60_Door()'s own Sw_d, restated (rule 4)
SW_REACH_Clear = 2.0;   // stated minimum clearance to the board's own face
SW_REACH = R60_Body_OD/2 - R60_Vega_Board_Inner_Y - SW_REACH_Clear;  // ~8.24
SW_X = 0;           // R60_Door()'s own Sw_X -- the cover's own crown
SW_Z = R60_Door_Overlap + R60_Door_Open_H/2;   // R60_Door()'s own Sw_Z, 48.5
module SwitchProbe(){
    translate([0, R60_Body_OD/2, SW_Z])
        rotate([90,0,0])
            cylinder(d=SW_D, h=SW_REACH);
}
module Pair16_A(){ translate([0,0,Door_Z0_ - R60_Door_Overlap]) SwitchProbe(); }
module Pair16_B(){ R60_EBayTube(); }
module Pair20_A(){ translate([0,0,Door_Z0_ - R60_Door_Overlap]) SwitchProbe(); }
module Pair20_B(){ R60_VegaSled(); }

// Pair 21: Vega BOARD's own envelope (5th review, finding 2) vs. e-bay
// tube (part 7's door bosses live in part 2, R60_EBayTube()). Pair 3
// above only ever modelled the SLED (part 6) -- the real collision
// finding 2 found was between the door bosses and the BOARD, which sits
// on TOP of the sled and was never rendered anywhere in this harness.
// BoardProbe is a PROBE-ONLY solid: the board's own footprint
// (R60_Vega_L x R60_Vega_W x R60_Vega_H, no mounting/standoff detail --
// none of that is load-bearing for a clearance check), positioned the
// SAME way Pair 3 positions the sled (Facing_Y, the rails' own measured
// contact surface) plus the stack height (sled T+Standoff_h+Vega_H) that
// sits between the rails and the board's own inner face.
module BoardProbe(){
    translate([0, Facing_Y + (R60_Vega_Sled_T+R60_Vega_Standoff_h), R60_EBay_L/2])
        rotate([-90,0,0])
            translate([-R60_Vega_W/2, -R60_Vega_L/2, 0])
                cube([R60_Vega_W, R60_Vega_L, R60_Vega_H]);
}
module Pair21_A(){ BoardProbe(); }
module Pair21_B(){ R60_EBayTube(); }
// Pair 22: fitted arming switch envelope vs. the Vega BOARD itself --
// see the Pairs 16/20/22 comment above for why this is a real, not
// hypothetical, risk despite the board not being a printed part.
module Pair22_A(){ translate([0,0,Door_Z0_ - R60_Door_Overlap]) SwitchProbe(); }
module Pair22_B(){ BoardProbe(); }

// Pairs 17-19: tether latch PIN withdrawal path vs. every real part
// around it once assembled -- coordinator override (same review round).
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
// vs. e-bay aft bulkhead -- same frame as Pair9.
module Pair18_A(){ translate([0,R60_Tether_Y,12+R60_Pin_Skirt_L]) PinPath(); }
module Pair18_B(){ R60_EBayAftBulkhead(); }
// vs. chute tube, at full seating -- same frame as Pair13 (Ins=80 default).
module Pair19_A(){ translate([0,R60_Tether_Y,Ins-65]) PinPath(); }
module Pair19_B(){ R60_ChuteTube(); }

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
if (Pair==16) intersection(){ Pair16_A(); Pair16_B(); }
if (Pair==17) intersection(){ Pair17_A(); Pair17_B(); }
if (Pair==18) intersection(){ Pair18_A(); Pair18_B(); }
if (Pair==19) intersection(){ Pair19_A(); Pair19_B(); }
if (Pair==20) intersection(){ Pair20_A(); Pair20_B(); }
if (Pair==21) intersection(){ Pair21_A(); Pair21_B(); }
if (Pair==22) intersection(){ Pair22_A(); Pair22_B(); }
