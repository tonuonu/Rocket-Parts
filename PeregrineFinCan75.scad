// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineFinCan75.scad
// by Tõnu Samuel
// Created: 2/12/2026
// Revision: 0.1.0  2/12/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// 3D printed aft section (fin can) for L3 Peregrine rocket.
// BT137 body tube (5.38", 140.1mm OD) with 75mm motor mount.
// Prints vertically on Bambu P1S (250mm max with AMS).
// If total height exceeds P1S limit, print in two pieces and glue.
//
// Structure (bottom to top):
//   - Male threaded retainer section at aft end (protrudes aft)
//     Accepts printed retainer cup for 75mm aft closure
//   - Outer wall at body tube OD (140.1mm)
//   - Inner motor mount tube (76mm bore for 75.4mm case)
//   - Centering rings connecting MMT to outer wall
//   - Fin slots through outer wall (stop 10mm from MMT)
//   - Fin guide ribs from outer wall to MMT (solid connection)
//   - Coupler shoulder at forward end (body tube slides over)
//   - Screw holes in coupler for securing body tube
//   - Cord channel through forward centering ring
//     (tubular nylon wraps MMT, exits forward through slot)
//
// Motor tube extends forward past fin can into body tube.
// Additional centering rings above fin can support motor tube.
// 75/5120 case (602.5mm) protrudes ~400mm above fin can.
//
// Fins are separate (3D printed core + composite overlay),
// slid into slots and epoxied.
// Fin slots do NOT reach motor tube — reloadable case,
// no fin-to-motor gluing needed. Full tube around motor.
// Recovery cord wraps MMT in gap between rib tops and forward CR.
//
//  ***** Fin Construction *****
// Fins: 3D printed core (Nylon/PPS) with fiberglass or carbon
// fiber cloth + epoxy overlay. FDM-only fins are inadequate at
// transonic speeds expected on M-class motors (300-500 m/s).
// Core defines NACA 0012 airfoil shape; composite skin provides
// bending strength, shear stiffness, and flutter resistance.
//
//  ***** History *****
// 0.1.0  2/12/2026   Initial design, adapted from PeregrineFinCan.scad v0.8.0.
//                     BT137 body, 75mm MMT, scaled retainer thread.
//
// ***********************************

$fn=$preview? 72:180;
Overlap=0.05;

// ========== USER PARAMETERS ==========

// Body tube (BT137 from TubesLib.scad)
Body_OD = 140.1;          // BT137 body tube outer diameter (measured)
Body_ID = 136.8;          // BT137 body tube inner diameter (5.385" = 136.78mm)
Body_Wall = (Body_OD - Body_ID) / 2;  // ~1.65mm

// Motor mount (75mm AeroTech RMS)
// Motor case OD = 75.4mm (kATRMS_75_Case_d)
// Aft closure OD = 79.4mm (kATRMS_Aft75_d)
MMT_OD = 76.0;            // 75.4mm case + 0.6mm clearance
MMT_ID = 74;              // motor mount tube ID (not used in geometry)
Motor_L = 602.5;          // AeroTech 75/5120 case length (extends past fin can)

// Fins (same planform as PeregrineFin.scad v0.7.0)
Fin_Count = 3;
Fin_Thickness = 7.5;      // 6.35mm printed core + 2×0.5mm composite overlay
Fin_Slot_Clearance = 0.5; // total extra width in slot
Fin_Slot_W = Fin_Thickness + Fin_Slot_Clearance;

// Fin slot geometry (from PeregrineFin.scad)
Fin_Root_L = 249;         // root chord length
Fin_Tab_H = 19;           // tab height
Fin_Tab_L = 190;          // fin tab length in slot
Slot_Clearance = 1;       // extra slot length at top for insertion
Fin_Tab_Pos = 87;         // tab position from leading edge

// Gap between fin slot and MMT (full tube around motor)
Slot_Gap = 10;            // mm from MMT outer wall to slot inner edge

// ========== THREADED MOTOR RETAINER ==========
// Sized for 75mm aft closure (79.4mm OD)
// Thread bore must clear aft closure with room for retainer cup
Thread_Minor_D = 82.55;   // 3-1/4" thread root diameter
Thread_Major_D = 85.725;  // 3-3/8" thread crest diameter
Thread_Pitch = 25.4/8;    // 8 TPI = 3.175mm (coarser for larger diameter)
Thread_H = 15.875;        // 5/8" = 5 turns at 8 TPI
Thread_Duty = 0.25;       // tooth width as fraction of pitch
Thread_Chamfer = 1.0;     // lead-in chamfer at aft end

// ========== FIN CAN DIMENSIONS ==========

Body_Len = 236;           // main body section length (same as 38mm version)
// Total print height = Thread_H + Body_Len = ~252mm
// Exceeds P1S 250mm limit by ~2mm — may need slight trim or split print

// Wall thickness of printed fin can
Wall = 2.4;               // 6 perimeters at 0.4mm

// Coupler (forward end, body tube slides over this)
Coupler_OD = Body_ID - 0.6;  // snug fit inside body tube
Coupler_Len = 35;         // overlap length (longer than 38mm version for larger tube)
Coupler_Wall = 2.4;
nCoupler_Screws = 6;      // retention screws
Coupler_Screw_d = 4.2;    // #8 screw clearance (larger for L3 loads)

// Shock cord channel
Cord_Slot_a = 60;         // midway between fins (0° and 120°)
Cord_Pass_H = 16;         // ribbon passage height in ribs

// Centering rings
CR_Thickness = 5;         // ring axial thickness (thicker for larger span)
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
Rib_Margin = 3;
Rib_Z_Start = Slot_Start - Rib_Margin;
Rib_Z_End = CR_Positions[2];  // ribs touch forward CR

Total_H = Thread_H + Body_Len;

echo(str("=== PeregrineFinCan75 v0.1.0 ==="));
echo(str("Total print height: ", Total_H, "mm"));
echo(str("Body: OD=", Body_OD, "mm, ID=", Body_ID, "mm"));
echo(str("MMT bore=", MMT_OD, "mm (75.4mm case + 0.6mm clearance)"));
echo(str("Annular gap: ", (Body_OD/2 - Wall) - (MMT_OD/2 + Wall), "mm"));
echo(str("Slot inner radius: ", Slot_Inner_R, "mm (", Slot_Gap, "mm gap from MMT)"));
echo(str("Rib Z range: ", Rib_Z_Start, " to ", Rib_Z_End, "mm"));
echo(str("Forward CR at Z=", CR_Positions[2], "mm"));
echo(str("Coupler base at Z=", Coupler_Z, "mm"));
echo(str("Fin slot width: ", Fin_Slot_W, "mm (", Fin_Thickness, "mm fin + ", Fin_Slot_Clearance, "mm clearance)"));
echo(str("Thread: ", Thread_Minor_D, "/", Thread_Major_D, "mm, pitch ", Thread_Pitch, "mm, H=", Thread_H, "mm"));

if (Total_H > 250.5)
	echo(str("WARNING: Total height ", Total_H, "mm exceeds P1S limit (250mm). Split print required."));

assert(Rib_Z_End < Coupler_Z, "RIBS PROTRUDE INTO COUPLER ZONE!");

// ========== RENDER ==========

Render_Part = 0;
// 0 = Assembly preview
// 1 = Fin can for printing (full or lower half if split)
// 2 = Cross-section (verify internal features)
// 3 = Upper half for split print (if needed)

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

	// Show motor ghost (75/5120 case, extends well above fin can)
	if ($preview)
		color("Gray", 0.2)
			cylinder(d=75.4, h=Motor_L);
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

		// Fin slots (stop short of MMT)
		for (i=[0:Fin_Count-1])
			rotate([0, 0, i * Fin_Angle])
				FinSlot();

		// Ribbon passage through each rib (near top, hugs MMT surface)
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

		// Cord passage: round hole through forward CR into coupler base
		rotate([0, 0, Cord_Slot_a]){
			R_Mid = (MMT_OD/2 + Wall + Body_OD/2 - Wall) / 2;
			Hole_D = (Body_OD/2 - Wall) - (MMT_OD/2 + Wall) - 8;
			translate([R_Mid, 0,
				CR_Positions[len(CR_Positions)-1] - Overlap])
				cylinder(d=Hole_D, h=CR_Thickness + Wall + 2*Overlap);
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

module CenteringRing(z_pos){
	CR_R_Inner = MMT_OD/2 + Wall - 0.05;
	CR_R_Outer = Body_OD/2 - Wall + 0.05;

	translate([0, 0, z_pos])
		difference(){
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

module SupportWeb(){
	Web_T = 1;
	Web_R_Inner = MMT_OD/2 + Wall - 0.05;
	Web_R_Outer = Body_OD/2 - Wall + 0.05;
	Web_Z_Start = CR_Positions[0] + CR_Thickness;
	Web_Z_End = CR_Positions[len(CR_Positions)-1];
	Web_H = Web_Z_End - Web_Z_Start;

	difference(){
		translate([Web_R_Inner, -Web_T/2, Web_Z_Start])
			cube([Web_R_Outer - Web_R_Inner, Web_T, Web_H]);

		// Ribbon passage near MMT
		translate([Web_R_Inner - 1, -Web_T/2 - 1,
			Rib_Z_End - Cord_Pass_H])
			cube([8 + 1, Web_T + 2, Cord_Pass_H]);
	}
}

// ========== FIN RIB ==========

module FinRib(){
	Rib_W = Fin_Slot_W + Wall*2;
	Rib_R_Inner = MMT_OD/2 - 0.5;
	Rib_R_Outer = Body_OD/2;
	Rib_H = Rib_Z_End - Rib_Z_Start;

	// Clip to body cylinder
	intersection(){
		union(){
			// Inner zone: thin web from MMT to slot edge
			translate([Rib_R_Inner, -Wall/2, Rib_Z_Start])
				cube([Slot_Inner_R - Rib_R_Inner,
					  Wall,
					  Rib_H]);

			// Slot back wall: thin vertical plate at inner end of fin slot
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

module FinSlot(){
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
	Gusset_Depth = 8;      // slightly deeper for larger coupler
	Gusset_W = 12;
	Gusset_H = Coupler_Len/2 + Coupler_Screw_d/2 + 1;
	for (i=[0:nCoupler_Screws-1])
		rotate([0, 0, i * 360/nCoupler_Screws + 30])
			translate([Coupler_ID/2 - Gusset_Depth, -Gusset_W/2, 0])
				hull(){
					cube([Gusset_Depth, Gusset_W, 0.01]);
					translate([Gusset_Depth - 0.01, 0, Gusset_H])
						cube([0.01, Gusset_W, 0.01]);
				}
}

// ========== INFO ==========

echo(str("Fits Bambu P1S: ", Total_H <= 250.5 ? "YES" : "NO — split print and glue"));
