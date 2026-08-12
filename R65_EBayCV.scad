// ***********************************
// Project: 3D Printed Rocket
// Filename: R65_EBayCV.scad
// by Tõnu Samuel
// Created: 3/4/2026
// Revision: 0.2.0  3/4/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Electronics Bay sled for CATS Vega flight computer
// in 65mm (LOC 2.65") rocket body tube.
// All metric hardware — M3, M5, M6.
//
// CATS Vega board: 100 x 33 x 15mm (with components)
// 3x M3 mounting holes, triangular pattern:
//   2 holes 27mm apart near one end
//   1 hole centered 60mm from the pair
//
// CATS Vega features used:
//   - PWM servo output (drives CableReleaseBBMini servo directly)
//   - Magnetic arming (no external switch needed)
//   - Pyro channel for BP ejection charge
//
// Sled mounts on M6 threaded rod between two base plates.
// Board stands vertically along rocket axis.
// 2S LiPo battery stands vertically on opposite side of mounting wall.
//
// Cross section layout (top view, looking down Z axis):
//
//         ○ coupler wall (64.8mm OD)
//        / \
//       | C |  C = CATS Vega board (33mm wide, components toward +Y)
//       |-W-|  W = mounting wall (3mm, at Y≈0)
//       | B |  B = battery pocket (30x15mm, standing 55mm tall)
//        \ /
//         ○
//
// Print upright (base plate on bed), no supports needed.
//
//  ***** Hardware *****
//
// M6 threaded rod + nuts (center rod, replaces 1/4-20)
// M5 x 12mm socket head cap screw (2 req) outer plate bolts
// M3 x 10mm socket head cap screw (3 req) CATS Vega mounting
// M3 nut (3 req) board retention (or thread into standoff)
// 2S LiPo battery (≤55 x 30 x 15mm recommended)
//
//  ***** History *****
function R65_EBayCV_Rev()="R65_EBayCV 0.2.0";
echo(R65_EBayCV_Rev());
// 0.2.0  3/4/2026   Fix non-manifold gussets, export Sled_Len as function.
// 0.1.0  3/4/2026   First code.
//
// ***********************************
//  ***** for STL output *****
//
// R65_EBayCV_Sled(OD=LOC65Coupler_OD);
// R65_EBayCV_TopPlate(OD=LOC65Coupler_OD);
//
// ***********************************

include<TubesLib.scad>
use<ThreadLib.scad>

CV_Overlap=0.05;
CV_IDXtra=0.2;

// Exported as function so use<> can access it
function CV_EBay_Len() = 120;

// ========== CATS Vega Board ==========
CV_Board_W=33;        // width (X direction, across tube)
CV_Board_L=100;       // length (Z direction, along tube axis)
CV_Board_T=1.6;       // PCB thickness
CV_Board_CompH=13;    // component height from PCB face

// M3 mounting hole pattern (triangular, from board center)
// Two holes near bottom end, 27mm apart in X; one hole 60mm up, centered.
CV_HoleSpace_X=27;    // horizontal spacing between bottom pair
CV_HoleSpace_Z=60;    // vertical distance from bottom pair to top hole

// ========== 2S LiPo Battery ==========
// Standing vertically: 30mm (X) x 15mm (Y) x 55mm (Z)
CV_Batt_X=30;    // width (across tube)
CV_Batt_Y=15;    // depth (toward tube center)
CV_Batt_Z=55;    // height (along tube axis, vertical)
CV_Batt_Wall=1.2;

// ========== Metric Hardware ==========
CV_M6_d=6.0;
CV_M6_p=1.0;
CV_M5_d=5.0;
CV_M5_p=0.8;
CV_M3_d=3.0;
CV_M3_clear=3.4;     // M3 clearance hole
CV_M5_clear=5.5;     // M5 clearance hole

// ========== Sled Dimensions ==========
CV_Plate_t=3;         // base plate thickness
CV_Boss_t=8;          // threaded boss height
CV_Wall_t=1.2;        // outer wall ring thickness
CV_Standoff_h=5;      // PCB standoff height from mounting wall
CV_Standoff_d=7;      // standoff outer diameter
CV_MountWall_t=3;     // vertical mounting wall thickness
CV_Sled_Len=CV_EBay_Len();

// ========== Calculated ==========
// Board bottom Z relative to Z=0 (base plate bottom)
CV_Board_Z=CV_Boss_t+4;  // above threaded bosses + clearance
// Board center Z
CV_BoardCenter_Z=CV_Board_Z+CV_Board_L/2;
// Trim cylinder for coupler interior
CV_Trim_d=LOC65Coupler_OD-CV_Wall_t*2-1;

// ========== Modules ==========

module CV_M5_ThreadedHole(depth=8){
	if ($preview){
		cylinder(d=CV_M5_d, h=depth);
	}else{
		ExternalThread(Pitch=CV_M5_p, Dia_Nominal=CV_M5_d+CV_IDXtra*2,
			Length=depth, Step_a=2, TrimEnd=true, TrimRoot=true);
	}
} // CV_M5_ThreadedHole

module CV_M6_ThreadedHole(depth=8){
	if ($preview){
		cylinder(d=CV_M6_d, h=depth);
	}else{
		ExternalThread(Pitch=CV_M6_p, Dia_Nominal=CV_M6_d+CV_IDXtra*2,
			Length=depth, Step_a=2, TrimEnd=true, TrimRoot=true);
	}
} // CV_M6_ThreadedHole

module CV_BoardHolePattern(){
	// 3x M3 hole positions relative to board center
	// X = across tube, Z = along tube axis
	translate([-CV_HoleSpace_X/2, 0, -CV_HoleSpace_Z/2]) children();  // bottom-left
	translate([+CV_HoleSpace_X/2, 0, -CV_HoleSpace_Z/2]) children();  // bottom-right
	translate([0, 0, +CV_HoleSpace_Z/2]) children();                   // top-center
} // CV_BoardHolePattern

module CV_TrimCoupler(OD=LOC65Coupler_OD){
	// Cylinder used to trim parts to fit inside coupler
	cylinder(d=OD-CV_Wall_t*2-1, h=CV_Sled_Len+1, $fn=$preview? 90:180);
} // CV_TrimCoupler

module CV_BasePlate(OD=LOC65Coupler_OD, IsTop=false, ShockCord_a=-30){
	nOuterBolts=2;
	Outer_BC_d=OD-11;

	difference(){
		union(){
			cylinder(d=OD, h=CV_Plate_t, $fn=$preview? 90:180);
			Tube(OD=OD, ID=OD-CV_Wall_t*2, Len=CV_Boss_t, myfn=$preview? 90:180);
			cylinder(d=CV_M6_d+5, h=CV_Boss_t, $fn=$preview? 36:90);
			for (j=[0:nOuterBolts-1]) rotate([0,0,360/nOuterBolts*j])
				translate([0, Outer_BC_d/2, 0])
					cylinder(d=CV_M5_d+5, h=CV_Boss_t, $fn=$preview? 36:90);
		} // union

		translate([0,0,-CV_Overlap])
			CV_M6_ThreadedHole(depth=CV_Boss_t+CV_Overlap*2);

		for (j=[0:nOuterBolts-1]) rotate([0,0,360/nOuterBolts*j])
			translate([0, Outer_BC_d/2, -CV_Overlap])
				CV_M5_ThreadedHole(depth=CV_Boss_t+CV_Overlap*2);

		rotate([0,0,ShockCord_a])
			translate([0, OD/2-CV_Wall_t-4, -CV_Overlap])
				cylinder(d=6, h=CV_Plate_t+CV_Overlap*2, $fn=24);

		if (!IsTop)
			translate([0,0,-CV_Overlap])
				cylinder(d=33, h=CV_Plate_t+CV_Overlap*2, $fn=36);
	} // difference
} // CV_BasePlate

module CV_MountingWall(OD=LOC65Coupler_OD){
	Wall_H=CV_Board_L+20;
	Wall_W=CV_Board_W+6;

	intersection(){
		translate([-Wall_W/2, -CV_MountWall_t/2, CV_Board_Z-10])
			cube([Wall_W, CV_MountWall_t, Wall_H]);
		CV_TrimCoupler(OD=OD);
	} // intersection
} // CV_MountingWall

module CV_Standoffs(){
	translate([0, CV_MountWall_t/2, CV_BoardCenter_Z])
		CV_BoardHolePattern()
			rotate([-90,0,0])
				difference(){
					cylinder(d=CV_Standoff_d, h=CV_Standoff_h, $fn=24);
					translate([0,0,-CV_Overlap])
						cylinder(d=CV_M3_clear, h=CV_Standoff_h+CV_Overlap*2, $fn=24);
				} // difference
} // CV_Standoffs

module CV_GussetRibs(OD=LOC65Coupler_OD){
	// Triangular gussets connecting mounting wall base to base plate.
	// Built on +X side, mirrored for -X side.

	Gusset_H=25;     // height of tall edge (at wall)
	Gusset_W=15;     // width of base edge (along base plate)
	Gusset_t=2;      // thickness in Y

	for (m=[0,1]){
		mirror([m,0,0])
			intersection(){
				translate([0, -Gusset_t/2, 0])
					hull(){
						// Tall thin edge at wall
						translate([CV_Board_W/2+1, 0, CV_Plate_t])
							cube([0.1, Gusset_t, Gusset_H]);
						// Short wide base on base plate
						translate([CV_Board_W/2+1, 0, CV_Plate_t])
							cube([Gusset_W, Gusset_t, 0.1]);
					} // hull
				CV_TrimCoupler(OD=OD);
			} // intersection
	} // for
} // CV_GussetRibs


module CV_BattPocket(){
	// 2S LiPo battery pocket — battery stands vertically.
	// Origin at pocket corner (0,0,0), pocket opens at +Z.

	Outer_X=CV_Batt_X+CV_Batt_Wall*2;
	Outer_Y=CV_Batt_Y+CV_Batt_Wall*2;
	Outer_Z=CV_Batt_Z+CV_Batt_Wall;

	difference(){
		cube([Outer_X, Outer_Y, Outer_Z]);

		// Inner pocket (open top)
		translate([CV_Batt_Wall, CV_Batt_Wall, CV_Batt_Wall])
			cube([CV_Batt_X, CV_Batt_Y, CV_Batt_Z+CV_Overlap]);

		// Wire exit slot (top, one end)
		translate([Outer_X-CV_Batt_Wall-8, CV_Batt_Wall+2, Outer_Z-8])
			cube([10, CV_Batt_Y-4, 10]);

		// Thumb push-out hole (bottom)
		translate([Outer_X/2, Outer_Y/2, -CV_Overlap])
			cylinder(d=12, h=CV_Batt_Wall+CV_Overlap*2, $fn=24);

		// Side windows (finger access, reduce mass)
		// Inset fully inside walls — no edge overlap
		translate([CV_Batt_Wall+5, 0, CV_Batt_Wall+8])
			cube([CV_Batt_X-10, CV_Batt_Wall, CV_Batt_Z-15]);
		translate([CV_Batt_Wall+5, Outer_Y-CV_Batt_Wall, CV_Batt_Wall+8])
			cube([CV_Batt_X-10, CV_Batt_Wall, CV_Batt_Z-15]);
	} // difference
} // CV_BattPocket

module R65_EBayCV_Sled(OD=LOC65Coupler_OD){
	Batt_Outer_X=CV_Batt_X+CV_Batt_Wall*2;
	Batt_Outer_Y=CV_Batt_Y+CV_Batt_Wall*2;

	// Base plate
	CV_BasePlate(OD=OD, IsTop=false);

	// Vertical mounting wall
	CV_MountingWall(OD=OD);

	// Gusset ribs
	CV_GussetRibs(OD=OD);

	// CATS Vega standoffs
	CV_Standoffs();

	// Battery pocket on -Y side, standing vertically
	intersection(){
		translate([-Batt_Outer_X/2,
				   -CV_MountWall_t/2-2-Batt_Outer_Y,
				   CV_Board_Z])
			CV_BattPocket();
		CV_TrimCoupler(OD=OD);
	} // intersection
} // R65_EBayCV_Sled

module R65_EBayCV_TopPlate(OD=LOC65Coupler_OD, ShockCord_a=-30){
	CV_BasePlate(OD=OD, IsTop=true, ShockCord_a=ShockCord_a);
} // R65_EBayCV_TopPlate

// ========== Preview ==========
// R65_EBayCV_Sled();
// R65_EBayCV_TopPlate();
// Full assembly:
// R65_EBayCV_Sled();
// translate([0,0,CV_Sled_Len+5]) rotate([180,0,0]) R65_EBayCV_TopPlate();
