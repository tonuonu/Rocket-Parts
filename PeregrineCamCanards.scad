// Canard roll/tilt control section, included by PeregrineCamNose.scad.
// Z is the assembled nosecone coordinate (Z=0 at the nosecone base plane,
// where the shell sits on the body-tube rim), also for separate parts.
//
// Four canards at 90 deg, each driven DIRECTLY by its own servo: the canard
// root plug fits over an MKS metal output arm on the servo spline and is
// screwed to it. There is no linkage, so no ball-link or pushrod backlash;
// the remaining play is the servo's own gear train. The four servo/canard
// units are identical and rotated 0/90/180/270 deg about the nose axis. Two
// opposite units are therefore rotated 180 deg relative to each other, so
// one Y-cabled signal (Y-cable at the Vega) deflects both in the same rotational sense: roll,
// without a reverser (stage 1, CATS ROLL_2). Stage 2 (FULL_4) drives the
// same four servos independently; nothing mechanical changes.
//
// Architecture (owner decision 2026-11-16): the CATS Vega flies IN the
// nose, on a mast above the servo cassette, with its own 2S LiPo. The nose
// carries the MAIN charge on the shoulder bulkhead and only comes off at
// main deployment; the drogue fires aft of the passive e-bay while the nose
// joint is still closed. The shoulder bulkhead is the gas-seal plane.
//
// 2026-11-19: four 18650 slots in the servo cassette (servo pair feeds the
// servos and camera; optional FC pair feeds the Vega instead of the LiPo),
// held from below by a cell keeper (part 19).
//
// Service: everything inserts from below. With the shoulder unscrewed (12
// radial M3 button heads; part 1 is no longer glued) and the cell keeper
// off, the cells drop out; the servo cassette (part 9) and then the Vega
// mast unit (part 14) slide out. Canards come off
// from outside: two M2 screws each, then the output hub's centre screw.
//
// Servo: MKS HV6160 (thin wing servo). Geometry from the MKS dimension
// drawing (as published by MKS Servo Distribution Europe; mks-servo.com's
// own copy is not reachable from here). Details the drawing does not give
// -- lead stub, case-screw heads, the metal arm's hub and arm sizes -- are
// estimates. Measure a real servo and arm before printing: Servo_*, Horn_*.

use<ChargeHolder.scad>
use<BatteryHolderLib.scad>

// ============================================
// LAYOUT
// ============================================
// Angles are OpenRocket's (PeregrineL2.ork): fins at 0/120/240, rail
// buttons at 60. The canards sit 45 deg off the rail line, at 15/105/195/285.
Rail_A    = 60;
Canard_A0 = Rail_A + 45 - 90;   // canard 1; others at +90 each
Canard_Z  = 50;     // pivot station = servo spline axis, above the base plane

// ============================================
// CANARD PLANFORM (one panel). Sized for static margin, see
// tools/canard_estimate.py: span 25 keeps the fail-safe trim small.
// ============================================
Canard_Root_C   = 45;
Canard_Tip_C    = 25;
Canard_Span     = 25;   // exposed, from the root gap outward
Canard_LE_Sweep = 12;   // tip LE this far aft of root LE
Canard_T        = 4;    // blade thickness
Canard_Bevel    = 1.5;  // LE/TE/tip bevel per side
Canard_Root_Gap = 0.8;  // blade root to skin, grows with deflection
// Pivot slightly AHEAD of the panel's centre of pressure, so the hinge
// moment always restores toward neutral: a limp or disconnected canard
// weathercocks to zero instead of flopping to a stop.
Canard_Pivot_Fwd = 0.05;   // fraction of MAC ahead of the Barrowman panel CP

// Barrowman panel CP (from root LE, along the body axis) and MAC
Canard_Lambda = Canard_Tip_C/Canard_Root_C;
Canard_MAC = 2/3*Canard_Root_C*(1+Canard_Lambda+Canard_Lambda*Canard_Lambda)/(1+Canard_Lambda);
Canard_Xf = Canard_LE_Sweep*(Canard_Root_C+2*Canard_Tip_C)/(3*(Canard_Root_C+Canard_Tip_C)) +
            (Canard_Root_C+Canard_Tip_C-Canard_Root_C*Canard_Tip_C/(Canard_Root_C+Canard_Tip_C))/6;
Canard_Pivot_From_LE = Canard_Xf - Canard_Pivot_Fwd*Canard_MAC;
Canard_LE_Z = Canard_Z + Canard_Pivot_From_LE;
Canard_TE_Z = Canard_LE_Z - Canard_Root_C;

// ============================================
// DEFLECTION LIMITS
// ============================================
Canard_Max_Cmd = 8;    // firmware ctrl_max_defl default
Canard_Stop    = 11;   // hard stop; design range 10..12
assert(Canard_Stop >= Canard_Max_Cmd+2 && Canard_Stop <= 15,
       "stop must sit just beyond the commanded range");

// ============================================
// SERVO (MKS HV6160 drawing -- MEASURE the estimated values)
// Servo frame used below: bottom face at local x = Servo_Bottom_R, spline
// axis on local y=0, z=0, the case's spline end facing -z (toward the base).
// The output is along the case HEIGHT, as on a standard servo; the case is
// just 10 mm thick, so the four cases stand side by side around the axis.
// ============================================
Servo_L          = 33;     // case length (drawing)
Servo_W          = 10;     // case thickness (drawing)
Servo_Case_H     = 35.2;   // case bottom to case top (drawing)
Servo_Spline_Off = 6;      // spline axis to spline-end face (drawing: 9 from the lug hole)
Servo_Spline_D   = 5;      // MKS 5 mm output (drawing)
Servo_Spline_Top = Servo_Case_H + 3.5;   // spline tip (drawing; 39.0 "max" at retailers)
// Integral lugs: a 2 mm plate centred on the thickness at the spline end of
// the case, 45 mm overall, one Ø3 hole each end on 39 mm, 31.2 above the
// bottom. Screws run through the lug ACROSS the case thickness (local y).
Servo_Lug_L      = 45;
Servo_Lug_H      = 8;      // from the case top down
Servo_Lug_T      = 2;
Servo_Lug_Hole_D = 3;
Servo_Lug_Hole_X = 31.2;   // above the case bottom
Servo_Lug_Spacing = 39;
Servo_Wire       = [2.2, 10, 7, 4];   // stub below the bottom, z centre, z length, width (estimated)
Servo_Lug_Ext    = (Servo_Lug_L-Servo_L)/2;
Servo_Centre_Z   = Servo_L/2 - Servo_Spline_Off;     // case centre rel. spline axis
// The four case bottoms face each other round a central channel that the
// leads (which leave the bottom face) drop down through to the floor. The
// spline tip must pass under the plug-hole rings while the cassette slides
// in (asserted below), which caps this radius.
Servo_Bottom_R   = 7.0;
assert(Servo_Bottom_R > Servo_W/2 + 0.5, "servo cases collide on the axis");

// OUTPUT SPLINE -- no HV6160 spline data exists yet; the owner measures it.
// Only the envelope and the hub's bore depend on these; nothing printed
// engages the spline.
// ============================================
Servo_Spline_Teeth = 0;      // 0 = unknown, MEASURE
Servo_Spline_OD    = Servo_Spline_D;
Servo_Shaft_H      = Servo_Spline_Top - Servo_Case_H;   // spline above the case top
Servo_Centre_Screw = "M2.5";  // MKS drawing; thread length unknown

// ============================================
// OUTPUT HUB and ROOT PLUG
// Horn_Type "clamp" (first choice): an aluminium clamp-type hub on the
//   spline with a flat top face and two tapped holes; the plug bolts to it
//   through ROUND holes, so the only angular play is the spline itself.
// Horn_Type "arm" (fallback): the servo's supplied arm sits in a form-fit
//   pocket in the plug, held by the centre screw plus one cross screw
//   through the plug into the arm's tapped outer hole.
// No slots either way; the neutral offset goes in firmware ctrl_trimN.
// ============================================
Horn_Type     = "clamp";
// Ø14: at Ø12 the tapped M2 holes at r=5 ran out at the rim. The holes stay
// at ±5 so the Ø2.4 holes in the printed canards still line up.
Clamp_Hub_D   = 14;
Clamp_Hub_H   = 5;      // above the case top: spline + centre screw head
Clamp_Holes_R = [-5, 5];   // tapped M2 (1.6 drill), along local y, clear of the blade
Clamp_Thread_R = 1;     // M2 major radius
Clamp_Thread_Wall = 0.8;  // aluminium round each tapped hole
Clamp_Wall    = 0.5;    // further aluminium between that and the spline bore
assert(max([for(r=Clamp_Holes_R) abs(r)]) + Clamp_Thread_R + Clamp_Thread_Wall <= Clamp_Hub_D/2,
       "clamp-hub tapped hole runs out at the hub rim");
assert(min([for(r=Clamp_Holes_R) abs(r)]) - Clamp_Thread_R - Clamp_Thread_Wall
       >= Servo_Spline_OD/2 + Clamp_Wall, "clamp-hub tapped hole breaks into the spline bore");
Horn_Hub_D    = Horn_Type=="clamp" ? Clamp_Hub_D : 8;
Horn_Hub_H    = Horn_Type=="clamp" ? Clamp_Hub_H : 4.8;
Horn_Arm_W    = 5.5;    // fallback arm (estimated; measure)
Horn_Arm_T    = 2.5;
Horn_Arm_L    = 12;
Horn_Holes_R  = Horn_Type=="clamp" ? Clamp_Holes_R : [9];
Horn_Gap      = 0.3;    // hub underside above the case top
Plug_X0       = Servo_Bottom_R + Servo_Case_H + Horn_Gap;   // plug inner face radius
Plug_Pocket_Clear = 0.1;
Plug_D        = 27;     // root plug, turns in a hole through the shell (fits either hub)
Plug_Clear    = 0.3;    // radial; the plug never bears on the shell
Plug_Hole_R   = Plug_D/2 + Plug_Clear;
Plug_Screw_D  = 2.4;    // M2 clearance, round
Plug_Screw_Head_D = 3.8;  // M2 90-deg countersunk
// Stop: a tab of the shell projects into the plug hole and runs in a
// slot along the plug side. The slot is open along the whole plug, so the
// canard goes in from outside past the tab. The slot's flanks are radial,
// so they meet the tab's inner corners at exactly +-Canard_Stop.
Stop_Tab_W = 3;
Stop_Tab_P = 2;         // tab protrusion into the hole
Stop_Tab_A = 52;        // position on the plug rim, deg from local +y toward +z;
                        // between the arm (0 deg) and the blade root (90 deg)
Stop_Slot_Clear = 0.3;
Stop_Tab_Rin = Plug_Hole_R - Stop_Tab_P;
Stop_Slot_Half = Canard_Stop + atan((Stop_Tab_W/2)/Stop_Tab_Rin);
Hole_Ring_W = 3;        // reinforcing ring round each hole, inside the shell
Hole_Ring_T = 2;

// ============================================
// SERVO CASSETTE (part 9)
// ============================================
Cas_Clear    = 0.3;
Cas_Wall     = 2.5;     // cradle side walls
Cas_Floor_T  = 3;
// The floor passes under the plug-hole rings at the canards.
Cas_Floor_Top = Canard_Z - Plug_Hole_R - Hole_Ring_W - 1;
Cas_Floor_Z  = Cas_Floor_Top - Cas_Floor_T;
Cas_Top_Z    = Canard_Z - Servo_Spline_Off - Servo_Lug_Ext + Servo_Lug_L + 1.5;
// Lugs: M2.5 through-bolts across the lug into a block beside it, nut in a
// trap on the block's far face. (An insert pocket would sit too close to
// the case end: the hole is only 3 mm from it.) The head side is reached
// through a hole in the opposite cradle wall.
Lug_Bolt_D   = 2.7;
Lug_Nut_AF   = 5.0;     // M2.5 hex nut
Lug_Nut_T    = 2.0;
Lug_Access_D = 6;
Cas_Lug_Y0   = Servo_Lug_T/2 + 0.05;       // block face the lug is pulled against
// Cassette to shell: 4 radial M3 countersunk screws between the canards,
// into ruthex M3x5.7 in bosses standing on the floor (the print bed side).
Cas_Screw_A  = [45,135,225,315];
Cas_Boss_D   = 9;
Cas_Screw_Z  = Cas_Floor_Z + Cas_Boss_D/2;
Cas_Boss_L   = Insert_Pocket_L + Bay_Screw_Tip_L/2 + 1.5;
Cas_Lead_Hole = 2*(Servo_W/2 + Cas_Clear) - 0.6;   // square, central channel

// ============================================
// SHOULDER JOINT -- screwed instead of glued, so the cassette can come out
// ============================================
// This joint carries the main-deployment load: ribbon on the shoulder
// bulkhead -> spigot -> screws in shear -> skirt. Twelve M3 BUTTON heads in
// plain holes: a countersink would leave only ~0.8 mm of the 2.2 mm skirt
// in bearing. Pull-test the joint coupon (parts 16+17) to >= 3.0 kN.
Sh_Joint_A = [for(k=[0:11]) 15+30*k];
Sh_Button_Head_D = 5.7;   // ISO 7380 M3
Sh_Joint_Z = Shoulder_Spigot_L/2;     // assembled Z, middle of the spigot
Sh_Boss_D  = 9;
Sh_Spigot_R = Shoulder_Spigot_OD/2;
Sh_Boss_L  = Insert_Pocket_L + Bay_Screw_Tip_L/2 + 1;

// ============================================
// INDEX KEY (nose <-> body tube)
// ============================================
// A key below the shell base engages a notch filed in the tube's forward
// rim at rail + 45 deg. It keeps the canards off the rail line and carries
// the canard roll torque into the airframe (~2 N m, ~40 N at the key).
Index_Key_Enabled = true;
Index_Key_A = Rail_A + 45;
Index_Key_W = 6;
Index_Key_H = 6;

// ============================================
// SHOULDER BULKHEAD: main charge, terminals, facing disc
// ============================================
// The bulkhead is the gas-seal plane. The ribbon loop through the two
// T-slots is permanent: pot slots and stems with high-temperature RTV.
Bulk_Add_T   = 2.5;      // extra bulkhead thickness on the inside
Facing_T     = 1.5;      // G10 1.5 (or plywood 3: set 3 and re-check)
// Seat = the flat outer face of the bulkhead itself. A recess or a lip would
// put a 95 mm bridge on the bed face (the shoulder prints bulkhead-down), so
// the disc is located by the two charge-well bolts and the four terminal
// posts that pass through it, and bonded with high-temperature RTV.
Facing_D     = Shoulder_OD - 2*(Shoulder_Entry_Chamfer_R + 1);
Charge_Dia   = 14;       // ChargeHolder.scad well
Charge_CC    = 3;
Charge_XY    = [-24, 0];
Charge_Bolt_Sp = Charge_Dia + 2*3.4 + 2*5.5;   // ChargeHolder's own CH_BC
Term_XY      = [[20,-6],[20,6],[28,-6],[28,6]]; // 4 x M3 brass posts: main pair, drogue pair
Term_D       = 3.2;

// ============================================
// CATS VEGA in the nose (mast unit, part 14)
// ============================================
// Board data from ~/cats-hardware/CATS-Vega/3D/CATS-Vega.step (STEP frame:
// top face at Z=0, board 100 x 33 x 1.6, centred). The STEP has no GNSS
// patch (BOM: 18x18 THT patch, feed at X=-17,Y=0, top side) and no WAGO
// terminals; those are envelopes (Vega_Top_H, Vega_Bot_H).
// Mounting: board long axis = rocket axis, board plane parallel to the
// canard-1 axis (15-195 deg), patch side toward the wall at 105 deg. SMA
// (right-angle, -X end) at the top so the whip runs up the wall; USB-C on
// the +Y long edge faces sideways (no 90-deg adapter), toward ~174 deg.
Vega_Board  = [100, 33, 1.6];
Vega_Holes  = [[-30,-13.5],[30,-13.5],[30,13.5]];   // M3, STEP
Vega_Top_H  = 6;      // patch side above the top face (patch not in the STEP)
Vega_Bot_H  = 14.3;   // top face to the lowest bottom-side part (STEP)
Vega_SMA    = [[-53.7,-50],[5.9,16.1],[-13.1,-2.9]];   // STEP ranges X,Y,Z
Vega_USB    = [[5.9,14.9],[8.9,16.4],[-1.0,3.3]];
Vega_Header = [[-6.9,1.9],[-16.5,-2.6],[-7.2,1.6]];    // servo 2x3, exits -Y edge
Vega_Z_Mid  = 170;    // board centre (STEP X=0); board spans Z 120..220
Vega_U      = -18.8;  // board centre along the canard-1 axis (toward 195 deg)
Vega_N      = 15;     // top face along the board normal (toward 105 deg)
Vega_Standoff_D = 8;  // M3 ruthex 5.7 in each (pocket 7.7)
Vega_RF_Clear = 25;   // board to the cells above and the servos below

Roof_Z0    = Cas_Top_Z + 0.5;   // sits on the cassette
Roof_T     = 3;
Roof_Rim_H = 6;                 // rim band carrying the foam-ring groove
// The roof passes the plug-hole rings on the way in, so its radius is the
// rings' bore; a closed-cell foam cord (Ø5) in the rim groove bridges the
// gap to the shell and squeezes past the rings.
Roof_R     = CN_Inner_R(Canard_Z+Plug_Hole_R+Hole_Ring_W) - Hole_Ring_T - 0.3;   // ring top: narrowest
Foam_Groove = [4.2, 2.5];        // width, depth
Roof_Screw_Z = Roof_Z0 + Cas_Boss_D/2;
Roof_Pass  = [3, 3, 9];          // local x(u), y(n), dia: leads, servo power, pyro
Mast_T     = 3;
Mast_Top_Z = Vega_Z_Mid + 30 + 8;
Mast_Front_N = Vega_N - Vega_Bot_H - 0.5;
LiPo_Z     = 170;                // pocket centre
// Vega LiPo: 2S = two 1S 362543 pouch cells (290 mAh, 1.073 Wh, the owner's
// stock) stacked face to face and wired in series; 2S keeps the pyro voltage.
// 362543 = 3.6 thick x 25 wide x 43 long (nominal, from the type code).
LiPo_Cell  = [25, 3.6, 43];      // u (width), n (thickness), Z (length)
LiPo_Cells = 2;
LiPo_Clear = [1.0, 0.8, 1.0];    // total play: +-0.5 width tolerance, swell, tape
LiPo_Wall  = 1.2;
LiPo_In    = [LiPo_Cell[0]+LiPo_Clear[0], LiPo_Cells*LiPo_Cell[1]+LiPo_Clear[1], LiPo_Cell[2]+LiPo_Clear[2]];
LiPo_Out   = LiPo_In + 2*[LiPo_Wall, LiPo_Wall, LiPo_Wall];
// The pocket and its two webs end flush with the flange's +u edge
// (Vega_U+15), away from the roof pass, and grow toward -u.
LiPo_U     = Vega_U + 15 - Mast_T - LiPo_Out[0]/2;
Mast_U0    = min(Vega_U - 15, LiPo_U - LiPo_Out[0]/2 - Mast_T);   // flange -u edge
Cap_D      = 10;  Cap_L = 16;   // 1000 uF / 16 V at the cassette
Cap_A      = 300; Cap_R = 26;

// Vega power switch (second Schurter 0033.4513, same cut as the camera's)
// and the USB window: both on the side away from the rail.
Vsw_A = 300;  Vsw_Z = 120;
USB_Win = [12, 7];               // along Z x along n

// Static ports into the sealed Vega bay, between the canards, above the
// 02/03 glued lap (the lap is Z 147-154). Slice 03 is already printed: they
// can be drilled.
Port_Z = 160;  Port_D = 2.5;
// Camera power pass-through in the camera-bay floor (part 06), potted.
Floor_Pass_XY = [0, 18];  Floor_Pass_D = 4;

// ============================================
// 18650 CELLS beside the servos (in part 9) and CELL KEEPER (part 19)
// ============================================
// Four identical sleeves in the quadrants between the servos. The servo
// pair (60/240 deg) feeds the servos and the camera; the FC pair (150/330)
// optionally feeds the Vega, whose LiPo pocket on the mast stays as the
// alternative. Cells carry spot-welded tabs and soldered leads; there are
// no spring contacts. A cell bears only on its insulated rims: below on a
// seat ring of the keeper, above on a C-ring pad under the mast roof, so
// tabs and solder joints carry no load. The cells hang through the cassette
// floor; with the shoulder and the keeper off they drop out downward.
Cell_A       = [for(k=[0:3]) Canard_A0+45+90*k];   // 60, 150, 240, 330
Cell_Servo_A = [Cell_A[0], Cell_A[2]];
Cell_R       = 25.5;                 // sleeve axis radius
Cell_D       = Bay_Cell_D;           // 18.5 wrapped
Cell_Body_L  = Bay_Cell_Body_L;      // 65, excluding tabs
Cell_Bore_D  = Bay_Cup_ID;           // 19.5
Cell_Wall    = 1.6;
Cell_Sleeve_OD = Cell_Bore_D + 2*Cell_Wall;   // 22.7
Cell_End_Relief = Bay_End_Relief;    // 2: tab and solder joint room at each end
Cell_Slot_W  = Bay_Tab_Slot_W;       // 6: full-height tab/lead slot toward the axis
Cell_Notch   = [Cell_Slot_W, 5];     // floor notch toward the axis: width, depth
// Top pad: C-ring, 1.5 fishpaper/G10 + 0.5 closed-cell foam, OD 18, ID 12,
// gap toward the slot. It bears on the rim, never on the tab, and is the
// stack's only compliance: there is no other axial slack.
Cell_Top_Pad_T = 2;
Cell_Pad = [18, 12];                 // OD, ID
Cell_Top_Z    = Roof_Z0 - Cell_Top_Pad_T;   // 83
Cell_Bottom_Z = Cell_Top_Z - Cell_Body_L;   // 18
// Lacing-cord tie holes (strain relief), a pair per sleeve in the floor of
// the cradle on the sleeve's clockwise side (canard local frame).
Cell_Tie_D   = 2.5;
Cell_Tie_XY  = [[10, 3], [15, 3]];

// Keeper (part 19): a plate under the cassette floor, inside the shoulder
// spigot and above the shoulder's insert bosses, with four seat rings and
// four columns screwed up into the cassette.
Keeper_T     = 2.5;
Keeper_Top_Z = Cell_Bottom_Z - Cell_End_Relief;   // 16
Keeper_Z0    = Keeper_Top_Z - Keeper_T;           // 13.5
Keeper_R     = 38;
Keeper_Lead_D = 12;                  // central lead hole (pyro, pack leads)
Keeper_Ring  = [Bay_End_Window_D, Cell_Bore_D];   // seat ring ID, OD (14.5, 19.5)
Keeper_Col_D = 8;
// Fixing: M3x20 90-deg countersunk, flush under the plate, into ruthex
// M3x5.7 set from below into a Ø8 boss on the cassette floor. The boss
// stands against the outer face of each cradle's -y wall (canard local
// frame): no lug block, no nut trap, clear of the lug-bolt driver line.
Keeper_Fix   = [31, -10.5];
Keeper_Boss_D = 8;
Keeper_Boss_Top_Z = Cas_Floor_Z + Insert_Pocket_L + 1.6;
Keeper_Screw_L = 20;

// Servo switch: a third Schurter 0033.4513 on the printed slice 02, drilled
// by hand (Ø12.7 + R1.2 key relief), with a glue-on saddle (part 12) inside
// the shell for a flat nut face. Slice 02's source is NOT changed.
Ssw_A = 30;  Ssw_Z = 106;
Ssw_Bezel = [15.2, 2.3];             // datasheet: bezel Ø15.2 x 2.3
Ssw_Body  = [16, 23.5];              // conservative rear envelope behind the face
Ssw_Thread_D = 12.6;
// The ogive widens downward, so the flat bezel first touches the skin at
// its lowest point; the saddle's flat back is a full panel thickness behind.
Ssw_Face_R = CN_Outer_R(Ssw_Z - Ssw_Bezel[0]/2);
Ssw_Panel_T = Bay_Switch_Panel_T;    // 6; the switch allows up to 8.5
Ssw_Glue = 0.2;                      // epoxy gap, saddle to the shell
Roof_Pass_Ream_D = 11;               // ream the printed Ø9 roof pass (part 14)

// ============================================
// SANITY CHECKS
// ============================================
function CN_Outer_R(Z) = Z < NC_Base_L ? Peregrine_Body_OD/2 : Ogive_OD_At_Z(Z)/2;
function CN_Inner_R(Z) = Z < NC_Base_L ? Peregrine_Coupler_OD/2 : Ogive_OD_At_Z(Z,NC_Wall_T)/2;
Canard_Skin_R = CN_Outer_R(Canard_Z);
assert(Canard_TE_Z > NC_Base_L, "canard TE must stay on the ogive above the skirt screws");
assert(Cas_Floor_Z > Shoulder_Spigot_L + 1, "cassette floor must clear the shoulder spigot");
assert(Canard_Z - Plug_Hole_R - Hole_Ring_W >= Cas_Floor_Top + 1,
       "plug ring would block the cassette floor");
assert(Horn_Hub_D/2 < Stop_Tab_Rin, "arm hub must pass the stop tab in the plug hole");
for(r=Horn_Holes_R) assert(abs(r) - Plug_Screw_Head_D/2 > Canard_T/2 + 0.5, "plug screw head under the blade");
// The slot sector must clear the arm pocket (at 0 deg) and the blade root
// (at 90 deg). The arm itself passes the tab when fitted from outside.
assert(Stop_Tab_A - Stop_Slot_Half > (Horn_Type=="arm" ?
       asin((Horn_Arm_W/2+Plug_Pocket_Clear+1)/(Stop_Tab_Rin-Stop_Slot_Clear)) : 0) + 2,
       "stop slot cuts the arm pocket");
assert(Horn_Type=="arm" || Clamp_Hub_D/2 + 1 < Stop_Tab_Rin - Stop_Slot_Clear, "stop slot cuts the hub pocket");
assert(Stop_Tab_A + Stop_Slot_Half < 90 - asin((Canard_T/2)/(Stop_Tab_Rin-Stop_Slot_Clear)) - 2,
       "stop slot cuts the blade root");
assert(Servo_Bottom_R + Servo_Spline_Top < CN_Inner_R(Cas_Floor_Top+1) - Hole_Ring_T - 0.5,
       "spline tip would hit the plug-hole ring while the cassette slides in");
assert(Plug_X0 < CN_Inner_R(Canard_Z) - Hole_Ring_T - 2,
       "case top too close to the shell: no room for the plug");
assert(Canard_Skin_R - (Plug_X0 + Horn_Hub_H + Plug_Pocket_Clear) >= 1.5,
       "plug too thin over the arm hub");
assert(Sh_Joint_Z + Sh_Boss_D/2 < Shoulder_Spigot_L, "joint boss off the spigot");
// Vega fit: board corners, patch envelope and SMA inside the shell along the
// whole board, mast and SMA below the camera-bay corbel, RF clearances.
Vega_Corbel_Z = Bay_Floor_Z - Bay_Seat_T - Bay_Seat_Ramp;    // 245
Vega_Top_Z = Vega_Z_Mid - Vega_SMA[0][0];                     // SMA tip
for(z=[Vega_Z_Mid-Vega_Board[0]/2:10:Vega_Top_Z])
    assert(norm([abs(Vega_U)+Vega_Board[1]/2, Vega_N+Vega_Top_H]) < CN_Inner_R(z) - 1,
           str("Vega patch side hits the shell at Z=", z));
assert(Vega_Top_Z < Vega_Corbel_Z - 15, "Vega SMA too close to the camera-bay corbel");
assert(Mast_Top_Z < Vega_Corbel_Z, "mast above the corbel");
assert(Bay_Cell_Bottom_Z - (Vega_Z_Mid + Vega_Board[0]/2) >= Vega_RF_Clear, "Vega within 25 mm of the cells");
assert((Vega_Z_Mid - Vega_Board[0]/2) - (Canard_Z - Servo_Spline_Off - Servo_Lug_Ext + Servo_Lug_L) >= Vega_RF_Clear,
       "Vega within 25 mm of the servos");
assert(Port_Z > Cut1_Z + 7 + Port_D, "static ports in the glued lap");
// Cells: the sleeve bore stays outside the cradle walls, the wall arcs stay
// inside the walls' thickness (never in a servo cradle), and the bore ends
// inside the quadrant screw boss's tip relief.
Cas_Yw = Servo_W/2 + Cas_Clear;
assert(Cell_R*sin(45) - Cell_Bore_D/2 >= Cas_Yw + Cas_Wall + 0.3, "cell bore cuts a cradle wall");
assert(Cell_R*sin(45) - Cell_Sleeve_OD/2 > Cas_Yw, "sleeve wall reaches into a servo cradle");
assert(Cell_R + Cell_Bore_D/2 < CN_Inner_R(Cas_Floor_Z+Cas_Boss_D) - Cas_Clear - Insert_Pocket_L - Bay_Screw_Tip_L/2 - 1.5,
       "cell bore too close to the cassette screw's tip relief");
assert(Cell_Top_Z + Cell_Top_Pad_T <= Roof_Z0, "cell stack taller than the space under the roof");
assert(Cell_Top_Z < Cas_Top_Z, "cell top above the sleeve");
assert((Vega_Z_Mid - Vega_Board[0]/2) - (Cell_Top_Z + Cell_Top_Pad_T) >= Vega_RF_Clear,
       "Vega within 25 mm of the cassette cells");
// Keeper: above the shoulder's insert bosses, inside the spigot, and its
// screws hold in a sound boss.
assert(Keeper_Z0 >= Sh_Joint_Z + Sh_Boss_D/2 + 1, "keeper plate on the shoulder boss tops");
assert(Keeper_R < Sh_Spigot_R - NC_Wall_T - 2, "keeper plate hits the shoulder spigot");
assert(Keeper_Boss_D >= Insert_Hole_D + 2*1.6, "keeper boss wall under ruthex minimum (1.6 mm)");
assert(Keeper_Boss_Top_Z - (Cas_Floor_Z + Insert_Pocket_L) >= 1.2, "keeper insert pocket breaks through the boss top");
assert(Keeper_Z0 + Keeper_Screw_L - Cas_Floor_Z >= 4, "keeper screw engages less than 4 mm of the insert");
assert(Keeper_Z0 + Keeper_Screw_L < Cas_Floor_Z + Insert_Pocket_L, "keeper screw bottoms in the pocket");
assert(norm(Keeper_Fix - [Cell_R*cos(45), -Cell_R*sin(45)]) - Insert_Hole_D/2 - Cell_Bore_D/2 >= 1.6,
       "keeper insert pocket too close to the cell bore");
assert(Keeper_Fix[1] + Keeper_Boss_D/2 < -Cas_Yw, "keeper boss reaches into the servo cradle");
assert(Keeper_Fix[0] + Keeper_Boss_D/2 < Servo_Bottom_R + Servo_Lug_Hole_X - Lug_Access_D/2,
       "keeper boss in the lug-bolt access hole");
assert(Ssw_Panel_T <= 8.5, "servo switch panel thicker than the Schurter allows");

echo(str("CANARD: pivot Z=", Canard_Z, " LE Z=", Canard_LE_Z, " TE Z=", Canard_TE_Z,
         " MAC=", Canard_MAC, " Xf=", Canard_Xf, " pivot from LE=", Canard_Pivot_From_LE,
         " skin R=", Canard_Skin_R, " stop=", Canard_Stop, " slot half=", Stop_Slot_Half));
echo(str("CANARD_PARAMS ", Canard_Root_C, " ", Canard_Tip_C, " ", Canard_Span, " ",
         Canard_LE_Sweep, " ", Canard_Z, " ", Canard_LE_Z, " ", Canard_Pivot_Fwd, " ",
         Canard_Stop, " ", Canard_Max_Cmd, " ", Canard_Skin_R, " ",
         Servo_Bottom_R+Servo_Spline_Top));

echo(str("CANARD_CHECK ", CN_Inner_R(Cas_Floor_Z+Cas_Boss_D)-Cas_Clear, " ", Cas_Screw_Z, " ",
         Sh_Joint_Z, " ", Sh_Spigot_R, " ", Insert_Pocket_L, " ", Cas_Floor_Z, " ", Cas_Top_Z, " ",
         Index_Key_A, " ", Index_Key_H, " ", Canard_A0, " ", Plug_X0));

echo(str("CANARD_LUGS ", Servo_Bottom_R+Servo_Lug_Hole_X, " ", Canard_Z+Lug_Hole_Zs()[0], " ",
         Canard_Z+Lug_Hole_Zs()[1], " ", Servo_W/2+Cas_Clear+Cas_Wall-Lug_Nut_T-0.4));

echo(str("CANARD_VEGA ", Vega_U, " ", Vega_N, " ", Vega_Z_Mid, " ", Roof_Screw_Z, " ",
         CN_Inner_R(Roof_Screw_Z)-0.3, " ", Port_Z, " ", Floor_Pass_XY[0], " ", Floor_Pass_XY[1], " ",
         Bay_Floor_Z, " ", Bay_Floor_T, " ", Mast_Top_Z, " ", Rail_A, " ", Roof_Z0));

echo(str("CELLS_GEOM ", Cell_R, " ", Cell_D, " ", Cell_Bottom_Z, " ", Cell_Top_Z, " ",
         Cell_Top_Pad_T, " ", Keeper_Z0, " ", Keeper_Fix[0], " ", Keeper_Fix[1], " ",
         Cas_Floor_Z, " ", Cas_Floor_Z+Insert_Pocket_L, " ", Keeper_Boss_Top_Z, " ",
         Keeper_Screw_L, " ", Bay_Charge_Head_D));
echo(str("SSW_GEOM ", Ssw_A, " ", Ssw_Z, " ", Ssw_Face_R, " ", Ssw_Bezel[0], " ", Ssw_Bezel[1], " ",
         Roof_Pass[0], " ", Roof_Pass[1], " ", Roof_Pass[2], " ", Roof_Pass_Ream_D, " ",
         Roof_Z0, " ", Roof_T, " ", Roof_Rim_H, " ", Peregrine_Body_OD/2));

// ============================================
// FRAMES
// ============================================
// Local canard frame k: x radial out, y tangential, z axial (0 at Canard_Z)
module Canard_Frame(k){
    rotate([0,0,Canard_A0+90*k]) translate([0,0,Canard_Z]) children();
}
module Radial_At(a, r, z){   // child +Z points radially inward
    rotate([0,0,a]) translate([r,0,z]) rotate([0,-90,0]) children();
}
// Blind ruthex M3x5.7 pocket (L+2) plus screw-tip relief, entering at radius r
module Radial_Insert_Pocket(a, r, z){
    Radial_At(a, r+Overlap, z) cylinder(d=Insert_Hole_D,h=Insert_Pocket_L+Overlap,$fn=36);
    Radial_At(a, r-Insert_Pocket_L+Overlap, z) cylinder(d=Bay_M3_Clearance,h=Bay_Screw_Tip_L/2,$fn=36);
}

// ============================================
// SERVO ENVELOPE (inspection and clearance checks only)
// ============================================
module Canard_Servo_Envelope(){
    b = Servo_Bottom_R;
    difference(){
        union(){
            translate([b,-Servo_W/2,-Servo_Spline_Off]) cube([Servo_Case_H,Servo_W,Servo_L]);
            translate([b+Servo_Case_H-Servo_Lug_H,-Servo_Lug_T/2,-Servo_Spline_Off-Servo_Lug_Ext])
                cube([Servo_Lug_H,Servo_Lug_T,Servo_Lug_L]);
        }
        for(z=Lug_Hole_Zs()) translate([b+Servo_Lug_Hole_X,0,z]) rotate([90,0,0])
            cylinder(d=Servo_Lug_Hole_D,h=Servo_W,center=true,$fn=24);
    }
    translate([b+Servo_Case_H-Overlap,0,0]) rotate([0,90,0])
        cylinder(d=Servo_Spline_D,h=Servo_Spline_Top-Servo_Case_H+Overlap,$fn=36);
    translate([b-Servo_Wire[0],-Servo_Wire[3]/2,Servo_Wire[1]-Servo_Wire[2]/2])
        cube([Servo_Wire[0]+Overlap,Servo_Wire[3],Servo_Wire[2]]);
}
function Lug_Hole_Zs() = [Servo_Centre_Z-Servo_Lug_Spacing/2, Servo_Centre_Z+Servo_Lug_Spacing/2];
// Output arm along local +y, hub on the spline
module Canard_Horn_Shape(c=0){
    x0 = Plug_X0 - c;
    translate([x0,0,0]) rotate([0,90,0]) cylinder(d=Horn_Hub_D+2*c,h=Horn_Hub_H+2*c,$fn=48);
    if (Horn_Type=="arm") hull(){
        translate([x0,0,0]) rotate([0,90,0]) cylinder(d=Horn_Arm_W+2*c,h=Horn_Arm_T+2*c,$fn=36);
        translate([x0,Horn_Arm_L-Horn_Arm_W/2,0]) rotate([0,90,0])
            cylinder(d=Horn_Arm_W+2*c,h=Horn_Arm_T+2*c,$fn=36);
    }
}
module Canard_Horn_Envelope(){ Canard_Horn_Shape(0); }

// ============================================
// CANARD: root plug + blade, one print (part 10), local frame
// ============================================
// Planform in the (z, x) plane: z along the body axis, x radially out.
// The root line follows the skin (plus the gap) between root LE and TE.
function Canard_Root_X(z) = CN_Outer_R(Canard_Z+z) + Canard_Root_Gap;
module Canard_Planform2D(inset=0){
    zl = Canard_Pivot_From_LE; zt = zl-Canard_Root_C;
    zlt = zl-Canard_LE_Sweep; ztt = zlt-Canard_Tip_C;
    xt = Canard_Skin_R + Canard_Root_Gap + Canard_Span;
    offset(delta=-inset)
        polygon([[zt,Canard_Root_X(zt)],[zl,Canard_Root_X(zl)],[zlt,xt],[ztt,xt]]);
}
// 2D (u,v) extruded along w  ->  local (x=v, y=w, z=u)
module Canard_From2D() multmatrix([[0,1,0,0],[0,0,1,0],[1,0,0,0],[0,0,0,1]]) children();
module Canard_Blade(){
    // Bevelled flat plate: full thickness inside, 1 mm at the LE, TE and tip.
    hull(){
        Canard_From2D() translate([0,0,-Canard_T/2]) linear_extrude(height=Canard_T)
            Canard_Planform2D(Canard_Bevel*2);
        Canard_From2D() translate([0,0,-0.5]) linear_extrude(height=1)
            Canard_Planform2D(0);
    }
    // full-thickness root band, so the bevel does not thin the root
    Canard_From2D() translate([0,0,-Canard_T/2]) linear_extrude(height=Canard_T)
        intersection(){
            Canard_Planform2D(0);
            translate([-200,0]) square([400,Canard_Skin_R+Canard_Root_Gap+3]);
        }
}
module Canard_Plug_Screw_Cuts(x0, x1){
    // two M2 countersunk screws into the tapped arm
    for(r=Horn_Holes_R) translate([0,r,0]){
        translate([x0-Overlap,0,0]) rotate([0,90,0])
            cylinder(d=Plug_Screw_D,h=x1-x0+2*Overlap,$fn=24);
        translate([x1+Overlap,0,0]) rotate([0,-90,0])
            cylinder(d1=Plug_Screw_Head_D+2*Overlap,d2=Plug_Screw_D,
                     h=(Plug_Screw_Head_D-Plug_Screw_D)/2+Overlap,$fn=36);
    }
}
module Canard_Plug(){
    x0 = Plug_X0; x1 = Canard_Skin_R;
    difference(){
        union(){
            // plug; its outer face is the skin of revolution
            intersection(){
                translate([x0,0,0]) rotate([0,90,0]) cylinder(d=Plug_D,h=x1-x0+2,$fn=96);
                translate([0,0,-Canard_Z]) rotate_extrude($fn=360)
                    polygon(concat([[0,Canard_Z-20]],
                        [for(z=[Canard_Z-20:2:Canard_Z+20]) [CN_Outer_R(z),z]],
                        [[0,Canard_Z+20]]));
            }
            // neck: the blade section across the root gap, inside the plug
            intersection(){
                translate([x0,0,0]) rotate([0,90,0]) cylinder(d=Plug_D-1,h=20,$fn=96);
                translate([x1-1,-Canard_T/2,-Plug_D/2]) cube([Canard_Root_Gap+2,Canard_T,Plug_D]);
            }
        }
        // pocket: the plug sits over the arm and its hub, a close fit
        translate([-Overlap,0,0]) Canard_Horn_Shape(Plug_Pocket_Clear);
        Canard_Plug_Screw_Cuts(x0, x1);
        // stop slot: annular sector, open along the whole plug
        rotate([Stop_Tab_A,0,0]) translate([x0-1,0,0]) rotate([0,90,0])
            linear_extrude(height=x1-x0+1+Overlap) difference(){
                polygon(concat([[0,0]],
                    [for(a=[-Stop_Slot_Half:0.5:Stop_Slot_Half]) 20*[sin(a),cos(a)]]));
                circle(r=Stop_Tab_Rin-Stop_Slot_Clear,$fn=96);
            }
    }
}
module Canard_Unit(){ Canard_Plug(); Canard_Blade(); }   // local frame, neutral
// Print orientation: plug inner face on the bed, blade up. The blade's
// root ends beyond the plug need a little support.
module CN_Canard_Print(){
    translate([0,0,-Plug_X0]) rotate([0,-90,0]) Canard_Unit();
}

// ============================================
// CANARD SLICE (replaces part 2)
// ============================================
module Canard_Hole_Cut(){   // local frame
    difference(){
        translate([Canard_Skin_R-12,0,0]) rotate([0,90,0]) cylinder(r=Plug_Hole_R,h=20,$fn=96);
        // the stop tab stays
        rotate([Stop_Tab_A,0,0]) translate([0,Stop_Tab_Rin,-Stop_Tab_W/2]) cube([60,10,Stop_Tab_W]);
    }
}
module Canard_Hole_Ring(){  // local frame, fused to the inside of the shell
    intersection(){
        // teardrop outline, point down: the ring's underside stays at 45
        // deg so the slice prints wide-end-down without support under it
        // (point trimmed 1 mm above the cassette floor, which passes under it)
        intersection(){
            translate([30,0,0]) rotate([0,90,0]) hull(){
                cylinder(r=Plug_Hole_R+Hole_Ring_W,h=30,$fn=96);
                translate([(Plug_Hole_R+Hole_Ring_W)*sqrt(2),0,0]) cylinder(r=0.2,h=30,$fn=8);
            }
            translate([0,-50,Cas_Floor_Top+1-Canard_Z]) cube([100,100,100]);
        }
        // a band from Hole_Ring_T inside the bore out to just under the skin
        translate([0,0,-Canard_Z]) rotate_extrude($fn=360)
            polygon(concat(
                [for(z=[Canard_Z-25:2:Canard_Z+25]) [CN_Inner_R(z)-Hole_Ring_T,z]],
                [for(z=[Canard_Z+25:-2:Canard_Z-25]) [CN_Outer_R(z)-0.3,z]]));
    }
}
module Countersunk_Radial(a, z){
    r = CN_Outer_R(z);
    Radial_At(a, r+1, z) cylinder(d=Bay_M3_Clearance, h=8, $fn=36);
    Radial_At(a, r+Overlap, z)
        cylinder(d1=Bay_Joint_Head_D+2*Overlap, d2=Bay_M3_Clearance,
                 h=(Bay_Joint_Head_D-Bay_M3_Clearance)/2+Overlap, $fn=60);
}
module CN_Canard_Slice(){
    difference(){
        union(){
            CN_Cone(Cut_d=Cut1_d, Lower=true);
            for(k=[0:3]) Canard_Frame(k) Canard_Hole_Ring();
            Canard_Switch_Add();
        }
        for(k=[0:3]) Canard_Frame(k) Canard_Hole_Cut();
        Canard_Switch_Cut();
        for(a=Sh_Joint_A) Radial_At(a, CN_Outer_R(Sh_Joint_Z)+1, Sh_Joint_Z)
            cylinder(d=Bay_M3_Clearance, h=8, $fn=36);
        for(a=Cas_Screw_A) Countersunk_Radial(Canard_A0+a, Cas_Screw_Z);
        for(a=Cas_Screw_A) Countersunk_Radial(Canard_A0+a, Roof_Screw_Z);
    }
}

// ============================================
// SERVO CASSETTE (part 9), assembled position; prints floor-down
// ============================================
module Cas_Cradle(){   // local frame of one servo
    b = Servo_Bottom_R; zt = Cas_Top_Z-Canard_Z; zf = Cas_Floor_Top-Canard_Z;
    yw = Servo_W/2+Cas_Clear;
    xt = b+Servo_Case_H;
    xb = b+Servo_Lug_Hole_X-Lug_Access_D/2-1;     // lug blocks start here
    zl = -Servo_Spline_Off-Cas_Clear;             // case ends (+clearance)
    zu = Servo_L-Servo_Spline_Off+Cas_Clear;
    // side walls; they start at the channel edge so neighbours' walls merge
    // (solid: the cell sleeves are fused to their outer faces)
    Cas_Walls(zf-Overlap, zt-zf+Overlap);
    // lug blocks beside the lug plates, beyond both case ends
    translate([xb,Cas_Lug_Y0,zf-Overlap]) cube([xt-xb,yw+Cas_Wall-Cas_Lug_Y0,zl-zf+Overlap]);
    // upper block: a ~4 mm ledge off the +y wall over the case end
    translate([xb,Cas_Lug_Y0,zu]) cube([xt-xb,yw+Cas_Wall-Cas_Lug_Y0,zt-zu]);
}
module Cas_Walls(z0, h){   // local frame (z relative to Canard_Z)
    yw = Servo_W/2+Cas_Clear; xt = Servo_Bottom_R+Servo_Case_H;
    for(s=[-1,1]) translate([yw, s>0 ? yw : -yw-Cas_Wall, z0]) cube([xt-yw, Cas_Wall, h]);
}
module Canard_Rot(k) rotate([0,0,Canard_A0+90*k]) children();   // canard frame, Z absolute

// Cell sleeves: a Ø22.7 tube per quadrant on the floor, fused to both
// neighbouring cradle walls, plus a web out to the quadrant screw boss.
module Cell_Sleeves_Add(rf){
    for(a=Cell_A) rotate([0,0,a]){
        translate([Cell_R,0,Cas_Floor_Top-Overlap])
            cylinder(d=Cell_Sleeve_OD,h=Cas_Top_Z-Cas_Floor_Top+Overlap,$fn=96);
        translate([Cell_R,-3,Cas_Floor_Top-Overlap])
            cube([rf-Cas_Boss_L+0.5-Cell_R,6,Cas_Floor_Z+Cas_Boss_D-Cas_Floor_Top+Overlap]);
    }
    // keeper insert bosses, against the outer face of each -y cradle wall
    for(k=[0:3]) Canard_Rot(k) translate([Keeper_Fix[0],Keeper_Fix[1],Cas_Floor_Top-Overlap])
        cylinder(d=Keeper_Boss_D,h=Keeper_Boss_Top_Z-Cas_Floor_Top+Overlap,$fn=48);
}
module Cell_Sleeves_Cut(){
    for(a=Cell_A) rotate([0,0,a]){
        // bore, through the floor: the cell hangs below it onto the keeper
        translate([Cell_R,0,Cas_Floor_Z-1]) cylinder(d=Cell_Bore_D,h=Cas_Top_Z-Cas_Floor_Z+2,$fn=96);
        // full-height tab/lead slot toward the axis, through the wall arc only
        translate([Cell_R-Cell_Sleeve_OD/2-0.1,-Cell_Slot_W/2,Cas_Floor_Top-Overlap])
            cube([Cell_Sleeve_OD/2+0.1,Cell_Slot_W,Cas_Top_Z-Cas_Floor_Top+1]);
    }
    // floor notch toward the axis, under the lead channel between the two
    // cradle walls; the floor under the walls stays, so nothing overhangs
    difference(){
        for(a=Cell_A) rotate([0,0,a])
            translate([Cell_R-Cell_Bore_D/2-Cell_Notch[1],-Cell_Notch[0]/2,Cas_Floor_Z-1])
                cube([Cell_Notch[1]+1,Cell_Notch[0],Cas_Floor_T+2]);
        for(k=[0:3]) Canard_Rot(k) Cas_Walls(Cas_Floor_Z-2, Cas_Floor_T+4);
    }
    for(k=[0:3]) Canard_Rot(k){
        // keeper inserts, set from below
        translate([Keeper_Fix[0],Keeper_Fix[1],Cas_Floor_Z-Overlap])
            cylinder(d=Insert_Hole_D,h=Insert_Pocket_L+Overlap,$fn=36);
        for(p=Cell_Tie_XY) translate([p[0],p[1],Cas_Floor_Z-1]) cylinder(d=Cell_Tie_D,h=Cas_Floor_T+2,$fn=24);
    }
}
module Cas_Lug_Cuts(){   // local frame
    b = Servo_Bottom_R; yw = Servo_W/2+Cas_Clear;
    for(z=Lug_Hole_Zs()) translate([b+Servo_Lug_Hole_X,0,z]){
        rotate([-90,0,0]) cylinder(d=Lug_Bolt_D,h=yw+Cas_Wall+1,$fn=24);
        // nut trap in the far face
        translate([0,yw+Cas_Wall-Lug_Nut_T-0.4,0]) rotate([-90,0,0])
            cylinder(d=(Lug_Nut_AF+0.2)/cos(30),h=Lug_Nut_T+1,$fn=6);
        // driver and head access through the near wall
        translate([0,-Servo_Lug_T/2-Overlap,0]) rotate([90,0,0])
            cylinder(d=Lug_Access_D,h=yw+Cas_Wall+1,$fn=36);
    }
}
module CN_Canard_Cassette(){
    rf = CN_Inner_R(Cas_Floor_Z+Cas_Boss_D) - Cas_Clear;   // bore narrows upward
    difference(){
        union(){
            translate([0,0,Cas_Floor_Z]) cylinder(r=rf,h=Cas_Floor_T,$fn=180);
            for(k=[0:3]) Canard_Frame(k) Cas_Cradle();
            // screw bosses, standing on the floor
            for(a=Cas_Screw_A) intersection(){
                Radial_At(Canard_A0+a, rf, Cas_Screw_Z) translate([0,0,-Overlap])
                    hull(){ cylinder(d=Cas_Boss_D,h=Cas_Boss_L,$fn=48);
                            translate([-Cas_Boss_D/2,-Cas_Boss_D/2,0]) cube([Cas_Boss_D/2,Cas_Boss_D,Cas_Boss_L]); }
                translate([0,0,Cas_Floor_Z]) cylinder(r=rf,h=Cas_Boss_D+3,$fn=180);
            }
            Cell_Sleeves_Add(rf);
        }
        for(k=[0:3]) Canard_Frame(k) Cas_Lug_Cuts();
        Cell_Sleeves_Cut();
        // the four leads drop down the central channel through one hole
        rotate([0,0,Canard_A0]) translate([-Cas_Lead_Hole/2,-Cas_Lead_Hole/2,Cas_Floor_Z-1])
            cube([Cas_Lead_Hole,Cas_Lead_Hole,Cas_Floor_T+2]);
        for(a=Cas_Screw_A) Radial_Insert_Pocket(Canard_A0+a, rf, Cas_Screw_Z);
    }
}

// ============================================
// CELL KEEPER (part 19), assembled position; prints plate-down
// ============================================
module CN_Cell_Keeper(){
    difference(){
        union(){
            translate([0,0,Keeper_Z0]) cylinder(r=Keeper_R,h=Keeper_T,$fn=180);
            // seat rings on the cells' insulated bottom rims
            for(a=Cell_A) rotate([0,0,a]) translate([Cell_R,0,Keeper_Top_Z-Overlap])
                cylinder(d=Keeper_Ring[1],h=Cell_End_Relief+Overlap,$fn=96);
            // columns up to the cassette floor
            for(k=[0:3]) Canard_Rot(k) translate([Keeper_Fix[0],Keeper_Fix[1],Keeper_Top_Z-Overlap])
                cylinder(d=Keeper_Col_D,h=Cas_Floor_Z-Keeper_Top_Z+Overlap,$fn=48);
        }
        translate([0,0,Keeper_Z0-1]) cylinder(d=Keeper_Lead_D,h=Keeper_T+2,$fn=48);
        for(a=Cell_A) rotate([0,0,a]){
            // end window for the tab and solder joint, and its lead slot
            translate([Cell_R,0,Keeper_Z0-1]) cylinder(d=Keeper_Ring[0],h=Keeper_T+Cell_End_Relief+2,$fn=72);
            translate([Cell_R-Keeper_Ring[1]/2-1,-Cell_Slot_W/2,Keeper_Z0-1])
                cube([Keeper_Ring[1]/2+1,Cell_Slot_W,Keeper_T+Cell_End_Relief+2]);
        }
        // M3 countersunk, flush with the plate's underside
        for(k=[0:3]) Canard_Rot(k) translate([Keeper_Fix[0],Keeper_Fix[1],Keeper_Z0]){
            translate([0,0,-1]) cylinder(d=Bay_M3_Clearance,h=Cas_Floor_Z-Keeper_Z0+2,$fn=36);
            translate([0,0,-Overlap]) cylinder(d1=Bay_Charge_Head_D+2*Overlap,d2=Bay_M3_Clearance,
                h=(Bay_Charge_Head_D-Bay_M3_Clearance)/2+Overlap,$fn=60);
        }
    }
}
// Cells, with their top pads, for checks and the assembly view
module CN_Cell_Envelopes(){
    for(a=Cell_A) rotate([0,0,a]) translate([Cell_R,0,0]){
        translate([0,0,Cell_Bottom_Z]) cylinder(d=Cell_D,h=Cell_Body_L,$fn=72);
        translate([0,0,Cell_Top_Z]) difference(){
            cylinder(d=Cell_Pad[0],h=Cell_Top_Pad_T,$fn=72);
            translate([0,0,-1]) cylinder(d=Cell_Pad[1],h=Cell_Top_Pad_T+2,$fn=72);
            translate([-Cell_Pad[0],-Cell_Slot_W/2,-1]) cube([Cell_Pad[0],Cell_Slot_W,Cell_Top_Pad_T+2]);
        }
    }
}
// Keeper screws M3x20 countersunk (head flush in the plate), for checks
module CN_Keeper_Screws(){
    for(k=[0:3]) Canard_Rot(k) translate([Keeper_Fix[0],Keeper_Fix[1],Keeper_Z0]){
        cylinder(d1=Bay_Charge_Head_D-0.2,d2=2.9,h=(Bay_Charge_Head_D-0.2-2.9)/2,$fn=36);
        cylinder(d=2.9,h=Keeper_Screw_L,$fn=36);
    }
}

// ============================================
// SERVO SWITCH on slice 02 (drilled) and its saddle (part 12)
// ============================================
// Local XY is the bezel's seating plane, local +Z points into the nose.
module Ssw_Frame(){
    rotate([0,0,Ssw_A-90]) translate([0,Ssw_Face_R,Ssw_Z]) rotate([90,0,0]) children();
}
module Ssw_Hole_Cut(h=30){   // Ø12.7 + R1.2 key relief (13.6 overall), as the camera switch
    translate([0,0,-h/2]) cylinder(d=Bay_Switch_Hole_D,h=h,$fn=120);
    translate([0,6.05,-h/2]) cylinder(r=1.2,h=h,$fn=48);
}
// Glued inside the shell; its flat back carries the nut. Print flat back down.
module CN_Ssw_Saddle(){
    difference(){
        intersection(){
            Ssw_Frame() Bay_Panel(22,22,Ssw_Panel_T);
            rotate_extrude($fn=360) polygon(concat([[0,Ssw_Z-20]],
                [for(z=[Ssw_Z-20:2:Ssw_Z+20]) [CN_Inner_R(z)-Ssw_Glue,z]],
                [[0,Ssw_Z+20]]));
        }
        Ssw_Frame() Ssw_Hole_Cut();
    }
}
// Bezel in front, thread through the panel, Ø16 rear envelope behind it
module CN_Ssw_Envelope(){
    Ssw_Frame(){
        translate([0,0,-Ssw_Bezel[1]]) cylinder(d=Ssw_Bezel[0],h=Ssw_Bezel[1],$fn=72);
        cylinder(d=Ssw_Thread_D,h=Ssw_Panel_T+Overlap,$fn=72);
        translate([0,0,Ssw_Panel_T]) cylinder(d=Ssw_Body[0],h=Ssw_Body[1]-Ssw_Panel_T,$fn=72);
    }
}
// Slice 02 as drilled by hand for the servo switch (checks only; the
// printed part and its STL keep the source geometry)
module CN_Slice_Drilled(){ difference(){ CN_Canard_Slice(); Ssw_Frame() Ssw_Hole_Cut(); } }

// ============================================
// SHOULDER ADDITIONS (shoulder coordinates: assembled Z + Shoulder_L)
// ============================================
module Canard_Shoulder_Add(){
    zs = Shoulder_L + Sh_Joint_Z;
    rin = Sh_Spigot_R - NC_Wall_T;
    // insert bosses inside the spigot, gusseted down into the shoulder wall
    for(a=Sh_Joint_A) intersection(){
        hull(){
            Radial_At(a, Sh_Spigot_R-0.3, zs) cylinder(d=Sh_Boss_D,h=Sh_Boss_L,$fn=48);
            Radial_At(a, Shoulder_Bore_D/2+0.6, zs-Sh_Boss_D/2-(Sh_Boss_L-NC_Wall_T)*1.4)
                cylinder(d=2,h=1.2,$fn=24);
        }
        translate([0,0,zs-40]) cylinder(r=Sh_Spigot_R-0.3,h=40+Sh_Boss_D/2+1,$fn=180);
    }
    // thicker bulkhead (inside), for the charge well, posts and facing disc
    translate([0,0,Shoulder_Bulk_T-Overlap]) cylinder(d=Shoulder_Bore_D+0.2,h=Bulk_Add_T+Overlap,$fn=180);
    // index key under the shell base, in the tube wall's annulus
    if (Index_Key_Enabled) rotate([0,0,Index_Key_A]) intersection(){
        translate([Shoulder_OD/2-1,-Index_Key_W/2,Shoulder_L-Index_Key_H]) cube([Peregrine_Body_OD/2-Shoulder_OD/2+0.7,Index_Key_W,Index_Key_H]);
        // 45-deg lead at the bottom so it prints and finds the notch
        // (inner edge kept inside the shoulder wall, off the spigot radius)
        rotate_extrude($fn=360) polygon([[Shoulder_OD/2-0.5,Shoulder_L-Index_Key_H],
            [Shoulder_OD/2,Shoulder_L-Index_Key_H],
            [Peregrine_Body_OD/2-0.3,Shoulder_L-Index_Key_H+(Peregrine_Body_OD/2-0.3-Shoulder_OD/2)],
            [Peregrine_Body_OD/2-0.3,Shoulder_L],[Shoulder_OD/2-0.5,Shoulder_L]]);
    }
}
module Canard_Shoulder_Cut(){
    zs = Shoulder_L + Sh_Joint_Z;
    bt = Shoulder_Bulk_T + Bulk_Add_T;
    for(a=Sh_Joint_A) Radial_Insert_Pocket(a, Sh_Spigot_R, zs);
    // ribbon T-slots, re-cut through the thicker bulkhead (same shape as plain)
    for (s=[-1,1]) translate([0, s*(Shoulder_Bore_D/2-4), -Overlap]){
        RoundRect(X=16, Y=4, Z=bt+1, R=1.5);
        translate([0, -s*(2+Ribbon_Guide_L)/2, 0])
            RoundRect(X=Ribbon_Guide_W, Y=2+Ribbon_Guide_L, Z=bt+1, R=Ribbon_Guide_W/2-0.01);
    }
    // M3 brass terminal posts (RTV-sealed) and the charge-well bolts
    for(p=Term_XY) translate([p[0],p[1],-Overlap]) cylinder(d=Term_D,h=bt+2*Overlap,$fn=24);
    for(s=[-1,1]) translate([Charge_XY[0],Charge_XY[1]+s*Charge_Bolt_Sp/2,-Overlap])
        cylinder(d=Bay_M3_Clearance,h=bt+2*Overlap,$fn=24);
}

// ============================================
// VEGA, MAST UNIT (part 14, print roof-down), SHELL FEATURES
// ============================================
module Local1() rotate([0,0,Canard_A0]) children();    // x = u (15 deg), y = n (105 deg)
module Vega_Frame() Local1()
    multmatrix([[0,-1,0,Vega_U],[0,0,1,Vega_N],[-1,0,0,Vega_Z_Mid],[0,0,0,1]]) children();
function box_of(r) = [r[0][0],r[1][0],r[2][0]];
function size_of(r) = [r[0][1]-r[0][0],r[1][1]-r[1][0],r[2][1]-r[2][0]];
module Vega_Envelope(){   // STEP frame
    b = Vega_Board;
    translate([-b[0]/2,-b[1]/2,-b[2]]) cube(b);
    translate([-b[0]/2,-b[1]/2,0]) cube([b[0],b[1],Vega_Top_H]);
    difference(){
        translate([-b[0]/2,-b[1]/2,-Vega_Bot_H]) cube([b[0],b[1],Vega_Bot_H-b[2]+Overlap]);
        for(h=Vega_Holes) translate([h[0],h[1],-Vega_Bot_H-1]) cylinder(d=Vega_Standoff_D+1,h=Vega_Bot_H+1,$fn=36);
    }
    translate(box_of(Vega_SMA)) cube(size_of(Vega_SMA));
}
module CN_Vega_Envelope(){ Vega_Frame() Vega_Envelope(); }

module Roof_Plan(h){
    difference(){
        cylinder(r=Roof_R,h=h,$fn=180);
        Local1() translate([Roof_Pass[0],Roof_Pass[1],-Overlap]) cylinder(d=Roof_Pass[2],h=h+2*Overlap,$fn=36);
    }
}
// Open-top pocket for the 2S LiPo stack, centred on the origin: floor at
// -In.z/2, walls up to +In.z/2+Wall, lead slot over the rim along u, push-up
// hole in the floor, lightening windows in the faces and sides.
module Vega_LiPo_Pocket(){
    i = LiPo_In;  o = LiPo_Out;  w = LiPo_Wall;
    difference(){
        cube(o, center=true);
        translate([0,0,w+Overlap]) cube(i+[0,0,2*w], center=true);
        translate([0,0,i[2]/2+2]) rotate([0,90,0]) cylinder(d=7,h=o[0]+2*Overlap,center=true,$fn=36);
        translate([0,0,-o[2]/2-Overlap]) cylinder(d=5,h=w+2*Overlap,$fn=36);
        hull() for(z=[-1,1]) translate([0,0,z*(i[2]/2-9)]) rotate([90,0,0])
            cylinder(d=14,h=o[1]+2*Overlap,center=true,$fn=36);
        hull() for(z=[-1,1]) translate([0,0,z*(i[2]/2-8)]) rotate([0,90,0])
            cylinder(d=i[1]-2,h=o[0]+2*Overlap,center=true,$fn=36);
    }
}
module Mast_Local(){   // local u/n frame, Z absolute
    zf = Roof_Z0+Roof_T-Overlap;
    yf = Mast_Front_N;
    fw = Vega_U + 15 - Mast_U0;          // flange width
    d  = LiPo_Out[1];                    // channel depth behind the flange
    // flange behind the board
    translate([Mast_U0, yf-Mast_T, zf]) cube([fw, Mast_T, Mast_Top_Z-zf]);
    // two webs either side of the LiPo pocket: a channel section
    for(s=[-1,1]) translate([LiPo_U+s*(LiPo_Out[0]+Mast_T)/2-Mast_T/2, yf-Mast_T-d, zf])
        cube([Mast_T, d+Overlap, Mast_Top_Z-zf]);
    // LiPo pocket on the back of the flange
    translate([LiPo_U, yf-Mast_T-d/2+Overlap, LiPo_Z]) Vega_LiPo_Pocket();
    // 45-deg gussets at the foot, front and back
    hull(){
        translate([Mast_U0, yf-Mast_T-d, zf]) cube([fw, d+Mast_T+12, Overlap]);
        translate([Mast_U0, yf-Mast_T, zf+12]) cube([fw, Mast_T, Overlap]);
    }
}
module CN_Vega_Mast(){
    difference(){
        union(){
            translate([0,0,Roof_Z0]) Roof_Plan(Roof_T);
            // rim band with the foam groove
            translate([0,0,Roof_Z0]) difference(){
                cylinder(r=Roof_R,h=Roof_Rim_H,$fn=180);
                translate([0,0,-Overlap]) cylinder(r=Roof_R-3,h=Roof_Rim_H+2*Overlap,$fn=180);
            }
            // radial screw bosses to the shell, between the canards
            for(k=[0:3]) intersection(){
                Radial_At(Canard_A0+45+90*k, CN_Inner_R(Roof_Screw_Z)-0.3, Roof_Screw_Z) translate([0,0,-Overlap])
                    hull(){ cylinder(d=Cas_Boss_D,h=Cas_Boss_L,$fn=48);
                            translate([-Cas_Boss_D/2,-Cas_Boss_D/2,0]) cube([Cas_Boss_D/2,Cas_Boss_D,Cas_Boss_L]); }
                translate([0,0,Roof_Z0]) cylinder(r=CN_Inner_R(Roof_Screw_Z)-0.3,h=Cas_Boss_D+2,$fn=180);
            }
            Local1() Mast_Local();
            // Vega standoffs: short Ø8 columns fused into the flange (the
            // board's underside parts leave only a Ø9 keep-out round each hole)
            Vega_Frame() for(h=Vega_Holes) translate([h[0],h[1],-Vega_Board[2]]) mirror([0,0,1])
                cylinder(d=Vega_Standoff_D,h=Vega_Bot_H-Vega_Board[2]+0.5+Mast_T/2,$fn=48);
            // capacitor cup
            rotate([0,0,Cap_A]) translate([Cap_R,0,Roof_Z0+Roof_T-Overlap]) cylinder(d=Cap_D+0.6+3.2,h=10,$fn=48);
        }
        // foam groove
        translate([0,0,Roof_Z0+(Roof_Rim_H-Foam_Groove[0])/2]) difference(){
            cylinder(r=Roof_R+1,h=Foam_Groove[0],$fn=180);
            cylinder(r=Roof_R-Foam_Groove[1],h=Foam_Groove[0],$fn=180);
        }
        Local1() translate([Roof_Pass[0],Roof_Pass[1],Roof_Z0-1]) cylinder(d=Roof_Pass[2],h=Roof_Rim_H+2,$fn=36);
        for(k=[0:3]) Radial_Insert_Pocket(Canard_A0+45+90*k, CN_Inner_R(Roof_Screw_Z)-0.3, Roof_Screw_Z);
        Vega_Frame() for(h=Vega_Holes) translate([h[0],h[1],-Vega_Board[2]+Overlap]) mirror([0,0,1]){
            cylinder(d=Insert_Hole_D,h=Insert_Pocket_L,$fn=36);
            cylinder(d=Bay_M3_Clearance,h=Insert_Pocket_L+Bay_Screw_Tip_L,$fn=36);
        }
        rotate([0,0,Cap_A]) translate([Cap_R,0,Roof_Z0+Roof_T]) cylinder(d=Cap_D+0.6,h=11,$fn=48);
    }
}

// Second Schurter switch on slice 02, same keyed cut and flat pad as the camera's
module Vsw_Frame(){
    rotate([0,0,Vsw_A-90]) translate([0,CN_Outer_R(Vsw_Z-11)+0.8,Vsw_Z]) rotate([90,0,0]) children();
}
module Canard_Switch_Add(){ Vsw_Frame() Bay_Panel(22,22,Bay_Switch_Panel_T); }
module Canard_Switch_Cut(){
    Vsw_Frame(){
        translate([0,0,-Overlap]) cylinder(d=Bay_Switch_Hole_D,h=Bay_Switch_Panel_T+2*Overlap,$fn=120);
        translate([0,6.05,-Overlap]) cylinder(r=1.2,h=Bay_Switch_Panel_T+2*Overlap,$fn=48);
    }
}
// Schurter rear envelope (Ø16 x 23.5 behind the panel face) for checks
module CN_Vsw_Envelope(){ Vsw_Frame() cylinder(d=16,h=23.5,$fn=48); }

// Slice 03 cuts (only with canards): static ports and the USB window
module Canard_Middle_Cuts(){
    for(k=[0:3]) Radial_At(Canard_A0+45+90*k, CN_Outer_R(Port_Z)+1, Port_Z)
        cylinder(d=Port_D,h=NC_Wall_T+6,$fn=24);
    // USB-C: the window sits on the connector's axis (parallel to -u)
    Local1() translate([-60, Vega_N+1.15-USB_Win[1]/2, Vega_Z_Mid-10.4-USB_Win[0]/2])
        cube([60-abs(Vega_U)-Vega_Board[1]/2-3, USB_Win[1], USB_Win[0]]);
}
// Part 06 (camera-bay floor): one potted pass for the servo supply
module Canard_Floor_Pass(){
    translate([Floor_Pass_XY[0],Floor_Pass_XY[1],Bay_Floor_Z-1]) cylinder(d=Floor_Pass_D,h=Bay_Floor_T+2,$fn=24);
}

// ============================================
// SHOULDER-JOINT TEST COUPON (parts 16, 17) and FACING DISC (part 18)
// ============================================
Coupon_Slice_H = 30;  Coupon_Shoulder_H = 35;
module CN_Coupon_Slice(){ intersection(){ CN_Canard_Slice(); translate([0,0,-1]) cylinder(d=120,h=Coupon_Slice_H+1); } }
module CN_Coupon_Shoulder(){
    intersection(){ CN_Shoulder(); translate([0,0,Shoulder_L+Shoulder_Spigot_L-Coupon_Shoulder_H]) cylinder(d=120,h=Coupon_Shoulder_H+1); }
}
module CN_Facing_Disc_2D(){
    difference(){
        circle(d=Facing_D-0.4,$fn=180);
        for (s=[-1,1]) translate([0, s*(Shoulder_Bore_D/2-4)]){
            offset(r=1.5) square([16-3,4-3],center=true);
            translate([0,-s*(2+Ribbon_Guide_L)/2]) square([Ribbon_Guide_W,2+Ribbon_Guide_L],center=true);
        }
        for(p=Term_XY) translate(p) circle(d=Term_D+3,$fn=24);   // insulating clearance
        for(s=[-1,1]) translate([Charge_XY[0],Charge_XY[1]+s*Charge_Bolt_Sp/2]) circle(d=Bay_M3_Clearance,$fn=24);
    }
}
module CN_Charge_Well(){ rotate([0,0,90]) ChargeHolder(CH_BoltSp=0, Dia=Charge_Dia, CC=Charge_CC); }

// ============================================
// ASSEMBLY VIEW (part 11) and check envelopes
// ============================================
Canard_View_Defl = 0;
module CN_Canard_Units(defl=Canard_View_Defl){
    for(k=[0:3]) Canard_Frame(k) rotate([defl,0,0]) Canard_Unit();
}
module CN_Canard_Servos(){ for(k=[0:3]) Canard_Frame(k) Canard_Servo_Envelope(); }
module CN_Canard_Horns(){ for(k=[0:3]) Canard_Frame(k) Canard_Horn_Envelope(); }
module CN_Canard_Assembly(){
    color([0.78,0.79,0.81,0.5]) difference(){
        CN_Canard_Slice();
        rotate([0,0,Canard_A0+45]) translate([-100,-100,-1]) cube([100,200,200]);
    }
    color([0.95,0.62,0.18]) CN_Canard_Cassette();
    color([0.2,0.45,0.95]) CN_Cell_Envelopes();
    color([0.85,0.3,0.3]) CN_Cell_Keeper();
    color([0.85,0.3,0.3]) CN_Ssw_Saddle();
    color([0.15,0.15,0.15]) CN_Ssw_Envelope();
    color([0.3,0.7,0.4]) CN_Vega_Mast();
    color([0.1,0.35,0.2]) CN_Vega_Envelope();
    color([0.2,0.2,0.25]) CN_Canard_Servos();
    color([0.6,0.6,0.65]) CN_Canard_Horns();
    color([0.15,0.45,0.85]) CN_Canard_Units();
    color([0.78,0.79,0.81,0.5]) difference(){
        translate([0,0,-Shoulder_L]) CN_Shoulder();
        rotate([0,0,Canard_A0+45]) translate([-100,-100,-120]) cube([100,200,200]);
    }
}
