// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineFin.scad
// by Tõnu Samuel
// Created: 2/8/2026
// Revision: 0.5.0  2/12/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Subsonic trapezoidal fin for Peregrine fin can.
// NACA 0012 symmetric airfoil cross-section.
//
// Printed standing on trailing edge so each layer is
// an airfoil cross-section — smooth surfaces off printer.
//
// Mounted orientation:
//   X = chord (LE=0, TE=chord)
//   Y = span (body surface=0, tip=Span)
//   Z = thickness (centered)
//
//  ***** History *****
// 0.1.0  2/8/2026   Initial.
// 0.2.0  2/8/2026   NACA airfoil attempt.
// 0.3.0  2/8/2026   Fixed axes, proper airfoil loft.
// 0.4.0  2/9/2026   Post-test-print: Body_OD=101.5, shorter tab
//                    (slot stops 10mm from MMT), tab shifted 5mm
//                    from trailing edge (unprintable thin section).
// 0.5.0  2/12/2026  Add 2× 2.2mm rod channels at 20% and 60% chord,
//                    centered (Z=0), 100mm apart at root, 36mm at tip.
//                    For optional 2mm carbon rods or epoxy fill.
//
// ***********************************

$fn=$preview? 36:90;

// ========== FIN CAN PARAMETERS ==========

Body_OD = 101.5;          // match fin can (was 100)
MMT_OD = 38.5;            // match fin can bore
Wall = 2.4;               // fin can wall thickness
Slot_Gap = 10;            // gap between slot and MMT
Fin_Slot_L = 190;         // match fin can

// ========== FIN PARAMETERS ==========

Fin_T = 6.35;             // max thickness at root

// Tab
Slot_Inner_R = MMT_OD/2 + Wall + Slot_Gap;
Tab_H = Body_OD/2 - Slot_Inner_R;  // ~19mm (slot stops short of MMT)
Tab_L = Fin_Slot_L;

// Planform
Root_L = 249;              // original Peregrine root chord
Tip_L = 90;               // tip chord
Span = 114;               // original Peregrine span
Sweep = 120;              // gentle LE sweep

// NACA airfoil resolution
NACA_N = 60;               // points per side

// Rod channels (optional 2mm carbon rod or epoxy reinforcement)
Rod_Chan_D = 2.2;           // 2mm rod + 0.2mm clearance
Rod_Chan_Fwd = 0.20;        // forward channel at 20% local chord
Rod_Chan_Aft = 0.60;        // aft channel at 60% local chord
// Both at Z=0 (centerline) — bridges layer boundaries spanwise
// Root spacing: 100mm, tip spacing: 36mm

// ========== RENDER ==========

Render_Part = 0;
// 0 = Fin as mounted
// 1 = Print orientation

if (Render_Part == 0) PeregrineFin();
if (Render_Part == 1) PrintLayout();

module PrintLayout(){
	// Stand on trailing edge, rotated diagonally on plate
	Diag_Angle = atan((Tab_H + Span) / Root_L);
	rotate([0, 0, Diag_Angle])
		rotate([0, 90, 0])
			PeregrineFin();
}

// ========== FIN ==========

module PeregrineFin(){
	difference(){
		union(){
			// Tab: flat slab
			// Tab shifted 5mm from trailing edge (slicer can't print thin TE)
			translate([Root_L - Tab_L - 5, -Tab_H, -Fin_T/2])
				cube([Tab_L, Tab_H + 0.01, Fin_T]);

			// Airfoil body: lofted from root to tip
			FinLoft();
		}

		// Rod channels — two straight tunnels from tab base to tip
		RodChannels();
	}
}

// Two reinforcement channels at 20% and 60% local chord, Z=0
// Spread chord-wise to bridge layer boundaries across the fin
// Accessible from tab base for rod insertion
module RodChannels(){
	for (frac = [Rod_Chan_Fwd, Rod_Chan_Aft]){
		// Root end (extends through tab for insertion access)
		x_root = frac * Root_L;
		y_root = -Tab_H;

		// Tip end (follows local chord fraction)
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

// Loft NACA airfoil from root to tip
// Uses hull between pairs of adjacent cross-section polygons
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

// One airfoil cross-section at span fraction f (0=root, 1=tip)
// Cross-section is in XZ plane, thin slab in Y
module SpanSection(f){
	chord = Root_L * (1-f) + Tip_L * f;
	y_pos = f * Span;
	x_off = f * Sweep;
	// Taper thickness toward tip
	t = Fin_T * (1 - f * 0.3);

	translate([x_off, y_pos, 0])
		rotate([90, 0, 0])
			linear_extrude(height=0.01)
				NACA_Profile(chord, t);
}

// NACA symmetric airfoil profile in XY plane
// X = chord direction, Y = thickness direction
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

// ========== INFO ==========

echo(str("Peregrine Fin v0.5.0"));
echo(str("Rod channels: 2× ", Rod_Chan_D, "mm dia at ", Rod_Chan_Fwd*100, "% and ", Rod_Chan_Aft*100, "% chord, Z=0"));
echo(str("Root=", Root_L, "mm, Tip=", Tip_L, "mm, Span=", Span, "mm"));
echo(str("Tab=", Tab_L, "x", Tab_H, "mm"));
echo(str("Thickness=", Fin_T, "mm (root t/c=", round(Fin_T/Root_L*1000)/10, "%)"));
echo(str("Sweep=", Sweep, "mm"));
Diag = sqrt(Root_L*Root_L + (Tab_H+Span)*(Tab_H+Span));
echo(str("Print diagonal=", round(Diag*10)/10, "mm — Fits P1S: ",
	Diag <= 362 ? "YES" : "NO"));
