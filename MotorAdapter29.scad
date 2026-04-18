// ***********************************
// Project: 3D Printed Rocket
// Filename: MotorAdapter29.scad
// Motor adapter for using 18mm or 24mm motors in a 29mm MMT
// Revision: 0.7 - motor protrudes 5mm past adapter aft face so the
//                 rocket's aft retainer catches the motor rim
//                 directly (not the adapter).  Adapter length is
//                 now motor-dependent, not MMT-dependent.
//           0.6 - removed exhaust throat
//           0.5 - thrust RING (open center)
//           0.4 - Klima 18mm and TSP E20-P 24mm presets
//           0.3 - Motor_Class selector
//           0.2 - motor-length-aware bore with (removed) throat
//           0.1 - single-bore full length (superseded)
// Units: mm
// ***********************************
//
// PURPOSE:
//   Printed adapter for flying 18mm or 24mm motors in a rocket
//   with a 29mm MMT.
//
// DESIGN (v0.7):
//   Adapter is sized to the motor, not to the MMT.  Length is:
//       Adapter_L = Motor_L + Thrust_Ring_T - Motor_Stick_Out
//
//   With Motor_Stick_Out = 5mm (standard), the motor's aft end
//   (nozzle) protrudes 5mm past the adapter's aft face.  This
//   puts the motor's aft rim in the same axial position it would
//   be in if a native 29mm motor were installed, so the rocket's
//   existing aft retainer grips the motor rim directly.
//
//   The adapter then sits loose in the forward portion of the MMT,
//   held by:
//     - Its forward face pressed against the rocket's thrust ring
//     - The motor inside it pressed forward by thrust (during burn)
//       and by the aft retainer (always)
//
//
//   Rocket thrust ring ("edge")                Rocket aft retainer
//                ↓                                      ↓
//   ═══════════════════════════════════════════════════════════
//   ring │       Ø Motor_OD+0.3 bore         │[  motor nozzle 5mm  out ]
//   [O]  │          = Motor_L                │
//   ═════════════════════════════════════════════════════════════
//   3.5mm              Motor_L                5mm   MMT depth - adapter - 5
//   ←──────── adapter total ────────────→←stick-out → ← empty MMT behind →
//
//   Ring [O] has OPEN center Ø (Motor_OD - 2mm) = motor ID, so:
//     - Motor's paper forward cap can blow through cleanly
//       (for motors with ejection charge)
//     - Ejection gases pass unrestricted into the rocket body
//     - Plugged (-P) motors: ring center is harmless
//
//   Thrust path during burn:
//     motor forward rim -> thrust ring aft face
//                       -> adapter wall
//                       -> rocket thrust ring
//                       -> rocket body
//
// ===========================================================
// HOW TO USE:
//   Pick ONE of the preset motor classes by setting Motor_Class
//   below.  Motor_OD and Motor_L are auto-set from the preset
//   table.  Adapter length is then auto-computed from motor length.
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
//   For a non-preset motor, set Motor_Class = -1 and override
//   Motor_OD / Motor_L manually.
//
// MOTOR RETENTION:
//   Rocket's existing 29mm aft retainer catches the MOTOR rim
//   (not the adapter) because the motor protrudes past the
//   adapter's aft face.  No tape or hook needed.
//
// ***********************************

Overlap = 0.05;

// ============================================
// HOST MMT
// ============================================
MMT_ID    = 29.0;      // MMT inner bore
MMT_Depth = 113;       // for info only (adapter no longer fills MMT)

// ============================================
// MOTOR CLASS  (set this to select your motor)
// ============================================
Motor_Class = 5;       // <- EDIT THIS   (5 = 18mm Klima, 6 = 24mm TSP E20-P)

// ============================================
// PRESET TABLE
// ============================================
//                   class:  0         1         2           3           4           5           6
Preset_OD    = [          18,        18,        24,          24,         24,         18,         24             ];
Preset_L     = [          45,        70,        70,          89,         95,         69,         94             ];
Preset_Name  = ["18mm-short", "18mm-std", "24mm-EstesD", "24mm-AT2440", "24mm-EstesE", "18mm-Klima", "24mm-TSP-E20P" ];

// ============================================
// MANUAL OVERRIDE  (Motor_Class = -1)
// ============================================
Manual_Motor_OD = 24;
Manual_Motor_L  = 70;

// ============================================
// PRINT CLEARANCES
// ============================================
Clear_OD = 0.3;        // adapter OD = MMT_ID - Clear_OD  (slip fit in MMT)
Clear_ID = 0.3;        // motor bore = Motor_OD + Clear_ID (motor slides in)

// ============================================
// THRUST RING (forward end, annular)
// ============================================
Thrust_Ring_T         = 3.5;   // axial thickness of the ring
Ring_Inner_Reduction  = 2.0;   // ring inner Ø = Motor_OD - this

// ============================================
// MOTOR PROTRUSION  (key v0.7 parameter)
// ============================================
// How far the motor sticks out of the adapter aft face.  The
// rocket's aft retainer catches the motor rim at this position.
// 5mm is the typical protrusion of a 29mm motor in a 29mm MMT
// with a screw-on retainer cap.
Motor_Stick_Out = 5.0;

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
Thrust_Ring_ID  = Motor_OD - Ring_Inner_Reduction;

// Adapter length is driven by the motor, not the MMT
Adapter_L       = Motor_L + Thrust_Ring_T - Motor_Stick_Out;
Motor_Bore_L    = Adapter_L - Thrust_Ring_T;   // = Motor_L - Motor_Stick_Out

// Walls (for reporting)
Motor_Wall_T   = (Adapter_OD - Motor_Bore_ID) / 2;
Ring_Bearing_W = (Motor_OD - Thrust_Ring_ID) / 2;

// How much MMT space sits empty behind the adapter
MMT_Empty_L    = MMT_Depth - Adapter_L - Motor_Stick_Out;

// ============================================
// REPORT / SANITY CHECKS
// ============================================
echo(str("=== MotorAdapter29 v0.7 ==="));
echo(str("  Motor class:    ", Motor_Class,
        " (", Motor_Label, ")"));
echo(str("  Target motor:   ", Motor_OD, "mm OD, ",
        Motor_L, "mm long"));
echo(str("  Adapter OD:     ", Adapter_OD,
        " mm  (in ", MMT_ID, "mm MMT)"));
echo(str("  Adapter length: ", Adapter_L, " mm",
        "   (motor ", Motor_L, "mm + ring ", Thrust_Ring_T,
        "mm - stick-out ", Motor_Stick_Out, "mm)"));
echo(str("  Motor bore:     Ø", Motor_Bore_ID,
        " x ", Motor_Bore_L, " mm (wall ",
        Motor_Wall_T, " mm)"));
echo(str("  Thrust ring:    Ø", Thrust_Ring_ID,
        " inner x ", Thrust_Ring_T,
        " mm thick (rim contact ", Ring_Bearing_W, " mm)"));
echo(str("  Motor aft stick-out: ", Motor_Stick_Out,
        " mm past adapter aft face"));
echo(str("  MMT empty behind adapter: ", MMT_Empty_L,
        " mm (just air, harmless)"));

if (Motor_Wall_T < 1.5)
    echo("  !! WARNING: motor-bore wall < 1.5mm - use 4+ perimeters.");
if (Ring_Bearing_W < 0.8)
    echo("  !! WARNING: ring-motor bearing overlap < 0.8mm.");
if (Motor_Stick_Out >= Motor_L)
    echo("  !! ERROR: Motor_Stick_Out >= Motor_L, adapter length would be negative.");
if (Adapter_L + Motor_Stick_Out > MMT_Depth)
    echo(str("  !! ERROR: adapter + motor stick-out (",
            Adapter_L + Motor_Stick_Out,
            ") exceeds MMT depth (", MMT_Depth, ")"));

// ============================================
// MAIN ADAPTER
// ============================================
// Z=0 is the aft (open) end of the adapter.
// Z=Adapter_L is the forward end (thrust ring face).
//
module MotorAdapter() {
    difference() {
        // Outer cylinder
        cylinder(d = Adapter_OD, h = Adapter_L, $fn = 180);

        // Motor bore (aft end to thrust ring)
        translate([0, 0, -Overlap])
            cylinder(d = Motor_Bore_ID,
                     h = Motor_Bore_L + Overlap,
                     $fn = 120);

        // Thrust ring open center
        translate([0, 0, Adapter_L - Thrust_Ring_T - Overlap])
            cylinder(d = Thrust_Ring_ID,
                     h = Thrust_Ring_T + 2 * Overlap,
                     $fn = 60);
    }
}

// ============================================
// DUMMY MOTOR (preview only)
// ============================================
module DummyMotor(len = 70) {
    color("silver", 0.7)
    difference() {
        cylinder(d = Motor_OD, h = len, $fn = 60);
        // Aft nozzle indentation
        translate([0, 0, -Overlap])
            cylinder(d = Motor_OD * 0.4, h = 6, $fn = 36);
        // Forward paper cap recess
        translate([0, 0, len - 0.5])
            cylinder(d = Motor_OD - 2, h = 0.5 + Overlap, $fn = 60);
    }
}

// ============================================
// ASSEMBLY PREVIEW  (cross-section)
// ============================================
// Motor forward rim bears on thrust ring.
// Motor aft face is at Z = -Motor_Stick_Out (protrudes below adapter).
//
module AssemblyPreview(motor_len = Motor_L) {
    difference() {
        union() {
            color("tan", 0.6) MotorAdapter();
            translate([0, 0, Adapter_L - Thrust_Ring_T - motor_len])
                DummyMotor(len = motor_len);
        }
        // Cut away -Y half to reveal cross-section
        translate([-MMT_ID, -MMT_ID, -Motor_Stick_Out - 5])
            cube([2 * MMT_ID, MMT_ID, Adapter_L + Motor_Stick_Out + 10]);
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
// FILE NAMING:
//   MotorAdapter29_18mm-Klima.stl
//   MotorAdapter29_24mm-TSP-E20P.stl
//
// PRINT SETTINGS (Bambu P1S, PC or PC-CF):
//   - Orientation: vertical, aft end down.  Thrust ring prints
//     last and bridges the bore opening.
//   - Walls: 4+ perimeters
//   - Infill: 40-60%
//   - Layer height: 0.2mm
//   - Brim recommended
//
// MATERIAL CHOICE:
//   - PC-CF: excellent
//   - PC: recommended
//   - PETG: OK
//   - PLA: NOT recommended (softens near motor casing)
//   - ABS / ASA: OK
//
// TESTING BEFORE FLIGHT:
//   1. Slip-fit check: adapter into 29mm MMT, light friction only.
//   2. Motor fit: slides in from aft, bottoms on thrust ring,
//      aft rim protrudes Motor_Stick_Out mm past adapter aft face.
//   3. Retainer check: rocket's existing aft retainer catches the
//      motor rim (not the adapter).
//   4. Look through the ring from the forward end - you should
//      see the motor's paper forward cap.
//
// EJECTION-CHARGE MOTORS (Estes A-E, Klima non-plugged):
//   - Ground-test deployment once per motor type before flying.
//
// PLUGGED-MOTOR CHECKLIST (Klima-P, TSP -P):
//   - Flight computer armed.
//   - Backup ejection tested.
//
// SAFETY:
//   - Don't widen ring beyond motor tube OD.
//   - Don't reuse a severely scorched adapter.
//
// ***********************************
