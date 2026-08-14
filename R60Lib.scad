// ***********************************
// Project: 3D Printed Rocket
// Filename: R60Lib.scad
// for Rocket 60 (60mm body, camera nosecone)
// by Tõnu Samuel
// Created: 2026-08-13
// Units: mm
// ***********************************
//  ***** Notes *****
//
// Shared constants and modules for the 60mm camera rocket. No printable
// part lives here - see Rocket60.scad.
//
// The airframe OD is NOT a design choice. It is the measured base
// diameter of the user's "Nose Cone.STEP", which cannot be modified.
//
//  ***** History *****
//
function R60Lib_Rev()="R60Lib 0.1.0";
echo(R60Lib_Rev());
// 0.1.0  2026-08-13  First code.

Overlap = 0.05;
IDXtra  = 0.2;
$fn = $preview ? 36 : 180;

// ============================================
// AIRFRAME
// ============================================
R60_Body_OD    = 60.0;
R60_Wall_T     = 1.6;
R60_Body_ID    = R60_Body_OD - 2*R60_Wall_T;   // 56.8
// 0.4mm diametral clearance, same convention as PeregrineNoseCone.scad.
// Derived, so a wall-thickness change can never silently produce an
// interference fit here.
R60_Coupler_OD = R60_Body_ID - 0.4;            // 56.4

// R60_EBay_L history (superseded -- 5th review, finding 1): this used to
// be derived from the arming switch's own Z window on the TUBE wall (grew
// 160->165->177 across the 3rd/4th reviews chasing that window's margin).
// The switch has since moved onto the access door (R60_Door()'s own
// module comment) and no longer has a Z window on this tube at all -- the
// 177 figure is kept AS IS ("do not grow the e-bay" -- 5th review) but is
// no longer switch-derived; its remaining justification is the one below
// (Vega 100 + upright MG90S 29 + slack). If this ever needs re-deriving
// from scratch, do not reintroduce a switch-clearance term here -- the
// switch's own placement is now entirely local to R60_Door() and cannot
// invert this tube's length again.
R60_EBay_L   = 177;   // fits Vega 100 + upright MG90S 29 + slack
R60_Chute_L  = 180;   // spring mechanism 80 + 24in main 100
R60_FinCan_L = 228;

// Chute-bay-to-fin-can spigot (3rd review, should-fix 6). Every OTHER
// internal airframe joint in this design gets a Ø56.4 (R60_Coupler_OD)
// spigot locating it concentrically and giving it something more than a
// glue ring to resist bending -- the neck's skirt into the e-bay tube,
// the e-bay aft bulkhead's skirt into the chute tube -- except this one,
// which used to be a bare butt bond between two 1.6mm walls across a
// 662mm airframe. Built onto the chute tube's own aft end, PAST its
// existing R60_Chute_L (not into R60_FinCan() -- that part's own forward
// annulus is already open and unmodified, so nothing there needs to
// change).
//
// R60_FinCan_FwdOpen_L (4th review, should-fix 8): the fin can's own
// forward centring ring sits this far from the tube's own forward tip
// (R60_FinCan()'s ring-Z loop), so this is exactly how much open annulus
// is actually free to receive a spigot there. Shared, not restated,
// so the two can never independently drift the way they did before this
// fix: R60_FinCanSpigot_L used to be a SECOND, independently-typed "6"
// that happened to equal this figure exactly -- a bare tangency, zero
// axial clearance, so the spigot bottomed on the ring before the
// airframe's own outer OD faces could close flush (the review's own
// pair-7 probe read 0cm3 for this reason: not a clear fit, a touching
// one). R60_FinCanSpigot_Clear states the axial clearance explicitly,
// same "derived minimum, not hand-matched" idiom as R60_Tether_Clear.
R60_FinCan_FwdOpen_L   = 6;
R60_FinCanSpigot_Clear = 0.5;   // stated axial print-tolerance clearance
R60_FinCanSpigot_L = R60_FinCan_FwdOpen_L - R60_FinCanSpigot_Clear;   // 5.5

// Neck skirt length -- shared with R60_EBayTube() so the arming switch
// hole can be positioned clear of it by construction instead of a
// hand-picked Z that can silently start overlapping it again. See task
// report (the switch used to land inside this skirt's own span).
R60_Neck_Skirt_L = 19;

// E-bay aft bulkhead disc thickness (R60_EBayAftBulkhead()'s own T) --
// shared with R60_EBayTube() (3rd review, defect 2) so the Vega
// retention rails can be kept clear of the disc BY CONSTRUCTION, the
// same treatment R60_Neck_Skirt_L above already gets for the skirt end.
// Was a second, local-only `T=12` inside R60_EBayAftBulkhead() with
// nothing else deriving from it -- the rails' own Z window had no way to
// know where the disc actually sits, and silently overlapped it.
R60_AftBulk_T = 12;
// E-bay forward bulkhead disc thickness (R60_EBayFwdBulkhead()'s own T)
// -- shared for the same reason as R60_AftBulk_T above: the rails must
// also clear this bulkhead, which sits immediately below the neck skirt.
R60_FwdBulk_T = 6;

// Access door aperture (R60_EBayTube()) and the retaining frame/bosses on
// R60_Door() that mate with it -- shared so the two are always derived
// from the same opening, never two hand-typed numbers. See task report:
// the door used to be a bare plug with 0.35mm of play and nothing to stop
// it falling through, and nothing behind its screw holes but open air.
R60_Door_Open_W  = 36;    // aperture width, X
R60_Door_Open_H  = 85;    // aperture height, Z
R60_Door_Overlap = 6;     // the door's retaining cover/frame overlaps
                           // solid tube material by this much all around
R60_Door_Hole_Clear = 3;  // fastener bosses sit this far outside the
                           // aperture's own edge, on solid material

// ============================================
// NOSECONE INTERFACE - MEASURED, DO NOT ROUND
// ============================================
// Taken from "Nose Cone.STEP" with FreeCAD planar sections. The STEP is
// authored in a parent-assembly frame with the base plane at Y=501.95;
// these are restated as height above that plane.
R60_NC_Base_OD  = 59.98;   // outer diameter at the base plane
R60_NC_Base_ID  = 54.25;   // base annulus bore
R60_NC_Bore_Low = 53.25;   // bore 0.5..1.5mm above the base
R60_NC_Bore_Gen = 55.60;   // bore higher up

// ============================================
// CAMERA INTERFACE - MEASURED, DO NOT ROUND
// ============================================
// From ~/Camera.STEP. Three M3 heat-set inserts (ruthex RX-M3x5.7) on one
// circle. The angles are deliberately NOT 120deg apart - the asymmetry
// keys the camera's clocking, so preserve them exactly.
R60_Cam_BC_R    = 18.98;                  // bolt circle RADIUS
R60_Cam_Ang     = [52.2, -52.2, 180.0];
R60_Cam_Bolt_d  = 3.4;                    // M3 clearance

// ============================================
// CATS VEGA  (manual v2.0.0 sec 4.3.3)
// ============================================
// Manual says 15mm total height, catsystems.io says 21mm. Cut for 21.
R60_Vega_L = 100;
R60_Vega_W = 33;
R60_Vega_H = 21;
// L-shaped M3 pattern, 60mm apart along the length, 27mm across the width.
// X = across width, Y = along length.
R60_Vega_Holes = [[-13.5, -25], [-13.5, +35], [+13.5, +35]];
R60_Vega_BoardHole_d = 3.4;   // M3 clearance, the board's own mounting
                                // screws into R60_VegaSled()'s standoffs
                                // -- promoted from a local module variable
                                // to a shared constant so the rail's own X
                                // position (below) can be derived from it
                                // without a second, independently-typed
                                // 3.4
R60_Vega_Standoff_h = 4;   // manual recommends spacers under the board
R60_Vega_Sled_T = 4;                  // sled plate thickness -- unchanged
                                       // by the 7th-review retention
                                       // redesign below; the board-
                                       // carrying middle's own radial
                                       // reach is untouched

// Sled retention -- REPLACES the bolted-bridge feet (7th review, finding
// 1: the FOURTH distinct failure of Vega retention -- round 2 shipped
// none at all, round 3's rails blocked the bulkheads, round 5's "fixed"
// rails had no facing-gap solution, and round 6's 4 bolted feet could not
// physically be INSERTED: each foot's Ø3.4 shank clearance hole existed
// only within its own short foot-pad span, never continuing through the
// board-carrying plate between it and the tube's open end -- the plate's
// own T=4mm is solid at every (x,z) that hole ever occupied, for the
// plate's FULL 112mm length. A screw fed in from the only accessible
// point ("drive the 4 screws from inside the open bore") had nowhere to
// enter; it would have to travel 100+mm through solid plastic before
// reaching a hole that only started at the very end. Confirmed by
// mutation test (7th review): sweeping the old Ø3.4 shank + Ø5.5 SHCS
// head along its own insertion axis and intersecting against
// R60_VegaSled()'s own rendered mesh gives a real 3.91cm3 collision, not
// a marginal near-miss -- see tools/r60_assembly.scad's FastenerSweep()
// pairs, which reproduce this on every fastener in the design now.
//
// Replaced with the standard high-power e-bay pattern: 2 threaded M3
// rods span the full window between the bulkheads; the sled slides onto
// them through 2 continuous, CONSTANT-cross-section RAILS (never a
// separate end pad the hole exists in only near the tip -- that
// inconsistent cross-section was the actual defect, not the concept of
// a foot/pad at all); a nut+washer per rod, bearing on the rail's own
// flat aft face, captures the sled axially against a hard stop at the
// forward end. Both the sled's radial position and its clocking about
// the tube axis are fixed by the 2 rods' own (X,Z) positions once
// threaded/slid on -- geometric, not frictional, the one property the
// retired design already had right.
//
// FASTENER ACCESS ROUTE: this is now a BENCH-BUILT CARTRIDGE, not
// assembled inside the tube. On the bench: thread both rods into
// R60_EBayFwdBulkhead()'s own inserts (fixed, permanent -- the same
// ruthex convention used everywhere else in this file); slide
// R60_VegaSled() onto the two rods until it hard-stops against the
// forward bulkhead's own boss face; thread the aft nut+washer onto each
// rod against the rail's own aft face, capturing the sled. Insert the
// WHOLE cartridge (both bulkheads + sled, now one rigid unit) into the
// tube forward-bulkhead-first; glue the forward bulkhead at its station;
// the aft bulkhead seats last, its 2 blind pockets (below) simply
// receiving the rods' free aft tips as it seats. No tool ever turns a
// fastener 150mm down a blind tube -- every rod/nut is manipulated in
// open bench space. R60-PrintSettings.md's assembly order is updated to
// match.
R60_Vega_Wall_Clear   = 0.4;

// Rail geometry (7th review, finding 1/2). CONSTANT 6.6x6.6mm cross-
// section (rod clearance + 2x a real R60_Wall_T print wall, both X and
// Z -- same stated-minimum-wall idiom as every other boss in this file)
// along the rail's ENTIRE length, so there is no axial position along
// the rod's own path where the hole does not exist.
R60_Vega_Rail_d        = 3.4;    // M3 rod clearance, matching every other
                                    // M3 clearance hole in this file
R60_Vega_Rail_WZ = R60_Vega_Rail_d + 2*R60_Wall_T;   // 6.6 (both X and Z)
// Rail X position: OUTBOARD of the board's own mounting holes
// (R60_Vega_Holes' own +-13.5mm), not merely clear of the board's
// printed footprint -- the board sits well above the rail in Z
// (standoffs start at Sled_T=4, the rail tops out at 6.6, so the two
// never collide there regardless), but the rail's own rod-clearance hole
// and a standoff's own board-screw hole are two DIFFERENT holes that
// must not merge into one ragged void. R60_Vega_Rail_HoleWall is that
// spacing -- deliberately smaller than R60_Wall_T: it is internal
// hardware-to-hardware clearance between two hand-driven M3 fasteners,
// neither of which loads across this specific gap, not the airframe's
// own pressure-boundary wall convention.
R60_Vega_Rail_HoleWall = 1.0;
R60_Vega_Rail_X = abs(R60_Vega_Holes[0][0]) + R60_Vega_BoardHole_d/2
                  + R60_Vega_Rail_HoleWall + R60_Vega_Rail_d/2;   // ~17.9
// Sled plate width -- DERIVED from the rail's own footprint (rail's
// outer edge + a real R60_Wall_T print wall to the plate's own edge),
// not the board's width plus a free constant the way it used to be: the
// rail has to physically fit on the plate, so the plate is sized around
// it, the same "derive the boss from what it hosts, not the other way
// around" rule finding 3.1 (6th review) already established for the
// door boss.
R60_Vega_Sled_W = 2*(R60_Vega_Rail_X + R60_Vega_Rail_WZ/2 + R60_Wall_T);   // ~45.6

// Radial position: closed-form, the DEEPEST the plate's own flat back can
// sit while its two long back corners (+-Sled_W/2, Facing_Y) still clear
// the tube ID by a stated print clearance -- i.e. as close to the -Y wall
// (opposite the door/switch, both +Y) as the plate's own width allows,
// same 0.4mm clearance convention as R60_Coupler_OD. Formula unchanged
// from the 6th-review fix; only its input (Sled_W, above) moved.
R60_Vega_Facing_Y_Nom = -sqrt(pow(R60_Body_ID/2 - R60_Vega_Wall_Clear, 2)
                               - pow(R60_Vega_Sled_W/2, 2));   // ~-16.25

// Forward rod anchor -- see R60_VegaSled()'s own module comment for the
// full derivation. Defined BEFORE the axial window below because the
// window's own forward edge has to account for R60_Vega_RodBoss_FwdExtra
// (see that constant's own comment) -- OpenSCAD does not forward-
// reference top-level assignments (confirmed empirically), so anything
// the window formula reads must already be defined above it.
R60_Vega_Rail_FwdClear = 0.2;    // small assembly gap between the rail's
                                    // own forward tip and the bulkhead's
                                    // mounting face -- the rod/nut draws
                                    // it flush, not a print fit relying
                                    // on being dead-on
// Aft-end clearance is NOT the same small print-tolerance gap: unlike
// the retired screw-head design, real hardware (a nut + washer, ~3-4mm
// stack) sits AT the rail's own aft face, and it has to physically fit
// in the space before the aft bulkhead's own e-bay-facing surface, not
// just clear a manufacturing tolerance. Stated, not derived from the
// hardware's own dimensions (no datasheet for a generic M3 nut+washer is
// worth citing) -- comfortably covers a nut (~2.4mm) + washer (~0.5mm) +
// turning clearance for a driver/pliers.
R60_Vega_Rail_AftClear = 5.0;
R60_Vega_RodInsert_d = 4.0;      // ruthex RX-M3x5.7 hole per datasheet --
                                  // same physical part/hole size as
                                  // R60_TetherInsert_d and
                                  // R60_MotorRetainer()'s own Insert_d,
                                  // restated (that constant is defined
                                  // AFTER this point in the file)
R60_Vega_RodInsert_h = 6.7;      // same ruthex convention (datasheet:
                                  // insert length 5.7 + 1mm), matches
                                  // R60_MotorRetainer()'s Insert_h
R60_Vega_RodInsert_Backing = 1.0;    // solid material left BEHIND the
                                       // insert's own floor, same
                                       // convention as R60_EBayTube()'s
                                       // door-boss backing
R60_Vega_RodBoss_d   = 8;        // >= insert hole + 2x1.6mm min wall, same
                                  // convention as every other ruthex boss
                                  // in this file
// R60_EBayFwdBulkhead()'s own disc is only R60_FwdBulk_T=6mm -- shorter
// than the insert's 6.7mm depth -- so that module grows a LOCAL boss
// AFT-ward (into the e-bay, past its own z=0 face) at each insert, same
// as the retired foot design's own boss (this is the ONE piece of that
// design reused as-is -- the boss/insert stack itself was never the
// defect, only how the sled's own hole reached it).
R60_Vega_RodBoss_FwdExtra = R60_Vega_RodInsert_h + R60_Vega_RodInsert_Backing
                             - R60_FwdBulk_T;   // ~1.7

// Forward bulkhead's own TRUE placement in the tube frame -- its plain
// disc's own z=0 (e-bay-facing) face, UNCHANGED by the rod boss (the
// boss reaches FORWARD of this face, into the e-bay, from local
// z=-R60_Vega_RodBoss_FwdExtra to 0 -- see R60_EBayFwdBulkhead()'s own
// module comment). Matches r60_assembly.scad's Pair 1 transform
// (R60_EBay_L-R60_Neck_Skirt_L-R60_FwdBulk_T) -- restated here as a named
// constant, not a second inline expression, specifically so
// R60_Vega_Window_Z1 (below) and the module's own placement can never
// silently diverge on what "the forward bulkhead's face" means.
R60_FwdBulkhead_TubeZ0 = R60_EBay_L - R60_Neck_Skirt_L - R60_FwdBulk_T;

// Axial window the sled now spans, end to end: the aft bulkhead's own
// e-bay-facing face (tube z=R60_AftBulk_T -- R60_EBayAftBulkhead()'s own
// z=0, the "pocket-opening" face, see that module's comment) to the
// forward bulkhead's own rod-BOSS face (R60_FwdBulkhead_TubeZ0 minus
// R60_Vega_RodBoss_FwdExtra -- R60_EBayFwdBulkhead()'s own boss tip, the
// NEAREST solid material the rail's forward tip can actually reach, not
// the disc's own plain face behind it). Grows/shrinks automatically with
// R60_EBay_L or either bulkhead's thickness instead of the sled silently
// falling short (or overlapping) the next time either changes.
R60_Vega_Window_Z0 = R60_AftBulk_T;
R60_Vega_Window_Z1 = R60_FwdBulkhead_TubeZ0 - R60_Vega_RodBoss_FwdExtra;
// Sled's own axial centre once assembled -- the window's midpoint, NOT
// R60_EBay_L/2 (the window is not centred on the tube: the aft bulkhead
// alone is 12mm, the forward bulkhead + neck skirt together are 25mm).
// The board-carrying middle plate stays centred here; the rail (below)
// extends different amounts fwd/aft of it since the two end clearances
// now differ (Rail_FwdClear vs the much larger Rail_AftClear).
R60_Vega_AxialCenter = (R60_Vega_Window_Z0 + R60_Vega_Window_Z1) / 2;
// Rail's own local Z centre (=radial once assembled) for its hole, both
// local (R60_VegaSled()'s own frame, Z=0 at the plate's base) and global
// (tube frame) -- shared so R60_EBayAftBulkhead()/R60_EBayFwdBulkhead()
// drill their own insert/pocket holes at the IDENTICAL position the
// rail's own hole lands at, not an independently-typed match.
R60_Vega_Rail_Z_Local = R60_Vega_Rail_WZ / 2;
R60_Vega_Rail_Y = R60_Vega_Facing_Y_Nom + R60_Vega_Rail_Z_Local;

// Aft bulkhead's blind rod-guide pockets (7th review): NOT threaded, NOT
// a full pass-through -- the rod's own forward end is already fixed
// (threaded into the forward bulkhead's insert above), so this end only
// needs to LOCATE the rod's free aft tip, giving it a second support
// point so a ~150mm M3 rod, cantilevered off one end with a sled+board
// hanging on it, is not relying on that one fixed end alone against
// handling/vibration. Bored from the aft bulkhead's own e-bay-facing
// (z=0) face, well short of its own T=12mm disc thickness -- the skirt
// beyond z=12 is busy (shear pins at z=20, shaft bore, horn slot, cord
// holes, spring-carrier glue face) and this pocket has no business
// reaching any of it.
R60_Vega_RodPocket_Depth = 8.0;

// Rail length (7th review): the FULL axial reach, both ends together --
// matches the retired design's own "L+2*Foot_L=window, minus 2 clearance
// gaps" shape, just with the two clearances now independently stated
// (Rail_FwdClear at the hard stop, the much larger Rail_AftClear for the
// nut/washer stack) rather than one shared "Foot_Clear". Individual
// fwd/aft reach past the board-carrying plate's own +-L/2 is computed in
// R60_VegaSled() itself (it already knows its own L there).
R60_Vega_Rail_L = R60_Vega_Window_Z1 - R60_Vega_Window_Z0
                  - R60_Vega_Rail_FwdClear - R60_Vega_Rail_AftClear;

// Vega board worst-case radial reach into the e-bay bore, installed (5th
// review, finding 2). NOMINAL closed form of the SAME quantity
// tools/verify_rocket60.py's own CLEAR_EXPECT check measures off the
// rendered mesh (facing_y + the sled/standoff/board stack, then the
// board's own half-width for the corner) -- restated here so
// R60_EBayTube()'s door-boss geometry can be derived against it directly
// (rule 4) instead of reaching into the bore by an amount nobody ever
// checked against the board. That was finding 2's actual bug: the
// boss's inner tip reached r=25 -- inside this corner's own ~25.7mm --
// and the assembly harness's own Pair 3 only ever modelled the sled,
// never the board sitting on top of it, so nothing caught it.
// 7th review: Facing_Y_Nom moved (-17.32 -> ~-16.25, Sled_W grew to fit
// the rail) so the two downstream figures below moved with it -- both
// re-derive automatically, restated here only as fresh comments, not
// second copies anything reads.
R60_Vega_Board_Stack    = R60_Vega_Sled_T + R60_Vega_Standoff_h + R60_Vega_H;   // 29
R60_Vega_Board_Inner_Y  = R60_Vega_Facing_Y_Nom + R60_Vega_Board_Stack;         // ~12.75
R60_Vega_Board_Corner_R = sqrt(pow(R60_Vega_W/2, 2) + pow(R60_Vega_Board_Inner_Y, 2)); // ~20.85

// ============================================
// MOTOR
// ============================================
R60_MMT_ID  = 29.0 + 0.3;   // 29mm motor, slip fit
R60_MMT_OD  = R60_MMT_ID + 3.0;
// R60_FinCan() builds the MMT the fin can's own full length (R60_FinCan_L)
// -- derive this from that SAME constant, not a second, independently
// hardcoded number. It used to be a separately typed 223 (5mm short of
// the fin can's actual 228mm build depth): R60_MotorSpacer() then sized a
// spacer 5mm too short, so a motor+spacer stack never reached the
// retainer lip and the motor could slam 5mm aft on ejection. See task
// report.
R60_MMT_L   = R60_FinCan_L;
R60_Motor_L = [124, 203, 216];  // G80T-14A, H182R-14A, H135W-14A

// Motor-catching lip bore -- shared between R60_MotorRetainer() (aft,
// catches the motor's own aft rim, resisting AFT motion) and
// R60_ThrustRing() (forward, part 14, 3rd review defect 3: catches the
// motor+spacer stack's forward face, resisting FORWARD motion -- nothing
// did before this, so the ~66N forward thrust reaction on a G80T-14A had
// only a 0.3mm slip fit standing between the motor+spacer stack and the
// packed parachute). Same lip width both ends, one derived constant.
R60_Motor_Lip_d = R60_MMT_ID - 2.5;
// R60_ThrustRing()'s own thickness -- shared with R60_MotorSpacer() so
// the spacer's length is derived knowing the ring now occupies the last
// R60_ThrustRing_T of the MMT's own R60_MMT_L, not a second part sized
// as if it had the whole length to itself (which would make the ring
// and the spacer's forward end occupy the same 6mm and collide -- caught
// on the rendered assembly, tools/verify_rocket60_assembly.py pair 10,
// before this was wired through).
R60_ThrustRing_T = 6;

// ============================================
// SPRING SEPARATION JOINT (spec 4.2 -- supersedes the cam-ramped bayonet)
// ============================================
// CS4323 compression spring dimensions, as documented in the repo's
// SpringThingBooster.scad/SpringEndsLib.scad family (ST_DSpring_OD/ID,
// ST_DSpring_CBL/FL) and restated here since Rocket60.scad does not
// `use<>` those files -- see R60_SpringCarrier()'s module comment for why.
R60_Spring_OD  = 44.30;
R60_Spring_ID  = 40.50;
R60_Spring_FL  = 200;    // free length
R60_Spring_CBL = 22;     // coil-bound length

// Shear pins bridge the REAL separable airframe joint -- chute bay tube
// (part 3) into the e-bay aft bulkhead's skirt (part 5) -- not the spring
// carrier. See R60_EBayAftBulkhead()'s module comment for why that
// placement is what keeps the two separation paths independent.
//
// Target: 2x nylon 2-56, ~130N combined shear (spec 4.2). NO spring force
// figure exists anywhere in this repo (grep of all nine spring/release
// files found none) -- this pin size is a stated target, not a verified
// one. The spring must be bench-measured to confirm it beats this load
// before flight (spec A11 -- the largest open risk in the recovery
// system). Do not treat PIN_D as validated by anything in this file.
R60_Pin_d            = 2.2;   // nylon 2-56 clearance
R60_Pin_Skirt_L      = 15;    // e-bay aft bulkhead's aft skirt engagement
R60_Pin_Z_FromJoint  = 8;     // both R60_ChuteTube() and R60_EBayAftBulkhead()
                               // cut their pin hole this far from the joint,
                               // so one physical pin lines up through both

// Tether latch (part 13, Task 8) routing. Shared between R60_ChuteTube()
// (the fixed tie-off at the chute bay's forward rim), R60_EBayAftBulkhead()
// (the latch's own mount, offset under servo 2's horn so it can drive it,
// plus a relief channel through the skirt) and R60_SpringCarrier() (a
// matching notch through its counterbore rim), so the tether's ~50mm cord
// path lines up across all three once assembled -- see each module's
// comment. This is a SEPARATE line from the shock cord (which is
// permanently anchored e-bay aft bulkhead <-> fin can forward centring
// ring, spec 4.1) -- conflating the two leaves the aft section attached
// to nothing after main release.
R60_Tether_Y  = 13.6;   // R60_EBayAftBulkhead()'s own S2_Y now READS this
                          // constant directly (6th review, finding 3.3 --
                          // was a second, independently-typed 13.6 that
                          // this comment asserted equal without enforcing
                          // it), so servo 2's own pocket/horn slot always
                          // stays under wherever this moves to
R60_Tether_Az = 90;     // +Y -- azimuth of the relief channel/tie-off

// Tether tie-off lug (R60_ChuteTube(), part 3) and the relief notch that
// must swallow it through the aft bulkhead skirt (part 5, which the chute
// tube's forward rim slides over). Defined once, here, so the notch is
// always DERIVED from the lug's own footprint plus a stated clearance --
// not a hand-matched dimension that can silently drift out of sync (a
// first draft sized the notch to exactly the lug's own dimensions: zero
// clearance on width and 0.8mm of outright interference on depth. See
// task report).
R60_TetherLug_W  = 8;     // lug width, X
R60_TetherLug_D  = 4;     // lug radial depth, Y -- how far it reaches
                           // inward from the chute tube's own ID
R60_TetherLug_H  = 5;     // lug height, Z
R60_TetherLug_Z  = 4;     // lug Z position (base), in the chute tube's
                           // own frame
R60_Tether_Clear = 0.6;   // stated per-side clearance: the notch is cut
                           // this much deeper (radius) and this much wider
                           // (each side) than the lug's own footprint

// Tether latch (part 13) mounting hole spacing. Servo 2's horn slot
// (R60_Horn_L, R60_EBayAftBulkhead()) is shared here so the latch's own
// mounting holes and the bulkhead's insert holes it screws into are always
// derived from the SAME slot dimension, and so they can never again land
// inside its void -- see task report: the original +-11mm spacing put
// both mounting inserts inside the horn slot (only ~2.5mm^2 of a 12.6mm^2
// bore was solid).
R60_Horn_L            = 24;    // servo 2 horn slot length, X
R60_Horn_W            = 9;     // servo 2 horn slot width, Y -- shared for
                                // the same reason R60_Horn_L is: 4th
                                // review, critical 5, needs it to size the
                                // pass-through R60_TetherLatch() now cuts
                                // through its own base (see that module's
                                // comment) so it never again matches the
                                // bulkhead's own slot width by coincidence
R60_TetherInsert_d    = 4.0;   // ruthex RX-M3x5.7 hole, tether latch mount
R60_Tether_Wall_Min   = 2.0;   // min solid wall around the insert hole,
                                // clear of the horn slot void
R60_TetherLatch_HoleX = R60_Horn_L/2 + R60_TetherInsert_d/2 + R60_Tether_Wall_Min;  // 16

// Spring carrier (part 8) counterbore diameter -- shared with
// R60_TetherLatch() (4th review, critical 2) so the latch can clip its
// own base to a radius that is guaranteed to stay inside it, DERIVED,
// rather than the two silently drifting the way R60_TetherLug_*/
// R60_Tether_Clear were introduced to prevent for the tether notch. Was
// a second, local-only `CB_D=51` inside R60_SpringCarrier() with nothing
// else deriving from it -- fine while the latch was assumed to fit
// inside it whole, which the module comment claimed ("the posts and pin
// recess into that counterbore") but never actually checked for the
// latch's own rectangular BASE, offset R60_Tether_Y off the carrier's
// axis so servo 2 can reach it. A round counterbore centred ON that axis
// can never fully clear an off-axis rectangle no matter how large --
// the base's own far corners (r=28.97mm from the carrier's axis) sit
// PAST the carrier's own OD (28.2mm), so growing CB_D cannot be the fix;
// R60_TetherLatch()'s own module comment explains the clip this drives.
R60_SpringCarrier_CB_D = 51;

// ============================================
// FINS
// ============================================
// Span grown 55 -> 63mm (task report, coordinator decision, group 2
// re-target): the buried root originally reported here was correct as a
// PLANFORM number, but tools/rocket60_model.py's Barrowman analysis had
// been counting all 55mm of it as EXPOSED span -- 14mm of it (D/2 -
// R60_MMT_OD/2) actually sits inside the fin can, under the epoxied
// joint, and contributes zero normal force. Fed the corrected EXPOSED
// geometry, the G80T-14A -- the motor actually owned, the sizing case
// per the coordinator's explicit re-target -- static margin was only
// 1.05 cal at liftoff. Root/tip/sweep/thickness are UNCHANGED: span is
// the most efficient lever per gram (CN scales with (exposed-span/D)^2,
// so growing span buys far more CP shift per gram added than growing
// chord -- see tools/rocket60_model.py's own sweep for the chord-only
// and Ct-trim alternatives that were rejected for costing more mass at
// the same margin). 63mm clears the design's real physical minimum --
// 1.0 cal, standard high-power practice's accepted 1.0-2.0 cal band --
// with genuine room: 1.45 cal at liftoff on the G80T (5th review,
// finding 11: this comment used to cite a 1.5 cal target, since retired
// as never having been a physical requirement, and a 1.61 cal figure,
// itself twice corrected downward by a full station audit -- see spec
// section 6.1 for the ruling and tools/rocket60_model.py's own
// MIN_MARGIN_CAL for the current gate). Flutter velocity -- a function of
// exposed AR, which RISES as span grows (span 55->AR 0.739->Vf 1220 m/s;
// 63->0.869->959; 70->0.982->802 -- growing span 18% raised AR 18% and
// CUT Vf 21%, the opposite of a free lever) -- still stays comfortably
// above 3x the fastest flight speed on any motor at 63mm. This is a real
// cost, not a margin grown for free: do not read this as licence to keep
// growing span for stability headroom without re-checking Vf each time
// (R60_Fin()'s own module comment already says this; restated here so
// this comment does not contradict it) -- see
// tools/verify_rocket60.py's fin-span check (3rd review, should-fix 7)
// and the module comment on R60_Fin() for the current AR/flutter
// figures. Slot geometry in R60_FinCan() needs no
// width change: the slot already cuts clear through to the body OD
// (r=30) regardless of span, so only Slot_L (root chord, unchanged) sets
// its footprint -- span only changes how far the fin's OWN tip reaches
// past the airframe, which the slot cut (through the outer wall only,
// unbounded in the +Y direction of the cube) already accommodates.
R60_Fin_Root  = 90;
R60_Fin_Tip   = 35;
R60_Fin_Span  = 63;
R60_Fin_Sweep = 45;
R60_Fin_T     = 4.0;
R60_nFins     = 3;

// ============================================
// SHARED MODULES
// ============================================

// A plain airframe tube. Length along +Z, base at Z=0.
module R60_Tube(len, od=R60_Body_OD, wall=R60_Wall_T){
    difference(){
        cylinder(d=od, h=len);
        translate([0,0,-Overlap]) cylinder(d=od-2*wall, h=len+Overlap*2);
    }
} // R60_Tube

// Bolt pattern for the camera's three heat-set inserts. Children are
// placed at each hole, on the XY plane, oriented +Z.
module R60_CameraBoltPattern(){
    for (a=R60_Cam_Ang)
        rotate([0,0,a]) translate([R60_Cam_BC_R,0,0]) children();
} // R60_CameraBoltPattern
