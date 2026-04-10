// ***********************************
// Project: Camera Rocket
// Filename: CamRocket.scad
// Created: 2025-01-04
// Units: mm
// ***********************************
// 3D printed rocket
// 3 parts: Nosecone, Body tube, Fin can
// Coordinate system: Z=0 at motor nozzle, Z+ toward nose
// ***********************************

// ***** Parameters *****

// Body tube
body_od = 75;           // outer diameter
body_wall = 1.8;        // wall thickness
body_id = body_od - 2*body_wall;
body_height = 250;      // P1S max with AMS

// Fin can  
fincan_length = 120;    // total length
fincan_shoulder = 30;   // portion that slides into body tube
motor_dia = 24;         // 24mm motor
motor_clearance = 0.4;
motor_tube_id = motor_dia + motor_clearance;
motor_tube_wall = 2.5;
motor_tube_od = motor_tube_id + 2*motor_tube_wall;
motor_len = 70;         // D/E motor length

// Fins (clipped delta / trapezoid)
n_fins = 4;
fin_root = 70;          // chord at body
fin_tip = 30;           // chord at tip  
fin_span = 50;          // radial distance from body
fin_sweep = 20;         // tip leading edge behind root leading edge
fin_thick = 3;          // fin thickness

// Nosecone
nc_length = 150;        // ogive length
nc_wall = 2.2;          // wall thickness
nc_shoulder = 25;       // shoulder that slides into body tube

// General
$fn = $preview ? 48 : 120;
eps = 0.01;

// ***** Derived dimensions *****
fincan_body_len = fincan_length - fincan_shoulder;

// ***** Modules *****

// 2D fin profile - in XZ plane (X=span outward, Z=along rocket)
module fin_profile() {
    polygon([
        [0, 0],                                    // root trailing edge
        [0, fin_root],                             // root leading edge  
        [fin_span, fin_root - fin_sweep],          // tip leading edge
        [fin_span, fin_root - fin_sweep - fin_tip] // tip trailing edge
    ]);
}

module fin() {
    // Fin centered on thickness, profile in XZ plane
    rotate([90, 0, 0])
        linear_extrude(height=fin_thick, center=true)
            fin_profile();
}

module fin_can() {
    difference() {
        union() {
            // Shoulder (slides into body tube)
            translate([0, 0, fincan_body_len])
                cylinder(d=body_id - 0.2, h=fincan_shoulder);
            
            // Main body tube section
            cylinder(d=body_od, h=fincan_body_len);
            
            // Motor tube (centered)
            cylinder(d=motor_tube_od, h=motor_len + 10);
            
            // 4 Fins
            for (i = [0:n_fins-1]) {
                rotate([0, 0, i * 360/n_fins + 45])  // offset 45° so fins between flat sides
                    translate([body_od/2, 0, 0])
                        fin();
            }
        }
        
        // Motor bore
        translate([0, 0, -eps])
            cylinder(d=motor_tube_id, h=motor_len + 15);
        
        // Hollow shoulder interior
        translate([0, 0, fincan_body_len + 5])
            cylinder(d=body_id - 8, h=fincan_shoulder);
        
        // Hollow main body interior (above motor tube)
        translate([0, 0, motor_len + 5])
            cylinder(d=body_od - 6, h=fincan_body_len - motor_len);
    }
    
    // Centering rings
    for (z = [5, motor_len]) {
        translate([0, 0, z])
            difference() {
                cylinder(d=body_od - 4, h=4);
                translate([0, 0, -eps])
                    cylinder(d=motor_tube_od + 0.5, h=4 + 2*eps);
            }
    }
}

module body_tube() {
    difference() {
        // Main tube
        cylinder(d=body_od, h=body_height);
        
        // Hollow center
        translate([0, 0, -eps])
            cylinder(d=body_id, h=body_height + 2*eps);
    }
}

// Ogive 2D profile for rotate_extrude
module ogive_profile(L, R) {
    // Tangent ogive: arc centered at (-p+R, 0) with radius p
    p = (R*R + L*L) / (2*R);
    
    intersection() {
        square([R, L]);
        translate([-p + R, 0])
            circle(r=p, $fn=$preview ? 90 : 360);
    }
}

module nosecone() {
    R = body_od / 2;
    
    difference() {
        union() {
            // Ogive
            rotate_extrude($fn=$preview ? 90 : 360)
                ogive_profile(nc_length, R);
            
            // Shoulder
            cylinder(d=body_id - 0.2, h=nc_shoulder);
        }
        
        // Hollow inside
        rotate_extrude($fn=$preview ? 90 : 360)
            offset(-nc_wall)
                ogive_profile(nc_length, R);
        
        // Hollow shoulder
        translate([0, 0, -eps])
            cylinder(d=body_id - nc_wall*2 - 0.5, h=nc_shoulder + 5);
    }
}

// ***** Assembly *****

// Z positions
z_fincan = 0;
z_body = fincan_body_len;  // body starts where fincan body ends
z_nosecone = z_body + body_height;  // nosecone sits on top of body tube

// Preview assembly
if ($preview) {
    // Fin can (red)
    color("Tomato", 0.8)
        translate([0, 0, z_fincan])
            fin_can();
    
    // Body tube (blue)
    color("RoyalBlue", 0.8)
        translate([0, 0, z_body])
            body_tube();
    
    // Nosecone (green)
    color("SeaGreen", 0.8)
        translate([0, 0, z_nosecone])
            nosecone();
}

// ***** For STL export, uncomment ONE: *****
// fin_can();
// body_tube();
// nosecone();
