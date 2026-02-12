// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineEjection.scad
// Active Bayonet Ejection System for Apogee Peregrine
// Created: 2025-01-19
// Revision: 0.3 - Simplified geometry, fixed floating parts
// Units: mm
// ***********************************

include<NoseCone.scad>

// ============================================
// TUBE DIMENSIONS
// ============================================

Body_OD = 101.5;        // Body tube outer diameter
Body_ID = 99.0;         // Body tube inner diameter
Coupler_OD = 98.0;      // Fits inside body tube
Coupler_ID = 92.0;      // Inner diameter of coupler
Wall_T = 3.0;           // Wall thickness

// ============================================
// CATS VEGA DIMENSIONS (100 x 33 x 21 mm)
// ============================================

Vega_L = 100;
Vega_W = 33;
Vega_H = 21;

// ============================================
// MG90S SERVO DIMENSIONS
// ============================================

Servo_L = 23;
Servo_W = 12.2;
Servo_H = 29;
Servo_Mount_W = 32.5;
Servo_Mount_H = 2.5;
Servo_Mount_Y = 16;

// ============================================
// BAYONET PARAMETERS
// ============================================

nLugs = 3;
Lug_W = 12;
Lug_H = 5;
Lug_D = 4;
Lug_Angle = 30;
Lug_R = 40;             // Radius to lug center (fixed value)

Spring_OD = 10;
Spring_R = 25;          // Radius to spring center (fixed value)

// ============================================
// E-BAY DIMENSIONS
// ============================================

EBay_L = 120;

// ============================================
// RENDER SELECTION
// ============================================
// 0 = Assembly preview
// 1 = E-Bay Coupler
// 2 = Bayonet Ring  
// 3 = Nose Cone Base
// 4 = Servo Bracket

Render_Part = 0;

// ============================================
// VISUALIZATION
// ============================================

module MG90S_Servo() {
    color("blue") {
        translate([-Servo_L/2, -Servo_W/2, 0])
            cube([Servo_L, Servo_W, Servo_H - 4]);
        translate([-Servo_Mount_W/2, -Servo_W/2, Servo_Mount_Y])
            cube([Servo_Mount_W, Servo_W, Servo_Mount_H]);
        translate([0, 0, Servo_H - 4])
            cylinder(d=12, h=4, $fn=36);
    }
}

module CATS_Vega() {
    color("green")
        translate([-Vega_L/2, -Vega_W/2, 0])
            cube([Vega_L, Vega_W, Vega_H]);
}

// ============================================
// PART 1: E-BAY COUPLER
// ============================================

module EBayCoupler() {
    difference() {
        union() {
            // Main tube wall
            Tube(OD=Coupler_OD, ID=Coupler_ID, Len=EBay_L, myfn=$preview? 90:360);
            
            // Bottom bulkhead (solid with center hole)
            cylinder(d=Coupler_OD, h=Wall_T, $fn=$preview? 90:360);
            
            // Top bulkhead
            translate([0, 0, EBay_L - Wall_T])
                cylinder(d=Coupler_OD, h=Wall_T, $fn=$preview? 90:360);
        }
        
        // Center hole bottom (for wires)
        translate([0, 0, -1])
            cylinder(d=25, h=Wall_T + 2, $fn=48);
        
        // Center hole top (for servo shaft)
        translate([0, 0, EBay_L - Wall_T - 1])
            cylinder(d=20, h=Wall_T + 2, $fn=48);
        
        // Servo pocket from top
        translate([-Servo_L/2 - 1, -Servo_W/2 - 1, EBay_L - 35])
            cube([Servo_L + 2, Servo_W + 2, 35 - Wall_T + 1]);
        
        // Vega access slot (side opening)
        translate([-Vega_L/2 - 1, -Coupler_OD/2 - 1, 15])
            cube([Vega_L + 2, Coupler_OD/2 - Coupler_ID/2 + 5, Vega_H + 5]);
        
        // Vent holes
        for (a=[60, 180, 300]) rotate([0, 0, a])
            translate([Coupler_OD/2, 0, EBay_L/2])
                rotate([0, 90, 0])
                    cylinder(d=8, h=10, center=true, $fn=24);
    }
}

// ============================================
// PART 2: BAYONET RING
// ============================================

module BayonetRing() {
    Ring_H = 12;
    Ring_OD = Coupler_ID - 2;
    Ring_ID = 50;
    
    difference() {
        // Solid ring with center hub
        union() {
            cylinder(d=Ring_OD, h=Ring_H, $fn=$preview? 90:360);
        }
        
        // Hollow out the ring (leave hub solid)
        translate([0, 0, -1])
            difference() {
                cylinder(d=Ring_OD - 12, h=Ring_H + 2, $fn=$preview? 90:360);
                cylinder(d=30, h=Ring_H + 2, $fn=48);
            }
        
        // Center hole for servo
        translate([0, 0, -1])
            cylinder(d=8, h=Ring_H + 2, $fn=36);
        
        // Servo screw hole
        translate([0, 0, Ring_H - 5])
            cylinder(d=4, h=6, $fn=24);
        
        // Bayonet L-slots
        for (a=[0, 120, 240]) rotate([0, 0, a]) {
            // Entry slot (top, lug enters here)
            translate([Lug_R - Lug_D, -Lug_W/2 - 1, Ring_H - Lug_H - 1])
                cube([Lug_D + 8, Lug_W + 2, Lug_H + 2]);
            
            // Lock slot (rotated, lug locks here)
            rotate([0, 0, -Lug_Angle])
                translate([Lug_R - Lug_D, -Lug_W/2 - 1, 2])
                    cube([Lug_D + 8, Lug_W + 2, Lug_H + 1]);
        }
        
        // Spoke cutouts for weight reduction
        for (a=[60, 180, 300]) rotate([0, 0, a])
            translate([Ring_OD/2 - 15, -8, -1])
                cube([10, 16, Ring_H + 2]);
    }
}

// ============================================
// PART 3: NOSE CONE BASE
// ============================================

module NoseConeBase() {
    Base_H = 30;
    Plate_T = 6;
    Inner_R = 35;  // Shock cord hole radius / 2
    
    difference() {
        union() {
            // Solid base plate
            cylinder(d=Coupler_OD, h=Plate_T, $fn=$preview? 90:360);
            
            // Outer skirt wall
            Tube(OD=Body_OD, ID=Body_OD - Wall_T*2, Len=Base_H, myfn=$preview? 90:360);
            
            // Inner ring with lugs
            Tube(OD=Lug_R*2 + Lug_D + 4, ID=Inner_R*2, Len=Base_H, myfn=$preview? 90:360);
            
            // Bayonet lugs (attached to inner ring)
            for (a=[0, 120, 240]) rotate([0, 0, a])
                translate([Lug_R, -Lug_W/2, Plate_T])
                    cube([Lug_D, Lug_W, Lug_H]);
            
            // Radial ribs connecting outer to inner
            for (a=[60, 180, 300]) rotate([0, 0, a])
                translate([-3, Inner_R, 0])
                    cube([6, (Body_OD/2 - Wall_T) - Inner_R, Plate_T]);
            
            // Spring seats on ribs (solid cylinders)
            for (a=[60, 180, 300]) rotate([0, 0, a])
                translate([0, Spring_R, 0])
                    cylinder(d=Spring_OD + 4, h=Plate_T + 5, $fn=36);
        }
        
        // Center shock cord hole
        translate([0, 0, -1])
            cylinder(d=Inner_R*2, h=Base_H + 2, $fn=48);
        
        // Spring guide holes (goes through spring seats)
        for (a=[60, 180, 300]) rotate([0, 0, a])
            translate([0, Spring_R, -1])
                cylinder(d=Spring_OD + 1, h=Plate_T + 2, $fn=36);
        
        // Spring pin holes
        for (a=[60, 180, 300]) rotate([0, 0, a])
            translate([0, Spring_R, Plate_T])
                cylinder(d=4, h=10, $fn=24);
        
        // Rivet holes
        for (a=[30, 150, 270]) rotate([0, 0, a])
            translate([Body_OD/2 - Wall_T, 0, Base_H - 8])
                rotate([0, 90, 0])
                    cylinder(d=4, h=Wall_T*2 + 2, center=true, $fn=24);
    }
}

// ============================================
// PART 4: SERVO BRACKET (optional)
// ============================================

module ServoBracket() {
    difference() {
        union() {
            // Base
            translate([-25, -12, 0])
                cube([50, 24, 3]);
            // Walls
            translate([-Servo_L/2 - 3, -Servo_W/2 - 2, 0])
                cube([3, Servo_W + 4, 20]);
            translate([Servo_L/2, -Servo_W/2 - 2, 0])
                cube([3, Servo_W + 4, 20]);
        }
        
        // Servo clearance
        translate([-Servo_L/2 - 0.5, -Servo_W/2 - 0.5, 3])
            cube([Servo_L + 1, Servo_W + 1, 25]);
        
        // Servo tabs
        translate([-Servo_Mount_W/2 - 0.5, -Servo_W/2 - 0.5, Servo_Mount_Y])
            cube([Servo_Mount_W + 1, Servo_W + 1, Servo_Mount_H + 1]);
        
        // Shaft hole
        cylinder(d=15, h=5, $fn=36);
        
        // Mount holes
        for (x=[-1, 1]) for (y=[-1, 1])
            translate([x*20, y*8, -1])
                cylinder(d=3.2, h=5, $fn=24);
    }
}

// ============================================
// ASSEMBLY
// ============================================

module Assembly() {
    // E-Bay
    color("tan", 0.7) EBayCoupler();
    
    // Servo
    translate([0, 0, EBay_L - 32])
        MG90S_Servo();
    
    // Bayonet Ring
    translate([0, 0, EBay_L + 3])
        color("orange", 0.8) BayonetRing();
    
    // Nose Cone Base (separated to show spring gap)
    translate([0, 0, EBay_L + 3 + 12 + 20])
        color("yellow", 0.8) NoseConeBase();
    
    // Vega
    translate([0, 0, 25])
        CATS_Vega();
}

// ============================================
// RENDER
// ============================================

if (Render_Part == 0) Assembly();
if (Render_Part == 1) EBayCoupler();
if (Render_Part == 2) BayonetRing();
if (Render_Part == 3) NoseConeBase();
if (Render_Part == 4) ServoBracket();

// ============================================
// NOTES
// ============================================
//
// ASSEMBLY ORDER:
// 1. Mount Vega in E-Bay
// 2. Mount servo at E-Bay top
// 3. Attach servo horn to Bayonet Ring center
// 4. Glue E-Bay into body tube
// 5. Rivet Nose Cone Base to nose cone
// 6. Insert springs (10mm OD, ~30mm long)
// 7. Lock: push down + twist 30° clockwise
// 8. Unlock: servo rotates ring 30° counter-clockwise
//
// ***********************************
