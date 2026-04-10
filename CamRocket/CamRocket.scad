// ***********************************
// Project: Camera Rocket
// Filename: CamRocket.scad
// Created: 2025-01-04
// Units: mm
// ***********************************
// 3D printed rocket with CATS Vega e-bay
// 4 parts: Nosecone, E-bay coupler, Body tube, Fin can
// + separate door piece for e-bay access
// Coordinate system: Z=0 at motor nozzle, Z+ toward nose
// ***********************************

// ***** Parameters *****

// Body tube (DO NOT MODIFY - already printed)
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
nc_shoulder = 25;       // shoulder that slides into body tube / e-bay socket

// General
$fn = $preview ? 48 : 120;
eps = 0.01;
shoulder_clearance = 0.2;   // per side, for slip fit

// ================================================
// E-BAY COUPLER PARAMETERS
// ================================================
// Coupler sits between body tube top and nosecone.
// Bottom shoulder slides into body tube.
// Top socket receives nosecone shoulder.
// Total: 145mm, well within P1S 250mm AMS limit.

ebay_wall = 2.0;                    // coupler wall thickness
ebay_shoulder_bot = 20;             // bottom shoulder (into body tube)
ebay_body_h = 100;                  // exposed coupler body
ebay_socket_top = nc_shoulder;      // top socket for nosecone (25mm)
ebay_total = ebay_shoulder_bot + ebay_body_h + ebay_socket_top;  // 145mm

ebay_shoulder_od = body_id - 2*shoulder_clearance;  // 71.0mm
ebay_bore_sh = ebay_shoulder_od - 2*ebay_wall;      // 67.0mm (shoulder bore)
ebay_bore_body = body_od - 2*ebay_wall;             // 71.0mm (body bore)
// Top socket bore = body_id = 71.4mm (accepts nosecone shoulder)

// ================================================
// CATS VEGA FLIGHT COMPUTER
// ================================================
// From CATS User Manual v2.0.0, Section 4.1 / Figure 10
// Board: 100 x 33 x 21mm (without SMA antenna)
//
// CRITICAL: 3 mounting holes in TRIANGLE pattern, M3.
//           NOT 4 corner holes!
//           See manual Figure 10 (page 19).
//
// Mounting hole pattern: 60mm x 27mm
//   - Two holes on one long edge, 60mm apart along length
//   - One hole on the opposite long edge, centered between them
//
// *** MEASURE YOUR ACTUAL BOARD AND VERIFY THESE POSITIONS ***
// *** The PDF figure does not dimension individual hole offsets ***
// *** from board edges. Adjust cv_holes[] after measuring. ***

cv_pcb_l = 100;             // board length
cv_pcb_w = 33;              // board width
cv_pcb_h = 21;              // component height (no antenna)
cv_standoff_h = 5;          // standoff above rail
cv_standoff_od = 7;         // standoff outer diameter
cv_m3_tap = 2.5;            // M3 tap drill (2.5mm)

// Hole positions: origin at board geometric center
// X = across width (board is 33mm, range ±16.5)
// Y = along length (board is 100mm, range ±50)
cv_hole_dx = 27;            // cross-board spacing
cv_hole_dy = 60;            // along-length spacing (same-side pair)
cv_holes = [
    [-cv_hole_dx/2, -cv_hole_dy/2],  // A: left side, 30mm below center
    [-cv_hole_dx/2,  cv_hole_dy/2],  // B: left side, 30mm above center
    [ cv_hole_dx/2,  0]              // C: right side, at center height
];

// SMA antenna connector
sma_hole_d = 6.5;           // SMA bulkhead clearance

// Access door (on -Y side, opposite mounting rail)
// Replaces USB slot — gives full access to CATS Vega
door_w = 36;                // door opening width (> board 33mm)
door_h = 85;                // door opening height
door_corner_r = 3;          // rounded corner radius
door_panel_t = 2.0;         // door panel thickness
door_sill = 1.5;            // lip/sill width inside frame
door_bolt_d = 2.5;          // M2.5 bolt
door_bolt_tap = 2.0;        // M2.5 tap drill
door_bolt_boss_od = 6;      // boss around bolt hole
door_bolt_boss_h = 4;       // boss height (projects inward)
door_bolt_inset = 5;        // bolt center from door edge

// M12 camera lens placeholder (future nosecone camera)
// M12 x 0.5mm thread, 12mm nominal OD
// Evetar M13B0818IR or similar, 1/3" format
m12_thread_d = 12.0;
m12_boss_od = 18;
m12_boss_h = 10;

// ***** Derived dimensions *****
fincan_body_len = fincan_length - fincan_shoulder;

// Door center Z in coupler local frame
door_cz = ebay_shoulder_bot + ebay_body_h / 2;

// Door bolt positions [x, z] relative to door center
door_bolts = [
    for (sx = [-1, 1], sz = [-1, 1])
        [sx * (door_w/2 - door_bolt_inset), sz * (door_h/2 - door_bolt_inset)]
];

// ***** EXISTING MODULES (unchanged) *****

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

// DO NOT MODIFY - already printed
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

        // TODO: M12 camera lens bore at tip (future)
        // Needs careful placement at ogive apex.
        // Bore: cylinder(d=m12_thread_d, h=m12_boss_h) at tip
        // Boss: add solid cylinder at tip before boring
        // Defer until camera PCB dimensions are confirmed.
    }
}

// ================================================
// E-BAY COUPLER MODULE
// ================================================
// Structure (bottom to top):
//   z=0..20:  Bottom shoulder (OD 71.0, bore 67.0) - into body tube
//   z=20..120: Exposed body (OD 75.0, bore 71.0) - houses CATS Vega
//   z=120..145: Top socket (OD 75.0, bore 71.4) - receives nosecone
//
// Internal rail on +Y wall holds CATS Vega via 3 M3 standoffs.
// Access door on -Y wall for USB, battery, switch access.
// Open bore allows ejection gas to flow nose-ward.

module ebay_coupler() {
    // Board mounting geometry
    // Board vertical: length along Z, width along X
    // Component side faces -Y (toward tube center / door side)
    // Rail on +Y bore wall
    board_z0 = ebay_shoulder_bot + 3;         // board bottom z
    board_cz = board_z0 + cv_pcb_l / 2;      // board center z

    // Rail geometry
    rail_t = 3;                               // plate thickness
    rail_w = cv_pcb_w + 8;                    // 41mm, wider than board
    rail_z0 = board_z0 - 3;                   // starts 3mm below board
    rail_h = cv_pcb_l + 6;                    // 106mm tall
    bore_r = ebay_bore_body / 2;              // 35.5mm
    rail_front_y = bore_r - rail_t;           // 32.5mm from center

    // Board back face Y (sits on standoff tips)
    board_back_y = rail_front_y - cv_standoff_h;  // 27.5mm from center
    // Board component face at ~27.5 - 21 = 6.5mm from center
    // Leaves ~42mm clear on -Y side for wires and gas flow

    difference() {
        union() {
            // --- HOLLOW COUPLER SHELL ---
            _ebay_shell();

            // --- MOUNTING RAIL (inside bore, bonded to wall) ---
            intersection() {
                // Rail plate: extends 3mm into wall for structural bond
                translate([-rail_w/2, rail_front_y, rail_z0])
                    cube([rail_w, rail_t + 3, rail_h]);
                // Clip to outer shell envelope
                cylinder(d=body_od - 0.2, h=ebay_total);
            }

            // --- 3x STANDOFFS (triangle pattern) ---
            for (hole = cv_holes) {
                hx = hole[0];   // board X → coupler X
                hz = hole[1];   // board Y → coupler Z offset from center
                // Standoff from board face to rail, grows in +Y
                translate([hx, board_back_y, board_cz + hz])
                    rotate([-90, 0, 0])
                        cylinder(d=cv_standoff_od, h=cv_standoff_h + rail_t);
            }

            // --- DOOR FRAME BOLT BOSSES (4x, inside coupler wall) ---
            for (bp = door_bolts) {
                translate([bp[0], 0, door_cz + bp[1]])
                    rotate([90, 0, 0])
                        translate([0, 0, bore_r - door_bolt_boss_h])
                            cylinder(d=door_bolt_boss_od, h=door_bolt_boss_h + ebay_wall);
            }
        }

        // --- M3 TAP HOLES through standoffs ---
        for (hole = cv_holes) {
            hx = hole[0];
            hz = hole[1];
            translate([hx, board_back_y - eps, board_cz + hz])
                rotate([-90, 0, 0])
                    cylinder(d=cv_m3_tap, h=cv_standoff_h + rail_t + 2*eps);
        }

        // --- ACCESS DOOR OPENING ---
        // Large curved opening on -Y side for full CATS Vega access.
        // Rounded rectangle projected through tube wall.
        _door_opening();

        // --- DOOR SILL (recessed lip for door panel to sit against) ---
        // Slightly larger than door opening, slightly shallower
        _door_sill();

        // --- DOOR BOLT HOLES (M2.5 tap through bosses) ---
        for (bp = door_bolts) {
            translate([bp[0], 0, door_cz + bp[1]])
                rotate([90, 0, 0])
                    translate([0, 0, bore_r - door_bolt_boss_h - eps])
                        cylinder(d=door_bolt_tap, h=door_bolt_boss_h + ebay_wall + 2*eps);
        }

        // --- SMA ANTENNA HOLE ---
        // Centered, through top of coupler into nosecone cavity.
        translate([0, 0, ebay_total - 5])
            cylinder(d=sma_hole_d, h=10);
    }

    // --- Shell as nested module ---
    module _ebay_shell() {
        difference() {
            union() {
                // Bottom shoulder
                cylinder(d=ebay_shoulder_od, h=ebay_shoulder_bot);
                // Exposed body
                translate([0, 0, ebay_shoulder_bot])
                    cylinder(d=body_od, h=ebay_body_h);
                // Top socket
                translate([0, 0, ebay_shoulder_bot + ebay_body_h])
                    cylinder(d=body_od, h=ebay_socket_top);
            }
            // Bore: shoulder (open bottom for gas flow)
            translate([0, 0, -eps])
                cylinder(d=ebay_bore_sh, h=ebay_shoulder_bot + 2*eps);
            // Bore: body section
            translate([0, 0, ebay_shoulder_bot])
                cylinder(d=ebay_bore_body, h=ebay_body_h);
            // Bore: top socket (sized for nosecone shoulder)
            translate([0, 0, ebay_shoulder_bot + ebay_body_h])
                cylinder(d=body_id, h=ebay_socket_top + eps);
        }
    }

    // --- Door opening: rounded rectangle through -Y wall ---
    module _door_opening() {
        r = door_corner_r;
        intersection() {
            // Rounded rectangle, extruded radially through wall
            translate([0, 0, door_cz])
                hull() {
                    for (sx = [-1, 1], sz = [-1, 1])
                        translate([sx*(door_w/2-r), -body_od, sz*(door_h/2-r)])
                            rotate([-90, 0, 0])
                                cylinder(r=r, h=body_od);
                }
            // Clip to tube wall annulus only
            difference() {
                cylinder(d=body_od + 1, h=ebay_total + 2*eps);
                cylinder(d=ebay_bore_body - 0.1, h=ebay_total + 2*eps);
            }
        }
    }

    // --- Door sill: shallow recess for door panel to sit flush ---
    module _door_sill() {
        r = door_corner_r + door_sill;
        sill_depth = door_panel_t + 0.2;  // door panel + clearance
        intersection() {
            translate([0, 0, door_cz])
                hull() {
                    for (sx = [-1, 1], sz = [-1, 1])
                        translate([sx*(door_w/2+door_sill-r), -body_od, sz*(door_h/2+door_sill-r)])
                            rotate([-90, 0, 0])
                                cylinder(r=r, h=body_od);
                }
            // Clip to outer sill depth only
            difference() {
                cylinder(d=body_od + 1, h=ebay_total + 2*eps);
                cylinder(d=body_od - 2*sill_depth, h=ebay_total + 2*eps);
            }
        }
    }
}

// ================================================
// E-BAY DOOR (separate print)
// ================================================
// Curved panel that covers the access opening.
// Print flat (inside face up) or curved side down.
// 4x M2.5 clearance holes for bolts.

module ebay_door() {
    r = door_corner_r + door_sill - 0.3;  // slightly smaller for clearance
    panel_w = door_w + 2*door_sill - 0.6;
    panel_h = door_h + 2*door_sill - 0.6;

    difference() {
        // Curved door panel
        intersection() {
            // Rounded rectangle shape
            translate([0, 0, 0])
                hull() {
                    for (sx = [-1, 1], sz = [-1, 1])
                        translate([sx*(panel_w/2-r), 0, sz*(panel_h/2-r)])
                            rotate([-90, 0, 0])
                                cylinder(r=r, h=body_od/2);
                }
            // Curved: shell between OD and OD-panel_t
            difference() {
                cylinder(d=body_od - 0.2, h=panel_h + 10, center=true);
                cylinder(d=body_od - 0.2 - 2*door_panel_t, h=panel_h + 12, center=true);
            }
        }

        // 4x M2.5 clearance holes
        for (bp = door_bolts) {
            translate([bp[0], -body_od/2, bp[1]])
                rotate([-90, 0, 0])
                    cylinder(d=door_bolt_d, h=body_od/2 + 5);
        }
    }
}

// ================================================
// CATS VEGA GHOST (preview only)
// ================================================
// Simple visualization in mounted orientation.
// Length along Z, width along X, components face -Y.
module cats_vega_ghost() {
    // PCB
    color("DarkGreen", 0.7)
        translate([-cv_pcb_w/2, -0.8, -cv_pcb_l/2])
            cube([cv_pcb_w, 1.6, cv_pcb_l]);
    // Components (on -Y face)
    color("DimGray", 0.5)
        translate([-cv_pcb_w/2 + 2, -cv_pcb_h + 0.8, -cv_pcb_l/2 + 5])
            cube([cv_pcb_w - 4, cv_pcb_h - 1.6, cv_pcb_l - 10]);
    // Mounting holes
    color("Gold", 0.9)
    for (hole = cv_holes) {
        translate([hole[0], 0, hole[1]])
            rotate([-90, 0, 0])
                cylinder(d=3, h=3, center=true, $fn=12);
    }
    // SMA connector stub at top
    color("Gold", 0.9)
        translate([0, 0, cv_pcb_l/2])
            cylinder(d=6, h=15, $fn=12);
}

// ***** Assembly *****

// Z positions in global frame
z_fincan = 0;
z_body = fincan_body_len;  // body starts where fincan body ends
// E-bay bottom shoulder overlaps into body tube top
z_ebay = z_body + body_height - ebay_shoulder_bot;
// Nosecone shoulder drops into e-bay top socket
z_nosecone = z_ebay + ebay_total - nc_shoulder;

// Preview assembly
if ($preview) {
    // Fin can (red)
    color("Tomato", 0.8)
        translate([0, 0, z_fincan])
            fin_can();

    // Body tube (blue) - DO NOT MODIFY
    color("RoyalBlue", 0.8)
        translate([0, 0, z_body])
            body_tube();

    // E-bay coupler (gold)
    color("Gold", 0.8)
        translate([0, 0, z_ebay])
            ebay_coupler();

    // Door (orange, shown in place)
    color("Orange", 0.9)
        translate([0, 0, z_ebay + door_cz])
            ebay_door();

    // CATS Vega ghost (green) inside e-bay
    translate([0, 0, z_ebay]) {
        _bz0 = ebay_shoulder_bot + 3;
        _bcz = _bz0 + cv_pcb_l / 2;
        _bore_r = ebay_bore_body / 2;
        _rail_t = 3;
        _bby = _bore_r - _rail_t - cv_standoff_h;
        translate([0, _bby, _bcz])
            cats_vega_ghost();
    }

    // Nosecone (green)
    color("SeaGreen", 0.8)
        translate([0, 0, z_nosecone])
            nosecone();
}

// ***** For STL export, uncomment ONE: *****
// fin_can();
// body_tube();
// nosecone();
// ebay_coupler();
// ebay_door();
