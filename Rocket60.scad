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
// 14 = Forward thrust ring
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

// E-bay tube with the access opening.
//
// The arming switch itself does NOT live on this tube any more (5th
// review, finding 1) -- see R60_Door()'s own module comment for where it
// went and why. This module only cuts the door's own aperture and the 4
// screw bosses that retain it.
module R60_EBayTube(){
    Door_Z0 = (R60_EBay_L - R60_Door_Open_H)/2;   // aperture bottom
    Door_Z1 = Door_Z0 + R60_Door_Open_H;          // aperture top
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
    //
    // Door_Boss_Reach_R (defect 2a): the boss's own OUTER CAP must stop
    // short of the true OD, not reach it. A round boss's flat end cap
    // bulges TANGENTIALLY by its own radius (Door_Boss_d/2) as well as
    // axially -- even with the cap's AXIS ending exactly at
    // R60_Body_OD/2, a point on the cap's rim is
    // sqrt(r_axis^2+(Door_Boss_d/2)^2) from the tube's own Z axis, past
    // R60_Body_OD/2 (measured on a render with the axis at
    // R60_Body_OD/2+Overlap: dmax 60.40, not the tube's own 60.00 -- the
    // door cover then rocks on the boss tips instead of seating flat,
    // exactly the failure this module's own comment above claims to have
    // avoided). The boss does not need to reach the OD at all: the wall
    // from R60_Body_ID/2 to R60_Body_OD/2 is already solid everywhere
    // except the door aperture cut itself, so the boss only has to
    // thicken the wall INWARD of the ID and then fuse into that
    // already-solid material -- same margin idiom as the Vega rails'
    // Rail_Overlap_R below.
    Door_Boss_d = 6;
    // Door_Boss_h (5th review, finding 2; re-derived 6th review, finding
    // 3.1): defect 2a (above) only bounded the boss's OUTER cap
    // (Door_Boss_Reach_R, below); its INNER tip (R60_Body_OD/2-Door_Boss_h)
    // must never reach past a stated clearance beyond the Vega board's own
    // worst-case corner (R60_Vega_Board_Corner_R, R60Lib.scad) -- asserted,
    // not just trusted, so a future change to the Vega stack that erodes
    // this margin fails loudly instead of silently reopening the 5th
    // review's board collision.
    //
    // Finding 3.1 (6th review): the 5th-review fix above derived
    // Door_Boss_h from WHATEVER clearance happened to be left ("as deep as
    // the board allows"), not from what the screw actually needs -- and at
    // the board's old (broken, rail-derived) position that left only
    // 2.757mm. Door_Pilot_Depth = Door_Boss_h-1.0 (leave 1mm backing before
    // the boss's own inward limit) then measured 1.757mm, of which only
    // the outermost 0.157mm was ever past the PLAIN wall's own natural
    // inner face (R60_Body_ID/2=28.4) -- the boss's remaining 1.157mm of
    // "extra" inward material sat INBOARD of where the pilot hole even
    // reached, never threaded at all. Direction fixed: derive Door_Boss_h
    // from a STATED pilot-engagement TARGET (a functional need), then
    // assert that target still fits inside the board-clearance ceiling --
    // not the reverse (deriving the boss from the ceiling and hoping
    // whatever pilot depth falls out of "-1.0" is enough). Now that the
    // sled sits at its own closed-form radial position (R60Lib.scad's
    // R60_Vega_Facing_Y_Nom, finding 1) instead of the old rail-derived
    // one, the board sits much deeper in the bore and the ceiling has real
    // headroom (~8.3mm) for a proper self-tap depth.
    Door_Pilot_MinDepth = 6.0;   // ~2.4x the M2.5 nominal diameter, a
                                   // standard self-tap engagement guideline
                                   // for a screw into PETG -- comfortably
                                   // more than the pre-5th-review 4mm this
                                   // boss originally shipped with
    Door_Boss_Backing = 1.0;     // solid boss material left BEHIND the
                                   // pilot hole's own floor, so it never
                                   // punches through into open bore
    Door_Boss_h = Door_Pilot_MinDepth + Door_Boss_Backing;   // 7.0
    Door_Boss_Clear = 1.5;   // stated margin beyond the board's own corner
    Door_Boss_MinInner_R = R60_Vega_Board_Corner_R + Door_Boss_Clear;  // ~21.72
    assert(R60_Body_OD/2 - Door_Boss_h >= Door_Boss_MinInner_R,
        str("R60_EBayTube: door boss's stated engagement target reaches ",
            "past the Vega board's own corner clearance (tip lands at r=",
            R60_Body_OD/2 - Door_Boss_h, ", must stay >= ",
            Door_Boss_MinInner_R, ") -- shrink Door_Pilot_MinDepth or ",
            "recheck the board stack"));
    Door_Boss_Reach_R = R60_Body_ID/2 + 1.2;   // fuses into the
                                                 // already-solid wall, well
                                                 // short of the OD (30.20mm
                                                 // even at the cap's own
                                                 // tangential bulge)
    Door_Pilot_d = 2.0;  // self-tap pilot, M2.5 into PETG
    Door_Pilot_Depth = Door_Boss_h - Door_Boss_Backing;   // = Door_Pilot_MinDepth, 6.0mm
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
    // Vega sled retention -- REMOVED (6th review, finding 1): this tube
    // used to cut 2 rails + 4 zip-tie slots at the -Y wall to capture the
    // sled's long edges. That concept failed three separate ways across
    // three review rounds (round 2: no retention at all; round 3: rails
    // overlapping the bulkheads; round 5: a "fixed" Rail_HalfAng that
    // turns out to open the two rails' facing planes AWAY from each other
    // with increasing radius -- there is no angle at which a sled corner
    // is simultaneously past a rail's inner face AND within its own
    // width, so the sled slides past both rails' corners and falls to
    // the tube ID, uncaptured; rail_facing_gap()'s tangential-only sample
    // could never see this because it never asked whether the CORNER
    // geometry has a solution at all). Retired rather than iterated a
    // fourth time -- see R60Lib.scad's own "Sled retention" comment.
    // Nothing in THIS part serves the sled any more: the tube's wall is
    // now a plain, unmodified cylinder there. Retention moved entirely to
    // R60_VegaSled() (which now bridges the full e-bay length and bolts
    // to both bulkheads) and R60_EBayAftBulkhead()/R60_EBayFwdBulkhead()
    // (which carry the matching inserts).
    difference(){
        union(){
            R60_Tube(R60_EBay_L);
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
                            cylinder(d=Door_Boss_d,
                                     h=Door_Boss_Reach_R-(R60_Body_OD/2-Door_Boss_h),
                                     $fn=32);
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
    // Wall_Fuse_R (4th review, critical 4): radial reach PAST the tube's
    // own ID a printed feature must have to actually weld into the wall
    // instead of merely touching it tangent. Same idiom/value as
    // R60_EBayTube()'s Rail_Overlap_R / Door_Boss_Reach_R (both 1.2mm
    // past R60_Body_ID/2, leaving the same 0.4mm of skin short of the
    // true OD) -- applied here to the spring reaction tabs and the
    // tether tie-off lug below, which both used to stop EXACTLY at
    // R60_Body_ID/2 (tangent, not embedded): measured weld cross-section
    // ~0.78mm^2/feature, indistinguishable from a meshing artifact, not a
    // real structural bond. Reacting 130N (the spring's own stated
    // target, R60Lib.scad's R60_Pin_d comment) across the 3 embedded tabs
    // now gives 3 * (Tab_W * Wall_Fuse_R) = 3*8*1.2 = 28.8mm^2, 4.5MPa --
    // comfortably below printed PETG's typical strength (order 30MPa+)
    // with real margin, not the 57MPa the tangent geometry worked out to.
    // No equivalent load figure exists in this repo for the lug's own
    // ~25s tumbling load (R60Lib.scad's own R60_Tether_Y comment notes
    // this), so its fix is the same embedding treatment without a
    // matching stress claim -- 8*1.2=9.6mm^2 of real weld area either
    // way, not the same near-zero tangent contact.
    Wall_Fuse_R = 1.2;
    difference(){
        union(){
            R60_Tube(R60_Chute_L);
            // Weld ring (4th review, critical 1): bridges the main wall
            // (r=R60_Body_ID/2..R60_Body_OD/2 = 28.4..30.0) to the aft
            // spigot's own OD/ID (26.6..28.2, below) with real shared
            // material. The spigot's OD is DELIBERATELY smaller than
            // this tube's own bore -- it has to slip inside the fin
            // can's matching 56.8mm ID, same 0.4mm-clearance convention
            // as every internal joint in this design -- so a plain step
            // straight from the wall to the spigot leaves a 0.2mm
            // radial gap with ZERO shared geometry between them: two
            // disconnected solids (confirmed:
            // tools/scad_verify.py's components() read 2 for this part,
            // not 1, before this fix -- genus could not see it, see that
            // function's own docstring). Built INSIDE the tube's own
            // existing R60_Chute_L (the last Weld_L mm of it), not as
            // added length, so it cannot itself reach into the fin can's
            // bore; its ID (matching the spigot's own ID, 53.2mm)
            // leaves the full working bore open for the shock cord/
            // tether cord/spring assembly that already routes through
            // this tube well forward of this joint -- nothing needs
            // more than that 53.2mm clear centre here.
            //
            // Height is Weld_L EXACTLY, ending flush at z=R60_Chute_L, not
            // Weld_L+Overlap: this ring sits INSIDE the main tube's own
            // z=0..R60_Chute_L span (R60_Tube(R60_Chute_L) already has
            // material there), so it needs no axial overlap fudge to fuse
            // with it -- unlike the spigot boundary below, which is a real
            // part-to-part butt joint once assembled and needs its own
            // Overlap on ITS OWN translate (already there). A first draft
            // gave this ring the same "+Overlap, starts at -Overlap"
            // idiom used for genuine boundary joints elsewhere in this
            // file, and the ring's own OUTER radius (R60_Body_OD, matching
            // the full wall) then poked 0.05mm PAST z=R60_Chute_L into
            // where the fin can's own forward tip sits once assembled --
            // caught on the rendered assembly,
            // tools/verify_rocket60_assembly.py pair 7 (0.0147cm3 at
            // z=180.00..180.05, dmax=60mm -- the tube's full OD, not the
            // spigot's narrower one) -- a real, if tiny, second-order
            // defect this fix itself introduced.
            Weld_L = 2;
            translate([0,0,R60_Chute_L-Weld_L])
                difference(){
                    cylinder(d=R60_Body_OD, h=Weld_L);
                    translate([0,0,-Overlap])
                        cylinder(d=R60_Coupler_OD-2*R60_Wall_T, h=Weld_L+Overlap*2);
                }
            // Aft spigot (3rd review, should-fix 6), ADDITIONAL length
            // past R60_Chute_L (same "spigot adds to the part's own
            // printed height, not carved from within a fixed total"
            // idiom as R60_Neck()'s skirt past its flange and
            // R60_EBayAftBulkhead()'s skirt past its disc -- a spigot
            // that stopped flush at the nominal 180mm boundary instead
            // of reaching past it would just touch the fin can's own
            // forward face, not insert into it, and prove nothing on the
            // assembly probe; caught there, tools/verify_rocket60_
            // assembly.py pair 7, before this was corrected to reach
            // past 180). Reduces to Coupler_OD so the joint to the fin
            // can gets the same concentric spigot every other internal
            // joint in this design already has, instead of a bare
            // 1.6mm-wall-to-1.6mm-wall butt bond. Fits the fin can's OWN
            // unmodified body ID (56.8mm) in the open outer annulus just
            // short of its forward centring ring -- see R60Lib.scad's
            // R60_FinCanSpigot_L comment for why 6mm and not
            // R60_Pin_Skirt_L=15 like the OTHER skirts (there is simply
            // less room here before that ring). Same "reduced OD/ID tube
            // section" idiom as R60_Neck()'s skirt and
            // R60_EBayAftBulkhead()'s skirt -- R60_Tube()'s own od/wall
            // parameters, not a hand-built difference().
            translate([0,0,R60_Chute_L-Overlap])
                R60_Tube(R60_FinCanSpigot_L+Overlap, od=R60_Coupler_OD, wall=R60_Wall_T);
            // Spring reaction tabs, inward from the tube wall, embedded
            // Wall_Fuse_R past the ID into the wall itself (see that
            // constant's comment) instead of stopping tangent to it.
            for (i=[0:nStopTabs-1])
                rotate([0,0,i*360/nStopTabs])
                    translate([-Tab_W/2, Stop_ID/2, Stop_Z])
                        cube([Tab_W, R60_Body_ID/2+Wall_Fuse_R-Stop_ID/2, Stop_T]);
            // Tether tie-off lug, +Y, well clear of the +-X pin holes and
            // the aft-most stop tabs -- embedded Wall_Fuse_R past the ID
            // into the wall (see that constant's comment); Tie_D itself
            // is unchanged (it still governs how far the lug reaches
            // INWARD, which is what R60_EBayAftBulkhead()'s relief notch
            // derives its own clearance from).
            translate([-Tie_W/2, R60_Body_ID/2-Tie_D, Tie_Z])
                cube([Tie_W, Tie_D+Wall_Fuse_R, Tie_H]);
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
//
// Vega sled mounting (6th review, finding 1): 2 ruthex RX-M3x5.7 inserts
// on the AFT (e-bay-facing, local z=0) face for the sled's forward foot --
// matching R60_EBayAftBulkhead() and R60_VegaSled()'s own foot holes
// exactly (R60Lib.scad's R60_VegaFoot_*), same idiom as
// R60_MotorRetainer()'s own insert bosses. The plain disc's own T=6mm is
// shorter than the insert's own 6.7mm depth, so a local boss grows the
// disc AFT-ward (local z<0, into the e-bay, where the sled's forward foot
// actually lands) at each insert. This part is NO LONGER symmetric
// front/back the way it was before this fix: the boss/insert face MUST be
// the aft face, matching R60_Neck()'s own comment and
// r60_assembly.scad's Pair 1 frame (this module's own z=0 lands at tube
// z=R60_EBay_L-R60_Neck_Skirt_L-R60_FwdBulk_T, growing +z toward the neck
// skirt) -- mark the aft face on the print.
module R60_EBayFwdBulkhead(){
    T = R60_FwdBulk_T;
    Boss_d = R60_VegaFoot_Boss_d;
    Insert_d = R60_VegaFoot_Insert_d;
    Insert_h = R60_VegaFoot_Insert_h;
    // Boss_Extra: how far the boss must grow PAST the plain disc's own
    // T=6mm so the insert (bored from the boss's own new outer/contact
    // face) still leaves R60_VegaFoot_Insert_Backing of solid material
    // before the disc's forward face. SHARED with R60Lib.scad's
    // R60_Vega_Window_Z1 (not recomputed locally) -- that constant has to
    // know exactly how far this boss reaches into the e-bay so the sled's
    // own Foot_L stops short of it, not just short of the plain disc face
    // (6th review, finding 1: a first version of this fix computed
    // Boss_Extra here only, leaving Window_Z1 still measured to the
    // plain disc face -- a real, measured 0.0937cm3 interference between
    // the sled's foot and this exact boss, tools/verify_rocket60_
    // assembly.py pair 24, before the two were unified).
    Boss_Extra = R60_VegaFoot_FwdBossExtra;
    assert(Boss_Extra > 0.5,
        str("R60_EBayFwdBulkhead: foot boss too shallow for a real ",
            "backing margin (Boss_Extra=", Boss_Extra, ")"));
    difference(){
        union(){
            cylinder(d=R60_Coupler_OD, h=T);
            for (x=[-R60_VegaFoot_HoleX, R60_VegaFoot_HoleX])
                translate([x, R60_VegaFoot_HoleY, -Boss_Extra])
                    cylinder(d=Boss_d, h=Boss_Extra+Overlap);
        }
        translate([0,0,-Overlap]) cylinder(d=22, h=T+Overlap*2);
        for (x=[-R60_VegaFoot_HoleX, R60_VegaFoot_HoleX])
            translate([x, R60_VegaFoot_HoleY, -Boss_Extra-Overlap])
                cylinder(d=Insert_d, h=Insert_h+Overlap);
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
    T         = R60_AftBulk_T;   // shared with R60_EBayTube()'s Vega
                                   // rails (3rd review, defect 2)
    Skirt_L   = R60_Pin_Skirt_L;
    Total_H   = T + Skirt_L;
    P_L       = 23.0 + IDXtra;   // MG90S body footprint
    P_W       = 12.2 + IDXtra;
    P_D       = 9;               // pocket depth; leaves 3mm of aft material
    Shaft_d   = 12;              // servo 1 output -> spring carrier ball-lock
    Horn_W    = R60_Horn_W;      // servo 2 horn slot -- shared with
                                   // R60_TetherLatch()'s own base
                                   // pass-through (4th review, critical 5)
    Horn_L    = R60_Horn_L;
    S_Off     = 5.5;             // MG90S shaft offset from body centre
    // = R60_Tether_Y (R60Lib.scad), not a second, independently-typed
    // 13.6 -- that constant's OWN comment already asserts this equality
    // ("so servo 2's horn can reach the latch") without enforcing it (6th
    // review, finding 3.3): changing R60_Tether_Y moved the tether
    // latch's mounting holes/pin path but silently left servo 2's own
    // pocket/horn slot behind, over a horn the servo could no longer
    // reach -- every existing check still passed, because they all
    // derive from whichever constant actually moved.
    S2_Y      = R60_Tether_Y;    // 1.2mm pocket wall (3 perimeters @ 0.4mm nozzle)
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

        // Vega sled mounting (6th review, finding 1): 2 ruthex RX-M3x5.7
        // inserts on this disc's own forward (e-bay-facing, z=0) face for
        // the sled's aft foot -- matching R60_EBayFwdBulkhead() and
        // R60_VegaSled()'s own foot holes exactly (R60Lib.scad's
        // R60_VegaFoot_*). This disc's own T=12mm has ample depth for the
        // insert's 6.7mm without a boss (unlike the forward bulkhead,
        // T=6mm there -- see that module's own comment). X/Y both clear
        // the servo pockets (max reach x=6.1,y=6.2), the horn slot (max
        // reach x=12,y=18.1) and the shock cord holes (x=+-6,y=-22) by
        // several mm, confirmed on the rendered mesh.
        for (x=[-R60_VegaFoot_HoleX, R60_VegaFoot_HoleX])
            translate([x, R60_VegaFoot_HoleY, -Overlap])
                cylinder(d=R60_VegaFoot_Insert_d, h=R60_VegaFoot_Insert_h+Overlap);

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
// RETENTION (6th review, finding 1 -- REPLACES the rail/zip-tie scheme,
// retired after 3 straight review-round failures; see R60Lib.scad's own
// "Sled retention" comment and R60_EBayTube()'s module comment for the
// closed-form proof the rails' capturing frame had no solution). This
// plate now BRIDGES the full axial gap between the aft and forward
// bulkheads' own e-bay-facing faces (R60_Vega_Window_Z0/Z1, R60Lib.scad)
// -- the board-carrying middle is unchanged (L=R60_Vega_L+12=112, same
// R60_Vega_Holes pattern), extended at each end by a derived FOOT that
// reaches the corresponding bulkhead and bolts to it, 2x M3 into ruthex
// RX-M3x5.7 inserts per end (4 total). Both the sled's radial position
// (R60_Vega_Facing_Y_Nom -- closed-form now, not a number that fell out
// of the rail math) and its clocking about the tube axis (the 2 holes'
// own X spread at each end -- a rigid body pinned at 2 non-collinear
// points per end cannot spin about the tube axis) are geometric, not
// frictional. Assembly: feed the plate in lengthwise before the neck is
// glued on, seat both feet against their bulkhead faces, drive the 4
// screws from inside the open bore.
module R60_VegaSled(){
    T = R60_Vega_Sled_T;
    L = R60_Vega_L + 12;   // board-carrying plate, unchanged
    W = R60_Vega_Sled_W;
    // Mounting holes are M3 (R60Lib.scad: "L-shaped M3 pattern"). Was
    // Ø2.9 -- tap-drill size, same defect class as the tether latch's
    // original holes (task report): the M3 standoff screw would thread
    // the sled instead of clamping it. Now Ø3.4, matching the M3
    // clearance convention used everywhere else in this file
    // (R60_Cam_Bolt_d, R60_MotorRetainer()'s Bolt_d, R60_TetherLatch()'s
    // mounting holes).
    Hole_d = 3.4;

    // Foot geometry -- see R60Lib.scad's own comments for each constant's
    // derivation. Foot_L (how far each foot reaches past the plate's own
    // +-L/2) is the one quantity computed HERE rather than in R60Lib.scad,
    // since it depends on this module's own L: DERIVED from the real
    // axial gap between the two bulkhead mounting faces, not a free
    // constant, so it grows/shrinks automatically with R60_EBay_L or
    // either bulkhead's thickness instead of silently falling short (or
    // overlapping) the next time either changes.
    Foot_HoleX = R60_VegaFoot_HoleX;
    Foot_Hole_d = R60_VegaFoot_Hole_d;
    Foot_PadZ = R60_VegaFoot_PadZ;   // local Z (=radial once assembled)
    Foot_PadX = R60_VegaFoot_PadX;   // local X width, spans both holes
                                       // with real wall either side
    Window_L = R60_Vega_Window_Z1 - R60_Vega_Window_Z0 - 2*R60_Vega_Foot_Clear;
    Foot_L = (Window_L - L) / 2;
    assert(Foot_L > 5,
        str("R60_VegaSled: foot too short to be a rigid mounting tab ",
            "(Foot_L=", Foot_L, ") -- e-bay length/skirt/bulkhead sizes ",
            "no longer leave room for the bridge"));

    difference(){
        union(){
            translate([-W/2, -L/2, 0]) cube([W, L, T]);
            for (h=R60_Vega_Holes)
                translate([h[0], h[1], T-Overlap])
                    cylinder(d=7, h=R60_Vega_Standoff_h+Overlap);
            // Foot pads, both ends. Local Z grown to Foot_PadZ (not just
            // the plain plate's T=4) so the M3 hole gets a real wall
            // around it once assembled -- R60Lib.scad's R60_VegaFoot_PadZ
            // comment: T alone would leave only 0.3mm, the same
            // "boss sized to fit the OD, never checked against the hole
            // it hosts" defect class as finding 3.1's door boss. Local Y
            // runs from the plate's own +-L/2 out to +-(L/2+Foot_L),
            // reaching the bulkheads with R60_Vega_Foot_Clear to spare.
            for (s=[-1,1])
                translate([-Foot_PadX/2, s>0 ? L/2-Overlap : -L/2-Foot_L,
                           0])
                    cube([Foot_PadX, Foot_L+Overlap, Foot_PadZ]);
        }
        for (h=R60_Vega_Holes)
            translate([h[0], h[1], -Overlap])
                cylinder(d=Hole_d, h=T+R60_Vega_Standoff_h+Overlap*2);
        // Foot mounting holes -- bored along local Y (axial once
        // assembled) the full length of each pad, so the M3 screw runs
        // straight through into the bulkhead's own insert.
        for (s=[-1,1], x=[-Foot_HoleX, Foot_HoleX])
            translate([x, s>0 ? L/2-Overlap : -L/2-Foot_L-Overlap,
                       R60_VegaFoot_HoleZ_Local])
                rotate([-90,0,0])
                    cylinder(d=Foot_Hole_d, h=Foot_L+2*Overlap);
    }
} // R60_VegaSled

// Curved door COVER, 4x M2.5, and the panel-mount arming switch (5th
// review, finding 1). Overlaps the tube's opening (cut in R60_EBayTube())
// on all 4 sides and rests against the tube's own outer surface -- a real
// ledge, not a loose plug.
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
//
// ARMING SWITCH (5th review, finding 1) -- moved here from the tube wall.
// The switch's own Z window there (Sw_Z0/Sw_Z1, R60_EBayTube()) had to
// clear BOTH this cover's real footprint (Door_Z1+R60_Door_Overlap) AND
// the neck skirt above it (R60_EBay_L-R60_Neck_Skirt_L) -- a window that
// had already inverted once (4th review, critical 3) and, correctly
// counting the forward bulkhead too (which the window never did),
// inverts again at the CURRENT R60_EBay_L: the corrected Sw_Z1 comes out
// at 143, below Sw_Z0=146, and closing that gap by growing the e-bay
// again would need R60_EBay_L>=183 -- patching the same defect class a
// third time by growing the tube instead of fixing the placement. The
// door is the better home regardless of that number: it is removable
// with its own wiring attached, and the CATS manual's actual requirement
// (board armed only once the rocket is vertical on the pad) is satisfied
// by a switch on the door just as directly as one on the tube wall -- a
// barrel through the tube wall has to thread between the door aperture,
// the neck skirt and the forward bulkhead, which is what has now failed
// twice. Centred in the APERTURE itself (not the overlap frame) so there
// is open bore behind it once assembled, not solid tube wall, giving the
// retaining nut and wiring somewhere to actually go. Local x=0
// (Hole_Az(0)=90deg) is the cover's own crown, farthest from both pairs
// of screw bosses -- see tools/r60_assembly.scad's new switch-envelope
// pairs for the proof this clears everything it could reach once fitted.
module R60_Door(){
    Cover_H = R60_Door_Open_H + 2*R60_Door_Overlap;
    T = 2.0;    // cover shell thickness
    Hole_X = R60_Door_Open_W/2 + R60_Door_Hole_Clear;
    Hole_Z = [R60_Door_Overlap - R60_Door_Hole_Clear,
              R60_Door_Overlap + R60_Door_Open_H + R60_Door_Hole_Clear];
    // Cover_W (6th review, finding 3.2): the flat X-clip used to be
    // SIZED ONLY off the aperture-overlap requirement
    // (R60_Door_Open_W+2*R60_Door_Overlap), leaving just ~0.6mm of solid
    // material past the screw hole's own edge (1.5 extrusion widths) --
    // measured on the rendered mesh, not the ~1.65mm a naive flat
    // "hole radius + wall" estimate predicts: a hole bored along the
    // wall's own RADIAL direction (Hole_Az(x), above) through a CURVED
    // shell sweeps further in flat X than its own diameter alone
    // suggests as it crosses from the inner to outer face, the same
    // curved-vs-flat effect defect 1a fixed for hole AZIMUTH. Same
    // defect class as R60_TetherLatch()'s Base_L/R60_SpringCarrier()'s
    // Ball_Wall_Min (a boss/edge sized to ONE constraint, never checked
    // against the hole it has to host) -- Cover_W now derives from BOTH
    // the overlap requirement (retention, R60_Door()'s own module
    // comment) and a stated minimum wall beyond the screw hole's own
    // edge, whichever is larger. Door_Hole_Curve_Pad is a stated,
    // conservative allowance for the curved-hole effect above (not a
    // closed form -- confirmed sufficient by re-measuring the rendered
    // mesh, tools/verify_rocket60.py's own door-cover-wall check, rather
    // than trusted from this arithmetic alone).
    Door_Hole_d = 2.7;
    Door_Hole_Wall_Min = R60_Wall_T;   // 1.6mm, matching every other
                                         // stated-minimum-wall convention
                                         // in this file
    Door_Hole_Curve_Pad = 1.5;
    Cover_HalfW = max(R60_Door_Open_W/2 + R60_Door_Overlap,
                       Hole_X + Door_Hole_d/2 + Door_Hole_Wall_Min
                           + Door_Hole_Curve_Pad);
    Cover_W = 2 * Cover_HalfW;
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
    Sw_d = 12;   // panel-mount toggle -- matches R60_EBayTube()'s old Sw_d
    Sw_X = 0;    // the cover's own crown
    Sw_Z = R60_Door_Overlap + R60_Door_Open_H/2;   // aperture's own centre
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
                        cylinder(d=Door_Hole_d, h=T+2*Overlap, $fn=32);
        // Arming switch -- see the module comment above. Same "rotate for
        // azimuth, then bore along local radial +X through the shell
        // only" idiom as the screw holes above.
        rotate([0,0,Hole_Az(Sw_X)])
            translate([R60_Body_OD/2-Overlap, 0, Sw_Z])
                rotate([0,90,0])
                    cylinder(d=Sw_d, h=T+2*Overlap, $fn=32);
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
// channel through the wall at R60_Tether_Az (+Y), running this carrier's
// FULL length (3rd review, defect 1 -- see the cut's own comment below:
// a short notch at the rim only relieves where the tether cord ends up
// once fully assembled, not the clearance the chute tube's rigid tether
// lug needs while sliding on), continues the tether's relief channel
// from the skirt into the counterbore -- see R60_ChuteTube()'s module
// comment for the tether's fixed end.
module R60_SpringCarrier(){
    OD      = R60_Coupler_OD;      // 56.4 -- 0.4mm clearance in the chute
                                    // tube's 56.8mm bore, same convention
                                    // as every internal part in this repo
    Bore    = R60_Spring_OD + 0.5;  // 44.80 -- clears the CS4323's 44.30mm OD
    L       = 65;                   // + the skirt's 15mm = 80mm, the
                                     // "SpringThing2" figure sourced above
    CB_D      = R60_SpringCarrier_CB_D;  // 51 -- tether latch (part 13)
                                     // clearance -- shared (4th review,
                                     // critical 2) so the latch's own base
                                     // clip is derived from the SAME
                                     // number, not a second copy
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
        // Tether relief channel through the OD-to-CB_D/Bore annulus (the
        // wall thickness outside whatever is already hollow at each Z --
        // CB_D's counterbore for z<CB_Depth, the narrower Bore beyond
        // it), at R60_Tether_Az (+Y) matching R60_EBayAftBulkhead()'s
        // skirt channel -- defect 2c: this notch used to be a hardcoded
        // 8mm wide while the skirt channel it must match DERIVES as
        // R60_TetherLug_W + 2*R60_Tether_Clear = 9.2mm, necking the cord
        // from 9.2 down to 8.0mm and stepping 1.2mm outward in radius at
        // the glue joint despite the comment's claim they "match
        // exactly". Same formula as R60_EBayAftBulkhead()'s
        // Tether_Notch_W, not a hand-matched copy -- the whole point of
        // the R60_TetherLug_* constants (see R60Lib.scad) is that this
        // notch be derived, never a second, independently-typed number
        // that can silently drift.
        //
        // Height (3rd review, defect 1): this used to stop at 5mm,
        // relieving only the forward rim. That is not what the channel
        // has to clear -- the chute tube's tether tie-off lug
        // (R60_ChuteTube(), a FIXED boss at chute-frame z=4..9) does not
        // stay near the forward rim as the chute tube is assembled onto
        // this carrier; the carrier is 65mm long and the tube telescopes
        // over its ENTIRE length before finally seating with the lug
        // back inside the (already-relieved) skirt span. A 5mm-tall
        // relief only covers the very end of that stroke, so for most of
        // the assembly the lug rides against this wall's solid OD and
        // the two parts physically cannot be pushed together --
        // confirmed on the rendered mesh
        // (tools/verify_rocket60_assembly.py, pair 6: intersecting the
        // carrier with the chute tube along the insertion stroke reads
        // 0 cm3 at first contact, but 0.0838 cm3 for most of the middle
        // of the stroke, not clearing again until the lug re-enters the
        // skirt's own span -- the rocket could not be assembled at all).
        // Run the channel the carrier's FULL length instead: the ball
        // pockets (60/180/300deg) and the cord channels (~255-285deg)
        // are both well clear of R60_Tether_Az=90deg, so a full-length
        // slot here does not touch either.
        //
        // Radial depth: a first draft kept the ORIGINAL CB_D/2-0.5=25.0mm
        // inner bound (correct for the short forward-rim notch it
        // replaced, where everything inboard of CB_D was already open
        // counterbore) and only extended the LENGTH. That left a real
        // gap for z>CB_Depth=17mm, where the bore has already narrowed to
        // Bore=44.8 (r=22.4) and the channel is the ONLY relief -- the
        // lug's own inner reach (R60_Body_ID/2-R60_TetherLug_D=24.4mm, on
        // R60_ChuteTube()) is INSIDE this channel's 25.0mm bound, so a
        // 0.6mm-thick sliver of solid material remained between the
        // lug's tip and the channel's own wall for the whole
        // post-counterbore length -- caught by the SAME rendered-mesh
        // check (0.0223 cm3 residual after the length-only fix, vs. 0
        // once this is corrected too). Match R60_EBayAftBulkhead()'s own
        // Tether_Notch_MinR formula instead of a value that only worked
        // for one specific Z range.
        // Top plane (5th review, finding 14): was L+Overlap, giving a top
        // face at -Overlap+(L+Overlap)=L exactly -- EXACTLY coincident
        // with this part's own top face at z=L, against this file's own
        // "+Overlap*2" idiom used everywhere else specifically to avoid a
        // degenerate boolean at a shared plane (GENUS[8] has zero
        // tolerance for the kind of spurious handle a coincident-face
        // boolean can produce). Nothing else occupies z>L in this module,
        // so reaching Overlap past it is a pure no-op on the printed
        // geometry, same as every other genuine boundary cut in this file.
        Notch_W = R60_TetherLug_W + 2*R60_Tether_Clear;
        Notch_MinR = R60_Body_ID/2 - R60_TetherLug_D - R60_Tether_Clear;
        translate([-Notch_W/2, Notch_MinR, -Overlap])
            cube([Notch_W, OD/2-Notch_MinR+1, L+Overlap*2]);
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
    // axial Ø5 holes at x=+-4mm (Cord_d matches R60_EBayAftBulkhead()'s
    // own cord holes; the x spacing does not -- this ring's annulus is
    // narrower, so +-4mm, not that part's +-6mm, is what actually clears
    // both the MMT and the fin slots here), through the FORWARD ring
    // only, at -Y -- clear of all 3 fin slots (0/120/240deg) and solidly
    // inside the ring's own annulus (MMT_OD/2=16.15 .. Body_ID/2=28.4).
    //
    // R60_FinCan_FwdOpen_L (4th review, should-fix 8), not a bare local
    // "6": shared with R60Lib.scad's R60_FinCanSpigot_L so the chute
    // tube's own spigot is derived from exactly how much open annulus
    // this ring actually leaves forward of it, with a stated clearance,
    // instead of a second independently-typed "6" that happened to match
    // it exactly (a bare tangency -- see R60_FinCanSpigot_L's comment).
    FwdRing_Z = R60_FinCan_L - Ring_T - R60_FinCan_FwdOpen_L;
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
            for (z=[6, R60_FinCan_L/2, FwdRing_Z])
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

// Aft retainer. Screws to the fin can and traps the motor's aft rim --
// resists AFT motion only (the motor sliding out the nozzle end). See
// R60_ThrustRing() (part 14) for the forward-thrust counterpart this
// alone does not provide.
module R60_MotorRetainer(){
    T = 6;
    // Same bolt circle and 60deg fin offset as R60_FinCan()'s bosses.
    Bolt_BC_R = 24;
    Bolt_d    = 3.4;   // M3 clearance
    difference(){
        cylinder(d=R60_Body_OD, h=T);
        translate([0,0,-Overlap])
            cylinder(d=R60_Motor_Lip_d, h=T+Overlap*2);
        for (i=[0:R60_nFins-1])
            rotate([0,0,i*360/R60_nFins + 180/R60_nFins])
                translate([Bolt_BC_R, 0, -Overlap])
                    cylinder(d=Bolt_d, h=T+Overlap*2);
    }
} // R60_MotorRetainer

// Forward spacer so a motor shorter than the R60_MMT_L (228mm) MMT still
// sits flush at the aft end. Open bore: ejection gas and the forward
// closure pass through.
//
// Length (3rd review, defect 3 corollary): the spacer's own forward face
// used to be sized flush with R60_MMT_L, the fin can's own full build
// depth -- correct before this task, when nothing else lived in that
// last stretch of the MMT. R60_ThrustRing() (part 14) now glues in
// flush with that same forward tip, occupying its own R60_ThrustRing_T
// there; the spacer must stop that much short of R60_MMT_L instead, or
// the two occupy the same space (caught on the rendered assembly,
// tools/verify_rocket60_assembly.py pair 10, before this line existed).
module R60_MotorSpacer(){
    L = R60_MMT_L - R60_ThrustRing_T - R60_Motor_L[Motor_Class];
    if (L > 1)
        difference(){
            cylinder(d=R60_MMT_ID-0.3, h=L);
            translate([0,0,-Overlap])
                cylinder(d=R60_MMT_ID-0.3-2*2.0, h=L+Overlap*2);
        }
} // R60_MotorSpacer

// Forward thrust ring (part 14, 3rd review defect 3). Glues into the
// MMT's forward opening, flush with the fin can's own forward tip, and
// reacts the motor's FORWARD thrust load -- the load R60_MotorRetainer()
// (aft) cannot touch, because it only meets the motor's AFT rim.
//
// Nothing reacted this before. During the burn the motor case feels a
// FORWARD reaction force (Newton's third law -- the exhaust is expelled
// aft, so the case is pushed forward), roughly the motor's own average
// thrust: 77.6N for the G80T-14A (thrustcurve.org), more for either H.
// R60_FinCan()'s forward centring ring bores 32.25mm and bonds to the
// MMT's OUTSIDE, so it never reaches into the 29.3mm bore at all; the
// only thing between the motor+R60_MotorSpacer() stack and the packed
// parachute forward of it was a 0.3mm slip fit -- friction alone,
// against tens of newtons, for the whole burn.
//
// Bore: R60_Motor_Lip_d (R60Lib.scad), the SAME lip width as
// R60_MotorRetainer()'s own aft bore -- smaller than the motor/spacer's
// own OD (R60_MMT_ID-0.3=29.0mm) so it physically catches whichever one
// is flush at the front (see below), but well clear of
// R60_MotorSpacer()'s own internal bore (R60_MMT_ID-0.3-2*2.0=25.0mm) so
// it adds no new restriction to the ejection-gas/forward-closure path
// that spacer already exists to keep open.
//
// Axial position: this ring occupies the LAST R60_ThrustRing_T of the
// MMT's own R60_MMT_L=R60_FinCan_L=228mm, flush with the fin can's own
// forward tip and immediately aft of R60_FinCan()'s own forward centring
// ring (z=FwdRing_Z..R60_FinCan_L-6) so it bonds against existing
// structure rather than an unsupported span of MMT wall. It glues in
// from the fin can's still-open forward end -- the last step before
// bonding R60_ChuteTube() on, per R60-PrintSettings.md.
// R60_MotorSpacer()'s own length is derived to stop R60_ThrustRing_T
// short of R60_MMT_L for exactly this reason (see that module's own
// comment) -- whatever is forward-most in the motor+spacer stack, the
// spacer for any motor shorter than R60_MMT_L-R60_ThrustRing_T, or the
// motor itself if one is ever added that long, always has its own
// forward face flush against this ring's aft face, not sharing its
// space.
//
// OD: R60_MMT_ID-0.4, the same "-0.4mm" glued-internal-tube-in-tube
// convention as every other glued internal part in this repo
// (R60_Coupler_OD = R60_Body_ID-0.4), sized to the MMT's own measured
// bore rather than a second, independently-typed number.
//
// Verified mesh-against-mesh, not by reasoning (tools/verify_rocket60.py
// and tools/verify_rocket60_assembly.py, pairs 10/11): the ring's own
// bore is measured off its rendered mesh and checked smaller than the
// spacer's own measured OD (it obstructs), and the assembled
// intersection of the motor+spacer stack against this ring, pushed a
// deliberate few mm past its resting position, confirms real, solid
// contact in the forward direction -- not just two numbers that happen
// to compare correctly. Pair 11 does the same for R60_MotorRetainer()'s
// existing aft lip, so both directions of the trap are confirmed, not
// just the one this task added.
module R60_ThrustRing(){
    T = R60_ThrustRing_T;
    difference(){
        cylinder(d=R60_MMT_ID-0.4, h=T);
        translate([0,0,-Overlap])
            cylinder(d=R60_Motor_Lip_d, h=T+Overlap*2);
    }
} // R60_ThrustRing

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
// The actuation linkage that reaches from servo 2's horn (mounted well
// forward, in R60_EBayAftBulkhead()'s own servo pocket) through the
// bulkhead's horn slot and the pass-through this module cuts through its
// own base, to the pin/loop mechanism above, is a COMPANION PIECE not
// modelled as its own part in this task -- same treatment, and for the
// same reason, as R60_SpringCarrier()'s own ball-lock plunger/lock-disk
// (see that module's comment): a rotating horn arm cannot reach the pin
// directly, so a pushrod/cam/bellcrank of some kind is needed, and
// designing that mechanism is out of this task's scope. What IS in scope,
// and was the 4th review's own critical finding 5, is that this module's
// geometry must not itself make that (unmodelled) linkage's path
// physically impossible -- see Base_Pass_W/Base_Pass_H below.
module R60_TetherLatch(){
    // Base_L (defect 2b): the old "2mm edge margin" was hole-CENTRE-to-
    // edge, not wall thickness. With a Ø3.4 mounting hole (radius 1.7)
    // centred at x=R60_TetherLatch_HoleX=16, the hole itself already
    // reaches to x=17.7 -- on a 36mm base (edge at x=18) that left only
    // 0.3mm of solid wall outboard of the hole, below one extrusion width
    // (measured on the rendered mesh). Same defect class as
    // R60_SpringCarrier()'s ball pockets (Ball_Wall_Min): derive Base_L
    // from a STATED minimum wall beyond the hole's own EDGE, not a
    // hand-picked centre-to-edge margin. Mount_Wall_Min matches
    // R60_Wall_T, the airframe's own established solid-wall figure.
    Mount_Hole_d  = 3.4;   // M3 clearance
    Mount_Wall_Min = R60_Wall_T;   // 1.6mm -- solid wall beyond the hole edge
    Base_L = 2*(R60_TetherLatch_HoleX + Mount_Hole_d/2 + Mount_Wall_Min);
    Base_W = 16; Base_T = 4;
    Pin_d  = 3.0 + IDXtra;
    Post_H = 12;
    Post_X = 9; Post_d = 8;
    // Clip radius (4th review, critical 2): this module's own base is
    // mounted OFF-AXIS -- offset R60_Tether_Y from the carrier/chute-tube
    // axis it shares the aft bulkhead's mount face with, so servo 2's
    // horn (also at R60_Tether_Y) can reach it -- but its rectangular
    // footprint was never clipped to account for that offset. The base's
    // own far corners sit r=28.97mm from that axis (measured), past BOTH
    // R60_SpringCarrier()'s counterbore rim (r=CB_D/2=25.5..OD/2=28.2,
    // solid there) it is bonded flush against, AND the chute tube's own
    // bore (r=28.4) it must fit inside once assembled -- a real,
    // measured 0.0973cm^3 collision with the carrier alone. Growing
    // R60_SpringCarrier_CB_D cannot fix this: no round counterbore
    // centred ON that axis can clear an off-axis rectangle without
    // itself exceeding the carrier's own 56.4mm OD. Clip this module's
    // OWN geometry instead, to a circle centred on that axis (local
    // y=-R60_Tether_Y from here) -- R60_Tether_Clear inside
    // R60_SpringCarrier_CB_D/2, the same stated per-side clearance
    // R60_ChuteTube()'s tether lug already uses against its own mating
    // notch. Survivors, all measured against this radius: the mounting
    // holes (global r=21.0mm) keep 2.2mm of wall past their own edge
    // (>=Mount_Wall_Min); the base's front edge (local y=0, closest to
    // the axis) is untouched (clip reaches x=+-20.9 there, past the
    // base's own +-19.3); only the two far corners (toward local
    // +Base_W/2, farthest from the axis) are clipped -- the posts
    // (r<=20.3 from this axis) are nowhere near the clip boundary either
    // way, matching the module comment this replaces ("true for the
    // posts, never checked for the base").
    Clip_R = R60_SpringCarrier_CB_D/2 - R60_Tether_Clear;
    // Base pass-through (4th review, critical 5): the horn slot
    // (R60_EBayAftBulkhead()) was extended through the bulkhead's own
    // skirt specifically so servo 2 could reach this latch, but this
    // module's base is a solid Base_T slab bolted flat over that
    // opening, with its only cuts (the pin bore, the loop slot) sitting
    // ABOVE Base_T in the posts -- the horn slot's own void dead-ends
    // against solid material here, same failure class the horn slot
    // itself was already fixed for at R60_EBayAftBulkhead()'s skirt (see
    // that module's comment). Local (0,0) already coincides with the
    // horn slot's own global centre (both sit at R60_Tether_Y, by
    // construction), so no offset is needed here, only a size.
    // Base_Pass_W cannot be the bulkhead's full R60_Horn_L (24mm): the
    // two posts (Post_X=+-9, radius Post_d/2=4) sit almost entirely
    // inside that width and are the pin's own load path (Post_H=12mm
    // cantilevers reacting the tether release load into this base) --
    // cutting through their own base would undermine exactly the
    // structural weld finding 4 (this same review) fixes elsewhere.
    // Base_Pass_W is instead the clear gap BETWEEN the two posts,
    // derived from their own placement, not a hand-picked number: still
    // a real, unobstructed opening for whatever unmodelled linkage
    // reaches up between them (see the module-level companion-piece note
    // above), just narrower than the bulkhead's own slot. Height matches
    // R60_Horn_W directly (shared, R60Lib.scad) rather than a second,
    // independently-typed width.
    Base_Pass_W = 2*(Post_X - Post_d/2);   // 10
    intersection(){
        difference(){
            union(){
                translate([-Base_L/2,-Base_W/2,0]) cube([Base_L,Base_W,Base_T]);
                for (x=[-Post_X, Post_X])
                    translate([x,0,Base_T-Overlap]) cylinder(d=Post_d, h=Post_H+Overlap);
            }
            // Pin bore through both posts. The pin IS the load path - it is a
            // 3mm steel dowel, not printed.
            //
            // Reach (5th review, finding 3): this used to run the latch's
            // own full base width (Base_L+2, half-reach 20.3mm) regardless
            // of what that is actually clear of. The binding constraint is
            // the spring carrier's own counterbore rim
            // (R60_SpringCarrier_CB_D/2=25.5mm) the pin travels inside once
            // assembled (r60_assembly.scad pairs 17-19) -- and the true
            // available reach there is set by the PIN'S OWN RADIUS too, not
            // just its centreline: the farthest point on the pin is offset
            // R60_Tether_Y+Pin_d/2 off the carrier's axis (at the end cap's
            // own tangent), not just R60_Tether_Y. The old comment's
            // "1.27mm of real margin" came from
            // sqrt((CB_D/2)^2-Tether_Y^2)-20.3 -- the centreline-only
            // figure; correctly counting the pin's own radius, the real
            // number is sqrt((CB_D/2)^2-(Tether_Y+Pin_d/2)^2)-20.3 =
            // 0.15mm, inside print tolerance for a Ø3 dowel that has to be
            // inserted and withdrawn (confirmed on the rendered mesh: first
            // contact between half-reach 20.45 and 20.6mm, not the +3.4mm
            // the old "mutation-tested" claim implied -- that mutation
            // probed ~20x past the real threshold).
            //
            // Withdrawal only ever needs to clear both posts
            // (Post_X+Post_d/2=13mm) plus a stated hand-grip allowance --
            // nowhere near that ceiling -- so Pin_Reach is capped there
            // explicitly, with a stated real clearance to the rim, instead
            // of reaching for the old bore's full width. That means this
            // bore no longer breaks through the base's own outer edge
            // (Pin_Reach=17 < Base_L/2=19.3) -- a BLIND channel, which is
            // fine: nothing in this module's scope requires the printed
            // bore itself to reach open air at the base's edge, only that
            // it give the pin (separate steel hardware) a straight,
            // adequately long channel to travel in. Asserted so a future
            // change to R60_Tether_Y/R60_SpringCarrier_CB_D/Pin_d that eats
            // this margin fails loudly instead of silently reopening the
            // same 0.15mm gap.
            Pin_Reach_Grip = 4;    // hand-grip/actuation allowance past the post
            Pin_Reach = Post_X + Post_d/2 + Pin_Reach_Grip;   // 17
            Pin_Reach_MaxSafe = sqrt(pow(R60_SpringCarrier_CB_D/2, 2)
                                     - pow(R60_Tether_Y + Pin_d/2, 2));  // ~20.47
            Pin_Reach_Clear = 1.5;  // stated minimum real clearance to the rim
            assert(Pin_Reach + Pin_Reach_Clear <= Pin_Reach_MaxSafe,
                str("R60_TetherLatch: pin withdrawal reach has no safe margin ",
                    "left against the spring carrier's counterbore rim (need=",
                    Pin_Reach + Pin_Reach_Clear, " maxsafe=", Pin_Reach_MaxSafe, ")"));
            translate([0,0,Base_T+Post_H-4]) rotate([0,90,0])
                cylinder(d=Pin_d, h=2*Pin_Reach, center=true);
            // Loop channel (5th review, finding 4): the gap BETWEEN the two
            // posts (x=-5..5, the SAME span Base_Pass_W below derives) is
            // already open above the base slab (z>=Base_T) BY CONSTRUCTION
            // -- the posts sit at x=+-Post_X with radius Post_d/2=4, so
            // nothing spans x=-5..5 there in the first place. A cube used
            // to be cut here claiming to open "the slot the tether loop
            // sits in", but its footprint (x=-5..5, z=7.5..16.5) was
            // exactly tangent to the posts' own inner faces (x=+-5) and
            // started above the base's own top face (z=4) -- removing
            // material that was never there, a no-op cut (confirmed:
            // Base_Pass_W = 2*(Post_X-Post_d/2) is the SAME 10 by
            // construction). The gap between the posts IS the loop's
            // channel; the posts' inner faces are what retain it
            // laterally. No separate cut is needed.
            // Mounting holes into the e-bay aft bulkhead. Ø3.4, M3 clearance
            // -- was Ø2.9 (tap-drill size, task report: the screw would
            // thread the latch instead of clamping it), matching the M3
            // clearance convention used everywhere else in this file
            // (R60_Cam_Bolt_d, R60_MotorRetainer()'s Bolt_d, ...). X spacing
            // is R60_TetherLatch_HoleX (R60Lib.scad), matching
            // R60_EBayAftBulkhead()'s insert holes exactly.
            for (x=[-R60_TetherLatch_HoleX, R60_TetherLatch_HoleX])
                translate([x,0,-Overlap]) cylinder(d=Mount_Hole_d, h=Base_T+Overlap*2);
            // Base pass-through -- see Base_Pass_W's own comment above.
            translate([-Base_Pass_W/2, -R60_Horn_W/2, -Overlap])
                cube([Base_Pass_W, R60_Horn_W, Base_T+Overlap*2]);
        }
        // Corner clip -- see Clip_R's own comment above.
        translate([0,-R60_Tether_Y,-Overlap])
            cylinder(r=Clip_R, h=Base_T+Post_H+Overlap*2);
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
if (Render_Part==14) R60_ThrustRing();
