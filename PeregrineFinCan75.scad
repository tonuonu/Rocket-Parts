// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineFinCan75.scad
// by Tõnu Samuel
// Created: 2/12/2026
// Revision: 0.4.0  2/13/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// 3D printed aft section (fin can) for L3 Peregrine rocket.
// BT137 body tube (5.38", 140.1mm OD) with 75mm motor mount.
//
// SPLIT PRINT: Total height ~326mm, printed as two halves.
// Lower half: retainer + lower body (~171mm)
// Upper half: upper body + coupler (~155mm)
// Both halves fit Bambu P1S (250mm max with AMS).
//
// Assembly: fins span both halves, binding them structurally.
// Then fiberglass fabric + epoxy overwrap over entire assembly
// (body + fin root fillets) creates composite skin.
// 4mm carbon rods can reinforce the joint line between fins.
//
// Structure (bottom to top):
//   - Male threaded retainer section at aft end (protrudes aft)
//     Accepts printed retainer cup for 75mm aft closure
//   - Outer wall at body tube OD (140.1mm)
//   - Inner motor mount tube (76mm bore for 75.4mm case)
//   - 4 centering rings connecting MMT to outer wall
//   - Fin slots through outer wall (stop 10mm from MMT)
//     Extended to ~240mm — nearly full root chord support
//   - Fin guide ribs from outer wall to MMT (solid connection)
//   - Split joint with interlocking step at midpoint
//   - Coupler shoulder at forward end (body tube slides over)
//   - Screw holes in coupler for securing body tube
//   - Cord channel through forward centering ring
//
// Motor tube extends forward past fin can into body tube.
// 75/5120 case (602.5mm) protrudes ~280mm above fin can.
//
// Fins: 3D printed core (Nylon/PPS) with fiberglass or carbon
// fiber cloth + epoxy overlay. Core defines NACA 0012 airfoil;
// composite skin provides bending/shear/flutter resistance.
//
//  ***** History *****
// 0.1.0  2/12/2026   Initial design, adapted from PeregrineFinCan.scad v0.8.0.
// 0.2.0  2/12/2026   Extended body for full root chord support.
//                     Split print at midpoint (2 halves, ~171 + ~155mm).
//                     Interlocking step joint with alignment pins.
//                     4 centering rings (was 3).
//                     Fin tab extended to 240mm (was 190mm).
//                     Designed for GF fabric overwrap assembly.
// 0.3.0  2/12/2026   Changed to 4 fins (was 3).
//                     4 alignment pins (was 3).
//                     8 coupler screws (was 6).
//                     Cord slot angle 45° (was 60°).
//                     Rationale: better stability at equal mass,
//                     same flutter speed, stronger fin-body joint.
// 0.4.0  2/13/2026   Cut fin slots through split joint step rings.
//                     Male step (lower) and female recess (upper)
//                     were continuous, blocking fin insertion.
//
// ***********************************

$fn=$preview? 72:180;
Overlap=0.05;

// ========== USER PARAMETERS ==========

// Body tube (BT137 from TubesLib.scad)
Body_OD = 140.1;          // BT137 body tube outer diameter (measured)
Body_ID = 136.8;          // BT137 body tube inner diameter
Body_Wall = (Body_OD - Body_ID) / 2;  // ~1.65mm

// Motor mount (75mm AeroTech RMS)
// Motor case OD = 75.4mm (kATRMS_75_Case_d)
// Aft closure OD = 79.4mm (kATRMS_Aft75_d)
MMT_OD = 76.0;            // 75.4mm case + 0.6mm clearance
MMT_ID = 74;              // motor mount tube ID
Motor_L = 602.5;          // AeroTech 75/5120 case length

// Fins (same planform as PeregrineFin.scad v0.7.0)
Fin_Count = 4;
Fin_Thickness = 7.5;      // 6.35mm printed core + 2×0.5mm composite overlay
Fin_Slot_Clearance = 0.5; // total extra width in slot
Fin_Slot_W = Fin_Thickness + Fin_Slot_Clearance;

// Fin slot geometry
Fin_Root_L = 249;         // root chord length (from PeregrineFin.scad)
Fin_Tab_L = 240;          // fin tab length in slot (nearly full root chord)
Slot_Clearance = 1;       // extra slot length at top for insertion
Fin_Tab_H = 19;           // tab height
Fin_Tab_Pos = 87;         // tab position from leading edge

// Gap between fin slot and MMT (full tube around motor)
Slot_Gap = 10;            // mm from MMT outer wall to slot inner edge

// ========== THREADED MOTOR RETAINER ==========
// Sized for 75mm aft closure (79.4mm OD)
Thread_Minor_D = 82.55;   // 3-1/4" thread root diameter
Thread_Major_D = 85.725;  // 3-3/8" thread crest diameter
Thread_Pitch = 25.4/8;    // 8 TPI = 3.175mm
Thread_H = 15.875;        // 5/8" = 5 turns at 8 TPI
Thread_Duty = 0.25;       // tooth width as fraction of pitch
Thread_Chamfer = 1.0;     // lead-in chamfer at aft end

// ========== FIN CAN DIMENSIONS ==========

Body_Len = 310;           // extended for full root chord fin support
// Total print height = Thread_H + Body_Len = ~326mm — requires split print

// Wall thickness of printed fin can
Wall = 2.4;               // 6 perimeters at 0.4mm

// Coupler (forward end, body tube slides over this)
Coupler_OD = Body_ID - 0.6;  // snug fit inside body tube
Coupler_Len = 35;         // overlap length
Coupler_Wall = 2.4;
nCoupler_Screws = 8;      // 2 per fin quadrant
Coupler_Screw_d = 4.2;    // #8 screw clearance

// Shock cord channel
Cord_Slot_a = 45;         // midway between fins (360/4/2)
Cord_Pass_H = 16;         // ribbon passage height in ribs

// Centering rings
CR_Thickness = 5;         // ring axial thickness
nCR = 4;                  // 4 centering rings for longer body

// ========== SPLIT PRINT ==========

// Split at midpoint of body section
Split_Z = Thread_H + Body_Len / 2;  // ~170.9mm

// Interlocking step joint:
// Lower half has male ring (protrudes up)
// Upper half has matching female recess
// Fins spanning both halves provide primary shear connection
Joint_Step_H = 5;         // height of interlocking step
Joint_Step_D = 2;         // radial depth of step (inward from OD)
Joint_Clearance = 0.3;    // fit clearance on step

// Alignment pin holes (for carbon rod alignment pins)
nAlign_Pins = 4;          // between fins (one per quadrant)
Align_Pin_d = 4.2;        // 4mm carbon rod + 0.2mm clearance
Align_Pin_Depth = 10;     // depth into each half

// ========== COMPUTED ==========

Fin_Angle = 360 / Fin_Count;

// Slot inner radius: 10mm gap from MMT wall
Slot_Inner_R = MMT_OD/2 + Wall + Slot_Gap;

// Z layout:
Slot_Start = Thread_H + CR_Thickness;  // above first centering ring
Slot_End = Slot_Start + Fin_Tab_L;

// Coupler base Z position
Coupler_Z = Thread_H + Body_Len - Coupler_Len;

// Centering ring positions (4 rings, evenly distributed)
CR_Positions = [
	Thread_H,                                          // aft (at junction)
	Thread_H + (Body_Len - Coupler_Len) * 1/3,       // lower third
	Thread_H + (Body_Len - Coupler_Len) * 2/3,       // upper third
	Thread_H + Body_Len - Coupler_Len - CR_Thickness  // forward (below coupler)
];

// Rib extends past slot bottom, and up to forward CR for rigidity
Rib_Margin = 3;
Rib_Z_Start = Slot_Start - Rib_Margin;
Rib_Z_End = CR_Positions[3];  // ribs touch forward CR

Total_H = Thread_H + Body_Len;
Lower_H = Split_Z;
Upper_H = Total_H - Split_Z;

echo(str("=== PeregrineFinCan75 v0.4.0 ==="));
echo(str("Total height: ", Total_H, "mm (split print required)"));
echo(str("Split at Z=", Split_Z, "mm"));
echo(str("Lower half: ", Lower_H, "mm"));
echo(str("Upper half: ", Upper_H, "mm"));
echo(str("Body: OD=", Body_OD, "mm, ID=", Body_ID, "mm, Len=", Body_Len, "mm"));
echo(str("MMT bore=", MMT_OD, "mm"));
echo(str("Annular gap: ", (Body_OD/2 - Wall) - (MMT_OD/2 + Wall), "mm"));
echo(str("Slot inner radius: ", Slot_Inner_R, "mm"));
echo(str("Fin slot: ", Fin_Slot_W, "mm W x ", Fin_Tab_L, "mm L"));
echo(str("Slot Z: ", Slot_Start, " to ", Slot_End, "mm"));
echo(str("CR positions: ", CR_Positions));
echo(str("Rib Z: ", Rib_Z_Start, " to ", Rib_Z_End, "mm"));
echo(str("Coupler base at Z=", Coupler_Z, "mm"));

// Alignment pin radial position (midway in annular gap, between fins)
Align_Pin_R = (MMT_OD/2 + Wall + Body_OD/2 - Wall) / 2;

assert(Lower_H <= 250, str("LOWER HALF TOO TALL: ", Lower_H, "mm"));
assert(Upper_H <= 250, str("UPPER HALF TOO TALL: ", Upper_H, "mm"));
assert(Rib_Z_End < Coupler_Z, "RIBS PROTRUDE INTO COUPLER ZONE!");
assert(Slot_End <= CR_Positions[3], str("FIN SLOT EXTENDS PAST FORWARD CR: slot end=", Slot_End, " CR=", CR_Positions[3]));

// ========== RENDER ==========

Render_Part = 1;
// 0 = Assembly preview (full, with split line shown)
// 1 = Lower half for printing (retainer + lower body)
// 2 = Upper half for printing (upper body + coupler)
// 3 = Cross-section (verify internal features)
// 4 = Full fin can (for reference, not printable)

if (Render_Part == 0) FinCanAssembly();
if (Render_Part == 1) LowerHalf();
if (Render_Part == 2) translate([0, 0, -Split_Z]) UpperHalf();
if (Render_Part == 3) difference(){
	FinCanAssembly();
	rotate([0, 0, Cord_Slot_a])
		translate([0, 0, -1]) cube([Body_OD, Body_OD, Total_H + 2]);
}
if (Render_Part == 4) FinCan();

// ========== SPLIT MODULES ==========

module LowerHalf(){
	difference(){
		union(){
			// Full fin can cut at split line
			intersection(){
				FinCan();
				cylinder(d=Body_OD + 10, h=Split_Z);
			}
			// Male step ring (protrudes above split line)
			translate([0, 0, Split_Z - Overlap])
				difference(){
					cylinder(d=Body_OD - Joint_Step_D*2, h=Joint_Step_H + Overlap);
					translate([0, 0, -1])
						cylinder(d=Body_OD - Joint_Step_D*2 - Wall*2, h=Joint_Step_H + 2);
				}
			// Male step on MMT (inner alignment)
			translate([0, 0, Split_Z - Overlap])
				difference(){
					cylinder(d=MMT_OD + Wall*2 + Joint_Step_D*2, h=Joint_Step_H + Overlap);
					translate([0, 0, -1])
						cylinder(d=MMT_OD, h=Joint_Step_H + 2);
				}
		}
		// MMT bore
		translate([0, 0, -1])
			cylinder(d=MMT_OD, h=Split_Z + Joint_Step_H + 2);

		// Alignment pin holes (blind, into top face)
		for (i=[0:nAlign_Pins-1])
			rotate([0, 0, i * Fin_Angle + Fin_Angle/2])
				translate([Align_Pin_R, 0, Split_Z + Joint_Step_H - Align_Pin_Depth])
					cylinder(d=Align_Pin_d, h=Align_Pin_Depth + 1);

		// Fin slots through male step ring (so fins can span both halves)
		for (i=[0:Fin_Count-1])
			rotate([0, 0, i * Fin_Angle])
				translate([Slot_Inner_R, -Fin_Slot_W/2, Split_Z - 1])
					cube([Body_OD/2 - Slot_Inner_R + 2, Fin_Slot_W,
						  Joint_Step_H + 2]);
	}
}

module UpperHalf(){
	difference(){
		union(){
			// Full fin can above split line
			intersection(){
				FinCan();
				translate([0, 0, Split_Z])
					cylinder(d=Body_OD + 10, h=Upper_H + 1);
			}
		}
		// Female recess for outer step
		translate([0, 0, Split_Z - Overlap])
			difference(){
				cylinder(d=Body_OD - Joint_Step_D*2 + Joint_Clearance*2,
						 h=Joint_Step_H + Overlap*2);
				translate([0, 0, -1])
					cylinder(d=Body_OD - Joint_Step_D*2 - Wall*2 - Joint_Clearance*2,
							 h=Joint_Step_H + 2);
			}

		// Female recess for inner (MMT) step
		translate([0, 0, Split_Z - Overlap])
			difference(){
				cylinder(d=MMT_OD + Wall*2 + Joint_Step_D*2 + Joint_Clearance*2,
						 h=Joint_Step_H + Overlap*2);
				translate([0, 0, -1])
					cylinder(d=MMT_OD + Joint_Clearance*2, h=Joint_Step_H + 2);
			}

		// MMT bore
		translate([0, 0, Split_Z - 1])
			cylinder(d=MMT_OD, h=Upper_H + 2);

		// Alignment pin holes (blind, into bottom face)
		for (i=[0:nAlign_Pins-1])
			rotate([0, 0, i * Fin_Angle + Fin_Angle/2])
				translate([Align_Pin_R, 0, Split_Z - 1])
					cylinder(d=Align_Pin_d, h=Align_Pin_Depth + 1);

		// Fin slots through female recess zone (so fins can span both halves)
		for (i=[0:Fin_Count-1])
			rotate([0, 0, i * Fin_Angle])
				translate([Slot_Inner_R, -Fin_Slot_W/2, Split_Z - Joint_Step_H - 1])
					cube([Body_OD/2 - Slot_Inner_R + 2, Fin_Slot_W,
						  Joint_Step_H + 2]);
	}
}

// ========== ASSEMBLY ==========

module FinCanAssembly(){
	FinCan();

	// Show split line
	if ($preview)
		color("Red", 0.3)
			translate([0, 0, Split_Z])
				difference(){
					cylinder(d=Body_OD + 5, h=0.5);
					translate([0, 0, -1])
						cylinder(d=MMT_OD - 5, h=3);
				}

	// Show body tube ghost
	if ($preview)
		color("Tan", 0.2)
			translate([0, 0, Coupler_Z])
				difference(){
					cylinder(d=Body_OD, h=Coupler_Len + 50);
					translate([0, 0, -1])
						cylinder(d=Body_ID, h=Coupler_Len + 52);
				}

	// Show motor ghost (75/5120 case)
	if ($preview)
		color("Gray", 0.2)
			cylinder(d=75.4, h=Motor_L);

	// Show alignment pins
	if ($preview)
		for (i=[0:nAlign_Pins-1])
			rotate([0, 0, i * Fin_Angle + Fin_Angle/2])
				translate([Align_Pin_R, 0, Split_Z - Align_Pin_Depth])
					color("DarkGray") cylinder(d=4, h=Align_Pin_Depth*2);
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

		// Cord passage through forward CR
		rotate([0, 0, Cord_Slot_a]){
			R_Mid = (MMT_OD/2 + Wall + Body_OD/2 - Wall) / 2;
			Hole_D = (Body_OD/2 - Wall) - (MMT_OD/2 + Wall) - 8;
			translate([R_Mid, 0,
				CR_Positions[len(CR_Positions)-1] - Overlap])
				cylinder(d=Hole_D, h=CR_Thickness + Wall + 2*Overlap);
		}

		// Thread lead-in chamfer at aft end
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

			// Slot back wall
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
	Slot_Top = CR_Positions[3];
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
	Gusset_Depth = 8;
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

echo(str("Thread: ", Thread_Minor_D, "/", Thread_Major_D, "mm, pitch ", Thread_Pitch, "mm, H=", Thread_H, "mm"));
echo(str("Joint: step=", Joint_Step_D, "mm deep x ", Joint_Step_H, "mm tall, clearance=", Joint_Clearance, "mm"));
echo(str("Alignment: ", nAlign_Pins, " pins, ", Align_Pin_d, "mm holes at R=", Align_Pin_R, "mm, depth=", Align_Pin_Depth, "mm"));
echo(str("Lower half fits P1S: ", Lower_H <= 250 ? "YES" : "NO"));
echo(str("Upper half fits P1S: ", Upper_H <= 250 ? "YES" : "NO"));
