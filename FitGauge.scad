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
// Mode 0, STEPPED PLUG (one print, immediate answer):
//   A stack of bands, each Step larger than the one above it, with its own
//   diameter embossed on it. Offer the small end up to the tube and push.
//   It stops at the first band that is too big; the largest band that
//   entered is your working diameter.
//
// Mode 1, SINGLE RING:
//   One ring at index Gauge_Index, if you would rather have separate
//   pieces than one staircase. Print several with different indices.
//
// Worked example - Peregrine shoulder into a 99.0 ID tube:
//   Gauge_Target_d=98.6, Gauge_Step=0.25, Gauge_Count=5
//   gives 98.10 98.35 98.60 98.85 99.10.
//   If 98.35 is the largest that enters, your parts are printing about
//   0.25mm oversize and every mating OD wants that much taken off.
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
Gauge_Target_d = 98.6;   // the diameter you are trying to hit
Gauge_Step     = 0.25;   // diametral step between bands
Gauge_Count    = 5;      // how many bands (odd puts Target in the middle)
Gauge_Band_H   = 7;      // height of each band
Gauge_Wall     = 3.0;    // wall thickness (bore = smallest band - 2*wall)
Gauge_Text     = 4.0;    // embossed digit height, 0 disables

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
// str() on a computed float yields e.g. "98.90000000000001". Round to 2dp so
// the engraved label reads as the diameter it actually is.
function gauge_label(d) = str(round(d*100)/100);

echo(str("Gauge diameters: ", [for(i=[0:Gauge_Count-1]) gauge_d(i)]));
echo(str("Bore: ", gauge_bore()));

// Diameter embossed on the band's outer face, readable with the part
// standing as printed. Sunk into the surface so it survives handling and
// cannot add to the measured OD - a raised numeral would fit worse than
// the band it labels, which would defeat the whole gauge.
module GaugeLabel(d, z){
    if (Gauge_Text > 0)
        translate([0, 0, z + Gauge_Band_H/2])
            rotate([0, 0, 0])
                linear_extrude(height=1.2, center=false)
                    translate([0, 0, 0])
                        text(gauge_label(d), size=Gauge_Text, halign="center",
                             valign="center", $fn=32);
}

module GaugeBand(i, z){
    d = gauge_d(i);
    difference(){
        translate([0,0,z]) cylinder(d=d, h=Gauge_Band_H);
        // sink the label into the outer wall
        if (Gauge_Text > 0)
            translate([0, -d/2 + 0.6, z + Gauge_Band_H/2])
                rotate([90, 0, 0])
                    linear_extrude(height=1.2)
                        text(gauge_label(d), size=Gauge_Text, halign="center",
                             valign="center");
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
if (Gauge_Mode == 0) SteppedPlug();
if (Gauge_Mode == 1) SingleRing();
