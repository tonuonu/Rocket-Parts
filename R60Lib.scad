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

// ============================================
// MOTOR
// ============================================
R60_MMT_ID  = 29.0 + 0.3;   // 29mm motor, slip fit
R60_MMT_OD  = R60_MMT_ID + 3.0;
R60_MMT_L   = 223;          // takes the 216mm H135W, the longest 29mm H DMS
R60_Motor_L = [124, 203, 216];  // G80T-14A, H182R-14A, H135W-14A

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
