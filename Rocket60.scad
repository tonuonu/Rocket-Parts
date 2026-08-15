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

// Petal deployment (spec 4.2 transplant) -- transplanted, not
// re-invented: PD_Petals()/R65_PetalHub() (petal cage + hub) from a
// flown 2.6" single-deploy design's own libraries, and the release
// catch from CableReleaseBBMicro.scad (chosen over the flown design's
// own CableReleaseBBMini.scad on mesh-measured evidence -- see
// R60_ReleaseActivator()'s module comment). See tasks/lessons.md for
// why an invented mechanism lost to a proven one here.
use<PetalDeploymentLib.scad>
use<R65Lib.scad>
use<CableReleaseBBMicro.scad>
use<SpringEndsLib.scad>

// ============================================
// RENDER SELECTION - change this value!
// ============================================
//  0 = Test ring (PRINT THIS FIRST)
//  1 = Neck
//  2 = E-bay tube
//  3 = Deployment bay tube (fixed; petals telescope through its open aft end)
//  4 = E-bay forward bulkhead
//  5 = E-bay aft bulkhead
//  6 = Vega sled
//  7 = Access door
//  8 = Petal hub (bolts to the fin can side; carries the petal cage)
//  9 = Fin can
// 10 = Fin
// 11 = Motor retainer
// 12 = Motor spacer
// 13 = Petals (hinge to part 8 via part 24's spring holders, not bolted;
//      flex open under spring load once released)
// 14 = Forward thrust ring
// 15 = Release activator (servo mount, bolts to part 5's aft face)
// 16 = Release top retainer
// 17 = Release lock ring
// 18 = Release outer bearing retainer
// 19 = Release trigger post
// 20 = Release magnet bracket
// 21 = Release extension rod
// 22 = Release locking pin
// 23 = Forward spring end (spring piston; threads onto the release
//      stack's locking pin/extension rod and locks onto the petals
//      directly -- not bolted to part 8, see its own module comment)
// 24 = Petal spring holder (print 3x -- the hinge: bolts to each petal,
//      axle rides in part 8's pivot socket, spring-preloaded open)
// 25 = Spring centering ring mount (seats the CS4323, bolts to part 16)
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

        // Static vent port (task 6, R60Lib.scad's R60_Vent_d/R60_Vent_Z
        // comment) -- 3 plain radial through-holes at 120deg, clear of
        // the neck skirt above and the door aperture below by
        // construction. Same "rotate for azimuth, then translate along
        // local +X = radial" idiom as the door bosses/pilots.
        //
        // Vent_StartR (crescent-edge fix, this review): the cut used to
        // start its flat face at R60_Body_ID/2-Overlap -- just inside the
        // ID ONLY on the hole's own radial centreline. Off that
        // centreline, at the cut's own tangential edges (+-R60_Vent_d/2),
        // the TRUE curved bore surface sits at radius
        // sqrt(startR^2+(R60_Vent_d/2)^2), which EXCEEDS R60_Body_ID/2
        // once startR is this close to it -- the flat starting face was
        // already past the true bore surface there, leaving a feathered
        // crescent of un-cut wall (measured up to 0.039mm thick) instead
        // of a clean round hole. Starting a full R60_Vent_d inside the ID
        // keeps the WHOLE starting face's tangential edges well below the
        // true bore radius (checked: sqrt(23.9^2+2.25^2)=24.0, 4.4mm of
        // margin under the 28.4mm bore) -- grows outward past the OD from
        // there, same direction as before, just further to travel.
        // Local $fn, same reasoning as the door bosses/pilots (a small
        // hole at an odd, non-90deg azimuth tessellates poorly at the
        // file-wide $fn).
        Vent_StartR = R60_Body_ID/2 - R60_Vent_d;
        for (i=[0:2])
            rotate([0,0,i*120])
                translate([Vent_StartR, 0, R60_Vent_Z])
                    rotate([0,90,0])
                        cylinder(d=R60_Vent_d,
                                 h=(R60_Body_OD/2-Vent_StartR)+Overlap, $fn=32);
    }
} // R60_EBayTube

// Deployment bay tube (petal transplant, replaces the shear-pin/spring-
// tab/tether-lug design entirely -- see tasks/lessons.md). This is now a
// FIXED tube: it bonds to the e-bay aft bulkhead's aft skirt at its
// forward rim (same joint the old design used, unchanged) and stays with
// the e-bay/nosecone section for good -- there is no separable joint
// here any more, so nothing in this tube shears, releases or reacts a
// load. It exists only to shroud the release stack (parts 15-24, all
// bolted to part 5's aft face, not to this tube) and give the spring
// room to extend.
//
// THE separable joint moved entirely to the petal cage (part 8/13):
// R60_PetalHub()/R60_Petals(), bolted to the fin-can side, sit INSIDE
// this tube's open aft end at rest (a plain sliding fit -- this tube's
// natural bore, R60_Body_ID=56.8, already gives the same 0.4mm clearance
// on the petal cage's R60_Coupler_OD=56.4 that every other internal fit
// in this design uses, so no feature is needed here to provide it) and
// telescope OUT of that open end when the spring fires. See
// R60_PetalHub()/R60_Petals()'s own module comments for the mechanism.
//
// Length: see R60Lib.scad's R60_Chute_L comment for the derivation
// (275mm, target 2.7mm of hub-spigot-into-fin-can engagement at
// R60_Petal_Len=140).
//
// SPLIT IN TWO (12th review): 275mm exceeds this project's own "fits
// 250mm Z" convention and the printer's own build volume as a single
// piece -- see R60_Chute_L's own comment for why (and why a longer tube
// does not fix the closure gap the way it looks like it should). Joined
// by an in-wall spigot/socket (R60Lib.scad's R60_ChuteSplit_* constants,
// same comment for the load this joint is sized against) rather than an
// internal sleeve, because the release stack (parts 15-23) and the
// retracted petal cage already fill this tube's 56.8mm bore through
// most of its own length -- nothing may narrow that bore anywhere along
// it. R60_ChuteTubeFwd() (part 3, keeps the tube's own forward-rim
// identity -- still bonds to the e-bay aft bulkhead exactly as before)
// carries the spigot at its own aft end; R60_ChuteTubeAft() (part 26,
// new) carries the matching socket at its own forward end and reaches
// the tube's own true aft/open end, where the petal cage telescopes
// through. No internal features beyond the joint: nothing in the old
// design's list (shear pins, spring reaction tabs, tether tie-off lug,
// tether relief channel) has anything to attach to any more -- the
// spring reacts between R60_FwdSpringEnd() (part 23, inside the petal
// cage) and the release stack (parts 15-23, on part 5's aft face);
// neither tube piece touches either.
module R60_ChuteTubeFwd(){
    Engage = R60_ChuteSplit_Engage;
    SpigotOD = R60_ChuteSplit_SpigotOD;
    Taper = 1;   // matches R60_ChuteTubeAft()'s own Taper -- the spigot
                  // must stop SHORT of the socket's own tapered mouth
                  // (Engage-Taper, not the full Engage), or its constant-
                  // OD tip pushes into the socket's own narrowing bore
                  // and the two collide (found by this session's own
                  // mating-fit probe: 0.058cm3 before this fix, 0.4mm
                  // clearance's own tolerance band is nowhere near that
                  // large).
    union(){
        R60_Tube(R60_ChuteSplit_Z);
        // Spigot: the tube's own inner half-wall only, extended past the
        // nominal cut -- the bore (R60_Body_ID) stays open all the way
        // through it, so nothing that needs the full 56.8mm bore ever
        // sees this feature.
        translate([0,0,R60_ChuteSplit_Z])
            difference(){
                cylinder(d=SpigotOD, h=Engage-Taper);
                translate([0,0,-Overlap])
                    cylinder(d=R60_Body_ID, h=Engage-Taper+Overlap*2);
            }
    }
} // R60_ChuteTubeFwd

module R60_ChuteTubeAft(){
    Engage = R60_ChuteSplit_Engage;
    SocketID = R60_ChuteSplit_SocketID;
    Taper = 1;   // 1mm chamfer so the socket's own ID step (58.8->56.8)
                  // prints without support -- same "taper so no support
                  // is needed" idiom NoseCone.scad's own gluing flange
                  // uses for its matching step.
    AftLen = R60_Chute_L - R60_ChuteSplit_Z;
    difference(){
        R60_Tube(AftLen);
        // Socket: bore the receiving piece's own first Engage mm out to
        // SpigotOD+clearance, leaving only its outer half-wall there --
        // the fwd piece's spigot nests inside this, both halves
        // together making up the full 1.6mm wall through the joint, so
        // the OD (60mm) is unbroken too, same as the bore.
        union(){
            translate([0,0,-Overlap])
                cylinder(d=SocketID, h=Engage-Taper+Overlap);
            translate([0,0,Engage-Taper])
                cylinder(d1=SocketID, d2=R60_Body_ID, h=Taper);
        }
    }
} // R60_ChuteTubeAft

// Forward bulkhead: closes the top of the e-bay, passes the camera harness.
//
// Vega sled mounting (7th review, finding 1/2 -- REPLACES the 6th
// review's 2-screws-per-end bolted feet, which could not physically be
// inserted; see R60Lib.scad's "Sled retention" comment for the full
// story). 2 ruthex RX-M3x5.7 inserts on the AFT (e-bay-facing, local z=0)
// face -- now each is a FIXED ANCHOR for one threaded rod's forward end
// (a stud, not a screw), matching R60_VegaSled()'s own rail holes exactly
// (R60Lib.scad's R60_Vega_Rail_*), same idiom as R60_MotorRetainer()'s
// own insert bosses. The plain disc's own T=6mm is shorter than the
// insert's own 6.7mm depth, so a local boss grows the disc AFT-ward
// (local z<0, into the e-bay, where the sled's rail actually lands) at
// each insert. This part is NOT symmetric front/back -- the boss/insert
// face MUST be the aft face, matching R60_Neck()'s own comment and
// r60_assembly.scad's Pair 1 frame (this module's own z=0 lands at tube
// z=R60_EBay_L-R60_Neck_Skirt_L-R60_FwdBulk_T, growing +z toward the neck
// skirt) -- mark the aft face on the print.
module R60_EBayFwdBulkhead(){
    T = R60_FwdBulk_T;
    Boss_d = R60_Vega_RodBoss_d;
    Insert_d = R60_Vega_RodInsert_d;
    Insert_h = R60_Vega_RodInsert_h;
    // Boss_Extra: how far the boss must grow PAST the plain disc's own
    // T=6mm so the insert (bored from the boss's own new outer/contact
    // face) still leaves R60_Vega_RodInsert_Backing of solid material
    // before the disc's forward face. SHARED with R60Lib.scad's
    // R60_Vega_Window_Z1 (not recomputed locally) -- that constant has to
    // know exactly how far this boss reaches into the e-bay so the sled's
    // own rail stops short of it, not just short of the plain disc face.
    Boss_Extra = R60_Vega_RodBoss_FwdExtra;
    assert(Boss_Extra > 0.5,
        str("R60_EBayFwdBulkhead: rod boss too shallow for a real ",
            "backing margin (Boss_Extra=", Boss_Extra, ")"));
    difference(){
        union(){
            cylinder(d=R60_Coupler_OD, h=T);
            for (x=[-R60_Vega_Rail_X, R60_Vega_Rail_X])
                translate([x, R60_Vega_Rail_Y, -Boss_Extra])
                    cylinder(d=Boss_d, h=Boss_Extra+Overlap);
        }
        translate([0,0,-Overlap]) cylinder(d=22, h=T+Overlap*2);
        for (x=[-R60_Vega_Rail_X, R60_Vega_Rail_X])
            translate([x, R60_Vega_Rail_Y, -Boss_Extra-Overlap])
                cylinder(d=Insert_d, h=Insert_h+Overlap);
    }
} // R60_EBayFwdBulkhead

// Aft bulkhead. THE structural part of the recovery system: the shock cord
// anchors here so deployment snatch never reaches the camera's three M3
// screws. Also carries the release mechanism's mounting interface.
//
// Servo (petal transplant): ONE servo now, not two -- single deploy has
// no tumble/tether phase to release separately (spec 4.1's old "two
// separate lines" distinction no longer applies; there is only the
// permanent shock cord). The servo itself is no longer built into this
// bulkhead at all: CRBBm_Activator (part 15) carries its own self-
// contained MG90S pocket (CableReleaseBBMicro.scad's own geometry,
// unmodified) and bolts to this bulkhead's aft face -- this disc only
// needs to provide that bolt pattern, not a shaft bore or horn slot
// reaching through it. Old servo 2 (tether release) is deleted outright.
//
// AFT SKIRT: unchanged in concept from the pre-transplant design (bonds
// into R60_ChuteTubeFwd()'s forward bore, 56.4mm OD, same 0.4mm-clearance
// convention as every internal joint here) but no longer carries shear
// pins -- there is no separable joint at this skirt any more (that moved
// entirely to the petal cage, parts 8/13/24, far aft -- see
// R60_PetalHub()'s module comment). It exists only to give this glued
// joint the same positive locating spigot every other internal joint in
// this design has.
//
// Activator mount (CRITICAL FIX, this review): the previous 3x M3
// ruthex-insert pattern at CRBBm_BottomBoltCircle_d() was wrong on two
// independent counts, found by actually rendering
// CRBBm_Activator(OD=R60_Coupler_OD) and measuring its aft face
// (Rocket60.scad's Render_Part=15, world z=-19, this session):
//  1. BottomBoltCircle_d is the Activator's own INTERNAL joint to
//     CRBBm_TopRetainer() (part 16) -- CRBBm_Activator()'s own
//     TopMountingBolts() cuts this SAME circle on its OPPOSITE
//     (forward, TopRetainer-ward) face, 22.5mm away in the real stack
//     (Rocket6551.scad's own SCR_Z-22.5 arithmetic) -- nothing on THIS
//     face ever matched it.
//  2. That circle's own hardware (CableReleaseBBMicro.scad's Bolt4* =
//     #4-40 UNC, major dia 2.845mm) is 0.16mm undersized for the M3
//     ruthex inserts this bulkhead was cutting for it regardless of
//     position.
// The real host-mount feature on this face is CRBBm_Activator()'s own
// nested EBay_TopPlate() -- a flat ring at the part's own aft-most extent
// (local Z=-19..-11, confirmed against the render's own zmin=-19)
// carrying 2 axial #10-24 threaded bosses, donor-native hardware built
// for exactly this job. CableReleaseBBMicro.scad gained 2 accessor
// functions this session (CRBBm_EBayTopPlate_BC_d()/_BossAz(), mirroring
// the existing CRBBm_BottomBoltCircle_d() idiom -- both are otherwise
// LOCAL to CRBBm_Activator()) so this bolt circle is derived from the
// real part, never hand-matched. Clocked R60_Act_Clock_a (R60Lib.scad,
// baked into R60_ReleaseActivator() itself) clear of the shock-cord holes
// and Vega rod pockets already cut into this same disc -- see that
// constant's own comment for the clearance scan.
//
// SEATING: the Activator's ring (its aft-most feature) butts directly
// against this bulkhead's own aft face (Total_H) -- there is no air gap
// between them. The mounting screws are #10-24, ~1-3/8in (35mm): through
// this disc/skirt's full Total_H=27mm, then Boss_t=8mm of thread
// engagement in the Activator's own boss, comfortably short of bottoming
// (CableReleaseBBMicro.scad's own ExternalThread cut runs the boss's
// full depth). Access is from this disc's OPEN forward face, before the
// deployment bay tube goes anywhere near the assembly -- see
// tools/r60_assembly.scad's Pair 33/34 for the mesh-verified seat and
// fastener-reach proof, and tasks/lessons.md for the mutation test that
// failed on the OLD mount before this fix.
module R60_EBayAftBulkhead(){
    T         = R60_AftBulk_T;   // shared with R60_EBayTube()'s Vega
                                   // rails (3rd review, defect 2)
    Skirt_L   = 15;               // aft skirt engagement into R60_ChuteTubeFwd()'s
                                   // forward bore -- a plain glue joint now
                                   // (no pins), local since nothing else derives
                                   // from it any more
    Total_H   = T + Skirt_L;
    Cord_d    = 5;
    // Skirt WALL (mass defect, this review): the skirt used to be a
    // solid Ø56.4 slug for its full Skirt_L=15mm -- 67.5cm3, ~65g, the
    // third-heaviest part in the rocket, with nothing passing through it
    // (the mount is now on this disc's own aft FACE, not through the
    // skirt's body) -- R60_Neck() thins its own skirt to a tube 3 lines
    // into this file for the exact same joint class, and this one never
    // got the same treatment. Hollowed to a plain R60_Wall_T tube for
    // its own middle span (T..Total_H-Web_T) -- same wall convention as
    // every airframe tube here -- leaving Web_T solid only at the very
    // tip.
    Web_T = 3;   // solid web at the skirt's own aft tip -- NOT part of
                  // the mass this fix removes: it is the only solid
                  // material in the skirt's own span the 2 mounting
                  // screws below can pass through to reach the
                  // Activator's real boss material beyond (the hollowed
                  // tube's own wall, R60_Wall_T=1.6mm radially, is far
                  // too thin at the boss's own Act_BC_d/2=21.775mm radius
                  // -- that radius sits inside the open bore, not in the
                  // wall, once hollowed). Prints as a horizontal internal
                  // ceiling over the hollow -- needs slicer support
                  // underneath (R60-PrintSettings.md sec 4, part 5).
    // Activator mount -- see module comment above.
    Act_BC_d = CRBBm_EBayTopPlate_BC_d(OD=R60_Coupler_OD);
    Act_Bolt_Clear_d = CRBBm_EBayTopPlate_Thread_d() + 0.4;   // #10-24
                         // clearance, same +0.4mm diametral convention as
                         // every other clearance hole in this file
                         // (R60_Cam_Bolt_d etc.)
    Act_Az = [CRBBm_EBayTopPlate_BossAz()+R60_Act_Clock_a,
              CRBBm_EBayTopPlate_BossAz()+R60_Act_Clock_a+180];
    // Clearance assert -- re-derived from the SAME live geometry the cut
    // below uses (not the R60_Act_Clock_a comment's own stated numbers),
    // so a future change to the shock-cord/rod-pocket layout that erodes
    // this margin fails loudly here instead of silently reopening the
    // 3.3mm collision this review fixed.
    Act_MinClear = min([
        for (az=Act_Az, kx=[-6,6])
            norm([Act_BC_d/2*cos(az)-kx, Act_BC_d/2*sin(az)-(-22)]),
        for (az=Act_Az, kx=[-R60_Vega_Rail_X, R60_Vega_Rail_X])
            norm([Act_BC_d/2*cos(az)-kx, Act_BC_d/2*sin(az)-R60_Vega_Rail_Y]),
    ]);
    assert(Act_MinClear > 8,
        str("R60_EBayAftBulkhead: activator mounting screw clears the ",
            "shock-cord/rod-pocket holes by only ", Act_MinClear,
            "mm -- recheck R60_Act_Clock_a"));
    difference(){
        union(){
            cylinder(d=R60_Coupler_OD, h=T);
            translate([0,0,T-Overlap])
                cylinder(d=R60_Coupler_OD, h=Skirt_L+Overlap);
        }

        // Shock cord anchor: two axial holes on the -Y side, running the
        // full Total_H so the cord threads through into the deployment
        // bay and on to the fin can's forward centring ring.
        for (x=[-6, 6])
            translate([x, -22, -Overlap])
                cylinder(d=Cord_d, h=Total_H + Overlap*2);

        // Vega sled mounting (7th review, finding 1/2): the rod's forward
        // end is already fixed at R60_EBayFwdBulkhead()'s own insert, so
        // this end is a BLIND, UNTHREADED guide pocket, not a second
        // anchor -- it only locates the rod's free aft tip. Matches
        // R60_VegaSled()'s own rail holes exactly (R60Lib.scad's
        // R60_Vega_Rail_*).
        for (x=[-R60_Vega_Rail_X, R60_Vega_Rail_X])
            translate([x, R60_Vega_Rail_Y, -Overlap])
                cylinder(d=R60_Vega_Rail_d, h=R60_Vega_RodPocket_Depth+Overlap);

        // Skirt bore -- see Web_T's own comment above for why the last
        // Web_T of it stays solid.
        translate([0,0,T-Overlap])
            cylinder(d=R60_Coupler_OD-2*R60_Wall_T, h=Skirt_L-Web_T+Overlap);

        // Activator (part 15) mounting screws -- see module comment.
        // THROUGH holes, not blind: the fastener enters this disc's own
        // forward face and threads into the Activator's own boss beyond
        // Web_T -- nothing here for it to bottom out against short of
        // that.
        for (az=Act_Az)
            rotate([0,0,az])
                translate([0, Act_BC_d/2, -Overlap])
                    cylinder(d=Act_Bolt_Clear_d, h=Total_H+Overlap*2);
    }
} // R60_EBayAftBulkhead

// CATS Vega sled. Manual sec 4.3.3: mounting holes are 60 x 27mm apart,
// M3, and spacers are recommended so nothing touches the board.
//
// Orientation matters: the GNSS patch antenna must face RADIALLY OUTWARD
// with no battery, loom or metal between it and the airframe wall. Mark
// the antenna side on the print.
//
// RETENTION (7th review, finding 1/2 -- REPLACES the 6th review's bolted
// feet, retired because they could not physically be inserted: see
// R60Lib.scad's own "Sled retention" comment for the full history and
// the mutation-test measurement that proved it). This plate still
// BRIDGES the full axial gap between the aft and forward bulkheads' own
// e-bay-facing faces (R60_Vega_Window_Z0/Z1, R60Lib.scad) -- the
// board-carrying middle is unchanged (L=R60_Vega_L+12=112, same
// R60_Vega_Holes pattern) -- but now via 2 continuous RAILS (constant
// 6.6x6.6mm cross-section, the rod's own clearance hole bored their FULL
// length, never just near one end) instead of discrete end feet. Each
// rail slides onto one M3 threaded rod: the FORWARD end is fixed (a stud
// threaded into R60_EBayFwdBulkhead()'s own insert), the rail's forward
// tip hard-stops against that bulkhead's boss face, and a nut+washer
// threaded onto the rod against the rail's own flat AFT face captures
// the sled axially. Both the sled's radial position
// (R60_Vega_Facing_Y_Nom) and its clocking about the tube axis (the 2
// rails' own X spread -- a rigid body pinned at 2 non-collinear points
// cannot spin about the tube axis) are geometric, not frictional.
//
// Assembly is now BENCH-BUILT, not built inside the tube (see
// R60Lib.scad's own module-adjacent comment for the full sequence): slide
// this plate onto the 2 rods (already threaded into the forward
// bulkhead), thread on the 2 aft nuts, THEN insert the whole cartridge
// into the tube. No fastener here is ever turned down a blind 150mm
// tube.
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
    Hole_d = R60_Vega_BoardHole_d;

    // Rail geometry -- see R60Lib.scad's own comments for each shared
    // constant's derivation. Rail_Y0/Rail_Y1 (8th review, finding 1) are
    // now READ DIRECTLY from R60Lib.scad's own R60_Vega_Rail_FwdTip_Y/
    // AftTip_Y -- NOT recomputed here from RailFwd_L/RailAft_L against
    // this module's own L, which is what let the two ends get swapped:
    // that local computation matched VegaSledPlaced()'s local-Y-to-
    // global-Z sign (local +Y = AFT, see R60Lib.scad's own comment on
    // these constants) at only one of the two call sites that mattered,
    // while r60_assembly.scad's RodSweep_Sled()/NutSweep_Sled() each
    // re-typed the SAME swapped arithmetic independently -- three
    // triplicated copies of one mistake all agreeing with each other.
    // Reading the shared constants here means every consumer now derives
    // from the one place the fwd/aft mapping is actually stated.
    Rail_X = R60_Vega_Rail_X;
    Rail_d = R60_Vega_Rail_d;
    Rail_WZ = R60_Vega_Rail_WZ;         // local Z (=radial once
                                          // assembled) AND local X width,
                                          // CONSTANT along the rail's
                                          // entire length -- deliberately
                                          // never a separate, narrower
                                          // "pad" only near one end: that
                                          // inconsistent cross-section is
                                          // exactly why the retired
                                          // bolted-foot design's own hole
                                          // was unreachable (see the
                                          // module comment above)
    Rail_Z_Local = R60_Vega_Rail_Z_Local;
    Rail_Y0 = R60_Vega_Rail_FwdTip_Y;   // local -Y = fwd -- hard stop
                                          // against the fwd bulkhead boss
    Rail_Y1 = R60_Vega_Rail_AftTip_Y;   // local +Y = aft -- nut face
    RailFwd_Reach = -L/2 - Rail_Y0;     // how far the rail extends past
                                          // the plate's own fwd edge
    RailAft_Reach = Rail_Y1 - L/2;      // how far the rail extends past
                                          // the plate's own aft edge
    assert(RailFwd_Reach > 5 && RailAft_Reach > 5,
        str("R60_VegaSled: rail too short to be a rigid mounting rail ",
            "(RailFwd_Reach=", RailFwd_Reach, ", RailAft_Reach=", RailAft_Reach, ") -- ",
            "e-bay length/skirt/bulkhead sizes no longer leave room for ",
            "the bridge"));

    difference(){
        union(){
            translate([-W/2, -L/2, 0]) cube([W, L, T]);
            for (h=R60_Vega_Holes)
                translate([h[0], h[1], T-Overlap])
                    cylinder(d=7, h=R60_Vega_Standoff_h+Overlap);
            // Rails, both sides -- CONSTANT cross-section the plate's
            // own board-carrying middle to well past each bulkhead face,
            // Rail_Y0..Rail_Y1 (see above). Local Z grown to Rail_WZ (not
            // just the plain plate's T=4) so the M3 hole gets a real wall
            // around it -- R60Lib.scad's R60_Vega_Rail_WZ comment: T
            // alone would leave only 0.3mm, the same "boss sized to fit
            // the OD, never checked against the hole it hosts" defect
            // class as finding 3.1's door boss.
            for (s=[-1,1])
                translate([s*Rail_X - Rail_WZ/2, Rail_Y0, 0])
                    cube([Rail_WZ, Rail_Y1-Rail_Y0, Rail_WZ]);
        }
        for (h=R60_Vega_Holes)
            translate([h[0], h[1], -Overlap])
                cylinder(d=Hole_d, h=T+R60_Vega_Standoff_h+Overlap*2);
        // Rod clearance holes -- bored along local Y (axial once
        // assembled) the rail's FULL length, Rail_Y0 to Rail_Y1, at the
        // SAME local Z the rail itself is centred on (Rail_Z_Local) --
        // there is no axial position along this bore where the
        // surrounding rail material does not exist, unlike the retired
        // per-end pad this replaces.
        for (s=[-1,1])
            translate([s*Rail_X, Rail_Y0-Overlap, Rail_Z_Local])
                rotate([-90,0,0])
                    cylinder(d=Rail_d, h=(Rail_Y1-Rail_Y0)+2*Overlap);
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

// Petal hub (part 8, replaces the spring/ball-lock carrier -- see
// tasks/lessons.md). R65_PetalHub()'s OWN two halves are NOT
// interchangeable ends: its skirt (local Z[-5,0], "// attaches to nose
// cone" in R65Lib.scad's own source) is a plain OD-hugging ring with
// PD_PetalHubBoltPattern's axial bolt-clearance holes -- a flat mounting
// face with nothing else on it; its PD_PetalHub() call (local Z[0,16],
// UNTRANSLATED, so it is the OTHER end) carries every petal-mating
// feature that exists on this part -- the ledge cuts, the pivot
// sockets the spring-holder's hinge axle rides in, and the spring
// clearance slots -- because that is the face PD_Petals()'s own root
// nests around once the two are placed at the donor's own relative
// offset (petal frame = hub frame - 9.5mm, Rocket6551.scad's
// ShowRocket(): hub at NC-5, petals at NC-14.5 -- confirmed this session
// by rendering both at that offset and finding an EMPTY intersection
// post-fix; pre-fix it read 1.31 cm3 at hub-local Z[16.70,21.50], the
// exact old spigot band). So the skirt (local Z<0) is the ONLY end free
// of petal-mating geometry, and it is also the end R65_PetalHub()'s own
// header comment says mounts to something external -- here, the fin-can
// side (the section that separates and pulls away at deployment --
// mirrored from Rocket6551, where the hub bolts to the nosecone side,
// because THIS design's e-bay/release-catch is forward instead of aft).
// The spigot (below) belongs on THAT end so the petal-mating end stays
// clear and points at the petals, not into the fin can's own bore.
//
// R60_Petals() (part 13) does NOT bolt to this hub at all -- see that
// module's own comment for the real joint (3x PD_PetalSpringHolder,
// bolted to each petal, hinging on the axle this hub's pivot sockets
// carry, preloaded by a coil spring seated in this hub's own integral
// bosses). When servo 1 (inside part 15's Activator) rotates the
// release catch's lock ring, R60_FwdSpringEnd() (part 23), captive
// until then, is driven forward by the CS4323 spring, rams the petals
// open past their own printed locks, and the whole fin-can+petal-hub
// section is pushed clear -- the airframe is never held together by
// anything that shears (see R60_ChuteTubeFwd()'s module comment: this
// joint replaces every shear-pin/ball-lock feature the design it
// supersedes needed).
//
// use<>-included, not hand-built: R65_PetalHub()/PD_Petals() are a
// flown mechanism (Rocket6551.scad, 2.6" single-deploy, CS4323 spring),
// not reimplemented here -- see the file header for the full transplant
// rationale.
//
// Aft spigot into the fin can's forward opening -- SAME joint
// R60_ChuteTubeFwd() used to make onto the fin can (part 9, UNCHANGED by
// this task), now carried here instead since the fixed deployment-bay
// tube no longer reaches that far. R60_PetalHubSpigot_L (R60Lib.scad) is
// shared with the constant the old joint used, not a second copy. Placed
// BELOW the skirt (local Z[-5-R60_PetalHubSpigot_L,-5], continuing the
// skirt's own aft face outward) -- NOT at z=16 (that band is the petal-
// mating end covered above, and is exactly where the pre-fix spigot
// collided with the petals' own root -- see the collision figures
// above). R65_PetalHub(OD=56.4) rendered and measured this session:
// Z[-5,16] -- its own internal geometry is a library module, not
// something this file's own constants derive, so this is stated from
// the rendered mesh, same convention as this repo's STL_VOL figures.
module R60_PetalHub(){
    $fn=90;   // use<>'d libraries' own file-scope $fn (their convention:
              // $preview?24:90 or ?36:90) never executes -- use<> only
              // imports definitions, not top-level statements -- so
              // without this, these calls inherit R60Lib.scad's own
              // $fn=180 and balloon small mechanism parts to 10-100x the
              // triangle count they need (confirmed: part 15 measured
              // 88838 triangles / 25.8MB at the inherited 180, the same
              // geometry at the donor's own intended 90 is a fraction of
              // that with no visible difference at this feature size).
    R65_PetalHub(OD=R60_Coupler_OD, nPetals=R60_nPetals, nBolts=R60_nPetals*2,
                 Skirt_h=5, HasWirePath=false);
    translate([0,0,-5-R60_PetalHubSpigot_L])
        R60_Tube(R60_PetalHubSpigot_L, od=R60_Coupler_OD, wall=R60_Wall_T);
} // R60_PetalHub

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
// is what puts flutter velocity at ~589 m/s (10th review: was 955,
// R60-PrintSettings.md's own sec 3 correction/flutter_Vf()'s own comment
// -- the mean-chord t/c bug that produced the old 955 figure inflated
// Vf 1.62x; 955 itself superseded a 9th-review 959, predating the 8th
// review's MMT_r correction), 2.9x the H182R's Vmax (~203 m/s) and 3.1x
// the H135W's -- both re-derived on the EXPOSED panel (root at the body
// OD, not the buried root at the MMT), which is the panel that actually
// flexes, and gated PER-MOTOR against a stated 1.5x floor
// (tools/rocket60_model.py's own FLUTTER_MIN_RATIO), not the retired
// single "Vf >= 3x fastest Vmax" gate this comment used to cite -- see
// that constant's own comment for why the gate itself was re-scoped, not
// just the number recomputed. Span grew 55->63mm (task report,
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
// bonding R60_PetalHub() (part 8, its own glued spigot -- NOT this
// tube, which stays with the e-bay section -- see that part's own
// module comment) on, per R60-PrintSettings.md.
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

// Petals (part 13, replaces the tether latch -- see tasks/lessons.md).
// Does NOT bolt to R60_PetalHub() (part 8) -- PD_Petals() has no axial
// holes at all (its own mesh starts at local Z=7.2, no base flange to
// put them in); the ONLY holes it has are the 2x radial #4-40 holes per
// petal at Z=17.25/25.25 (PD_Petals()'s own Bolt1_Z), which take
// R60_PetalSpringHolder() (part 24, see that module's own comment) --
// the real joint to the hub is that printed hinge, not a bolted flange.
// HasLocks=true prints the small integral catch nubs (PD_PetalLocks())
// that hold the petals shut against a light load; the CS4323 spring,
// once released and driving R60_FwdSpringEnd() into the petals, forces
// them open past those nubs and past R60_PetalSpringHolder()'s own
// hinge preload. This part IS the separable joint -- there is no second,
// independent shear feature anywhere else in this design any more (see
// R60_ChuteTubeFwd()'s module comment).
//
// Lock_Span_a=30 (donor's own Rocket6551.scad changelog, 0.9.5: "Petal
// locks now 30deg" -- deliberate, not the library default): PD_PetalLocks'
// own default (0) means Lock_Span_a=0 -> full-circumference lock ridge,
// about 4x the donor's actual flown engagement arc. Left un-set here
// before this review, silently inheriting the library default instead
// of the donor's own deliberately narrowed one.
//
// R60_Petal_Len (R60Lib.scad) derivation -- packing volume for a 24in
// main + Nomex protector + shroud lines, ~250 cm^3 at a stated ~0.2
// g/cm^3 packing-density assumption -- is in that constant's own
// comment, alongside why it also matches Rocket6551's own flown value.
module R60_Petals(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    PD_Petals(OD=R60_Coupler_OD, Len=R60_Petal_Len, nPetals=R60_nPetals,
              Wall_t=R60_Wall_T, AntiClimber_h=0, HasLocks=true,
              Lock_Span_a=30);
} // R60_Petals

// ============================================
// RELEASE HARDWARE (parts 15-24) -- CableReleaseBBMicro.scad's own
// printed BOM, `use<>`-instantiated at R60_Coupler_OD/R60_LockPin_d/
// R60_Ball_d/R60_nBalls, plus R65_FwdSpringEnd() (SpringEndsLib.scad's
// CS4323 dimensions). None of this geometry is re-derived here -- every
// module below is a THIN wrapper (parameters only) around the donor
// library's own proven parts, per the task's "instantiate, don't copy"
// instruction. See R60_ReleaseActivator()'s own comment for why
// CableReleaseBBMicro.scad, not the flown CableReleaseBBMini.scad, is
// the family actually used.
//
// Hardware note: this repo's own CableReleaseBBMicro.scad header BOM
// comment is STALE (lists 5/16" Delrin balls + a 6705 bearing) -- the
// LIVE code (confirmed this session) uses 6mm balls, a 6703-2RS bearing,
// and MR63 lock bearings. Print settings/BOM docs must cite the live
// code, not that header.
//
// Assembly stack, fixed (part 5) toward the petal cage (part 8/13):
// part 15 (bolts to part 5's aft face, carries the MG90S servo) -> parts
// 16-20 (bolt together per CableReleaseBBMicro.scad's own hardware
// stack) -> spring (no dedicated centering ring -- see the note above
// R60_FwdSpringEnd()'s own module comment) -> part 23 (bolts inside
// part 8's petal cage) -> parts
// 21/22 (locking pin + extension rod, running back through the spring's
// own ID to part 17's lock ring).

// Release activator (part 15). Servo mount + rotating-lock-ring driver;
// bolts to R60_EBayAftBulkhead()'s aft face (3x M3 into ruthex inserts,
// bolt circle DERIVED from this part's own CRBBm_BottomBoltCircle_d() --
// see that module's comment).
//
// BBMicro over BBMini -- MESH-MEASURED, not flight-history: rendered
// CRBBm_Activator(OD=R60_Coupler_OD) from BOTH families this session.
// BBMini's (the family Rocket6551.scad actually flies) measures
// max radius 31.8mm -- PAST this bore's own 28.4mm radius -- because its
// spoke/servo-strut geometry is built from absolute mm offsets, not
// values derived from its own OD argument (its own file even warns
// "Designed and works for Loc65 tube, may not scale", on this exact
// module). BBMicro's measures 28.2mm, landing exactly on
// R60_Coupler_OD/2 -- this repo's own standard 0.4mm-diametral-clearance
// convention, not a coincidence, because BBMicro's Activator DOES derive
// its spoke geometry from its own OD parameter. Every other shared part
// (lock ring, top retainer, outer bearing retainer) clears either
// family's own bore with 10+mm to spare -- the Activator is the one part
// that actually decides this, and BBMini's does not fit.
module R60_ReleaseActivator(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    // R60_Act_Clock_a (R60Lib.scad): clocks the part's own 2 EBay_TopPlate
    // mounting bosses clear of this bulkhead's shock-cord holes/Vega rod
    // pockets -- baked in here (not at the call site) so the standalone
    // print and every assembly reference agree on which way it was
    // printed. No X/Y flip (unlike parts 16/17/19/20/23): this part's own
    // local -Z (its EBay_TopPlate ring, the real host-mount face) already
    // lands at the SMALLER global station once translated to the
    // bulkhead's aft face -- see R60_EBayAftBulkhead()'s own module
    // comment.
    rotate([0,0,R60_Act_Clock_a])
        CRBBm_Activator(OD=R60_Coupler_OD);
} // R60_ReleaseActivator

// Release top retainer (part 16). Stationary; carries the 6703 bearing's
// inner race and the ball-lock pockets.
module R60_ReleaseTopRetainer(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    rotate([180,0,0])
        CRBBm_TopRetainer(LockPin_d=R60_LockPin_d, nBalls=R60_nBalls, Ball_d=R60_Ball_d,
                          LockRing_d=CRBBm_LockRingDiameter(), Flange_t=4, OD=0,
                          HasMountingBolts=true, GuidePoint=false, Light=true);
} // R60_ReleaseTopRetainer

// Release lock ring (part 17). Rotating; the servo (in part 15) turns
// this ~24deg to free the balls and release the locking pin (part 22).
module R60_ReleaseLockRing(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    rotate([180,0,0])
        CRBBm_LockRing(LockPin_d=R60_LockPin_d, Ball_d=R60_Ball_d, nBalls=R60_nBalls,
                       GuidePoint=false);
} // R60_ReleaseLockRing

// Release outer bearing retainer (part 18). Bolts to, and rotates with,
// part 17.
module R60_ReleaseOuterBearingRetainer(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    CRBBm_OuterBearingRetainer(Light=true);
} // R60_ReleaseOuterBearingRetainer

// Release trigger post (part 19). Rotates with part 17/18; the servo
// horn (part 15) strikes this to kick the lock ring off its magnetic
// detent.
module R60_ReleaseTriggerPost(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    rotate([180,0,0]) CRBBm_TriggerPost();
} // R60_ReleaseTriggerPost

// Release magnet bracket (part 20). Rotates with part 17/18; holds one
// of the two N42 magnets forming the over-centre detent against part
// 15's own fixed magnet post.
module R60_ReleaseMagnetBracket(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    rotate([180,0,0]) CRBBm_MagnetBracket();
} // R60_ReleaseMagnetBracket

// Release extension rod (part 21). Extends the locking pin (part 22)
// through the spring's own ID (40.50mm, clears R60_LockPin_d=12mm with
// room) up to R60_FwdSpringEnd() (part 23).
module R60_ReleaseExtensionRod(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    CRBBm_ExtensionRod(LockPin_d=R60_LockPin_d, Len=26, ID=0.190*25.4, Light=true);
} // R60_ReleaseExtensionRod

// Release locking pin (part 22). The load path: captive in part 17's
// ball pockets until the servo releases it.
module R60_ReleaseLockingPin(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    CRBBm_LockingPin(nBalls=R60_nBalls, LockPin_d=R60_LockPin_d, LockPin_Len=18,
                     GuidePoint=false);
} // R60_ReleaseLockingPin

// R60_CenteringRingMount() (part 25, below the release hardware block
// per the parts-list numbering) now gives the CS4323 the real seat this
// used to punt on -- see that module's own comment for the fix and the
// mesh-measured evidence (R60_ReleaseActivator()'s own module comment)
// it answers. "~4.5mm of self-centering radial slack" was never a
// substitute for a seat: it says the spring will not wander sideways, it
// says nothing about what its own axial preload rests on, which was the
// real defect (the activator's 1.2mm spokes/servo braces, pad to
// apogee).

// Forward spring end (part 23). The moving piston: captive on the
// locking pin (part 22) until the servo releases it, then driven forward
// by the CS4323 spring into the petals (part 13), popping them open. Not
// bolted to R60_PetalHub() at all -- R65_FwdSpringEnd()'s own module
// comment is "This locks onto the bottom of the petals": it threads onto
// part 22's own extension (the ExternalThread center hole) and its own
// "Petal Locks" cut seats directly against part 13's lock feature, both
// independent of part 8.
module R60_FwdSpringEnd(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    rotate([180,0,0])
        R65_FwdSpringEnd(OD=R60_Coupler_OD, ID=R60_Coupler_OD-1.8, LockPin_d=R60_LockPin_d,
                         nRopes=6, Skirt_h=25, HasServoConnector=false);
} // R60_FwdSpringEnd

// Petal spring holder (part 24). THE hinge -- dropped entirely from the
// first transplant attempt (tasks/lessons.md). PD_PetalSpringHolder() is
// a separate print, bolted to EACH petal (part 13) with 2x #4-40 through
// the petal's own only holes (radial, at petal-local Z=17.25/25.25 --
// see R60_Petals()'s own module comment), carrying a printed hinge axle
// that rides in R60_PetalHub()'s (part 8) own pivot socket, preloaded
// open by a 5/16" OD coil spring seated in this same part's own integral
// spring receiver. 3x printed (one per petal) -- see R60_PSH_Placed()
// below for where each one sits once assembled.
//
// Donor geometry, un-parameterised (PD_PetalSpringHolder() takes no
// arguments at all) -- nothing here to derive from R60_Coupler_OD; the
// part is sized for the donor's own PetalWidth/Bolt4Inset constants,
// both shared file-scope constants this design already uses unchanged.
// Rocket6551 prints this: Rocket6551_petalspringholder.3mf is a flown
// artifact.
module R60_PetalSpringHolder(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    PD_PetalSpringHolder();
} // R60_PetalSpringHolder

// R60_PSH_Placed(j): where petal spring holder j (0..R60_nPetals-1)
// sits, assembled, in R60_PetalHub()'s OWN local frame (same frame
// R60_PetalHub() itself renders in, Render_Part==8) -- shared by the
// standalone-part convenience preview below and by
// tools/r60_assembly.scad's own pairs, so the placement is derived once,
// not restated (rule 4).
//
// Derivation (mesh-verified, not eyeballed -- see tasks/lessons.md's
// own "follow the donor, don't narrate it" lesson this fix exists to
// close): PD_Petals()'s 2 bolt holes are at petal-local
// Z=Bolt1_Z=17.25 and Bolt1_Z+Bolt4Inset*2=25.25, radial, entering at
// petal-local Y=OD/2 (PD_Petals()'s own source). PD_PetalSpringHolder()'s
// own 2 matching Bolt4Hole()s are at ITS local Z=20 and
// 20+Bolt4Inset*2=28, also radial, entering at ITS local Y=0 -- SAME
// Bolt4Inset*2=8mm spacing, and BOTH already built with the identical
// rotate([-90,0,0]) hole axis, so no relative ROTATION is needed between
// the two parts, only a translate: petal-local (0,OD/2,-2.75) (20-17.25=
// 2.75=28-25.25, the one constant offset consistent with both holes at
// once -- the only pairing that keeps the two parts' own fixed 8mm hole
// spacing equal). Converted to R60_PetalHub()'s own frame with this
// transplant's own established petal-to-hub offset (R60_PetalHub()'s own
// module comment: petal frame = hub frame - 9.5mm): hub-local
// (0, R60_Coupler_OD/2, 6.75).
//
// Checked against the OTHER mating interface too (the axle vs. the
// hub's own pivot-socket cut, PD_PetalHub()'s own source): this places
// the holder's axle centre within ~1mm of the socket's own stated seated
// position (hub-local Y=21.2,Z=7) -- intersection(R60_PetalHub(),
// R60_PSH_Placed(0)) measures ~0.007cm3 (tools/r60_assembly.scad Pair
// 36), a sub-mm hinge-boss/clearance-cut residual at this scale (two
// orders of magnitude below the 1.31cm3 upside-down-hub defect this
// review fixed), consistent with ordinary FDM print-fit tolerance on a
// moving joint, not a placement error -- the bolt-hole alignment above
// is exact (matched to the tenth of a mm from both parts' own source
// constants), and is the harder, non-negotiable constraint of the two.
module R60_PSH_Placed(j=0){
    rotate([0,0,360/R60_nPetals*j])
        translate([0, R60_Coupler_OD/2, 6.75])
            R60_PetalSpringHolder();
} // R60_PSH_Placed

// Spring centering ring mount (part 25). Fix 4: gives the CS4323 a real
// seat -- mesh-measured this session, the release stack's own rotating
// parts (lock ring r=17.5, trigger post/magnet bracket r~=19.1) sit well
// inside the spring's own r=20.25 bore, so with NOTHING seating it the
// spring's full preload rested on the activator's own 1.2mm spokes/servo
// braces from pad to apogee, a coil running ~1.1mm from the rotating
// trigger post -- see R60_ReleaseActivator()'s own module comment for the
// mesh-measured evidence this fix answers.
//
// CableReleaseBBMicro.scad's own CRBBm_CenteringRingMount() used to
// hardcode a different, smaller spring (SE_Spring3670) with no override
// -- fixed there (this task, additive-only: Spring_OD/Spring_ID are now
// real parameters, mirroring CableReleaseBBMini.scad's own signature,
// which Rocket6551.scad calls with Spring_OD=SE_Spring_CS4323_OD()) so
// it can be instantiated here for the CS4323 instead of forced or
// dropped.
//
// Verified mesh-against-mesh, not asserted: the spring cavity's own
// inner wall (z=4..6 band, this part's rendered mesh) measures
// Ø44.29 -- SE_Spring_CS4323_OD()=44.30 -- so the spring seats on this
// part's own step, not float. Below the spring (z=0..3.4 band) the ONLY
// opening is the Ø30 lock-pin guide -- everything else is this part's
// own solid disc, the fence that keeps the spring's coils out of the
// rotating lock-ring/trigger-post/magnet-bracket's own r<=19.1
// envelope below it.
//
// Bolts to CRBBm_TopRetainer() (part 16) via its own
// CRBBm_MountingBoltPattern -- same joint class as parts 16/17/19/20/23
// (R60_ReleaseTopRetainer() etc.'s own module comments), so it gets the
// same end-for-end rotate([180,0,0]) for its own standalone/print
// rendering here. Where it sits RELATIVE to the rest of the release
// stack (mirroring the donor's own ShowCableRelease() offset,
// translate([0,0,TopRetainerFlange_t+8.7]) off the SCR stack's own
// reference face, restated at this design's own TopRetainerFlange_t=4 --
// R60_ReleaseTopRetainer()'s own Flange_t=4 argument -- giving 12.7mm) is
// tools/r60_assembly.scad's own job, same convention as every other
// assembly-relative offset in this file (Pair 33's own translate(46), not
// baked into R60_ReleaseActivator() itself).
module R60_CenteringRingMount(){
    $fn=90;   // see R60_PetalHub()'s own comment for why this is needed
    // nRopes=6, not 0: CRBBm_CenteringRingMount()'s own "Spokes" loop
    // (the ONLY structural connection between the outer body-centering
    // ring and the inner spring-seat/lock-pin-guide hub) shares this
    // SAME loop variable with the "Ropes" cut -- nRopes=0 does not just
    // drop the (here, unneeded) retention-cord holes, it deletes the
    // spokes too, silently splitting this part into 3 disconnected
    // pieces (confirmed: tools/verify_rocket60.py's own connected-
    // components check, `components()`==3 at nRopes=0, ==1 at nRopes=6).
    // The resulting rope holes are unused but harmless -- this repo's
    // own shock cord routes bulkhead -> piston -> hub (R60_Petals()'s
    // module comment), not through this mount.
    rotate([180,0,0])
        CRBBm_CenteringRingMount(OD=R60_Coupler_OD, nRopes=6,
            Spring_OD=R60_Spring_OD, Spring_ID=R60_Spring_ID);
} // R60_CenteringRingMount

// ============================================
// DISPATCH
// ============================================
if (Render_Part==0) R60_TestRing();
if (Render_Part==1) R60_Neck();
if (Render_Part==2) R60_EBayTube();
if (Render_Part==3) R60_ChuteTubeFwd();
if (Render_Part==4) R60_EBayFwdBulkhead();
if (Render_Part==5) R60_EBayAftBulkhead();
if (Render_Part==6) R60_VegaSled();
if (Render_Part==7) R60_Door();
if (Render_Part==8) R60_PetalHub();
if (Render_Part==9)  R60_FinCan();
if (Render_Part==10) R60_Fin();
if (Render_Part==11) R60_MotorRetainer();
if (Render_Part==12) R60_MotorSpacer();
if (Render_Part==13) R60_Petals();
if (Render_Part==14) R60_ThrustRing();
if (Render_Part==15) R60_ReleaseActivator();
if (Render_Part==16) R60_ReleaseTopRetainer();
if (Render_Part==17) R60_ReleaseLockRing();
if (Render_Part==18) R60_ReleaseOuterBearingRetainer();
if (Render_Part==19) R60_ReleaseTriggerPost();
if (Render_Part==20) R60_ReleaseMagnetBracket();
if (Render_Part==21) R60_ReleaseExtensionRod();
if (Render_Part==22) R60_ReleaseLockingPin();
if (Render_Part==23) R60_FwdSpringEnd();
if (Render_Part==24) R60_PetalSpringHolder();
if (Render_Part==25) R60_CenteringRingMount();
if (Render_Part==26) R60_ChuteTubeAft();
