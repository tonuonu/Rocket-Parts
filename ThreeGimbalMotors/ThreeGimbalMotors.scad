// Three Gimbaled 29mm Motor Holders in 5.5" Body Tube
// Optimal placement for maximum gimbal clearance (~±12°)

/* [Body Tube] */
body_tube_od = 140;        // 5.5 inch nominal OD
body_tube_wall = 1.5;      // fiberglass wall thickness
body_tube_id = body_tube_od - 2 * body_tube_wall; // ~137mm
body_tube_length = 120;    // display length

/* [Motor Holders] */
motor_od = 35;             // 29mm motor + holder wall
motor_id = 29;             // motor casing bore
motor_length = 70;         // approximate D16-0 length
holder_wall = (motor_od - motor_id) / 2;

/* [Gimbal Geometry] */
// Optimal center distance balancing wall and inter-motor clearance
d_center = 36.7;           // mm from tube axis to motor axis
gimbal_max = 12;           // max gimbal angle in degrees
n_motors = 3;
motor_spacing_angle = 360 / n_motors; // 120°

/* [Pivot] */
pivot_diameter = 8;        // pivot ball/pin diameter
pivot_length = 10;         // pivot block height

/* [Display Options] */
show_gimbaled = true;      // show one motor at max deflection
gimbal_demo_angle = 12;    // degrees to tilt demo motor
body_tube_alpha = 0.15;    // body tube transparency
$fn = 64;

// --- Modules ---

module body_tube() {
    color("gray", body_tube_alpha)
    difference() {
        cylinder(d=body_tube_od, h=body_tube_length, center=true);
        cylinder(d=body_tube_id, h=body_tube_length + 1, center=true);
    }
}

module motor_holder(highlight=false) {
    clr = highlight ? "orange" : "steelblue";
    color(clr, 0.8)
    difference() {
        cylinder(d=motor_od, h=motor_length);
        // bore
        translate([0, 0, -0.5])
            cylinder(d=motor_id, h=motor_length + 1);
    }
}

module pivot_block() {
    color("darkred", 0.9)
    cylinder(d=pivot_diameter, h=pivot_length, center=true);
}

module motor_assembly(angle_offset, gimbal_tilt=0, gimbal_azimuth=0, highlight=false) {
    rotate([0, 0, angle_offset])
    translate([d_center, 0, 0]) {
        // pivot point at top of motor
        translate([0, 0, motor_length / 2])
            pivot_block();

        // motor tilts around pivot (top end)
        translate([0, 0, motor_length / 2])
        rotate([0, 0, gimbal_azimuth])
        rotate([gimbal_tilt, 0, 0])
        translate([0, 0, -motor_length / 2])
            motor_holder(highlight);
    }
}

module clearance_envelope(angle_offset) {
    // show the cone swept by motor nozzle at max gimbal
    rotate([0, 0, angle_offset])
    translate([d_center, 0, motor_length / 2]) {
        color("yellow", 0.08)
        cylinder(r1=0, r2=motor_length * sin(gimbal_max) + motor_od/2,
                 h=motor_length, center=false);
        // invert for downward sweep
        color("yellow", 0.08)
        rotate([180, 0, 0])
        cylinder(r1=0, r2=motor_length * sin(gimbal_max) + motor_od/2,
                 h=motor_length, center=false);
    }
}

// --- Assembly ---

// Body tube (centered at origin)
body_tube();

// Motor assemblies - pivot at top, nozzle hangs down
// Shift everything so motors are centered in the tube
translate([0, 0, -motor_length / 2]) {

    // Motor 0 - shown gimbaled as demo
    if (show_gimbaled) {
        motor_assembly(0,
            gimbal_tilt=gimbal_demo_angle,
            gimbal_azimuth=0,
            highlight=true);
    } else {
        motor_assembly(0);
    }

    // Motor 1 - neutral
    motor_assembly(120);

    // Motor 2 - neutral
    motor_assembly(240);
}

// Clearance envelopes
translate([0, 0, -motor_length / 2]) {
    for (a = [0, 120, 240])
        clearance_envelope(a);
}

// --- Annotations ---
// Center mark
color("red") cylinder(d=2, h=body_tube_length + 10, center=true);

// Radial lines showing center distance
for (a = [0, 120, 240]) {
    color("white", 0.4)
    rotate([0, 0, a])
    translate([d_center / 2, 0, 0])
    cube([d_center, 0.5, 0.5], center=true);
}
