// ***********************************
// Project: 3D Printed Rocket
// Filename: MotorDummy29.scad
// Mass-equivalent inert motors, 29mm
// by Tõnu Samuel
// Created: 2026-08-13
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Inert stand-ins matching a real motor's envelope AND its mass, so the
// recovery system can be exercised on the ground with the rocket loaded
// the way it actually flies.
//
// Why mass-equivalent and not just a plug: a 128g motor sits 480mm aft of
// the nose and is the single largest mass in the airframe. Swing-testing
// or drop-testing without it measures a different rocket. Ejection and
// separation tests done with an empty motor tube let the aft section move
// far too easily.
//
// The shell is printed light and the mass is made up with loose ballast in
// the cavity, so ONE print covers both the loaded and burnout cases: fill
// to the loaded figure, test, then pour some out to the burnout figure and
// test again. That second case matters - burnout is when the deployment
// actually happens.
//
// Echoes tell you the exact ballast mass to add. Weigh the printed shell
// first; the echo assumes the density below and your printer will differ.
//
// CG: the real motor's CG is not published, and a uniformly-filled dummy
// puts it at mid-length. Good enough for separation and fit testing; if
// you need CG fidelity for a swing test, bias the ballast aft and say so
// in your notes rather than trusting this part.
//
//  ***** History *****
//
function MotorDummy29_Rev()="MotorDummy29 0.1.0";
echo(MotorDummy29_Rev());
// 0.1.0  2026-08-13  First code.

Overlap = 0.05;
IDXtra  = 0.2;
$fn = $preview ? 36 : 180;

// ============================================
// MOTOR SELECTION
// ============================================
// 0 = AeroTech G80T-14A   29 x 124mm, 128g loaded, 63g propellant
// 1 = AeroTech H182R-14A  29 x 203mm, 207g loaded, 115g propellant
// 2 = AeroTech H135W-14A  29 x 216mm, 212g loaded,  82g propellant
// Figures from thrustcurve.org.
Motor_Class = 0;

// [OD, length, loaded mass g, propellant mass g]
Motor_Data = [[29, 124, 128, 63],
              [29, 203, 207, 115],
              [29, 216, 212,  82]];

Filament_Density = 1.27;   // g/cm3. PETG. PC is 1.20, PLA 1.24.

// ============================================
// DERIVED
// ============================================
M_OD   = Motor_Data[Motor_Class][0];
M_L    = Motor_Data[Motor_Class][1];
M_Wet  = Motor_Data[Motor_Class][2];
M_Prop = Motor_Data[Motor_Class][3];
M_Dry  = M_Wet - M_Prop;

Wall     = 2.0;
End_T    = 3.0;
// M_OD (29mm nominal, all 3 classes -- the AeroTech 29mm motor family) is
// the SAME real-world motor OD Rocket60.scad's own design derives from:
// R60Lib.scad's R60_MMT_ID ("R60_MMT_ID = 29.0 + 0.3; // 29mm motor, slip
// fit") and tools/r60_assembly.scad's Pair 11, which stands in for the
// motor directly (`cylinder(d=29.0, ...)`, "the real motor case's own
// known OD"). This file is deliberately standalone (no include<> of
// R60Lib.scad -- a mass-equivalent dummy is useful outside this specific
// rocket too), so that agreement is NOT enforced by any shared constant;
// if the assumed motor OD ever needs correcting, update Motor_Data here
// AND both of those references by hand (6th review, finding 4 -- flagged
// as an unexplained disagreement, 28.8 vs 29.0, between this and Pair
// 11's own stand-in for "the same object"). Body_OD below is NOT that
// same 29.0mm figure: it is THIS PRINTED PART's own reduced-for-slip-fit
// OD (M_OD-IDXtra), deliberately smaller so a dummy that gets repeatedly
// inserted and withdrawn for ground testing never jams -- a real motor
// (and Pair 11's own stand-in for one) is not print-fit-reduced and
// stays at the full 29.0mm.
Body_OD  = M_OD - IDXtra;         // slip fit in a 29mm motor tube
Cavity_d = Body_OD - 2*Wall;
// Closed at the FORWARD end only (3rd review, defect 10 -- was labelled
// "AFT" here and printed/loaded accordingly, which put the ballast port
// and the grip flats below at the BURIED end instead of the reachable
// one; see the module comment below for the full reasoning). Sealing
// BOTH ends instead (the pre-fix defect) makes an enclosed void: the
// ballast cannot go in, and the render reports genus -1 (two disjoint
// closed surfaces -- the outer shell and the sealed cavity -- combine to
// a negative value under OpenSCAD's own Euler-characteristic formula),
// which is how the first version was caught. A one-end-open cup (this,
// the fixed design) is genus 0, not genus 1 as this comment previously
// (and wrongly) claimed -- confirmed on the rendered mesh, all 3 motor
// classes (6th review, finding 4; tools/verify_motordummy29.py).
Cavity_L = M_L - End_T;

// Solid shell volume in mm3, then cm3.
Shell_mm3 = PI*pow(Body_OD/2,2)*M_L - PI*pow(Cavity_d/2,2)*Cavity_L;
Shell_cm3 = Shell_mm3/1000;
Shell_g   = Shell_cm3 * Filament_Density;
Cavity_cm3 = PI*pow(Cavity_d/2,2)*Cavity_L/1000;

echo(str("motor            : class ", Motor_Class, "  ", M_OD, " x ", M_L, "mm"));
echo(str("shell (100% fill): ", Shell_cm3, " cm3 = ", Shell_g, " g"));
echo(str("cavity           : ", Cavity_cm3, " cm3"));
echo(str("BALLAST, loaded  : ", M_Wet - Shell_g, " g   (total ", M_Wet, " g)"));
echo(str("BALLAST, burnout : ", M_Dry - Shell_g, " g   (total ", M_Dry, " g)"));
echo(str("ballast density needed, loaded: ",
         (M_Wet - Shell_g)/Cavity_cm3, " g/cm3"));
// Sand ~1.5, steel shot ~4.5, lead shot ~6.5 g/cm3 loose-packed. If the
// figure above exceeds ~4 the cavity is too small for anything but lead.

// ============================================
// PART
// ============================================
// Prints forward-end down, no supports: the cavity is a plain bore and
// the open aft end needs no bridging. Tape or a printed plug retains the
// ballast - deliberately not a screw thread, so you can change the fill
// between the loaded and burnout tests without tools.
//
// Grip flats and fill opening are at the AFT end (3rd review, defect
// 10 -- the pre-fix part had both at the open end, which this file
// mislabelled "forward"). A real motor loads forward-closure-first:
// that closed end leads the insertion and ends up
// buried against the thrust ring, ~104mm+ deep for the G80T; the
// nozzle end trails and stays at the tube's aft opening, reachable,
// where the retainer clips on. A mass-equivalent dummy has to load the
// same way for the ground test to mean anything, so its own closed end
// (below, z=0) is the FORWARD end -- correctly buried and inert -- and
// its open end (grip flats + ballast port, z=M_L) is the AFT end,
// staying at the tube's mouth where you can actually reach it to pull
// the dummy back out or change the ballast. The pre-fix version called
// the closed end "aft" and the open end "forward", which is backwards:
// following those labels at insertion buries the ballast port and grip
// flats 104mm+ into the tube, unreachable once loaded.
module MotorDummy(){
    difference(){
        cylinder(d=Body_OD, h=M_L);
        translate([0,0,End_T])
            cylinder(d=Cavity_d, h=Cavity_L + Overlap);   // opens at the top (aft)
        // Grip flats so it can be pulled back out of the motor tube.
        for (a=[0,180])
            rotate([0,0,a]) translate([Body_OD/2-0.6, -4, M_L-8])
                cube([2, 8, 8+Overlap]);
    }
} // MotorDummy

MotorDummy();
