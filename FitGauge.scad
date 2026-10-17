// ***********************************
// Project: 3D Printed Rocket
// Filename: FitGauge.scad
// by Tõnu Samuel
// Created: 2026-08-13
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Find the diameter that actually fits YOUR tube, instead of trusting a
// nominal dimension or guessing at a shrinkage percentage.
//
// A nominal number tells you what the model is. It does not tell you what
// comes off your printer in your material. Rather than diagnose that, this
// prints a range of diameters and lets the tube pick the winner.
//
// This duplicates the "print this first" verification role that TestRing()
// already plays in PeregrineNoseCone.scad and PeregrineCamNose.scad. Left
// as a separate standalone tool rather than merged into those files - noted
// here per PR #21 review, not restructured.
//
// Mode 0, STEPPED PLUG (one print, immediate answer):
//   A stack of bands, each Step larger than the one above it, with its own
//   diameter engraved on it. Offer the small end up to the tube and push.
//   It stops at the first band that is too big; the largest band that
//   entered is your working diameter.
//
// Mode 1, SINGLE RING:
//   One ring at index Gauge_Index, if you would rather have separate
//   pieces than one staircase. Print several with different indices.
//
// What the reading is, and is not:
//   The largest band that enters is the biggest NOMINAL diameter that this
//   tube and this printer, together, will actually accept. It is not the
//   tube's true ID - printer error (over/under-extrusion, horizontal
//   expansion) shifts it too, and the gauge cannot separate the two. Never
//   use the reading to grow a mating OD past its designed target: mating
//   parts are deliberately drawn smaller than the nominal tube ID by some
//   clearance (see e.g. PeregrineNoseCone.scad's Shoulder_OD), and the
//   reading's job is to catch that clearance having been silently eaten,
//   not to invite spending it. See README.md for the worked table.
//
// Worked example - Peregrine shoulder (Ø98.6) into a 99.0 ID tube:
//   Gauge_Target_d=98.6, Gauge_Step=0.25, Gauge_Count=5
//   gives 98.10 98.35 98.60 98.85 99.10.
//   At 98.60 the designed 0.4mm clearance is exactly used up - it still
//   fits, but with no margin left. Below 98.60 (e.g. 98.35) the clearance
//   is gone and part of it is interference, by 98.60-98.35=0.25mm.
//   Above 98.60 (98.85, 99.10) more than the designed clearance survives -
//   no correction needed, and NOT a reason to size the shoulder up to it.
//
//  ***** History *****
//
function FitGauge_Rev()="FitGauge 0.1.0";
echo(FitGauge_Rev());
// 0.1.0  2026-08-13  First code.

Overlap = 0.05;
$fn = $preview ? 64 : 240;

// ============================================
// WHAT TO MEASURE - set these
// ============================================
// Mirrors PeregrineNoseCone.scad / PeregrineCamNose.scad:
//   Peregrine_Body_ID = 99.0            (tube ID)
//   Shoulder_OD       = Peregrine_Body_ID - 0.4   (0.4mm diametral clearance)
// FitGauge.scad is a standalone tool and deliberately does NOT
// `include <PeregrineNoseCone.scad>` to pick this up live: that file
// unconditionally renders TestRing() at its own Render_Part default (0),
// which would leak extra geometry into every FitGauge STL, and OpenSCAD's
// last-assignment-wins variable rule makes overriding that from here
// unreliable. So the two numbers below are a MANUAL MIRROR, not a live
// derivation - if Peregrine_Body_ID changes in either Peregrine file, this
// block and every shipped FitGauge STL go stale silently. Grep both files
// for "Peregrine_Body_ID" before trusting this default, and re-export the
// STLs under STL Files/FitGauge/ if it has moved.
Peregrine_Body_ID_mirror = 99.0;   // <- must match Peregrine_Body_ID upstream
Peregrine_Shoulder_Clearance = 0.4; // <- must match the "- 0.4" upstream

Gauge_Target_d = Peregrine_Body_ID_mirror - Peregrine_Shoulder_Clearance;
Gauge_Step     = 0.25;   // diametral step between bands
Gauge_Count    = 5;      // how many bands (odd puts Target in the middle)
Gauge_Band_H   = 7;      // height of each band
Gauge_Wall     = 3.0;    // wall thickness (bore = smallest band - 2*wall)
Gauge_Text     = 4.0;    // engraved digit height, 0 disables
Gauge_Text_Depth = 0.6;  // radial engraving depth, mm

// Mode 0 = stepped plug (all bands, one part)
// Mode 1 = single ring at Gauge_Index
Gauge_Mode  = 0;
Gauge_Index = 0;         // 0 = smallest band

// ============================================
// DERIVED - do not edit
// ============================================
function gauge_d(i) = Gauge_Target_d
                    - Gauge_Step*(Gauge_Count-1)/2
                    + Gauge_Step*i;
function gauge_min_d() = gauge_d(0);
function gauge_bore()  = gauge_min_d() - 2*Gauge_Wall;

// ============================================
// VALIDATION - fail loudly rather than silently export junk
// ============================================
assert(Gauge_Count >= 1,
       str("Gauge_Count must be >= 1, got ", Gauge_Count));
assert(Gauge_Index >= 0 && Gauge_Index < Gauge_Count,
       str("Gauge_Index must be in [0, Gauge_Count-1] = [0, ",
           Gauge_Count-1, "], got ", Gauge_Index));
assert(gauge_bore() > 0,
       str("Gauge_Wall (", Gauge_Wall, ") leaves a bore of ", gauge_bore(),
           "mm on the smallest band (", gauge_min_d(), "mm) - reduce ",
           "Gauge_Wall below ", gauge_min_d()/2,
           ", or this exports as a solid slug instead of a tube."));

// str() on a computed float keeps binary noise and drops trailing zeros
// ("98.90000000000001", or "98.9" instead of "98.90"), which both misstates
// the value and can make two distinct bands print the same label once
// Gauge_Step gets fine. Format to a fixed decimal count instead, derived
// from Gauge_Step so there is always just enough resolution to tell
// adjacent bands apart.
function gauge_decimals(step, d=0) =
    (d >= 6 || abs(step*pow(10,d) - round(step*pow(10,d))) < 1e-6)
        ? d : gauge_decimals(step, d+1);
Gauge_Label_Decimals = gauge_decimals(Gauge_Step);

function gauge_zpad(s, width) =
    len(s) >= width ? s : gauge_zpad(str("0", s), width);

function gauge_fixed(x, decimals) =
    let(scale = pow(10, decimals))
    let(n     = round(x*scale))
    let(sign  = n < 0 ? "-" : "")
    let(a     = abs(n))
    let(ip    = floor(a/scale))
    let(fp    = a - ip*scale)
    decimals == 0 ? str(sign, ip)
                  : str(sign, ip, ".", gauge_zpad(str(fp), decimals));

function gauge_label(d) = gauge_fixed(d, Gauge_Label_Decimals);

// No two bands may render the same label - too fine a Gauge_Step would
// otherwise round two adjacent diameters to one string and the gauge
// becomes unreadable (which band is which?).
function gauge_dup_pairs() =
    [for (i=[0:Gauge_Count-2], j=[i+1:Gauge_Count-1])
        if (gauge_label(gauge_d(i)) == gauge_label(gauge_d(j))) [i,j]];
assert(len(gauge_dup_pairs()) == 0,
       str("Gauge_Step (", Gauge_Step, ") is too fine for ",
           Gauge_Label_Decimals, " decimal place(s) - band pair(s) ",
           gauge_dup_pairs(), " would share a label."));

echo(str("Gauge diameters: ", [for(i=[0:Gauge_Count-1]) gauge_label(gauge_d(i))]));
echo(str("Bore: ", gauge_fixed(gauge_bore(), Gauge_Label_Decimals)));

// Cuts the label into the band's outer surface at a uniform RADIAL depth
// (Gauge_Text_Depth) regardless of string length or gauge diameter. Sunk,
// not raised: a raised numeral would fit worse than the band it labels,
// which would defeat the whole gauge - keep this subtractive.
// A single flat cutting plane loses depth toward the ends of the string as
// the true cylindrical surface curves away from that plane - on the
// shipped coarse gauge this collapsed from 0.60mm at centre to 0.33mm at
// the edge, and is fatal for longer labels on smaller-diameter gauges
// (PR #21 review). Intersecting a generously-sized flat text mask with a
// true constant-thickness annular shell fixes that: the shell alone
// defines the radial depth, the mask only supplies the (x,z) footprint.
module GaugeLabelCut(d, z){
    R = d/2;
    translate([0, 0, z])
        intersection(){
            difference(){
                cylinder(r=R+Overlap, h=Gauge_Band_H);
                cylinder(r=R-Gauge_Text_Depth, h=Gauge_Band_H);
            }
            translate([0, 0, Gauge_Band_H/2])
                rotate([90, 0, 0])
                    linear_extrude(height=R+Overlap+1)
                        text(gauge_label(d), size=Gauge_Text, halign="center",
                             valign="center", $fn=32);
        }
}

module GaugeBand(i, z){
    d = gauge_d(i);
    difference(){
        translate([0,0,z]) cylinder(d=d, h=Gauge_Band_H);
        // sink the label into the outer wall - see GaugeLabelCut for why
        // this is not a flat cut.
        if (Gauge_Text > 0) GaugeLabelCut(d, z);
    }
}

// Largest band on the bed for adhesion; diameters decrease upward, so the
// top is the end you offer to the tube.
module SteppedPlug(){
    difference(){
        union(){
            for (i=[0:Gauge_Count-1])
                GaugeBand(Gauge_Count-1-i, i*Gauge_Band_H);
        }
        translate([0,0,-Overlap])
            cylinder(d=gauge_bore(),
                     h=Gauge_Count*Gauge_Band_H + Overlap*2);
    }
}

module SingleRing(){
    difference(){
        GaugeBand(Gauge_Index, 0);
        translate([0,0,-Overlap])
            cylinder(d=gauge_bore(), h=Gauge_Band_H + Overlap*2);
    }
}

// ============================================
// RENDER
// ============================================
// -D Gauge_Mode=2 (or any value other than 0/1) would otherwise fall
// through both ifs below with no render and no error - a 0-triangle STL
// that OpenSCAD still exits 0 on. Fail loudly instead.
assert(Gauge_Mode == 0 || Gauge_Mode == 1,
       str("Gauge_Mode must be 0 (stepped plug) or 1 (single ring), got ",
           Gauge_Mode));
if (Gauge_Mode == 0) SteppedPlug();
if (Gauge_Mode == 1) SingleRing();
