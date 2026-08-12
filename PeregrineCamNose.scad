// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineCamNose.scad
// for Apogee Peregrine (100mm body tube), with forward-looking camera
// Created: 2026-08-12
// Units: mm
// ***********************************
//
// Camera variant of PeregrineNoseCone.scad. Same 574.55 ogive, but blunted
// with a large tip radius so the nose is a smooth spherical cap the camera
// can see out of, instead of a slender point.
//
// WHY Tip_R IS 26 AND NOT 8
// The camera reaches its full 50.2mm width only 54mm behind its lens, so any
// cone enclosing it must be at least 54.6mm across at that station. On this
// ogive that occurs at Z=406, which pins the lens to Z<=460. Blunting with
// Tip_R=26 puts the apex at 441.4 and gives the camera 4.7mm diametral
// clearance. A slender Tip_R=8 nose (apex 550) cannot contain the camera at
// any height -- it misses by 19mm.
//
// The lens looks out through a hole at the apex. The camera bolts to four
// M3 heat-set inserts already fitted in its own top and bottom faces.
//
// ***********************************

include<NoseCone.scad>

// ============================================
// BODY TUBE -- measure yours and adjust
// ============================================
Peregrine_Body_OD    = 101.5;   // outside diameter of body tube
Peregrine_Body_ID    = 99.0;    // inside diameter of body tube
Peregrine_Coupler_OD = 97.1;    // shell ID = Body_OD - 2*Wall_T

// ============================================
// NOSE CONE -- 441mm, blunted for the camera
// ============================================
NC_Length  = 574.55;   // same ogive as the non-camera version
NC_Base_L  = 15;
NC_Tip_R   = 26;       // large: the nose is a 52mm spherical cap
NC_Wall_T  = 2.2;
NC_nRivets = 0;        // shoulder is glued via its spigot, not pinned

// Slice planes. Cut_d is a DIAMETER; the module derives Z from it.
Cut1_d = 96.17;   // -> Z = 147.14
Cut2_d = 77.66;   // -> Z = 294.29
Cut1_Z = 147.14;  // clip plane for the middle slice
Apex_Z = 441.43;  // top of the finished cone

// ============================================
// CAMERA
// ============================================
// Lens is 14.0mm on an M12 thread. It looks out through the apex.
Lens_D      = 14.4;    // 14.0 + 0.4 clearance
// The camera carries four ruthex M3x5.7 inserts in its own top and bottom
// faces, 30mm apart, centred, at radius 25 from the lens axis. Screws pass
// radially inward through the shell into those inserts.
Cam_Mount_R = 25.0;    // camera mounting faces, from the lens axis
Cam_Mount_B = [58.5, 88.5];   // mm behind the lens face
M3_Clear    = 3.4;
M3_Head     = 6.4;     // countersunk head diameter
Spacer_Front_T = 2.83;   // shell inner surface -> camera face, front station
Spacer_Rear_T  = 6.08;   // ditto, rear station

// ============================================
// SHOULDER -- stepped, printed, all-in-one
// ============================================
Shoulder_L         = 100;
Shoulder_OD        = Peregrine_Body_ID - 0.4;   // 0.4mm diametral clearance
Shoulder_Spigot_L  = 15;
Shoulder_Spigot_OD = 96.7;
Shoulder_Bulk_T    = 4;

// ============================================
// RENDER SELECTION -- change this value!
// ============================================
// 0 = Test ring (print first!)
// 1 = Shoulder + bulkhead + parachute anchor
// 2 = Bottom slice
// 3 = Middle slice
// 4 = Top slice (carries the lens hole and camera mounts)
// 5 = Spacer x2, front stations
// 6 = Spacer x2, rear stations
Render_Part = 0;

// ============================================
// PARTS
// ============================================
module CN_Cone(Cut_d=0, Lower=false){
    BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD,
        L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets,
        Tip_R=NC_Tip_R, Wall_T=NC_Wall_T,
        Cut_d=Cut_d, LowerPortion=Lower, FillTip=false);
} // CN_Cone

module CN_Slice_Bottom(){ CN_Cone(Cut_d=Cut1_d, Lower=true); }

module CN_Slice_Middle(){
    // Everything below cut 2 (with its gluing flange), clipped above cut 1.
    intersection(){
        CN_Cone(Cut_d=Cut2_d, Lower=true);
        translate([0,0,Cut1_Z])
            cylinder(d=Peregrine_Body_OD+2, h=NC_Length, $fn=$preview? 90:360);
    } // intersection
} // CN_Slice_Middle

module CN_MountHoles(){
    // Radial M3 clearance holes with a countersink from outside. An M3
    // countersunk head is 6.0 x 1.65mm, which fits the 2.2mm wall flush,
    // so no boss is needed and nothing protrudes into the airflow.
    for (b=Cam_Mount_B) for (s=[1,-1])
        translate([0, s*60, Apex_Z-b]) rotate([90,0,0]){
            cylinder(d=M3_Clear, h=120, center=true, $fn=$preview? 18:36);
            translate([0,0,50-Overlap])
                cylinder(d1=M3_Clear, d2=M3_Head, h=1.8, $fn=$preview? 18:36);
            translate([0,0,51.8]) cylinder(d=M3_Head, h=20, $fn=$preview? 18:36);
        }
} // CN_MountHoles

module CN_Slice_Top(){
    difference(){
        CN_Cone(Cut_d=Cut2_d, Lower=false);
        translate([0,0,Apex_Z-60]) cylinder(d=Lens_D, h=120, $fn=$preview? 60:120);
        CN_MountHoles();
    } // difference
} // CN_Slice_Top

module CN_Spacer(T=3){
    // Fills the gap between the shell inner surface and the camera face so
    // the screw clamps solid instead of bending the shell inward.
    difference(){
        cylinder(d=8, h=T, $fn=$preview? 30:60);
        translate([0,0,-Overlap]) cylinder(d=M3_Clear, h=T+Overlap*2,
                                           $fn=$preview? 18:36);
    } // difference
} // CN_Spacer

module CN_Shoulder(){
    difference(){
        union(){
            cylinder(d=Shoulder_OD, h=Shoulder_L, $fn=$preview? 90:360);
            translate([0,0,Shoulder_L])
                cylinder(d=Shoulder_Spigot_OD, h=Shoulder_Spigot_L,
                         $fn=$preview? 90:360);
        } // union
        translate([0,0,Shoulder_Bulk_T])
            cylinder(d=Shoulder_OD-NC_Wall_T*2,
                     h=Shoulder_L-Shoulder_Bulk_T+Overlap, $fn=$preview? 90:360);
        translate([0,0,Shoulder_L])
            cylinder(d=Shoulder_Spigot_OD-NC_Wall_T*2,
                     h=Shoulder_Spigot_L+Overlap, $fn=$preview? 90:360);
        translate([0, Shoulder_OD/2-NC_Wall_T-4, -Overlap])
            RoundRect(X=16, Y=4, Z=Shoulder_Bulk_T+1, R=1.5);
        translate([0, -Shoulder_OD/2+NC_Wall_T+4, -Overlap])
            RoundRect(X=16, Y=4, Z=Shoulder_Bulk_T+1, R=1.5);
    } // difference
} // CN_Shoulder

module TestRing(){
    // Print this FIRST. OD must sit flush on the body tube; the bore must
    // accept the shoulder spigot (96.7) with a light push fit.
    difference(){
        cylinder(d=Peregrine_Body_OD, h=15, $fn=90);
        translate([0,0,-Overlap])
            cylinder(d=Peregrine_Coupler_OD, h=15+Overlap*2, $fn=90);
    } // difference
} // TestRing

// ============================================
// RENDERING LOGIC -- don't edit below
// ============================================
if (Render_Part == 0) TestRing();
if (Render_Part == 1) CN_Shoulder();
if (Render_Part == 2) CN_Slice_Bottom();
if (Render_Part == 3) CN_Slice_Middle();
if (Render_Part == 4) CN_Slice_Top();
if (Render_Part == 5) CN_Spacer(T=Spacer_Front_T);
if (Render_Part == 6) CN_Spacer(T=Spacer_Rear_T);

// ============================================
// PRINT NOTES
// ============================================
//
// Parts:
//   0  Test ring        15mm   -- disposable fit check, print first, not glued
//   1  Shoulder        115mm
//   2  Bottom slice    147mm
//   3  Middle slice    147mm
//   4  Top slice       147mm   -- lens hole and camera mounts
//   5  Spacer x2        2.83mm -- front mount station
//   6  Spacer x2        6.08mm -- rear mount station
//
// Assembly, bottom to top:
//   1. Print part 0. Check it sits flush on the tube and accepts the spigot.
//   2. Glue the shoulder spigot into the bottom slice bore.
//   3. Glue the bottom slice flange into the middle slice, hold until set.
//   4. Glue the middle slice flange into the top slice, hold until set.
//   5. Slide the camera in through the open base, lens up to the apex hole,
//      and fasten with four M3 countersunk screws into its own inserts,
//      with a spacer on each screw between shell and camera face.
//
// The camera goes in AFTER the cone is assembled and comes out the same way,
// so it stays serviceable as long as the shoulder is not glued permanently.
//
// Parts 3 and 4 export at Z=147.14 and 294.29 rather than 0 -- drop to plate
// in the slicer.
//
// Use gel CA or epoxy, not thin CA: the laps are large and thin CA gives a
// one-shot alignment on a 147mm part.
//
// Print settings: 3 perimeters, 15% infill, PETG or ASA.
//
// ALWAYS export with F6. F5 preview applies a quarter cutaway and will
// silently export a broken part.
//
// ***********************************
