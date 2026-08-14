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
R60_Vega_Standoff_h = 4;   // manual recommends spacers under the board
R60_Vega_Sled_W = R60_Vega_W + 11;   // sled plate width (chord), matches
                                       // R60_VegaSled()'s own W
R60_Vega_Sled_T = 4;                  // sled plate thickness

// Sled retention -- REPLACES the rail/zip-tie scheme (6th review, finding
// 1: the THIRD distinct failure of that concept -- round 2 shipped no
// retention at all, round 3's rails blocked the bulkheads, and round 5's
// "fixed" Rail_HalfAng (a*sinH-b*cosH solve for the rails' own facing
// gap) turns out to open the two rails' facing planes AWAY from each
// other with increasing radius rather than toward: transforming a sled
// corner into either rail's own local frame has no solution simultaneously
// satisfying "past the rail's inner face" and "within the rail's own
// width" -- the sled slides past both rails' corners and falls to the
// tube ID, uncaptured, which rail_facing_gap()'s tangential-only sample
// could never see. Abandoning the concept per the review's own verdict:
// the sled now BRIDGES the full axial gap between the aft and forward
// bulkheads' own e-bay-facing faces (R60_Vega_Window_Z0/Z1 below) and
// bolts directly to each, 2x M3 into ruthex RX-M3x5.7 inserts per end (4
// total) -- see R60_VegaSled()/R60_EBayAftBulkhead()/R60_EBayFwdBulkhead()
// in Rocket60.scad. Both the sled's radial position and its clocking
// about the tube axis are now fixed by where those 4 holes/inserts land,
// not by resting against (or being captured by) anything.
//
// Radial position: closed-form, the DEEPEST the plate's own flat back can
// sit while its two long back corners (+-Sled_W/2, Facing_Y) still clear
// the tube ID by a stated print clearance -- i.e. as close to the -Y wall
// (opposite the door/switch, both +Y) as the plate's own width allows,
// same 0.4mm clearance convention as R60_Coupler_OD. Replaces the old
// R60_Vega_Facing_Y_Nom, which had no closed form at all (it fell out of
// the now-deleted Rail_HalfAng solve) and was only ever a restated
// measurement of geometry that turns out not to work.
R60_Vega_Wall_Clear   = 0.4;
R60_Vega_Facing_Y_Nom = -sqrt(pow(R60_Body_ID/2 - R60_Vega_Wall_Clear, 2)
                               - pow(R60_Vega_Sled_W/2, 2));   // ~-17.32

// Mounting feet, both ends -- see R60_VegaSled()'s own module comment for
// the full derivation. Defined BEFORE the axial window below because the
// window's own forward edge has to account for R60_VegaFoot_FwdBossExtra
// (see that constant's own comment) -- OpenSCAD does not forward-
// reference top-level assignments (confirmed empirically), so anything
// the window formula reads must already be defined above it.
R60_Vega_Foot_Clear   = 0.2;    // small assembly gap, each end, between
                                  // the foot's own tip and the bulkhead's
                                  // mounting face -- the screw draws it
                                  // flush, not a print fit relying on
                                  // being dead-on
R60_VegaFoot_HoleX    = 14;      // M3 hole X offset, symmetric -- clear of
                                  // the aft bulkhead's servo-1 pocket (max
                                  // reach x=6.1,y=6.2), horn slot (max
                                  // reach x=12) and both bulkheads' own
                                  // OD/central bore, confirmed on the
                                  // rendered mesh (verify_rocket60.py)
R60_VegaFoot_Hole_d   = 3.4;     // M3 clearance, matching R60_Vega_Holes'
R60_VegaFoot_Insert_d = 4.0;     // ruthex RX-M3x5.7 hole per datasheet --
                                  // same physical part/hole size as
                                  // R60_TetherInsert_d and
                                  // R60_MotorRetainer()'s own Insert_d,
                                  // restated (that constant is defined
                                  // AFTER this point in the file)
R60_VegaFoot_Insert_h = 6.7;     // same ruthex convention (datasheet:
                                  // insert length 5.7 + 1mm), matches
                                  // R60_MotorRetainer()'s Insert_h
R60_VegaFoot_Insert_Backing = 1.0;   // solid material left BEHIND the
                                       // insert's own floor, same
                                       // convention as R60_EBayTube()'s
                                       // door-boss backing
R60_VegaFoot_Boss_d   = 8;       // >= insert hole + 2x1.6mm min wall, same
                                  // convention as every other ruthex boss
                                  // in this file
// R60_EBayFwdBulkhead()'s own disc is only R60_FwdBulk_T=6mm -- shorter
// than the insert's 6.7mm depth -- so that module grows a LOCAL boss
// AFT-ward (into the e-bay, past its own z=0 face) at each insert. That
// boss is real, solid, PRINTED material sitting exactly where the sled's
// forward foot needs to travel to reach the plain disc face -- caught on
// the rendered assembly (tools/verify_rocket60_assembly.py Pair 24:
// 0.0937cm3, first version of this fix, before R60_Vega_Window_Z1 below
// accounted for it) as a real interference, not a hypothetical one: the
// foot's own Foot_Clear was measured against the WRONG surface (the
// plain disc's face, z=R60_Vega_Window_Z1 before this fix) when the
// ACTUAL nearest solid material is the boss's own outer face,
// R60_VegaFoot_FwdBossExtra closer. Shared here (not local to
// R60_EBayFwdBulkhead()) so the window computation below and the boss
// that creates the constraint can never drift out of sync again.
R60_VegaFoot_FwdBossExtra = R60_VegaFoot_Insert_h + R60_VegaFoot_Insert_Backing
                             - R60_FwdBulk_T;   // ~1.7

// Forward bulkhead's own TRUE placement in the tube frame -- its plain
// disc's own z=0 (e-bay-facing) face, UNCHANGED by the foot boss (the
// boss reaches FORWARD of this face, into the e-bay, from local
// z=-R60_VegaFoot_FwdBossExtra to 0 -- see R60_EBayFwdBulkhead()'s own
// module comment). Matches r60_assembly.scad's Pair 1 transform
// (R60_EBay_L-R60_Neck_Skirt_L-R60_FwdBulk_T) -- restated here as a named
// constant, not a second inline expression, specifically so
// R60_Vega_Window_Z1 (below) and the module's own placement can never
// silently diverge on what "the forward bulkhead's face" means (6th
// review, finding 1: a first version of this fix conflated the two --
// TRANSLATING THE WHOLE BULKHEAD MODULE to the boss-tip position instead
// of just deriving the sled's usable window from it -- which physically
// moved the disc itself 1.7mm out of its real assembled position and,
// because the boss is built RELATIVE to that moved disc, left the exact
// same 0.0937cm3 collision the fix was meant to remove, confirmed on the
// rendered assembly, tools/verify_rocket60_assembly.py pair 24, before
// this was corrected).
R60_FwdBulkhead_TubeZ0 = R60_EBay_L - R60_Neck_Skirt_L - R60_FwdBulk_T;

// Axial window the sled now spans, end to end: the aft bulkhead's own
// e-bay-facing face (tube z=R60_AftBulk_T -- R60_EBayAftBulkhead()'s own
// z=0, the "pocket-opening" face, see that module's comment) to the
// forward bulkhead's own foot-BOSS face (R60_FwdBulkhead_TubeZ0 minus
// R60_VegaFoot_FwdBossExtra -- R60_EBayFwdBulkhead()'s own boss tip, the
// NEAREST solid material the sled's forward foot can actually reach, not
// the disc's own plain face behind it). Grows/shrinks automatically with
// R60_EBay_L or either bulkhead's thickness instead of the sled silently
// falling short (or overlapping) the next time either changes.
R60_Vega_Window_Z0 = R60_AftBulk_T;
R60_Vega_Window_Z1 = R60_FwdBulkhead_TubeZ0 - R60_VegaFoot_FwdBossExtra;
// Sled's own axial centre once assembled -- the window's midpoint, NOT
// R60_EBay_L/2 (the window is not centred on the tube: the aft bulkhead
// alone is 12mm, the forward bulkhead + neck skirt together are 25mm).
R60_Vega_AxialCenter = (R60_Vega_Window_Z0 + R60_Vega_Window_Z1) / 2;
// Foot pad's own local depth (Z, =radial once assembled) and width (X)
// around each hole -- derived from a stated minimum wall beyond the
// hole's own edge (R60_Wall_T, matching R60_TetherLatch()'s
// Mount_Wall_Min/R60_SpringCarrier()'s Ball_Wall_Min convention), not a
// hand-picked pad size. The plain plate's own T=4mm alone would leave
// only (4-3.4)/2=0.3mm of wall around a Z-bored M3 hole -- the same
// "boss sized to the OD constraint, never checked against the hole it
// hosts" defect class as finding 3.1's door boss.
R60_VegaFoot_PadZ = R60_VegaFoot_Hole_d + 2*R60_Wall_T;   // 6.6
R60_VegaFoot_PadX = 2*(R60_VegaFoot_HoleX + R60_VegaFoot_Hole_d/2
                        + R60_Wall_T);                     // ~34.6
// Hole's own Y (radial), both local (R60_VegaSled()'s own frame, Z=0 at
// the plate's base) and global (tube frame, once assembled) -- shared so
// R60_EBayAftBulkhead()/R60_EBayFwdBulkhead() drill their insert holes at
// the IDENTICAL position the sled's own holes land at, not a
// independently-typed match.
R60_VegaFoot_HoleZ_Local = R60_VegaFoot_PadZ / 2;
R60_VegaFoot_HoleY = R60_Vega_Facing_Y_Nom + R60_VegaFoot_HoleZ_Local;

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
R60_Vega_Board_Stack    = R60_Vega_Sled_T + R60_Vega_Standoff_h + R60_Vega_H;   // 29
R60_Vega_Board_Inner_Y  = R60_Vega_Facing_Y_Nom + R60_Vega_Board_Stack;         // ~11.68
R60_Vega_Board_Corner_R = sqrt(pow(R60_Vega_W/2, 2) + pow(R60_Vega_Board_Inner_Y, 2)); // ~20.22

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
