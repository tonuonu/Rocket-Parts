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
Peregrine_Body_OD = 100.5;  // Outside diameter of body tube
Peregrine_Body_ID = 99.0;   // Inside diameter of body tube

// Coupler dimensions - measure or estimate as Body_ID - 2.5
Peregrine_Coupler_OD = 96.5;  // What slides inside body tube

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

// Which part to render
Render_Lower = false;   // true = bottom part, false = top part

// ============================================
// RENDER SELECTION
// ============================================

// Uncomment ONE of these to render:

// Option 1: Single piece (if length <= 250mm)
// BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD, 
//     L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets, 
//     Tip_R=NC_Tip_R, Wall_T=NC_Wall_T, Cut_d=0);

// Option 2: Two piece - TOP (tip)
BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD, 
    L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets, 
    Tip_R=NC_Tip_R, Wall_T=NC_Wall_T, 
    Cut_d=NC_Cut_d, LowerPortion=false, FillTip=true);

// Option 3: Two piece - BOTTOM (base/skirt)
// BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD, 
//     L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets, 
//     Tip_R=NC_Tip_R, Wall_T=NC_Wall_T, 
//     Cut_d=NC_Cut_d, LowerPortion=true);

// ============================================
// TEST RING - Print this first to check fit!
// ============================================

// Uncomment to render a test ring
// TestRing();

module TestRing() {
    // Quick test piece to verify tube dimensions
    difference() {
        cylinder(d=Peregrine_Body_OD, h=15, $fn=90);
        translate([0,0,-0.1]) cylinder(d=Peregrine_Coupler_OD, h=15.2, $fn=90);
    }
    // Should: slide into body tube (OD), coupler slides into it (ID)
}

// ============================================
// PRINT NOTES
// ============================================
//
// 1. Print test ring first to verify dimensions
// 2. Print nose cone tip-down (no supports needed)
// 3. For two-piece: glue halves with CA or epoxy
// 4. Recommended: 3 perimeters, 15% infill
// 5. Material: PETG or ASA for outdoor use
//
// Estimated print times (P1S, 0.2mm layer):
// - Test ring: ~15 min
// - Upper section: ~4-5 hours  
// - Lower section: ~3-4 hours
//
// ***********************************
