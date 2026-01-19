// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineEjection.scad
// Active Bayonet Ejection System for Apogee Peregrine
// Created: 2025-01-19
// Units: mm
// ***********************************
//
// Servo-actuated bayonet release with spring ejection
// Uses CATS Vega flight computer + MG90S servo
//
// ***********************************

include<NoseCone.scad>

Overlap = 0.05;
$fn = $preview ? 90 : 360;

// ============================================
// TUBE DIMENSIONS (from PeregrineNoseCone.scad)
// ============================================

Body_OD = 101.5;        // Body tube outer diameter
Body_ID = 99.0;         // Body tube inner diameter
Coupler_OD = 98.0;      // Fits inside body tube (ID - 1mm clearance)
Coupler_ID = 90.0;      // Inner diameter of coupler
Wall_T = 2.2;           // Standard wall thickness

// ============================================
// CATS VEGA DIMENSIONS
// ============================================

Vega_L = 100;           // Length
Vega_W = 33;            // Width  
Vega_H = 21;            // Height (without antenna)

// ============================================
// MG90S SERVO DIMENSIONS
// ============================================

Servo_L = 23;           // Length
Servo_W = 12.2;         // Width
Servo_H = 29;           // Height (with shaft)
Servo_Shaft_H = 4;      // Shaft height above body
Servo_Mount_W = 32.5;   // Width including mounting tabs
Servo_Mount_H = 2.5;    // Tab thickness
Servo_Mount_Y = 16;     // Distance from bottom to mount tabs

// ============================================
// BAYONET MECHANISM PARAMETERS
// ============================================

nLugs = 3;              // Number of bayonet lugs (120° apart)
Lug_W = 15;             // Lug width (circumferential)
Lug_H = 5;              // Lug height (axial)
Lug_D = 4;              // Lug depth (radial)
Lug_Angle = 30;         // Rotation angle to unlock (degrees)

// Lug position - must match between ring and base
Lug_R = Coupler_OD/2 - 5;  // Radius to lug outer edge

Spring_OD = 10;         // Compression spring outer diameter
Spring_Travel = 25;     // Compressed travel / ejection distance
nSprings = 3;           // Number of springs (between lugs)
Spring_R = Coupler_OD/2 - 20;  // Radius to spring centers

// ============================================
// E-BAY COUPLER DIMENSIONS  
// ============================================

EBay_L = 150;           // Total e-bay coupler length
Mechanism_H = 40;       // Height for bayonet mechanism + servo
Vega_Bay_H = 70;        // Height for Vega + wiring
Battery_Bay_H = 40;     // Height for battery

// ============================================
// RENDER SELECTION
// ============================================
// 0 = Full assembly (preview)
// 1 = E-Bay Coupler (lower section with Vega mount)
// 2 = Bayonet Ring (servo-driven rotating ring)
// 3 = Nose Cone Base (with lugs, attaches to nose cone)
// 4 = Servo Mount Bracket
// 5 = All parts exploded for print check

Render_Part = 0;

// ============================================
// VISUALIZATION MODULES
// ============================================

module MG90S_Servo() {
    color("blue") {
        // Main body
        translate([-Servo_L/2, -Servo_W/2, 0])
            cube([Servo_L, Servo_W, Servo_H - Servo_Shaft_H]);
        // Mounting tabs
        translate([-Servo_Mount_W/2, -Servo_W/2, Servo_Mount_Y])
            cube([Servo_Mount_W, Servo_W, Servo_Mount_H]);
        // Shaft
        translate([0, 0, Servo_H - Servo_Shaft_H])
            cylinder(d=12, h=Servo_Shaft_H, $fn=36);
    }
}

module CATS_Vega() {
    color("green")
        translate([-Vega_L/2, -Vega_W/2, 0])
            cube([Vega_L, Vega_W, Vega_H]);
}

// ============================================
// MAIN COMPONENTS
// ============================================

module EBayCoupler() {
    // Lower coupler section - holds Vega, battery, servo
    
    difference() {
        union() {
            // Main coupler tube
            difference() {
                cylinder(d=Coupler_OD, h=EBay_L);
                translate([0, 0, Wall_T])
                    cylinder(d=Coupler_ID, h=EBay_L);
            }
            
            // Bottom bulkhead
            cylinder(d=Coupler_OD, h=Wall_T);
            
            // Servo platform at top
            translate([0, 0, EBay_L - Mechanism_H])
                difference() {
                    cylinder(d=Coupler_ID - 1, h=Wall_T);
                    // Center hole for wires
                    cylinder(d=30, h=Wall_T + Overlap);
                }
            
            // Vega mounting posts
            for (a=[45, 135, 225, 315]) rotate([0, 0, a])
                translate([Coupler_ID/2 - 8, 0, Wall_T])
                    cylinder(d=8, h=Vega_Bay_H);
        }
        
        // Vega mounting screw holes
        for (a=[45, 135, 225, 315]) rotate([0, 0, a])
            translate([Coupler_ID/2 - 8, 0, Wall_T + Vega_Bay_H - 10])
                cylinder(d=3.2, h=15);
        
        // Vent holes
        for (a=[0:60:359]) rotate([0, 0, a])
            translate([Coupler_OD/2, 0, EBay_L/2])
                rotate([0, 90, 0])
                    cylinder(d=6, h=Wall_T + 2, center=true, $fn=24);
        
        // Wire passage from Vega bay to servo
        translate([Coupler_ID/2 - 15, 0, Vega_Bay_H])
            cylinder(d=10, h=EBay_L - Vega_Bay_H);
    }
}

module BayonetRing() {
    // Rotating ring driven by servo - engages/releases nose cone lugs
    
    Ring_H = Lug_H + 10;
    Ring_OD = Coupler_ID - 2;
    Ring_ID = Coupler_ID - 20;
    
    difference() {
        union() {
            // Main ring body
            difference() {
                cylinder(d=Ring_OD, h=Ring_H);
                translate([0, 0, -Overlap])
                    cylinder(d=Ring_ID, h=Ring_H + Overlap*2);
            }
            
            // Center hub for servo attachment
            cylinder(d=25, h=Ring_H);
        }
        
        // Bayonet lug L-slots (entry + lock)
        for (a=[0:360/nLugs:359]) rotate([0, 0, a]) {
            // Vertical entry slot
            translate([Lug_R - Lug_D - 1, -Lug_W/2 - 1, Ring_H - Lug_H - 2])
                cube([Lug_D + 5, Lug_W + 2, Lug_H + 3]);
            
            // Horizontal lock slot (rotated)
            rotate([0, 0, -Lug_Angle])
                translate([Lug_R - Lug_D - 1, -Lug_W/2 - 1, 3])
                    cube([Lug_D + 5, Lug_W + 2, Lug_H + 2]);
        }
        
        // Servo shaft hole (center)
        translate([0, 0, -Overlap])
            cylinder(d=8, h=Ring_H + Overlap*2, $fn=36);
        
        // Servo arm screw hole
        translate([0, 0, Ring_H - 6])
            cylinder(d=3, h=7, $fn=24);
    }
}

module NoseConeBase() {
    // Attaches to nose cone - has bayonet lugs and spring seats
    
    Base_H = 35;
    Plate_T = 5;  // Thicker bottom plate
    
    difference() {
        union() {
            // Outer skirt (matches body tube OD for flush fit)
            difference() {
                cylinder(d=Body_OD, h=Base_H);
                translate([0, 0, Plate_T])
                    cylinder(d=Body_OD - Wall_T*2, h=Base_H);
            }
            
            // Inner ring that engages with bayonet
            difference() {
                cylinder(d=Coupler_OD, h=Base_H);
                translate([0, 0, Plate_T])
                    cylinder(d=Coupler_OD - 10, h=Base_H);
            }
            
            // Solid bottom plate
            cylinder(d=Coupler_OD, h=Plate_T);
            
            // Bayonet lugs on inner ring
            for (a=[0:360/nLugs:359]) rotate([0, 0, a])
                translate([Lug_R - Lug_D, -Lug_W/2, Plate_T])
                    cube([Lug_D, Lug_W, Lug_H]);
            
            // Spring guide posts (connected to plate)
            for (a=[60, 180, 300]) rotate([0, 0, a])
                translate([Spring_R, 0, 0])
                    cylinder(d=Spring_OD - 2, h=Plate_T + Spring_Travel);
        }
        
        // Spring pockets in bottom plate
        for (a=[60, 180, 300]) rotate([0, 0, a])
            translate([Spring_R, 0, -Overlap])
                cylinder(d=Spring_OD + 1, h=3);
        
        // Center hole for shock cord
        translate([0, 0, -Overlap])
            cylinder(d=35, h=Base_H + Overlap*2);
        
        // Rivet holes to attach to nose cone
        for (a=[30, 150, 270]) rotate([0, 0, a])
            translate([Body_OD/2 - Wall_T, 0, Base_H - 10])
                rotate([0, 90, 0])
                    cylinder(d=4, h=Wall_T*2, $fn=24);
    }
}

module ServoMountBracket() {
    // Bracket to mount MG90S servo, attaches to e-bay top
    
    Bracket_L = 50;
    Bracket_W = Servo_Mount_W + 10;
    Bracket_H = 25;
    
    difference() {
        union() {
            // Base plate
            translate([-Bracket_L/2, -Bracket_W/2, 0])
                cube([Bracket_L, Bracket_W, 3]);
            
            // Side walls
            translate([-Bracket_L/2, -Bracket_W/2, 0])
                cube([3, Bracket_W, Bracket_H]);
            translate([Bracket_L/2 - 3, -Bracket_W/2, 0])
                cube([3, Bracket_W, Bracket_H]);
            
            // Servo mount rails
            translate([-Servo_Mount_W/2 - 2, -Servo_W/2 - 2, 0])
                cube([4, Servo_W + 4, Servo_Mount_Y + Servo_Mount_H]);
            translate([Servo_Mount_W/2 - 2, -Servo_W/2 - 2, 0])
                cube([4, Servo_W + 4, Servo_Mount_Y + Servo_Mount_H]);
        }
        
        // Servo body clearance
        translate([-Servo_L/2 - 1, -Servo_W/2 - 1, 3])
            cube([Servo_L + 2, Servo_W + 2, Bracket_H]);
        
        // Servo tab slots  
        translate([-Servo_Mount_W/2 - 1, -Servo_W/2 - 1, Servo_Mount_Y])
            cube([Servo_Mount_W + 2, Servo_W + 2, Servo_Mount_H + 1]);
        
        // Shaft hole through base
        cylinder(d=15, h=5);
        
        // Mounting holes for bracket
        for (x=[-1, 1]) for (y=[-1, 1])
            translate([x * (Bracket_L/2 - 6), y * (Bracket_W/2 - 6), -Overlap])
                cylinder(d=3.2, h=5, $fn=24);
    }
}

// ============================================
// ASSEMBLY PREVIEW
// ============================================

module Assembly() {
    // E-Bay Coupler at bottom
    color("tan", 0.5) EBayCoupler();
    
    // Servo bracket on top of coupler
    translate([0, 0, EBay_L - Mechanism_H + 5])
        color("gray") ServoMountBracket();
    
    // Servo in bracket
    translate([0, 0, EBay_L - Mechanism_H + 8])
        MG90S_Servo();
    
    // Bayonet ring above servo
    translate([0, 0, EBay_L + 5])
        color("orange", 0.7) BayonetRing();
    
    // Nose cone base on top (with gap to show separation)
    translate([0, 0, EBay_L + 35])
        color("yellow", 0.7) NoseConeBase();
    
    // Show Vega position
    translate([0, 0, 30])
        CATS_Vega();
}

// ============================================
// RENDER
// ============================================

if (Render_Part == 0) {
    Assembly();
}

if (Render_Part == 1) {
    EBayCoupler();
}

if (Render_Part == 2) {
    BayonetRing();
}

if (Render_Part == 3) {
    NoseConeBase();
}

if (Render_Part == 4) {
    ServoMountBracket();
}

if (Render_Part == 5) {
    // All parts laid out for print check
    translate([-60, 0, 0]) EBayCoupler();
    translate([60, 0, 0]) NoseConeBase();
    translate([0, 70, 0]) BayonetRing();
    translate([0, -50, 0]) ServoMountBracket();
}

// ============================================
// ASSEMBLY NOTES
// ============================================
//
// Operation:
// 1. Nose cone base attached to nose cone (rivets)
// 2. Insert compression springs on guide posts
// 3. Lower nose cone onto bayonet ring
// 4. Twist clockwise ~30° to lock lugs
// 5. At apogee, servo rotates ring counter-clockwise
// 6. Lugs release, springs push nose cone off
//
// Parts:
// - 3x compression springs: 10mm OD, 30-40mm length, light rate
// - MG90S servo
// - CATS Vega flight computer
// - M3 hardware for mounting
//
// ***********************************
