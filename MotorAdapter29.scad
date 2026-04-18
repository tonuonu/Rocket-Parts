// ***********************************
// Project: 3D Printed Rocket
// Filename: MotorAdapter29.scad
// Motor adapter for using 18mm or 24mm motors in a 29mm MMT
// Revision: 0.8 - correct full-length design:
//                   aft: motor bore (motor_L - 5mm deep from aft)
//                   fwd: narrow gas passage (Ø12mm) rest of adapter
//                 Motor protrudes 5mm past aft. Adapter fills MMT.
//           0.7 - short adapter (wrong approach - reverted)
//           0.6 - single bore full length (no gas passage)
//           0.5 - thrust ring (open center) - good idea, wrong size
//           0.4 - Klima 18mm and TSP E20-P 24mm presets
//           0.3 - Motor_Class selector
//           0.2 - motor-length-aware bore with exhaust throat
//           0.1 - single-bore full length
// Units: mm
// ***********************************
//
// PURPOSE:
//   Printed adapter for flying 18mm or 24mm motors in a rocket
//   with a 29mm MMT.
//
// DESIGN:
//   Full-length adapter (fills the entire MMT_Depth). Two bores:
//
//     Aft zone:  motor bore Ø (Motor_OD + 0.3),
//                depth = Motor_L - Motor_Stick_Out
//                Motor slides in from aft; its forward rim bottoms
//                on the step into the gas passage. Aft of motor
//                protrudes Motor_Stick_Out past the adapter face.
//
//     Forward zone: gas passage Ø12 (default), takes up the rest
//                of the adapter depth. For motors with ejection
//                charge/delay: gases pass through here into the
//                rocket body. For plugged motors: harmless.
//
//
//   FORWARD end (against rocket thrust ring)            AFT end
//   ═══════════════════════════════════════════════════════════
//        gas passage Ø12            │      motor bore Ø(OD+0.3)   │[motor 5mm out]
//   ═══════════════════════════════════════════════════════════
//        MMT_Depth - (Motor_L - 5)  │       Motor_L - 5           5mm
//   ←─────────────── adapter total = MMT_Depth ──────────────→
//
//   Motor retention:
//     Rocket's existing 29mm aft retainer catches the motor rim
//     (the motor protrudes 5mm, same as a native 29mm motor).
//     No tape, no hook.
//
//   Thrust path during burn:
//     motor forward rim -> step between motor bore and gas passage
//                       -> adapter wall
//                       -> rocket thrust ring ("the edge")
//                       -> rocket body
//
//   Ejection path (motors with ejection charge):
//     charge fires -> paper forward cap blows through gas passage
//     -> gases fill rocket body -> nose cone / chute deploys.
//
// ===========================================================
// HOW TO USE:
//   Set Motor_Class to your motor. Done.
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
// ***********************************

Overlap = 0.05;

// ============================================
// HOST MMT
// ============================================
MMT_ID    = 29.0;
MMT_Depth = 113;       // adapter will be this long

// ============================================
// MOTOR CLASS
// ============================================
Motor_Class = 5;       // <- EDIT THIS   (5 = 18mm Klima, 6 = 24mm TSP E20-P)

// Preset table
Preset_OD    = [          18,        18,        24,          24,         24,         18,         24             ];
Preset_L     = [          45,        70,        70,          89,         95,         69,         94             ];
Preset_Name  = ["18mm-short", "18mm-std", "24mm-EstesD", "24mm-AT2440", "24mm-EstesE", "18mm-Klima", "24mm-TSP-E20P" ];

// Manual override when Motor_Class = -1
Manual_Motor_OD = 24;
Manual_Motor_L  = 70;

// ============================================
// CLEARANCES AND KEY DIMENSIONS
// ============================================
Clear_OD        = 0.3;    // adapter OD = MMT_ID - Clear_OD
Clear_ID        = 0.3;    // motor bore = Motor_OD + Clear_ID
Motor_Stick_Out = 5.0;    // motor aft protrudes past adapter aft face
Gas_Passage_D   = 12.0;   // forward bore Ø (for ejection gases / delay smoke)

// ============================================
// RENDER
// ============================================
// 1 = adapter body (print this)
// 2 = adapter + dummy motor, cross-sectioned
Render_Part = 1;

// ============================================
// DERIVED
// ============================================
Motor_OD    = (Motor_Class == -1) ? Manual_Motor_OD : Preset_OD[Motor_Class];
Motor_L     = (Motor_Class == -1) ? Manual_Motor_L  : Preset_L[Motor_Class];
Motor_Label = (Motor_Class == -1) ? "manual"        : Preset_Name[Motor_Class];

Adapter_OD      = MMT_ID - Clear_OD;
Motor_Bore_ID   = Motor_OD + Clear_ID;
Motor_Bore_L    = Motor_L - Motor_Stick_Out;         // depth from aft face
Gas_Passage_L   = MMT_Depth - Motor_Bore_L;          // rest of adapter length

// For reporting
Motor_Wall_T    = (Adapter_OD - Motor_Bore_ID) / 2;
Step_Radial_W   = (Motor_Bore_ID - Gas_Passage_D) / 2;  // motor rim bearing

// ============================================
// REPORT
// ============================================
echo(str("=== MotorAdapter29 v0.8 ==="));
echo(str("  Motor class:    ", Motor_Class,
        " (", Motor_Label, ")"));
echo(str("  Target motor:   ", Motor_OD, "mm OD, ",
        Motor_L, "mm long"));
echo(str("  Adapter:        Ø", Adapter_OD, " x ", MMT_Depth,
        " mm total (fills MMT)"));
echo(str("  Motor bore:     Ø", Motor_Bore_ID, " x ",
        Motor_Bore_L, " mm from aft (wall ",
        Motor_Wall_T, " mm)"));
echo(str("  Gas passage:    Ø", Gas_Passage_D, " x ",
        Gas_Passage_L, " mm forward of motor"));
echo(str("  Motor rim step: ", Step_Radial_W, " mm radial bearing"));
echo(str("  Motor stick-out: ", Motor_Stick_Out,
        " mm past adapter aft face (grabbed by rocket's aft retainer)"));

if (Motor_Wall_T < 1.5)
    echo("  !! WARNING: motor-bore wall < 1.5mm - use 4+ perimeters.");
if (Step_Radial_W < 1.0)
    echo("  !! WARNING: motor rim step < 1.0mm - gas passage too wide.");
if (Gas_Passage_D >= Motor_Bore_ID)
    echo("  !! ERROR: gas passage is not narrower than motor bore.");
if (Motor_Stick_Out >= Motor_L)
    echo("  !! ERROR: Motor_Stick_Out >= Motor_L.");
if (Motor_Bore_L >= MMT_Depth)
    echo("  !! ERROR: motor bore longer than MMT.");

// ============================================
// MAIN ADAPTER
// ============================================
// Z=0 is the aft (open) end.
// Z=MMT_Depth is the forward end (against rocket thrust ring).
//
module MotorAdapter() {
    difference() {
        // Outer cylinder, full MMT depth
        cylinder(d = Adapter_OD, h = MMT_Depth, $fn = 180);

        // Motor bore, aft zone
        translate([0, 0, -Overlap])
            cylinder(d = Motor_Bore_ID,
                     h = Motor_Bore_L + Overlap,
                     $fn = 120);

        // Gas passage, forward zone (through to forward face)
        translate([0, 0, Motor_Bore_L - Overlap])
            cylinder(d = Gas_Passage_D,
                     h = Gas_Passage_L + 2 * Overlap,
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
// ASSEMBLY PREVIEW (cross-section)
// ============================================
// Motor aft face at Z = -Motor_Stick_Out
// Motor forward rim at Z = -Motor_Stick_Out + Motor_L = Motor_Bore_L
// (bears on the step into the gas passage)
//
module AssemblyPreview(motor_len = Motor_L) {
    difference() {
        union() {
            color("tan", 0.6) MotorAdapter();
            translate([0, 0, -Motor_Stick_Out])
                DummyMotor(len = motor_len);
        }
        // Cut away -Y half
        translate([-MMT_ID, -MMT_ID, -Motor_Stick_Out - 5])
            cube([2 * MMT_ID, MMT_ID, MMT_Depth + Motor_Stick_Out + 10]);
    }
}

// ============================================
// RENDER
// ============================================
if (Render_Part == 1) MotorAdapter();
if (Render_Part == 2) AssemblyPreview(motor_len = Motor_L);

// ============================================
// NOTES
// ============================================
//
// FILE NAMING:
//   MotorAdapter29_18mm-Klima.stl
//   MotorAdapter29_24mm-TSP-E20P.stl
//
// PRINT (Bambu P1S, PC or PC-CF):
//   - Orientation: vertical, aft end down.
//   - Walls: 4+ perimeters
//   - Infill: 40-60%
//   - Layer: 0.2mm
//   - Brim recommended
//
// MATERIAL:
//   - PC-CF: excellent
//   - PC: recommended
//   - PETG: OK
//   - PLA: NOT recommended
//   - ABS/ASA: OK
//
// TEST BEFORE FLIGHT:
//   1. Adapter slip-fits 29mm MMT with light friction.
//   2. Motor slides in from aft, forward rim bottoms on the step,
//      aft rim protrudes 5mm past adapter face.
//   3. Rocket's aft retainer catches the motor rim.
//   4. Look through gas passage from forward end: motor's paper
//      forward cap is visible.
//
// EJECTION MOTORS: ground-test deployment once per motor type.
// PLUGGED MOTORS: flight computer armed, backup ejection tested.
//
// ***********************************
