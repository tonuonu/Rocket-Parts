// ***********************************
// Project: VRdaemon Camera Assembly
// Filename: CameraAssembly.scad
// by Tõnu Samuel
// Created: 2/8/2026
// Revision: 0.1.0
// Units: mm
// ***********************************
//  ***** Notes *****
//
// 3D reference model of camera assembly:
//   - 6mm f/1.8 M12 lens
//   - MIPI-LHLD12 M12 S-mount lens holder (VK000057)
//   - Square PCB with M2 corner mounting holes
//
// All dimensions parametric — adjust when actual parts arrive.
// Exact LHLD12 dimensions not in public datasheet text,
// using standard M12 holder measurements.
//
//  ***** History *****
// 0.1.0  2/8/2026   Initial model.
//
// ***********************************

$fn=$preview? 36:90;

// === Lens parameters (6mm f/1.8 M12) ===
Lens_Thread_d=12;        // M12x0.5 thread OD
Lens_Body_d=14;          // lens barrel OD
Lens_Body_Len=12;        // barrel length above thread
Lens_Thread_Len=6;       // thread engagement length
Lens_Front_d=10;         // front glass diameter
Lens_Front_Depth=1;      // glass recess depth

// === Lens holder parameters (MIPI-LHLD12 / VK000057) ===
// Standard M12 plastic S-mount holder, 20mm hole spacing
Holder_X=24;             // body length (along hole axis)
Holder_Y=17;             // body width
Holder_Z=14;             // body height
Holder_HoleSpacing=20;   // M2 mounting hole spacing
Holder_HoleDia=2.2;      // M2 clearance
Holder_Thread_d=12.5;    // M12x0.5 threaded bore (clearance)
Holder_Flange_d=16;      // top flange around thread
Holder_Flange_Z=2;       // flange height

// === PCB parameters ===
PCB_Size=26;             // square PCB side length (>Holder_X)
PCB_t=1.6;               // PCB thickness (standard FR4)
PCB_HoleInset=2;         // hole center from edge
PCB_HoleDia=2.2;         // M2 clearance holes
PCB_Color="green";

// === Assembly ===
// PCB at Z=0, lens holder sits on top, lens screws in from top

Render_Part=0;
// 0 = Complete assembly
// 1 = Lens only
// 2 = Holder only
// 3 = PCB only

if (Render_Part==0) CameraAssembly();
if (Render_Part==1) M12_Lens();
if (Render_Part==2) M12_LensHolder();
if (Render_Part==3) CameraPCB();

module M12_Lens(){
	// Simplified M12 6mm f/1.8 lens
	color("DimGray"){
		// Thread section (screws into holder)
		cylinder(d=Lens_Thread_d, h=Lens_Thread_Len);
		
		// Main barrel
		translate([0,0,Lens_Thread_Len])
			cylinder(d=Lens_Body_d, h=Lens_Body_Len);
	}
	// Front element
	translate([0,0,Lens_Thread_Len+Lens_Body_Len-Lens_Front_Depth])
		color("LightBlue", 0.5)
			cylinder(d=Lens_Front_d, h=Lens_Front_Depth+0.01);
}

module M12_LensHolder(){
	// MIPI-LHLD12 style M12 S-mount lens holder
	color("Black"){
		difference(){
			union(){
				// Main body
				translate([-Holder_X/2, -Holder_Y/2, 0])
					cube([Holder_X, Holder_Y, Holder_Z]);
				
				// Top flange ring
				translate([0,0,Holder_Z])
					cylinder(d=Holder_Flange_d, h=Holder_Flange_Z);
			}
			
			// Thread bore (all the way through)
			translate([0,0,-0.1])
				cylinder(d=Holder_Thread_d, h=Holder_Z+Holder_Flange_Z+0.2);
			
			// Mounting screw holes (2x, along X axis)
			for (x=[-Holder_HoleSpacing/2, Holder_HoleSpacing/2])
				translate([x, 0, -0.1])
					cylinder(d=Holder_HoleDia, h=Holder_Z+0.2);
		}
	}
}

module CameraPCB(){
	// Square PCB with M2 corner holes
	color(PCB_Color){
		difference(){
			// PCB body
			translate([-PCB_Size/2, -PCB_Size/2, 0])
				cube([PCB_Size, PCB_Size, PCB_t]);
			
			// Corner mounting holes
			for (x=[-PCB_Size/2+PCB_HoleInset, PCB_Size/2-PCB_HoleInset])
				for (y=[-PCB_Size/2+PCB_HoleInset, PCB_Size/2-PCB_HoleInset])
					translate([x, y, -0.1])
						cylinder(d=PCB_HoleDia, h=PCB_t+0.2);
			
			// Sensor window (center hole for light path)
			translate([0, 0, -0.1])
				cylinder(d=8, h=PCB_t+0.2);
		}
	}
}

module CameraAssembly(){
	// PCB at bottom
	CameraPCB();
	
	// Lens holder on top of PCB
	translate([0, 0, PCB_t])
		M12_LensHolder();
	
	// Lens screwed into holder from top
	// Thread starts inside holder bore, barrel sticks up
	translate([0, 0, PCB_t + Holder_Z + Holder_Flange_Z - Lens_Thread_Len])
		M12_Lens();
}
