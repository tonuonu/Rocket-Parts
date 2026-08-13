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

R60_EBay_L   = 160;   // fits Vega 100 + upright MG90S 29 + slack
R60_Chute_L  = 180;   // spring mechanism 80 + 24in main 100
R60_FinCan_L = 228;

// Neck skirt length -- shared with R60_EBayTube() so the arming switch
// hole can be positioned clear of it by construction instead of a
// hand-picked Z that can silently start overlapping it again. See task
// report (the switch used to land inside this skirt's own span).
R60_Neck_Skirt_L = 19;

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
// the tube axis; 2 zip-tie slots straddling its mid-length stop axial
// sliding and hold it down against the rails.
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
R60_TetherInsert_d    = 4.0;   // ruthex RX-M3x5.7 hole, tether latch mount
R60_Tether_Wall_Min   = 2.0;   // min solid wall around the insert hole,
                                // clear of the horn slot void
R60_TetherLatch_HoleX = R60_Horn_L/2 + R60_TetherInsert_d/2 + R60_Tether_Wall_Min;  // 16

// ============================================
// FINS
// ============================================
R60_Fin_Root  = 90;
R60_Fin_Tip   = 35;
R60_Fin_Span  = 55;
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
