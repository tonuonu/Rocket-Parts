// ***********************************
// Project: 3D Printed Rocket
// Filename: CameraDoor.scad
// by Tõnu Samuel
// Created: 2/8/2026
// Revision: 0.6.0  2/8/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Camera observation door for Peregrine ebay.
// Replaces one altimeter door with a tilted camera module.
// Camera looks outward AND downward toward tail to capture
// rocket body, fins, and ground during flight.
//
// Door frame coordinates:
//   X = circumferential
//   Y = radial: negative = outward, 0 = tube center
//   Z = axial: +Z = nose, -Z = tail
//
//  ***** History *****
// 0.1-0.5          Various iterations.
// 0.6.0  2/8/2026  Clean rewrite, direct coordinates.
//
// ***********************************

include<TubesLib.scad>
use<DoorLib.scad>
use<CameraAssembly.scad>

$fn=$preview? 36:90;
Overlap=0.05;

// === Peregrine tube ===
Peregrine_Body_OD=101.5;
Peregrine_Body_ID=99.0;

// === Door dimensions ===
Peregrine_DoorXtra_X=4;
Peregrine_DoorXtra_Y=2;
Door_X=38.2+Peregrine_DoorXtra_X;     // 42.2
Door_Y=91.5+14+Peregrine_DoorXtra_Y;  // 107.5
Door_t=3.0;

Door_Outer_R=Peregrine_Body_OD/2;           // 50.75
Door_Inner_R=Peregrine_Body_OD/2 - Door_t;  // 47.75

// === Camera tilt ===
Camera_Tilt=50;  // degrees from perpendicular, toward tail

// === Camera dimensions (from CameraAssembly.scad) ===
Cam_PCB=26;
Cam_PCB_t=1.6;
Cam_Holder_X=24;
Cam_Holder_Z=14;
Cam_Flange_Z=2;
Cam_Lens_Barrel=12;
Cam_Lens_d=14;
Cam_PCB_HoleInset=2;
Cam_PCB_HoleSpacing=Cam_PCB - 2*Cam_PCB_HoleInset; // 22mm
Cam_H=Cam_PCB_t + Cam_Holder_Z + Cam_Flange_Z + Cam_Lens_Barrel;

// === Lens placement ===
Lens_Hole_d=16;
Lens_Proud=7;             // mm lens tip protrudes beyond body OD
Lens_Z_Offset=-10;        // lens hole shifted toward tail

// === Lens tip target position in door frame ===
Lens_Tip_Y = -Door_Outer_R - Lens_Proud;  // -57.75
Lens_Tip_Z = Lens_Z_Offset;               // -10

// === Camera rotation ===
// Camera local: +Z = lens direction (from PCB toward lens tip)
// We want camera +Z to point outward(-Y) and toward tail(-Z).
//
// rotate([Tilt,0,0]) rotate([90,0,0]):
//   First rotate 90° around X: camera +Z → -Y (outward)
//   Then rotate Tilt around X: -Y tilts toward -Z (tail)
//   Result: camera +Z points (0, -cos(T), -sin(T))
//
// Camera origin (PCB center) position computed so lens tip
// lands at target:
//   Lens is at (0,0,Cam_H) in camera local.
//   After rotation: (0, -Cam_H*cos(T), -Cam_H*sin(T)) from origin.
//   So origin = lens_tip - rotated_lens_offset
Cam_Origin_Y = Lens_Tip_Y + Cam_H*cos(Camera_Tilt);
Cam_Origin_Z = Lens_Tip_Z + Cam_H*sin(Camera_Tilt);

// === Standoff parameters ===
Standoff_d=6;
Standoff_H=3;
Standoff_Hole_d=1.6;
Standoff_Hole_Depth=8;

// === Ramp ===
Ramp_W=Cam_PCB + 6;       // 32mm, width along X
Taper_Nose=10;
Taper_Tail=12;

// === FPC cable slot ===
Cable_W=16;
Cable_H=2;

// === Render control ===
Render_Part=0;
// 0 = Assembly preview
// 1 = Door for printing

if (Render_Part==0) CameraDoorAssembly();
if (Render_Part==1) rotate([-90,0,0]) CameraDoor();

// ============================================================
// Camera placement: puts CameraAssembly() at correct position
// ============================================================
module CamPlace(){
	translate([0, Cam_Origin_Y, Cam_Origin_Z])
		rotate([Camera_Tilt, 0, 0])
			rotate([90, 0, 0])
				children();
}

// PCB corner hole pattern (camera local frame)
module CamPCBHoles(){
	HoleR=Cam_PCB_HoleSpacing/2;
	for (x=[-HoleR, HoleR])
		for (y=[-HoleR, HoleR])
			translate([x, y, 0])
				children();
}

// ============================================================
// Assembly preview
// ============================================================
module CameraDoorAssembly(){
	CameraDoor();

	if ($preview)
		color("Yellow", 0.3)
			CamPlace()
				CameraAssembly();
}

// ============================================================
// Camera door
// ============================================================
module CameraDoor(){
	difference(){
		union(){
			// Door shell
			Door(Door_X=Door_X, Door_Y=Door_Y, Door_t=Door_t,
				Tube_OD=Peregrine_Body_OD, HasSixBolts=true, HasBoltHoles=false);

			// Camera ramp
			CameraRamp();
		}

		// Lens bore along camera axis
		CamPlace()
			translate([0, 0, -10])
				cylinder(d=Lens_Hole_d, h=Cam_H+20);

		// Door mounting bolts
		DoorBoltPattern(Door_X=Door_X, Door_Y=Door_Y,
			Tube_OD=Peregrine_Body_OD, HasSixBolts=true)
				Bolt4ClearHole();

		// M2 tap holes at PCB corners
		CamPlace()
			CamPCBHoles()
				translate([0, 0, -Standoff_Hole_Depth])
					cylinder(d=Standoff_Hole_d, h=Standoff_Hole_Depth+Overlap);

		// Camera body clearance through ramp
		CamPlace()
			translate([0, 0, Cam_PCB_t - 1])
				cylinder(d=Cam_Holder_X+1, h=Cam_H);

		// FPC cable slot (exits inward toward tube center)
		CamPlace()
			translate([-Cable_W/2, -Cable_H/2, -15])
				cube([Cable_W, Cable_H, 15+Overlap]);
	}
}

// ============================================================
// Camera ramp - built directly in door frame coordinates
//
// Key points in door frame:
//   Lens tip:    Y=-57.75, Z=-10
//   PCB center:  Y=Cam_Origin_Y, Z=Cam_Origin_Z (inside tube)
//   Door inner:  Y=-47.75
//
// The ramp connects the door inner surface to the PCB
// mounting face (standoffs).
// ============================================================
module CameraRamp(){
	intersection(){
		// Tube interior: nothing beyond inner door surface
		translate([0, 0, -Door_Y/2-1])
			cylinder(d=Door_Inner_R*2, h=Door_Y+2, $fn=$preview? 90:360);

		union(){
			// --- Main ramp body ---
			// Hull from a thin base at door surface (lens end)
			// to the thick PCB support platform (inward end)

			// Standoff base positions in door frame
			// PCB holes are at Z=0 in camera local
			// Standoffs extend from Z=-Standoff_H to Z=0 in camera local
			// Standoff base in camera local: (x,y,-Standoff_H)
			// Need these in door frame... use the known camera origin.
			//
			// Camera axis direction (unit): (0, -cos(T), -sin(T))
			// Camera local X stays as X
			// Camera local Y after transform... complex.
			// Simpler: just use hull between door-surface rect and PCB-area rect.

			// Ramp base: thin rectangle at door inner surface near lens hole
			// (where the lens bore exits the door interior)
			Base_Z = Lens_Z_Offset;  // -10
			Base_Y = -Door_Inner_R;  // -47.75
			Base_Thick = 3;

			// PCB platform: rectangle at PCB location
			// PCB center in door frame: (0, Cam_Origin_Y, Cam_Origin_Z)
			// The standoffs sit under the PCB, so platform top is
			// at Cam_Origin_Y - small offset
			Plat_Y = Cam_Origin_Y;        // further inside tube
			Plat_Z = Cam_Origin_Z;        // further toward nose
			Plat_Thick = 5;

			hull(){
				// Base at door surface, lens area
				translate([-Ramp_W/2, Base_Y, Base_Z - Ramp_W/3])
					cube([Ramp_W, Base_Thick, Ramp_W/1.5]);

				// Platform at PCB area
				translate([-Ramp_W/2, Plat_Y - Plat_Thick, Plat_Z - Ramp_W/3])
					cube([Ramp_W, Plat_Thick, Ramp_W/1.5]);
			}

			// --- M2 standoffs ---
			CamPlace()
				CamPCBHoles()
					translate([0, 0, -Standoff_H])
						cylinder(d=Standoff_d, h=Standoff_H);

			// --- Nose taper (smooth entry from +Z side) ---
			hull(){
				translate([-Ramp_W/2, Base_Y, Base_Z + Ramp_W/3 - 0.1])
					cube([Ramp_W, Base_Thick, 0.1]);

				translate([-Ramp_W/2, Plat_Y - Plat_Thick, Plat_Z + Ramp_W/3 - 0.1])
					cube([Ramp_W, Plat_Thick, 0.1]);

				// Thin nose edge
				translate([0, Base_Y + 1,
				           max(Base_Z, Plat_Z) + Ramp_W/3 + Taper_Nose])
					rotate([0, 90, 0])
						cylinder(d=1, h=Ramp_W*0.6, center=true);
			}

			// --- Tail taper (toward -Z) ---
			hull(){
				translate([-Ramp_W/2, Base_Y, Base_Z - Ramp_W/3])
					cube([Ramp_W, Base_Thick, 0.1]);

				// Thin tail edge
				translate([0, Base_Y + 0.5,
				           Base_Z - Ramp_W/3 - Taper_Tail])
					rotate([0, 90, 0])
						cylinder(d=0.5, h=Ramp_W*0.4, center=true);
			}
		}
	}
}
