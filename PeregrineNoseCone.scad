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
// ADJUST THESE PARAMETERS TO FIT YOUR TUBE
// ============================================

// Body tube dimensions - MEASURE YOUR TUBE!
Peregrine_Body_OD = 101.5;  // Outside diameter of body tube
Peregrine_Body_ID = 99.0;   // Inside diameter of body tube

// Coupler dimensions - measure or estimate as Body_ID - 2.5
Peregrine_Coupler_OD = 97.5;  // What slides inside body tube

// ============================================
// NOSE CONE PARAMETERS
// ============================================

NC_Length = 300;        // Total nose cone length (3:1 ratio)
NC_Base_L = 15;         // Skirt length (for rivets)
NC_Tip_R = 8;           // Tip radius (blunted tip)
NC_Wall_T = 2.2;        // Wall thickness
NC_nRivets = 3;         // Number of rivet holes

// ============================================
// TWO-PIECE PRINTING OPTIONS
// ============================================

// Set to 0 for single piece, or body OD minus ~20mm for split
NC_Cut_d = Peregrine_Body_OD - 20;  // ~80mm split diameter

// ============================================
// RENDER SELECTION - Change this value!
// ============================================
// 0 = Test ring (print first!)
// 1 = Single piece nose cone
// 2 = Two piece - TOP (tip section)
// 3 = Two piece - BOTTOM (base/skirt section)

Render_Part = 0;

// ============================================
// RENDERING LOGIC - Don't edit below
// ============================================

if (Render_Part == 0) {
    // Test ring - print first to verify fit
    TestRing();
}

if (Render_Part == 1) {
    // Single piece (if length <= 250mm)
    BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD, 
        L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets, 
        Tip_R=NC_Tip_R, Wall_T=NC_Wall_T, Cut_d=0);
}

if (Render_Part == 2) {
    // Two piece - TOP (tip)
    BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD, 
        L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets, 
        Tip_R=NC_Tip_R, Wall_T=NC_Wall_T, 
        Cut_d=NC_Cut_d, LowerPortion=false, FillTip=true);
}

if (Render_Part == 3) {
    // Two piece - BOTTOM (base/skirt)
    BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD, 
        L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets, 
        Tip_R=NC_Tip_R, Wall_T=NC_Wall_T, 
        Cut_d=NC_Cut_d, LowerPortion=true);
}

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
