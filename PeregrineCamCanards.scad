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
// one Y-cabled signal deflects both in the same rotational sense: roll,
// without a reverser (stage 1, CATS ROLL_2). Stage 2 (FULL_4) drives the
// same four servos independently; nothing mechanical changes.
//
// Service: the four servos live on a removable cassette (part 9). With the
// shoulder unscrewed (8 radial M3; part 1 is no longer glued) the cassette
// slides out of the bottom. Canards come off from outside: two M2 screws
// each, then the arm's M2.5 centre screw.
//
// Servo: MKS HV6160 (thin wing servo). Geometry from the MKS dimension
// drawing (as published by MKS Servo Distribution Europe; mks-servo.com's
// own copy is not reachable from here). Details the drawing does not give
// -- lead stub, case-screw heads, the metal arm's hub and arm sizes -- are
// estimates. Measure a real servo and arm before printing: Servo_*, Horn_*.

// ============================================
// LAYOUT
// ============================================
Canard_A0 = 0;      // clocking of canard 1 (deg from +X); others at +90 each.
                    // Stage 2 needs these on the Vega board's transverse
                    // axes; see Index_Key_A. Keep the launch-rail line 45 deg
                    // off the canards: a canard on the rail line hits the rail.
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

// ============================================
// OUTPUT ARM (MKS short metal arm for the 5 mm output, M2.5 centre screw)
// and ROOT PLUG. The plug fits over the arm in a matching pocket and is
// held by two M2 countersunk screws into the arm: tap the arm's 9 mm hole
// and its 4.6 mm dimple M2 (1.6 mm drill). Arm sizes are ESTIMATES.
// ============================================
Horn_Hub_D    = 8;
Horn_Hub_H    = 4.8;    // above the arm's underside; covers spline and screw head
Horn_Arm_W    = 5.5;
Horn_Arm_T    = 2.5;
Horn_Arm_L    = 12;     // axis to arm tip
Horn_Holes_R  = [4.6, 9];
Horn_Gap      = 0.3;    // arm underside above the case top
Plug_X0       = Servo_Bottom_R + Servo_Case_H + Horn_Gap;   // plug inner face radius
Plug_Pocket_Clear = 0.1;
Plug_D        = 2*(Horn_Arm_L + 1.5);   // root plug, turns in a hole through the shell
Plug_Clear    = 0.3;    // radial; the plug never bears on the shell
Plug_Hole_R   = Plug_D/2 + Plug_Clear;
Plug_Screw_D  = 2.4;    // M2 clearance
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
// This joint now carries the recovery load: drogue snatch on the shoulder
// bulkhead -> spigot -> screws in shear -> skirt. A rough snatch estimate is
// ~1 kN; one M3 bearing on the countersunk 2.2 mm PETG skirt holds very
// roughly 0.2 kN, so eight. Fewer is the owner's call after a pull test.
Sh_Joint_A = [for(k=[0:7]) 22.5+45*k];   // clear of the canards and the key
Sh_Joint_Z = Shoulder_Spigot_L/2;     // assembled Z, middle of the spigot
Sh_Boss_D  = 9;
Sh_Spigot_R = Shoulder_Spigot_OD/2;
Sh_Boss_L  = Insert_Pocket_L + Bay_Screw_Tip_L/2 + 1;

// ============================================
// INDEX KEY (nose <-> body tube) and CABLE EXIT
// ============================================
// A key below the shell base engages a notch filed in the tube's forward
// rim, fixing the canard clocking to the airframe. Stage 2 also needs the
// tube -> coupler -> sled -> Vega chain fixed; that is outside this CAD.
Index_Key_Enabled = true;
Index_Key_A = Canard_A0;   // set so canard 1 lands on a Vega board axis
Index_Key_W = 6;
Index_Key_H = 6;
// Breakaway connector: the nose separates at apogee (drogue bay is nose to
// e-bay), so the servo harness must part there. Default: a panel connector
// in the shoulder bulkhead (stage 2 needs 4 signals + GND + 5 V = 6 pins);
// false gives a plain sealed grommet hole instead, with the split elsewhere.
Conn_In_Bulkhead = true;
Conn_A = Canard_A0;        // clear of the ribbon T-slots on +-Y
Conn_R = 28;
Conn_Cut = Conn_In_Bulkhead ? [14, 7] : [8, 8];   // W (tangential) x H (radial)

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
assert(Horn_Holes_R[0] - Plug_Screw_Head_D/2 > Canard_T/2 + 0.5, "inner plug screw head under the blade");
// The slot sector must clear the arm pocket (at 0 deg) and the blade root
// (at 90 deg). The arm itself passes the tab when fitted from outside.
assert(Stop_Tab_A - Stop_Slot_Half > asin((Horn_Arm_W/2+Plug_Pocket_Clear+1)/(Stop_Tab_Rin-Stop_Slot_Clear)) + 2,
       "stop slot cuts the arm pocket");
assert(Stop_Tab_A + Stop_Slot_Half < 90 - asin((Canard_T/2)/(Stop_Tab_Rin-Stop_Slot_Clear)) - 2,
       "stop slot cuts the blade root");
assert(Servo_Bottom_R + Servo_Spline_Top < CN_Inner_R(Cas_Floor_Top+1) - Hole_Ring_T - 0.5,
       "spline tip would hit the plug-hole ring while the cassette slides in");
assert(Plug_X0 < CN_Inner_R(Canard_Z) - Hole_Ring_T - 2,
       "case top too close to the shell: no room for the plug");
assert(Canard_Skin_R - (Plug_X0 + Horn_Gap + Horn_Hub_H + Plug_Pocket_Clear) >= 1.5,
       "plug too thin over the arm hub");
assert(Sh_Joint_Z + Sh_Boss_D/2 < Shoulder_Spigot_L, "joint boss off the spigot");

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
    hull(){
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
        }
        for(k=[0:3]) Canard_Frame(k) Canard_Hole_Cut();
        for(a=Sh_Joint_A) Countersunk_Radial(Canard_A0+a, Sh_Joint_Z);
        for(a=Cas_Screw_A) Countersunk_Radial(Canard_A0+a, Cas_Screw_Z);
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
    for(s=[-1,1]) translate([yw, s>0 ? yw : -yw-Cas_Wall, zf-Overlap])
        cube([xt-yw, Cas_Wall, zt-zf+Overlap]);
    // lug blocks beside the lug plates, beyond both case ends
    translate([xb,Cas_Lug_Y0,zf-Overlap]) cube([xt-xb,yw+Cas_Wall-Cas_Lug_Y0,zl-zf+Overlap]);
    // upper block: a ~4 mm ledge off the +y wall over the case end
    translate([xb,Cas_Lug_Y0,zu]) cube([xt-xb,yw+Cas_Wall-Cas_Lug_Y0,zt-zu]);
}
// Diamond lightening window in a side wall, between the lug blocks: its
// edges are at 45 deg, so the print needs no bridge.
module Cas_Wall_Window(){
    b = Servo_Bottom_R; yw = Servo_W/2+Cas_Clear;
    x0 = yw+3; x1 = b+Servo_Lug_Hole_X-Lug_Access_D/2-3;
    z0 = -Servo_Spline_Off+1; z1 = Servo_L-Servo_Spline_Off-1;
    d = min(x1-x0, z1-z0);
    for(s=[-1,1]) translate([(x0+x1)/2, s*(yw+Cas_Wall/2), (z0+z1)/2])
        rotate([90,0,0]) rotate([0,0,45]) cube([d/sqrt(2),d/sqrt(2),Cas_Wall+1],center=true);
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
        }
        for(k=[0:3]) Canard_Frame(k){ Cas_Lug_Cuts(); Cas_Wall_Window(); }
        // the four leads drop down the central channel through one hole
        rotate([0,0,Canard_A0]) translate([-Cas_Lead_Hole/2,-Cas_Lead_Hole/2,Cas_Floor_Z-1])
            cube([Cas_Lead_Hole,Cas_Lead_Hole,Cas_Floor_T+2]);
        for(a=Cas_Screw_A) Radial_Insert_Pocket(Canard_A0+a, rf, Cas_Screw_Z);
    }
}

// ============================================
// SHOULDER ADDITIONS (shoulder coordinates: assembled Z + Shoulder_L)
// ============================================
module Canard_Shoulder_Add(){
    zs = Shoulder_L + Sh_Joint_Z;
    rin = Sh_Spigot_R - NC_Wall_T;
    // insert bosses inside the spigot, gusseted down into the shoulder wall
    for(a=Sh_Joint_A) intersection(){
        hull(){
            Radial_At(Canard_A0+a, Sh_Spigot_R-0.3, zs) cylinder(d=Sh_Boss_D,h=Sh_Boss_L,$fn=48);
            Radial_At(Canard_A0+a, Shoulder_Bore_D/2+0.6, zs-Sh_Boss_D/2-(Sh_Boss_L-NC_Wall_T)*1.4)
                cylinder(d=2,h=1.2,$fn=24);
        }
        translate([0,0,zs-40]) cylinder(r=Sh_Spigot_R-0.3,h=40+Sh_Boss_D/2+1,$fn=180);
    }
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
    for(a=Sh_Joint_A) Radial_Insert_Pocket(Canard_A0+a, Sh_Spigot_R, zs);
    // harness exit through the bulkhead
    rotate([0,0,Conn_A]) translate([Conn_R-Conn_Cut[1]/2,-Conn_Cut[0]/2,-Overlap])
        cube([Conn_Cut[1],Conn_Cut[0],Shoulder_Bulk_T+2*Overlap]);
}

// ============================================
// ASSEMBLY VIEW (part 12) and check envelopes
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
    color([0.2,0.2,0.25]) CN_Canard_Servos();
    color([0.6,0.6,0.65]) CN_Canard_Horns();
    color([0.15,0.45,0.85]) CN_Canard_Units();
    color([0.78,0.79,0.81,0.5]) difference(){
        translate([0,0,-Shoulder_L]) CN_Shoulder();
        rotate([0,0,Canard_A0+45]) translate([-100,-100,-120]) cube([100,200,200]);
    }
}
