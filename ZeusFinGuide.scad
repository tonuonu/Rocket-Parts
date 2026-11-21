// ***********************************
// Project: 3D Printed Rocket
// Filename: ZeusFinGuide.scad
// by Tõnu Samuel
// Created: 11/9/2026
// Revision: 0.1.0  11/9/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// External fin alignment guide for the LOC Precision Zeus 2.26" kit
// (4 through-the-wall fins, 1/8" thick). It works like the LOC fin
// alignment guide: a collar slides along the booster from one end and
// stops against the fins, and holds all four fins radial and 90 degrees
// apart while the glue sets.
//
//   collar  - hugs the tube over its full height, so it sits square
//   slots   - one per fin, open at the far end and at the outside, so
//             any fin span or sweep fits
//   flange  - a 6 mm band at the closed end stops on the fin root and
//             ties neighbouring guide walls together
//
// Use one from the forward end (stops on the fin leading edges) and,
// if there is tube left behind the fins, a second from the aft end
// (stops on the trailing edges). Print flange down, no supports.
//
// The slot is widened next to the tube so a root glue bead does not
// glue the guide to the rocket. Wax or tape the slot faces anyway.
//
// MEASURE BEFORE PRINTING: tube OD and fin thickness with calipers,
// then set Tube_OD and Fin_T below. Print Render_Part = 2 first (a
// 10 mm test ring with all four slots) to check both fits quickly.
//
// Sources: LOC Precision Zeus 2.26" page (fin thickness 1/8",
// diameter 2.26", through-the-wall fins). Tube OD 2.26" is the nominal
// LOC size, not a measured value.
//
//  ***** History *****
// 0.1.0  11/9/2026  First version.
// 0.2.0  11/21/2026 Split guide (Render_Part 3) for the mid-body fins:
//                   two halves bolt together around the tube, so it can
//                   be put on anywhere along the body.
//
// ***********************************

Render_Part = 1;    // 1 = guide, 2 = fit test ring, 3 = split guide (mid fins)

$fn = $preview ? 90 : 240;

// ========== USER PARAMETERS ==========

Tube_OD   = 57.40;  // 2.26" nominal - measure yours
Fin_T     = 3.175;  // 1/8" plywood - measure yours
Fin_Count = 4;

Tube_Clearance = 0.40;  // diametral; collar must slide, not rattle
Fin_Clearance  = 0.35;  // total across the slot

Guide_H   = 40;     // collar height = guided length along the fin root
Guide_L   = 35;     // guide wall length, outward from the tube surface
Flange_T  = 6;      // closed-end band that stops on the fin root
Collar_W  = 3;      // collar wall
Wall_T    = 3;      // guide wall
Glue_Relief = 1.5;  // extra slot width each side next to the tube

// Split guide: the two halves are clamped by M3 screws through a block
// on each split line, halfway between two fins.
Split_Block_W  = 16;    // across the split line, 8 mm per half
Split_Block_R  = 47;    // block reaches out to this radius
Split_Screw_R  = 40;    // screw axis radius
Split_Screw_Z  = [12, 30];
Split_Screw_D  = 3.4;   // M3 clearance
Split_Head_D   = 6.4;   // M3 socket head counterbore
Split_Head_Depth = 3;
Split_Nut_AF   = 5.7;   // M3 nut 5.5 across flats + clearance
Split_Nut_Depth  = 3;
Split_Gap      = 10;    // between the halves on the print bed

// ========== COMPUTED ==========

Bore_D  = Tube_OD + Tube_Clearance;
Collar_D = Bore_D + 2*Collar_W;
Slot_W  = Fin_T + Fin_Clearance;
Outer_R = Tube_OD/2 + Guide_L;
Overlap = 0.01;

assert(Wall_T >= 1.2, "guide wall under FDM minimum");
assert(Slot_W/2 + Glue_Relief < Slot_W/2 + Wall_T,
       "glue relief would cut the guide walls off the collar");

echo(str("Bore ", Bore_D, "  slot ", Slot_W, "  overall D ",
         2*Outer_R, "  height ", Guide_H));

// ========== MODULES ==========

module Each_Fin(){
    for (i = [0:Fin_Count-1]) rotate([0, 0, i*360/Fin_Count]) children();
}

// Print orientation: flange on the bed (z = 0). In use the flange is
// the end that stops against the fins.
module Fin_Guide(h = Guide_H, l = Guide_L, flange = Flange_T){
    r_out = Tube_OD/2 + l;
    difference(){
        union(){
            cylinder(d = Collar_D, h = h);
            // Flange sectors tie the guide walls of neighbouring fins.
            cylinder(r = r_out, h = flange);
            // Guide walls, flush with the outer edge of the flange.
            Each_Fin() for (s = [-1, 1])
                translate([Bore_D/2, s > 0 ? Slot_W/2 : -Slot_W/2 - Wall_T, 0])
                    cube([r_out - Bore_D/2, Wall_T, h]);
        }
        translate([0, 0, -Overlap]) cylinder(d = Bore_D, h = h + 2*Overlap);
        Each_Fin(){
            // Fin slot: open at the outside and at the far (top) end.
            // Through the flange only outside the collar, so the collar
            // band is what stops on the fin root.
            translate([Collar_D/2, -Slot_W/2, -Overlap])
                cube([r_out, Slot_W, h + 2*Overlap]);
            translate([0, -Slot_W/2, flange])
                cube([r_out + 1, Slot_W, h]);
            // Glue relief next to the tube, through the collar wall.
            translate([0, -Slot_W/2 - Glue_Relief, flange])
                cube([Collar_D/2 + Overlap, Slot_W + 2*Glue_Relief, h]);
        }
    }
}

// Short print (10 mm tall, 12 mm walls): checks the bore slides on the real tube and the
// slot takes a real fin before committing to the full guide.
module Fit_Test(){
    Fin_Guide(h = 10, l = 12, flange = 3);
}

// Split guide for fins in the middle of the body. The split lines run
// halfway between fins (45 degrees off the fins with four fins), so each
// half carries whole fin slots. Close it around the tube just ahead of
// the fins, tighten the screws until the halves touch, then slide it on
// to the fins like the one-piece guide. Same bore: it slides, not clamps.
Split_A = 180/Fin_Count;   // split plane angle, between fins

module Split_Rotate(){ rotate([0, 0, Split_A]) children(); }

module Split_Guide_Whole(){
    difference(){
        union(){
            Fin_Guide();
            // Clamp blocks on both ends of the split line.
            Split_Rotate() for (s = [-1, 1]) rotate([0, 0, s > 0 ? 0 : 180])
                translate([Collar_D/2 - 1, -Split_Block_W/2, 0])
                    cube([Split_Block_R - Collar_D/2 + 1, Split_Block_W, Guide_H]);
        }
        translate([0, 0, -Overlap]) cylinder(d = Bore_D, h = Guide_H + 2*Overlap);
        Split_Rotate() for (s = [-1, 1]) rotate([0, 0, s > 0 ? 0 : 180])
            for (z = Split_Screw_Z) translate([Split_Screw_R, 0, z]){
                // Screw across the split line (along local y).
                rotate([90, 0, 0]) cylinder(d = Split_Screw_D,
                    h = Split_Block_W + 2, center = true, $fn = 32);
                // Head counterbore on +y, nut trap on -y. The hex has a
                // corner up so its roof prints without support.
                translate([0, Split_Block_W/2 - Split_Head_Depth, 0])
                    rotate([-90, 0, 0])
                        cylinder(d = Split_Head_D, h = Split_Head_Depth + 1, $fn = 48);
                translate([0, -Split_Block_W/2 + Split_Nut_Depth, 0])
                    rotate([90, 0, 0]) rotate([0, 0, 30])
                        cylinder(d = Split_Nut_AF/cos(30), h = Split_Nut_Depth + 1, $fn = 6);
            }
    }
}

// side = +1 or -1: the half on that side of the split plane.
module Split_Guide_Half(side){
    intersection(){
        Split_Guide_Whole();
        Split_Rotate() translate([-100, side > 0 ? 0 : -100, -1])
            cube([200, 100, Guide_H + 2]);
    }
}

// Both halves on the bed, flange down, split faces apart.
module Split_Guide_Print(){
    for (s = [-1, 1]) Split_Rotate() translate([0, s*Split_Gap/2, 0])
        rotate([0, 0, -Split_A]) Split_Guide_Half(s);
}

// ========== RENDER ==========

if (Render_Part == 1) Fin_Guide();
if (Render_Part == 2) Fit_Test();
if (Render_Part == 3) Split_Guide_Print();
if (Render_Part == 4) Split_Guide_Whole();   // assembled, for checks
