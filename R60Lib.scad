// ***********************************
// Project: 3D Printed Rocket
// Filename: R60Lib.scad
// for Rocket 60 (60mm body, camera nosecone)
// by Tõnu Samuel
// Created: 2026-08-13
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Shared constants and modules for the 60mm camera rocket. No printable
// part lives here - see Rocket60.scad.
//
// The airframe OD is NOT a design choice. It is the measured base
// diameter of the user's "Nose Cone.STEP", which cannot be modified.
//
//  ***** History *****
//
function R60Lib_Rev()="R60Lib 0.1.0";
echo(R60Lib_Rev());
// 0.1.0  2026-08-13  First code.

Overlap = 0.05;
IDXtra  = 0.2;
$fn = $preview ? 36 : 180;

// ============================================
// AIRFRAME
// ============================================
R60_Body_OD    = 60.0;
R60_Wall_T     = 1.6;
R60_Body_ID    = R60_Body_OD - 2*R60_Wall_T;   // 56.8
// 0.4mm diametral clearance, same convention as PeregrineNoseCone.scad.
// Derived, so a wall-thickness change can never silently produce an
// interference fit here.
R60_Coupler_OD = R60_Body_ID - 0.4;            // 56.4

// R60_EBay_L (4th review, critical 3): grew again, 165->177. The 3rd
// review grew this 160->165 to give the arming-switch Z window "a
// genuine ~3mm margin on both sides" -- but that derivation (see
// R60_EBayTube()'s Sw_Z0, below) measured clearance from the door
// APERTURE's own top edge (Door_Z1), not from R60_Door()'s actual built
// footprint, which overlaps R60_Door_Overlap=6mm PAST the aperture on
// every side (it is a COVER, not a flush plug -- see R60_Door()'s own
// module comment). So the real clearance was 6mm less than intended:
// at L=165 the switch hole's own near edge landed 1.5mm INSIDE the
// door cover's own footprint (measured: cover z=34..131, switch
// z=129.50..131.00, 16.3mm^3 overlap) -- a hair-gap bug reintroduced by
// the very fix that thought it had closed the 3rd review's 0.5mm-window
// defect. Window width W (Sw_Z_max-Sw_Z_min, correctly counting
// R60_Door_Overlap this time) = 0.5*R60_EBay_L - 85.5; solving W=3 (the
// SAME ~3mm target the 3rd review intended) for the correctly-derived
// formula gives L=177 -- restated here as a literal because R60Lib.scad
// cannot reference R60_Door_Open_H/R60_Neck_Skirt_L/R60_Door_Overlap in
// a closed form without becoming circular; R60_EBayTube()'s own assert
// is the load-bearing guard, this comment only documents where 177 came
// from. See tools/verify_rocket60.py's SW_Z_EXPECT for the same
// derivation restated as a check.
R60_EBay_L   = 177;   // fits Vega 100 + upright MG90S 29 + slack, +17mm
                       // over the bare minimum so the arming-switch Z
                       // window is a genuine ~3mm margin on both sides
                       // of the door COVER's real footprint (not just
                       // the aperture) and of the neck skirt
R60_Chute_L  = 180;   // spring mechanism 80 + 24in main 100
R60_FinCan_L = 228;

// Chute-bay-to-fin-can spigot (3rd review, should-fix 6). Every OTHER
// internal airframe joint in this design gets a Ø56.4 (R60_Coupler_OD)
// spigot locating it concentrically and giving it something more than a
// glue ring to resist bending -- the neck's skirt into the e-bay tube,
// the e-bay aft bulkhead's skirt into the chute tube -- except this one,
// which used to be a bare butt bond between two 1.6mm walls across a
// 662mm airframe. Built onto the chute tube's own aft end, PAST its
// existing R60_Chute_L (not into R60_FinCan() -- that part's own forward
// annulus is already open and unmodified, so nothing there needs to
// change).
//
// R60_FinCan_FwdOpen_L (4th review, should-fix 8): the fin can's own
// forward centring ring sits this far from the tube's own forward tip
// (R60_FinCan()'s ring-Z loop), so this is exactly how much open annulus
// is actually free to receive a spigot there. Shared, not restated,
// so the two can never independently drift the way they did before this
// fix: R60_FinCanSpigot_L used to be a SECOND, independently-typed "6"
// that happened to equal this figure exactly -- a bare tangency, zero
// axial clearance, so the spigot bottomed on the ring before the
// airframe's own outer OD faces could close flush (the review's own
// pair-7 probe read 0cm3 for this reason: not a clear fit, a touching
// one). R60_FinCanSpigot_Clear states the axial clearance explicitly,
// same "derived minimum, not hand-matched" idiom as R60_Tether_Clear.
R60_FinCan_FwdOpen_L   = 6;
R60_FinCanSpigot_Clear = 0.5;   // stated axial print-tolerance clearance
R60_FinCanSpigot_L = R60_FinCan_FwdOpen_L - R60_FinCanSpigot_Clear;   // 5.5

// Neck skirt length -- shared with R60_EBayTube() so the arming switch
// hole can be positioned clear of it by construction instead of a
// hand-picked Z that can silently start overlapping it again. See task
// report (the switch used to land inside this skirt's own span).
R60_Neck_Skirt_L = 19;

// E-bay aft bulkhead disc thickness (R60_EBayAftBulkhead()'s own T) --
// shared with R60_EBayTube() (3rd review, defect 2) so the Vega
// retention rails can be kept clear of the disc BY CONSTRUCTION, the
// same treatment R60_Neck_Skirt_L above already gets for the skirt end.
// Was a second, local-only `T=12` inside R60_EBayAftBulkhead() with
// nothing else deriving from it -- the rails' own Z window had no way to
// know where the disc actually sits, and silently overlapped it.
R60_AftBulk_T = 12;
// E-bay forward bulkhead disc thickness (R60_EBayFwdBulkhead()'s own T)
// -- shared for the same reason as R60_AftBulk_T above: the rails must
// also clear this bulkhead, which sits immediately below the neck skirt.
R60_FwdBulk_T = 6;

// Access door aperture (R60_EBayTube()) and the retaining frame/bosses on
// R60_Door() that mate with it -- shared so the two are always derived
// from the same opening, never two hand-typed numbers. See task report:
// the door used to be a bare plug with 0.35mm of play and nothing to stop
// it falling through, and nothing behind its screw holes but open air.
R60_Door_Open_W  = 36;    // aperture width, X
R60_Door_Open_H  = 85;    // aperture height, Z
R60_Door_Overlap = 6;     // the door's retaining cover/frame overlaps
                           // solid tube material by this much all around
R60_Door_Hole_Clear = 3;  // fastener bosses sit this far outside the
                           // aperture's own edge, on solid material

// ============================================
// NOSECONE INTERFACE - MEASURED, DO NOT ROUND
// ============================================
// Taken from "Nose Cone.STEP" with FreeCAD planar sections. The STEP is
// authored in a parent-assembly frame with the base plane at Y=501.95;
// these are restated as height above that plane.
R60_NC_Base_OD  = 59.98;   // outer diameter at the base plane
R60_NC_Base_ID  = 54.25;   // base annulus bore
R60_NC_Bore_Low = 53.25;   // bore 0.5..1.5mm above the base
R60_NC_Bore_Gen = 55.60;   // bore higher up

// ============================================
// CAMERA INTERFACE - MEASURED, DO NOT ROUND
// ============================================
// From ~/Camera.STEP. Three M3 heat-set inserts (ruthex RX-M3x5.7) on one
// circle. The angles are deliberately NOT 120deg apart - the asymmetry
// keys the camera's clocking, so preserve them exactly.
R60_Cam_BC_R    = 18.98;                  // bolt circle RADIUS
R60_Cam_Ang     = [52.2, -52.2, 180.0];
R60_Cam_Bolt_d  = 3.4;                    // M3 clearance

// ============================================
// CATS VEGA  (manual v2.0.0 sec 4.3.3)
// ============================================
// Manual says 15mm total height, catsystems.io says 21mm. Cut for 21.
R60_Vega_L = 100;
R60_Vega_W = 33;
R60_Vega_H = 21;
// L-shaped M3 pattern, 60mm apart along the length, 27mm across the width.
// X = across width, Y = along length.
R60_Vega_Holes = [[-13.5, -25], [-13.5, +35], [+13.5, +35]];
R60_Vega_Standoff_h = 4;   // manual recommends spacers under the board
R60_Vega_Sled_W = R60_Vega_W + 11;   // sled plate width (chord), matches
                                       // R60_VegaSled()'s own W
R60_Vega_Sled_T = 4;                  // sled plate thickness

// Sled retention (R60_EBayTube()/R60_VegaSled(), task report): the sled
// had nothing holding it in place and was free to slide and rotate. 2
// rails run the tube's full length at the -Y wall (opposite the door and
// switch, both at +Y, so neither competes for space), capturing the
// sled's two long edges so it can neither slide radially nor rotate about
// the tube axis; 4 zip-tie slots (2 Z stations, one pair of holes per
// station at 270+-Rail_HalfAng -- straddling the sled TANGENTIALLY, not
// sharing an azimuth -- 3rd review, defect 11) let 2 ties cinch it down
// against the rails and stop axial sliding.
R60_Vega_RailGap = R60_Vega_Sled_W + 2*IDXtra;   // inner-to-inner rail
                                                   // spacing = sled width
                                                   // + clearance
R60_Vega_RailW   = 3;     // rail width, X
R60_Vega_RailH   = R60_Vega_Sled_T + 2*IDXtra;    // radial height, clears
                                                    // the sled's thickness

// ============================================
// MOTOR
// ============================================
R60_MMT_ID  = 29.0 + 0.3;   // 29mm motor, slip fit
R60_MMT_OD  = R60_MMT_ID + 3.0;
// R60_FinCan() builds the MMT the fin can's own full length (R60_FinCan_L)
// -- derive this from that SAME constant, not a second, independently
// hardcoded number. It used to be a separately typed 223 (5mm short of
// the fin can's actual 228mm build depth): R60_MotorSpacer() then sized a
// spacer 5mm too short, so a motor+spacer stack never reached the
// retainer lip and the motor could slam 5mm aft on ejection. See task
// report.
R60_MMT_L   = R60_FinCan_L;
R60_Motor_L = [124, 203, 216];  // G80T-14A, H182R-14A, H135W-14A

// Motor-catching lip bore -- shared between R60_MotorRetainer() (aft,
// catches the motor's own aft rim, resisting AFT motion) and
// R60_ThrustRing() (forward, part 14, 3rd review defect 3: catches the
// motor+spacer stack's forward face, resisting FORWARD motion -- nothing
// did before this, so the ~66N forward thrust reaction on a G80T-14A had
// only a 0.3mm slip fit standing between the motor+spacer stack and the
// packed parachute). Same lip width both ends, one derived constant.
R60_Motor_Lip_d = R60_MMT_ID - 2.5;
// R60_ThrustRing()'s own thickness -- shared with R60_MotorSpacer() so
// the spacer's length is derived knowing the ring now occupies the last
// R60_ThrustRing_T of the MMT's own R60_MMT_L, not a second part sized
// as if it had the whole length to itself (which would make the ring
// and the spacer's forward end occupy the same 6mm and collide -- caught
// on the rendered assembly, tools/verify_rocket60_assembly.py pair 10,
// before this was wired through).
R60_ThrustRing_T = 6;

// ============================================
// SPRING SEPARATION JOINT (spec 4.2 -- supersedes the cam-ramped bayonet)
// ============================================
// CS4323 compression spring dimensions, as documented in the repo's
// SpringThingBooster.scad/SpringEndsLib.scad family (ST_DSpring_OD/ID,
// ST_DSpring_CBL/FL) and restated here since Rocket60.scad does not
// `use<>` those files -- see R60_SpringCarrier()'s module comment for why.
R60_Spring_OD  = 44.30;
R60_Spring_ID  = 40.50;
R60_Spring_FL  = 200;    // free length
R60_Spring_CBL = 22;     // coil-bound length

// Shear pins bridge the REAL separable airframe joint -- chute bay tube
// (part 3) into the e-bay aft bulkhead's skirt (part 5) -- not the spring
// carrier. See R60_EBayAftBulkhead()'s module comment for why that
// placement is what keeps the two separation paths independent.
//
// Target: 2x nylon 2-56, ~130N combined shear (spec 4.2). NO spring force
// figure exists anywhere in this repo (grep of all nine spring/release
// files found none) -- this pin size is a stated target, not a verified
// one. The spring must be bench-measured to confirm it beats this load
// before flight (spec A11 -- the largest open risk in the recovery
// system). Do not treat PIN_D as validated by anything in this file.
R60_Pin_d            = 2.2;   // nylon 2-56 clearance
R60_Pin_Skirt_L      = 15;    // e-bay aft bulkhead's aft skirt engagement
R60_Pin_Z_FromJoint  = 8;     // both R60_ChuteTube() and R60_EBayAftBulkhead()
                               // cut their pin hole this far from the joint,
                               // so one physical pin lines up through both

// Tether latch (part 13, Task 8) routing. Shared between R60_ChuteTube()
// (the fixed tie-off at the chute bay's forward rim), R60_EBayAftBulkhead()
// (the latch's own mount, offset under servo 2's horn so it can drive it,
// plus a relief channel through the skirt) and R60_SpringCarrier() (a
// matching notch through its counterbore rim), so the tether's ~50mm cord
// path lines up across all three once assembled -- see each module's
// comment. This is a SEPARATE line from the shock cord (which is
// permanently anchored e-bay aft bulkhead <-> fin can forward centring
// ring, spec 4.1) -- conflating the two leaves the aft section attached
// to nothing after main release.
R60_Tether_Y  = 13.6;   // = S2_Y, so servo 2's horn can reach the latch
R60_Tether_Az = 90;     // +Y -- azimuth of the relief channel/tie-off

// Tether tie-off lug (R60_ChuteTube(), part 3) and the relief notch that
// must swallow it through the aft bulkhead skirt (part 5, which the chute
// tube's forward rim slides over). Defined once, here, so the notch is
// always DERIVED from the lug's own footprint plus a stated clearance --
// not a hand-matched dimension that can silently drift out of sync (a
// first draft sized the notch to exactly the lug's own dimensions: zero
// clearance on width and 0.8mm of outright interference on depth. See
// task report).
R60_TetherLug_W  = 8;     // lug width, X
R60_TetherLug_D  = 4;     // lug radial depth, Y -- how far it reaches
                           // inward from the chute tube's own ID
R60_TetherLug_H  = 5;     // lug height, Z
R60_TetherLug_Z  = 4;     // lug Z position (base), in the chute tube's
                           // own frame
R60_Tether_Clear = 0.6;   // stated per-side clearance: the notch is cut
                           // this much deeper (radius) and this much wider
                           // (each side) than the lug's own footprint

// Tether latch (part 13) mounting hole spacing. Servo 2's horn slot
// (R60_Horn_L, R60_EBayAftBulkhead()) is shared here so the latch's own
// mounting holes and the bulkhead's insert holes it screws into are always
// derived from the SAME slot dimension, and so they can never again land
// inside its void -- see task report: the original +-11mm spacing put
// both mounting inserts inside the horn slot (only ~2.5mm^2 of a 12.6mm^2
// bore was solid).
R60_Horn_L            = 24;    // servo 2 horn slot length, X
R60_Horn_W            = 9;     // servo 2 horn slot width, Y -- shared for
                                // the same reason R60_Horn_L is: 4th
                                // review, critical 5, needs it to size the
                                // pass-through R60_TetherLatch() now cuts
                                // through its own base (see that module's
                                // comment) so it never again matches the
                                // bulkhead's own slot width by coincidence
R60_TetherInsert_d    = 4.0;   // ruthex RX-M3x5.7 hole, tether latch mount
R60_Tether_Wall_Min   = 2.0;   // min solid wall around the insert hole,
                                // clear of the horn slot void
R60_TetherLatch_HoleX = R60_Horn_L/2 + R60_TetherInsert_d/2 + R60_Tether_Wall_Min;  // 16

// Spring carrier (part 8) counterbore diameter -- shared with
// R60_TetherLatch() (4th review, critical 2) so the latch can clip its
// own base to a radius that is guaranteed to stay inside it, DERIVED,
// rather than the two silently drifting the way R60_TetherLug_*/
// R60_Tether_Clear were introduced to prevent for the tether notch. Was
// a second, local-only `CB_D=51` inside R60_SpringCarrier() with nothing
// else deriving from it -- fine while the latch was assumed to fit
// inside it whole, which the module comment claimed ("the posts and pin
// recess into that counterbore") but never actually checked for the
// latch's own rectangular BASE, offset R60_Tether_Y off the carrier's
// axis so servo 2 can reach it. A round counterbore centred ON that axis
// can never fully clear an off-axis rectangle no matter how large --
// the base's own far corners (r=28.97mm from the carrier's axis) sit
// PAST the carrier's own OD (28.2mm), so growing CB_D cannot be the fix;
// R60_TetherLatch()'s own module comment explains the clip this drives.
R60_SpringCarrier_CB_D = 51;

// ============================================
// FINS
// ============================================
// Span grown 55 -> 63mm (task report, coordinator decision, group 2
// re-target): the buried root originally reported here was correct as a
// PLANFORM number, but tools/rocket60_model.py's Barrowman analysis had
// been counting all 55mm of it as EXPOSED span -- 14mm of it (D/2 -
// R60_MMT_OD/2) actually sits inside the fin can, under the epoxied
// joint, and contributes zero normal force. Fed the corrected EXPOSED
// geometry, the G80T-14A -- the motor actually owned, the sizing case
// per the coordinator's explicit re-target -- static margin was only
// 1.05 cal at liftoff. Root/tip/sweep/thickness are UNCHANGED: span is
// the most efficient lever per gram (CN scales with (exposed-span/D)^2,
// so growing span buys far more CP shift per gram added than growing
// chord -- see tools/rocket60_model.py's own sweep for the chord-only
// and Ct-trim alternatives that were rejected for costing more mass at
// the same margin). 63mm clears 1.5 cal on the G80T with margin to
// spare (1.61 cal) while flutter velocity -- a function of exposed AR,
// which RISES as span grows (span 55->AR 0.739->Vf 1220 m/s; 63->0.869
// ->959; 70->0.982->802 -- growing span 18% raised AR 18% and CUT Vf
// 21%, the opposite of a free lever) -- still stays comfortably above 3x
// the fastest flight speed on any motor at 63mm. This is a real cost,
// not a margin grown for free: do not read this as licence to keep
// growing span for stability headroom without re-checking Vf each time
// (R60_Fin()'s own module comment already says this; restated here so
// this comment does not contradict it) -- see
// tools/verify_rocket60.py's fin-span check (3rd review, should-fix 7)
// and the module comment on R60_Fin() for the current AR/flutter
// figures. Slot geometry in R60_FinCan() needs no
// width change: the slot already cuts clear through to the body OD
// (r=30) regardless of span, so only Slot_L (root chord, unchanged) sets
// its footprint -- span only changes how far the fin's OWN tip reaches
// past the airframe, which the slot cut (through the outer wall only,
// unbounded in the +Y direction of the cube) already accommodates.
R60_Fin_Root  = 90;
R60_Fin_Tip   = 35;
R60_Fin_Span  = 63;
R60_Fin_Sweep = 45;
R60_Fin_T     = 4.0;
R60_nFins     = 3;

// ============================================
// SHARED MODULES
// ============================================

// A plain airframe tube. Length along +Z, base at Z=0.
module R60_Tube(len, od=R60_Body_OD, wall=R60_Wall_T){
    difference(){
        cylinder(d=od, h=len);
        translate([0,0,-Overlap]) cylinder(d=od-2*wall, h=len+Overlap*2);
    }
} // R60_Tube

// Bolt pattern for the camera's three heat-set inserts. Children are
// placed at each hole, on the XY plane, oriented +Z.
module R60_CameraBoltPattern(){
    for (a=R60_Cam_Ang)
        rotate([0,0,a]) translate([R60_Cam_BC_R,0,0]) children();
} // R60_CameraBoltPattern
