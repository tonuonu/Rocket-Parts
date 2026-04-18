// ***********************************
// Project: 3D Printed Rocket
// Filename: MotorAdapter29.scad
// Motor adapter for using 18mm or 24mm motors in a 29mm MMT
// Revision: 0.3 - single Motor_Class selector (auto-sets OD and length)
//           0.2 - motor-length-aware bore + widened exhaust throat
//           0.1 - single-bore full length (superseded)
// Units: mm
// ***********************************
//
// PURPOSE:
//   Printed adapter sleeve that fits inside a 29mm motor mount tube
//   (MMT) so you can fly smaller standard motors (18mm or 24mm) in
//   the same rocket.
//
// KEY IDEA:
//   Smaller motors are SHORTER than the 29mm motors the rocket was
//   designed for.  The adapter has two distinct inner-bore zones:
//
//     - "Motor bore" at the forward end, sized exactly to the
//       chosen motor (OD and length).
//     - "Exhaust throat" at the aft end, wider than the motor,
//       so the motor nozzle plume has room to expand and isn't
//       blasting hot gas against a thin 18mm/24mm wall.
//
//   The adapter still fills the full 113mm MMT depth, so the
//   rocket's existing 29mm retainer engages the adapter's aft rim
//   (the retainer holds the adapter; the adapter holds the motor).
//
//
//   FORWARD (thrust ring end)                            AFT
//   ═════════════════════════════════════════════════════════
//    cap            MOTOR BORE                    THROAT
//    [V]    Ø(Motor_OD+0.3), fits motor       Ø wider, cool air
//   ═════════════════════════════════════════════════════════
//   3.5mm   Motor_L + 2mm buffer                remainder
//
//   Thrust path:
//     motor fwd rim -> adapter thrust cap
//                   -> rocket thrust ring ("edge")
//                   -> rocket body
//
// ===========================================================
// HOW TO USE:
//   Pick ONE of the preset motor classes by setting Motor_Class
//   below.  Motor_OD and Motor_L are then auto-set from the
//   preset table. No need to remember two numbers.
// ===========================================================
//
//   Motor_Class | Target motor           | OD | L  | Echo tag
//   ------------|------------------------|----|----|---------------
//        0      | 18mm 1/2A (short)      | 18 | 45 | 18mm-short
//        1      | 18mm Estes A8/B6/C6    | 18 | 70 | 18mm-std
//        2      | 24mm Estes D12         | 24 | 70 | 24mm-EstesD
//        3      | 24mm Aerotech 24/40    | 24 | 89 | 24mm-AT2440
//        4      | 24mm Estes E9 / E12    | 24 | 95 | 24mm-EstesE
//
//   For a non-preset motor (or another rocket with different MMT
//   depth), set Motor_Class = -1 and override Motor_OD / Motor_L
//   manually in the "MANUAL OVERRIDE" block below.
//
// MOTOR RETENTION (aft) - NOT integrated. Use either:
//   (a) Masking tape around the adapter aft end and motor aft
//   (b) Traditional wire motor hook taped to adapter outside
//   (c) Rocket's existing 29mm aft retainer: the retainer catches
//       the adapter's 28.7mm OD aft rim; the motor is retained
//       inside the adapter by friction and continuous thrust/
//       ejection pressure pushing it against the thrust cap.
//
// EJECTION:
//   Default Vent_D = 6mm allows motor-ejection gases through the
//   thrust cap into the rocket body.  For altimeter/electronic
//   ejection only, use "-P" plugged motor variants or seal the
//   vent hole with tape after motor install.
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
// See preset table in header comment.
// Use -1 to override manually (see MANUAL OVERRIDE block below).

Motor_Class = 1;       // <- EDIT THIS

// ============================================
// PRESET TABLE  (don't edit - add new entries here if needed)
// ============================================
Preset_OD    = [ 18,            18,            24,             24,             24            ];
Preset_L     = [ 45,            70,            70,             89,             95            ];
Preset_Name  = ["18mm-short",  "18mm-std",    "24mm-EstesD",  "24mm-AT2440",  "24mm-EstesE" ];

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
// THRUST CAP (forward)
// ============================================
Thrust_Cap_T = 3.5;    // thickness of forward cap
Vent_D       = 6.0;    // vent hole through cap

// ============================================
// EXHAUST THROAT (aft of motor bore)
// ============================================
Throat_Clearance = 3.0;   // throat ID = Motor_OD + Throat_Clearance (requested)
Min_Throat_Wall  = 1.5;   // minimum wall thickness in throat zone
Min_Throat_L     = 5.0;   // if remaining axial space < this, skip throat
Motor_Buffer_L   = 2.0;   // bore length beyond nominal motor length

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
Adapter_OD    = MMT_ID - Clear_OD;
Motor_Bore_ID = Motor_OD + Clear_ID;

// Throat bore: requested OR wall-limited, whichever forces thinner wall
Throat_ID_Requested = Motor_OD + Throat_Clearance;
Throat_ID_WallLimit = MMT_ID - 2 * Min_Throat_Wall;
Throat_ID           = min(Throat_ID_Requested, Throat_ID_WallLimit);

Motor_Bore_L  = Motor_L + Motor_Buffer_L;
Throat_L_Raw  = MMT_Depth - Thrust_Cap_T - Motor_Bore_L;
Use_Throat    = (Throat_L_Raw >= Min_Throat_L) &&
                (Throat_ID   >  Motor_Bore_ID + 1.0);

// If throat zone too short/thin to matter, just extend motor bore
Throat_L      = Use_Throat ? Throat_L_Raw : 0;
Bore_Actual_L = Use_Throat ? Motor_Bore_L : MMT_Depth - Thrust_Cap_T;

// Walls (for reporting)
Motor_Wall_T  = (Adapter_OD - Motor_Bore_ID) / 2;
Throat_Wall_T = Use_Throat ? (Adapter_OD - Throat_ID) / 2 : Motor_Wall_T;

// ============================================
// REPORT / SANITY CHECKS
// ============================================
echo(str("=== MotorAdapter29 v0.3 ==="));
echo(str("  Motor class:    ", Motor_Class,
        " (", Motor_Label, ")"));
echo(str("  Target motor:   ", Motor_OD, "mm OD, ",
        Motor_L, "mm long"));
echo(str("  Adapter OD:     ", Adapter_OD,
        " mm  (in ", MMT_ID, "mm MMT)"));
echo(str("  Total length:   ", MMT_Depth, " mm"));
echo(str("  Motor bore:     Ø", Motor_Bore_ID,
        " mm x ", Bore_Actual_L, " mm long (wall ",
        Motor_Wall_T, " mm)"));
if (Use_Throat)
    echo(str("  Exhaust throat: Ø", Throat_ID,
            " mm x ", Throat_L, " mm long (wall ",
            Throat_Wall_T, " mm)"));
else
    echo("  Exhaust throat: (none - motor bore extends full length)");

if (Motor_L + Thrust_Cap_T > MMT_Depth)
    echo(str("  !! ERROR: motor too long! ", Motor_L + Thrust_Cap_T,
            "mm required vs ", MMT_Depth, "mm available."));
if (Motor_Wall_T < 1.5)
    echo("  !! WARNING: motor-bore wall < 1.5mm - use 4+ perimeters.");
if (Use_Throat && Throat_Wall_T < 1.5)
    echo("  !! WARNING: throat wall < 1.5mm - use 4+ perimeters.");

// ============================================
// MAIN ADAPTER
// ============================================
// Z=0 is the aft (open) end.
// Z=MMT_Depth is the forward end (against thrust ring).
//
module MotorAdapter() {
    difference() {
        // Outer cylinder (fits inside MMT)
        cylinder(d = Adapter_OD, h = MMT_Depth, $fn = 180);

        // Exhaust throat (aft zone, wider bore) - if used
        if (Use_Throat) {
            translate([0, 0, -Overlap])
                cylinder(d = Throat_ID,
                         h = Throat_L + Overlap,
                         $fn = 120);
        }

        // Motor bore (forward zone, motor-sized)
        translate([0, 0, Throat_L - Overlap])
            cylinder(d = Motor_Bore_ID,
                     h = Bore_Actual_L + 2 * Overlap,
                     $fn = 120);

        // Vent hole through thrust cap
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
    }
}

// ============================================
// ASSEMBLY PREVIEW  (cross-section)
// ============================================
module AssemblyPreview(motor_len = 70) {
    difference() {
        union() {
            color("tan", 0.6) MotorAdapter();
            translate([0, 0, MMT_Depth - Thrust_Cap_T - motor_len])
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
//   Rename the exported STL/3MF to include the motor class so you
//   don't mix them up at the bench:
//     MotorAdapter29_18mm-std.stl
//     MotorAdapter29_24mm-EstesE.stl
//   etc.
//
// PRINT SETTINGS (Bambu P1S, PC or PETG):
//   - Orientation: vertical, cap down, aft up (so the thrust cap
//     prints first on a solid layer; the vent prints as a simple
//     bridge/overhang near the end of the print).
//     Alt: cap up, aft down (vent printed early over bed).
//   - Walls: 4+ perimeters (especially for 24mm where the motor-
//     bore wall is only ~2.2mm)
//   - Infill: 40-60%
//   - Layer height: 0.2mm fine
//   - Brim recommended if printing vertically
//
// MATERIAL CHOICE:
//   - PC (polycarbonate): recommended for repeated use, best heat
//     tolerance (Tg ~150 C, softening above that).
//   - PETG: OK for single use, cheap. May sag slightly near the
//     nozzle on higher-thrust motors.
//   - PLA: NOT recommended - softens near motor casing temp.
//   - ABS / ASA: acceptable alternative.
//
// TESTING BEFORE FLIGHT:
//   1. Print adapter. Verify it slip-fits the 29mm MMT.
//      Slight friction is OK; no force required.
//   2. Test-insert the motor. Should slide cleanly through the
//      throat (if present), into the motor bore, and bottom
//      against the thrust cap.
//   3. Inspect the thrust cap for print defects / layer separation.
//      This cap takes the full motor thrust - MUST be sound.
//   4. Confirm vent hole is open.
//   5. For a new adapter/new material: start with the smallest
//      motor class (A8, not D12). Ground-test ejection if using
//      motor ejection.
//
// SAFETY:
//   - Never remove the thrust cap. Without it, thrust has no
//     path to the airframe - motor goes forward, rocket stays.
//   - Don't reuse a severely scorched adapter. Plastic near
//     the nozzle degrades with each flight.
//
// ***********************************
