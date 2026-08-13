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
Body_OD  = M_OD - IDXtra;         // slip fit in a 29mm motor tube
Cavity_d = Body_OD - 2*Wall;
// Closed at the AFT end only. Sealing both ends makes an enclosed void:
// the ballast cannot go in, and the render reports genus -1 (two surface
// components) rather than 1 - which is how the first version was caught.
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
// Prints aft-end down, no supports: the cavity is a plain bore and the
// open forward end needs no bridging. Tape or a printed plug retains the
// ballast - deliberately not a screw thread, so you can change the fill
// between the loaded and burnout tests without tools.
module MotorDummy(){
    difference(){
        cylinder(d=Body_OD, h=M_L);
        translate([0,0,End_T])
            cylinder(d=Cavity_d, h=Cavity_L + Overlap);   // opens at the top
        // Grip flats so it can be pulled back out of the motor tube.
        for (a=[0,180])
            rotate([0,0,a]) translate([Body_OD/2-0.6, -4, M_L-8])
                cube([2, 8, 8+Overlap]);
    }
} // MotorDummy

MotorDummy();
