// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineEjection.scad
// Active Bayonet Ejection System for Apogee Peregrine
// Revision: 0.4 - Option B geometry (downward post, outward lugs)
//                 MG996R servo, Battery bay, side-mounted shock cord
// Units: mm
// ***********************************
//
// GEOMETRY (Option B):
//   Nose Cone Base has a DOWNWARD post with OUTWARD lugs at bottom
//   Bayonet Ring has an INNER lip with slots cut through it
//   Post inserts through lip, lugs pass slots, then rotate under lip
//   Springs push nose cone UP, lugs press against lip underside
//
// OPERATION:
//   Arm:     servo at ENTRY position, insert nose cone, servo to LOCK
//   Deploy:  servo to ENTRY position, springs eject nose cone
//
// ***********************************

include<NoseCone.scad>

Overlap = 0.05;

// ============================================
// TUBE DIMENSIONS
// ============================================

Body_OD = 101.5;
Body_ID = 99.0;
Coupler_OD = 98.0;
Coupler_ID = 92.0;
Wall_T = 3.0;

// ============================================
// MG996R SERVO DIMENSIONS
// ============================================

Servo_L = 40.7;
Servo_W = 19.7;
Servo_H = 42.9;
Servo_Mount_HoleSpacing = 49.5;
Servo_Mount_Ear_Y = 10;
Servo_Mount_Hole_D = 4.3;
Servo_Shaft_D = 5.75;

// ============================================
// CATS VEGA DIMENSIONS
// ============================================

Vega_L = 100;
Vega_W = 33;
Vega_H = 21;

// ============================================
// BATTERY (2S LiPo, typical)
// ============================================

Battery_L = 60;
Battery_W = 30;
Battery_H = 16;

// ============================================
// BAYONET GEOMETRY (Option B)
// ============================================

Post_OD = 30;
Post_H = 24;

Lug_OD = 44;
Lug_H = 4;
Lug_W_deg = 28;
nLugs = 3;

Ring_OD = 68;
Ring_Bore = 46;
Ring_Lip_Bore = 33;
Ring_H = 14;
Lip_T = 4;
Slot_W_deg = 34;

Lock_Angle = 30;

// ============================================
// SPRINGS
// ============================================

Spring_OD = 10;
Spring_Pocket_D = 11;
Spring_Free_L = 40;
Spring_R = 38;
nSprings = 3;

// ============================================
// E-BAY DIMENSIONS
// ============================================

EBay_L = 160;
TopBulkhead_T = 5;
BottomBulkhead_T = 3;

// ============================================
// RENDER SELECTION
// ============================================
// 0 = Assembly preview
// 1 = E-Bay Coupler
// 2 = Bayonet Ring
// 3 = Nose Cone Base (with post+lugs)
// 4 = Servo Mount Bracket
// 5 = Battery Tray
// 6 = Horn Coupler

Render_Part = 0;

// ============================================
// VISUALIZATION
// ============================================

module MG996R_Servo() {
    color("blue") {
        translate([-Servo_L/2, -Servo_W/2, 0])
            cube([Servo_L, Servo_W, Servo_H]);
        Ear_L = 7;
        translate([-Servo_Mount_HoleSpacing/2 - Ear_L/2, -Servo_W/2, 
                   Servo_H - Servo_Mount_Ear_Y - 2])
            cube([Ear_L, Servo_W, 2]);
        translate([Servo_Mount_HoleSpacing/2 - Ear_L/2, -Servo_W/2,
                   Servo_H - Servo_Mount_Ear_Y - 2])
            cube([Ear_L, Servo_W, 2]);
        translate([0, 0, Servo_H])
            cylinder(d=Servo_Shaft_D, h=3, $fn=24);
    }
}

module CATS_Vega() {
    color("green")
        translate([-Vega_L/2, -Vega_W/2, 0])
            cube([Vega_L, Vega_W, Vega_H]);
}

module LipoBattery() {
    color("red")
        translate([-Battery_L/2, -Battery_W/2, 0])
            cube([Battery_L, Battery_W, Battery_H]);
}

// ============================================
// PART 1: E-BAY COUPLER
// ============================================

module EBayCoupler() {
    ShockCord_Hole_D = 6;
    Bracket_Mount_Spacing = 60;
    
    difference() {
        union() {
            Tube(OD=Coupler_OD, ID=Coupler_ID, Len=EBay_L,
                 myfn=$preview? 90:360);
            
            translate([0, 0, EBay_L - TopBulkhead_T])
                cylinder(d=Coupler_OD, h=TopBulkhead_T,
                         $fn=$preview? 90:360);
            
            cylinder(d=Coupler_OD, h=BottomBulkhead_T,
                     $fn=$preview? 90:360);
        }
        
        // Central servo shaft hole
        translate([0, 0, EBay_L - TopBulkhead_T - Overlap])
            cylinder(d=14, h=TopBulkhead_T + 2*Overlap, $fn=48);
        
        // Servo bracket mounting holes
        for (a = [45, 135, 225, 315]) rotate([0, 0, a])
            translate([Bracket_Mount_Spacing/2, 0, 
                       EBay_L - TopBulkhead_T - Overlap])
                cylinder(d=3.4, h=TopBulkhead_T + 2*Overlap, $fn=24);
        
        // Shock cord anchor holes (bottom)
        for (x = [-1, 1])
            translate([x * 10, 0, -Overlap])
                cylinder(d=ShockCord_Hole_D, 
                         h=BottomBulkhead_T + 2*Overlap, $fn=24);
        
        // Side access slot for Vega
        translate([-Vega_L/2 - 1, -Coupler_OD/2 - 1, 30])
            cube([Vega_L + 2, Wall_T + 2, Vega_H + 4]);
        
        // Vent holes
        for (a = [60, 180, 300]) rotate([0, 0, a])
            translate([Coupler_OD/2, 0, EBay_L * 0.7])
                rotate([0, 90, 0])
                    cylinder(d=5, h=Wall_T + 2, center=true, $fn=24);
    }
}

// ============================================
// PART 2: BAYONET RING
// ============================================

module BayonetRing() {
    Hub_D = 22;
    Horn_Screw_D = 3.2;
    
    difference() {
        union() {
            cylinder(d=Ring_OD, h=Ring_H, $fn=$preview? 90:360);
            cylinder(d=Hub_D, h=Ring_H, $fn=$preview? 90:360);
        }
        
        // Main bore (below lip)
        translate([0, 0, -Overlap])
            cylinder(d=Ring_Bore, h=Ring_H - Lip_T + Overlap,
                     $fn=$preview? 90:360);
        
        // Narrow lip bore (top)
        translate([0, 0, Ring_H - Lip_T])
            cylinder(d=Ring_Lip_Bore, h=Lip_T + Overlap,
                     $fn=$preview? 90:360);
        
        // Central servo shaft
        translate([0, 0, -Overlap])
            cylinder(d=Servo_Shaft_D + 0.3, h=Ring_H + 2*Overlap, $fn=36);
        
        // Servo horn mount screw
        translate([0, 0, Ring_H - 8])
            cylinder(d=Horn_Screw_D, h=9, $fn=24);
        
        // LUG SLOTS in the lip
        for (i = [0:nLugs-1])
            rotate([0, 0, 360/nLugs * i - Slot_W_deg/2])
                rotate_extrude(angle=Slot_W_deg,
                               $fn=$preview? 90:360)
                    translate([Ring_Lip_Bore/2 - Overlap, 
                               Ring_H - Lip_T - Overlap])
                        square([(Ring_Bore - Ring_Lip_Bore)/2 + 2*Overlap,
                                Lip_T + 2*Overlap]);
    }
}

// ============================================
// PART 3: NOSE CONE BASE (Option B)
// ============================================

module NoseConeBase() {
    Plate_T = 6;
    Skirt_H = 20;
    Skirt_OD = Coupler_OD;
    NC_Rivet_OD = Skirt_OD;
    
    ShockCord_Holes_R = Spring_R + 12;
    nRivets = 3;
    
    difference() {
        union() {
            // Base plate
            cylinder(d=Skirt_OD, h=Plate_T, $fn=$preview? 90:360);
            
            // Upward skirt (into nose cone shell)
            translate([0, 0, Plate_T])
                Tube(OD=Skirt_OD, ID=Skirt_OD - 2*Wall_T, Len=Skirt_H,
                     myfn=$preview? 90:360);
            
            // DOWNWARD post
            translate([0, 0, -Post_H])
                cylinder(d=Post_OD, h=Post_H + Overlap,
                         $fn=$preview? 90:360);
            
            // OUTWARD lugs at bottom of post
            for (i = [0:nLugs-1])
                rotate([0, 0, 360/nLugs * i - Lug_W_deg/2])
                    rotate_extrude(angle=Lug_W_deg,
                                   $fn=$preview? 90:360)
                        translate([Post_OD/2 - Overlap, -Post_H])
                            square([(Lug_OD - Post_OD)/2 + Overlap,
                                    Lug_H]);
            
            // Spring guide pins
            for (i = [0:nSprings-1])
                rotate([0, 0, 360/nSprings * i + 60])
                    translate([Spring_R, 0, 0])
                        cylinder(d=Spring_OD - 1, h=Plate_T + 25,
                                 $fn=24);
        }
        
        // Central hole through post
        translate([0, 0, -Post_H - Overlap])
            cylinder(d=Post_OD - 2*Wall_T, 
                     h=Post_H + Plate_T + Skirt_H + 2*Overlap,
                     $fn=48);
        
        // Spring pockets in bottom
        for (i = [0:nSprings-1])
            rotate([0, 0, 360/nSprings * i + 60])
                translate([Spring_R, 0, -Overlap])
                    cylinder(d=Spring_Pocket_D, h=4, $fn=36);
        
        // Shock cord anchor holes (side-to-side)
        for (i = [0:nRivets-1])
            rotate([0, 0, 360/nRivets * i])
                translate([ShockCord_Holes_R, 0, 
                           Plate_T + Skirt_H - 5])
                    rotate([0, 90, 0])
                        cylinder(d=4, h=10, center=true, $fn=24);
        
        // Rivet holes for nose cone shell
        for (i = [0:nRivets-1])
            rotate([0, 0, 360/nRivets * i + 60])
                translate([NC_Rivet_OD/2 - Wall_T, 0, 
                           Plate_T + Skirt_H/2])
                    rotate([0, 90, 0])
                        cylinder(d=4, h=10, center=true, $fn=24);
    }
}

// ============================================
// PART 4: SERVO MOUNT BRACKET
// ============================================

module ServoBracket() {
    Bracket_L = Servo_Mount_HoleSpacing + 20;
    Bracket_W = Servo_W + 10;
    Bracket_T = 4;
    Bracket_Mount_Spacing = 60;
    
    difference() {
        union() {
            // Flange bolts to E-Bay top
            cylinder(d=Bracket_Mount_Spacing + 15, h=Bracket_T, 
                     $fn=$preview? 60:180);
            
            // Body extends down to servo ears
            translate([-Bracket_L/2, -Bracket_W/2, -Servo_Mount_Ear_Y - 3])
                cube([Bracket_L, Bracket_W, Servo_Mount_Ear_Y + 3 + Bracket_T]);
        }
        
        translate([0, 0, -20])
            cylinder(d=14, h=30, $fn=36);
        
        translate([-Servo_L/2 - 0.5, -Servo_W/2 - 0.5, -50])
            cube([Servo_L + 1, Servo_W + 1, 50 + Overlap]);
        
        for (x = [-1, 1])
            translate([x * Servo_Mount_HoleSpacing/2, 0, 
                       -Servo_Mount_Ear_Y - 3 - Overlap])
                cylinder(d=Servo_Mount_Hole_D, h=20, $fn=24);
        
        for (a = [45, 135, 225, 315]) rotate([0, 0, a])
            translate([Bracket_Mount_Spacing/2, 0, -Overlap])
                cylinder(d=3.4, h=Bracket_T + 2*Overlap, $fn=24);
    }
}

// ============================================
// PART 5: BATTERY TRAY
// ============================================

module BatteryTray() {
    Tray_L = Battery_L + 10;
    Tray_W = Battery_W + 6;
    Tray_H = Battery_H + 3;
    Tray_T = 2.5;
    
    difference() {
        union() {
            translate([-Tray_L/2, -Tray_W/2, 0])
                cube([Tray_L, Tray_W, Tray_T]);
            translate([-Tray_L/2, -Tray_W/2, 0])
                cube([Tray_L, Tray_T, Tray_H]);
            translate([-Tray_L/2, Tray_W/2 - Tray_T, 0])
                cube([Tray_L, Tray_T, Tray_H]);
            translate([-Tray_L/2, -Tray_W/2, 0])
                cube([Tray_T, Tray_W, Tray_H]);
            translate([Tray_L/2 - Tray_T, -Tray_W/2, 0])
                cube([Tray_T, Tray_W, Tray_H]);
        }
        
        for (x = [-1, 1])
            translate([x * Tray_L/4 - 2.5, -Tray_W/2 - Overlap, -Overlap])
                cube([5, Tray_W + 2*Overlap, Tray_T + 2*Overlap]);
    }
}

// ============================================
// PART 6: SERVO HORN COUPLER
// ============================================

module HornCoupler() {
    Coupler_D = 20;
    Coupler_H = 8;
    Horn_Square = 14;
    
    difference() {
        cylinder(d=Coupler_D, h=Coupler_H, $fn=48);
        
        translate([0, 0, -Overlap])
            cylinder(d=Servo_Shaft_D + 0.3, h=Coupler_H + 2*Overlap, $fn=24);
        
        translate([0, 0, -Overlap])
            for (a = [0, 90])
                rotate([0, 0, a])
                    translate([-Horn_Square/2, -2, 0])
                        cube([Horn_Square, 4, 4]);
        
        translate([0, 0, 4])
            cylinder(d=3.2, h=Coupler_H, $fn=24);
    }
}

// ============================================
// ASSEMBLY PREVIEW
// ============================================

module AssemblyPreview() {
    color("tan", 0.5) EBayCoupler();
    
    translate([0, 0, 40])
        CATS_Vega();
    
    translate([0, 0, 85])
        LipoBattery();
    
    translate([0, 0, EBay_L - TopBulkhead_T - Servo_H])
        MG996R_Servo();
    
    translate([0, 0, EBay_L + 1])
        color("orange", 0.7) BayonetRing();
    
    translate([0, 0, EBay_L + 1 + Ring_H + 25 + Post_H])
        color("yellow", 0.7) NoseConeBase();
}

// ============================================
// RENDER
// ============================================

if (Render_Part == 0) AssemblyPreview();
if (Render_Part == 1) EBayCoupler();
if (Render_Part == 2) BayonetRing();
if (Render_Part == 3) NoseConeBase();
if (Render_Part == 4) ServoBracket();
if (Render_Part == 5) BatteryTray();
if (Render_Part == 6) HornCoupler();

// ============================================
// NOTES
// ============================================
//
// OPERATION:
//   1. Power on -> Vega commands servo to ENTRY position
//   2. Align nose cone marks, lower onto E-Bay
//   3. Lugs pass through slots, springs compress
//   4. Vega commands servo to LOCK (rotate 30°)
//   5. Lugs now under solid lip, springs pre-loaded
//   6. Fly
//   7. At apogee: Vega -> servo to ENTRY position
//   8. Slots align with lugs, springs eject nose cone
//
// BACKUP DEPLOYMENT:
//   Keep one of Vega's 2 pyro channels as backup.
//
// PARTS NEEDED:
//   - MG996R servo (you have)
//   - CATS Vega
//   - 2S/3S LiPo battery (7-24V for Vega)
//   - 3x springs: 10mm OD, ~40mm free length, 0.3-0.5 N/mm
//   - M3 screws for bracket, 4mm rivets, shock cord
//
// ***********************************
