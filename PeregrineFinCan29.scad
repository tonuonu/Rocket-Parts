// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineFinCan29.scad
// by Tõnu Samuel
// Created: 2/8/2026
// Revision: 0.1.0  2/8/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// 3D printed aft section (fin can) for Peregrine rocket.
// Prints vertically on Bambu P1S (256mm max).
//
// Structure (bottom to top):
//   - Motor retainer ring at aft end
//   - Outer wall at body tube OD (100mm)
//   - Inner motor mount tube (38mm bore)
//   - Centering rings connecting MMT to outer wall
//   - Fin slots through outer wall
//   - Coupler shoulder at forward end (cardboard tube slides over)
//   - Screw holes in coupler for securing body tube
//
// Fins are separate (plywood/G10/printed), slid into slots
// and epoxied in place.
//
//  ***** History *****
// 0.1.0  2/8/2026   Initial design.
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
MMT_OD = 29.5;            // 29mm motor + 0.5mm clearance
MMT_ID = 27;              // 29mm motor mount ID

// Fins
Fin_Count = 3;
Fin_Thickness = 6.35;     // 1/4" plywood
Fin_Slot_Clearance = 0.5; // total extra
Fin_Slot_W = Fin_Thickness + Fin_Slot_Clearance;

// Fin slot geometry (from OpenRocket)
Fin_Root_L = 249;         // root chord length
Fin_Tab_H = 30;           // tab height (how deep fin goes through wall)
Fin_Tab_L = 203;          // maximized for Can_Len=245
Fin_Tab_Pos = 92;         // tab position from fin leading edge

// ========== FIN CAN DIMENSIONS ==========

// Total can length: limited by printer
Can_Len = 245;            // safe limit for Bambu P1S

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

// Motor retainer (aft end)
Retainer_Len = 8;         // retainer ring length
Retainer_Lip = 2;         // inward lip to hold motor

// Fin slot position: at aft end, fins extend behind body tube
// Tab starts right at the aft end of the can
Fin_LE_from_Aft = 0;  // fin tab starts at aft end of can

// ========== COMPUTED ==========

Fin_Angle = 360 / Fin_Count;

// Fin slot through outer wall:
// Slot starts at Fin_Tab_Pos from fin leading edge
// Slot is Fin_Tab_L long
Slot_Start = Retainer_Len;  // start just above motor retainer
Slot_End = Slot_Start + Fin_Tab_L;

// Centering ring positions (evenly spaced, avoiding slot)
// Place at aft end, middle, and forward end
CR_Positions = [
	Retainer_Len,                        // just above retainer
	Can_Len/2 - Coupler_Len/2,          // middle
	Can_Len - Coupler_Len - CR_Thickness // just below coupler
];

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
			translate([0, 0, Can_Len - Coupler_Len])
				difference(){
					cylinder(d=Body_OD, h=Coupler_Len + 50);
					translate([0, 0, -1])
						cylinder(d=Body_ID, h=Coupler_Len + 52);
				}

	// Show motor tube ghost
	if ($preview)
		color("Gray", 0.2)
			translate([0, 0, -20])
				difference(){
					cylinder(d=MMT_OD, h=Can_Len + 40);
					translate([0, 0, -1])
						cylinder(d=MMT_ID, h=Can_Len + 42);
				}
}

module FinCan(){
	difference(){
		union(){
			// Outer wall (body tube diameter)
			difference(){
				cylinder(d=Body_OD, h=Can_Len - Coupler_Len);
				translate([0, 0, -1])
					cylinder(d=Body_OD - Wall*2, h=Can_Len - Coupler_Len + 2);
			}

			// Motor mount tube
			difference(){
				cylinder(d=MMT_OD + Wall*2, h=Can_Len - Coupler_Len);
				translate([0, 0, -1])
					cylinder(d=MMT_OD, h=Can_Len - Coupler_Len + 2);
			}

			// Motor retainer ring (aft end, inward lip)
			difference(){
				cylinder(d=MMT_OD + Wall*2, h=Retainer_Len);
				translate([0, 0, -1])
					cylinder(d=MMT_ID, h=Retainer_Len + 2);
			}

			// Centering rings
			for (z=CR_Positions)
				CenteringRing(z);

			// Fin guide ribs (reinforcement along fin slots)
			for (i=[0:Fin_Count-1])
				rotate([0, 0, i * Fin_Angle])
					FinRib();

			// Coupler shoulder (forward end)
			translate([0, 0, Can_Len - Coupler_Len])
				Coupler();
		}

		// MMT bore through everything
		translate([0, 0, -1])
			cylinder(d=MMT_OD, h=Can_Len + 2);

		// Motor retainer bore (smaller, holds motor)
		// Already handled by retainer ring above

		// Fin slots through outer wall
		for (i=[0:Fin_Count-1])
			rotate([0, 0, i * Fin_Angle])
				FinSlot();

		// Coupler screw holes
		for (i=[0:nCoupler_Screws-1])
			rotate([0, 0, i * 360/nCoupler_Screws + 30])
				translate([0, 0, Can_Len - Coupler_Len/2])
					rotate([90, 0, 0])
						cylinder(d=Coupler_Screw_d, h=Body_OD, center=true);
	}
}

// Centering ring: solid disk from MMT to outer wall
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

// Fin reinforcement rib: thickened wall along each fin slot
module FinRib(){
	Rib_W = Fin_Slot_W + Wall*2;  // wall on each side of slot
	Rib_R_Inner = MMT_OD/2 + Wall - 0.1;
	Rib_R_Outer = Body_OD/2;

	translate([Rib_R_Inner, -Rib_W/2, Slot_Start - 5])
		cube([Rib_R_Outer - Rib_R_Inner,
			  Rib_W,
			  Fin_Tab_L + 10]);
}

// Fin slot: cuts through outer wall and ribs
module FinSlot(){
	// Through outer wall
	translate([Body_OD/2 - Wall - 1, -Fin_Slot_W/2, Slot_Start])
		cube([Wall + 2, Fin_Slot_W, Fin_Tab_L]);

	// Tab pocket inward (for fin tab to bond to MMT)
	translate([MMT_OD/2 - 1, -Fin_Slot_W/2, Slot_Start])
		cube([Body_OD/2 - MMT_OD/2 + 2, Fin_Slot_W, Fin_Tab_L]);
}

// Coupler shoulder
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

echo(str("Peregrine Fin Can"));
echo(str("Can length=", Can_Len, "mm"));
echo(str("Body OD=", Body_OD, "mm, MMT=", MMT_OD, "mm"));
echo(str("Fin slot: ", Fin_Slot_W, "mm wide, ", Fin_Tab_L, "mm long"));
echo(str("Slot position: ", Slot_Start, "mm to ", Slot_End, "mm from aft"));
echo(str("Coupler: ", Coupler_OD, "mm OD x ", Coupler_Len, "mm"));
echo(str("Fits Bambu P1S: ", Can_Len <= 250 ? "YES" : "NO"));
