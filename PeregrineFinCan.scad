// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineFinCan.scad
// by Tõnu Samuel
// Created: 2/8/2026
// Revision: 0.2.0  2/8/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// 3D printed aft section (fin can) for Peregrine rocket.
// Prints vertically on Bambu P1S (250mm max with AMS).
//
// Structure (bottom to top):
//   - Male threaded retainer section at aft end (13mm, protrudes aft)
//     Accepts original 38mm motor retainer cup (printed separately)
//   - Outer wall at body tube OD (100mm)
//   - Inner motor mount tube (38mm bore)
//   - Centering rings connecting MMT to outer wall
//   - Fin slots through outer wall
//   - Coupler shoulder at forward end (cardboard tube slides over)
//   - Screw holes in coupler for securing body tube
//   - Shock cord mount (12mm Al tube through coupler)
//
// Fins are separate (plywood/G10/printed), slid into slots
// and epoxied in place.
//
//  ***** History *****
// 0.1.0  2/8/2026   Initial design.
// 0.2.0  2/8/2026   Replace retainer lip with male threaded section
//                    matching original 38mm motor retainer cup.
//                    Thread dimensions reverse-engineered from STL.
//                    Can_Len adjusted to 237mm (total print 250mm).
//
// ***********************************

$fn=$preview? 72:180;
Overlap=0.05;

// ========== USER PARAMETERS ==========

// Body tube
Body_OD = 100;            // body tube outer diameter
Body_ID = 98;             // body tube inner diameter
Body_Wall = (Body_OD - Body_ID) / 2;  // 1mm

// Motor mount
MMT_OD = 38.5;            // 38mm motor + 0.5mm clearance
MMT_ID = 36;              // motor mount tube ID

// Fins
Fin_Count = 3;
Fin_Thickness = 6.35;     // 1/4" plywood
Fin_Slot_Clearance = 0.5; // total extra
Fin_Slot_W = Fin_Thickness + Fin_Slot_Clearance;

// Fin slot geometry (from OpenRocket)
Fin_Root_L = 249;         // root chord length
Fin_Tab_H = 30;           // tab height (how deep fin goes through wall)
Fin_Tab_L = 203;          // fin tab length in slot
Fin_Tab_Pos = 92;         // tab position from fin leading edge

// ========== THREADED MOTOR RETAINER ==========
// Dimensions reverse-engineered from 38mm_motor_retainer.stl
// Male thread on fin can aft end; original cup screws onto it.

Thread_Minor_D = 44.14;    // thread root diameter (core OD)
Thread_Major_D = 47.14;   // thread crest diameter
Thread_Pitch = 2.6;       // mm per revolution
Thread_H = 13.1;          // threaded section height
Thread_Duty = 0.25;       // tooth width as fraction of pitch
Thread_Chamfer = 0.8;     // lead-in chamfer at aft end

// ========== FIN CAN DIMENSIONS ==========

// Body section (above thread)
Body_Len = 237;           // main body section length
// Total print height = Thread_H + Body_Len = 250.1mm (P1S limit)

// Wall thickness of printed fin can
Wall = 2.4;               // 6 perimeters at 0.4mm

// Coupler (forward end, body tube slides over this)
Coupler_OD = Body_ID - 0.6;  // snug fit inside body tube
Coupler_Len = 30;         // overlap length
Coupler_Wall = 2.4;
nCoupler_Screws = 6;      // retention screws
Coupler_Screw_d = 3.5;    // #6 screw clearance

// Shock cord mount (12mm aluminium tube through coupler)
Al_Tube_d = 12.0;         // tube diameter
Al_Tube_Boss = Al_Tube_d + 6;  // boss OD around tube
Al_Tube_Z = Al_Tube_d/2 + 5;   // 5mm clearance for cord below tube
ShockMount_a = 0;         // aligned with fin, between screws

// Centering rings
CR_Thickness = 4;         // ring axial thickness
nCR = 3;                  // number of centering rings

// ========== COMPUTED ==========

Fin_Angle = 360 / Fin_Count;

// In the printed model:
// Z = 0 to Thread_H: threaded retainer section (MMT only, no outer wall)
// Z = Thread_H to Thread_H + Body_Len: main body
// Total height = Thread_H + Body_Len

// Fin slots start just above thread-to-body junction
Slot_Start = Thread_H + CR_Thickness;  // leave room for first centering ring
Slot_End = Slot_Start + Fin_Tab_L;

// Centering ring positions
CR_Positions = [
	Thread_H,                                          // at junction
	Thread_H + Body_Len/2 - Coupler_Len/2,           // middle
	Thread_H + Body_Len - Coupler_Len - CR_Thickness  // just below coupler
];

// Total height check
Total_H = Thread_H + Body_Len;
echo(str("Total print height: ", Total_H, "mm"));
assert(Total_H <= 250.5, "TOO TALL FOR P1S!");

// ========== RENDER ==========

Render_Part = 0;
// 0 = Assembly preview
// 1 = Fin can for printing

if (Render_Part == 0) FinCanAssembly();
if (Render_Part == 1) FinCan();

// ========== MODULES ==========

module FinCanAssembly(){
	FinCan();

	// Show body tube ghost
	if ($preview)
		color("Tan", 0.2)
			translate([0, 0, Thread_H + Body_Len - Coupler_Len])
				difference(){
					cylinder(d=Body_OD, h=Coupler_Len + 50);
					translate([0, 0, -1])
						cylinder(d=Body_ID, h=Coupler_Len + 52);
				}

	// Show motor ghost (38mm case, extends forward)
	if ($preview)
		color("Gray", 0.2)
			translate([0, 0, -20])
				cylinder(d=38, h=Total_H + 40);
}

module FinCan(){
	difference(){
		union(){
			// === THREADED RETAINER SECTION (Z=0 to Thread_H) ===
			// Core cylinder at thread root diameter
			difference(){
				cylinder(d=Thread_Minor_D, h=Thread_H);
				translate([0, 0, -1])
					cylinder(d=MMT_OD, h=Thread_H + 2);
			}

			// Helical male thread
			MaleThread();

			// === MAIN BODY SECTION (Z=Thread_H to Thread_H+Body_Len) ===

			// Outer wall (body tube diameter)
			translate([0, 0, Thread_H])
				difference(){
					cylinder(d=Body_OD, h=Body_Len - Coupler_Len);
					translate([0, 0, -1])
						cylinder(d=Body_OD - Wall*2, h=Body_Len - Coupler_Len + 2);
				}

			// Motor mount tube (through body section)
			translate([0, 0, Thread_H])
				difference(){
					cylinder(d=MMT_OD + Wall*2, h=Body_Len - Coupler_Len);
					translate([0, 0, -1])
						cylinder(d=MMT_OD, h=Body_Len - Coupler_Len + 2);
				}

			// Centering rings
			for (z=CR_Positions)
				CenteringRing(z);

			// Fin guide ribs (reinforcement along fin slots)
			for (i=[0:Fin_Count-1])
				rotate([0, 0, i * Fin_Angle])
					FinRib();

			// Coupler shoulder (forward end)
			translate([0, 0, Thread_H + Body_Len - Coupler_Len])
				Coupler();
		}

		// MMT bore through everything
		translate([0, 0, -1])
			cylinder(d=MMT_OD, h=Total_H + 2);

		// Fin slots through outer wall
		for (i=[0:Fin_Count-1])
			rotate([0, 0, i * Fin_Angle])
				FinSlot();

		// Coupler screw holes
		for (i=[0:nCoupler_Screws-1])
			rotate([0, 0, i * 360/nCoupler_Screws + 30])
				translate([0, 0, Thread_H + Body_Len - Coupler_Len/2])
					rotate([90, 0, 0])
						cylinder(d=Coupler_Screw_d, h=Body_OD, center=true);

		// Thread lead-in chamfer at aft end (Z=0)
		translate([0, 0, -Overlap])
			difference(){
				cylinder(d=Thread_Major_D + 2, h=Thread_Chamfer + Overlap);
				cylinder(d1=Thread_Minor_D - 1, d2=Thread_Major_D + 1,
						 h=Thread_Chamfer + Overlap);
			}
	}
}

// ========== MALE THREAD MODULE ==========
// Creates helical male thread using twisted half-annulus method.
// The 2D cross-section (annular sector) is extruded with twist to form helix.

module MaleThread(){
	thread_depth = (Thread_Major_D - Thread_Minor_D) / 2;
	n_turns = Thread_H / Thread_Pitch;
	duty_angle = Thread_Duty * 360;  // angular extent of tooth (25% = 90°)

	intersection(){
		// Limit to annular thread zone
		difference(){
			cylinder(d=Thread_Major_D, h=Thread_H);
			translate([0, 0, -Overlap])
				cylinder(d=Thread_Minor_D - Overlap, h=Thread_H + 2*Overlap);
		}

		// Twisted sector: creates helix
		linear_extrude(height=Thread_H, twist=-360*n_turns, convexity=10,
					   $fn=$preview? 72 : 180)
			intersection(){
				// Annular ring (larger than needed, intersection above trims it)
				difference(){
					circle(d=Thread_Major_D + 2);
					circle(d=Thread_Minor_D - 2);
				}
				// Sector for duty cycle
				// rotate half the duty angle so tooth is centered on X+
				rotate([0, 0, -duty_angle/2])
					SectorPoly(Thread_Major_D/2 + 2, duty_angle);
			}
	}
}

// 2D sector polygon from angle 0 to `angle` degrees at given radius
module SectorPoly(r, angle){
	steps = max(1, ceil(angle / 5));
	polygon(
		concat(
			[[0, 0]],
			[for (i=[0:steps]) [r * cos(i * angle/steps),
								r * sin(i * angle/steps)]]
		)
	);
}

// ========== CENTERING RING ==========

module CenteringRing(z_pos){
	translate([0, 0, z_pos])
		difference(){
			cylinder(d=Body_OD - Wall*2 + 0.1, h=CR_Thickness);
			translate([0, 0, -1])
				cylinder(d=MMT_OD + Wall*2 - 0.1, h=CR_Thickness + 2);

			// Lightening holes
			for (i=[0:Fin_Count-1])
				rotate([0, 0, i * Fin_Angle + Fin_Angle/2]){
					R_Mid = (MMT_OD/2 + Wall + Body_OD/2 - Wall) / 2;
					Hole_D = (Body_OD/2 - Wall) - (MMT_OD/2 + Wall) - 8;
					if (Hole_D > 5)
						translate([R_Mid, 0, -1])
							cylinder(d=Hole_D, h=CR_Thickness + 2);
				}
		}
}

// ========== FIN RIB ==========

module FinRib(){
	Rib_W = Fin_Slot_W + Wall*2;
	Rib_R_Inner = MMT_OD/2 + Wall - 0.1;
	Rib_R_Outer = Body_OD/2;

	translate([Rib_R_Inner, -Rib_W/2, Slot_Start - 5])
		cube([Rib_R_Outer - Rib_R_Inner,
			  Rib_W,
			  Fin_Tab_L + 10]);
}

// ========== FIN SLOT ==========

module FinSlot(){
	// Through outer wall and ribs
	translate([MMT_OD/2 - 1, -Fin_Slot_W/2, Slot_Start])
		cube([Body_OD/2 - MMT_OD/2 + 2, Fin_Slot_W, Fin_Tab_L]);
}

// ========== COUPLER ==========

module Coupler(){
	Coupler_ID = Coupler_OD - Coupler_Wall*2;

	difference(){
		union(){
			// Coupler tube
			difference(){
				cylinder(d=Coupler_OD, h=Coupler_Len);
				translate([0, 0, -1])
					cylinder(d=Coupler_ID, h=Coupler_Len + 2);
			}

			// Transition ring at base of coupler
			cylinder(d=Body_OD, h=Wall);

			// Shock mount boss (solid around Al tube)
			difference(){
				intersection(){
					translate([0, 0, Al_Tube_Z])
						rotate([0, 0, ShockMount_a])
							rotate([90, 0, 0])
								cylinder(d=Al_Tube_Boss, h=Coupler_OD, center=true);
					// Trim to coupler cylinder
					cylinder(d=Coupler_OD - 1, h=Coupler_Len);
				}
				// Hollow center so cord can wrap
				translate([0, 0, Al_Tube_Z])
					rotate([0, 0, ShockMount_a])
						rotate([90, 0, 0])
							cylinder(d=Al_Tube_Boss + 1, h=Coupler_ID - 10, center=true);
			}
		}

		// Al tube bore (through entire coupler width)
		translate([0, 0, Al_Tube_Z])
			rotate([0, 0, ShockMount_a])
				rotate([90, 0, 0])
					cylinder(d=Al_Tube_d, h=Body_OD, center=true);
	}
}

// ========== INFO ==========

echo(str("Peregrine Fin Can v0.2.0 (threaded retainer)"));
echo(str("Total print height: ", Total_H, "mm"));
echo(str("Thread section: ", Thread_H, "mm (", Thread_Minor_D, "/", Thread_Major_D, "mm, pitch ", Thread_Pitch, "mm)"));
echo(str("Body section: ", Body_Len, "mm"));
echo(str("Body OD=", Body_OD, "mm, MMT bore=", MMT_OD, "mm"));
echo(str("Fin slot: ", Fin_Slot_W, "mm wide, ", Fin_Tab_L, "mm long"));
echo(str("Slot position: ", Slot_Start, "mm to ", Slot_End, "mm from aft"));
echo(str("Coupler: ", Coupler_OD, "mm OD x ", Coupler_Len, "mm"));
echo(str("Fits Bambu P1S: ", Total_H <= 250.5 ? "YES" : "NO"));
