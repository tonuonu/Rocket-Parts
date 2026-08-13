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
//  9 = Fin can
// 10 = Fin
// 11 = Motor retainer
// 12 = Motor spacer
Render_Part = 0;

// 0 = G80T-14A (124mm), 1 = H182R-14A (203mm), 2 = H135W-14A (216mm)
Motor_Class = 0;

// ============================================
// PARTS
// ============================================

// Print this FIRST. It gauges three fits on one 10mm part:
//   1. flange OD flush against the nosecone base (no step, either way)
//   2. the 3x M3 bolt circle and its clocking against the camera inserts
//   3. the coupler spigot inside a printed body tube
// If any of the three is wrong, nothing downstream is worth printing.
//
// No counterbore: this face mates with nothing (it is inside the
// airframe), so a plain clearance hole is the real joint and the gauge
// must match it, or it stops testing what actually gets bolted.
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
        R60_CameraBoltPattern()
            translate([0,0,-Overlap])
                cylinder(d=R60_Cam_Bolt_d, h=H_flange+H_spigot+Overlap*2);
    }
} // R60_TestRing

// The camera assembly fills the nosecone bore and sits flush with its base
// plane, so the neck cannot have a spigot - it is a butt joint. The three
// M3x10 SHCS pull it up into the camera's heat-set inserts; those screws
// and the flange face are the whole joint.
//
// No counterbore: the aft face (z=Flange_T) is inside the airframe and
// mates with nothing - the e-bay tube's end lands at r=28.4..30, clear of
// the r=18.98 bolt circle, so a screw head proud there touches nothing.
// Plain Ø3.4 through-holes give the full 5.0mm flange as grip under the
// head. M3x10 protrudes 10-5.0=5.0mm past the mating face, for 5.0mm of
// engagement in the camera's 5.7mm ruthex RX-M3x5.7 insert - does not
// bottom out.
//
// Load path: the shock cord anchors on the E-BAY AFT BULKHEAD, never here.
// These three screws only ever carry the nose section's own inertia.
module R60_Neck(){
    Flange_T = 5;      // grip under the screw head - see note above
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
        R60_CameraBoltPattern()
            translate([0,0,-Overlap])
                cylinder(d=R60_Cam_Bolt_d, h=Flange_T+Overlap*2);
    }
} // R60_Neck

// E-bay tube with the access opening and the arming switch hole.
//
// The switch is NOT optional and NOT interchangeable with the door: the
// CATS manual requires the board be powered up only once the rocket is
// vertical on the pad, and disarming afterwards is only possible by
// powering off. So it must be reachable on the rail.
module R60_EBayTube(){
    Sw_d = 12;   // panel-mount toggle
    difference(){
        R60_Tube(R60_EBay_L);
        translate([0,0,(R60_EBay_L-85)/2])
            rotate([0,0,0]) translate([-18,0,0])
                cube([36, R60_Body_OD, 85]);
        // Panel-mount arming switch, +Y, above the door aperture.
        //
        // Same side as the door on purpose: the retaining nut is tightened from
        // inside, and the door is the only hand access into the bore. A switch on
        // the opposite wall could not be fitted without cutting a second opening.
        //
        // Cuts ONE wall. A full-diameter cylinder on the axis would punch through
        // both and leave an open hole in the far side of the airframe.
        translate([0, R60_Body_OD/2, R60_EBay_L - 18])
            rotate([90, 0, 0])
                cylinder(d=Sw_d, h=R60_Wall_T*3, center=true);
    }
} // R60_EBayTube

module R60_ChuteTube(){ R60_Tube(R60_Chute_L); }

// Forward bulkhead: closes the top of the e-bay, passes the camera harness.
module R60_EBayFwdBulkhead(){
    T = 6;
    difference(){
        cylinder(d=R60_Coupler_OD, h=T);
        translate([0,0,-Overlap]) cylinder(d=22, h=T+Overlap*2);
    }
} // R60_EBayFwdBulkhead

// Aft bulkhead. THE structural part of the recovery system: the shock cord
// anchors here so deployment snatch never reaches the camera's three M3
// screws. Also carries both servos and passes their output aft.
//
// Servos stand UPRIGHT, shafts along the rocket axis, per
// PeregrineEjection.scad. Servo 1 is on the centreline and rotates the
// bayonet ring through its centre; servo 2 sits beside it and drives the
// tether latch through a slot. A radial layout is impossible: drive bore
// r=6 to disc edge r=28.2 is 22.2mm, an MG90S body is 22.8mm long.
//
// The MG90S output shaft is 5.5mm off the body centre, so servo 1's body
// is offset by that much to put its SHAFT on the axis, not its body.
module R60_EBayAftBulkhead(){
    T       = 12;
    P_L     = 23.0 + IDXtra;   // MG90S body footprint
    P_W     = 12.2 + IDXtra;
    P_D     = 9;               // pocket depth; leaves 3mm of aft material
    Shaft_d = 12;              // servo 1 output -> bayonet ring
    Horn_W  = 9;               // servo 2 horn slot
    Horn_L  = 24;
    S_Off   = 5.5;             // MG90S shaft offset from body centre
    S2_Y    = 13.6;            // 1.2mm pocket wall (3 perimeters @ 0.4mm nozzle)
    Cord_d  = 5;
    difference(){
        cylinder(d=R60_Coupler_OD, h=T);

        // servo 1 pocket, opens forward
        translate([-S_Off - P_L/2, -P_W/2, -Overlap])
            cube([P_L, P_W, P_D + Overlap]);
        // servo 1 shaft bore, through the remaining 3mm, on the axis
        translate([0, 0, P_D - Overlap])
            cylinder(d=Shaft_d, h=T - P_D + Overlap*2);

        // servo 2 pocket, offset in +Y
        translate([-S_Off - P_L/2, S2_Y - P_W/2, -Overlap])
            cube([P_L, P_W, P_D + Overlap]);
        // servo 2 horn slot through the remaining material
        translate([-Horn_L/2, S2_Y - Horn_W/2, P_D - Overlap])
            cube([Horn_L, Horn_W, T - P_D + Overlap*2]);

        // Shock cord anchor: two axial holes on the -Y side, clear of both
        // servos. The cord threads through both like a belt loop and passes
        // from the e-bay through to the chute bay. Axial rather than a
        // transverse bore because a Ø8 transverse hole in a 12mm disc would
        // leave 2mm of material each side on the ONE feature that carries
        // every deployment load in the vehicle.
        for (x=[-6, 6])
            translate([x, -22, -Overlap])
                cylinder(d=Cord_d, h=T + Overlap*2);
    }
} // R60_EBayAftBulkhead

// CATS Vega sled. Manual sec 4.3.3: mounting holes are 60 x 27mm apart,
// M3, and spacers are recommended so nothing touches the board.
//
// Orientation matters: the GNSS patch antenna must face RADIALLY OUTWARD
// with no battery, loom or metal between it and the airframe wall. Mark
// the antenna side on the print.
module R60_VegaSled(){
    T = 4;
    L = R60_Vega_L + 12;
    W = R60_Vega_W + 11;
    difference(){
        union(){
            translate([-W/2, -L/2, 0]) cube([W, L, T]);
            for (h=R60_Vega_Holes)
                translate([h[0], h[1], T-Overlap])
                    cylinder(d=7, h=R60_Vega_Standoff_h+Overlap);
        }
        for (h=R60_Vega_Holes)
            translate([h[0], h[1], -Overlap])
                cylinder(d=2.9, h=T+R60_Vega_Standoff_h+Overlap*2);
    }
} // R60_VegaSled

// Curved door panel, 4x M2.5. Sits in the opening cut above.
module R60_Door(){
    Gap = 0.35;   // per side
    difference(){
        intersection(){
            difference(){
                cylinder(d=R60_Body_OD, h=85-2*Gap);
                translate([0,0,-Overlap])
                    cylinder(d=R60_Body_OD-2*R60_Wall_T, h=85+Overlap*2);
            }
            translate([-(36-2*Gap)/2, 0, 0])
                cube([36-2*Gap, R60_Body_OD, 85-2*Gap]);
        }
        for (x=[-12,12], z=[8, 85-2*Gap-8])
            translate([x, R60_Body_OD/2, z]) rotate([90,0,0])
                cylinder(d=2.7, h=R60_Body_OD, center=true);
    }
} // R60_Door

// Fin can. 228mm because the longest 29mm H DMS (H135W) is 216mm - NOT
// because the G80T needs it. The G80T is 124mm and flies on a spacer.
// This is what makes the rocket H-ready without a reprint.
module R60_FinCan(){
    Ring_T   = 3;
    // Width already got IDXtra; a line-to-line fit lengthwise over 90mm is
    // not assemblable (layer bulge/elephant's foot/print scaling and the
    // fin won't enter, or splits the wall going in). The fin is epoxied in,
    // so a slip fit costs nothing - add IDXtra clearance at each end too.
    Slot_L   = R60_Fin_Root + 2*IDXtra;
    Slot_Z   = 8 - IDXtra;
    // Retainer bolt circle: sits in the open annulus between the MMT
    // (r=R60_MMT_OD/2=16) and the body ID (r=R60_Body_OD/2-R60_Wall_T=28.4),
    // offset 60deg from the fins (0/120/240) so the 3 bolts land between
    // the fins, not through them.
    Boss_BC_R = 24;
    Boss_d    = 8;      // >= 4.0 insert hole + 2x1.6 min wall (ruthex RX-M3x5.7)
    Boss_h    = 9;       // reaches/merges into the aft centering ring (z=6..9)
    Insert_d  = 4.0;     // ruthex RX-M3x5.7 hole per datasheet
    Insert_h  = 6.7;     // datasheet: insert L(5.7) + 1mm
    difference(){
        union(){
            R60_Tube(R60_FinCan_L);
            // MMT
            difference(){
                cylinder(d=R60_MMT_OD, h=R60_FinCan_L);
                translate([0,0,-Overlap])
                    cylinder(d=R60_MMT_ID, h=R60_FinCan_L+Overlap*2);
            }
            // Centering rings: aft, mid, forward.
            for (z=[6, R60_FinCan_L/2, R60_FinCan_L-Ring_T-6])
                translate([0,0,z]) difference(){
                    cylinder(d=R60_Body_ID, h=Ring_T);
                    translate([0,0,-Overlap])
                        cylinder(d=R60_MMT_OD-Overlap, h=Ring_T+Overlap*2);
                }
            // Retainer bolt bosses, aft end.
            for (i=[0:R60_nFins-1])
                rotate([0,0,i*360/R60_nFins + 180/R60_nFins])
                    translate([Boss_BC_R,0,0])
                        cylinder(d=Boss_d, h=Boss_h);
        }
        // Fin slots, through the outer wall only.
        for (i=[0:R60_nFins-1])
            rotate([0,0,i*360/R60_nFins])
                translate([R60_MMT_OD/2, -R60_Fin_T/2-IDXtra/2, Slot_Z])
                    cube([R60_Body_OD, R60_Fin_T+IDXtra, Slot_L]);
        // Retainer bolt bosses' blind inserts, cut from the aft face.
        for (i=[0:R60_nFins-1])
            rotate([0,0,i*360/R60_nFins + 180/R60_nFins])
                translate([Boss_BC_R, 0, -Overlap])
                    cylinder(d=Insert_d, h=Insert_h+Overlap);
    }
} // R60_FinCan

// Fin, printed flat. Low aspect ratio (0.88) is deliberate - it is what
// puts flutter velocity at ~850 m/s, 3.8x the H182R's 221 m/s. Do NOT
// thin it or extend the span without recomputing flutter.
module R60_Fin(){
    linear_extrude(height=R60_Fin_T)
        polygon([[0,0],
                 [R60_Fin_Root, 0],
                 [R60_Fin_Sweep+R60_Fin_Tip, R60_Fin_Span],
                 [R60_Fin_Sweep, R60_Fin_Span]]);
} // R60_Fin

// Aft retainer. Screws to the fin can and traps the motor's aft rim.
module R60_MotorRetainer(){
    T = 6;
    // Same bolt circle and 60deg fin offset as R60_FinCan()'s bosses.
    Bolt_BC_R = 24;
    Bolt_d    = 3.4;   // M3 clearance
    difference(){
        cylinder(d=R60_Body_OD, h=T);
        translate([0,0,-Overlap])
            cylinder(d=R60_MMT_ID-2.5, h=T+Overlap*2);
        for (i=[0:R60_nFins-1])
            rotate([0,0,i*360/R60_nFins + 180/R60_nFins])
                translate([Bolt_BC_R, 0, -Overlap])
                    cylinder(d=Bolt_d, h=T+Overlap*2);
    }
} // R60_MotorRetainer

// Forward spacer so a motor shorter than the 223mm MMT still sits flush at
// the aft end. Open bore: ejection gas and the forward closure pass through.
module R60_MotorSpacer(){
    L = R60_MMT_L - R60_Motor_L[Motor_Class];
    if (L > 1)
        difference(){
            cylinder(d=R60_MMT_ID-0.3, h=L);
            translate([0,0,-Overlap])
                cylinder(d=R60_MMT_ID-0.3-2*2.0, h=L+Overlap*2);
        }
} // R60_MotorSpacer

// ============================================
// DISPATCH
// ============================================
if (Render_Part==0) R60_TestRing();
if (Render_Part==1) R60_Neck();
if (Render_Part==2) R60_EBayTube();
if (Render_Part==3) R60_ChuteTube();
if (Render_Part==4) R60_EBayFwdBulkhead();
if (Render_Part==5) R60_EBayAftBulkhead();
if (Render_Part==6) R60_VegaSled();
if (Render_Part==7) R60_Door();
if (Render_Part==9)  R60_FinCan();
if (Render_Part==10) R60_Fin();
if (Render_Part==11) R60_MotorRetainer();
if (Render_Part==12) R60_MotorSpacer();
