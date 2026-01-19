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
Vega_Mount_Holes = 3;   // M3 mounting holes

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
Lug_W = 12;             // Lug width (circumferential)
Lug_H = 4;              // Lug height (axial)
Lug_D = 3;              // Lug depth (radial)
Lug_Angle = 25;         // Rotation angle to unlock (degrees)

Spring_OD = 10;         // Compression spring outer diameter
Spring_ID = 8;          // Spring inner diameter
Spring_Free_L = 40;     // Free length
Spring_Travel = 25;     // Compressed travel / ejection distance
nSprings = 3;           // Number of springs (between lugs)
Spring_Pocket_D = 12;   // Pocket diameter for spring

// ============================================
// E-BAY COUPLER DIMENSIONS  
// ============================================

EBay_L = 150;           // Total e-bay coupler length
Mechanism_H = 35;       // Height for bayonet mechanism + servo
Vega_Bay_H = 60;        // Height for Vega + wiring
Battery_Bay_H = 45;     // Height for battery

// ============================================
// RENDER SELECTION
// ============================================
// 0 = Full assembly (preview)
// 1 = E-Bay Coupler (lower section with Vega mount)
// 2 = Bayonet Ring (servo-driven rotating ring)
// 3 = Nose Cone Base (with lugs, attaches to nose cone)
// 4 = Servo Mount Bracket
// 5 = Test fit ring

Render_Part = 0;

// ============================================
// COMMON MODULES
// ============================================

module MG90S_Servo() {
    // Servo body visualization
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
    // Vega visualization
    color("green")
        translate([-Vega_L/2, -Vega_W/2, 0])
            cube([Vega_L, Vega_W, Vega_H]);
}

module SpringPocket(depth=15) {
    // Pocket for compression spring
    cylinder(d=Spring_Pocket_D, h=depth, $fn=36);
    // Guide pin hole
    translate([0, 0, -0.1])
        cylinder(d=Spring_ID-1, h=depth+0.2, $fn=24);
}

// ============================================
// BAYONET LUG PROFILES
// ============================================

module BayonetLug() {
    // Single bayonet lug (L-shaped for twist lock)
    hull() {
        cube([Lug_D, Lug_W, Lug_H]);
        translate([0, Lug_W, 0])
            cube([Lug_D, 0.1, Lug_H]);
    }
}

module BayonetLugCutout() {
    // Cutout in ring for lug to pass through and lock
    Entry_W = Lug_W + 2;  // Wider entry
    Lock_W = Lug_W + 1;
    
    // Entry slot (vertical)
    translate([0, -Entry_W/2, 0])
        cube([Lug_D + 2, Entry_W, Lug_H + 5]);
    
    // Lock slot (rotated)
    rotate([0, 0, -Lug_Angle])
        translate([0, -Lock_W/2, 0])
            cube([Lug_D + 2, Lock_W, Lug_H + 1]);
    
    // Transition between entry and lock
    hull() {
        translate([0, -Entry_W/2, 0])
            cube([Lug_D + 2, Entry_W, 0.1]);
        rotate([0, 0, -Lug_Angle])
            translate([0, -Lock_W/2, 0])
                cube([Lug_D + 2, Lock_W, 0.1]);
    }
}

// ============================================
// MAIN COMPONENTS
// ============================================

module EBayCoupler() {
    // Lower coupler section - holds Vega, servo, and bayonet mechanism base
    
    difference() {
        union() {
            // Main coupler tube
            Tube(OD=Coupler_OD, ID=Coupler_ID, Len=EBay_L, myfn=$preview? 90:360);
            
            // Bulkhead at bottom
            cylinder(d=Coupler_OD, h=Wall_T, $fn=$preview? 90:360);
            
            // Servo mount platform
            translate([0, 0, EBay_L - Mechanism_H])
                cylinder(d=Coupler_ID - 2, h=Wall_T, $fn=$preview? 90:360);
        }
        
        // Vega mounting slot
        translate([0, 0, 20])
            rotate([90, 0, 0])
                translate([-Vega_L/2 - 1, -1, -Coupler_ID/2])
                    cube([Vega_L + 2, Vega_H + 5, Coupler_ID]);
        
        // Servo pocket
        translate([0, 0, EBay_L - Mechanism_H + Wall_T]) {
            // Servo body
            translate([0, 0, 0])
                cube([Servo_L + 1, Servo_W + 1, 30], center=true);
            // Servo shaft clearance
            translate([0, 0, 15])
                cylinder(d=15, h=20, $fn=36);
        }
        
        // Wire passage holes
        for (a=[0, 120, 240]) rotate([0, 0, a])
            translate([Coupler_ID/2 - 5, 0, 0])
                cylinder(d=8, h=EBay_L, $fn=24);
        
        // Vent holes
        for (a=[60, 180, 300]) rotate([0, 0, a])
            translate([0, Coupler_OD/2 - Wall_T/2, EBay_L/2])
                rotate([0, 90, 0])
                    cylinder(d=5, h=Wall_T + 2, center=true, $fn=24);
    }
    
    // Vega mounting rails
    for (y=[-1, 1]) 
        translate([-Vega_L/2, y * (Vega_W/2 + 2), 20])
            cube([Vega_L, 2, Vega_H]);
}

module BayonetRing() {
    // Rotating ring driven by servo - engages/releases nose cone lugs
    
    Ring_H = Lug_H + 8;
    Ring_OD = Coupler_ID - 1;
    Ring_ID = Ring_OD - 10;
    
    difference() {
        union() {
            // Main ring
            Tube(OD=Ring_OD, ID=Ring_ID, Len=Ring_H, myfn=$preview? 90:360);
            
            // Servo arm attachment hub
            translate([0, 0, Ring_H/2])
                cylinder(d=20, h=Ring_H/2, $fn=36);
        }
        
        // Bayonet lug slots
        for (a=[0:360/nLugs:359]) rotate([0, 0, a])
            translate([Ring_OD/2 - Lug_D, 0, 2])
                BayonetLugCutout();
        
        // Servo arm attachment hole
        translate([0, 0, Ring_H - 5])
            cylinder(d=6, h=6, $fn=36);
        
        // Servo arm screw hole
        translate([0, 0, Ring_H - 2])
            cylinder(d=2.5, h=3, $fn=24);
    }
}

module NoseConeBase() {
    // Attaches to nose cone - has bayonet lugs and spring seats
    
    Base_H = 30;
    Lug_R = (Coupler_ID - 2) / 2 - Lug_D/2;  // Radius to lug center
    Spring_R = Lug_R - 10;  // Springs inboard of lugs
    
    difference() {
        union() {
            // Outer ring (matches nose cone ID interface)
            Tube(OD=Body_OD, ID=Coupler_OD + 0.5, Len=Base_H, myfn=$preview? 90:360);
            
            // Inner structure
            Tube(OD=Coupler_OD, ID=Coupler_OD - 8, Len=Base_H, myfn=$preview? 90:360);
            
            // Bottom plate
            translate([0, 0, 0])
                cylinder(d=Coupler_OD, h=Wall_T, $fn=$preview? 90:360);
            
            // Bayonet lugs
            for (a=[0:360/nLugs:359]) rotate([0, 0, a])
                translate([Lug_R, -Lug_W/2, Wall_T])
                    BayonetLug();
            
            // Spring guide posts
            for (a=[60, 180, 300]) rotate([0, 0, a])
                translate([Spring_R, 0, Wall_T])
                    cylinder(d=Spring_ID - 1.5, h=Spring_Travel, $fn=24);
        }
        
        // Spring pockets (in bottom plate)
        for (a=[60, 180, 300]) rotate([0, 0, a])
            translate([Spring_R, 0, -0.1])
                cylinder(d=Spring_Pocket_D, h=Wall_T + 0.2, $fn=36);
        
        // Center hole for shock cord
        translate([0, 0, -0.1])
            cylinder(d=30, h=Base_H + 0.2, $fn=48);
        
        // Rivet holes to attach to nose cone
        for (a=[0:120:359]) rotate([0, 0, a + 60])
            translate([Body_OD/2 - Wall_T/2, 0, Base_H/2])
                rotate([0, 90, 0])
                    cylinder(d=4, h=Wall_T + 2, center=true, $fn=24);
    }
}

module ServoMountBracket() {
    // Bracket to mount MG90S servo in e-bay
    
    Bracket_W = Servo_Mount_W + 8;
    Bracket_D = Servo_W + 6;
    Bracket_H = Servo_Mount_Y + Servo_Mount_H + 2;
    
    difference() {
        // Main bracket body
        translate([-Bracket_W/2, -Bracket_D/2, 0])
            cube([Bracket_W, Bracket_D, Bracket_H]);
        
        // Servo body pocket
        translate([-Servo_L/2 - 0.5, -Servo_W/2 - 0.5, 3])
            cube([Servo_L + 1, Servo_W + 1, Bracket_H]);
        
        // Servo tab slots
        translate([-Servo_Mount_W/2 - 0.5, -Servo_W/2 - 0.5, Servo_Mount_Y])
            cube([Servo_Mount_W + 1, Servo_W + 1, Servo_Mount_H + 1]);
        
        // Mounting screw holes
        for (x=[-1, 1]) for (y=[-1, 1])
            translate([x * (Bracket_W/2 - 4), y * (Bracket_D/2 - 4), -0.1])
                cylinder(d=3.2, h=4, $fn=24);
    }
}

module TestFitRing() {
    // Test ring to verify bayonet lug engagement
    
    Ring_H = 20;
    
    difference() {
        cylinder(d=Coupler_OD, h=Ring_H, $fn=90);
        
        // Lug slots
        for (a=[0:360/nLugs:359]) rotate([0, 0, a])
            translate([(Coupler_ID-2)/2 - Lug_D - 5, 0, 5])
                BayonetLugCutout();
        
        // Center hole
        translate([0, 0, -0.1])
            cylinder(d=Coupler_ID - 20, h=Ring_H + 0.2, $fn=90);
    }
}

// ============================================
// RENDER
// ============================================

if (Render_Part == 0) {
    // Full assembly preview
    color("tan", 0.3) EBayCoupler();
    
    translate([0, 0, EBay_L - 10])
        color("orange") BayonetRing();
    
    translate([0, 0, EBay_L + 20])
        color("yellow") NoseConeBase();
    
    // Show Vega position
    translate([0, 0, 40])
        rotate([90, 0, 0])
            CATS_Vega();
    
    // Show servo position  
    translate([0, 0, EBay_L - Mechanism_H + 10])
        MG90S_Servo();
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
    TestFitRing();
}

// ============================================
// ASSEMBLY NOTES
// ============================================
//
// 1. E-Bay Coupler glues into body tube
// 2. CATS Vega mounts on rails, connect servo to servo channel
// 3. Bayonet Ring sits on top, servo arm attaches to hub
// 4. Nose Cone Base attaches to nose cone with rivets
// 5. Insert 3x compression springs (10mm OD, ~40mm free length)
// 6. Twist nose cone to lock lugs, servo unlocks at apogee
//
// Springs: McMaster 9657K356 or similar
// (10mm OD, 40mm free length, ~0.5N/mm rate)
//
// ***********************************
