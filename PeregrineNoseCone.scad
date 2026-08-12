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
// SHOULDER — stepped, printed, all-in-one
// ============================================
// Body enters the tube (99.0 ID), spigot enters the shell (97.1 ID).
// Both clearances are 0.4mm diametral.
Shoulder_L         = 100;    // length inside the body tube
// Derived from the body tube ID so a re-measured tube (line 20) can never
// silently produce an interference fit here: 0.4mm diametral clearance.
Shoulder_OD        = Peregrine_Body_ID - 0.4;
Shoulder_Spigot_L  = 15;     // length inside the nosecone skirt
Shoulder_Spigot_OD = 96.7;
Shoulder_Bulk_T    = 4;      // bulkhead thickness, carries the anchor

// ============================================
// GUIDE RINGS — keep the strap off the shell
// ============================================
// OD is the measured flange bore less 0.4-0.5mm diametral clearance.
// Flange bores: 82.47 at joint 1, 52.41 at joint 2.
Ring_T     = 6;
Ring1_OD   = 82.0;
Ring2_OD   = 52.0;
Ring_Eye_d = 12;   // strap pass-through
Ring_Wall  = 4;

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

module NC_Shoulder(){
    // Printed replacement for a bought coupler. The bulkhead is the
    // parachute anchor: shock passes straight into the body tube, so no
    // glue joint is ever loaded in tension.
    difference(){
        union(){
            cylinder(d=Shoulder_OD, h=Shoulder_L, $fn=$preview? 90:360);

            translate([0,0,Shoulder_L])
                cylinder(d=Shoulder_Spigot_OD, h=Shoulder_Spigot_L,
                         $fn=$preview? 90:360);
        } // union

        // Hollow the body, leaving the bulkhead at the bottom
        translate([0,0,Shoulder_Bulk_T])
            cylinder(d=Shoulder_OD-NC_Wall_T*2,
                     h=Shoulder_L-Shoulder_Bulk_T+Overlap,
                     $fn=$preview? 90:360);

        // Hollow the spigot separately so its wall stays NC_Wall_T
        translate([0,0,Shoulder_L])
            cylinder(d=Shoulder_Spigot_OD-NC_Wall_T*2,
                     h=Shoulder_Spigot_L+Overlap, $fn=$preview? 90:360);

        // Strap slots — printed anchor, no metal hardware
        translate([0, Shoulder_OD/2-NC_Wall_T-4, -Overlap])
            RoundRect(X=16, Y=4, Z=Shoulder_Bulk_T+1, R=1.5);
        translate([0, -Shoulder_OD/2+NC_Wall_T+4, -Overlap])
            RoundRect(X=16, Y=4, Z=Shoulder_Bulk_T+1, R=1.5);
    } // difference
} // NC_Shoulder

module NC_GuideRing(OD=Ring1_OD){
    // Annulus + 3 spokes + central eyelet. A solid disc would add ~39g
    // at joint 1 and block the cone interior.
    intersection(){
        difference(){
            union(){
                difference(){
                    cylinder(d=OD, h=Ring_T, $fn=$preview? 90:360);
                    translate([0,0,-Overlap])
                        cylinder(d=OD-Ring_Wall*2, h=Ring_T+Overlap*2,
                                 $fn=$preview? 90:360);
                } // difference

                difference(){
                    cylinder(d=Ring_Eye_d+Ring_Wall*2, h=Ring_T, $fn=$preview? 90:180);
                    translate([0,0,-Overlap])
                        cylinder(d=Ring_Eye_d, h=Ring_T+Overlap*2, $fn=$preview? 90:180);
                } // difference

                for (j=[0:2]) rotate([0,0,120*j])
                    translate([0,-Ring_Wall/2,0]) cube([OD/2, Ring_Wall, Ring_T]);
            } // union

            // Spokes cross the axis, so the eyelet bore must be cut AFTER
            // they are unioned or the strap hole is webbed shut.
            translate([0,0,-Overlap])
                cylinder(d=Ring_Eye_d, h=Ring_T+Overlap*2, $fn=$preview? 90:180);
        } // difference

        // Clamp to OD: the spoke cube corners otherwise reach
        // sqrt((OD/2)^2+(Ring_Wall/2)^2), eating the flange clearance.
        translate([0,0,-Overlap])
            cylinder(d=OD, h=Ring_T+Overlap*2, $fn=$preview? 90:360);
    } // intersection
} // NC_GuideRing

// ============================================
// RENDERING LOGIC — don't edit below
// ============================================
if (Render_Part == 0) TestRing();
if (Render_Part == 1) NC_Shoulder();
if (Render_Part == 2) NC_Slice_Bottom();
if (Render_Part == 3) NC_Slice_Middle();
if (Render_Part == 4) NC_Slice_Top();
if (Render_Part == 5) NC_GuideRing(OD=Ring1_OD);
if (Render_Part == 6) NC_GuideRing(OD=Ring2_OD);

module TestRing(){
    // Print this FIRST. Verifies both fits before committing to 190mm parts.
    // OD must sit flush on the body tube (no step).
    // Bore must accept the shoulder spigot (96.7) with a light push fit.
    difference(){
        cylinder(d=Peregrine_Body_OD, h=15, $fn=90);
        translate([0,0,-Overlap])
            cylinder(d=Peregrine_Coupler_OD, h=15+Overlap*2, $fn=90);
    } // difference
} // TestRing

// ============================================
// PRINT NOTES
// ============================================
//
// Parts (all 3D printed):
//   0  Test ring          15mm    -- disposable fit check. Print FIRST,
//                                     verify both fits, then set aside --
//                                     it is NOT glued into the assembly.
//   1  Shoulder          115mm    -- superglued into the assembly
//   2  Bottom slice      190mm    -- superglued into the assembly
//   3  Middle slice      190mm    -- superglued into the assembly
//   4  Top slice         183mm    -- superglued into the assembly
//   5  Guide ring lower    6mm    -- superglued into the assembly (optional)
//   6  Guide ring upper    6mm    -- superglued into the assembly (optional)
//
// Parts 3 and 4 EXPORT starting at z=183.33 and z=366.67 (not z=0) --
// drop them to the build plate in the slicer before printing.
//
// Guide rings 5 and 6 keep the parachute strap off the shell wall while
// it is packed up INSIDE the cone. If the parachute instead packs below
// the nosecone, in the body tube, the rings serve no purpose -- skip
// parts 5 and 6 and glue joints 1 and 2 directly.
//
// Each flange bore is NARROWEST right at its own rim and WIDENS going
// down into the open cone below it. A ring set in loose will not catch
// there -- it slides straight down past the flange and keeps going until
// it reaches the shoulder bulkhead, far below. Every ring must be GLUED
// into its flange bore and HELD in place until the glue sets; it will
// not stay there by itself.
//
// Assembly, bottom to top. Thread the strap and seat each ring BEFORE
// closing the joint above it, never after -- once a joint is glued shut,
// its far side is a sealed cavity and nothing can be threaded into it:
//   1. Thread the parachute strap through the shoulder's bulkhead slots.
//   2. Glue the shoulder spigot into the bottom slice bore. Hold until set.
//   3. Feed the strap up through ring 5's eyelet, seat the ring in the
//      bottom slice's joint-1 flange bore, glue, and hold until set.
//   4. Glue the middle slice onto the bottom slice's flange, closing
//      joint 1. Ring 5 and the strap are now sealed inside, already
//      threaded correctly.
//   5. Feed the strap up through ring 6's eyelet, seat the ring in the
//      middle slice's joint-2 flange bore, glue, and hold until set.
//   6. Glue the top slice onto the middle slice's flange, closing joint 2.
// (If skipping the rings per above, just glue each joint directly and
// thread the strap through the bulkhead slots only.)
//
// Use gel CA or a slow epoxy, not thin/wicking CA. The laps are large
// (1935mm^2 at joint 1) with only a ~0.2mm radial gap, and thin CA kicks
// on contact -- it gives you one shot at alignment on a 190mm-long part.
//
// Print settings: 3 perimeters, 15% infill, PETG or ASA.
// Total ~508g in PETG.
//
// ALWAYS export with F6 (full render). F5 preview applies a quarter
// cutaway and will silently export a broken part.
//
// ***********************************
