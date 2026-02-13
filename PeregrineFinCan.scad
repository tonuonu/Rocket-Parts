// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineFinCan.scad
// by Tõnu Samuel
// Created: 2/8/2026
// Revision: 1.0.1  2/13/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// 3D printed aft section (fin can) for Peregrine rocket.
// Prints vertically on Bambu P1S (250mm max with AMS).
//
// Structure (bottom to top):
//   - Male threaded retainer section at aft end (1/2", protrudes aft)
//     Accepts original 38mm motor retainer cup (printed separately)
//   - Outer wall at body tube OD (101.5mm)
//   - Inner motor mount tube (38.5mm bore)
//   - Centering rings connecting MMT to outer wall
//   - Fin slots through outer wall (stop 10mm from MMT)
//   - Fin guide ribs from outer wall to MMT (solid connection)
//   - Coupler shoulder at forward end (cardboard tube slides over)
//   - Screw holes in coupler for securing body tube
//   - Cord channel slot in forward centering ring
//     (tubular nylon wraps MMT, exits forward through slot)
//
// Fins are separate (printed/G10), slid into slots and epoxied.
// Fin slots do NOT reach motor tube — reloadable case,
// no fin-to-motor gluing needed. Full tube around motor for strength.
// Recovery cord wraps MMT in gap between rib tops and forward CR.
//
//  ***** History *****
// 0.1.0  2/8/2026   Initial design.
// 0.2.0  2/8/2026   Replace retainer lip with male threaded section.
// 0.3.0  2/8/2026   Correct thread dims to imperial.
// 0.4.0  2/8/2026   Replace Al tube shock mount with cord channel slot.
// 0.5.0  2/9/2026   Post-test-print fixes:
//                    - Body OD/ID corrected to 101.5/99.0 (match EBay)
//                    - Fin slots stop 10mm from MMT (reloadable case)
//                    - Ribs connect solidly to MMT (no gap)
//                    - Ribs trimmed below coupler (body tube slides on)
//                    - Recovery cord wraps in gap above ribs
//                    - Fin tab shortened to 190mm
// 0.6.0  2/10/2026  Printability and weight improvements:
//                    - CR 45° chamfers on underside edges (no supports)
//                    - Ribbon passages (8x16mm) through ribs at MMT
//                    - Ribs clipped to body cylinder (no external lip)
//                    - Lightweight ribs: thin web in inner zone
//                    - 1mm slot clearance at top for fin insertion
// 0.7.0  2/10/2026  Built-in print support and CR cleanup:
//                    - Remove ineffective CR chamfers (were buried in walls)
//                    - Add 3 support webs at 60/180/300° between CRs
//                    - Webs serve as print support + anti-ovalizing
// 0.8.0  2/10/2026  Structural and printability refinements:
//                    - Lightweight ribs: thin web inner zone, 0.8mm back wall
//                    - Vertical tubes through CR lightening holes
//                    - Round cord passage replacing rectangular slot
//                    - Ribbon passages through support webs
//                    - Slots/ribs extended to forward CR
//                    - 6 triangular gussets behind coupler screws
// 0.9.0  2/13/2026  Removed redundant cord passage through forward CR.
// 1.0.0  2/13/2026  Cord passage: rectangular slot (18×20mm) through
//                    outer wall at 60°, spanning forward CR zone.
//                    Connects tube interior to outside for cord exit.
//
// ***********************************

$fn=$preview? 72:180;
Overlap=0.05;

// ========== USER PARAMETERS ==========

// Body tube (matches PeregrineEBay.scad)
Body_OD = 101.5;          // body tube outer diameter
Body_ID = 99.0;           // body tube inner diameter
Body_Wall = (Body_OD - Body_ID) / 2;  // 1.25mm

// Motor mount
MMT_OD = 38.5;            // 38mm motor + 0.5mm clearance
MMT_ID = 36;              // motor mount tube ID
Motor_L = 337;            // AeroTech 38/720 case length

// Fins
Fin_Count = 3;
Fin_Thickness = 6.35;     // 1/4" plywood
Fin_Slot_Clearance = 0.5; // total extra
Fin_Slot_W = Fin_Thickness + Fin_Slot_Clearance;

// Fin slot geometry
Fin_Root_L = 249;         // root chord length
Fin_Tab_H = 19;           // tab height (slot doesn't reach MMT)
Fin_Tab_L = 190;          // fin tab length in slot
Slot_Clearance = 1;       // extra slot length at top for easy insertion
Fin_Tab_Pos = 87;         // tab position from leading edge (shifted 5mm fwd)

// Gap between fin slot and MMT (full tube around motor)
Slot_Gap = 10;            // mm from MMT outer wall to slot inner edge

// ========== THREADED MOTOR RETAINER ==========
Thread_Minor_D = 44.45;   // 1-3/4" thread root diameter
Thread_Major_D = 47.625;  // 1-7/8" thread crest diameter
Thread_Pitch = 25.4/10;   // 10 TPI = 2.54mm
Thread_H = 12.7;          // 1/2" = 5 turns at 10 TPI
Thread_Duty = 0.25;       // tooth width as fraction of pitch
Thread_Chamfer = 0.8;     // lead-in chamfer at aft end

// ========== FIN CAN DIMENSIONS ==========

Body_Len = 236;           // main body section length
// Total print height = Thread_H + Body_Len = 248.7mm (P1S limit)

// Wall thickness of printed fin can
Wall = 2.4;               // 6 perimeters at 0.4mm

// Coupler (forward end, body tube slides over this)
Coupler_OD = Body_ID - 0.6;  // snug fit inside body tube
Coupler_Len = 30;         // overlap length
Coupler_Wall = 2.4;
nCoupler_Screws = 6;      // retention screws
Coupler_Screw_d = 3.5;    // #6 screw clearance

// Shock cord channel
Cord_Slot_a = 60;         // midway between fins (0° and 120°)
Cord_Pass_H = 16;         // ribbon passage height in ribs (cord width + clearance)

// Centering rings
CR_Thickness = 4;         // ring axial thickness
nCR = 3;                  // number of centering rings

// ========== COMPUTED ==========

Fin_Angle = 360 / Fin_Count;

// Slot inner radius: 10mm gap from MMT wall
Slot_Inner_R = MMT_OD/2 + Wall + Slot_Gap;

// Z layout:
// Z = 0 to Thread_H: threaded retainer section
// Z = Thread_H to Thread_H + Body_Len: main body
Slot_Start = Thread_H + CR_Thickness;  // above first centering ring
Slot_End = Slot_Start + Fin_Tab_L;

// Coupler base Z position
Coupler_Z = Thread_H + Body_Len - Coupler_Len;

// Centering ring positions
CR_Positions = [
	Thread_H,                                          // at junction
	Thread_H + Body_Len/2 - Coupler_Len/2,           // middle
	Thread_H + Body_Len - Coupler_Len - CR_Thickness  // just below coupler
];

// Rib extends past slot bottom, and up to forward CR for rigidity
Rib_Margin = 3;           // extend past slot at bottom end
Rib_Z_Start = Slot_Start - Rib_Margin;
Rib_Z_End = CR_Positions[2];  // ribs touch forward CR — no gap

Total_H = Thread_H + Body_Len;

echo(str("Total print height: ", Total_H, "mm"));
echo(str("Slot inner radius: ", Slot_Inner_R, "mm (", Slot_Gap, "mm gap from MMT)"));
echo(str("Rib Z range: ", Rib_Z_Start, " to ", Rib_Z_End, "mm"));
echo(str("Forward CR at Z=", CR_Positions[2], "mm"));
echo(str("Coupler base at Z=", Coupler_Z, "mm"));
assert(Total_H <= 250.5, "TOO TALL FOR P1S!");
assert(Rib_Z_End < Coupler_Z, "RIBS PROTRUDE INTO COUPLER ZONE!");

// ========== RENDER ==========

Render_Part = 0;
// 0 = Assembly preview
// 1 = Fin can for printing
// 2 = Cross-section (verify internal features)

if (Render_Part == 0) FinCanAssembly();
if (Render_Part == 1) FinCan();
if (Render_Part == 2) difference(){
	FinCanAssembly();
	rotate([0, 0, Cord_Slot_a])
		translate([0, 0, -1]) cube([Body_OD, Body_OD, Total_H + 2]);
}

// ========== MODULES ==========

module FinCanAssembly(){
	FinCan();

	// Show body tube ghost
	if ($preview)
		color("Tan", 0.2)
			translate([0, 0, Coupler_Z])
				difference(){
					cylinder(d=Body_OD, h=Coupler_Len + 50);
					translate([0, 0, -1])
						cylinder(d=Body_ID, h=Coupler_Len + 52);
				}

	// Show motor ghost (AeroTech 38/720, nozzle at aft end)
	if ($preview)
		color("Gray", 0.2)
			cylinder(d=38, h=Motor_L);
}

module FinCan(){
	difference(){
		union(){
			// === THREADED RETAINER SECTION (Z=0 to Thread_H) ===
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

			// Vertical tubes through CR lightening holes
			// Connects all CRs so slicer has continuous vertical
			// geometry — eliminates support trees in pockets
			for (i=[0:Fin_Count-1])
				rotate([0, 0, i * Fin_Angle + Fin_Angle/2]){
					R_Mid = (MMT_OD/2 + Wall + Body_OD/2 - Wall) / 2;
					Hole_D = (Body_OD/2 - Wall) - (MMT_OD/2 + Wall) - 8;
					Tube_Wall = 0.8;
					Tube_Z0 = CR_Positions[0];
					Tube_Z1 = CR_Positions[len(CR_Positions)-1] + CR_Thickness;
					if (Hole_D > 5)
						translate([R_Mid, 0, Tube_Z0])
							difference(){
								cylinder(d=Hole_D, h=Tube_Z1 - Tube_Z0);
								translate([0, 0, -1])
									cylinder(d=Hole_D - Tube_Wall*2, h=Tube_Z1 - Tube_Z0 + 2);
							}
				}

			// Fin guide ribs (solid bridge from outer wall to MMT)
			for (i=[0:Fin_Count-1])
				rotate([0, 0, i * Fin_Angle])
					FinRib();

			// Support webs (print support for CRs + anti-ovalizing)
			// 6 webs at 30/90/150/210/270/330° — symmetric, avoids
			// fins (0/120/240°) and CR lightening holes (60/180/300°)
			for (i=[0:Fin_Count-1])
				for (offset=[Fin_Angle/4, 3*Fin_Angle/4])
					rotate([0, 0, i * Fin_Angle + offset])
						SupportWeb();

			// Coupler shoulder (forward end)
			translate([0, 0, Coupler_Z])
				Coupler();
		}

		// MMT bore through everything
		translate([0, 0, -1])
			cylinder(d=MMT_OD, h=Total_H + 2);

		// Fin slots (stop short of MMT — leave full tube around motor)
		for (i=[0:Fin_Count-1])
			rotate([0, 0, i * Fin_Angle])
				FinSlot();

		// Ribbon passage through each rib (near top, hugs MMT surface)
		// 8mm radial x 16mm tall — ribbon lays flat on motor tube
		for (i=[0:Fin_Count-1])
			rotate([0, 0, i * Fin_Angle])
				translate([MMT_OD/2 + Wall, -Fin_Slot_W/2 - Wall, Rib_Z_End - Cord_Pass_H])
					cube([8, Fin_Slot_W + Wall*2, Cord_Pass_H + 1]);

		// Coupler screw holes
		for (i=[0:nCoupler_Screws-1])
			rotate([0, 0, i * 360/nCoupler_Screws])
				translate([0, 0, Coupler_Z + Coupler_Len/2])
					rotate([90, 0, 0])
						cylinder(d=Coupler_Screw_d, h=Body_OD, center=true);

		// Cord passage: rectangular slot through outer wall at 60°.
		// Cuts through the forward CR zone and coupler base, connecting
		// the vertical tube interior to the outside of the fin can.
		// Cord route: retainer area → tube interior → this slot → outside
		// → up between fin can and body tube → body tube interior.
		rotate([0, 0, Cord_Slot_a]){
			Cord_Slot_W = 18;     // width (matches tube interior ~17mm)
			Cord_Slot_H = 20;     // height (fits 1" tubular nylon)
			Cord_Slot_Z = CR_Positions[len(CR_Positions)-1] - 2;  // start 2mm below fwd CR
			translate([Body_OD/2 - Wall - Overlap, -Cord_Slot_W/2, Cord_Slot_Z])
				cube([Wall + 2*Overlap, Cord_Slot_W, Cord_Slot_H]);
		}

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

module MaleThread(){
	thread_depth = (Thread_Major_D - Thread_Minor_D) / 2;
	n_turns = Thread_H / Thread_Pitch;
	duty_angle = Thread_Duty * 360;

	intersection(){
		difference(){
			cylinder(d=Thread_Major_D, h=Thread_H);
			translate([0, 0, -Overlap])
				cylinder(d=Thread_Minor_D - Overlap, h=Thread_H + 2*Overlap);
		}

		linear_extrude(height=Thread_H, twist=-360*n_turns, convexity=10,
					   $fn=$preview? 72 : 180)
			intersection(){
				difference(){
					circle(d=Thread_Major_D + 2);
					circle(d=Thread_Minor_D - 2);
				}
				rotate([0, 0, -duty_angle/2])
					SectorPoly(Thread_Major_D/2 + 2, duty_angle);
			}
	}
}

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

// Centering ring: flat disc with small 45° chamfers on underside edges.

module CenteringRing(z_pos){
	CR_R_Inner = MMT_OD/2 + Wall - 0.05;
	CR_R_Outer = Body_OD/2 - Wall + 0.05;

	translate([0, 0, z_pos])
		difference(){
			// Flat disc — supported by SupportWebs below
			rotate_extrude(convexity=4)
				polygon([
					[CR_R_Inner, 0],
					[CR_R_Inner, CR_Thickness],
					[CR_R_Outer, CR_Thickness],
					[CR_R_Outer, 0]
				]);

			// Lightening holes (between fins)
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


// ========== SUPPORT WEB ==========
// Thin radial wall between CRs in sectors between fins.
// Serves as built-in print support for CR undersides AND
// structural anti-ovalizing reinforcement.
// 6 webs at 30°/90°/150°/210°/270°/330° (symmetric).
// Avoids fins (0/120/240°) and CR holes (60/180/300°).

module SupportWeb(){
	Web_T = 1;  // wall thickness (2-3 perimeters)
	Web_R_Inner = MMT_OD/2 + Wall - 0.05;
	Web_R_Outer = Body_OD/2 - Wall + 0.05;
	Web_Z_Start = CR_Positions[0] + CR_Thickness;  // top of aft CR
	Web_Z_End = CR_Positions[len(CR_Positions)-1];  // bottom of fwd CR
	Web_H = Web_Z_End - Web_Z_Start;

	difference(){
		translate([Web_R_Inner, -Web_T/2, Web_Z_Start])
			cube([Web_R_Outer - Web_R_Inner, Web_T, Web_H]);

		// Ribbon passage near MMT (same Z and depth as rib passages)
		translate([Web_R_Inner - 1, -Web_T/2 - 1,
			Rib_Z_End - Cord_Pass_H])
			cube([8 + 1, Web_T + 2, Cord_Pass_H]);
	}
}

// ========== FIN RIB ==========
// Solid bridge from outer wall to MMT surface.
// Extends slightly past slot ends. Stops well below coupler.
// Inner edge overlaps into MMT zone — bore trims it, guaranteeing
// solid connection to MMT wall.

module FinRib(){
	Rib_W = Fin_Slot_W + Wall*2;
	Rib_R_Inner = MMT_OD/2 - 0.5;
	Rib_R_Outer = Body_OD/2;
	Rib_H = Rib_Z_End - Rib_Z_Start;

	// Clip to body cylinder (no protruding lips)
	intersection(){
		union(){
			// Inner zone: thin web (Wall thick) from MMT to slot edge
			// Only transfers radial loads, doesn't guide fins
			translate([Rib_R_Inner, -Wall/2, Rib_Z_Start])
				cube([Slot_Inner_R - Rib_R_Inner,
					  Wall,
					  Rib_H]);

			// Slot back wall: thin vertical plate at inner end of fin slot
			// 0.8mm = single perimeter round-trip, just holds parts
			// during assembly until epoxy cures
			Back_Wall_T = 0.8;
			translate([Slot_Inner_R - Back_Wall_T, -Rib_W/2, Rib_Z_Start])
				cube([Back_Wall_T, Rib_W, Rib_H]);
			// Outer zone: full width (flanks the fin slot)
			translate([Slot_Inner_R, -Rib_W/2, Rib_Z_Start])
				cube([Rib_R_Outer - Slot_Inner_R,
					  Rib_W,
					  Rib_H]);
		}
		translate([0, 0, Rib_Z_Start - 1])
			cylinder(d=Body_OD, h=Rib_H + 2);
	}
}

// ========== FIN SLOT ==========
// Cuts from outer wall inward but stops Slot_Gap mm from MMT.
// Leaves full unbroken tube around motor for strength.
// Recovery cord wraps through gap above rib tops.

module FinSlot(){
	// Slot extends from above aft CR to forward CR for full rigidity
	Slot_Top = CR_Positions[2];
	translate([Slot_Inner_R, -Fin_Slot_W/2, Slot_Start])
		cube([Body_OD/2 - Slot_Inner_R + 2, Fin_Slot_W, Slot_Top - Slot_Start]);
}

// ========== COUPLER ==========

module Coupler(){
	Coupler_ID = Coupler_OD - Coupler_Wall*2;

	// Coupler tube
	difference(){
		cylinder(d=Coupler_OD, h=Coupler_Len);
		translate([0, 0, -1])
			cylinder(d=Coupler_ID, h=Coupler_Len + 2);
	}

	// Transition ring at base of coupler
	cylinder(d=Body_OD, h=Wall);

	// Triangular gussets behind each screw hole
	// Connect coupler wall to base — prevents layer separation,
	// gives screws more grip material
	Gusset_Depth = 6;     // inward from wall at base
	Gusset_W = 10;        // circumferential width
	Gusset_H = Coupler_Len/2 + Coupler_Screw_d/2 + 1;  // base to just above screw
	for (i=[0:nCoupler_Screws-1])
		rotate([0, 0, i * 360/nCoupler_Screws + 30])
			translate([Coupler_ID/2 - Gusset_Depth, -Gusset_W/2, 0])
				hull(){
					// Base: full depth inward from wall
					cube([Gusset_Depth, Gusset_W, 0.01]);
					// Top: tapers to wall at screw height
					translate([Gusset_Depth - 0.01, 0, Gusset_H])
						cube([0.01, Gusset_W, 0.01]);
				}
}

// ========== INFO ==========

echo(str("Peregrine Fin Can v1.0.1"));
echo(str("Screw/gusset angle offset: 0 (at 0/60/120/180/240/300)"));
echo(str("Total print height: ", Total_H, "mm"));
echo(str("Thread: ", Thread_Minor_D, "/", Thread_Major_D, "mm, pitch ", Thread_Pitch, "mm, H=", Thread_H, "mm"));
echo(str("Body: OD=", Body_OD, "mm, ID=", Body_ID, "mm, Len=", Body_Len, "mm"));
echo(str("MMT bore=", MMT_OD, "mm"));
echo(str("Fin slot: ", Fin_Slot_W, "mm W x ", Fin_Tab_L, "mm L, inner R=", Slot_Inner_R, "mm"));
echo(str("Slot Z: ", Slot_Start, " to ", CR_Positions[2], "mm (tab ends at ", Slot_End, ")"));
echo(str("Rib Z: ", Rib_Z_Start, " to ", Rib_Z_End, "mm"));
echo(str("Coupler: ", Coupler_OD, "mm OD x ", Coupler_Len, "mm"));
echo(str("Fits Bambu P1S: ", Total_H <= 250.5 ? "YES" : "NO"));
