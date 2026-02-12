// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineFin75.scad
// by Tõnu Samuel
// Created: 2/12/2026
// Revision: 0.1.0  2/12/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Composite fin CORE for L3 Peregrine rocket.
// Same planform as PeregrineFin.scad (L2 version) but adapted for:
//   - BT137 body tube (140.1mm OD)
//   - 75mm MMT (76mm bore in fin can)
//   - Extended tab (240mm) for PeregrineFinCan75 slot
//   - Thicker core (7mm) for carbon fiber overlay
//   - Larger rod channels (4.2mm for 4mm CF rods)
//
// CONSTRUCTION: This is the 3D printed CORE only.
// After printing, overlay with carbon fiber cloth + epoxy:
//   - 2× 0.75mm CF cloth layers each side = 1.5mm total overlay
//   - Final fin thickness: ~8.5mm
//   - CF skin provides bending stiffness and flutter resistance
//
// The printed core serves as:
//   1. Mandrel/form for wet layup
//   2. Shear web between CF face sheets (sandwich beam)
//   3. Airfoil shape definition
//
// Rod channels for 4mm carbon fiber rods:
//   - At 25% and 60% local chord, Z=0 centerline
//   - Provide spanwise stiffness before CF overlay cures
//   - Also serve as split-print alignment (same as PeregrineFin v0.7.0)
//
// Print orientation:
//   Split print at 60% chord line (same as L2 fin v0.7.0).
//   Each half stands on cut face for along-layer bending strength.
//   Rod at cut line provides alignment during glue-up.
//
//  ***** History *****
// 0.1.0  2/12/2026   Initial, adapted from PeregrineFin.scad v0.7.0.
//                     BT137 body, 75mm MMT, 240mm tab, 7mm core,
//                     4.2mm rod channels for 4mm CF rods.
//
// ***********************************

$fn=$preview? 36:90;

// ========== FIN CAN PARAMETERS ==========
// Must match PeregrineFinCan75.scad v0.2.0

Body_OD = 140.1;          // BT137 body tube outer diameter
MMT_OD = 76.0;            // 75mm motor mount bore
Wall = 2.4;               // fin can wall thickness
Slot_Gap = 10;            // gap between slot and MMT
Fin_Slot_L = 240;         // fin can slot length (Tab_L in fin can)

// ========== FIN PARAMETERS ==========

Fin_T = 7.0;              // core max thickness at root (was 6.35 for L2)
                          // + ~1.5mm CF overlay → ~8.5mm total

// Tab
Slot_Inner_R = MMT_OD/2 + Wall + Slot_Gap;  // same formula as fin can
Tab_H = Body_OD/2 - Slot_Inner_R;           // ~19.85mm
Tab_L = Fin_Slot_L;                          // 240mm (was 190 for L2)

// Planform (same as PeregrineFin v0.7.0 — proven aerodynamics)
Root_L = 249;             // root chord
Tip_L = 90;               // tip chord
Span = 137;               // exposed span beyond body
Sweep = 120;              // LE sweep distance

// NACA airfoil
NACA_N = 60;

// Rod channels (4mm CF rods + 0.2mm clearance)
Rod_Chan_D = 4.2;         // 4mm rod + 0.2mm clearance (was 2.2 for L2)
Rod_Chan_Fwd = 0.25;      // forward channel at 25% local chord
Rod_Chan_Aft = 0.60;      // aft channel at 60% local chord
// Both at Z=0 (centerline)
// Root spacing: 87mm, tip spacing: 31mm

// ========== RENDER ==========

Render_Part = 0;
// 0 = Fin as mounted (full core)
// 1 = Print: full fin on trailing edge
// 2 = Print: forward half (LE side) on cut face
// 3 = Print: aft half (TE side) on cut face

if (Render_Part == 0) MountedView();
if (Render_Part == 1) PrintLayoutFull();
if (Render_Part == 2) PrintLayoutFwd();
if (Render_Part == 3) PrintLayoutAft();

module PrintLayoutFull(){
	Diag_Angle = atan((Tab_H + Span) / Root_L);
	rotate([0, 0, Diag_Angle])
		rotate([0, 90, 0])
			PeregrineFin75();
}

Cut_Angle = atan2(
	(Sweep + Rod_Chan_Aft * Tip_L) - (Rod_Chan_Aft * Root_L),
	Span + Tab_H);

module PrintLayoutFwd(){
	rotate([0, 0, -Cut_Angle])
		rotate([0, -90, 0])
			translate([-Rod_Chan_Aft * Root_L, 0, 0])
				FinForwardHalf();
}

module PrintLayoutAft(){
	rotate([0, 0, -Cut_Angle])
		rotate([0, 90, 0])
			translate([-Rod_Chan_Aft * Root_L, 0, 0])
				FinAftHalf();
}

module MountedView(){
	PeregrineFin75();
	// Ghost body tube (BT137)
	%translate([Root_L/2, -Body_OD/2, 0])
		rotate([0, 90, 0])
			difference(){
				cylinder(d=Body_OD, h=Root_L + 60, center=true, $fn=72);
				cylinder(d=Body_OD - 2*Wall, h=Root_L + 62, center=true, $fn=72);
			}
	// Ghost motor tube
	%translate([Root_L/2, -Body_OD/2, 0])
		rotate([0, 90, 0])
			difference(){
				cylinder(d=MMT_OD + 2*Wall, h=Root_L + 60, center=true, $fn=72);
				cylinder(d=MMT_OD, h=Root_L + 62, center=true, $fn=72);
			}
}

// ========== FIN ==========

module PeregrineFin75(){
	difference(){
		union(){
			// Tab: flat slab
			// Tab shifted 5mm from trailing edge
			translate([Root_L - Tab_L - 5, -Tab_H, -Fin_T/2])
				cube([Tab_L, Tab_H + 0.01, Fin_T]);

			// Airfoil body: lofted from root to tip
			FinLoft();
		}

		// Rod channels
		RodChannels();
	}
}

module RodChannels(){
	for (frac = [Rod_Chan_Fwd, Rod_Chan_Aft]){
		x_root = frac * Root_L;
		y_root = -Tab_H;
		x_tip = Sweep + frac * Tip_L;
		y_tip = Span;

		hull(){
			translate([x_root, y_root, 0])
				sphere(d=Rod_Chan_D, $fn=24);
			translate([x_tip, y_tip, 0])
				sphere(d=Rod_Chan_D, $fn=24);
		}
	}
}

module FinLoft(){
	N_Span = 20;
	for (i=[0:N_Span-1]){
		f1 = i / N_Span;
		f2 = (i + 1) / N_Span;
		hull(){
			SpanSection(f1);
			SpanSection(f2);
		}
	}
}

module SpanSection(f){
	chord = Root_L * (1-f) + Tip_L * f;
	y_pos = f * Span;
	x_off = f * Sweep;
	t = Fin_T * (1 - f * 0.3);

	translate([x_off, y_pos, 0])
		rotate([90, 0, 0])
			linear_extrude(height=0.01)
				NACA_Profile(chord, t);
}

module NACA_Profile(chord, max_t){
	tc = max_t / chord;
	pts_upper = [for (i=[0:NACA_N])
		let(x = i/NACA_N)
		let(yt = (tc/0.2) * (0.2969*sqrt(x) - 0.1260*x
			- 0.3516*pow(x,2) + 0.2843*pow(x,3) - 0.1036*pow(x,4)))
		[x * chord, yt * chord]
	];
	pts_lower = [for (i=[NACA_N:-1:1])
		let(x = i/NACA_N)
		let(yt = (tc/0.2) * (0.2969*sqrt(x) - 0.1260*x
			- 0.3516*pow(x,2) + 0.2843*pow(x,3) - 0.1036*pow(x,4)))
		[x * chord, -yt * chord]
	];
	polygon(concat(pts_upper, pts_lower));
}

// ========== SPLIT HALVES ==========

module CutVolumeFwd(){
	x_root = Rod_Chan_Aft * Root_L;
	x_tip = Sweep + Rod_Chan_Aft * Tip_L;
	big = 500;
	linear_extrude(height=big, center=true)
		polygon([
			[-big, -Tab_H - 1],
			[x_root, -Tab_H - 1],
			[x_tip, Span + 1],
			[-big, Span + 1]
		]);
}

module CutVolumeAft(){
	x_root = Rod_Chan_Aft * Root_L;
	x_tip = Sweep + Rod_Chan_Aft * Tip_L;
	big = 500;
	linear_extrude(height=big, center=true)
		polygon([
			[x_root, -Tab_H - 1],
			[big, -Tab_H - 1],
			[big, Span + 1],
			[x_tip, Span + 1]
		]);
}

module FinForwardHalf(){
	intersection(){
		PeregrineFin75();
		CutVolumeFwd();
	}
}

module FinAftHalf(){
	intersection(){
		PeregrineFin75();
		CutVolumeAft();
	}
}

// ========== INFO ==========

echo(str("PeregrineFin75 v0.1.0 — COMPOSITE CORE"));
echo(str("Body: BT137 (", Body_OD, "mm OD), MMT: ", MMT_OD, "mm"));
echo(str("Planform: Root=", Root_L, " Tip=", Tip_L, " Span=", Span, " Sweep=", Sweep));
echo(str("Core thickness: ", Fin_T, "mm (+ ~1.5mm CF overlay → 8.5mm total)"));
echo(str("Tab: ", Tab_L, "mm x ", Tab_H, "mm"));
echo(str("Rod channels: 2× ", Rod_Chan_D, "mm at ", Rod_Chan_Fwd*100, "% and ", Rod_Chan_Aft*100, "% chord"));
echo(str("Slot inner R: ", Slot_Inner_R, "mm (gap=", Slot_Gap, "mm from MMT)"));

Area = 0.5 * (Root_L + Tip_L) * Span;
echo(str("Planform area: ", Area, " mm² (", Area/100, " cm²)"));

Diag = sqrt(Root_L*Root_L + (Tab_H+Span)*(Tab_H+Span));
echo(str("Print diagonal: ", round(Diag*10)/10, "mm — Fits P1S: ",
	Diag <= 362 ? "YES" : "NO"));

echo(str("Split: cut at ", Rod_Chan_Aft*100, "% chord"));
echo(str("  Fwd half root: ", Rod_Chan_Aft*Root_L, "mm"));
echo(str("  Aft half root: ", (1-Rod_Chan_Aft)*Root_L, "mm"));
