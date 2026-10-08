// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineL3.scad
// by Tõnu Samuel
// Created: 10/8/2026
// Revision: 0.1.0  10/8/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Whole-rocket assembly view of the Peregrine L3 (L3-Design.md §4.2).
// For looking and rendering only - nothing here is printed.
//
// Real parts come from their own files:
//   PeregrineFinCan75.scad  fin can (FinCanAssembly)
//   PeregrineFin75.scad     fin core (PeregrineFin75)
// Tubes, e-bay, nose cone, motors and the 54 mm adapter are simple
// placeholders sized from L3-Design.md and L3-TestFlights.md.
//
// Z = 0 at the aft end of the retainer thread, rocket axis along +Z.
//
// Pick Render_Part and Motor below (or Customizer). Use F6 / --render
// for clean images: F5 preview shows the fin can's internal cutters
// through the main tube. Command-line example:
//   OPENSCADPATH=. openscad --backend=manifold --render \
//     -D Render_Part=1 -D Motor=3 --viewall --autocenter \
//     --camera=0,0,0,0,90,90,0 --projection=o --imgsize=2400,900 \
//     -o cutaway.png PeregrineL3.scad
//
//  ***** History *****
// 0.1.0  10/8/2026  First assembly view, selectable test motors
//
// ***********************************

use<PeregrineFinCan75.scad>
use<PeregrineFin75.scad>

// ========== RENDER ==========

Render_Part = 0;
// 0 = Full rocket
// 1 = Cutaway (half removed) - motor, adapter, nose shoulder visible
// 2 = Fin can + fins only

Motor = 0;
// 0 = AeroTech M1297W   RMS-75/5120  (L3 cert flight)
// 1 = AeroTech K1499N   RMS-75/1280  (test flight, no adapter)
// 2 = AeroTech J1299N   RMS-54/852   (test flight, 54 mm adapter)
// 3 = AeroTech K2050ST  RMS-54/1706  (test flight, 54 mm adapter)

// ========== DIMENSIONS ==========

// Shared with PeregrineFinCan75.scad / PeregrineFin75.scad
// (`use` does not import variables - keep these in sync)
Body_OD = 140.1;
Body_ID = 136.8;
MMT_OD = 76.0;
Thread_H = 15.875;
FinCan_Body_Len = 310;
FinCan_Coupler_Len = 35;
Fin_Count = 4;
Fin_Root_L = 249;
Fin_Tab_L = 240;
Fin_Slot_Start = Thread_H + 5;        // above aft centering ring
Fin_LE_Z = Fin_Slot_Start + Fin_Tab_L + 4;  // tab starts 4 mm aft of root LE

// Section lengths (L3-Design.md §4.2)
FinCan_Exposed_Z = Thread_H + FinCan_Body_Len - FinCan_Coupler_Len;
Main_Len = 500;
EBay_Len = 200;
Drogue_Len = 350;
Nose_L = 450;           // exposed ogive, ~3.2:1
Nose_Shoulder_L = 85;

Main_Z = FinCan_Exposed_Z;
EBay_Z = Main_Z + Main_Len;
Drogue_Z = EBay_Z + EBay_Len;
Nose_Z = Drogue_Z + Drogue_Len;
Tip_Z = Nose_Z + Nose_L;

// Rail buttons (1515) between fins. The aft button sits low on the fin can:
// rail exit is when it leaves the rail (tools/l3_motor_survey.py AFT_BUTTON 0.2 m).
Rail_a = 45;
Rail_Z = [200, EBay_Z - 40];

// Motors: [name, case dia, length]  (ThrustCurve.org)
Motors = [
	["M1297W RMS-75/5120", 75.4, 602.5],
	["K1499N RMS-75/1280", 75.4, 260],
	["J1299N RMS-54/852", 54, 231],
	["K2050ST RMS-54/1706", 54, 383]
];
Motor_Name = Motors[Motor][0];
Motor_D = Motors[Motor][1];
Motor_L = Motors[Motor][2];
Motor_Aft_Z = -8;       // aft closure sits proud of the retainer

echo(str("=== PeregrineL3 assembly 0.1.0 ==="));
echo(str("Motor: ", Motor_Name));
echo(str("Sections Z: fin can 0-", FinCan_Exposed_Z, ", main ", Main_Z, "-", EBay_Z,
	", e-bay -", Drogue_Z, ", drogue -", Nose_Z, ", nose -", Tip_Z));
echo(str("Overall length: ", Tip_Z, " mm (L3-Design.md §4.2: ~1791)"));

$fn = $preview ? 72 : 180;

// ========== RENDER SELECT ==========

Cut = Render_Part == 1;

if (Render_Part <= 1) Rocket();
if (Render_Part == 2) { FinCanWithFins(); MotorView(); }

// ========== ASSEMBLY ==========

module Rocket(){
	FinCanWithFins();
	MotorView();
	Part("RoyalBlue") Tube(Main_Z, Main_Len);
	EBay();
	Part("RoyalBlue") Tube(Drogue_Z, Drogue_Len);
	Part("WhiteSmoke") NoseCone();
	Part("Silver") RailButtons();
}

// Colour a part; in the cutaway, clip it to the far half first so its
// cut faces keep the part colour.
module Part(c, alpha = 1){
	if (Cut)
		color(c, alpha) intersection(){
			children();
			translate([-Body_OD, -2 * Body_OD, Motor_Aft_Z - 20])
				cube([2 * Body_OD, 2 * Body_OD, Tip_Z + 40]);
		}
	else
		color(c, alpha) children();
}

module FinCanWithFins(){
	Part("DimGray") FinCanAssembly();
	Part("Black")
		for (i = [0:Fin_Count - 1]) rotate([0, 0, i * 360 / Fin_Count])
			FinInPlace();
}

// PeregrineFin75 local frame: X along root chord (LE at 0), Y outward
// (0 = body surface, tab below), Z through thickness. Map to rocket:
// X -> -Z (LE forward), Y -> radial +X, Z -> -Y.
module FinInPlace(){
	multmatrix([
		[0, 1,  0, Body_OD / 2],
		[0, 0, -1, 0],
		[-1, 0, 0, Fin_LE_Z],
		[0, 0,  0, 1]])
		PeregrineFin75();
}

module Tube(z, len, od = Body_OD, id = Body_ID){
	translate([0, 0, z]) difference(){
		cylinder(d = od, h = len);
		translate([0, 0, -1]) cylinder(d = id, h = len + 2);
	}
}

// Placeholder: printed e-bay section with integrated couplers, like the
// L2 PeregrineEBay. Two altimeter doors at 0 and 180 degrees.
module EBay(){
	Part("Orange") difference(){
		Tube(EBay_Z, EBay_Len);
		for (a = [0, 180]) rotate([0, 0, a])
			translate([Body_OD / 2 - 6, -20, EBay_Z + 40])
				cube([10, 40, EBay_Len - 80]);
	}
	Part("DarkOrange") for (a = [0, 180]) rotate([0, 0, a])
		translate([Body_OD / 2 - 2.5, -20, EBay_Z + 40])
			cube([1.5, 40, EBay_Len - 80]);
}

module NoseCone(){
	translate([0, 0, Nose_Z]) {
		difference(){
			rotate_extrude() polygon(OgiveProfile(Body_OD / 2, Nose_L, 24));
			translate([0, 0, -0.01])
				rotate_extrude() polygon(OgiveProfile(Body_OD / 2 - 3, Nose_L - 25, 24));
		}
		translate([0, 0, -Nose_Shoulder_L])
			Tube(0, Nose_Shoulder_L, Body_ID - 0.4, Body_ID - 4.4);
	}
}

// Tangent ogive, radius R, length L, n segments (solid)
function OgiveProfile(R, L, n) =
	let(rho = (R * R + L * L) / (2 * R))
	concat([[0, 0]],
		[for (i = [0:n]) let(x = L * i / n)
			[sqrt(rho * rho - x * x) + R - rho, x]],
		[[0, L]]);

module RailButtons(){
	rotate([0, 0, Rail_a])
		for (z = Rail_Z) translate([Body_OD / 2, 0, z]) rotate([0, 90, 0]) {
			cylinder(d = 11, h = 6);
			translate([0, 0, 6]) cylinder(d = 16, h = 3);
		}
}

module MotorView(){
	translate([0, 0, Motor_Aft_Z]) {
		Part("Red") cylinder(d = Motor_D, h = Motor_L);
		// 54 mm adapter: not designed yet, shown as a plain sleeve
		if (Motor_D < 70)
			Part("Yellow") Tube(-Motor_Aft_Z, Motor_L + Motor_Aft_Z, MMT_OD - 0.4, Motor_D + 0.6);
	}
}
