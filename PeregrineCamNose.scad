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
// already-finished CAD nosecone -- a straight FreeCAD conversion of the
// user's own design: correct ogive, sunken screw heads, lens bore, all of
// it -- that bolts onto the cut end via CN_Adapter(). That CAD nosecone's
// own mesh lives on a different branch (feature/rocket60), not here; this
// file only defines the interface it bolts to. An earlier version of this
// file reinvented that
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
// meshes: identical volume, z-span and profile.
NC_Tip_R   = 8;
NC_Wall_T  = 2.2;
Peregrine_Coupler_OD = Peregrine_Body_OD - NC_Wall_T*2;   // shell ID, 97.1
NC_nRivets = 0;        // shoulder is glued via its spigot, not pinned

// Slice planes. Cut_d is a DIAMETER; the module derives Z from it.
Cut1_d = 96.17;   // -> Z = 147.15
Cut2_d = 77.66;   // -> Z = 294.29
// Derived the same way Cut3_Z below is, not hardcoded next to it -- this
// previously read a bare 147.14 literal, so changing Cut1_d would move the
// bottom slice's own cut plane without moving this one, silently breaking
// the middle slice's clip.
Cut1_Z = NC_Base_L + Ogive_Cut_Z(Ogive_L=NC_Length, R=Peregrine_Body_OD/2, End_R=Cut1_d/2);   // -> 147.15
Cut2_Z = NC_Base_L + Ogive_Cut_Z(Ogive_L=NC_Length, R=Peregrine_Body_OD/2, End_R=Cut2_d/2);

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

// Outer or bore diameter of THIS shell's ogive at any axial station Z (mm
// from the nosecone base plane). Same tangent-ogive arc BluntOgiveShape
// draws to build the outer surface -- a circle of radius p centered at
// (R-p, 0) in the (radius, axial-from-Base_L) plane, the same p
// Ogive_Cut_Z above uses -- solved for radius given Z instead of Z given
// radius. Wall>0 gives the bore (inner) surface the way BluntOgiveNoseCone
// itself builds it (see BluntOgiveShape's Thickness parameter in
// NoseCone.scad): by shrinking the arc's radius by Wall, NOT by
// subtracting 2*Wall from the outer diameter -- that shortcut is only
// exact right at Base_L and increasingly wrong up the curve. Checked
// against the committed mesh, not just algebra: this formula predicts bore
// ID 55.61 / 56.25 / 57.80 / 58.90 at 0.17 / 3 / 10 / 15mm below the Cut3
// rim; the mesh measures 55.59 / 56.21 / 57.74 / 58.83 -- agreement to
// ordinary $fn chording, the same tolerance Cut3_Z's own derivation above
// was checked against. Only valid below the tip's spherical blend (Z well
// under Base_L+L-X0); Cut3 and the adapter's full engagement depth both
// are.
function Ogive_OD_At_Z(Z, Wall=0) =
    let(R=Peregrine_Body_OD/2, p=NC_OGiveArcOffset(R, NC_Length), y=Z-NC_Base_L)
    2*(R - p + sqrt((p-Wall)*(p-Wall) - y*y));

// ============================================
// ADAPTER -- joins the truncated shell to the CAD nosecone
// ============================================
// Bay_Enabled uses these flange dimensions directly in the top slice.
// The separate spigot/adapter (part 5) is retained only for the older,
// non-bay shell. Do not add it to the new integrated top.
// The CAD nosecone's interior is filled by the camera assembly, flush
// with its base plane, so nothing plugs into its bore -- it attaches
// only by three M3 screws. The screws come down through the CAD
// nosecone's sunken-head holes into heat-set inserts in THIS flange.
// (An earlier version assumed the inserts were in the camera's bottom
// face and gave the flange plain M3 clearance holes; that was wrong.)
// Bolt circle measured from the CAD mesh, not assumed.
CAD_Bolt_R    = 18.98;                  // bolt circle radius, Ø37.96
CAD_Bolt_A    = [52.2, -52.2, 180.0];   // NOT 120 deg apart -- keys the camera's clocking, preserve exactly
Insert_Hole_D = 4.0;                    // ruthex RX-M3x5.7 heat-set insert, maker's recommended hole dia
Insert_Depth  = 5.7;                    // insert length; must fit inside Adapter_Flange_T

// This joint carries the whole CAD nosecone + camera in flight, so it is
// always epoxied -- independent of Glue_Gap below, which is the user's
// per-flight choice for the separate, removable shoulder joint.
Adapter_Epoxy_Gap = 0.4;

Cut3_Bore_ID      = Ogive_OD_At_Z(Cut3_Z, NC_Wall_T);    // shell bore AT the rim, ~55.57
Adapter_Flange_OD = Cut3_d;                              // flush with the shell and the CAD base (59.99)
Adapter_Spigot_Wall = NC_Wall_T;                         // same wall as the shell
Adapter_Spigot_L    = 15;   // engagement depth into the bore

// The bore is a station on an ogive, not a cylinder (see Ogive_OD_At_Z
// above): its ID grows from Cut3_Bore_ID at the rim to a measurably wider
// ID one full engagement-length deeper. A spigot turned to a single,
// constant OD sized for the rim leaves the rest of the 15mm engagement as
// a widening, unglued void -- several mm diametral by the deep end,
// confirmed against the rendered mesh. (An earlier version of this file
// did exactly that, and justified the 15mm engagement length by analogy to
// the shoulder-to-shell spigot below -- but that joint enters a genuinely
// PARALLEL bore (NoseCone.scad:831), so the analogy does not carry over to
// a joint that enters a tapered one.) Taper the spigot to track the bore
// instead: d1 (bottom, the deepest point) and d2 (top, at the flange) are
// each the bore ID at that depth minus Adapter_Epoxy_Gap, so the diametral
// gap stays close to Adapter_Epoxy_Gap along the whole engagement instead
// of only at one end.
Adapter_Spigot_OD_Top = Cut3_Bore_ID - Adapter_Epoxy_Gap;                                      // -> 55.17, at the flange
Adapter_Spigot_OD_Bot = Ogive_OD_At_Z(Cut3_Z-Adapter_Spigot_L, NC_Wall_T) - Adapter_Epoxy_Gap;  // -> 58.50, at full depth
Adapter_Spigot_ID   = Adapter_Spigot_OD_Top - Adapter_Spigot_Wall*2;   // -> 50.77, hollow for the harness (straight bore -- no fit requirement inside, sized off the narrow end so the wall stays >= NC_Wall_T everywhere)

// Flange thickness: the flange carries the three heat-set inserts, so it
// must be at least Insert_Depth thick. 6.0mm holds the 5.7mm insert with
// 0.3mm to spare; the holes go right through, so a slightly proud insert
// or melt-displaced plastic has somewhere to go. Screw length is set by
// the CAD nosecone's base thickness at its sunken-head holes plus at most
// Insert_Depth of thread into the insert -- pick it against that part.
Adapter_Flange_T = 6.0;
assert(Adapter_Flange_T >= Insert_Depth, "flange too thin for the heat-set inserts");

// The flange's OWN bore is narrower than the spigot's hollow above --
// this leaves a solid shelf inside the flange, between the two bore
// radii, for the 3 insert holes to sit in solid material, with the wider
// spigot hollow open beneath for the camera harness to route through.
// Sized to leave a wall as thick as the shell's own (NC_Wall_T) between
// each insert hole and the bore.
Adapter_Bore_D = 2*(CAD_Bolt_R - Insert_Hole_D/2 - NC_Wall_T);   // -> 29.56, well inside Adapter_Spigot_ID (50.77)

// ============================================
// SHOULDER -- stepped, printed, all-in-one
// ============================================
// Adhesive gap for GLUED joints. Thin CA wicks into a 0.1-0.2mm gap and
// needs the tight fit to grip; epoxy is gap-filling and wants the room.
// Set this to match what you actually use.
//   0.2 = superglue / thin CA -- only for small parts; see the print notes
//         below on why this file's own laps are too large for thin CA
//   0.4 = gel CA or epoxy (default)
Glue_Gap = 0.4;

Shoulder_L         = 100;
// NOT glued - the shoulder is removed every flight to pack the chute, so
// this stays a slip fit. 0.4mm is also right because the joint is 100mm
// long: a 7mm gauge ring slides happily at 0.25mm, but over 100mm any
// ovality or bow in the tube accumulates and a tighter fit binds partway
// home, which is worse than loose.
// The owner reports four gauge bands entered (through 98.9 mm), while
// the 99.1 mm band did not. Keep 98.7 mm for the long shoulder: 0.2 mm
// smaller than the largest band that entered, leaving room for ovality.
// Any correction stays local; scaling Body_OD would invalidate printed slices.
Shoulder_Tube_Fit_Adjust = 0.0; // DIAMETRAL correction; gauge supports original OD
Shoulder_Nominal_OD = Peregrine_Body_ID - 0.4; // original slip-fit OD, 98.7
Shoulder_OD        = Shoulder_Nominal_OD + Shoulder_Tube_Fit_Adjust; // 98.7
// Fit adjustment affects only the outside; retain the validated bore,
// ribbon slots, internal chamfer and bay-facing spigot diameter.
Shoulder_Bore_D    = Shoulder_Nominal_OD - NC_Wall_T*2;
// Five 3 mm bands bracket the original fit instead of guessing another
// single diameter. Print largest end down; insert the smallest end first.
Shoulder_Fit_Gauge_Ds = [98.3, 98.5, 98.7, 98.9, 99.1];
Shoulder_Fit_Gauge_Step_H = 3;
Shoulder_Fit_Gauge_Lead = 0.3; // relief at the bed and the insertion tip
assert(Shoulder_OD >= Shoulder_Bore_D + NC_Wall_T*2,
       "tube-fit correction must not thin the original shoulder wall");
Shoulder_Spigot_L  = 15;
// GLUED into the bottom slice bore, so it takes Glue_Gap, not 0.4 flat --
// they happen to agree at the default (Glue_Gap=0.4), but Glue_Gap can
// still be tightened to 0.2 for thin CA on a small part.
Shoulder_Spigot_OD = Peregrine_Coupler_OD - Glue_Gap;   // -> 96.7 at the default
Shoulder_Bulk_T    = 4;
// Ease the bulkhead end into the tube without changing the full-length
// bearing diameter. The 96.7 mm tip grows to 98.7 over 2 mm: each 0.2 mm
// print layer advances only 0.1 mm radially. Keep the relief within the
// solid bulkhead and outside the recovery slots.
Shoulder_Entry_Chamfer_H = 2;
Shoulder_Entry_Chamfer_R = 1;
assert(Shoulder_Entry_Chamfer_H >= Shoulder_Entry_Chamfer_R &&
       Shoulder_Entry_Chamfer_R > 0 && Shoulder_Entry_Chamfer_H < Shoulder_Bulk_T,
       "entry chamfer must be self-supporting and stay within the bulkhead");
assert(Shoulder_OD/2-Shoulder_Entry_Chamfer_R >= Shoulder_Bore_D/2+1,
       "entry chamfer must retain material outside the bulkhead slots");
// The smaller spigot bore used to start with a horizontal 1 mm ledge at
// Z=100. That ledge caused tall tree supports inside the otherwise open
// shoulder. Bring the bore inward over 2 mm instead: at 0.2 mm layers the
// wall advances only 0.1 mm per layer. External mating surfaces stay put.
Shoulder_Bore_Chamfer_H = 2;
assert(Shoulder_Bore_Chamfer_H >= (Shoulder_Bore_D-(Shoulder_Spigot_OD-NC_Wall_T*2))/2,
       "shoulder bore chamfer must be at least as tall as the radial step");
assert(Shoulder_Bore_Chamfer_H < Shoulder_L-Shoulder_Bulk_T,
       "shoulder bore chamfer must stay above the bulkhead");

// The bay is local to this camera variant; do not change NoseCone.scad's
// shared gluing flanges for all the other rockets. False reproduces the
// previous shell for comparison or for an already-glued nosecone.
Bay_Enabled = true;
include<PeregrineCamBay.scad>

// ============================================
// RENDER SELECTION -- change this value!
// ============================================
// 0 = Test ring (print first!)
// 1 = Shoulder + bulkhead + parachute anchor
// 2 = Bottom slice
// 3 = Middle slice
// 4 = Top slice + integral camera flange (removable service shell)
// 5 = Legacy separate adapter (only for Bay_Enabled=false)
// 6 = Battery carrier / sealed floor (print base-down, translate to bed)
// 7 = DC-DC tray / battery keeper (print upside-down, supports under rim)
// 8 = Bay cutaway assembly, for inspection only (not a printable part)
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

module CN_Slice_Middle_Shell(){
    // Everything below cut 2 (with its gluing flange), clipped above cut 1.
    intersection(){
        CN_Cone(Cut_d=Cut2_d, Lower=true);
        translate([0,0,Cut1_Z])
            cylinder(d=Peregrine_Body_OD+2, h=NC_Length, $fn=$preview? 90:360);
    } // intersection
} // CN_Slice_Middle

module CN_Slice_Middle(){
    if (Bay_Enabled) CN_Bay_Middle();
    else CN_Slice_Middle_Shell();
}

module CN_Slice_Top_Shell(){
    // Plain frustum shell, cut 2 to cut 3 (OD 60) -- no lens hole, no
    // camera mounts. The camera now lives entirely in the CAD nosecone
    // that glues onto this shell's open top via CN_Adapter().
    intersection(){
        CN_Cone(Cut_d=Cut2_d, Lower=false);
        cylinder(d=Peregrine_Body_OD+2, h=Cut3_Z, $fn=$preview? 90:360);
    } // intersection
} // CN_Slice_Top

module CN_Slice_Top(){
    if (Bay_Enabled) CN_Bay_Top();
    else CN_Slice_Top_Shell();
}

module CN_Adapter(){
    // Flange butts the CAD nosecone's base and carries its 3 mounting
    // screws; the spigot below is epoxied into the shell's Cut3 bore.
    // Spigot is tapered (d1 at the deep end, d2 at the flange) to track
    // the bore's own taper -- see Ogive_OD_At_Z and the comment on
    // Adapter_Spigot_OD_Top/_Bot above.
    difference(){
        union(){
            cylinder(d=Adapter_Flange_OD, h=Adapter_Flange_T, $fn=$preview? 90:360);
            translate([0,0,-Adapter_Spigot_L])
                cylinder(d1=Adapter_Spigot_OD_Bot, d2=Adapter_Spigot_OD_Top,
                         h=Adapter_Spigot_L+Overlap, $fn=$preview? 90:360);
        } // union

        // flange's own bore -- through the flange only
        translate([0,0,-Overlap])
            cylinder(d=Adapter_Bore_D, h=Adapter_Flange_T+Overlap*2, $fn=$preview? 60:180);

        // spigot's hollow -- through the spigot only, wider than the bore
        // above, leaving the insert shelf (see comment on Adapter_Bore_D)
        translate([0,0,-Adapter_Spigot_L-Overlap])
            cylinder(d=Adapter_Spigot_ID, h=Adapter_Spigot_L+Overlap, $fn=$preview? 60:180);

        // heat-set insert holes, through the flange only
        for (a=CAD_Bolt_A)
            translate([CAD_Bolt_R*cos(a), CAD_Bolt_R*sin(a), -Overlap])
                cylinder(d=Insert_Hole_D, h=Adapter_Flange_T+Overlap*2, $fn=$preview? 18:36);
    } // difference
} // CN_Adapter

module CN_Shoulder(){
    difference(){
        union(){
            rotate_extrude($fn=$preview?90:360)
                polygon(points=[
                    [0,0], [Shoulder_OD/2-Shoulder_Entry_Chamfer_R,0],
                    [Shoulder_OD/2,Shoulder_Entry_Chamfer_H],
                    [Shoulder_OD/2,Shoulder_L], [0,Shoulder_L]
                ]);
            translate([0,0,Shoulder_L])
                cylinder(d=Shoulder_Spigot_OD, h=Shoulder_Spigot_L,
                         $fn=$preview? 90:360);
        } // union
        // One continuous revolved bore avoids overlap between subtractive
        // cylinders leaving a residual horizontal lip at the transition.
        rotate_extrude($fn=$preview? 90:360)
            polygon(points=[
                [0, Shoulder_Bulk_T],
                [Shoulder_Bore_D/2, Shoulder_Bulk_T],
                [Shoulder_Bore_D/2, Shoulder_L-Shoulder_Bore_Chamfer_H],
                [Shoulder_Spigot_OD/2-NC_Wall_T, Shoulder_L],
                [Shoulder_Spigot_OD/2-NC_Wall_T, Shoulder_L+Shoulder_Spigot_L+Overlap],
                [0, Shoulder_L+Shoulder_Spigot_L+Overlap]
            ]);
        translate([0, Shoulder_Bore_D/2-4, -Overlap])
            RoundRect(X=16, Y=4, Z=Shoulder_Bulk_T+1, R=1.5);
        translate([0, -Shoulder_Bore_D/2+4, -Overlap])
            RoundRect(X=16, Y=4, Z=Shoulder_Bulk_T+1, R=1.5);
    } // difference
} // CN_Shoulder

module TestRing(){
    // The old 101.5 mm ring tested the outside profile; the subsequent
    // 99.7 mm insertion ring was too large. These five bands give a range
    // in one short print. Keep every test surface free of raised labels.
    // The bottom relief keeps first-layer flare off the largest test band.
    n = len(Shoulder_Fit_Gauge_Ds);
    h = n*Shoulder_Fit_Gauge_Step_H;
    lead = Shoulder_Fit_Gauge_Lead;
    difference(){
        rotate_extrude($fn=$preview?90:360)
            polygon(points=concat(
                [[0,0], [Shoulder_Fit_Gauge_Ds[n-1]/2-lead,0],
                 [Shoulder_Fit_Gauge_Ds[n-1]/2,lead]],
                [for (i=[0:n-2]) each [
                    [Shoulder_Fit_Gauge_Ds[n-1-i]/2,(i+1)*Shoulder_Fit_Gauge_Step_H],
                    [Shoulder_Fit_Gauge_Ds[n-2-i]/2,(i+1)*Shoulder_Fit_Gauge_Step_H]]],
                [[Shoulder_Fit_Gauge_Ds[0]/2,h-lead],
                 [Shoulder_Fit_Gauge_Ds[0]/2-lead,h], [0,h]]));
        translate([0,0,-Overlap])
            cylinder(d=Shoulder_Bore_D, h=h+Overlap*2,
                     $fn=$preview?90:360);
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
if (Render_Part == 6) CN_Battery_Carrier();
if (Render_Part == 7) CN_Converter_Tray();
if (Render_Part == 8) CN_Bay_Assembly();

// ============================================
// PRINT NOTES
// ============================================
//
// Parts:
//   0  Test ring        15mm   -- disposable fit check, print first, not glued
//   1  Shoulder        115mm
//   2  Bottom slice    147mm
//   3  Middle slice    147mm
//   4  Bay top          95mm   -- integral camera flange, print flange-down
//   5  Legacy adapter   21mm   -- not used with the bay top
//   6  Battery carrier  77mm   -- print floor-down
//   7  Converter tray   15mm   -- includes upper battery keeper
//
// Assembly, bottom to top:
//   1. Print part 0. Check it sits flush on the tube and accepts the spigot.
//   2. Glue the shoulder spigot into the bottom slice bore.
//   3. Glue the bottom slice flange into the middle slice, hold until set.
//   4. With Bay_Enabled, fit the carrier and seal its seat, then fasten the
//      top slice with three M3x8 screws. Do NOT glue that service joint.
//      See STL Files/PeregrineCamNose/README.md for the bay build sequence.
//      With Bay_Enabled=false only, glue the middle-to-top flange.
//   5. Melt three ruthex M3x5.7 inserts into the camera flange from its
//      top (mating) face, flush. Bolt the CAD nosecone (camera already
//      installed in it) onto the flange with three M3 screws down through
//      its sunken-head holes into those inserts.
//   6. With Bay_Enabled there is no separate adapter or glue joint here.
//      For the legacy Bay_Enabled=false shell only, epoxy part 5 into it.
//
// Parts 3 and 4 export at Z=147.15 and 294.29 rather than 0 -- drop to
// plate in the slicer.
//
// Part 5 (adapter): print flange-down -- rotate 180 deg about X or Y in the
// slicer so the flange sits on the bed and the spigot points up. As
// modeled/exported (flange up, spigot hanging below) the flange's
// underside is a horizontal shelf bridging over the open spigot hollow,
// carrying the 3 screw holes -- unsupported, it droops or needs support
// material on the exact face the screw heads have to bear on. Rotated
// 180 deg, every overhang in the part is self-supporting.
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
