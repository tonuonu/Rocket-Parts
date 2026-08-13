// ***********************************
// Project: 3D Printed Rocket
// Filename: Rocket60.scad
// for Rocket 60 (60mm body, camera nosecone)
// by Tõnu Samuel
// Created: 2026-08-13
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Designed for Bambu P1S (256x256x256mm build volume, 250mm usable Z).
// Every printable part is selected with Render_Part below.
//
// Spec: docs/superpowers/specs/2026-08-13-rocket60-design.md
//
// ***********************************

include<R60Lib.scad>

// ============================================
// RENDER SELECTION - change this value!
// ============================================
//  0 = Test ring (PRINT THIS FIRST)
//  1 = Neck
//  2 = E-bay tube
//  3 = Chute bay tube
//  4 = E-bay forward bulkhead
//  5 = E-bay aft bulkhead
//  6 = Vega sled
//  7 = Access door
//  8 = Spring/ball-lock carrier
//  9 = Fin can
// 10 = Fin
// 11 = Motor retainer
// 12 = Motor spacer
// 13 = Tether latch
Render_Part = 0;

// 0 = G80T-14A (124mm), 1 = H182R-14A (203mm), 2 = H135W-14A (216mm)
Motor_Class = 0;

// ============================================
// PARTS
// ============================================

// Print this FIRST. It gauges three fits on one 10mm part:
//   1. flange OD flush against the nosecone base (no step, either way)
//   2. the 3x M3 bolt circle and its clocking against the camera inserts
//   3. the coupler spigot inside a printed body tube
// If any of the three is wrong, nothing downstream is worth printing.
//
// No counterbore: this face mates with nothing (it is inside the
// airframe), so a plain clearance hole is the real joint and the gauge
// must match it, or it stops testing what actually gets bolted.
module R60_TestRing(){
    H_flange = 4;
    H_spigot = 6;
    difference(){
        union(){
            cylinder(d=R60_Body_OD, h=H_flange);
            translate([0,0,H_flange-Overlap])
                cylinder(d=R60_Coupler_OD, h=H_spigot+Overlap);
        }
        // Open centre: the camera harness passes through here in the real
        // neck, so the gauge shares the same clear bore.
        translate([0,0,-Overlap])
            cylinder(d=28, h=H_flange+H_spigot+Overlap*2);
        R60_CameraBoltPattern()
            translate([0,0,-Overlap])
                cylinder(d=R60_Cam_Bolt_d, h=H_flange+H_spigot+Overlap*2);
    }
} // R60_TestRing

// The camera assembly fills the nosecone bore and sits flush with its base
// plane, so the neck cannot have a spigot - it is a butt joint. The three
// M3x10 SHCS pull it up into the camera's heat-set inserts; those screws
// and the flange face are the whole joint.
//
// No counterbore: the aft face (z=Flange_T) is inside the airframe and
// mates with nothing - the e-bay tube's end lands at r=28.4..30, clear of
// the r=18.98 bolt circle, so a screw head proud there touches nothing.
// Plain Ø3.4 through-holes give the full 5.0mm flange as grip under the
// head. M3x10 protrudes 10-5.0=5.0mm past the mating face, for 5.0mm of
// engagement in the camera's 5.7mm ruthex RX-M3x5.7 insert - does not
// bottom out.
//
// Load path: the shock cord anchors on the E-BAY AFT BULKHEAD, never here.
// These three screws only ever carry the nose section's own inertia.
module R60_Neck(){
    Flange_T = 5;      // grip under the screw head - see note above
    Skirt_L  = R60_Neck_Skirt_L;
    Bore_d   = 28;     // camera harness passes through
    difference(){
        union(){
            cylinder(d=R60_Body_OD, h=Flange_T);
            translate([0,0,Flange_T-Overlap])
                cylinder(d=R60_Coupler_OD, h=Skirt_L+Overlap);
        }
        translate([0,0,-Overlap])
            cylinder(d=Bore_d, h=Flange_T+Skirt_L+Overlap*2);
        // Thin the skirt so it is a tube, not a slug.
        translate([0,0,Flange_T])
            cylinder(d=R60_Coupler_OD-2*R60_Wall_T, h=Skirt_L+Overlap);
        R60_CameraBoltPattern()
            translate([0,0,-Overlap])
                cylinder(d=R60_Cam_Bolt_d, h=Flange_T+Overlap*2);
    }
} // R60_Neck

// E-bay tube with the access opening and the arming switch hole.
//
// The switch is NOT optional and NOT interchangeable with the door: the
// CATS manual requires the board be powered up only once the rocket is
// vertical on the pad, and disarming afterwards is only possible by
// powering off. So it must be reachable on the rail.
module R60_EBayTube(){
    Sw_d = 12;   // panel-mount toggle
    Door_Z0 = (R60_EBay_L - R60_Door_Open_H)/2;   // aperture bottom
    Door_Z1 = Door_Z0 + R60_Door_Open_H;          // aperture top
    // Arming switch Z, centred in the gap between the door's top edge and
    // the neck's skirt (which fills the tube's own top R60_Neck_Skirt_L
    // mm) -- DERIVED, not hand-picked, so it stays clear of both mating
    // parts even if EBay_L/door/skirt sizes change again. Was hardcoded at
    // EBay_L-18=142 (task report): that landed inside the skirt's
    // z=141..160 span, fouling the switch barrel and its inside retaining
    // nut, which also could not be tightened through the door as the
    // comment below requires.
    Sw_Margin = 3;   // clear of both the door top and the skirt start
    Sw_Z0 = Door_Z1 + Sw_Margin + Sw_d/2;
    Sw_Z1 = R60_EBay_L - R60_Neck_Skirt_L - Sw_Margin - Sw_d/2;
    Sw_Z  = (Sw_Z0 + Sw_Z1)/2;
    // Door boss positions -- R60_Door_Hole_Clear outside the aperture's
    // own edge on every side, matching R60_Door()'s own hole layout
    // exactly (both derived from the SAME R60Lib.scad constants) so the 4
    // screws always line up.
    Door_Hole_X = R60_Door_Open_W/2 + R60_Door_Hole_Clear;
    Door_Hole_Z = [Door_Z0 - R60_Door_Hole_Clear, Door_Z1 + R60_Door_Hole_Clear];
    // Boss stays FLUSH with the true OD (does not protrude past it): the
    // door cover's own inner face rests directly on R60_Body_OD, so a boss
    // proud of that would prop the cover up off the tube instead of
    // letting it seat flat (caught on an isolated probe: the boss's tip
    // read past the cover's own outer surface). Door_Boss_h instead
    // thickens the wall INWARD, into what is normally open bore, giving
    // the pilot hole real material to sit in without disturbing the
    // exterior surface the cover mates to.
    Door_Boss_d = 6;
    Door_Boss_h = 5;
    Door_Pilot_d = 2.0;  // self-tap pilot, M2.5 into PETG
    Door_Pilot_Depth = Door_Boss_h - 1.0;  // blind -- leaves 1mm backing
                                             // before the boss's own inward
                                             // limit
    // Boss azimuth: Door_Hole_X=21mm on a 30mm-radius tube is a real
    // angular offset (~44deg from straight +Y), not a small correction --
    // a boss built by simply offsetting X at a flat Y does not point along
    // the wall's actual local radial direction there and unions into the
    // curved OD only partially, leaving sliver gaps (confirmed by render:
    // a first draft this way read Genus 9, four MORE handles than
    // expected, one per boss/pilot pair -- CGAL was resolving those
    // slivers as real topology). Same "rotate for azimuth, then translate
    // along local +X = radial" idiom as R60_FinCan()'s bosses instead.
    function Door_Boss_Az(x) = acos(x/(R60_Body_OD/2));   // y>=0 (+Y side)
    // Vega sled retention rails: 2 ridges at the -Y wall (opposite the
    // door/switch at +Y), running nearly the tube's full length (see
    // Rail_Margin below), spaced to the sled's own width (R60_Vega_RailGap)
    // so its two long edges are captured between them -- fixes the sled's
    // radial position and stops it rotating about the tube axis. See
    // R60_VegaSled()'s module comment and R60Lib.scad's R60_Vega_Rail*
    // constants.
    //
    // Built in each rail's own ROTATED frame (same "rotate, then
    // translate along local +X = radial" idiom as R60_FinCan()'s bosses)
    // rather than raw (x,y) coordinates -- a flat XY offset does not sit
    // on the tube's curved wall at all except straight down the Y axis.
    //
    // Rail_HalfAng (defect 1b): the rail's own CAPTURING surface -- the
    // face that actually meets the sled -- is not at the tube ID. Each
    // rail cube starts at local X = R60_Body_ID/2-R60_Vega_RailH (see the
    // translate() below) and only reaches R60_Body_ID/2 to fuse invisibly
    // into the wall; the whole exposed, functional ridge sits
    // R60_Vega_RailH inward of the ID, at Rail_Inner_R. The old formula
    // used R60_Body_ID/2 for the asin(), sizing the angle for a chord that
    // only equals R60_Vega_RailGap way out at the ID -- at the smaller
    // radius the ridge actually occupies, that SAME angle subtends a
    // shorter chord (chord = 2*r*sin(angle) shrinks with r), so the
    // rendered capture gap came up short of the 44mm sled (measured on
    // render: 35.65mm between the two rails' facing corners, ~2.3mm play
    // instead of a captured fit -- confirmed on the rendered mesh, not
    // inferred from the parameter). The rail is also R60_Vega_RailW wide,
    // not an infinitely thin line, so each side eats R60_Vega_RailW/2 of
    // whatever chord the centreline spans before the FACING surfaces (the
    // ones the sled touches) are R60_Vega_RailGap apart. Solving
    // 2*Rail_Inner_R*sin(H) - R60_Vega_RailW*cos(H) = R60_Vega_RailGap for
    // H via the standard a*sinH - b*cosH = C*sin(H-phi) identity (C =
    // hypot(a,b), phi = atan(b/a)) gives both corrections in one closed
    // form -- verified against the rendered mesh (part 2's own rail
    // corners vs. part 6's own measured sled width) in
    // tools/verify_rocket60.py.
    Rail_Inner_R = R60_Body_ID/2 - R60_Vega_RailH;
    Rail_HalfAng = atan(R60_Vega_RailW / (2*Rail_Inner_R))
                 + asin(R60_Vega_RailGap
                        / sqrt((2*Rail_Inner_R)*(2*Rail_Inner_R)
                               + R60_Vega_RailW*R60_Vega_RailW));
    Rail_Overlap_R = 1.2;   // fuses into the wall without breaking its OD
    // Stop 5mm short of each end -- both so the tube's own base/top faces
    // stay a plain, unobstructed circle for every other part's mating
    // check that reads this tube's bore/OD near z=0 or z=EBay_L (a
    // full-length rail read as bore material there, corrupting those
    // checks -- caught by running verify_rocket60.py before this fix),
    // and because the sled (112mm) is shorter than the tube (160mm)
    // anyway and does not need the rails at the very tips.
    Rail_Margin = 5;
    // Zip-tie slots straddling the rails' mid-length -- cinch the sled
    // down against the rails so it cannot lift off them radially or slide
    // axially. 10mm x 3mm, a standard small zip tie, straight -Y (270deg,
    // centred between the two rails so one loop reaches both).
    Tie_Z = [R60_EBay_L/2 - 20, R60_EBay_L/2 + 20];
    difference(){
        union(){
            R60_Tube(R60_EBay_L);
            for (s=[1,-1])
                rotate([0,0,270+s*Rail_HalfAng])
                    translate([R60_Body_ID/2-R60_Vega_RailH, -R60_Vega_RailW/2, Rail_Margin])
                        cube([R60_Vega_RailH+Rail_Overlap_R, R60_Vega_RailW, R60_EBay_L-2*Rail_Margin]);
            // Door screw bosses -- local wall thickening on the INSIDE,
            // flush with the true OD, giving the 4 M2.5 screws real
            // material to thread into without propping the cover up off
            // the tube. See R60_Door()'s module comment for the retention
            // scheme these are half of.
            // Local $fn, same reasoning as R60_SpringCarrier()'s ball
            // pockets: a small 6mm boss gets no visible benefit from the
            // file-wide $fn=180, and at this odd azimuth (~45deg, not a
            // multiple of 90) the fine tessellation combined with the
            // rotate-translate-rotate composition produced a numerically
            // degenerate boolean -- confirmed on an isolated probe
            // (Genus jumped from the correct 1 to 5 at $fn=180, and back
            // to 1 at $fn=32, with the geometry otherwise identical).
            for (x=[-Door_Hole_X,Door_Hole_X], z=Door_Hole_Z)
                rotate([0,0,Door_Boss_Az(x)])
                    translate([R60_Body_OD/2-Door_Boss_h, 0, z])
                        rotate([0,90,0])
                            cylinder(d=Door_Boss_d, h=Door_Boss_h+Overlap, $fn=32);
        }
        translate([0,0,Door_Z0])
            translate([-R60_Door_Open_W/2,0,0])
                cube([R60_Door_Open_W, R60_Body_OD, R60_Door_Open_H]);
        // Door screw pilot holes, blind, open only at the true OD (where
        // the boss is flush) so the M2.5 screw enters through the cover's
        // own clearance hole straight into it. Local $fn -- see the boss
        // comment above.
        for (x=[-Door_Hole_X,Door_Hole_X], z=Door_Hole_Z)
            rotate([0,0,Door_Boss_Az(x)])
                translate([R60_Body_OD/2-Door_Pilot_Depth, 0, z])
                    rotate([0,90,0])
                        cylinder(d=Door_Pilot_d, h=Door_Pilot_Depth+Overlap, $fn=32);
        // Panel-mount arming switch, +Y, above the door aperture.
        //
        // Same side as the door on purpose: the retaining nut is tightened from
        // inside, and the door is the only hand access into the bore. A switch on
        // the opposite wall could not be fitted without cutting a second opening.
        //
        // Cuts ONE wall. A full-diameter cylinder on the axis would punch through
        // both and leave an open hole in the far side of the airframe.
        translate([0, R60_Body_OD/2, Sw_Z])
            rotate([90, 0, 0])
                cylinder(d=Sw_d, h=R60_Wall_T*3, center=true);
        // Zip-tie slots, straight through the -Y wall.
        for (tz=Tie_Z)
            rotate([0,0,270])
                translate([R60_Body_ID/2-1, -5, tz-1.5])
                    cube([R60_Wall_T*3, 10, 3]);
    }
} // R60_EBayTube

// Chute bay tube. Two shear pins bridge the REAL separable airframe joint
// here, at its forward rim, landing in the e-bay aft bulkhead's skirt
// (R60_EBayAftBulkhead) -- NOT in the spring carrier (part 8) -- so the
// ejection-charge backup shears them directly, independent of the
// ball-lock's state. See spec 4.2 and R60_EBayAftBulkhead()'s module
// comment for the placement rationale; R60_Pin_Z_FromJoint is shared with
// that module so one physical pin lines up through both parts.
//
// Spring reaction ring, added beyond the brief's literal file list
// (which named this file only for the pin holes) because without it the
// spring has nothing on the chute-bay side to push against -- it would
// release inside the carrier and go nowhere, which is exactly the kind of
// "measures right, does nothing" failure spec 4.2 rejected the bayonet
// for. 3 light tabs, not a solid disc, so the packed chute and shock cord
// still have a clear path aft. Positioned flush with where the carrier
// (part 8, bolted to the skirt) ends, so the spring transmits its full
// force the instant it releases with no unpowered runway -- see
// R60_SpringCarrier()'s module comment for the part 8 <-> tab handoff and
// why the plunger/lock-disk that would actually contact these tabs is a
// companion piece not modeled as its own part in this task.
//
// Tether tie-off (Task 8, spec 4.1): the tether's FIXED end anchors HERE,
// at the chute bay's forward rim -- this is NOT the shock cord, which
// anchors on the e-bay aft bulkhead and the fin can's forward centring
// ring and is never released; conflating the two leaves the aft section
// attached to nothing after main release. A small internal lug, not a
// hole through the outer wall, so the airframe's exterior stays clean.
// Positioned at R60_Tether_Az (+Y), the SAME azimuth as
// R60_EBayAftBulkhead()'s skirt channel and R60_SpringCarrier()'s
// counterbore notch, so the ~50mm cord has a continuous, unpinched path
// from this lug back to the latch (part 13) once assembled.
module R60_ChuteTube(){
    Pin_Z      = R60_Pin_Z_FromJoint;
    Stop_Z     = R60_Pin_Skirt_L + 65;   // skirt(15) + carrier(65) = the
                                          // "80mm end to lock balls" figure
                                          // the investigation sourced from
                                          // SpringThing2.scad for this
                                          // spring/mechanism class
    Stop_T     = 3;
    // Tab inner radius: was 46 ("clears the carrier's own 44.8mm spring
    // bore"), which cleared the WRONG thing -- the carrier's bore never
    // needs to pass this Z (the tabs sit flush with where the carrier
    // itself ends, so its OD never travels through here), and the actual
    // spring (OD 44.30/ID 40.50, r 20.25..22.15) missed the tabs by
    // 0.6-0.85mm radially, so it never touched them. Sized instead so the
    // tab's inner radius (20mm) sits inside the spring's own coil band,
    // guaranteeing genuine contact regardless of the coil's exact winding
    // angle. See task report; a real check for this is in
    // verify_rocket60.py (radial overlap, not just that both exist).
    Stop_ID    = 40;
    nStopTabs  = 3;
    Tab_W      = 8;     // chord width, small vs. the radius -- a flat cube
                         // is an adequate approximation of the arc here
    // Tether tie-off lug -- W/D/H/Z shared with R60Lib.scad's
    // R60_TetherLug_* so R60_EBayAftBulkhead()'s relief notch is always
    // derived from the SAME footprint, not a hand-matched copy (task
    // report: a first draft let the two drift 0.8mm into interference).
    Tie_W = R60_TetherLug_W; Tie_D = R60_TetherLug_D;
    Tie_H = R60_TetherLug_H; Tie_Z = R60_TetherLug_Z;
    difference(){
        union(){
            R60_Tube(R60_Chute_L);
            // Spring reaction tabs, inward from the tube wall.
            for (i=[0:nStopTabs-1])
                rotate([0,0,i*360/nStopTabs])
                    translate([-Tab_W/2, Stop_ID/2, Stop_Z])
                        cube([Tab_W, R60_Body_ID/2-Stop_ID/2, Stop_T]);
            // Tether tie-off lug, +Y, well clear of the +-X pin holes and
            // the aft-most stop tabs.
            translate([-Tie_W/2, R60_Body_ID/2-Tie_D, Tie_Z])
                cube([Tie_W, Tie_D, Tie_H]);
        }
        // Shear pin holes, +-X (matching R60_EBayAftBulkhead()'s skirt
        // pins), straight through the tube wall -- same idiom as the
        // door-opening/switch-hole cuts elsewhere in this file.
        for (s=[1,-1])
            translate([s*R60_Body_OD/2, 0, Pin_Z])
                rotate([0,90,0])
                    cylinder(d=R60_Pin_d, h=R60_Wall_T*3, center=true);
        // Lashing hole through the tie-off lug, along X, for the tether
        // cord to loop through.
        translate([-Tie_W/2-Overlap, R60_Body_ID/2-Tie_D/2, Tie_Z+Tie_H/2])
            rotate([0,90,0])
                cylinder(d=3.0+IDXtra, h=Tie_W+Overlap*2);
    }
} // R60_ChuteTube

// Forward bulkhead: closes the top of the e-bay, passes the camera harness.
module R60_EBayFwdBulkhead(){
    T = 6;
    difference(){
        cylinder(d=R60_Coupler_OD, h=T);
        translate([0,0,-Overlap]) cylinder(d=22, h=T+Overlap*2);
    }
} // R60_EBayFwdBulkhead

// Aft bulkhead. THE structural part of the recovery system: the shock cord
// anchors here so deployment snatch never reaches the camera's three M3
// screws. Also carries both servos and passes their output aft.
//
// Servos stand UPRIGHT, shafts along the rocket axis, per
// PeregrineEjection.scad. Servo 1 is on the centreline; its shaft now
// drives the spring carrier's (part 8) ball-lock release, not a bayonet
// ring -- see R60_SpringCarrier()'s module comment (spec 4.2 superseded
// the cam bayonet: rotate_extrude cannot cam, and a servo must never be
// the structural element holding the airframe together). Servo 2 sits
// beside it and drives the tether latch (part 13) through a slot. A radial
// layout is impossible: drive bore r=6 to disc edge r=28.2 is 22.2mm, an
// MG90S body is 22.8mm long.
//
// The MG90S output shaft is 5.5mm off the body centre, so servo 1's body
// is offset by that much to put its SHAFT on the axis, not its body.
//
// AFT SKIRT -- the shear-pin joint. The original 12mm disc glues inside
// the e-bay tube and carries nothing that reaches the chute bay. This
// task adds a solid skirt (T..T+R60_Pin_Skirt_L) that projects aft, past
// the e-bay tube's cut end, into the chute bay tube's forward bore
// (56.4mm OD, same 0.4mm-clearance convention as every internal part in
// this repo). Two shear pins land radially in this skirt's solid
// material, R60_Pin_Z_FromJoint past its start -- the SAME offset
// R60_ChuteTube() uses, measured from its own forward rim, so one
// physical pin bridges BOTH parts once the chute tube is slid over the
// skirt. This is the whole point of the redesign (spec 4.2): the pins tie
// the chute tube directly to this bulkhead, so the ejection-charge backup
// shears them regardless of whether the ball-lock (part 8, glued to this
// skirt's aft face, entirely downstream of the pins) has released. Pins
// placed only in the spring carrier would leave the charge fighting the
// ball-lock detent instead -- exactly the failure mode spec 4.2 warns
// against.
//
// The servo 1 shaft bore, the servo 2 horn slot, and the shock cord holes
// all now run the full T + Skirt_L depth (previously just T) so they stay
// open passages all the way to the new aft face: the shaft bore reaches
// part 8's ball-lock; the horn slot reaches the tether latch (part 13,
// Task 8), which mounts on this bulkhead's aft face -- if the horn slot
// stopped at the original T=12 disc face, the new skirt would seal it
// into a blind pocket and servo 2 would drive nothing (found by render:
// genus dropped 4->3 after the skirt was added but before this fix,
// confirmed on a sliced side-profile diagnostic that the slot dead-ended
// under solid skirt material); the cord holes so the shock cord still
// threads through into the chute bay.
module R60_EBayAftBulkhead(){
    T         = 12;
    Skirt_L   = R60_Pin_Skirt_L;
    Total_H   = T + Skirt_L;
    P_L       = 23.0 + IDXtra;   // MG90S body footprint
    P_W       = 12.2 + IDXtra;
    P_D       = 9;               // pocket depth; leaves 3mm of aft material
    Shaft_d   = 12;              // servo 1 output -> spring carrier ball-lock
    Horn_W    = 9;               // servo 2 horn slot
    Horn_L    = R60_Horn_L;
    S_Off     = 5.5;             // MG90S shaft offset from body centre
    S2_Y      = 13.6;            // 1.2mm pocket wall (3 perimeters @ 0.4mm nozzle)
    Cord_d    = 5;
    Pin_Z     = T + R60_Pin_Z_FromJoint;
    Pin_Depth = 10;               // blind hole -- purchase into the skirt,
                                   // not a full diametral pass-through
    // Midpoint radius for a center=true cylinder so the SAME expression
    // works mirrored at +-X: spans [R60_Coupler_OD/2-Pin_Depth,
    // R60_Coupler_OD/2+Overlap], i.e. from Pin_Depth inside the skirt to
    // just past its outer surface (clean boolean cut), on either side.
    Pin_R_Mid = R60_Coupler_OD/2 - Pin_Depth/2 + Overlap/2;
    difference(){
        union(){
            cylinder(d=R60_Coupler_OD, h=T);
            translate([0,0,T-Overlap])
                cylinder(d=R60_Coupler_OD, h=Skirt_L+Overlap);
        }

        // servo 1 pocket, opens forward
        translate([-S_Off - P_L/2, -P_W/2, -Overlap])
            cube([P_L, P_W, P_D + Overlap]);
        // servo 1 shaft bore -> the ball-lock drive, all the way to the
        // new aft face (through the original disc AND the skirt)
        translate([0, 0, P_D - Overlap])
            cylinder(d=Shaft_d, h=Total_H - P_D + Overlap*2);

        // servo 2 pocket, offset in +Y
        translate([-S_Off - P_L/2, S2_Y - P_W/2, -Overlap])
            cube([P_L, P_W, P_D + Overlap]);
        // servo 2 horn slot -> the tether latch (part 13), all the way to
        // the new aft face (see module comment -- this must match the
        // shaft bore's treatment or it seals shut under the skirt)
        translate([-Horn_L/2, S2_Y - Horn_W/2, P_D - Overlap])
            cube([Horn_L, Horn_W, Total_H - P_D + Overlap*2]);

        // Shock cord anchor: two axial holes on the -Y side, clear of both
        // servos, now extended the full Total_H so the cord still reaches
        // the chute bay through the skirt.
        for (x=[-6, 6])
            translate([x, -22, -Overlap])
                cylinder(d=Cord_d, h=Total_H + Overlap*2);

        // Shear pins, +-X (clear of the on-axis shaft bore and the -Y
        // cord holes), blind into the skirt's solid material.
        for (s=[1,-1])
            translate([s*Pin_R_Mid, 0, Pin_Z])
                rotate([0,90,0])
                    cylinder(d=R60_Pin_d, h=Pin_Depth+Overlap, center=true);

        // Tether latch (part 13) mounting inserts -- ruthex RX-M3x5.7,
        // same convention as R60_FinCan()/R60_MotorRetainer(). X offset is
        // R60_TetherLatch_HoleX (R60Lib.scad), DERIVED to clear the horn
        // slot's own half-length plus a stated wall -- was hardcoded at
        // +-11mm (task report), which put ~80% of each Ø4 bore inside the
        // horn slot's own void (only ~2.5mm^2 of a 12.6mm^2 bore was
        // solid), so the insert had almost nothing to grip and the latch
        // could not be mounted. Y stays at R60_Tether_Y (under servo 2's
        // horn) so servo 2 can still actually drive the latch it mounts.
        for (x=[-R60_TetherLatch_HoleX, R60_TetherLatch_HoleX])
            translate([x, R60_Tether_Y, Total_H-6.7])
                cylinder(d=R60_TetherInsert_d, h=6.7+Overlap);

        // Tether relief channel through the skirt's OD at R60_Tether_Az
        // (+Y) so the cord isn't pinched in the ~0.2mm nominal clearance
        // to the chute tube's ID as it runs from the latch (mounted here)
        // forward to its tie-off on R60_ChuteTube()'s forward rim -- a
        // matching notch continues this through R60_SpringCarrier()'s
        // counterbore rim. See R60Lib.scad's R60_Tether_Y/Az comment.
        //
        // Width/depth are DERIVED from R60_ChuteTube()'s tether lug
        // (R60_TetherLug_W/D) plus R60_Tether_Clear, not hand-matched --
        // task report: a first draft cut this to exactly the lug's own
        // 8mm width (zero clearance) and only 3mm deep (the lug reaches
        // 4mm past the tube's own ID, so it landed 0.8mm proud into solid
        // skirt material with zero width clearance either side -- the
        // joint could not close).
        Tether_Notch_W = R60_TetherLug_W + 2*R60_Tether_Clear;
        Tether_Notch_MinR = R60_Body_ID/2 - R60_TetherLug_D - R60_Tether_Clear;
        translate([-Tether_Notch_W/2, Tether_Notch_MinR, T-Overlap])
            cube([Tether_Notch_W, R60_Coupler_OD/2-Tether_Notch_MinR+Overlap, Skirt_L+Overlap*2]);
    }
} // R60_EBayAftBulkhead

// CATS Vega sled. Manual sec 4.3.3: mounting holes are 60 x 27mm apart,
// M3, and spacers are recommended so nothing touches the board.
//
// Orientation matters: the GNSS patch antenna must face RADIALLY OUTWARD
// with no battery, loom or metal between it and the airframe wall. Mark
// the antenna side on the print.
//
// RETENTION (task report): this plate used to have no attachment feature
// at all -- free to slide the full 142mm clear span inside the e-bay tube
// and rotate about the tube axis, which also defeats the antenna-outward
// requirement above (nothing keeps the marked side facing out once it can
// rotate). R60_EBayTube() now cuts 2 rails running nearly its full length
// at the -Y wall (R60_Vega_RailGap apart, matching this plate's own W
// below) that capture the plate's two long edges -- slide this sled in lengthwise
// from either end of the tube, then cinch it down with 2 zip ties through
// the tube's zip-tie slots. That fixes both the sliding/rotating defect
// and locks in whichever face was marked as the antenna side.
module R60_VegaSled(){
    T = R60_Vega_Sled_T;
    L = R60_Vega_L + 12;
    W = R60_Vega_Sled_W;
    // Mounting holes are M3 (R60Lib.scad: "L-shaped M3 pattern"). Was
    // Ø2.9 -- tap-drill size, same defect class as the tether latch's
    // original holes (task report): the M3 standoff screw would thread
    // the sled instead of clamping it. Now Ø3.4, matching the M3
    // clearance convention used everywhere else in this file
    // (R60_Cam_Bolt_d, R60_MotorRetainer()'s Bolt_d, R60_TetherLatch()'s
    // mounting holes).
    Hole_d = 3.4;
    difference(){
        union(){
            translate([-W/2, -L/2, 0]) cube([W, L, T]);
            for (h=R60_Vega_Holes)
                translate([h[0], h[1], T-Overlap])
                    cylinder(d=7, h=R60_Vega_Standoff_h+Overlap);
        }
        for (h=R60_Vega_Holes)
            translate([h[0], h[1], -Overlap])
                cylinder(d=Hole_d, h=T+R60_Vega_Standoff_h+Overlap*2);
    }
} // R60_VegaSled

// Curved door COVER, 4x M2.5. Overlaps the tube's opening (cut in
// R60_EBayTube()) on all 4 sides and rests against the tube's own outer
// surface -- a real ledge, not a loose plug.
//
// RETENTION (task report): this used to be a flush PLUG, 0.35mm smaller
// than the opening on every side and matching the wall's own thickness --
// nothing behind its screw holes but open air, and nothing stopping the
// panel from dropping straight through the 0.35mm gap into the bay. A
// plug sized smaller than its own hole cannot be fixed without adding a
// retaining feature to one of the two parts, so this is now a COVER,
// deliberately larger than R60_EBayTube()'s opening on every side
// (R60_Door_Overlap) so it always rests on solid tube material regardless
// of print tolerance, with 4 screws landing R60_Door_Hole_Clear outside
// the opening's own edge -- into real material, not the open aperture.
module R60_Door(){
    Cover_W = R60_Door_Open_W + 2*R60_Door_Overlap;
    Cover_H = R60_Door_Open_H + 2*R60_Door_Overlap;
    T = 2.0;    // cover shell thickness
    Hole_X = R60_Door_Open_W/2 + R60_Door_Hole_Clear;
    Hole_Z = [R60_Door_Overlap - R60_Door_Hole_Clear,
              R60_Door_Overlap + R60_Door_Open_H + R60_Door_Hole_Clear];
    // Hole azimuth on the R60_Body_OD/2 circle, y>=0 side -- SAME function
    // as R60_EBayTube()'s Door_Boss_Az(x), which this must match exactly
    // (both derived from the identical Hole_X). Needed because a screw
    // hole through a CURVED shell has to be bored along the wall's own
    // local radial direction, not a flat axis (defect 1a): the previous
    // `translate([x,0,z]) rotate([90,0,0])` bored straight along global Y
    // at a fixed X, which only agrees with the true radial line at
    // r=R60_Body_OD/2 and diverges further out -- at this cover's own
    // outer face (r=R60_Body_OD/2+T) the old hole centred on x=21 while
    // the tube's boss/pilot axis at that azimuth needs x=22.4 there, about
    // 1.3mm of solid cover material short of clearing an M2.5 shank
    // (confirmed by measuring both on the rendered mesh). Fixed with the
    // same "rotate for azimuth, then translate along local +X = radial"
    // idiom R60_EBayTube() already uses correctly for its bosses.
    function Hole_Az(x) = acos(x/(R60_Body_OD/2));
    difference(){
        intersection(){
            difference(){
                cylinder(d=R60_Body_OD+2*T, h=Cover_H);
                translate([0,0,-Overlap])
                    cylinder(d=R60_Body_OD, h=Cover_H+Overlap*2);
            }
            translate([-Cover_W/2, 0, 0])
                cube([Cover_W, R60_Body_OD, Cover_H]);
        }
        // Radial cut through the cover shell only (R60_Body_OD/2-Overlap
        // .. R60_Body_OD/2+T+Overlap), on the true local radial axis at
        // this hole's azimuth -- see Hole_Az() comment above. Local $fn,
        // same reasoning as R60_EBayTube()'s boss/pilot cuts (odd azimuth,
        // not a multiple of 90deg, produced a numerically degenerate
        // boolean at the file-wide $fn=180).
        for (x=[-Hole_X,Hole_X], z=Hole_Z)
            rotate([0,0,Hole_Az(x)])
                translate([R60_Body_OD/2-Overlap, 0, z])
                    rotate([0,90,0])
                        cylinder(d=2.7, h=T+2*Overlap, $fn=32);
    }
} // R60_Door

// Spring/ball-lock carrier. Primary separation path (spec 4.2): servo 1
// releases a ball-lock, freeing a CS4323 spring (OD 44.30/ID 40.50, free
// 200/coil-bound 22mm) that drives the sections apart hard enough to
// shear the two pins in R60_ChuteTube()/R60_EBayAftBulkhead()'s skirt.
// THE independence property (spec 4.2's whole reason for replacing the
// cam bayonet) lives in those pins bridging the real joint, not in
// anything below -- see those two modules' comments. This carrier only
// needs to hold and release a spring; it is not in the pins' load path.
//
// LIBRARY REUSE, and why this is hand-built rather than `use<>`-included:
// The repo's real ball-lock family (SpringThingBooster.scad's
// STB_BallRetainerTop/Bottom) is parametric on Body_ID, but its own
// sizing functions don't fit here -- STB_BallPerimeter_d(56.8) computes
// 60.2mm with STB_LockBall_d(56.8)=9.5mm balls, both LARGER than this
// carrier's 56.4mm OD. That isn't a rounding gap: STB's balls grip a
// groove on the OUTSIDE of a mating tube-end (the joint IS the ball-lock),
// which needs a wall this size doesn't have and isn't this design's
// architecture anyway (see below). Its full printable module also pulls
// in TubesLib/SG90ServoLib/LD-20MGServoLib/BatteryHolderLib/
// CommonStuffSAEmm via `use<>`/`include<>` -- none of which Rocket60.scad
// otherwise references -- for hardware (MR84 bearings, magnets, dowel
// pins) sized for a bigger mechanism. CableReleaseBBMini.scad's release
// catch is proven at this scale (~6-7mm radial margin per the
// investigation) but is ~14 SEPARATE printed parts for one working
// catch (lock ring, top retainer, 2 bearing retainers, magnet bracket,
// trigger post, spring end...), not the one part this task allocates.
//
// So: this carrier reuses the CS4323 spring's dimensions (R60Lib.scad,
// sourced from SpringEndsLib.scad) and adapts the CableRelease family's
// SMALLER topology -- a central plunger held by a few small balls in a
// fixed hub, released by a rotating lock ring -- at a hand-picked size
// that fits this bore (Ball_d/Ball_BCd below), instead of STB's grip-the-
// mating-tube pattern. This is "built the equivalent", not the real
// family, and it is deliberately incomplete: the ROTATING LOCK RING and
// the SLIDING PLUNGER/spring cap are, by mechanical necessity, NOT part
// of this monolithic print (a rotating part and a printed housing cannot
// be one piece) and are NOT modeled as their own parts in this task. What
// is modeled is the fixed housing: the mounting rim, the pressure
// diaphragm, the ball pockets, and the spring bore. A working release
// still needs those two companion pieces (plus the balls, hardware) built
// and given their own part numbers before this is flight-complete -- see
// the task report.
//
// PRESSURE SEAL. Part 5's servo shaft bore and horn slot are open
// passages from its aft face into the e-bay. Uncapped, the backup
// ejection charge would leak through them into the e-bay instead of
// building pressure against the shear-pin joint. This carrier's forward
// diaphragm closes both (down to a small Drive_d clearance for the
// unmodeled lock ring's driveshaft), so the pressurized volume is bounded
// by real structure on the way to the pins, not by two open holes.
//
// FORWARD COUNTERBORE -- added so this carrier and the tether latch
// (part 13, Task 8, which mounts on this same aft face per its brief)
// don't physically compete for it: a caught-before-release defect, see
// the task report. Widens the mating rim to CB_D=51mm for CB_Depth=17mm
// (latch height 16mm + 1mm clearance) before stepping down to the
// 44.8mm spring bore, so the latch's posts recess into this carrier
// instead of colliding with its own forward wall. This is why the
// diaphragm/ball-pocket stack below is offset by CB_Depth, not at z=0 --
// the "plain tube rim" that glues to R60_EBayAftBulkhead()'s skirt is
// still there, it is just CB_D wide instead of Bore wide for the first
// CB_Depth of its length. Costs cocked-spring room (~35mm remaining,
// down from ~55mm) -- record under spec A11 with the rest of the
// undocumented spring-force risk; trimming a spring's usable length is
// normal, but only the physical spring settles whether it still clears
// the pins' target load in that space.
//
// SHOCK CORD PASSAGE. Part 5's two Ø5 axial cord holes reach ITS aft
// face (Task 7 fix), but this carrier sat directly in their path with no
// through-feature of its own -- a second defect caught by the same
// review before it shipped. Cord_x/Cord_y below match part 5's cord hole
// centres exactly (+-6, -22) so the two channels are collinear once
// glued together. Because that radius (22.8mm) straddles the bore's own
// edge (22.4mm), the cut is a GROOVE open to the bore, not a fully
// enclosed hole -- confirmed on render, see the task report. It is a
// small, permanent gap in an otherwise sealed pressure boundary (~10mm^2
// each); acceptable at vent-hole scale but worth stating plainly rather
// than silently absorbing into "the seal is closed" -- the ejection
// charge sizing already needs ground testing regardless (A11).
//
// z=0 (this module's base) is a plain tube rim -- OD=Coupler_OD,
// bore=CB_D -- so it glues flush against R60_EBayAftBulkhead()'s skirt
// aft face (same OD, same convention as every internal part in this
// repo). The diaphragm sits well inboard of that rim, not at it. A
// notch through that rim at R60_Tether_Az (+Y) continues the tether's
// relief channel from the skirt into the counterbore -- see
// R60_ChuteTube()'s module comment for the tether's fixed end.
module R60_SpringCarrier(){
    OD      = R60_Coupler_OD;      // 56.4 -- 0.4mm clearance in the chute
                                    // tube's 56.8mm bore, same convention
                                    // as every internal part in this repo
    Bore    = R60_Spring_OD + 0.5;  // 44.80 -- clears the CS4323's 44.30mm OD
    L       = 65;                   // + the skirt's 15mm = 80mm, the
                                     // "SpringThing2" figure sourced above
    CB_D      = 51;                 // tether latch (part 13) clearance --
    CB_Depth  = 17;                 // latch height 16mm + 1mm margin
    Dia_Z   = CB_Depth + 3;         // diaphragm recessed from the step
    Dia_T   = 3;
    Drive_d = 8;                    // clearance for the (unmodeled) lock
                                     // ring's driveshaft from servo 1
    Ball_d   = 4.0;                 // sized to fit THIS wall: (OD-Bore)/2
                                     // = 5.8mm, so STB's 9.5mm ball (see
                                     // module comment) cannot be used here
    Ball_BCd_In  = Bore - Ball_d + 1.0;   // pocket's inner (locked) extent
    // Pocket's outer (retracted) extent, derived from a stated minimum
    // printable wall rather than an arbitrary "-1.0" -- that left only
    // OD/2 - (Ball_BCd_Out/2 + (Ball_d+2*IDXtra)/2) = 0.3mm of wall past
    // the pocket's widest point (task report), below one 0.4mm extrusion
    // width: the slicer either drops the skin (balls escape) or bulges
    // the sealing surface. Ball_Wall_Min sets the floor explicitly.
    Ball_Wall_Min = 1.3;
    Ball_BCd_Out = OD - Ball_d - 2*IDXtra - 2*Ball_Wall_Min;
    Ball_Z   = Dia_Z + Dia_T + 6;
    nBalls   = 3;
    Cord_d   = 5;                   // matches R60_EBayAftBulkhead()'s Cord_d
    Cord_x   = 6;                   // matches its cord hole centres exactly
    Cord_y   = -22;                 // (+-6, -22), so the passages line up

    difference(){
        union(){
            difference(){
                cylinder(d=OD, h=L);
                translate([0,0,-Overlap]) cylinder(d=CB_D, h=CB_Depth+Overlap);
                translate([0,0,CB_Depth-Overlap])
                    cylinder(d=Bore, h=L-CB_Depth+Overlap*2);
            }
            // Diaphragm floor -- the pressure seal, and the spring's
            // forward seat.
            translate([0,0,Dia_Z]) cylinder(d=Bore, h=Dia_T);
        }
        // Driveshaft clearance (also passes through the already-open
        // counterbore and transition stub ahead of the diaphragm --
        // no-op there, real cut is through the diaphragm itself).
        translate([0,0,-Overlap])
            cylinder(d=Drive_d, h=Dia_Z+Dia_T+Overlap*2);
        // Shock cord channels -- full length, so the cord threaded
        // through R60_EBayAftBulkhead()'s cord holes continues straight
        // through this carrier into the chute bay. Grooves, not enclosed
        // holes, since Cord_x/y's radius (22.8mm) is just past the bore's
        // own edge (22.4mm) -- see module comment.
        for (s=[1,-1])
            translate([s*Cord_x, Cord_y, -Overlap])
                cylinder(d=Cord_d, h=L+Overlap*2);
        // Tether relief notch through the forward rim (the OD-to-CB_D
        // annulus, the only material at z=0 outside the already-open
        // counterbore), at R60_Tether_Az (+Y) matching
        // R60_EBayAftBulkhead()'s skirt channel exactly, so the cord
        // continues straight from the skirt into this carrier's
        // counterbore where the latch (part 13) sits.
        translate([-4, CB_D/2-0.5, -Overlap])
            cube([8, OD/2-CB_D/2+1, 5+Overlap]);
        // Ball pockets: radial slots through the wall so a ball can travel
        // from fully engaged (inner) to retracted (outer), same hull-of-
        // two-spheres pattern as SpringThingBooster.scad's
        // STB_BallRetainerBottom, resized to this carrier's wall. Each
        // pocket's LOCAL position (translate([0,r,z]) below) already sits
        // at azimuth 90deg before this rotate, so landing them at final
        // azimuths 60/180/300deg (clear of the cord channels at
        // ~255-285deg) needs rotate angles of that MINUS 90 -- a first
        // draft used the target azimuths directly as the rotate angle,
        // which actually placed one pocket at 270deg, dead in the cord
        // sector (caught on render: genus 3 instead of the expected 1,
        // and a merged shape visible on a horizontal section slice).
        for (i=[0:nBalls-1]) rotate([0,0,-30+i*360/nBalls])
            hull(){
                // Local $fn: a UV-sphere's facet count grows with $fn^2, so
                // 6 spheres at the file-wide $fn=180 balloon this part's
                // mesh to 10s of MB for no visible benefit on a 4mm ball
                // pocket -- SpringThingBooster.scad's own $fn=90 exists for
                // the same reason. 32 is still smooth at this size.
                translate([0, Ball_BCd_In/2, Ball_Z]) sphere(d=Ball_d+IDXtra*2, $fn=32);
                translate([0, Ball_BCd_Out/2, Ball_Z]) sphere(d=Ball_d+IDXtra*2, $fn=32);
            }
    }
} // R60_SpringCarrier

// Fin can. 228mm because the longest 29mm H DMS (H135W) is 216mm - NOT
// because the G80T needs it. The G80T is 124mm and flies on a spacer.
// This is what makes the rocket H-ready without a reprint.
module R60_FinCan(){
    Ring_T   = 3;
    // Width already got IDXtra; a line-to-line fit lengthwise over 90mm is
    // not assemblable (layer bulge/elephant's foot/print scaling and the
    // fin won't enter, or splits the wall going in). The fin is epoxied in,
    // so a slip fit costs nothing - add IDXtra clearance at each end too.
    Slot_L   = R60_Fin_Root + 2*IDXtra;
    Slot_Z   = 8 - IDXtra;
    // Retainer bolt circle: sits in the open annulus between the MMT
    // (r=R60_MMT_OD/2=16) and the body ID (r=R60_Body_OD/2-R60_Wall_T=28.4),
    // offset 60deg from the fins (0/120/240) so the 3 bolts land between
    // the fins, not through them.
    Boss_BC_R = 24;
    Boss_d    = 8;      // >= 4.0 insert hole + 2x1.6 min wall (ruthex RX-M3x5.7)
    Boss_h    = 9;       // reaches/merges into the aft centering ring (z=6..9)
    Insert_d  = 4.0;     // ruthex RX-M3x5.7 hole per datasheet
    Insert_h  = 6.7;     // datasheet: insert L(5.7) + 1mm
    // Shock cord anchor (task report, spec 4.1): the forward centring
    // ring is where the permanent shock cord ties off on the aft
    // section's end -- without a real anchor feature here, nothing holds
    // the aft section (chute bay + fin can + motor) after separation. Two
    // axial Ø5 holes, same size/spacing convention as
    // R60_EBayAftBulkhead()'s own cord holes (Cord_d, +-6mm), through the
    // FORWARD ring only, at -Y -- clear of all 3 fin slots (0/120/240deg)
    // and solidly inside the ring's own annulus (MMT_OD/2=16.15 ..
    // Body_ID/2=28.4).
    FwdRing_Z = R60_FinCan_L - Ring_T - 6;
    Cord_d    = 5;
    Cord_R    = 22.5;
    difference(){
        union(){
            R60_Tube(R60_FinCan_L);
            // MMT
            difference(){
                cylinder(d=R60_MMT_OD, h=R60_FinCan_L);
                translate([0,0,-Overlap])
                    cylinder(d=R60_MMT_ID, h=R60_FinCan_L+Overlap*2);
            }
            // Centering rings: aft, mid, forward.
            for (z=[6, R60_FinCan_L/2, R60_FinCan_L-Ring_T-6])
                translate([0,0,z]) difference(){
                    cylinder(d=R60_Body_ID, h=Ring_T);
                    translate([0,0,-Overlap])
                        cylinder(d=R60_MMT_OD-Overlap, h=Ring_T+Overlap*2);
                }
            // Retainer bolt bosses, aft end.
            for (i=[0:R60_nFins-1])
                rotate([0,0,i*360/R60_nFins + 180/R60_nFins])
                    translate([Boss_BC_R,0,0])
                        cylinder(d=Boss_d, h=Boss_h);
        }
        // Fin slots, through the outer wall only.
        for (i=[0:R60_nFins-1])
            rotate([0,0,i*360/R60_nFins])
                translate([R60_MMT_OD/2, -R60_Fin_T/2-IDXtra/2, Slot_Z])
                    cube([R60_Body_OD, R60_Fin_T+IDXtra, Slot_L]);
        // Retainer bolt bosses' blind inserts, cut from the aft face.
        for (i=[0:R60_nFins-1])
            rotate([0,0,i*360/R60_nFins + 180/R60_nFins])
                translate([Boss_BC_R, 0, -Overlap])
                    cylinder(d=Insert_d, h=Insert_h+Overlap);
        // Shock cord anchor -- see the module-level comment above.
        for (x=[-4,4])
            translate([x, -Cord_R, FwdRing_Z-Overlap])
                cylinder(d=Cord_d, h=Ring_T+Overlap*2);
    }
} // R60_FinCan

// Fin, printed flat. Low aspect ratio (0.87, exposed) is deliberate - it
// is what puts flutter velocity at ~959 m/s, 4.6x the H182R's Vmax
// (~210 m/s) and 3.0x the H135W's -- both re-derived on the EXPOSED
// panel (root at the body OD, not the buried root at the MMT), which is
// the panel that actually flexes. Span grew 55->63mm (task report,
// coordinator decision) to fix the G80T-14A's static margin, which was
// only 1.05 cal when Barrowman was correctly fed the exposed geometry;
// root/tip/sweep/thickness are unchanged because span is the most
// mass-efficient lever (CN scales with (exposed span/D)^2). Do NOT thin
// it or extend the span further without recomputing BOTH stability
// (tools/rocket60_model.py) and flutter -- they move in opposite
// directions as span grows.
module R60_Fin(){
    linear_extrude(height=R60_Fin_T)
        polygon([[0,0],
                 [R60_Fin_Root, 0],
                 [R60_Fin_Sweep+R60_Fin_Tip, R60_Fin_Span],
                 [R60_Fin_Sweep, R60_Fin_Span]]);
} // R60_Fin

// Aft retainer. Screws to the fin can and traps the motor's aft rim.
module R60_MotorRetainer(){
    T = 6;
    // Same bolt circle and 60deg fin offset as R60_FinCan()'s bosses.
    Bolt_BC_R = 24;
    Bolt_d    = 3.4;   // M3 clearance
    difference(){
        cylinder(d=R60_Body_OD, h=T);
        translate([0,0,-Overlap])
            cylinder(d=R60_MMT_ID-2.5, h=T+Overlap*2);
        for (i=[0:R60_nFins-1])
            rotate([0,0,i*360/R60_nFins + 180/R60_nFins])
                translate([Bolt_BC_R, 0, -Overlap])
                    cylinder(d=Bolt_d, h=T+Overlap*2);
    }
} // R60_MotorRetainer

// Forward spacer so a motor shorter than the 223mm MMT still sits flush at
// the aft end. Open bore: ejection gas and the forward closure pass through.
module R60_MotorSpacer(){
    L = R60_MMT_L - R60_Motor_L[Motor_Class];
    if (L > 1)
        difference(){
            cylinder(d=R60_MMT_ID-0.3, h=L);
            translate([0,0,-Overlap])
                cylinder(d=R60_MMT_ID-0.3-2*2.0, h=L+Overlap*2);
        }
} // R60_MotorSpacer

// Tether latch. Servo 2 withdraws the 3mm pin at 150m, freeing the 50mm
// tether loop so the sections separate fully and the main is drawn out.
//
// This is NOT the shock cord. The shock cord runs from the e-bay aft
// bulkhead to the fin can's forward centring ring and is never released
// (spec 4.1); the tether is a short (~50mm) line whose only job is the
// apogee restraint -- it holds the sections ~50mm apart through the
// tumble so the packed chute cannot come out early. Confusing the two
// leaves the aft section attached to nothing after main release.
//
// This latch carries the aft section's flopping load for ~25s of
// tumbling, not a single static pull -- its bench test should be cyclic,
// not a one-shot proof load.
//
// Mounts to R60_EBayAftBulkhead()'s aft face via 2x M3 into ruthex
// inserts, 22mm apart, offset to R60_Tether_Y (under servo 2's horn, not
// centred) -- centred would have sat under R60_SpringCarrier()'s Ø51
// counterbore rim gap but directly over its central driveshaft/spring
// bore, which the posts+pin need to clear. The posts (Post_H=12) and pin
// recess into that counterbore (17mm deep), which is why the counterbore
// exists at this size -- see that module's comment for the collision
// this avoids. This module itself is unchanged from a plain flat-mount
// design (own local frame, own zmin=0 base) -- the offset is applied by
// WHERE R60_EBayAftBulkhead() cuts its mounting holes, not by moving
// this module's own geometry.
//
// The tether's other (fixed) end anchors at R60_ChuteTube()'s forward-rim
// tie-off lug; the ~50mm cord between the two runs through the relief
// channel/notch in R60_EBayAftBulkhead()'s skirt and R60_SpringCarrier()'s
// counterbore rim, all at the same R60_Tether_Az. See those modules'
// comments.
module R60_TetherLatch(){
    // Base_L grew from 26 to fit the new mounting hole spacing
    // (R60_TetherLatch_HoleX*2 + a 2mm edge margin each side, same margin
    // the original 26mm/+-11mm layout used) -- see R60Lib.scad's
    // R60_TetherLatch_HoleX comment and R60_EBayAftBulkhead()'s insert
    // holes, which this must keep matching.
    Base_L = 2*(R60_TetherLatch_HoleX+2); Base_W = 16; Base_T = 4;
    Pin_d  = 3.0 + IDXtra;
    Post_H = 12;
    difference(){
        union(){
            translate([-Base_L/2,-Base_W/2,0]) cube([Base_L,Base_W,Base_T]);
            for (x=[-9, 9])
                translate([x,0,Base_T-Overlap]) cylinder(d=8, h=Post_H+Overlap);
        }
        // Pin bore through both posts. The pin IS the load path - it is a
        // 3mm steel dowel, not printed.
        translate([0,0,Base_T+Post_H-4]) rotate([0,90,0])
            cylinder(d=Pin_d, h=Base_L+2, center=true);
        // Slot the tether loop sits in, under the pin.
        translate([0,0,Base_T+Post_H-4])
            cube([10, Base_W+2, 9], center=true);
        // Mounting holes into the e-bay aft bulkhead. Ø3.4, M3 clearance
        // -- was Ø2.9 (tap-drill size, task report: the screw would
        // thread the latch instead of clamping it), matching the M3
        // clearance convention used everywhere else in this file
        // (R60_Cam_Bolt_d, R60_MotorRetainer()'s Bolt_d, ...). X spacing
        // is R60_TetherLatch_HoleX (R60Lib.scad), matching
        // R60_EBayAftBulkhead()'s insert holes exactly.
        for (x=[-R60_TetherLatch_HoleX, R60_TetherLatch_HoleX])
            translate([x,0,-Overlap]) cylinder(d=3.4, h=Base_T+Overlap*2);
    }
} // R60_TetherLatch

// ============================================
// DISPATCH
// ============================================
if (Render_Part==0) R60_TestRing();
if (Render_Part==1) R60_Neck();
if (Render_Part==2) R60_EBayTube();
if (Render_Part==3) R60_ChuteTube();
if (Render_Part==4) R60_EBayFwdBulkhead();
if (Render_Part==5) R60_EBayAftBulkhead();
if (Render_Part==6) R60_VegaSled();
if (Render_Part==7) R60_Door();
if (Render_Part==8) R60_SpringCarrier();
if (Render_Part==9)  R60_FinCan();
if (Render_Part==10) R60_Fin();
if (Render_Part==11) R60_MotorRetainer();
if (Render_Part==12) R60_MotorSpacer();
if (Render_Part==13) R60_TetherLatch();
