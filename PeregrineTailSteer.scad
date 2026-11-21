// ***********************************
// Project: 3D Printed Rocket
// Filename: PeregrineTailSteer.scad
// by Tõnu Samuel
// Created: 11/21/2026
// Revision: 0.2.0  11/21/2026
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Tail steering for the Apogee Peregrine and the Apogee Zephyr (camera nose,
// CATS Vega): a printed PC fin can that replaces the aft 220 mm of the aft
// body tube. Each of the
// three fixed plywood fins carries a trailing-edge aileron. The aileron hangs
// on a 4 mm steel shaft that runs radially into the can in two NSK 684AZZ
// shielded bearings (4 x 9 x 4); the aileron is two halves clamped round the
// shaft. Inside the can a printed clevis crank on the shaft is driven by an
// axial M2 pushrod from an MKS HV6160 servo lying flat in the
// annulus between the motor mount and the wall. All three servos share one
// signal from the Vega; power is a 2S LiPo in the can. Servos and LiPo are
// reached through hatches.
//
// Why ailerons on the tail: the CFD study (MyLevel1Peregrine cfd/REPORT.md)
// shows the fins straighten the canard swirl and return 1.2-1.4x the canard
// roll moment, so canard roll control reverses. Surfaces at the tail have
// nothing downstream. The fixed fin keeps passive stability if a servo fails.
//
// Frame: Z = 0 at the aft end of the body (the base), +Z forward. Fins at
// 0/120/240 deg, rail buttons at 60 deg (PeregrineL2.ork). In a fin's own
// frame the fin points along +X; Fin coordinates (x_f, y_f) are those of the
// .ork freeform outline: x_f aft from the root leading edge, y_f out from the
// body surface. Z = Fin_Base_X - x_f, X = R_Out + y_f.
//
// The thrust path is motor -> thrust ring -> 38 mm motor tube -> fin tabs and
// hinge pillars (epoxy) -> can -> shoulder -> paper tube. The bearings carry
// only aileron loads.
//
//  ***** History *****
// 0.1.0  11/21/2026  First design.
// 0.1.1  11/21/2026  Review: ailerons clipped Skid_Margin ahead of the fixed fin's aft-most
//                    point (Zephyr); set-screw pocket assert against the arm and stud hole.
// 0.1.2  11/21/2026  Review 2: field-serviceable hinge with the fins glued (54 mm shaft
//                    that slides out into the cut-out, aileron split in two clamped
//                    halves); clevis crank on a Ø2 dowel, standing on the print bed;
//                    hinge pillars fused to the web.
// 0.1.3  11/21/2026  Review 3: M2x5 aileron clamp screws (M2x6 bottomed out); hatch
//                    fin-side edge at u 33.5 with a 2 mm rebate, clear of a 10 mm root fillet.
// 0.1.4  11/21/2026  Review 4: aileron drive line-to-line with a clamp relief and a Ø2
//                    dowel through the shaft; horn ball 3.95 off the arm (M2x10 12.9,
//                    0.3 shim); crank arm 14 mm (servo 59 deg, link 1.75); AeroPack RA38L
//                    retainer keep-out; hatch fin-side rebate 3 mm.
// 0.1.5  11/21/2026  Review 5: split-face relief only round the shaft, clamp screws over
//                    the shaft or solid contact; shaft 0.6 further in, D-bore 1.5 past
//                    its end; shaft drill jig; horn radius 9 (nut clears the case).
// 0.1.6  11/21/2026  Review 6 nits: inner clevis cheek spot-faced to Cheek_T at the
//                    pivot (bore 10.2 for the Ø2 x 10 dowel); horn stack derived from
//                    Horn_Arm_T/Ball_D/Horn_Shim; TS_CRANK echo for the estimate.
// 0.2.0  11/21/2026  Airframe = "Peregrine" | "Zephyr": the Zephyr Mach 0.8 build from new
//                    (carbon fins, +-5 deg, link 2.0, 24 in motor tube); Peregrine unchanged.
//
// ***********************************
//  ***** for STL output *****
// Render_Part = 1;  // fin can (PC, aft end down, no supports)
// Render_Part = 2;  // servo hatch cover (sectors B and C)
// Render_Part = 3;  // servo + LiPo hatch cover (sector A, at the rail)
// Render_Part = 4;  // crank, print hub-up
// Render_Part = 5;  // aileron screw half (-Y), print on its outer face
// Render_Part = 8;  // aileron tapped half (+Y), print on its outer face
// Render_Part = 6;  // bearing-fit coupon (one hinge block)
// Render_Part = 7;  // fixed fin 2D outline for laser/CNC cutting (DXF)
// Render_Part = 9;  // shaft drill jig (dowel cross hole), print as is
// ***********************************

$fn = $preview ? 48 : 96;
Overlap = 0.05;

// ============================================
// AIRFRAME (PeregrineFinCan.scad v0.5.0 test-print values; .ork 101.6/99.06)
// ============================================
// The Apogee Peregrine and Zephyr (kit 04997) share their aft section: the
// same AT-98/18 slotted tube, AT-38/11 motor tube 12.7 mm inside the tube end,
// plywood rings at 25.4 and 155.575 mm and rail buttons at 104.775 and
// 403.225 mm from the aft tube's front (PeregrineL2-CamNose.ork and Apogee's
// Zephyr.rkt agree to the 0.001 mm). Airframe = "Zephyr" is a Mach 0.8 build
// from the kit: its own fins (FinZ_Pts), +-5 deg aileron travel, a 2.0 link
// ratio (crank 16, horn 8, so the servo angle and the can differ) and a 24 in
// motor tube. Airframe = "Peregrine" leaves every Peregrine part as it was.
Airframe  = "Peregrine";    // "Peregrine" or "Zephyr"
assert(Airframe == "Peregrine" || Airframe == "Zephyr", "Airframe must be Peregrine or Zephyr");
Body_OD   = 101.5;          // measured kit tube OD
Body_ID   = 99.0;           // measured kit tube ID
R_Out     = Body_OD/2;
Wall      = 2.4;            // 6 perimeters (L2-PrintSettings.md)
R_In      = R_Out - Wall;
MMT_OD    = 41.53;          // Apogee 38 mm motor tube (.ork 0.0207645 m radius)
// Peregrine: 11 in, kit length (.ork). Zephyr: 24 in, for 38/1080 J motors up to 584 mm
MMT_L     = Airframe == "Zephyr" ? 609.6 : 279.4;
MMT_Z0    = 12.7;           // aft end above the base (.ork: bottom -0.0127)
Glue_Gap  = 0.2;            // radial epoxy gap at every MMT contact
MMT_Bore_R = MMT_OD/2 + Glue_Gap;
// Motor retainer: AeroPack RA38L (Apogee 24062) for 1.630 in (41.4 mm) paper
// tubes: OD 1.969 in (50.0 mm), 0.5 in (12.7 mm) long, needs >= 3/8 in of tube
// exposed. Keep-out: its OD + 1 mm radial, from the base to 1 mm past the body
// on the tube (tube end + 12.7). The cap sits aft of the tube end.
Retainer_D = 50.0 + 2;
Retainer_H = MMT_Z0 + 12.7 + 1;

Can_L      = 220;           // full-OD body of the can
Shoulder_L = 30;            // spigot into the paper tube
Shoulder_OD = Body_ID - 0.6;
Shoulder_Wall = 2.4;
Total_H    = Can_L + Shoulder_L;
Aft_Tube_L = 457.2;         // .ork aft body tube
Tube_Piece_L = Aft_Tube_L - Can_L;   // kept from the flown aft tube
Ply_CR_Z0  = Total_H + 1;   // kit plywood centering ring (eyebolt, gas seal)
Ply_CR_T   = 6.35;

Rail_A     = 60;
Rail_Aft_Z = 457.2 - 403.225;   // .ork aft rail button, 53.975 above the base
Fin_A      = [0, 120, 240];

// ============================================
// FIN OUTLINE (.ork freeform points, mm; x aft from root LE, y out)
// ============================================
Fin_Set = Airframe;         // "Peregrine" or "Zephyr"
FinP_Pts = [[0,0],[50.8,41.91],[93.98,76.2],[127.0,95.25],[152.4,105.41],
            [177.8,111.76],[203.2,114.3],[228.6,112.776],[254.0,107.442],
            [279.4,98.552],[304.8,85.09],[317.5,76.454],[324.104,71.12],
            [324.983,69.4722],[323.342,68.326],[304.8,63.754],[279.4,49.276],
            [266.7,36.576],[259.08,25.4],[254.0,15.494],[248.92,0]];
FinP_Base_X = 248.92;       // root TE at the tube end
// Zephyr, Mach 0.8 build: 1/4 in (6.35 mm) carbon-fibre plate fins, root chord
// and root LE station of the kit (Apogee DWG 04997: root LE 245.034 above the
// tube end), span 125 (kit 112.9), tip chord 90, straight trailing edge swept
// aft to 12 mm past the base. The larger span keeps ~1.9 cal at max speed with
// the heavier tail; the swept TE puts the fixed fin's tip, not an aileron,
// first on the ground. (Kit outline: [[0,0],[150.749,112.852],[223.749,112.852],
// [269.494,12.548],[245.034,12.548],[228.27,0]].)
FinZ_Pts = [[0,0],[167,125],[257,125],[228.27,0]];
FinZ_Base_X = 245.034;
Fin_Pts    = Fin_Set=="Zephyr" ? FinZ_Pts : FinP_Pts;
Fin_Base_X = Fin_Set=="Zephyr" ? FinZ_Base_X : FinP_Base_X;
Fin_T      = 6.35;          // 1/4 in: Baltic birch plywood (Peregrine), carbon-fibre plate (Zephyr)
Fin_Slot_W = Fin_T + 0.5;
Fin_Tab_Z  = [55, 175];     // through-the-wall tab, glued to the motor tube
Fin_Slot_End_Clear = 0.5;
Fin_Tab_Depth = R_Out - MMT_Bore_R;
Rib_Wall   = 2.0;           // slot flanks, wall to motor tube

// ============================================
// AILERON (all in can/fin-frame terms; parameters, not fitted)
// ============================================
Hinge_Z       = 34;         // hinge line, above the base
Flap_Span     = 55;         // outer edge, y_f
Flap_Root_Gap = 0.8;        // root edge above the body surface
Flap_Gap      = 0.8;        // to the fixed fin, LE and outer edge
Flap_LE_R     = Fin_T/2;    // round leading edge about the shaft
Hinge_X       = Fin_Base_X - Hinge_Z;   // in fin coordinates
// travel checked, +-deg. Zephyr: +-5 sizes the hinge for Mach 0.8 with factor >= 2 and
// still gives ~30x the fins' own induced roll (tools/tailsteer_estimate.py)
Flap_Max      = Airframe == "Zephyr" ? 5 : 15;
// The aileron is two halves split on the fin's mid-plane, clamped round the
// shaft by M2 countersunk screws from the -Y face into tapped holes in the +Y
// half. Undo them and the halves come off sideways, then the shaft slides out
// into the notch; nothing glued has to move.
// [dz aft of the hinge, y_f]. The inner two sit 4.5 aft of the axis, inside the
// relief band and over the shaft engagement: the shaft takes their load. The
// outer two sit on solid face-to-face contact (aft of the band, or outboard
// of the shaft end).
Clamp_Screws  = [[4.5, 12], [4.5, 26], [18, 40], [18, 52]];
Clamp_Clear_D = 2.2; Clamp_Tap_D = 1.6; Clamp_Head_D = 3.8; Clamp_Tap_L = 2.6;
// M2 x 5 countersunk (ISO 7046-1 / ISO 14581, head 3.8): the length runs from the
// head's top face, flush with the -Y face, to the tip. It must stop 0.3 mm short
// of the tap hole's bottom; the +Y half keeps Fin_T/2 - Clamp_Tap_L of skin.
Clamp_Screw_L = 5;
// Drive: the D-groove is line-to-line with the shaft; near the shaft the split
// faces stand Clamp_Relief apart, so the screws squeeze the halves onto the
// shaft instead of onto each other. A Ø2 dowel through a cross hole in the
// shaft, lying in the split plane along the chord, carries the torque (slip
// fit; it lifts out of the shaft once the halves are off).
Clamp_Relief  = 0.25;       // total gap at the split face round the shaft only:
Relief_Dz     = 6.5;        //   from the LE to Relief_Dz aft of the hinge,
Relief_X_Pad  = 1.5;        //   and from the root to Shaft_X1 + Relief_X_Pad
Bore_Pad      = 1.5;        // D-bore runs this far past the shaft end (build tolerance)
Pin_D = 2; Pin_Yf = 19; Pin_Z = [2.2, -11.8];   // dowel: dia, y_f, z range rel. hinge
Pin_X = R_Out + Pin_Yf;
assert(Clamp_Screw_L <= Fin_T/2 + Clamp_Tap_L - 0.3, "clamp screw bottoms out in the tap hole");
assert(Fin_T/2 - Clamp_Tap_L >= 0.5, "tap hole leaves under 0.5 mm of +Y skin");
// Tail-first landing: the fixed fin must reach further aft than any aileron
// point. The aileron is clipped Skid_Margin forward of the notched fixed fin's
// aft-most point. Neither fin set is clipped: the Peregrine's fixed fin tip
// reaches 35 mm aft of the aileron, the Zephyr's swept TE 16 mm.
Skid_Margin   = 5;
function Fixed_Aft_X() = let(yt = Flap_Span + Flap_Gap, xn = Hinge_X - Flap_LE_R - Flap_Gap,
        P = Fin_Pts, n = len(P),
        v = [for (q=P) if (q[1] > yt || q[0] < xn) q[0]],
        c = [for (i=[0:n-1]) let(a=P[i], b=P[(i+1)%n]) if ((a[1]-yt)*(b[1]-yt) < 0)
                a[0] + (yt - a[1])*(b[0] - a[0])/(b[1] - a[1])])
    max(concat(v, c));
Flap_X_Max    = Fixed_Aft_X() - Skid_Margin;   // aileron planform ends here (fin x)

// ============================================
// SHAFT and BEARINGS
// NSK 684AZZ: d 4, D 9, B 4, ZZ shields, Cr 705 N, C0r 225 N, 1.01 g
// (nsk.com 684AZZ1MC3P6). Shields, not seals: no contact drag.
// ============================================
Shaft_D    = 4;             // silver steel rod, h9
Shaft_Flat = 0.5;           // filed D-flat, faces aft (-Z)
Brg_d = 4; Brg_D = 9; Brg_B = 4;
Brg_Seat_D  = 9.1;          // bore; set the bearing with retaining compound
Brg_Relief_D = 7.6;         // shoulder touches the outer race only
Brg_In_X0   = 25.0;         // inner bearing, inboard face
Brg_Out_X1  = R_In - 0.6;   // outer bearing, outboard face
Housing_Wall = 2.0;
Housing_D   = Brg_Seat_D + 2*Housing_Wall;
Shaft_X0    = Brg_In_X0 + 0.3;   // 0.9 mm clear of the inner housing's relief floor
// Field service: the fixed fin covers the hinge axis above the notch, so the
// shaft must come out into the notch. Pulled outward until its inner end
// clears the wall, it has to fit between the wall and the notch's top edge.
Shaft_L     = 54;
Shaft_X1    = Shaft_X0 + Shaft_L;
Wall_Hole_D = Shaft_D + 1.0;
Brg_Spacing = (Brg_Out_X1 - Brg_B/2) - (Brg_In_X0 + Brg_B/2);
Web_Y       = [-8.1, -6.5]; // hinge-block web on the -y side

// ============================================
// SERVO: MKS HV6160 (as PeregrineCamCanards.scad; MKS drawing)
// ============================================
Servo_L = 33; Servo_W = 10; Servo_Case_H = 35.2;
Servo_Spline_Off = 6;       // spline axis to the near case end, along L
Servo_Spline_D = 5; Servo_Spline_Top = Servo_Case_H + 3.5;
Servo_Lug_L = 45; Servo_Lug_H = 8; Servo_Lug_T = 2;
Servo_Lug_Hole_D = 3; Servo_Lug_Hole_X = 31.2; Servo_Lug_Spacing = 39;
Servo_Wire = [2.2, 10, 7, 4];   // stub beyond the bottom: depth, centre (along L from spline), length, width
// Horn: the servo's own metal arm, M2 ball stud at Horn_R
Horn_Hub_D = 8; Horn_Hub_H = 3; Horn_Arm_W = 5.5; Horn_Arm_T = 2.5;
Horn_R     = Airframe == "Zephyr" ? 8 : 9;   // pivot from the spline axis: its nut clears the servo case at full travel
Horn_Plane = Servo_Case_H/2 + 2.0;   // horn mid-plane above the case centre
Ball_D     = 4.8;           // M2 ball stud
// Horn pivot: the 4.8 mm pivot ball on an M2 x 10 12.9 screw through the servo's
// metal arm (2.5 thick): M2 nut on the case side, arm, 0.3 mm shim, ball, head
// beyond the ball. The nut is modelled by its across-corners circle.
// Ball centre = arm half + shim + ball half; the link eye (4.6) clears the arm by 0.3.
Horn_Shim  = 0.3;
Horn_Nut   = [4.6, 1.6];    // M2 nut: across corners, thickness
Horn_Head  = [3.8, 2.0];    // M2 socket head: dia, height
Ball_Off   = Horn_Arm_T/2 + Horn_Shim + Ball_D/2;
Horn_Screw_L = Horn_Arm_T + Horn_Shim + Ball_D + Horn_Nut[1] + 0.5;   // grip + 0.5 protrusion
assert(Horn_Screw_L <= 10, "horn pivot needs a longer screw than M2 x 10");
Link_Eye_D = 7.0;           // ball-link body envelope
Link_Eye_W = 4.6;           // ball-link eye width across the ball
Pushrod_L  = 52;            // ball centre to ball centre, M2 threaded rod
// crank arm, shaft axis to ball centre (sets the servo angle: a longer arm puts the
// servo, and its hatch, further from the fin). Zephyr: 16 with an 8 mm horn, a 2.0
// link ratio, so the servo's gear lash counts half at the aileron (its +-5 deg travel
// needs only +-10 deg of servo).
Crank_A    = Airframe == "Zephyr" ? 16 : 14;
// Servo placement: the case lies flat (W radial) with its centre at Servo_Rc
// in the fin frame; the horn points inward. The angle is solved so the horn
// ball sits axially over the crank ball (pushrod parallel to the axis).
Servo_Rc   = 38.5;
Horn_Ball_U = Horn_Plane + Ball_Off;     // along the output axis from the case centre
Horn_Ball_V = Servo_Rc - Horn_R;         // from the axis, along the case's radial
T_R        = sqrt(Horn_Ball_V*Horn_Ball_V + Horn_Ball_U*Horn_Ball_U);
Servo_Theta = atan2(Horn_Ball_U, Horn_Ball_V) + asin(Crank_A/T_R);
Crank_Xk   = sqrt(T_R*T_R - Crank_A*Crank_A);   // crank ball centre, radial
Servo_ZO   = Hinge_Z + Pushrod_L;               // horn plane height
Servo_Zc   = Servo_ZO - Servo_Spline_Off + Servo_L/2;
Link_Ratio = Crank_A / Horn_R;                  // aileron torque / servo torque

// Crank (printed PC)
Crank_Hub_D  = 9;
Crank_Collar_D = 5.2;       // bears on the inner races only
Crank_X0     = Brg_In_X0 + Brg_B + 0.15;
Crank_X1     = Brg_Out_X1 - Brg_B - 0.15;
// Clevis arm: the ball link's 4.8 mm pivot ball sits between two cheeks on a
// Ø2 hardened dowel pin (double shear), centred on the pushrod line, so the
// arm sees no torsion and the pin no cantilever. The cheeks join in a closed
// window, so the outer cheek's underside is a short bridge when printed.
Clevis_Gap   = Link_Eye_W + 0.6;
Cheek_T      = 2.5;         // both cheeks at the pivot
Crank_Arm_H  = 9;           // along Z
Crank_Arm_Y0 = 3.0;         // arm starts here (inside the hub), clear of the set-screw pocket
Crank_Arm_X1 = Crank_Xk + Clevis_Gap/2 + Cheek_T;      // outer cheek face
Crank_Win_Y  = [Crank_A - Link_Eye_D/2 - 1, Crank_A + Link_Eye_D/2 + 1];
Crank_Tip_Y  = Crank_Win_Y[1] + 2;
Pivot_D      = 2.0;         // dowel, press fit (Ø1.95 printed, ream to fit)
Pivot_L      = 10;          // Ø2 x 10 dowel (ISO 8734), centred: 0.1 below each cheek face
// The arm stands on the print bed at Crank_X0, so the inner cheek is thicker
// than Cheek_T; a spot face on its bed side brings it to Cheek_T at the pivot,
// so the bore is Clevis_Gap + 2 Cheek_T long and the dowel sits in both cheeks alike.
Cheek_T_In   = Crank_Xk - Clevis_Gap/2 - Crank_X0;
Pivot_Spot_D = Pivot_D + 2.5;
assert(Pivot_L <= Clevis_Gap + 2*Cheek_T && (Pivot_L - Clevis_Gap)/2 >= Cheek_T - 0.25,
       "pivot dowel does not fit the bore, or engages a cheek by less than Cheek_T - 0.25");
assert(Cheek_T_In >= Cheek_T, "inner cheek thinner than Cheek_T");
Crank_Arm_Xm = Crank_Xk - Clevis_Gap/2 - Cheek_T/2;    // inner cheek mid-plane (kept for the echo)
Crank_Arm_T  = Cheek_T;
Crank_Boss   = [7.2, 7.2, 8];   // set-screw boss: X, Y, depth below the axis (ruthex W 1.6)
Crank_Boss_Xm = (Crank_X0 + Crank_X1)/2;
Set_Insert   = [4.0, 5.0];  // ruthex RX-M3x4.0 SHORT: hole, pocket depth (L+1)

// Servo bay (in the servo frame: lx outward, ly toward larger angle)
Bay_Ly      = [-32.0, 24.5];   // web positions (fin-side web 1 mm clear of the pushrod links)
Bay_Floor_X = [-9.1, -7.5];
Bay_Web_T   = 1.6;
Floor_Ly0   = -15.6;                                           // floor stops short of the horn pivot
Floor_Bridge_Z = Servo_ZO + Horn_R*sin(25) + Link_Eye_D/2 + 1.5; // floor reaches the web above the horn
Lug_Bolt_D  = 2.8;          // M2.5 through the lug
Lug_Nut_AF  = 5.0; Lug_Nut_T = 2.0;
Ped_Ly      = [-15.6, -8.6];   // the horn pivot (nut + screw tip) passes at ly <= -16.25; the nut trap opens at -15.6
Ped_X_In    = -7.5;
Spine_X     = [-7.5, -5.3];
Ped_Z_Aft   = [0, Servo_ZO - Servo_Spline_Off - 0.3];
Ped_Z_Fwd   = [Servo_ZO - Servo_Spline_Off + Servo_L + 0.3, Servo_Zc + Servo_Lug_L/2 + 3];
Bay_Top_A   = 200;          // sector A: floor carries the LiPo up to here
Bay_Top     = 121;          // sectors B and C

// LiPo: Tattu 450 mAh 2S 75C long pack (61 x 16 x 15 mm, 28 g), on sector A floor
Lipo = [15, 16, 61];        // along u (tangential), lx (radial), Z
Lipo_Z0 = 128;
Lipo_Lx0 = Bay_Floor_X[1] + 0.3;
Strap_Slot = [2.5, 14];

// Hatch openings (servo frame, u = -ly)
Hatch_U   = [-23.5, 33.5];    // servo part: arc at R_Out from the servo angle; the servo with its horn lifts out from 33.0 (verifier)
Hatch_Z   = [Servo_Zc - Servo_Lug_L/2 - 1, Servo_Zc + Servo_Lug_L/2 + 1];   // passes the lugs
Hatch_Bat_U = [-11.5, 11.5];  // sector A battery part
Hatch_Bat_Z1 = 192;
Hatch_Rebate = 7.5;           // cover overlap round the opening
// On the fin-side edge the rebate is narrow, so a fin-root fillet with a 10 mm
// leg still ends 2 mm short of the cover: the fin face is at u = Servo_Theta's
// arc minus Fin_T/2 (no screw sits on that edge).
Hatch_Rebate_Bat = 9.5;       // LiPo part, -u edge: wider, so its screw clears the rail strip
Hatch_Screw_In_Bat = 5.5;
Hatch_Rebate_Fin = 3.0;      // cover seat 2.75 mm on this edge (no screw on it)
Fillet_Max = 10;              // fin-root fillet leg the hatches leave room for (+2 mm)
assert(Servo_Theta*PI/180*R_Out - Fin_T/2 - (Hatch_U[1] + Hatch_Rebate_Fin) >= Fillet_Max + 2,
       "hatch rebate too close to the fin root fillet");
Hatch_Screw_In = 4.3;         // screw axis from the opening edge (insert wall 1.6 + 0.7)
Hatch_Rebate_D = 1.6;         // cover thickness = rebate depth
Hatch_Doubler = [8.5, 2.0];   // band round the opening inside the wall: width, thickness
Hatch_Gap = 0.25;
Hatch_Screw = 3.4;            // M3 button head through the cover
Hatch_Insert = [4.0, 6.7];    // ruthex RX-M3x5.7: hole, depth (L+1)
Hatch_Boss_D = 8.0;

// Rail button boss: ruthex RX-M4x8.1 (also #8-32 body), kit 1010 button
Rail_Insert = [5.6, 9.6];
Rail_Boss_D = 12;

// Servo switch: Schurter 0033.4513 (as the nose), sector B
Sw_A = 180; Sw_Z = 178; Sw_Panel_T = 6; Sw_Pad_D = 22;
Sw_Env = [16, 23.5];        // rear envelope: dia, depth behind the bezel seat

// ============================================
// CHECKS
// ============================================
assert(Total_H <= 250.5, "TOO TALL FOR P1S");
assert(Brg_Out_X1 - Brg_B > Crank_X1, "crank overlaps the outer bearing");
assert(Crank_Arm_X1 < Crank_X1 - 0.3, "outer cheek runs past the hub end");
assert(Crank_Win_Y[0] > Crank_Hub_D/2 + 1, "clevis window cuts into the hub");
assert(Crank_A - Link_Eye_D/2 > Housing_D/2 + 0.5, "link eye hits the outer housing");
assert(Shaft_L <= Flap_Span + Flap_Gap - 0.8, "shaft too long to come out into the notch");
assert(Shaft_X1 > R_Out + Flap_Root_Gap + 20, "shaft engages the aileron by less than 20 mm");
assert(Hinge_Z - Flap_LE_R - Flap_Gap > 0, "hinge too low");
assert(Fin_Tab_Z[0] - Hinge_Z > Housing_D/2 + 8, "fin tab runs into the hinge block");
assert(Rail_Aft_Z + Rail_Boss_D/2 + 3 < Hatch_Z[0] - Hatch_Rebate, "rail boss under the hatch");
assert(Servo_Rc + Servo_W/2 < R_In, "servo outside the wall");
assert(Shaft_X0 > MMT_Bore_R + 1, "shaft into the motor tube");
// set-screw insert pocket: on the aft side at |Y| <= Set_Insert[0]/2; the arm
// starts at Y = Crank_Arm_Y0 and the pivot hole is at Y = Crank_A, so the
// pocket clears both (in Y, whatever the X overlap)
assert(Set_Insert[0]/2 + 0.5 <= Crank_Arm_Y0, "set-screw pocket meets the crank arm");
assert(Crank_A - Pivot_D/2 > Set_Insert[0]/2 + 1, "set-screw pocket meets the pivot hole");
assert(Crank_Boss_Xm + Crank_Boss[0]/2 < Crank_X1 - 0.45, "set-screw boss runs past the hub");

// ============================================
// RENDER
// ============================================
Render_Part = 0;
// 0 assembly preview; 1 can; 2 servo hatch; 3 servo+LiPo hatch; 4 crank;
// 5 aileron (print pose); 6 bearing coupon; 7 fixed fin 2D (DXF)
// verifier envelopes (assembled pose, fin 0 frame unless noted):
// 20 servos x3; 21 horns x3; 22 bearings x6; 23 shafts x3; 24 cranks x3;
// 25 ailerons x3 (assembled); 26 fixed fins x3 (with tabs); 27 MMT; 28 LiPo;
// 29 switch envelope; 30 hatch covers assembled; 31 retainer envelope;
// 32 single aileron fin 0; 33 single crank fin 0; 34 single servo+horn fin 0 (no horn);
// 35 single horn fin 0; 36 single fixed fin 0; 37 paper tube + ply CR envelope
Defl = 0;                   // aileron deflection for the assembly preview

if (Render_Part == 0) TS_Assembly();
if (Render_Part == 1) TS_Can();
if (Render_Part == 2) TS_Hatch_Print(false);
if (Render_Part == 3) TS_Hatch_Print(true);
if (Render_Part == 4) TS_Crank_Print();
if (Render_Part == 5) TS_Aileron_Print(-1);   // screw half
if (Render_Part == 8) TS_Aileron_Print(1);    // tapped half
if (Render_Part == 40) Shaft(Defl);
if (Render_Part == 38) Aileron_Half(-1, Defl);
if (Render_Part == 39) Aileron_Half(1, Defl);
if (Render_Part == 6) TS_Coupon();
if (Render_Part == 7) TS_Fixed_Fin_2D();
if (Render_Part == 9) TS_Drill_Jig();
if (Render_Part == 20) for (k=[0:2]) Fin_Frame(k) Servo_Frame() Servo_Envelope();
if (Render_Part == 21) for (k=[0:2]) Fin_Frame(k) Servo_Frame() Horn_Envelope();
if (Render_Part == 22) for (k=[0:2]) Fin_Frame(k) Bearings();
if (Render_Part == 23) for (k=[0:2]) Fin_Frame(k) Shaft();
if (Render_Part == 24) for (k=[0:2]) Fin_Frame(k) Crank();
if (Render_Part == 25) for (k=[0:2]) Fin_Frame(k) Aileron();
if (Render_Part == 26) for (k=[0:2]) Fin_Frame(k) Fixed_Fin();
if (Render_Part == 27) MMT();
if (Render_Part == 28) Lipo_Envelope();
if (Render_Part == 29) Switch_Envelope();
if (Render_Part == 30) for (k=[0:2]) Fin_Frame(k) Hatch_Cover(k==0);
if (Render_Part == 31) translate([0,0,-Overlap]) cylinder(d=Retainer_D, h=Retainer_H);
if (Render_Part == 32) Aileron();
if (Render_Part == 33) Crank();
if (Render_Part == 34) Servo_Frame() Servo_Envelope();
if (Render_Part == 35) Servo_Frame() Horn_Envelope();
if (Render_Part == 36) Fixed_Fin();
if (Render_Part == 37) Paper_Tube();

// ============================================
// FRAMES
// ============================================
module Fin_Frame(k) rotate([0,0,Fin_A[k]]) children();
// servo frame: origin at the case centre line (Z kept), lx = case radial
module Servo_Frame() rotate([0,0,Servo_Theta]) translate([Servo_Rc,0,0]) children();
// fin-coordinate 2D -> fin frame 3D (extruded symmetric in Y)
module Fin_Place(t=Fin_T)
    multmatrix([[0,1,0,R_Out],[0,0,1,0],[-1,0,0,Fin_Base_X],[0,0,0,1]])
        linear_extrude(height=t, center=true, convexity=6) children();

// ============================================
// FIN AND AILERON
// ============================================
module Fin_Outline_2D() polygon(Fin_Pts);
module Notch_2D()      // cut from the fixed fin
    translate([Hinge_X - Flap_LE_R - Flap_Gap, -1])
        square([400, Flap_Span + Flap_Gap + 1]);
module Flap_Planform_2D()
    intersection(){
        Fin_Outline_2D();
        translate([Hinge_X - Flap_LE_R, Flap_Root_Gap])
            square([Flap_X_Max - (Hinge_X - Flap_LE_R), Flap_Span - Flap_Root_Gap]);
    }
module Tab_2D()
    translate([Fin_Base_X - Fin_Tab_Z[1], -Fin_Tab_Depth])
        square([Fin_Tab_Z[1] - Fin_Tab_Z[0], Fin_Tab_Depth + Overlap]);
module TS_Fixed_Fin_2D()
    union(){ difference(){ Fin_Outline_2D(); Notch_2D(); } Tab_2D(); }
module Fixed_Fin() Fin_Place() TS_Fixed_Fin_2D();

// D-bore for the shaft, along X at (0, Hinge_Z)
module Shaft_Section(d, flat) intersection(){
    circle(d=d, $fn=48);
    translate([-d, -(d/2 - flat)]) square([2*d, 2*d]);
}
module Aileron_Body() intersection(){
    Fin_Place() Flap_Planform_2D();
    // round LE about the shaft, flat aft of it
    union(){
        translate([0,0,Hinge_Z]) rotate([0,90,0]) cylinder(r=Flap_LE_R, h=400, $fn=64);
        translate([0,-Fin_T,Hinge_Z - 400]) cube([400, 2*Fin_T, 400]);
    }
}
// blind D-bore from the root, flat toward -Z (aft) as on the shaft
module Aileron_Bore(){
    translate([R_Out + Flap_Root_Gap - 1, 0, Hinge_Z]) rotate([0,90,0])
        linear_extrude(height = Shaft_X1 + Bore_Pad - (R_Out + Flap_Root_Gap - 1), convexity=4)
            rotate(90) Shaft_Section(Shaft_D, Shaft_Flat);      // line-to-line
    translate([Pin_X, 0, Hinge_Z + Pin_Z[1]]) cylinder(d=Pin_D + 0.05, h=Pin_Z[0] - Pin_Z[1], $fn=24);
    // split-face relief round the shaft
    translate([0, -Clamp_Relief/2, Hinge_Z - Relief_Dz]) cube([Shaft_X1 + Relief_X_Pad, Clamp_Relief, 400]);
}
// clamp screw at [dz aft of the hinge, y_f]: countersink on -Y, clearance in
// the -Y half, tap drill blind in the +Y half (its outer face stays closed)
function Clamp_Pos(c) = [R_Out + c[1], Hinge_Z - c[0]];
module Clamp_Holes(half)   // half: -1 = screw side, +1 = tapped side
    for (c=Clamp_Screws) let(q=Clamp_Pos(c)) translate([q[0], 0, q[1]]) rotate([90,0,0])
        if (half < 0) {
            translate([0,0,-Overlap]) cylinder(d=Clamp_Clear_D, h=Fin_T, $fn=20);
            translate([0,0,Fin_T/2 - (Clamp_Head_D - Clamp_Clear_D)/2])
                cylinder(d1=Clamp_Clear_D, d2=Clamp_Head_D + 0.2, h=(Clamp_Head_D - Clamp_Clear_D)/2 + 0.1 + Overlap, $fn=24);
        } else translate([0,0,-Clamp_Tap_L]) cylinder(d=Clamp_Tap_D, h=Clamp_Tap_L + Overlap, $fn=16);
module Aileron_Half(half, defl=Defl)
    translate([0,0,Hinge_Z]) rotate([defl,0,0]) translate([0,0,-Hinge_Z])
        difference(){
            intersection(){ Aileron_Body();
                translate([0, half > 0 ? 0 : -Fin_T, -400]) cube([400, Fin_T, 800]); }
            Aileron_Bore();
            Clamp_Holes(half);
        }
module Aileron(defl=Defl){ Aileron_Half(-1, defl); Aileron_Half(1, defl); }

module Shaft(defl=Defl)
    translate([0,0,Hinge_Z]) rotate([defl,0,0]) difference(){
        translate([Shaft_X0,0,0]) rotate([0,90,0])
            linear_extrude(height=Shaft_L, convexity=2) Shaft_Section_Pose();
        translate([Pin_X, 0, -5]) cylinder(d=Pin_D + 0.05, h=10, $fn=24);   // cross hole for the drive dowel
    }
// flat toward -Z: in the rotated extrude frame local x = -Z
module Shaft_Section_Pose() rotate([0,0,90]) Shaft_Section(Shaft_D, Shaft_Flat);

module Bearings() for (x0=[Brg_In_X0, Brg_Out_X1 - Brg_B])
    translate([x0,0,Hinge_Z]) rotate([0,90,0]) difference(){
        cylinder(d=Brg_D, h=Brg_B, $fn=48);
        translate([0,0,-1]) cylinder(d=Brg_d, h=Brg_B+2, $fn=32);
    }

// ============================================
// CRANK (printed PC): hub between the bearings, arm toward +Y
// ============================================
module Crank_Body(){
    // hub
    translate([Crank_X0 + 0.45,0,Hinge_Z]) rotate([0,90,0])
        cylinder(d=Crank_Hub_D, h=Crank_X1 - Crank_X0 - 0.9);
    for (x=[Crank_X0, Crank_X1 - 0.45]) translate([x,0,Hinge_Z]) rotate([0,90,0])
        cylinder(d=Crank_Collar_D, h=0.45 + Overlap);
    // clevis arm and set-screw boss stand on the inboard collar plane (the
    // print bed), recessed round the bearing face over the collar's height
    difference(){
        union(){
            hull(){
                translate([Crank_X0, Crank_Arm_Y0, Hinge_Z - Crank_Arm_H/2])
                    cube([Crank_Arm_X1 - Crank_X0, 1, Crank_Arm_H]);
                translate([Crank_X0, Crank_Tip_Y - Crank_Arm_H/2, Hinge_Z]) rotate([0,90,0])
                    cylinder(d=Crank_Arm_H, h=Crank_Arm_X1 - Crank_X0);
            }
            translate([Crank_X0, -Crank_Boss[1]/2, Hinge_Z - Crank_Boss[2]])
                cube([Crank_Boss_Xm + Crank_Boss[0]/2 - Crank_X0, Crank_Boss[1], Crank_Boss[2]]);
        }
        // bearing-face recess: nothing but the collar within r 4.9 over x0..x0+0.45
        translate([Crank_X0 - 1, 0, Hinge_Z]) rotate([0,90,0]) cylinder(r=Brg_D/2 + 0.4, h=1.45, $fn=48);
        // clevis window for the ball-link eye, through along Z
        translate([Crank_Xk - Clevis_Gap/2, Crank_Win_Y[0], Hinge_Z - Crank_Arm_H])
            cube([Clevis_Gap, Crank_Win_Y[1] - Crank_Win_Y[0], 2*Crank_Arm_H]);
    }
}
module Crank_Holes(){
    // D-bore
    translate([Crank_X0 - 1,0,Hinge_Z]) rotate([0,90,0])
        linear_extrude(height=Crank_X1 - Crank_X0 + 2) Shaft_Section_Pose_Bore();
    // pivot pin through both cheeks along X (press fit), and the spot face that
    // brings the inner cheek to Cheek_T at the pin
    translate([Crank_X0 - 1, Crank_A, Hinge_Z]) rotate([0,90,0])
        cylinder(d=Pivot_D - 0.05, h=Crank_Arm_X1 - Crank_X0 + 2, $fn=24);
    translate([Crank_X0 - 1, Crank_A, Hinge_Z]) rotate([0,90,0])
        cylinder(d=Pivot_Spot_D, h=1 + Cheek_T_In - Cheek_T, $fn=32);
    // set screw: insert pocket from the aft face, then M3 clearance to the bore
    translate([Crank_Boss_Xm, 0, Hinge_Z - Crank_Boss[2] - Overlap])
        cylinder(d=Set_Insert[0], h=Set_Insert[1] + Overlap, $fn=32);
    translate([Crank_Boss_Xm, 0, Hinge_Z - Crank_Boss[2]])
        cylinder(d=3.2, h=Crank_Boss[2], $fn=24);
}
module Shaft_Section_Pose_Bore() rotate([0,0,90]) Shaft_Section(Shaft_D + 0.1, Shaft_Flat - 0.05);
module Crank(defl=Defl)
    translate([0,0,Hinge_Z]) rotate([defl,0,0]) translate([0,0,-Hinge_Z])
        difference(){ Crank_Body(); Crank_Holes(); }

// ============================================
// SERVO, HORN, LiPo, SWITCH ENVELOPES
// ============================================
// servo frame: lx radial (case W), ly tangential (+ = away from the fin),
// output axis along -ly; horn plane at ly = -Horn_Plane, Z = Servo_ZO.
module Servo_Envelope(){
    zc0 = Servo_ZO - Servo_Spline_Off;
    translate([-Servo_W/2, -Servo_Case_H/2, zc0]) cube([Servo_W, Servo_Case_H, Servo_L]);
    // lugs (8 mm below the case top = output end)
    difference(){
        translate([-Servo_Lug_T/2, -Servo_Case_H/2, Servo_Zc - Servo_Lug_L/2])
            cube([Servo_Lug_T, Servo_Lug_H, Servo_Lug_L]);
        for (z=Lug_Zs()) translate([0, Servo_Lug_Hole_Ly(), z]) rotate([0,90,0])
            cylinder(d=Servo_Lug_Hole_D, h=4, center=true, $fn=20);
    }
    // spline
    translate([0, -Servo_Case_H/2 + Overlap, Servo_ZO]) rotate([90,0,0])
        cylinder(d=Servo_Spline_D, h=Servo_Spline_Top - Servo_Case_H + Overlap, $fn=24);
    // lead stub at the bottom end
    translate([-Servo_Wire[3]/2, Servo_Case_H/2 - Overlap, Servo_ZO + Servo_Wire[1] - Servo_Wire[2]/2])
        cube([Servo_Wire[3], Servo_Wire[0] + Overlap, Servo_Wire[2]]);
}
function Lug_Zs() = [Servo_Zc - Servo_Lug_Spacing/2, Servo_Zc + Servo_Lug_Spacing/2];
function Servo_Lug_Hole_Ly() = -(Servo_Lug_Hole_X - Servo_Case_H/2);
module Horn_Envelope(phi=0) difference(){ Horn_Envelope0(phi); translate([0, -Servo_Case_H/2 + 0.2, Servo_ZO]) rotate([90,0,0]) cylinder(d=Servo_Spline_D + 0.1, h=Servo_Spline_Top - Servo_Case_H + 0.2, $fn=24); }
module Horn_Envelope0(phi=0){
    // rotates about the output axis (along ly) by phi
    translate([0,0,Servo_ZO]) rotate([0,phi,0]) translate([0,0,-Servo_ZO]){
        translate([0, -(Servo_Case_H/2 + 0.5), Servo_ZO]) rotate([90,0,0])
            difference(){ cylinder(d=Horn_Hub_D, h=Horn_Hub_H, $fn=32); translate([0,0,-1]) cylinder(d=Servo_Spline_D + 0.1, h=Horn_Hub_H + 2, $fn=24); }
        hull(){
            translate([0, -Horn_Plane, Servo_ZO]) rotate([90,0,0])
                cylinder(d=Horn_Arm_W, h=Horn_Arm_T, center=true, $fn=24);
            translate([-Horn_R, -Horn_Plane, Servo_ZO]) rotate([90,0,0])
                cylinder(d=Horn_Arm_W, h=Horn_Arm_T, center=true, $fn=24);
        }
        // pivot screw: nut on the case side, head beyond the ball
        translate([-Horn_R, -Horn_Plane + Horn_Arm_T/2, Servo_ZO]) rotate([-90,0,0])
            cylinder(d=Horn_Nut[0], h=Horn_Nut[1], $fn=24);   // any nut angle
        translate([-Horn_R, -Horn_Plane + Horn_Arm_T/2 + Horn_Nut[1] + 0.5, Servo_ZO]) rotate([90,0,0])
            cylinder(d=2.0, h=Horn_Screw_L, $fn=16);
        translate([-Horn_R, -(Horn_Ball_U + Ball_D/2), Servo_ZO]) rotate([90,0,0])
            cylinder(d=Horn_Head[0], h=Horn_Head[1], $fn=20);
        translate([-Horn_R, -Horn_Ball_U, Servo_ZO]) sphere(d=Ball_D, $fn=24);
    }
}
module Lipo_Envelope() Fin_Frame(0) Servo_Frame()
    translate([Lipo_Lx0, -Lipo[0]/2, Lipo_Z0]) cube([Lipo[1], Lipo[0], Lipo[2]]);
module Switch_Envelope()
    rotate([0,0,Sw_A]) translate([R_Out - Sw_Panel_T, 0, Sw_Z]) rotate([0,-90,0])
        cylinder(d=Sw_Env[0], h=Sw_Env[1] - Sw_Panel_T, $fn=32);
module MMT() translate([0,0,MMT_Z0]) difference(){
    cylinder(d=MMT_OD, h=MMT_L, $fn=96);
    translate([0,0,-1]) cylinder(d=MMT_OD - 2.794, h=MMT_L + 2, $fn=96);
}
module Paper_Tube() union(){
    translate([0,0,Can_L]) difference(){
        cylinder(d=Body_OD, h=Tube_Piece_L, $fn=96);
        translate([0,0,-1]) cylinder(d=Body_ID, h=Tube_Piece_L + 2, $fn=96);
    }
    translate([0,0,Ply_CR_Z0]) difference(){
        cylinder(d=Body_ID, h=Ply_CR_T, $fn=96);
        translate([0,0,-1]) cylinder(d=MMT_OD, h=Ply_CR_T + 2, $fn=96);
    }
}

// ============================================
// HATCHES: outlines in (u, Z), u = arc length at R_Out from the servo's
// angle, + toward the fin. Cut and cover are radial prisms of the same
// outline, so every edge is radial (no undercut lips).
// ============================================
function Hatch_Pts(bat) = let(u0=Hatch_U[0], u1=Hatch_U[1], z0=Hatch_Z[0], z1=Hatch_Z[1],
        um=(u0+u1)/2, hw=(u1-u0)/2, b0=Hatch_Bat_U[0], b1=Hatch_Bat_U[1], bz=Hatch_Bat_Z1,
        bm=(b0+b1)/2, bh=(b1-b0)/2)
    bat ? [[u0,z0],[u1,z0],[u1,z1],[b1, z1+(u1-b1)],[b1,bz],[bm,bz+bh],[b0,bz],[b0, z1+(b0-u0)],[u0,z1]]
        : [[u0,z0],[u1,z0],[u1,z1],[um,z1+hw],[u0,z1]];   // 45 deg gable top: supportless
function Hatch_Ctr(bat) = bat ? [0, Hatch_Z[1] + 5] : [(Hatch_U[0]+Hatch_U[1])/2, (Hatch_Z[0]+Hatch_Z[1])/2];
// offset of a CCW polygon, edge i (P[i] -> P[i+1]) moved outward by G[i]; each
// vertex goes to the intersection of its two offset edges
function Off_Pts(P, G) = [for (i=[0:len(P)-1]) let(
        n=len(P), a=P[(i-1+n)%n], v=P[i], b=P[(i+1)%n],
        g1=G[(i-1+n)%n], g2=G[i],
        d1=(v-a)/norm(v-a), d2=(b-v)/norm(b-v), n1=[d1[1],-d1[0]], n2=[d2[1],-d2[0]],
        c=n1*n2)
    v + n1*(g1 - c*g2)/(1 - c*c) + n2*(g2 - c*g1)/(1 - c*c)];
// per-edge offsets: g everywhere, gf on the fin-side edge (P[1] -> P[2], u = Hatch_U[1])
// and gb on the LiPo part's -u edge (P6 -> P7, sector A only), where the third
// screw sits off the rail strip
function Hatch_G(bat, g, gf, gb) = [for (i=[0:len(Hatch_Pts(bat))-1])
    i == 1 ? gf : (bat && i == 6 && !is_undef(gb)) ? gb : g];
function Sub_Pts(P, step=2) = [for (i=[0:len(P)-1]) let(a=P[i], b=P[(i+1)%len(P)],
        n=max(1, ceil(norm(b-a)/step))) for (k=[0:n-1]) a + (b-a)*k/n];
function Ang_U(u) = Servo_Theta - u/R_Out*180/PI;
function RP(r, p) = [r*cos(Ang_U(p[0])), r*sin(Ang_U(p[0])), p[1]];
// radial prism of outline P between radii r0 and r1 (fin frame); c: star centre
module Radial_Prism(P, c, r0=28, r1=75) let(N=len(P))
    polyhedron(points=concat([for (p=P) RP(r0,p)], [for (p=P) RP(r1,p)], [RP(r0,c), RP(r1,c)]),
               faces=concat([for (i=[0:N-1]) [2*N, (i+1)%N, i]],
                            [for (i=[0:N-1]) [2*N+1, N+i, N+(i+1)%N]],
                            [for (i=[0:N-1]) each [[i,(i+1)%N,N+(i+1)%N],[i,N+(i+1)%N,N+i]]]),
               convexity=6);
module Hatch_Shell(bat, grow, ra, rb, grow_fin=undef, grow_bat=undef)
    intersection(){
        Radial_Prism(Sub_Pts(Off_Pts(Hatch_Pts(bat),
            Hatch_G(bat, grow, is_undef(grow_fin) ? grow : grow_fin, grow_bat))), Hatch_Ctr(bat));
        Tube_Shell(ra, rb);
    }
// undo the servo frame (for axis-centred solids inside Servo_Frame)
module Fin_Inv() translate([-Servo_Rc,0,0]) rotate([0,0,-Servo_Theta]) children();
module Tube_Shell(ra, rb) difference(){
    translate([0,0,-1]) cylinder(r=rb, h=Can_L + 2, $fn=192);
    translate([0,0,-2]) cylinder(r=ra, h=Can_L + 4, $fn=192);
}
// Screws sit in the rebate band, Hatch_Screw_In outside the opening edge.
// One on the side away from the fin; one on the 45 deg edge on the fin
// side, above the pushrod; sector A adds one beside the LiPo. On sector A
// all three stay off the 60 deg rail strip.
function Hatch_Screws(bat) = let(
        um = (Hatch_U[0] + Hatch_U[1])/2, hw = (Hatch_U[1] - Hatch_U[0])/2,
        e1 = [Hatch_U[1], Hatch_Z[1]],
        e2 = bat ? [Hatch_Bat_U[1], Hatch_Z[1] + (Hatch_U[1] - Hatch_Bat_U[1])] : [um, Hatch_Z[1] + hw],
        mid = (e1 + e2)/2, n = Hatch_Screw_In/sqrt(2))
    concat([[Hatch_U[0] - Hatch_Screw_In, Hatch_Z[1] - 8],   // boss and corbel above the servo lead stub
            [mid[0] + n, mid[1] + n]],
           bat ? [[Hatch_Bat_U[0] - Hatch_Screw_In_Bat, Hatch_Bat_Z1 - 8]] : []);
Hatch_Seat_R = R_Out - Hatch_Rebate_D;
// radial cylinders on the screw axes; a, b: radius range relative to the seat face
module Hatch_Screw_Axes(bat, d, a, b)
    for (s=Hatch_Screws(bat)) rotate([0,0,Ang_U(s[0])]) translate([Hatch_Seat_R + a, 0, s[1]])
        rotate([0,90,0]) cylinder(d=d, h=b - a, $fn=24);
module Hatch_Cover(bat=false)
    difference(){
        Hatch_Shell(bat, Hatch_Rebate - Hatch_Gap, Hatch_Seat_R, R_Out, Hatch_Rebate_Fin - Hatch_Gap, Hatch_Rebate_Bat - Hatch_Gap);
        Hatch_Screw_Axes(bat, Hatch_Screw, -1, 5);
    }
// band round the opening inside the wall + radial screw bosses on 45 deg corbels
module Hatch_Frame(bat=false){
    Hatch_Shell(bat, Hatch_Doubler[0], R_In - Hatch_Doubler[1], R_In + Overlap, undef, Hatch_Rebate_Bat + 1.5);
    for (s=Hatch_Screws(bat)){
        a = Hatch_Seat_R - Hatch_Insert[1] - 1.6;
        rotate([0,0,Ang_U(s[0])]) translate([0,0,s[1]]) intersection(){
            union(){
                translate([a, 0, 0]) rotate([0,90,0]) cylinder(d=Hatch_Boss_D, h=R_In - a + 0.5, $fn=32);
                translate([a, -Hatch_Boss_D/2, -Hatch_Boss_D/2]) cube([R_In - a + 0.5, Hatch_Boss_D, Hatch_Boss_D/2]);
                hull(){
                    translate([a, -Hatch_Boss_D/2, -Hatch_Boss_D/2]) cube([R_In - a + 0.5, Hatch_Boss_D, Overlap]);
                    translate([R_In - 1, -Hatch_Boss_D/2, -Hatch_Boss_D/2 - (R_In - 1 - a)]) cube([1.5, Hatch_Boss_D, Overlap]);
                }
            }
            translate([0,0,-s[1]]) cylinder(r=R_In + Overlap, h=Can_L, $fn=192);
        }
    }
}

// ============================================
// THE CAN
// ============================================
module TS_Can() difference(){
    union(){
        // outer wall and shoulder
        difference(){ cylinder(r=R_Out, h=Can_L, $fn=192);
                      translate([0,0,-1]) cylinder(r=R_In, h=Can_L + 2, $fn=192); }
        translate([0,0,Can_L - 4]) difference(){
            cylinder(d=Shoulder_OD, h=Shoulder_L + 4, $fn=192);
            translate([0,0,-1]) cylinder(d=Shoulder_OD - 2*Shoulder_Wall, h=Shoulder_L + 6, $fn=192);
        }
        // 45 deg step from the wall to the shoulder (supportless)
        translate([0,0,Can_L - 4 - (R_In - (Shoulder_OD/2 - Shoulder_Wall))])
            difference(){
                cylinder(r=R_In + Overlap, h=R_In - (Shoulder_OD/2 - Shoulder_Wall), $fn=192);
                translate([0,0,-Overlap]) cylinder(r1=R_In, r2=Shoulder_OD/2 - Shoulder_Wall,
                    h=R_In - (Shoulder_OD/2 - Shoulder_Wall) + 2*Overlap, $fn=192);
            }
        for (k=[0:2]) Fin_Frame(k){ Fin_Rib(); Hinge_Block(); Servo_Bay(k==0); }
        for (k=[0:2]) Fin_Frame(k) Hatch_Frame(k==0);
        Rail_Boss();
        Switch_Pad();
    }
    // motor tube and retainer clearance
    translate([0,0,-1]) cylinder(r=MMT_Bore_R, h=Total_H + 2, $fn=96);
    Retainer_Cut();
    for (k=[0:2]) Fin_Frame(k){
        Fin_Slot();
        Hinge_Holes();
        // aileron sweep and root clearance (nothing of the can outside R_Out anyway)
    }
    for (k=[0:2]) Fin_Frame(k){
        Hatch_Shell(k==0, 0, R_In - Hatch_Doubler[1] - 0.5, R_Out + 1);   // opening (wall and band only)
        Hatch_Shell(k==0, Hatch_Rebate, Hatch_Seat_R, R_Out + 1, Hatch_Rebate_Fin, Hatch_Rebate_Bat);   // rebate
        Hatch_Screw_Axes(k==0, Hatch_Insert[0], -Hatch_Insert[1], 0.5);
    }
    for (k=[0:2]) Fin_Frame(k) Servo_Frame(){
        Lug_Holes();
        if (k==0) Strap_Slots();
    }
    Rail_Hole();
    Switch_Hole();
}

// slot flanks from the motor tube to the wall; ribs stop 2 mm above the tab
// they stand on the bed and merge with the hinge pillars; over the crank
// window (cut later) they bridge from pillar to pillar
module Fin_Rib() intersection(){
    union(){
        for (s=[-1,1]) translate([MMT_Bore_R - 1, s > 0 ? Fin_Slot_W/2 : -(Fin_Slot_W/2 + Rib_Wall), 0])
            cube([R_Out, Rib_Wall, Fin_Tab_Z[1] + Fin_Slot_End_Clear + 2]);
        // between the flanks: solid only where the slot is (the slot is cut later) and a cap above it
        translate([MMT_Bore_R - 1, -Fin_Slot_W/2 - Overlap, Fin_Tab_Z[0] - Fin_Slot_End_Clear])
            cube([R_Out, Fin_Slot_W + 2*Overlap, Fin_Tab_Z[1] - Fin_Tab_Z[0] + 2*Fin_Slot_End_Clear + 2]);
    }
    cylinder(r=R_In + Overlap, h=Can_L, $fn=192);
}
module Fin_Slot()
    translate([MMT_Bore_R - 1, -Fin_Slot_W/2, Fin_Tab_Z[0] - Fin_Slot_End_Clear])
        cube([R_Out, Fin_Slot_W, Fin_Tab_Z[1] - Fin_Tab_Z[0] + 2*Fin_Slot_End_Clear]);

// hinge block: two bearing housings on pillars from the bed, joined by a web
// on the -Y side; the crank window between them is open aft and toward +Y.
module Hinge_Block(){
    ztop = Hinge_Z + Housing_D/2*sqrt(2);   // teardrop housings: pointed tops
    // inner housing + pillar (cut round the retainer, 45 deg underside)
    difference(){
        union(){
            translate([MMT_Bore_R - 0.5, Web_Y[1] - 0.5, 0])
                cube([Brg_In_X0 + Brg_B - MMT_Bore_R + 0.5, Housing_D/2 - 0.1 - (Web_Y[1] - 0.5), Hinge_Z + 1]);
            Teardrop_X(Housing_D, MMT_Bore_R - 0.5, Brg_In_X0 + Brg_B);
        }
        Retainer_Cut();
    }
    // outer housing + pillar, merged with the wall
    translate([Brg_Out_X1 - Brg_B, Web_Y[1] - 0.5, 0])
        cube([R_In - (Brg_Out_X1 - Brg_B) + 0.5, Housing_D/2 - 0.1 - (Web_Y[1] - 0.5), Hinge_Z + 1]);
    Teardrop_X(Housing_D, Brg_Out_X1 - Brg_B, R_In + 0.5);
    // web
    difference(){
        translate([MMT_Bore_R - 0.5, Web_Y[0], 0])
            cube([R_In - MMT_Bore_R + 1, Web_Y[1] - Web_Y[0], ztop]);
        Retainer_Cut();
    }
}
module Retainer_Cut()   // retainer envelope plus a 45 deg cone above it
    translate([0,0,-Overlap]) union(){
        cylinder(d=Retainer_D + 1, h=Retainer_H);
        translate([0,0,Retainer_H - Overlap])
            cylinder(r1=Retainer_D/2 + 0.5, r2=MMT_Bore_R, h=Retainer_D/2 + 0.5 - MMT_Bore_R);
    }
// bearing seats (teardrop: pointed top for supportless printing), reliefs, wall hole
module Teardrop_X(d, x0, x1)
    translate([x0, 0, Hinge_Z]) rotate([0,90,0]) linear_extrude(height=x1 - x0)
        rotate([0,0,90]) union(){ circle(d=d, $fn=48); rotate(45) square(d/2); }
module Hinge_Holes(){
    // inner: seat, relief behind it (outer race contact ring)
    Teardrop_X(Brg_Seat_D, Brg_In_X0, Brg_In_X0 + Brg_B + 1);
    Teardrop_X(Brg_Relief_D, Brg_In_X0 - 0.6, Brg_In_X0 + Overlap);
    // outer: seat, relief, shaft hole through the wall
    Teardrop_X(Brg_Seat_D, Brg_Out_X1 - Brg_B - 1, Brg_Out_X1);
    Teardrop_X(Brg_Relief_D, Brg_Out_X1 - Overlap, R_In + Overlap);
    Teardrop_X(Wall_Hole_D, R_In - 1, R_Out + 1);
    // crank window: everything between the housings on the +Y side of the web
    intersection(){
        translate([Brg_In_X0 + Brg_B + 0.05, Web_Y[1], -1])
            cube([(Brg_Out_X1 - Brg_B) - (Brg_In_X0 + Brg_B) - 0.1, Crank_Tip_Y + 1.5 - Web_Y[1], Hinge_Z + Housing_D]);
        cylinder(r=R_In - 0.5, h=Can_L, $fn=192);    // never into the wall
    }
}

// servo bay: floor plate, two webs to the wall, lug pedestals with nut traps
module Servo_Bay(bat=false) Servo_Frame(){
    top = bat ? Bay_Top_A : Bay_Top;
    // floor; on the fin side it stops short of the horn ball and pushrod and
    // reaches the web only above the horn, with a 45 deg underside
    translate([Bay_Floor_X[0], Floor_Ly0, 0])
        cube([Bay_Floor_X[1] - Bay_Floor_X[0], Bay_Ly[1] - Floor_Ly0 + Bay_Web_T, top]);
    hull(){
        translate([Bay_Floor_X[0], Floor_Ly0 - Overlap, Floor_Bridge_Z]) cube([Bay_Floor_X[1] - Bay_Floor_X[0], Overlap, top - Floor_Bridge_Z]);
        translate([Bay_Floor_X[0], Bay_Ly[0], Floor_Bridge_Z + (Floor_Ly0 - Bay_Ly[0])])
            cube([Bay_Floor_X[1] - Bay_Floor_X[0], Overlap, top - Floor_Bridge_Z - (Floor_Ly0 - Bay_Ly[0])]);
    }
    // webs from the floor to the wall
    for (ly=[Bay_Ly[0], Bay_Ly[1]]) intersection(){
        translate([Bay_Floor_X[0], ly, 0]) cube([30, Bay_Web_T, top]);
        Fin_Inv() cylinder(r=R_In + Overlap, h=Can_L, $fn=192);
    }
    // spine on the floor face under both lugs, aft pedestal from the bed
    translate([Spine_X[0], Ped_Ly[0], 0]) cube([Spine_X[1] - Spine_X[0], Ped_Ly[1] - Ped_Ly[0], Ped_Z_Fwd[1]]);
    translate([Spine_X[1] - Overlap, Ped_Ly[0], Ped_Z_Aft[0]])
        cube([-Servo_Lug_T/2 - 0.05 - Spine_X[1] + Overlap, Ped_Ly[1] - Ped_Ly[0], Ped_Z_Aft[1]]);
    translate([Spine_X[1] - Overlap, Ped_Ly[0], Ped_Z_Fwd[0]])
        cube([-Servo_Lug_T/2 - 0.05 - Spine_X[1] + Overlap, Ped_Ly[1] - Ped_Ly[0], Ped_Z_Fwd[1] - Ped_Z_Fwd[0]]);
}
module Lug_Holes() for (z=Lug_Zs()){
    translate([2, Servo_Lug_Hole_Ly(), z]) rotate([0,-90,0]) cylinder(d=Lug_Bolt_D, h=12, $fn=20);
    // nut trap, opens toward the fin side (-ly) for insertion
    translate([Spine_X[0] + 0.4, Ped_Ly[0] - 1, z - Lug_Nut_AF/2 - 0.1])
        cube([Lug_Nut_T + 0.3, Servo_Lug_Hole_Ly() + Lug_Nut_AF/2/cos(30) + 0.2 - Ped_Ly[0] + 1, Lug_Nut_AF + 0.2]);
}
module Strap_Slots() for (z=[Lipo_Z0 + 12, Lipo_Z0 + Lipo[2] - 12 - Strap_Slot[1]])
    for (s=[-1,1]) translate([Bay_Floor_X[0] - 1, s*(Lipo[0]/2 + 1.5) - Strap_Slot[0]/2, z])
        cube([Bay_Floor_X[1] - Bay_Floor_X[0] + 2, Strap_Slot[0], Strap_Slot[1]]);

// aft rail button boss on the 60 deg line
module Rail_Boss() rotate([0,0,Rail_A]) intersection(){
    union(){
        translate([R_Out - Rail_Insert[1] - 2.1, 0, Rail_Aft_Z]) rotate([0,90,0])
            cylinder(d=Rail_Boss_D, h=Rail_Insert[1] + 3, $fn=48);
        translate([R_Out - Rail_Insert[1] - 2.1, -Rail_Boss_D/2, Rail_Aft_Z - Rail_Boss_D/2])
            cube([Rail_Insert[1] + 3, Rail_Boss_D, Rail_Boss_D/2]);
        hull(){
            translate([R_Out - Rail_Insert[1] - 2.1, -Rail_Boss_D/2, Rail_Aft_Z - Rail_Boss_D/2])
                cube([Rail_Insert[1] + 3, Rail_Boss_D, Overlap]);
            translate([R_In - 1, -Rail_Boss_D/2, Rail_Aft_Z - Rail_Boss_D/2 - (R_In - 1 - (R_Out - Rail_Insert[1] - 2.1))])
                cube([2, Rail_Boss_D, Overlap]);
        }
    }
    cylinder(r=R_In + Overlap, h=Can_L, $fn=192);
}
module Rail_Hole() rotate([0,0,Rail_A]) translate([R_Out - Rail_Insert[1], 0, Rail_Aft_Z])
    rotate([0,90,0]) cylinder(d=Rail_Insert[0], h=Rail_Insert[1] + 1, $fn=32);

// switch: keyed hole and a flat inner pad, nut seat Sw_Panel_T behind the skin
module Switch_Pad() rotate([0,0,Sw_A]) intersection(){
    union(){
        translate([R_Out - Sw_Panel_T, 0, Sw_Z]) rotate([0,90,0]) cylinder(d=Sw_Pad_D, h=Sw_Panel_T, $fn=48);
        translate([R_Out - Sw_Panel_T, -Sw_Pad_D/2, Sw_Z - Sw_Pad_D/2]) cube([Sw_Panel_T, Sw_Pad_D, Sw_Pad_D/2]);
        hull(){
            translate([R_Out - Sw_Panel_T, -Sw_Pad_D/2, Sw_Z - Sw_Pad_D/2]) cube([Sw_Panel_T, Sw_Pad_D, Overlap]);
            translate([R_In - 1, -Sw_Pad_D/2, Sw_Z - Sw_Pad_D/2 - (R_In - 1 - (R_Out - Sw_Panel_T))])
                cube([2, Sw_Pad_D, Overlap]);
        }
    }
    cylinder(r=R_In + Overlap, h=Can_L, $fn=192);
}
// printed Ø6 teardrop pilot; drill Ø12.7 and file the R1.2 key relief upward
// (13.6 overall) on assembly, as the nose switch. A printed Ø12.7 hole would
// put a 12.7 mm bridge in the wall.
module Switch_Hole() rotate([0,0,Sw_A]) translate([R_Out - Sw_Panel_T - 1, 0, Sw_Z]) rotate([0,90,0])
    linear_extrude(height=Sw_Panel_T + 2) rotate(180) union(){ circle(d=6, $fn=32); rotate(45) square(3); }

// ============================================
// PRINT POSES
// ============================================
// the cover prints standing, as it sits on the rocket (a curved vertical wall)
module TS_Hatch_Print(bat)
    translate([0,0,-(Hatch_Z[0] - Hatch_Rebate + Hatch_Gap)]) rotate([0,0,-Servo_Theta])
        Hatch_Cover(bat);
module TS_Crank_Print()
    translate([0,0,-Crank_X0]) rotate([0,-90,0]) translate([0,0,-Hinge_Z]) Crank(0);
// each half lies on its outer face, split face (with the groove) up
module TS_Aileron_Print(half)
    translate([0,0,Fin_T/2]) rotate([half > 0 ? -90 : 90, 0, 0]) Aileron_Half(half, 0);
// Drill jig for the dowel's cross hole: the shaft lies flat-down in a D-channel
// with its inner end on the stop; a vertical Ø2 guide sits Pin_X - Shaft_X0 from
// the stop, square to the flat and through the axis.
Jig_Pin_From_End = Pin_X - Shaft_X0;
module TS_Drill_Jig(){
    L = Shaft_L + 8; W = 14; H = 12; zc = 5;     // shaft axis height above the bed
    difference(){
        cube([L, W, H]);
        // D-channel, flat on the bottom, teardrop top (supportless), from the stop face at x = 4
        translate([4, W/2, zc]) rotate([0,90,0]) linear_extrude(height=L) rotate(90) union(){
            Shaft_Section(Shaft_D + 0.15, Shaft_Flat - 0.05);
            rotate(45) square((Shaft_D + 0.15)/2);       // teardrop tip up (after the outer rotate(90))
        }
        // guide: Ø2 drill, through the top to below the shaft
        translate([4 + Jig_Pin_From_End, W/2, -1]) cylinder(d=Pin_D + 0.1, h=H + 2, $fn=24);
    }
}
module TS_Coupon() intersection(){
    TS_Can();
    translate([MMT_Bore_R - 1, -9, 0]) cube([R_Out - MMT_Bore_R + 2, 15.8, Hinge_Z + Housing_D/2*sqrt(2) + 2]);
}

// ============================================
// ASSEMBLY PREVIEW
// ============================================
module TS_Assembly(){
    color("Gainsboro") TS_Can();
    for (k=[0:2]) Fin_Frame(k){
        color("BurlyWood") Fixed_Fin();
        color("Orange") Aileron(Defl);
        color("Silver") Shaft(Defl);
        color("DimGray") Bearings();
        color("SteelBlue") Crank(Defl);
        Servo_Frame(){ color("Black", 0.8) Servo_Envelope(); color("Silver") Horn_Envelope(); }
    }
    if ($preview){
        color("Tan", 0.3) Paper_Tube();
        color("Gray", 0.4) MMT();
        color("Red", 0.6) Lipo_Envelope();
    }
}

// ============================================
// ECHO (read by tools/verify_tailsteer.py and tools/tailsteer_estimate.py)
// ============================================
echo(str("TS_PARAMS ", R_Out, " ", R_In, " ", MMT_OD, " ", MMT_Z0, " ", MMT_L, " ",
         Hinge_Z, " ", Hinge_X, " ", Fin_Base_X, " ", Flap_Span, " ", Flap_Root_Gap, " ",
         Flap_Gap, " ", Flap_LE_R, " ", Shaft_D, " ", Shaft_X0, " ", Shaft_X1, " ",
         Brg_In_X0, " ", Brg_Out_X1, " ", Brg_B, " ", Brg_D, " ", Crank_A, " ", Horn_R, " ",
         Crank_Xk, " ", Servo_Theta, " ", Servo_Rc, " ", Servo_ZO, " ", Pushrod_L, " ",
         Horn_Ball_U, " ", Fin_T, " ", Can_L, " ", Total_H, " ", Rail_A, " ", Rail_Aft_Z, " ",
         Tube_Piece_L, " ", Ply_CR_Z0, " ", Flap_Max, " ", Sw_A, " ", Sw_Z, " ",
         Flap_X_Max, " ", Fixed_Aft_X(), " ", Lipo_Z0, " ", Lipo[2], " ", Ball_Off, " ",
         Horn_Arm_T, " ", Pin_D, " ", Pin_Z[0] - Pin_Z[1], " ", Clamp_Relief));
echo(str("TS_HATCH ", Hatch_U[0], " ", Hatch_U[1], " ", Hatch_Z[0], " ", Hatch_Z[1], " ",
         Hatch_Bat_U[0], " ", Hatch_Bat_U[1], " ", Hatch_Bat_Z1, " ", Hatch_Rebate, " ",
         Hatch_Rebate_Fin, " ", Fillet_Max));
echo(str("TS_CRANK ", Clevis_Gap, " ", Cheek_T, " ", Crank_Arm_H, " ", Link_Eye_W, " ",
         Crank_Win_Y[0], " ", Crank_Hub_D/2, " ", Crank_Arm_X1 - Crank_X0, " ", Pivot_D, " ",
         Pivot_L, " ", Pin_Z[0], " ", Web_Y[1] - Web_Y[0], " ", Hinge_Z + Housing_D/2*sqrt(2), " ",
         Shaft_Flat, " ", Cheek_T_In));
echo(str("TS_CLAMP ", Clamp_Screw_L, " ", Fin_T, " ", [for (c=Clamp_Screws) each Clamp_Pos(c)]));
echo(str("TS_SCREWS ", [for (s=Hatch_Screws(true)) each s], " | ", [for (s=Hatch_Screws(false)) each s]));
echo(str("PeregrineTailSteer 0.2.0: airframe ", Airframe, ", fin set ", Fin_Set, ", servo at ", Servo_Theta,
         " deg from its fin, crank ball r ", Crank_Xk, ", link ratio ", Link_Ratio,
         ", bearing spacing ", Brg_Spacing, ", shaft ", Shaft_L, " mm"));
