// ***********************************
// Project: 3D Printed Rocket
// Filename: Rocket60.scad
// for Rocket 60 (60mm body, camera nosecone)
// by Tõnu Samuel
// Created: 2026-08-13
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Designed for Bambu P1S (256x256x256mm build volume, 250mm usable Z).
// Every printable part is selected with Render_Part below.
//
// Spec: docs/superpowers/specs/2026-08-13-rocket60-design.md
//
// ***********************************

include<R60Lib.scad>

// ============================================
// RENDER SELECTION - change this value!
// ============================================
//  0 = Test ring (PRINT THIS FIRST)
//  1 = Neck
//  2 = E-bay tube
//  3 = Chute bay tube
//  4 = E-bay forward bulkhead
//  5 = E-bay aft bulkhead
//  6 = Vega sled
//  7 = Access door
//  8 = Bayonet ring
//  9 = Fin can
// 10 = Fin
// 11 = Motor retainer
// 12 = Motor spacer
Render_Part = 0;

// ============================================
// PARTS
// ============================================

// Print this FIRST. It gauges three fits on one 10mm part:
//   1. flange OD flush against the nosecone base (no step, either way)
//   2. the 3x M3 bolt circle and its clocking against the camera inserts
//   3. the coupler spigot inside a printed body tube
// If any of the three is wrong, nothing downstream is worth printing.
module R60_TestRing(){
    H_flange = 4;
    H_spigot = 6;
    difference(){
        union(){
            cylinder(d=R60_Body_OD, h=H_flange);
            translate([0,0,H_flange-Overlap])
                cylinder(d=R60_Coupler_OD, h=H_spigot+Overlap);
        }
        // Open centre: the camera harness passes through here in the real
        // neck, so the gauge shares the same clear bore.
        translate([0,0,-Overlap])
            cylinder(d=28, h=H_flange+H_spigot+Overlap*2);
        R60_CameraBoltPattern(){
            translate([0,0,-Overlap])
                cylinder(d=R60_Cam_Bolt_d, h=H_flange+H_spigot+Overlap*2);
            translate([0,0,-Overlap])
                cylinder(d=R60_Cam_Cbore_d, h=R60_Cam_Cbore_h+Overlap);
        }
    }
} // R60_TestRing

// The camera assembly fills the nosecone bore and sits flush with its base
// plane, so the neck cannot have a spigot - it is a butt joint. The three
// M3x10 SHCS pull it up into the camera's heat-set inserts; those screws
// and the flange face are the whole joint.
//
// Load path: the shock cord anchors on the E-BAY AFT BULKHEAD, never here.
// These three screws only ever carry the nose section's own inertia.
module R60_Neck(){
    Flange_T = 5;      // gives ~5mm thread engagement in a 5.7mm insert
    Skirt_L  = 19;
    Bore_d   = 28;     // camera harness passes through
    difference(){
        union(){
            cylinder(d=R60_Body_OD, h=Flange_T);
            translate([0,0,Flange_T-Overlap])
                cylinder(d=R60_Coupler_OD, h=Skirt_L+Overlap);
        }
        translate([0,0,-Overlap])
            cylinder(d=Bore_d, h=Flange_T+Skirt_L+Overlap*2);
        // Thin the skirt so it is a tube, not a slug.
        translate([0,0,Flange_T])
            cylinder(d=R60_Coupler_OD-2*R60_Wall_T, h=Skirt_L+Overlap);
        R60_CameraBoltPattern(){
            translate([0,0,-Overlap])
                cylinder(d=R60_Cam_Bolt_d, h=Flange_T+Overlap*2);
            translate([0,0,-Overlap])
                cylinder(d=R60_Cam_Cbore_d, h=R60_Cam_Cbore_h+Overlap);
        }
    }
} // R60_Neck

// ============================================
// DISPATCH
// ============================================
if (Render_Part==0) R60_TestRing();
if (Render_Part==1) R60_Neck();
