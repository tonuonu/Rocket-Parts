// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineCamNose.scad
// for Apogee Peregrine (100mm body tube), with forward-looking camera
// Created: 2026-08-12
// Units: mm
// ***********************************
//
// Camera variant of PeregrineNoseCone.scad. Same 574.55 ogive as the
// plain nosecone, but truncated at OD 60.00 instead of running to a tip.
//
// The camera does not live in this part. It lives in a separate,
// already-finished CAD nosecone (STL Files/Rocket60/NoseCone.stl -- a
// straight FreeCAD conversion of the user's own design: correct ogive,
// sunken screw heads, lens bore, all of it) that bolts onto the cut end
// via CN_Adapter(). An earlier version of this file reinvented that
// camera housing here instead -- blunting the tip to a 26mm spherical
// cap, drilling a lens hole, and adding loose printed spacers to fill
// the gap between the shell and the camera's flat mounting faces. That
// is gone; the tip radius is back to the plain nosecone's 8mm, and
// nothing above the cut is ever printed.
//
// Grafting two different cones onto one shell leaves a visible slope
// discontinuity at the joint. Measured from the meshes, not assumed:
// this ogive's local half-angle at Cut3 is ~6.5 degrees, while the CAD
// cone is a curved profile too, not a straight cone -- its half-angle is
// only ~0.4 degrees right at its base plane, rising to ~3 degrees by
// 25mm up. So the kink right at the joint is roughly 6 degrees. That is
// inherent to grafting two different cones together, not a defect -- see
// the adapter section below.
//
// ***********************************

include<NoseCone.scad>

// ============================================
// BODY TUBE -- measure yours and adjust
// ============================================
Peregrine_Body_OD    = 101.5;   // outside diameter of body tube
// MEASURED 2026-08-13 with a printed stepped fit gauge, not assumed. A
// 99.10 band enters by hand but will not slide under its own weight; 98.85
// slides freely. That brackets the real ID at ~99.1.
Peregrine_Body_ID    = 99.1;    // inside diameter of body tube
// Derived, not hardcoded. This previously read 97.1 with a comment claiming
// it was Body_OD - 2*Wall_T; the two happened to agree, so a change to
// either input would have silently broken the shell fit with nothing to
// signal it. Declared below NC_Wall_T because it depends on it.

// ============================================
// NOSE CONE -- 574.55 ogive, truncated at OD 60 for the CAD nosecone
// ============================================
NC_Length  = 574.55;   // same ogive as the non-camera version
NC_Base_L  = 15;
// Slender again, matching PeregrineNoseCone.scad -- large Tip_R was only
// ever needed to fit the camera behind the apex, and the camera no
// longer lives here. This does not change the retained geometry below:
// Cut_Z (and so every slice plane) depends only on R, L, Base_L and
// Cut_d in BluntOgiveNoseCone -- never on Tip_R -- and the tip blending
// itself only reaches down to Z=418.6 even at the old Tip_R=26, versus
// Z=543.3 at this Tip_R=8. Both are far above Cut3_Z below, so parts 2
// and 3 (and the shell up to the new cut) are unaffected. Verified by
// rendering parts 2 and 3 before and after this change and diffing the
// meshes -- see REPORT-graft.md.
NC_Tip_R   = 8;
NC_Wall_T  = 2.2;
Peregrine_Coupler_OD = Peregrine_Body_OD - NC_Wall_T*2;   // shell ID, 97.1
NC_nRivets = 0;        // shoulder is glued via its spigot, not pinned

// Slice planes. Cut_d is a DIAMETER; the module derives Z from it.
Cut1_d = 96.17;   // -> Z = 147.14
Cut2_d = 77.66;   // -> Z = 294.29
Cut1_Z = 147.14;  // clip plane for the middle slice

// Third cut: where the generated ogive hands off to the CAD nosecone,
// at the station where this ogive's OD is 60.00 (the CAD cone's own base
// OD is 59.99 -- effectively the same diameter). Derived the same way
// BluntOgiveNoseCone derives its own Cut_Z internally, not read off a
// mesh: a fine bisection of the actual exported mesh
// (STL Files/PeregrineCamNose/SliceTop.stl, the pre-graft render) finds
// OD=60.00 at Z=383.13, 0.10mm from this formula's 383.23 -- ordinary
// $fn tessellation chording on a curved surface, not a disagreement worth
// chasing. (A coarse 1mm-grid reading of the same mesh -- 60.10 at
// Z=383.0, 59.91 at Z=384.0 -- undersamples the curve and lands on
// Z~383.5; the bisection against the mesh's actual facets is the more
// trustworthy empirical number, and it agrees with this formula to
// 0.10mm.)
Cut3_d = 60;
Cut3_Z = NC_Base_L + Ogive_Cut_Z(Ogive_L=NC_Length, R=Peregrine_Body_OD/2, End_R=Cut3_d/2);   // -> 383.23

// ============================================
// ADAPTER -- joins the truncated shell to the CAD nosecone
// ============================================
// The CAD nosecone's interior is filled by the camera assembly, flush
// with its base plane, so nothing plugs into its bore -- it attaches
// only by three M3 screws into heat-set inserts in the camera's own
// bottom face. Bolt circle and hole spec measured from that mesh, not
// assumed.
CAD_Bolt_R   = 18.98;                  // bolt circle radius, Ø37.96
CAD_Bolt_A   = [52.2, -52.2, 180.0];   // NOT 120 deg apart -- keys the camera's clocking, preserve exactly
M3_Clear     = 3.4;                    // clearance hole dia, no counterbore
M3_Screw_L   = 10;                     // M3x10...
Insert_Depth = 5.7;                    // ...into ruthex RX-M3x5.7 heat-set inserts

// This joint carries the whole CAD nosecone + camera in flight, so it is
// always epoxied -- independent of Glue_Gap below, which is the user's
// per-flight choice for the separate, removable shoulder joint.
Adapter_Epoxy_Gap = 0.4;

Cut3_Bore_ID      = Cut3_d - NC_Wall_T*2;                // shell bore at Cut3, 55.6
Adapter_Flange_OD = Cut3_d;                              // flush with the shell and the CAD base (59.99)
Adapter_Spigot_OD   = Cut3_Bore_ID - Adapter_Epoxy_Gap;  // -> 55.2
Adapter_Spigot_Wall = NC_Wall_T;                         // same wall as the shell
Adapter_Spigot_ID   = Adapter_Spigot_OD - Adapter_Spigot_Wall*2;   // -> 50.8, hollow for the harness
Adapter_Spigot_L    = 15;   // same glue engagement length as the shoulder-to-shell spigot joint below (Shoulder_Spigot_L)

// Flange thickness: an M3x10 screw crossing the flange must still reach
// enough of the insert's 5.7mm depth to hold, without its tip bottoming
// out in the insert before the head seats. 4.5mm leaves 5.5mm of
// engagement with 0.2mm to spare.
Adapter_Flange_T = M3_Screw_L - Insert_Depth + 0.2;   // -> 4.5

// The flange's OWN bore is narrower than the spigot's hollow above --
// this leaves a solid shelf inside the flange, between the two bore
// radii, for the 3 screw holes to pass through solid material. The screw
// heads seat on that shelf's underside, with the wider spigot hollow
// open beneath them for a screwdriver and for the camera harness to
// route through. Sized to clear the bolt circle by a wall as thick as
// the shell's own (NC_Wall_T) around each screw hole.
Adapter_Bore_D = 2*(CAD_Bolt_R - M3_Clear/2 - NC_Wall_T);   // -> 30.16, well inside Adapter_Spigot_ID (50.8)

// ============================================
// SHOULDER -- stepped, printed, all-in-one
// ============================================
// Adhesive gap for GLUED joints. Thin CA wicks into a 0.1-0.2mm gap and
// needs the tight fit to grip; epoxy is gap-filling and wants the room.
// Set this to match what you actually use.
//   0.2 = superglue / thin CA
//   0.4 = epoxy
Glue_Gap = 0.2;

Shoulder_L         = 100;
// NOT glued - the shoulder is removed every flight to pack the chute, so
// this stays a slip fit. 0.4mm is also right because the joint is 100mm
// long: a 7mm gauge ring slides happily at 0.25mm, but over 100mm any
// ovality or bow in the tube accumulates and a tighter fit binds partway
// home, which is worse than loose.
Shoulder_OD        = Peregrine_Body_ID - 0.4;   // slip fit -> 98.7
Shoulder_Spigot_L  = 15;
// GLUED into the bottom slice bore, so it takes Glue_Gap, not 0.4.
Shoulder_Spigot_OD = Peregrine_Coupler_OD - Glue_Gap;   // -> 96.9 with CA
Shoulder_Bulk_T    = 4;

// ============================================
// RENDER SELECTION -- change this value!
// ============================================
// 0 = Test ring (print first!)
// 1 = Shoulder + bulkhead + parachute anchor
// 2 = Bottom slice
// 3 = Middle slice
// 4 = Top slice (truncated at OD 60 -- no camera features)
// 5 = Adapter (flange + spigot, joins the shell to the CAD nosecone)
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

module CN_Slice_Top(){
    // Plain frustum shell, cut 2 to cut 3 (OD 60) -- no lens hole, no
    // camera mounts. The camera now lives entirely in the CAD nosecone
    // that glues onto this shell's open top via CN_Adapter().
    intersection(){
        CN_Cone(Cut_d=Cut2_d, Lower=false);
        cylinder(d=Peregrine_Body_OD+2, h=Cut3_Z, $fn=$preview? 90:360);
    } // intersection
} // CN_Slice_Top

module CN_Adapter(){
    // Flange butts the CAD nosecone's base and carries its 3 mounting
    // screws; the spigot below is epoxied into the shell's Cut3 bore.
    difference(){
        union(){
            cylinder(d=Adapter_Flange_OD, h=Adapter_Flange_T, $fn=$preview? 90:360);
            translate([0,0,-Adapter_Spigot_L])
                cylinder(d=Adapter_Spigot_OD, h=Adapter_Spigot_L+Overlap, $fn=$preview? 90:360);
        } // union

        // flange's own bore -- through the flange only
        translate([0,0,-Overlap])
            cylinder(d=Adapter_Bore_D, h=Adapter_Flange_T+Overlap*2, $fn=$preview? 60:180);

        // spigot's hollow -- through the spigot only, wider than the bore
        // above, so the screw heads have a shelf to seat on (see comment
        // on Adapter_Bore_D)
        translate([0,0,-Adapter_Spigot_L-Overlap])
            cylinder(d=Adapter_Spigot_ID, h=Adapter_Spigot_L+Overlap, $fn=$preview? 60:180);

        // screw clearance holes, through the flange only
        for (a=CAD_Bolt_A)
            translate([CAD_Bolt_R*cos(a), CAD_Bolt_R*sin(a), -Overlap])
                cylinder(d=M3_Clear, h=Adapter_Flange_T+Overlap*2, $fn=$preview? 18:36);
    } // difference
} // CN_Adapter

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
if (Render_Part == 5) CN_Adapter();

// ============================================
// PRINT NOTES
// ============================================
//
// Parts:
//   0  Test ring        15mm   -- disposable fit check, print first, not glued
//   1  Shoulder        115mm
//   2  Bottom slice    147mm
//   3  Middle slice    147mm
//   4  Top slice        89mm   -- truncated at OD 60, no camera features
//   5  Adapter          20mm   -- flange + spigot, joins shell to the CAD nosecone
//
// Assembly, bottom to top:
//   1. Print part 0. Check it sits flush on the tube and accepts the spigot.
//   2. Glue the shoulder spigot into the bottom slice bore.
//   3. Glue the bottom slice flange into the middle slice, hold until set.
//   4. Glue the middle slice flange into the top slice, hold until set.
//   5. Bolt the CAD nosecone (camera already installed in it) onto the
//      adapter's flange with three M3x10 screws into its own inserts.
//   6. Epoxy the adapter's spigot into the top slice's open bore (Cut3)
//      and hold until set. This joint is permanent, unlike the shoulder.
//
// Parts 3 and 4 export at Z=147.14 and 294.29 rather than 0 -- drop to
// plate in the slicer.
//
// Use gel CA or epoxy, not thin CA: the laps are large and thin CA gives a
// one-shot alignment on a 147mm part. The adapter-to-shell joint (step 6)
// is always epoxy, regardless of what Glue_Gap is set to.
//
// Print settings: 3 perimeters, 15% infill, PETG or ASA.
//
// ALWAYS export with F6. F5 preview applies a quarter cutaway and will
// silently export a broken part.
//
// The joint between this shell and the CAD nosecone has a visible slope
// discontinuity -- this ogive converges at ~6.5 deg half-angle at Cut3,
// the CAD cone at ~0.4 deg right at its base (it is a curved profile
// too, not a straight cone). That ~6 deg kink is inherent to grafting two
// different cones together and is not fixable without redesigning one of
// the two cones; it does not affect fit or strength.
//
// ***********************************
