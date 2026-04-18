// ***********************************
// Project: 3D Printed Rocket
// Filename: MotorAdapter29.scad
// Motor adapter for using 18mm or 24mm motors in a 29mm MMT
// Revision: 0.1 - initial design
// Units: mm
// ***********************************
//
// PURPOSE:
//   A printed adapter sleeve that fits inside a 29mm motor mount tube
//   (MMT) and allows using a smaller standard motor (18mm or 24mm).
//
// HOW IT WORKS:
//   - Adapter is a 29mm-OD tube slightly smaller than MMT_ID (slip fit)
//   - Adapter's inner bore matches your chosen motor OD + clearance
//   - Forward end of adapter is closed by an integrated "thrust cap"
//   - Motor slides in from the open aft end until its forward rim
//     bottoms against the thrust cap
//   - Thrust path during burn:
//         motor fwd rim  ->  adapter thrust cap  ->
//         rocket thrust ring (the "edge")  ->  rocket body
//   - A vent hole through the thrust cap allows motor ejection gases
//     (if any) to pass into the rocket body
//
// MOTOR RETENTION (aft):
//   This adapter does NOT integrate aft motor retention in v0.1.
//   Use ONE of:
//     (a) Masking tape: wrap 3-4 turns around adapter aft end + motor
//     (b) Motor hook: a thin wire clip taped to adapter outside;
//         aft end of hook bent inward to catch motor aft rim
//     (c) Rely on the rocket's existing 29mm aft retainer.
//         The retainer retains the ADAPTER (which is 29mm OD);
//         the motor is retained inside the adapter by friction +
//         continuous thrust/ejection pressure against the thrust cap.
//         If motor can jump aft during ejection, use (a) or (b).
//
// TYPICAL MOTOR LENGTHS (longest in a class):
//   18mm Estes:       A8-3 = 45mm, B6 = 70mm, C6 = 70mm
//   18mm Quest:       A/B/C ~ 54-76mm
//   24mm Estes:       D12 = 70mm, E9/E12 = 95mm
//   24mm Aerotech:    24/40 casing = 89mm (reloadable)
//
// EJECTION NOTES:
//   - If using motor ejection: leave Vent_D as default (6mm).
//   - If using altimeter/electronic ejection only: use "-P" plugged
//     motor variants, or seal the vent hole with tape after install.
//   - Vent must NOT be smaller than ~4mm or pressure can burst the cap.
//
// PARAMETRIC:
//   Set Motor_OD to 18 or 24 and regenerate. Other rockets with
//   different MMT depth: adjust MMT_Depth.
//
// ***********************************

Overlap = 0.05;

// ============================================
// HOST MMT (29mm motor mount tube)
// ============================================
// Adjust to your rocket. Default: 113mm deep, 29.0mm ID.

MMT_ID = 29.0;
MMT_Depth = 113;

// ============================================
// TARGET MOTOR
// ============================================
// 18 = 18mm standard (Estes A/B/C/D)
// 24 = 24mm standard (Estes D/E, Aerotech 24/40)

Motor_OD = 24;

// ============================================
// PRINT CLEARANCES
// ============================================

Clear_OD = 0.3;          // adapter OD smaller than MMT_ID by this (slip fit)
Clear_ID = 0.3;          // motor bore larger than Motor_OD by this
Chamfer  = 1.0;          // aft-end chamfer to aid motor insertion

// ============================================
// THRUST CAP (forward closure)
// ============================================

Thrust_Cap_T = 3.5;      // thickness of cap at forward end
Vent_D       = 6.0;      // vent hole diameter through cap

// ============================================
// RENDER
// ============================================
// 1 = adapter body  (print this)
// 2 = adapter + dummy motor, cross-sectioned for inspection

Render_Part = 1;

// ============================================
// DERIVED VALUES
// ============================================

Adapter_OD = MMT_ID - Clear_OD;
Adapter_ID = Motor_OD + Clear_ID;
Wall_T     = (Adapter_OD - Adapter_ID) / 2;

echo(str("=== MotorAdapter29 for ", Motor_OD, "mm motor ==="));
echo(str("  Adapter OD:     ", Adapter_OD, " mm"));
echo(str("  Adapter ID:     ", Adapter_ID, " mm"));
echo(str("  Wall thickness: ", Wall_T, " mm"));
echo(str("  Length:         ", MMT_Depth, " mm"));

if (Wall_T < 1.5)
    echo("  !! WARNING: wall thickness < 1.5mm, may be weak");
if (Motor_OD != 18 && Motor_OD != 24)
    echo("  !! NOTE: non-standard Motor_OD, verify carefully");

// ============================================
// MAIN ADAPTER
// ============================================

module MotorAdapter() {
    difference() {
        // Outer cylinder
        cylinder(d = Adapter_OD, h = MMT_Depth, $fn = 180);

        // Motor bore (closed at forward by thrust cap)
        translate([0, 0, -Overlap])
            cylinder(d = Adapter_ID,
                     h = MMT_Depth - Thrust_Cap_T + Overlap,
                     $fn = 120);

        // Aft chamfer (1mm x 45deg) for easier motor insertion
        translate([0, 0, -Overlap])
            cylinder(d1 = Adapter_ID + 2 * Chamfer,
                     d2 = Adapter_ID,
                     h  = Chamfer + Overlap,
                     $fn = 120);

        // Forward vent hole
        translate([0, 0, MMT_Depth - Thrust_Cap_T - Overlap])
            cylinder(d = Vent_D,
                     h = Thrust_Cap_T + 2 * Overlap,
                     $fn = 48);
    }
}

// ============================================
// DUMMY MOTOR (preview only, not printed)
// ============================================

module DummyMotor(len = 70) {
    color("silver", 0.7)
    difference() {
        cylinder(d = Motor_OD, h = len, $fn = 60);
        // Aft nozzle indentation
        translate([0, 0, -Overlap])
            cylinder(d = Motor_OD * 0.4, h = 6, $fn = 36);
        // Forward cap recess (approx)
        translate([0, 0, len - 2])
            cylinder(d = Motor_OD * 0.7, h = 2 + Overlap, $fn = 36);
    }
}

// ============================================
// ASSEMBLY PREVIEW (cross-section)
// ============================================

module AssemblyPreview(motor_len = 70) {
    difference() {
        union() {
            color("tan", 0.6) MotorAdapter();
            // Motor seated at forward end
            translate([0, 0, MMT_Depth - Thrust_Cap_T - motor_len])
                DummyMotor(len = motor_len);
        }
        // Cut away +Y half to reveal cross-section
        translate([-MMT_ID, 0, -10])
            cube([2 * MMT_ID, MMT_ID, MMT_Depth + 20]);
    }
}

// ============================================
// RENDER
// ============================================

if (Render_Part == 1) MotorAdapter();
if (Render_Part == 2) AssemblyPreview(motor_len = 70);

// ============================================
// NOTES / PRINT ADVICE
// ============================================
//
// PRINT SETTINGS (Bambu P1S, PC or PETG):
//   - Orientation: vertical (cap down, aft up) or cap up
//   - Walls: 4+ perimeters (wall is thin near the motor bore)
//   - Infill: 40-60% (not critical since walls are thick for 18mm)
//   - Layer: 0.2mm fine
//   - Brim recommended if printing vertically
//
// MATERIAL CHOICE:
//   - PC (polycarbonate): best for repeated use and thermal margin
//   - PETG: OK for single motor (cheap alternative)
//   - PLA: NOT recommended - softens near motor case heat
//   - ABS / ASA: acceptable
//
// TESTING BEFORE FLIGHT:
//   1. Print adapter. Verify it slip-fits into your 29mm MMT
//      (should slide in with light friction, no force)
//   2. Test-insert the target motor. It should slide through the
//      bore with very light friction and bottom cleanly against
//      the thrust cap.
//   3. Inspect the thrust cap for print defects / layer gaps.
//      This cap takes the full motor thrust - MUST be solid.
//   4. Verify the vent hole is clear.
//
// SAFETY:
//   - Test with smallest motor class first.
//   - Ground-test ejection if using motor ejection through the
//     adapter - make sure vent flow is adequate.
//   - Do NOT remove the thrust cap to make a "through-hole" adapter -
//     thrust will have nowhere to transfer.
//
// ***********************************
