// ***********************************
// Project: 3D Printed Rocket
// Filename: FinJig.scad
// by Tõnu Samuel
// Created: 2/8/2026
// Revision: 0.7.0  2/8/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Parametric fin alignment jig for model rockets.
// Inner part fits INSIDE body tube. Fin guide walls pass
// through body tube wall slots outward to an outer
// containment ring at fin tip radius.
//
// Structure (radially from center):
//   1. MMT bore (motor mount tube passes through)
//   2. Inner centering rings + cylinder (inside body tube)
//   3. Fin guide walls (pass through tube wall)
//   4. Outer containment ring (at fin tip radius)
//
//  ***** History *****
// 0.1-0.6          Various iterations.
// 0.7.0  2/8/2026  Inside tube + outer ring for fin tips.
//
// ***********************************

$fn=$preview? 72:180;

// ========== USER PARAMETERS ==========

// Body tube
Tube_OD = 100;
Tube_ID = 98;

// Motor mount tube outer diameter
MMT_OD = 38;

// Number of fins
Fin_Count = 3;

// Fin thickness
Fin_Thickness = 3.0;
Fin_Clearance = 0.5;
Fin_Slot_W = Fin_Thickness + Fin_Clearance;

// Fin span (from tube outer surface to fin tip)
Fin_Span = 80;

// Jig axial height
Jig_Height = 30;

// ========== JIG PARAMETERS ==========

Ring_H = 6;                // end ring height
Wall = 3;                  // wall thickness
Guide_Wall = 3;            // fin guide wall thickness
Tube_Clearance = 0.4;      // inner part to tube ID
MMT_Clearance = 1.0;       // bore to MMT

// Outer ring
Outer_Ring_Wall = 3;

// Lightening
Lighten = true;
Lighten_Margin = 6;

// ========== COMPUTED ==========

// Inner part: fits inside body tube
Inner_OD = Tube_ID - Tube_Clearance;         // ~97.6
Inner_ID = Inner_OD - Wall*2;                // ~91.6
MMT_Bore = MMT_OD + MMT_Clearance*2;         // 40
MMT_R = MMT_Bore/2;

// Outer ring: beyond body tube
Outer_Ring_IR = Tube_OD/2 + Fin_Span - Outer_Ring_Wall;
Outer_Ring_OR = Tube_OD/2 + Fin_Span;

Fin_Angle = 360 / Fin_Count;

// Guide walls span from MMT to outer ring
Guide_Start_R = MMT_R;
Guide_End_R = Outer_Ring_OR;

// ========== RENDER ==========

FinJig();

// ========== MODULES ==========

module FinJig(){
	difference(){
		union(){
			// --- Inner part (inside body tube) ---

			// Bottom end ring
			translate([0, 0, 0])
				cylinder(d=Inner_OD, h=Ring_H);

			// Top end ring
			translate([0, 0, Jig_Height - Ring_H])
				cylinder(d=Inner_OD, h=Ring_H);

			// Inner centering cylinder between rings
			translate([0, 0, Ring_H])
				difference(){
					cylinder(d=Inner_OD, h=Jig_Height - Ring_H*2);
					translate([0, 0, -1])
						cylinder(d=Inner_ID, h=Jig_Height - Ring_H*2 + 2);
				}

			// --- Outer containment ring (outside tube) ---
			difference(){
				cylinder(r=Outer_Ring_OR, h=Jig_Height);
				translate([0, 0, -1])
					cylinder(r=Outer_Ring_IR, h=Jig_Height + 2);
			}

			// --- Fin guide walls (MMT to outer ring) ---
			for (i=[0:Fin_Count-1])
				rotate([0, 0, i * Fin_Angle])
					FinGuide();
		}

		// MMT bore
		translate([0, 0, -1])
			cylinder(d=MMT_Bore, h=Jig_Height + 2);

		// Fin slots (cut through everything except guide walls)
		for (i=[0:Fin_Count-1])
			rotate([0, 0, i * Fin_Angle])
				FinSlot();

		// Lightening cutouts in inner rings
		if (Lighten)
			LighteningCutouts();
	}
}

// Guide walls: two parallel walls flanking each fin slot
// Run continuously from MMT to outer ring
module FinGuide(){
	Len = Guide_End_R - Guide_Start_R;

	for (side=[-1, 1]){
		Y_Off = side * Fin_Slot_W/2 + (side > 0 ? 0 : -Guide_Wall);

		translate([Guide_Start_R, Y_Off, 0])
			cube([Len, Guide_Wall, Jig_Height]);
	}
}

// Fin slot — cuts inner part only. Narrow passage through outer ring.
module FinSlot(){
	// Slot from MMT to outer ring inner wall
	translate([Guide_Start_R - 1, -Fin_Slot_W/2, -1])
		cube([Outer_Ring_IR - Guide_Start_R + 2,
			  Fin_Slot_W,
			  Jig_Height + 2]);

	// Narrow fin passage through outer ring only
	translate([Outer_Ring_IR - 1, -Fin_Slot_W/2, -1])
		cube([Outer_Ring_Wall + 2,
			  Fin_Slot_W,
			  Jig_Height + 2]);
}

// Lightening cutouts in inner end rings
module LighteningCutouts(){
	for (i=[0:Fin_Count-1])
		rotate([0, 0, i * Fin_Angle + Fin_Angle/2]){
			R_Inner = MMT_R + Lighten_Margin;
			R_Outer = Inner_ID/2 - Lighten_Margin;

			Slot_Half_Angle = atan((Fin_Slot_W/2 + Guide_Wall + Lighten_Margin) /
								  (R_Outer));
			Cut_Angle = Fin_Angle - 2*Slot_Half_Angle;

			if (R_Outer > R_Inner + 4 && Cut_Angle > 8){
				// Bottom ring
				translate([0, 0, -1])
					linear_extrude(Ring_H + 2)
						CutoutShape(R_Inner, R_Outer, Cut_Angle);

				// Top ring
				translate([0, 0, Jig_Height - Ring_H - 1])
					linear_extrude(Ring_H + 2)
						CutoutShape(R_Inner, R_Outer, Cut_Angle);
			}
		}
}

module CutoutShape(R_Inner, R_Outer, Angle){
	R_Mid = (R_Inner + R_Outer) / 2;
	W = R_Outer - R_Inner;

	hull(){
		rotate([0, 0, -Angle/2 + 3])
			translate([R_Mid, 0])
				circle(d=W - 2);

		rotate([0, 0, Angle/2 - 3])
			translate([R_Mid, 0])
				circle(d=W - 2);
	}
}

echo(str("Fin Jig: ", Fin_Count, " fins"));
echo(str("Inner part OD=", Inner_OD, "mm (inside ", Tube_ID, "mm tube)"));
echo(str("MMT bore=", MMT_Bore, "mm"));
echo(str("Outer ring OD=", Outer_Ring_OR*2, "mm (fin span=", Fin_Span, "mm)"));
echo(str("Height=", Jig_Height, "mm"));
