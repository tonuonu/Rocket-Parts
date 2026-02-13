// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineEBay.scad
// by Tõnu Samuel
// Created: 2/7/2026
// Revision: 0.5.4  2/7/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Electronics Bay for CATS Vega flight computer
// in Apogee Peregrine rocket (100mm body tube)
//
// CATS Vega board: 100 x 33 x 15mm
// 3x M3 mounting holes, 60mm x 27mm pattern
// No specific orientation required (auto-detects gravity)
// Must be in radio-transparent section (fiberglass/cardboard)
//
//  ***** History *****
function PeregrineEBayRev()="PeregrineEBay 0.5.4";
echo(PeregrineEBayRev());
// 0.5.2  2/7/2026   Added shock mount support ribs at 90/270.
// 0.5.1  2/7/2026   Added Render_Part selector for STL output.
// 0.5.0  2/7/2026   Custom coupler: bolt pattern offset 30° from shock mount.
// 0.4.0  2/7/2026   Two doors at 0° and 180°, replaced AltBay54 with manual construction.
// 0.3.0  2/7/2026   Added internal reinforcement ribs and bottom bulkhead.
// 0.2.0  2/7/2026   Added integrated couplers top and bottom.
// 0.1.0  2/7/2026   First code. CATS Vega door using AltBay library.
//
// ***********************************
//  ***** for STL output *****
//
// Set Render_Part:
//   0 = Electronics bay (complete, for preview)
//   1 = Electronics bay (no doors, for printing)
//   2 = Door only (flat, for printing)

Render_Part=1;

if (Render_Part==0) PeregrineEBay(ShowDoor=true);
if (Render_Part==1) PeregrineEBay(ShowDoor=false);
if (Render_Part==2) rotate([-90,0,0]) AltDoor54(Tube_OD=Peregrine_Body_OD, IsLoProfile=false, DoorXtra_X=Peregrine_DoorXtra_X, DoorXtra_Y=Peregrine_DoorXtra_Y, ShowAlt=false);

//
// ***********************************
//  ***** Routines *****
//
//  PeregrineEBay(ShowDoor=false);
//
// ***********************************

include<TubesLib.scad>
use<AltBay.scad>
use<ElectronicsBayLib.scad>

Overlap=0.05;
IDXtra=0.2;

// Apogee Peregrine tube dimensions
Peregrine_Body_OD=101.5;
Peregrine_Body_ID=99.0;

// CATS Vega board dimensions (for reference)
CATSVega_X=33;     // width
CATSVega_Y=100;    // length
CATSVega_Z=15;     // height
CATSVega_HolesX=27;  // M3 hole spacing X
CATSVega_HolesY=60;  // M3 hole spacing Y

// Door extra dimensions
Peregrine_DoorXtra_X=4;
Peregrine_DoorXtra_Y=2;

// Door angles
Door1_a=0;         // Front door
Door2_a=180;       // Back door (opposite side)

// Coupler dimensions
Coupler_Len=15; // length of each coupler skirt

// Reinforcement rib parameters
Rib_t=2;          // rib thickness
Rib_Depth=8;       // how far ribs extend inward from tube wall
nRibs=4;           // number of ribs
Rib_StartAngle=45; // offset from 0° to avoid doors at 0° and 180°
// Rib angles: 45, 135, 225, 315 — 45° clear of doors at 0° and 180°

// Bottom bulkhead parameters
Bulkhead_t=3;      // bulkhead thickness
WireHole_d=8;      // wire pass-through hole diameter

// Coupler parameters
Coupler_nBolts=6;
Coupler_BoltInset=7.5;
ShockMount_a=90;    // shock mount at 90° (side, between doors)
BoltOffset_a=30;    // bolt pattern offset from shock mount
// With 6 bolts at 60° spacing, offset 30° from shock mount at 90°:
// Bolts at: 120, 180, 240, 300, 0, 60 — none at 90° or 270°

module PeregrineIntegratedCoupler(Tube_OD=Peregrine_Body_OD, Tube_ID=Peregrine_Body_ID,
									nBolts=6, BoltInset=7.5, HasShockMount=true,
									ShockMount_a=90, BoltOffset_a=30){
	// Custom coupler based on EB_IntegratedCoupler but with
	// independent shock mount and bolt pattern angles.
	
	IntegratedCoupler_OD=Tube_ID;
	IntegratedCoupler_ID=Tube_ID-6;
	IntegratedCoupler_Len=HasShockMount? 21:15;  // taller to fit raised shock mount
	
	Al_Tube_d=12.0;              // 12mm metric aluminum tube
	Al_Tube_Z=Al_Tube_d/2+5;    // 5mm clearance for shock cord under tube
	
	difference(){
		union(){
			translate([0,0,-5]) 
				Tube(OD=IntegratedCoupler_OD, ID=IntegratedCoupler_ID, Len=IntegratedCoupler_Len+5, myfn=$preview? 36:360);
			translate([0,0,-5]) 
				Tube(OD=Tube_OD, ID=IntegratedCoupler_ID, Len=5, myfn=$preview? 36:360);
			translate([0,0,-5+Overlap]) 
				rotate([180,0,0]) TubeStop(InnerTubeID=IntegratedCoupler_ID, OuterTubeOD=Tube_OD, myfn=$preview? 36:360);
				
			// Shock cord mount
			if (HasShockMount){
				difference(){
					intersection(){
						translate([0, 0, Al_Tube_Z]) 
							rotate([0,0,ShockMount_a]) rotate([90,0,0]) cylinder(d=Al_Tube_d+6, h=IntegratedCoupler_OD, center=true);
							
						translate([0,0,-5]) cylinder(d=IntegratedCoupler_OD-1, h=IntegratedCoupler_Len+5);
					} // intersection
					translate([0,0,Al_Tube_Z]) 
						rotate([0,0,ShockMount_a]) rotate([90,0,0]) cylinder(d=Al_Tube_d+7, h=IntegratedCoupler_ID-20, center=true);
				} // difference
			}
		} // union
		
		if (HasShockMount) 
			translate([0,0,Al_Tube_Z]) rotate([0,0,ShockMount_a]) rotate([90,0,0]) 
				cylinder(d=Al_Tube_d, h=Tube_OD, center=true);
				
		// Bolt holes — offset from shock mount
		if (nBolts>0) for (j=[0:nBolts-1]) rotate([0,0,ShockMount_a+BoltOffset_a+360/nBolts*j])
			translate([0, -Tube_OD/2-1, BoltInset]) rotate([90,0,0]) Bolt4Hole();
	} // difference
} // PeregrineIntegratedCoupler

module PeregrineRibs(Tube_Len=136){
	// Internal reinforcement ribs — rectangular radial fins
	// Full wall contact, full length including coupler zones
	
	Rib_OR=Peregrine_Body_ID/2;      // extends to tube inner wall
	Rib_IR=Rib_OR-Rib_Depth;         // inner edge
	Extend=Coupler_Len;              // extend into both coupler zones
	Total_Len=Tube_Len+Extend*2;
	
	for (i=[0:nRibs-1]){
		a=Rib_StartAngle + i*(360/nRibs);
		rotate([0,0,a])
			intersection(){
				translate([Rib_IR,-Rib_t/2,-Extend])
					cube([Rib_Depth+5, Rib_t, Total_Len]);
				cylinder(d=Peregrine_Body_ID, h=Total_Len*2, center=true, $fn=$preview? 90:360);
			} // intersection
	} // for
} // PeregrineRibs

// Shock mount support parameters
ShockRib_t=2;          // rib thickness
ShockRib_Depth=8;      // how far ribs extend inward from tube wall
IntegratedCoupler_ID=Peregrine_Body_ID-6; // 93mm, must match coupler

module ShockMountRibs(Tube_Len=136){
	// Ribs at 0° and 180° connecting top and bottom shock mounts.
	// Extends into coupler zones, trimmed around shock mount tube holes.
	
	Rib_OR=Peregrine_Body_ID/2;       // extends to tube inner wall
	Rib_IR=Rib_OR-ShockRib_Depth;
	Extend=Coupler_Len;
	Total_Len=Tube_Len+Extend*2;
	
	Al_Tube_d=12.0;              // 12mm metric aluminum tube
	Al_Tube_Z=Al_Tube_d/2+5;    // 5mm clearance for shock cord under tube
	Trim_d=Al_Tube_d+2;          // clearance around tube
	
	difference(){
		for (a=[ShockMount_a-90, ShockMount_a+90]){  // 0° and 180° — along X, matching shock mount tube
			rotate([0,0,a])
				intersection(){
					translate([Rib_IR,-ShockRib_t/2,-Extend])
						cube([ShockRib_Depth+5, ShockRib_t, Total_Len]);
					cylinder(d=Peregrine_Body_ID, h=Total_Len*2, center=true, $fn=$preview? 90:360);
				} // intersection
		} // for
		
		// Trim top shock mount tube hole
		translate([0,0,Tube_Len+Al_Tube_Z])
			rotate([0,0,ShockMount_a]) rotate([90,0,0])
				cylinder(d=Trim_d, h=Peregrine_Body_OD, center=true, $fn=36);
		
		// Trim bottom shock mount tube hole
		translate([0,0,-Al_Tube_Z])
			rotate([0,0,ShockMount_a]) rotate([90,0,0])
				cylinder(d=Trim_d, h=Peregrine_Body_OD, center=true, $fn=36);
	} // difference
} // ShockMountRibs

// BP charge cup parameters
BP_Cup_ID=15;        // cup inner diameter
BP_Cup_Depth=7;      // cup depth (fill to 4.0mm for 0.7g BP)
BP_Cup_Wall=2;       // cup wall thickness
BP_Cup_Offset=30;    // Y offset from center (away from tube and wire holes)
BP_Cup_Slot_W=2;     // e-match wire slot width
BP_Cup_Slot_H=2;     // e-match wire slot height from bottom
// 0.7g BP at ~1.0 g/cm3 = 700 mm3
// Cup volume = pi * 7.5^2 * 5 = 884 mm3
// >>> Fill to 4.0mm for 0.7g, cup is 7mm deep — extra room for e-match <<<

module PeregrineBulkhead(){
	// Bottom bulkhead — separates ejection charge from electronics
	// Includes BP charge cup on underside
	
	difference(){
		union(){
			// Main bulkhead disc (acts as cup ceiling)
			cylinder(d=Peregrine_Body_ID-IDXtra, h=Bulkhead_t, $fn=$preview? 90:360);
			
			// BP charge cup walls — C-shape with e-match wire slot
			// Load BP from below, insert e-match through slot, seal with tape
			difference(){
				translate([0,BP_Cup_Offset,-BP_Cup_Depth])
					Tube(OD=BP_Cup_ID+BP_Cup_Wall*2, ID=BP_Cup_ID, Len=BP_Cup_Depth+Overlap, myfn=$preview? 36:90);
				// E-match wire slot (C-shape opening)
				translate([-(BP_Cup_ID/2+BP_Cup_Wall+Overlap), BP_Cup_Offset-BP_Cup_Slot_W/2, -BP_Cup_Depth])
					cube([BP_Cup_ID+BP_Cup_Wall*2+Overlap*2, BP_Cup_Slot_W, BP_Cup_Slot_H]);
			} // difference
		} // union
		
		// Wire pass-through holes (through bulkhead only, above cup)
		translate([0, 15, -Overlap])
			cylinder(d=WireHole_d, h=Bulkhead_t+Overlap*2, $fn=24);
		translate([0, -15, -Overlap])
			cylinder(d=WireHole_d, h=Bulkhead_t+Overlap*2, $fn=24);
	} // difference
} // PeregrineBulkhead

module PeregrineEBay(Tube_Len=136, ShowDoor=false){
	
	// Main tube with two door cutouts
	translate([0,0,Coupler_Len]){
		difference(){
			Tube(OD=Peregrine_Body_OD, ID=Peregrine_Body_ID, Len=Tube_Len, myfn=$preview? 90:360);
			
			// Door 1 frame hole
			translate([0,0,Tube_Len/2]) rotate([0,0,Door1_a])
				Alt_BayFrameHole(Tube_OD=Peregrine_Body_OD,
					DoorXtra_X=Peregrine_DoorXtra_X, DoorXtra_Y=Peregrine_DoorXtra_Y);
			
			// Door 2 frame hole
			translate([0,0,Tube_Len/2]) rotate([0,0,Door2_a])
				Alt_BayFrameHole(Tube_OD=Peregrine_Body_OD,
					DoorXtra_X=Peregrine_DoorXtra_X, DoorXtra_Y=Peregrine_DoorXtra_Y);
		} // difference
		
		// Door 1 frame
		translate([0,0,Tube_Len/2]) rotate([0,0,Door1_a])
			Alt_BayDoorFrame(Tube_OD=Peregrine_Body_OD, Tube_ID=Peregrine_Body_ID,
				DoorXtra_X=Peregrine_DoorXtra_X, DoorXtra_Y=Peregrine_DoorXtra_Y,
				ShowDoor=ShowDoor);
		
		// Door 2 frame
		translate([0,0,Tube_Len/2]) rotate([0,0,Door2_a])
			Alt_BayDoorFrame(Tube_OD=Peregrine_Body_OD, Tube_ID=Peregrine_Body_ID,
				DoorXtra_X=Peregrine_DoorXtra_X, DoorXtra_Y=Peregrine_DoorXtra_Y,
				ShowDoor=ShowDoor);
	} // translate

	// Internal reinforcement ribs
	translate([0,0,Coupler_Len])
		PeregrineRibs(Tube_Len=Tube_Len);

	// Shock mount support ribs (90° and 270°, extend into couplers)
	translate([0,0,Coupler_Len])
		ShockMountRibs(Tube_Len=Tube_Len);

	// Bottom bulkhead (separates ejection bay below from electronics)
	translate([0,0,Coupler_Len])
		PeregrineBulkhead();

	// Top bulkhead (separates electronics from upper ejection bay)
	// Mirrored so cup faces upward into top coupler
	translate([0,0,Coupler_Len+Tube_Len])
		mirror([0,0,1]) PeregrineBulkhead();

	// Forward (top) integrated coupler
	translate([0,0,Tube_Len+Coupler_Len])
		PeregrineIntegratedCoupler(nBolts=Coupler_nBolts, BoltInset=Coupler_BoltInset,
			HasShockMount=true, ShockMount_a=ShockMount_a, BoltOffset_a=BoltOffset_a);

	// Aft (bottom) integrated coupler
	translate([0,0,Coupler_Len]) rotate([180,0,0])
		PeregrineIntegratedCoupler(nBolts=Coupler_nBolts, BoltInset=Coupler_BoltInset,
			HasShockMount=true, ShockMount_a=ShockMount_a, BoltOffset_a=BoltOffset_a);

} // PeregrineEBay
