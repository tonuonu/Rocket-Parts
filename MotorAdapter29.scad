// ***********************************
// Project: 3D Printed Rocket
// Filename: MotorAdapter29.scad
// Motor adapter for using 18mm or 24mm motors in a 29mm MMT
// Revision: 0.6 - removed exhaust throat (it was over-engineering).
//                 Single motor-sized bore from aft end to thrust ring.
//                 Matches conventional model rocket motor adapters.
//           0.5 - thrust RING (open center) for ejection gas pass-through
//           0.4 - Klima 18mm and TSP E20-P 24mm presets
//           0.3 - Motor_Class selector
//           0.2 - motor-length-aware bore with (now-removed) throat
//           0.1 - single-bore full length (superseded, then re-adopted)
// Units: mm
// ***********************************
//
// PURPOSE:
//   Printed adapter sleeve that fits inside a 29mm motor mount tube
//   (MMT) so you can fly smaller standard motors (18mm or 24mm) in
//   the same rocket.
//
// DESIGN:
//   Two zones along the length:
//
//     - "Motor bore" from aft to just behind the thrust ring.
//       Sized exactly to motor OD + 0.3mm clearance.  Motor slides
//       in from the open aft end, forward rim bottoms against the
//       thrust ring.  The aft end of the motor (nozzle) protrudes
//       out of the adapter as in any normal motor installation.
//
//     - "Thrust ring" at the forward end - an ANNULUS (not a solid
//       cap).  Inner opening ≈ motor's internal diameter so the
//       paper forward cap (on motors with ejection charges) can
//       blow through freely and ejection gases pass into the
//       rocket body unrestricted.
//
//   The adapter fills the full MMT depth, so the rocket's existing
//   29mm aft retainer engages the adapter's aft rim (the retainer
//   holds the adapter; the adapter holds the motor).
//
//
//   FORWARD (thrust ring end)                            AFT
//   ═════════════════════════════════════════════════════════
//   ring │            MOTOR BORE                           │
//   [O]  │        Ø(Motor_OD+0.3), full length             │
//   ═════════════════════════════════════════════════════════
//   3.5mm                  MMT_Depth - 3.5mm
//
//   Ring [O] has an OPEN center Ø (Motor_OD - 2mm).  Motor's
//   tube-wall rim (outer annulus of its forward face) bears on
//   the ring; the motor's paper forward cap sits over the open
//   center.
//
//   Motor position:
//     - Forward rim against the thrust ring
//     - Nozzle sticks out of the aft end of the adapter by
//       (MMT_Depth - Thrust_Ring_T - Motor_L)
//     - That empty aft space is harmless - same as any normal
//       motor-in-MMT installation where the motor is shorter
//       than the MMT.
//
//   Thrust path:
//     motor forward rim -> thrust ring aft face
//                       -> adapter wall
//                       -> rocket thrust ring ("the edge")
//                       -> rocket body
//
//   Ejection path (motors with ejection charge):
//     ejection charge fires -> paper cap blows through the ring
//     open center -> gases fill rocket body -> deployment.
//
//   Plugged (-P) motors: ring center is harmless (no gas flow).
//   Use altimeter/electronic ejection for deployment.
//
// ===========================================================
// HOW TO USE:
//   Pick ONE of the preset motor classes by setting Motor_Class
//   below.  Motor_OD and Motor_L are auto-set from the preset
//   table.
// ===========================================================
//
//   Motor_Class | Target motor                | OD | L  | Echo tag
//   ------------|-----------------------------|----|----|----------------
//        0      | 18mm 1/2A (short)           | 18 | 45 | 18mm-short
//        1      | 18mm Estes A8/B6/C6         | 18 | 70 | 18mm-std
//        2      | 24mm Estes D12              | 24 | 70 | 24mm-EstesD
//        3      | 24mm Aerotech 24/40         | 24 | 89 | 24mm-AT2440
//        4      | 24mm Estes E9 / E12         | 24 | 95 | 24mm-EstesE
//        5      | 18mm Klima (plugged)        | 18 | 69 | 18mm-Klima
//        6      | 24mm TSP E20-P (plugged)    | 24 | 94 | 24mm-TSP-E20P
//
//   For a non-preset motor (or another rocket with different MMT
//   depth), set Motor_Class = -1 and override Motor_OD / Motor_L
//   manually.
//
// MOTOR TYPES SUPPORTED (any of these):
//   - Motors with standard ejection charge (Estes, Klima non-plugged)
//   - Plugged "-P" motors (Klima plugged, TSP E20-P, etc.)
//   - Composite reloads (Aerotech 24/40, etc.)
//
// MOTOR RETENTION (aft) - NOT integrated. Use either:
//   (a) Masking tape around the adapter aft end and motor aft
//   (b) Traditional wire motor hook taped to adapter outside
//   (c) Rocket's existing 29mm aft retainer: the retainer catches
//       the adapter's 28.7mm OD aft rim; the motor is held inside
//       the adapter by friction + thrust + (if applicable) ejection
//       back-pressure.
//       Note: with -P plugged motors there is no ejection back-
//       pressure, so tape wrap or motor hook is recommended.
//
// ***********************************

Overlap = 0.05;

// ============================================
// HOST MMT
// ============================================
MMT_ID    = 29.0;      // MMT inner bore
MMT_Depth = 113;       // depth from aft end to forward thrust ring

// ============================================
// MOTOR CLASS  (set this to select your motor)
// ============================================
Motor_Class = 5;       // <- EDIT THIS   (5 = 18mm Klima, 6 = 24mm TSP E20-P)

// ============================================
// PRESET TABLE  (append new entries at the end)
// ============================================
//                   class:  0         1         2           3           4           5           6
Preset_OD    = [          18,        18,        24,          24,         24,         18,         24             ];
Preset_L     = [          45,        70,        70,          89,         95,         69,         94             ];
Preset_Name  = ["18mm-short", "18mm-std", "24mm-EstesD", "24mm-AT2440", "24mm-EstesE", "18mm-Klima", "24mm-TSP-E20P" ];

// ============================================
// MANUAL OVERRIDE  (only used when Motor_Class = -1)
// ============================================
Manual_Motor_OD = 24;
Manual_Motor_L  = 70;

// ============================================
// PRINT CLEARANCES
// ============================================
Clear_OD = 0.3;        // adapter OD = MMT_ID - Clear_OD  (slip fit)
Clear_ID = 0.3;        // motor bore = Motor_OD + Clear_ID

// ============================================
// THRUST RING (forward end, annular)
// ============================================
Thrust_Ring_T         = 3.5;   // axial thickness of the ring
Ring_Inner_Reduction  = 2.0;   // ring inner Ø = Motor_OD - this (matches motor ID)
                               // 2mm works for paper cases (typical).
                               // Increase to 3-4mm if using thicker-walled
                               // motor casings (some composite reloads).

// ============================================
// RENDER
// ============================================
// 1 = adapter body (PRINT THIS)
// 2 = adapter + dummy motor, cross-sectioned for inspection
Render_Part = 1;

// ============================================
// DERIVED - motor class -> OD and L
// ============================================
Motor_OD    = (Motor_Class == -1) ? Manual_Motor_OD : Preset_OD[Motor_Class];
Motor_L     = (Motor_Class == -1) ? Manual_Motor_L  : Preset_L[Motor_Class];
Motor_Label = (Motor_Class == -1) ? "manual"        : Preset_Name[Motor_Class];

// ============================================
// DERIVED - geometry
// ============================================
Adapter_OD      = MMT_ID - Clear_OD;
Motor_Bore_ID   = Motor_OD + Clear_ID;
Motor_Bore_L    = MMT_Depth - Thrust_Ring_T;         // full length (aft to ring)
Thrust_Ring_ID  = Motor_OD - Ring_Inner_Reduction;   // open-center size

// Aft empty space behind the motor (for info only)
Aft_Empty_L    = Motor_Bore_L - Motor_L;             // space behind motor

// Walls (for reporting)
Motor_Wall_T   = (Adapter_OD - Motor_Bore_ID) / 2;
Ring_Wall_T    = (Adapter_OD - Thrust_Ring_ID) / 2;
Ring_Bearing_W = (Motor_OD - Thrust_Ring_ID) / 2;    // radial overlap with motor rim

// ============================================
// REPORT / SANITY CHECKS
// ============================================
echo(str("=== MotorAdapter29 v0.6 ==="));
echo(str("  Motor class:    ", Motor_Class,
        " (", Motor_Label, ")"));
echo(str("  Target motor:   ", Motor_OD, "mm OD, ",
        Motor_L, "mm long"));
echo(str("  Adapter OD:     ", Adapter_OD,
        " mm  (in ", MMT_ID, "mm MMT)"));
echo(str("  Total length:   ", MMT_Depth, " mm"));
echo(str("  Thrust ring:    Ø", Thrust_Ring_ID,
        " inner x ", Thrust_Ring_T,
        " mm thick (motor rim contact ",
        Ring_Bearing_W, " mm radial)"));
echo(str("  Motor bore:     Ø", Motor_Bore_ID,
        " x ", Motor_Bore_L, " mm (wall ",
        Motor_Wall_T, " mm)"));
echo(str("  Aft empty space: ", Aft_Empty_L,
        " mm behind motor (nozzle sits in here)"));

if (Motor_L + Thrust_Ring_T > MMT_Depth)
    echo(str("  !! ERROR: motor too long! ", Motor_L + Thrust_Ring_T,
            "mm required vs ", MMT_Depth, "mm available."));
if (Motor_Wall_T < 1.5)
    echo("  !! WARNING: motor-bore wall < 1.5mm - use 4+ perimeters.");
if (Ring_Bearing_W < 0.8)
    echo("  !! WARNING: ring-motor bearing overlap < 0.8mm - motor rim may slip through.");

// ============================================
// MAIN ADAPTER
// ============================================
// Z=0 is the aft (open) end.
// Z=MMT_Depth is the forward end (thrust ring against rocket's thrust ring).
//
// Interior Z-zones:
//   [0, MMT_Depth - Thrust_Ring_T]          -> motor bore Ø Motor_Bore_ID
//   [MMT_Depth - Thrust_Ring_T, MMT_Depth]  -> ring open center Ø Thrust_Ring_ID
//
module MotorAdapter() {
    difference() {
        // Outer cylinder (fits inside MMT)
        cylinder(d = Adapter_OD, h = MMT_Depth, $fn = 180);

        // Motor bore - single cylinder from aft end to thrust ring
        translate([0, 0, -Overlap])
            cylinder(d = Motor_Bore_ID,
                     h = Motor_Bore_L + Overlap,
                     $fn = 120);

        // Thrust ring open center
        translate([0, 0, MMT_Depth - Thrust_Ring_T - Overlap])
            cylinder(d = Thrust_Ring_ID,
                     h = Thrust_Ring_T + 2 * Overlap,
                     $fn = 60);
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
        // Forward paper cap (visualize as recess at forward end)
        translate([0, 0, len - 0.5])
            cylinder(d = Motor_OD - 2, h = 0.5 + Overlap, $fn = 60);
    }
}

// ============================================
// ASSEMBLY PREVIEW  (cross-section)
// ============================================
// Motor is seated against the thrust ring at the forward end.
// Motor's aft end (nozzle) is part-way up from the adapter's aft end.
//
module AssemblyPreview(motor_len = 70) {
    difference() {
        union() {
            color("tan", 0.6) MotorAdapter();
            translate([0, 0, MMT_Depth - Thrust_Ring_T - motor_len])
                DummyMotor(len = motor_len);
        }
        // Cut away -Y half to reveal cross-section
        translate([-MMT_ID, -MMT_ID, -10])
            cube([2 * MMT_ID, MMT_ID, MMT_Depth + 20]);
    }
}

// ============================================
// RENDER
// ============================================
if (Render_Part == 1) MotorAdapter();
if (Render_Part == 2) AssemblyPreview(motor_len = Motor_L);

// ============================================
// NOTES / PRINT ADVICE
// ============================================
//
// FILE NAMING CONVENTION WHEN EXPORTING:
//   Rename the exported STL/3MF to include the motor class:
//     MotorAdapter29_18mm-Klima.stl
//     MotorAdapter29_24mm-TSP-E20P.stl
//
// PRINT SETTINGS (Bambu P1S, PC or PC-CF):
//   - Orientation: vertical, aft end (open) down on the bed.
//     The thrust ring prints last; its open center needs no
//     support because the ring is thin (3.5mm) and bridges
//     the motor-bore opening.
//   - Walls: 4+ perimeters (for 24mm the motor-bore wall is
//     only ~2.2mm, and the thrust ring needs strength).
//   - Infill: 40-60%
//   - Layer height: 0.2mm fine
//   - Brim recommended
//
// MATERIAL CHOICE:
//   - PC-CF (carbon-fiber filled PC): excellent - high Tg, low
//     thermal expansion, good dimensional stability under heat.
//   - PC (polycarbonate): recommended, Tg ~150 C.
//   - PETG: OK for single use.
//   - PLA: NOT recommended - softens at motor casing temperature.
//   - ABS / ASA: acceptable alternative.
//
// TESTING BEFORE FLIGHT:
//   1. Print adapter. Verify it slip-fits your 29mm MMT.
//   2. Test-insert the motor from the aft end. It should slide
//      smoothly through the full bore and bottom cleanly against
//      the thrust ring.
//   3. Look through the ring opening from the forward end - you
//      should see the motor's paper forward cap.
//   4. Inspect the thrust ring for layer splits. This takes all
//      the motor thrust - must be sound.
//
// EJECTION-CHARGE MOTORS (Estes A-E, Klima non-plugged):
//   - Ground-test deployment with the adapter in place once per
//     motor type before the first real flight.
//   - Verify the paper forward cap passes cleanly through the ring.
//
// PLUGGED-MOTOR FLIGHT CHECKLIST (Klima-P, TSP -P, etc.):
//   - Altimeter / flight computer armed and verified.
//   - Backup ejection (pyro or servo) ground-tested.
//   - Aft motor retention (tape/hook) - plugged motors have no
//     ejection back-pressure to hold the motor forward after burnout.
//
// SAFETY:
//   - Never widen the ring inner opening beyond the motor tube OD -
//     the motor would slip through and thrust would not transfer.
//   - Don't reuse a severely scorched adapter.
//
// ***********************************
