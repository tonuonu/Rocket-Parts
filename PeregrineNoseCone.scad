// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineNoseCone.scad
// for Apogee Peregrine (100mm body tube)
// Created: 2025-01-19
// Units: mm
// ***********************************
//
// Designed for Bambu P1S (256x256x256mm build volume)
// Two-piece printing supported for lengths > 250mm
//
// ***********************************

include<NoseCone.scad>

// ============================================
// BODY TUBE — measure yours and adjust
// ============================================
Peregrine_Body_OD    = 101.5;   // outside diameter of body tube
Peregrine_Body_ID    = 99.0;    // inside diameter of body tube
Peregrine_Coupler_OD = 97.1;    // shell ID = Body_OD - 2*Wall_T

// ============================================
// NOSE CONE — 550mm exposed, 5.42:1 ogive
// ============================================
// Exposed height = NC_Base_L + NC_Length - X0 + NC_Tip_R.
// The +NC_Tip_R term matters: Tip_Z in BluntOgiveNoseCone is the tip
// SPHERE CENTRE, not the apex. NC_Length=574.55 gives exactly 550.
NC_Length  = 574.55;
NC_Base_L  = 15;
NC_Tip_R   = 8;
NC_Wall_T  = 2.2;
NC_nRivets = 0;   // shoulder is glued via its spigot, not pinned

// Slice planes. Cut_d is a DIAMETER; the module derives Z from it.
Cut1_d = 92.85;   // -> Z = 183.33
Cut2_d = 63.66;   // -> Z = 366.67
Cut1_Z = 183.33;  // clip plane for the middle slice

// ============================================
// RENDER SELECTION — change this value!
// ============================================
// 0 = Test ring (print first!)
// 1 = Shoulder + bulkhead + parachute anchor
// 2 = Bottom slice
// 3 = Middle slice
// 4 = Top slice (filled tip)
// 5 = Guide ring, lower
// 6 = Guide ring, upper
Render_Part = 0;

// ============================================
// PARTS
// ============================================
module NC_Slice_Bottom(){
    BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD,
        L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets,
        Tip_R=NC_Tip_R, Wall_T=NC_Wall_T,
        Cut_d=Cut1_d, LowerPortion=true);
} // NC_Slice_Bottom

module NC_Slice_Middle(){
    // Everything below cut 2 (with its gluing flange), clipped above cut 1.
    // The clean lower cut slides over the bottom slice's flange.
    intersection(){
        BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD,
            L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets,
            Tip_R=NC_Tip_R, Wall_T=NC_Wall_T,
            Cut_d=Cut2_d, LowerPortion=true);

        translate([0,0,Cut1_Z])
            cylinder(d=Peregrine_Body_OD+2, h=NC_Length, $fn=$preview? 90:360);
    } // intersection
} // NC_Slice_Middle

module NC_Slice_Top(){
    BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD,
        L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets,
        Tip_R=NC_Tip_R, Wall_T=NC_Wall_T,
        Cut_d=Cut2_d, LowerPortion=false, FillTip=true);
} // NC_Slice_Top

// ============================================
// RENDERING LOGIC — don't edit below
// ============================================
if (Render_Part == 2) NC_Slice_Bottom();
if (Render_Part == 3) NC_Slice_Middle();
if (Render_Part == 4) NC_Slice_Top();

module TestRing() {
    // Test piece to verify tube dimensions
    // OD should match body tube OD (flush fit, no step)
    // ID is the shoulder that sits inside the body tube
    difference() {
        cylinder(d=Peregrine_Body_OD, h=15, $fn=90);
        translate([0,0,-0.1]) cylinder(d=Peregrine_Coupler_OD, h=15.2, $fn=90);
    }
    // TEST: Place on top of body tube - should be flush (same OD)
    // TEST: The ID hole should accept the coupler tube (or fit inside body tube)
}

// ============================================
// PRINT NOTES
// ============================================
//
// 1. Set Render_Part = 0, print test ring, verify fit
// 2. Adjust Peregrine_Body_OD and Peregrine_Coupler_OD if needed
// 3. Set Render_Part = 2, export STL, print top
// 4. Set Render_Part = 3, export STL, print bottom
// 5. Glue halves with CA or epoxy
//
// Print settings: 3 perimeters, 15% infill, PETG/ASA
//
// ***********************************
