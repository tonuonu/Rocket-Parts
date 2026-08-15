# Rocket 60 — 3D Print Settings

**Project:** Rocket 60 camera rocket (60 mm body, CATS Vega single-deploy, petal deployment)
**Author:** Tõnu Samuel
**Date:** 2026-08-13
**Spec:** `docs/superpowers/specs/2026-08-13-rocket60-design.md`
**Parts:** `STL Files/Rocket60/README.md`, generated from `Rocket60.scad`

---

## Status — read this before printing anything

**Petal-deployment transplant.** The spring/ball-lock carrier, tether
latch and shear-pin design this section used to describe is **deleted**
— it never had a working release (its own ball-lock plunger/lock ring
were "deliberately incomplete"), and its pin-load spec was self-
contradictory. Replaced by transplanting a flown design's own libraries
(`Rocket6551.scad`'s petal deployment + `CableReleaseBBMicro.scad`'s
release catch) instead of re-deriving a mechanism from scratch a second
time — see spec §4 and `tasks/lessons.md`. All 27 printable parts (test
ring through the deployment bay tube's own aft piece, part 26) plus the
fixed `NoseCone.stl` exist as meshes and are covered below.

- The separation path (spec §4) is now the **petal cage itself**:
  `08_PetalHub.stl` spigots (glued, not bolted) into the fin can's
  forward opening; `13_Petals.stl` hinges to the hub via 3x `24_
  PetalSpringHolder.stl` (bolted to each petal, axle in the hub's own
  pivot socket, spring-preloaded open) — **not** a bolted joint between
  parts 8 and 13 directly (11th review, correcting that claim: `PD_Petals`
  has no axial holes at all). Closed, the petals' own printed lock nubs
  hold the hinges shut — not a shear-pin joint. Servo 1 (in `15_
  ReleaseActivator.stl`) rotates a lock ring, freeing `23_
  ForwardSpringEnd.stl`, which the CS4323 spring drives into the petals,
  popping the nubs open and driving the hinges. **Fully modelled this
  time**: the rotating lock ring, ball-detent and magnetic over-centre
  catch the deleted design left as an unmodelled "companion piece" are
  `15_ReleaseActivator.stl` through `22_ReleaseLockingPin.stl` — real,
  `use<>`-instantiated parts from a proven library, not a stated future
  task. `24_PetalSpringHolder.stl` (the hinge, print 3x) and `25_
  CenteringRingMount.stl` (seats the CS4323) close the two gaps the
  first transplant attempt left: the hinge subsystem was missing
  entirely, and the spring had nothing to seat on.
- `03_ChuteBayTube.stl` is now two pieces, `03_DeploymentBayTubeFwd.stl`
  + `26_DeploymentBayTubeAft.stl` (grown 180→240→275mm, then split —
  12th review, owner's ruling: the corrected length exceeds the print
  envelope as one piece, see spec §4.1). Neither piece ever separates
  from the other, or from the e-bay section — they are glued together
  (in-wall spigot/socket, `R60_ChuteSplit_Z`=137mm) and stay with the
  e-bay/nosecone section for good; together they house the release
  stack + spring + forward spring end, with an open aft end the petal
  cage telescopes through.
- `05_EBayAftBulkhead.stl` carries one servo mount instead of two servo
  pockets — single deploy has no second (tumble-release) servo. **10th
  review, critical fix:** the mount is 2× #10-24 through-bolts into
  `15_ReleaseActivator.stl`'s own `EBay_TopPlate` ring — NOT the 3× M3
  ruthex-insert circle an earlier draft of this document (and the code)
  described; that circle was the activator's own internal joint to its
  neighbour part, on the wrong face, sized for the wrong screw. The
  bulkhead's own 15mm skirt is also now mostly hollow (a plain tube +
  a 3mm web at the tip, not a solid slug) — see `Rocket60.scad`'s
  `R60_EBayAftBulkhead()` module comment.
- `14_ThrustRing.stl` glues into the MMT's forward opening, flush with
  the fin can's own tip, and reacts the motor's FORWARD thrust reaction,
  which `11_MotorRetainer.stl` alone cannot: that retainer only resists
  motion out the aft end.
- `09_FinCan.stl`, `10_Fin.stl`, `00_TestRing.stl` and `NoseCone.stl` are
  **unchanged by this task** (nine prior review rounds hardened them;
  this transplant does not touch them).

**Resolved (12th review) — both owner rulings applied, all three
verification suites exit 0.** Fixing the hub's orientation (above) also
fixed its own length requirement, exposing that the deployment bay tube
needed to grow to 275mm for a correct spigot engagement (not the 12.2mm
originally measured short at 240mm) — the owner's ruling grew
`R60_Petal_Len` to 140 (real packing margin, not a tangent fit) and
`R60_Chute_L` to 275 (derived from that), then split the tube into two
printed pieces since 275mm exceeds the print envelope as one — see spec
§4.1 for the full record and §9 "Known gaps" for the load the new joint
is sized against. Print `03_DeploymentBayTubeFwd.stl`,
`26_DeploymentBayTubeAft.stl` and the petal cage (parts 8/13/24) as
normal; nothing here is held back any more.

**Motors:** AeroTech G80T-14A (owned, 29 mm) is the sizing motor. The
petal-deployment transplant grew the deployment bay (180→240→275mm,
the last step the 12th review's tube-split/packing-margin ruling) and
moved the fin can (and CP) further aft; re-run, the G80T's static margin
**IMPROVED to 1.69 cal** (was 1.46 cal pre-transplant, 1.53 after the
11th review's hinge-subsystem fix — the 12th review's own R60_Chute_L
275/R60_Petal_Len 140 growth moved the margin again, to 1.69) — CP
moved aft more than CG did, since the added length sits forward of the
fin can. Clears the physical minimum, **1.0 cal** (standard high-power
practice's accepted 1.0–2.0 cal band), with real room. See spec §6/§6.1
for the full reasoning. Airframe is sized for a 29 mm H DMS (H182R-14A
or H135W-14A) so Mach 0.60 is available later with no reprint (spec
§1.1, §5); both clear the same 1.0 cal minimum (§9), H182R at
**1.48 cal**, H135W at **1.49 cal**.
**Envelope:** tallest printed part is the fin can at 228 mm, inside the
Bambu P1S's 256 mm Z with 22 mm to spare (spec §8) — the deployment bay
tube (275mm assembled) is split into two pieces (143/138mm) for the
same reason, each with more spare than the fin can.

---

## 1. Print order — Part 0 is a hard gate

**Print `00_TestRing.stl` first. Print nothing else until it passes.**

It is a single 10 mm part that gauges three fits at once (STL README):

1. The flange sits flush against the nosecone base annulus, no step, in
   either rotation.
2. The three Ø3.4 mm clearance holes line up with the camera's heat-set
   inserts on the **Ø37.96 mm bolt circle**, at **52.2° / −52.2° / 180°** —
   the asymmetry is deliberate and keys which way the camera faces (spec
   §2.1).
3. The coupler spigot slip-fits inside a printed Ø56.4 mm body tube.

**Gate: do not print `01_Neck.stl` or anything downstream of it until the
test ring bolts to the physical camera assembly and sits flush on the
nosecone base.** If the bolt circle or the clocking is wrong, every part
after it is wasted filament — this is the whole reason the test ring
exists as its own print (spec §11 item 1).

After the test ring passes, there is no further ordering constraint from
the geometry — print `01`–`12` in any order convenient for your queue.
Final *assembly* order is constrained; see §5.

---

## 2. Scale calibration — verify before printing anything else

You have been gauging real fits with printed stepped gauges
(`FitGauge.scad`). Those work because **printed-to-printed** fits survive
shrinkage: both halves shrink together, so a fit that was correct in CAD is
still correct after printing, just slightly smaller overall.

**This does not hold here.** The test ring's Ø37.96 mm bolt circle has to
line up with heat-set inserts in the camera's PCB — a **printed-to-bought**
fit against a part that does not shrink at all. A **printed-to-CAD** fit
(the flange against the nosecone base, which is fixed geometry from
`Nose Cone.STEP`) has the same problem.

Do the arithmetic before you trust a print:

| | Value |
|---|---|
| Nominal bolt circle | Ø37.96 mm |
| At 1.5% shrinkage error | Ø37.4 mm |
| Radial error | **≈0.28 mm** |
| M3 clearance hole slop (Ø3.4 mm hole, M3×3.0 mm screw) | **≈0.2 mm radial** |

A 1.5% scale error — well within what a mis-set flow rate or an
uncalibrated printer can produce — puts the bolt circle further out of
tolerance (0.28 mm) than the M3 clearance hole has slop to absorb (0.2 mm).
**It will not assemble.** Measure the test ring's actual bolt-circle
diameter and flange OD with calipers against the Ø37.96 mm and Ø59.98/60.0 mm
nominals before printing `01_Neck.stl` or anything else. If it's off,
correct your slicer's horizontal scale factor (not the model) and reprint
the test ring — do not proceed on a part you haven't measured.

---

## 3. Material split

| Zone | Material | Why |
|---|---|---|
| Nosecone → neck → e-bay → chute bay | **PETG** | Airframe and e-bay; per spec §8, "no carbon-filled filament anywhere from the neck to the chute bay" |
| Fin can, its integrated centering rings, motor retainer, motor spacer, forward thrust ring | **PC** (polycarbonate) | These sit against or next to the motor |
| Fins ×3 | **PETG** | See note below — deliberately *not* moved to PC |

**No carbon-filled filament anywhere from the neck to the chute bay.** The
CATS manual (§4.3.3) is explicit that a carbon-fibre section blocks all RF,
and both the 2.4 GHz telemetry and the GNSS patch antenna live inside that
same volume (spec §7.1, §8). This rules out CF-PETG or CF-nylon for the
neck, e-bay tube, both bulkheads, the Vega sled, the access door, and the
chute bay tube — full stop, regardless of any strength argument for using
it.

**Why PC, not PETG, for the fin can/retainer/spacer.** These parts sit
against or right next to the motor casing. `MotorAdapter29.scad`'s own
print-settings comment for this repo's other 29 mm motor hardware says it
directly: *"PLA: NOT recommended — softens at motor casing temperature"*
and recommends PC for repeated use (Tg ≈150°C) over PETG, which it
describes as only "OK for single use" and prone to sag near the nozzle on
higher-thrust motors. The G80T is the mildest of the three motors this
airframe is designed for; the H182R and H135W run hotter and longer.

*Note on sourcing:* the design spec's §8 materials section still reads
"PETG throughout," but `STL Files/Rocket60/README.md` (generated after §8
was written) and this task's own brief both specify the PC split above.
The README is the newer, more specific source and matches the
`MotorAdapter29` precedent, so this document follows it. See the Report at
the end of the originating task for this flagged explicitly.

**Centering rings are not a separate print.** `R60_FinCan()` in
`Rocket60.scad` builds the three centering rings and the MMT into the same
monolithic piece as `09_FinCan.stl` — there is no separate ring STL to
hunt for. Printing the fin can in PC satisfies "PC for the centering
rings" automatically.

**Fins stay PETG.** Spec §6 computes the fin flutter margin explicitly
from "G ≈ 0.5 GPa for printed PETG" → Vf ≈ 589 m/s (63mm-span fin, exposed
geometry, root-chord t/c — see §9's fin-sizing note for the 955→589 m/s
correction; this paragraph used to cite the SUPERSEDED 955 m/s figure
here, two sections before its own correction, a live instance of the
exact "restated literal drifts from the source" defect §9's own note
warns about), gated per-motor at a stated 1.5× floor, not a single "3×
the fastest motor" check — 3.0× against the H182R's own ~196 m/s Vmax
(§9's fin-sizing note has the full per-motor table). Moving the fins to
PC would change that shear modulus and orphan the documented margin
without a recompute, and neither
the STL README's materials note nor this task's brief lists fins among the
PC parts (both say "fin can, centering rings, retainer and spacers" —
never "fins"). The
fin can they mount into is PC; the fins themselves are PETG.

*Mass note:* PC (~1.20 g/cm³) is slightly lighter than the PETG
(1.27 g/cm³) the §5.1 mass budget assumed for these parts. Since the
fin can, retainer, and spacer are all aft of the CG, the swap moves total
mass and CG very slightly forward — both stability margin and rail-exit
speed move in the favorable direction relative to the spec's numbers, not
the unfavorable one. The budget's structure (which parts, what stations)
is unaffected.

---

## 4. Per-part print settings

Layer-height/wall/nozzle figures for the PETG airframe zone (test ring
through chute bay tube, plus door and sled) are §8's literal numbers:
**0.4 mm nozzle, 1.6 mm wall = 4 perimeters, 0.2 mm layers.** Fin infill
(62%) is also literal, from §8. Where the spec gives no number for a cell
(infill % on a thick, non-tube cross-section; any PC-part setting), that
cell is marked **[practice default]** — a normal FDM setting chosen by
this document, not a design-spec number — and the reasoning is given.

| # | Part | Material | Wall loops | Infill | Layer height | Orientation | Brim |
|---|---|---|---|---|---|---|---|
| — | `NoseCone.stl` | PETG (assumed) | — | — | — | as supplied | — |
| 0 | Test ring | PETG | 4 (§8) | 25–30% gyroid **[practice default]** — 16 mm radial cross-section needs real infill, not just walls | 0.2 mm (§8) | Flange down (bed), spigot up — matches modeled Z, puts the mating face against the bed for best flatness | Optional — small footprint, PETG bed adhesion is normally adequate; add if the first layer lifts |
| 1 | Neck | PETG | 4 (§8) | 25–30% gyroid on the 5 mm flange disc **[practice default]**; skirt is a 1.6 mm tube, solid from walls alone | 0.2 mm (§8) | Flange down (bed) — this is the face that bolts to the camera and bears on the nosecone base; skirt points up | Optional, same reasoning as test ring |
| 2 | E-bay tube | PETG | 4 (§8) | N/A — 1.6 mm tube wall, solid from perimeters | 0.2 mm (§8) | Vertical, as modeled (§8: "all tubes print vertically") | No |
| 3 | Deployment bay tube, fwd (12th review, the tube split) | PETG | 4 (§8) | N/A — same as e-bay tube | 0.2 mm (§8) | Vertical, as modeled, spigot end up | No |
| 4 | E-bay fwd bulkhead | PETG | 4 (§8) | 25–30% gyroid **[practice default]** — 17 mm radial disc, not flight-critical (harness pass-through only) | 0.2 mm (§8) | Flat, either face down | No |
| 5 | E-bay aft bulkhead | PETG | 4 (§8) | **≥50% gyroid, or solid, near the 2 activator-mount screw bosses and cord-anchor region [practice default, deliberately conservative]** | 0.2 mm (§8) | Flat, aft (skirt) face **up** — this face carries the 2 activator mounting holes and the now-mostly-hollow skirt's own internal ceiling (its 3mm aft web); printing it up gives the slicer a bridge/support target instead of an unsupported overhang on the down face | **Yes — supports required under the skirt's internal ceiling** (10th review: the skirt is now a hollow tube + a 3mm web at the tip, not a solid slug — R60_EBayAftBulkhead()'s own module comment). Tree/normal supports touching build plate only, so they don't fuse into the skirt's own hollow interior |
| 6 | Vega sled | PETG | 4 (§8) | 25–30% gyroid **[practice default]** | 0.2 mm (§8) | Flat, standoffs up | No |
| 7 | Access door | PETG | 4 (§8) | N/A — 1.6 mm wall, matches tube wall | 0.2 mm (§8) | Vertical, curved face as modeled | No |
| 8 | Petal hub | PETG | 4 (§8) | 25–30% gyroid **[practice default]** | 0.2 mm (§8) | Vertical, as a tube, aft spigot down (the face that slides into `09_FinCan.stl`'s forward opening) — matches modeled Z | No |
| 9 | Fin can (incl. 3 integrated centering rings + MMT) | **PC** | 4 (outer 1.6 mm wall and 1.5 mm MMT wall both print fully solid at 4 loops of a 0.4 mm nozzle — see note) | 70% gyroid **[from `L2-PrintSettings.md` PC fin-can precedent]** — governs only the three ~12 mm-wide integrated ring bands, not the thin tube/MMT walls | 0.12 mm **[from L2 precedent]** | Vertical, aft (retainer) end down | **Yes, 5 mm** — PC warps; large footprint helps (per `L2-PrintSettings.md`) |
| 10 | Fin (×3) | PETG | — (solid from flat print, no wall-loop concept) | **62% (§8, literal)** — pattern not specified by spec; gyroid assumed **[practice default: pattern only]** | 0.2 mm (§8) | Flat, oriented so layer lines run spanwise (§8, literal) | No |
| 11 | Motor retainer | **PC** | 4+ **[from `MotorAdapter29.scad` PC print-settings precedent]** | 40–60% **[same precedent]** | 0.2 mm **[same precedent]** | Flat, 6 mm disc — print flat, either face down (unlike the adapter's own tall geometry, this part has no long axis to stand on) | Recommended (same precedent) |
| 12 | Motor spacer | **PC** | 4+ **[same `MotorAdapter29` precedent]** | 40–60% **[same precedent]** | 0.2 mm **[same precedent]** | Vertical, as a tube (98 mm for the G80T; re-export for `Motor_Class=1`/`2` for the H182R/H135W — 19/6 mm; stops short of part 14, not the full MMT) | Recommended (same precedent) |
| 13 | Petals | PETG | 4 (§8) | 25–30% gyroid **[practice default]**; the printed lock nubs print fully solid from walls regardless | 0.2 mm (§8) | Vertical, as a tube, base (hub-facing) end down | No |
| 14 | Forward thrust ring | **PC** | 4+ **[same `MotorAdapter29` precedent]** | Solid — 6 mm thick, 1.05 mm lip, no interior to fill | 0.2 mm **[same precedent]** | Flat, either face down — a 6 mm annulus, no long axis | Recommended (same precedent) |
| 15 | Release activator | PETG | 4 (§8) | 25–30% gyroid **[practice default]** | 0.2 mm (§8) | Flat, `EBay_TopPlate` ring face down (the face that bolts to `05_EBayAftBulkhead.stl`'s aft face) — best flatness on the mating face | Yes, under the servo pocket/magnet-post overhangs |
| 16 | Release top retainer | PETG | 4 (§8) | 25–30% gyroid **[practice default]** | 0.2 mm (§8) | Vertical, bearing-bore axis up | Yes, under the ball-pocket/rotation-limit-slot overhangs |
| 17 | Release lock ring | PETG | 4 (§8) | 25–30% gyroid **[practice default]** | 0.2 mm (§8) | Vertical, bore axis up | Yes, under the ball-groove overhangs |
| 18 | Release outer bearing retainer | PETG | 4 (§8) | 25–30% gyroid **[practice default]** | 0.2 mm (§8) | Flat, either face down | No |
| 19 | Release trigger post | PETG | 4 (§8) | Solid — small part | 0.2 mm (§8) | Flat, base down | No |
| 20 | Release magnet bracket | PETG | 4 (§8) | Solid — small part | 0.2 mm (§8) | Flat, base down | No |
| 21 | Release extension rod | PETG | 4 (§8) | Solid — small part | 0.2 mm (§8) | Vertical, as a rod | No |
| 22 | Release locking pin | PETG | 4 (§8) | Solid — small part | 0.2 mm (§8) | Vertical, as a rod | No |
| 23 | Forward spring end | PETG | 4 (§8) | 25–30% gyroid **[practice default]** | 0.2 mm (§8) | Flat, skirt face down | No |
| 24 | Petal spring holder (×3, one per petal — 11th review, fix 2, the missing hinge) | PETG | 4 (§8) | 25–30% gyroid **[practice default]** — small part, mostly walls | 0.2 mm (§8) | Flat, bolt-hole face down (best flatness on the face that bears against the petal wall) | Yes, under the hinge boss overhang |
| 25 | Spring centering ring mount (11th review, fix 4 — seats the CS4323) | PETG | 4 (§8) | 25–30% gyroid **[practice default]** | 0.2 mm (§8) | Flat, spring-seat face down | Yes, under the spoke/rope-boss overhangs |
| 26 | Deployment bay tube, aft (12th review, the tube split) | PETG | 4 (§8) | N/A — same as e-bay tube | 0.2 mm (§8) | Vertical, as modeled, socket end down | No |

**Parts 15–23 (10th review):** these 9 release-hardware prints were
already exported and listed in `STL Files/Rocket60/README.md` but were
missing from this table entirely, meaning they printed at whatever a
slicer's own defaults happened to be — added above at this document's
own **[practice default]** convention (25–30% gyroid for the larger
housings, solid for the small pins/posts/rods, matching the equivalent
existing rows 6/1 in this table), not a Rocket 60-specific spec figure
(none exists for this donor-library hardware). Orientation follows each
part's own largest flat mating/bearing face, same reasoning as every
other row.

**Why the fin can gets 4 wall loops, not L2's 6.** `L2-PrintSettings.md`'s
PC fin can used 6 loops because its design wall is 2.4 mm. Rocket 60's
walls are thinner by design: `R60_Wall_T = 1.6 mm` for the outer tube and
1.5 mm for the MMT (Ø32.3/Ø29.3 in `R60Lib.scad`). Both are already fully
solid at 4 loops of a 0.4 mm nozzle (4 × 0.4 = 1.6 mm) — a sixth loop
would have no wall left to occupy. Everything else about the L2 fin-can
block (0.12 mm layers, 70% gyroid, 5 mm brim, enclosed heated chamber,
aft-end-down) is adopted directly because the two parts are otherwise
analogous: PC, printed in one piece, no composite overwrap, motor-adjacent.

**Why the aft bulkhead gets deliberately conservative infill.** Spec §3.1
makes this the sole shock-cord anchor: deployment snatch, "easily >100 N,"
is reacted here and *only* here — never by the neck's three M3 screws.
Spec §10 item A8 additionally flags that the 3 mm floor under each servo
pocket was sized against steady servo torque, not against the impulsive
load if the (currently unbuilt) ejection-charge backup ever fires through
it, and marks that case "not yet evaluated." Given both an always-on
static load and an unevaluated impulsive one land on this one disc, err
high on infill here rather than using the same 25–30% default as the
non-critical bulkhead and sled.

**Chamber:** PC parts (fin can, retainer, spacer) need an enclosed, heated
chamber, per `L2-PrintSettings.md` and `MotorAdapter29.scad`. PETG parts
do not.

---

## 5. Rail buttons and launch

Two rail buttons via `RailButton(OD=11, Flange_h=2, Slot_w=2.8)` from
`RailGuide.scad`, whose verified 8020-1010 profile matches the user's
6.2 mm slot and their actual Estes Pro Series II rail (1.83 m). **1010
rail only — the 3 mm launch rod is not usable at this mass**; at this
length a 3 mm rod would whip badly and rail exit would be unstable
(spec §9).

At the as-built liftoff mass (941 g on the G80T, from
`tools/rocket60_model.py`'s measured-mesh masses — see §9's fin-sizing
note) the rocket leaves the owner's 1.83 m rail at **20.0 m/s**, comfortably
clear of the ~15 m/s minimum needed for the fins to stabilize the vehicle
(spec §5, §6). The H182R is unaffected (29.8 m/s). Confirm actual rail
exit before flying (spec §11 item 6).

**Axial station (task 7, previously unspecified; 10th review: forward
button station corrected — it used to be measured against the wrong Z
frame, see `R60Lib.scad`'s own `R60_RailButton_Fwd_Z` comment):**
azimuth 180°, aft button at Z=630mm (fin can, forward of the fins, at
the mid centring ring), forward button at Z=242mm (e-bay tube, clear of
the door cover's own aft edge with a stated margin) —
R60Lib.scad's `R60_RailButton_Aft_Z`/`R60_RailButton_Fwd_Z`/
`R60_RailButton_Az`. Keeps the G80T's own liftoff CG (401.8mm) between
the two buttons.

Print settings for the rail buttons themselves are not covered by the
Rocket 60 sources (`RailGuide.scad` is a shared, pre-existing library, not
a Rocket 60-specific part) — use your established settings for that file
if you have them from other rockets; none are asserted here.

---

## 6. Assembly order and the load-path rule

**The load-path rule, stated once, explicitly: the shock cord anchors on
the e-bay aft bulkhead and never forward of it.** Deployment snatch —
easily over 100 N — is reacted entirely by that bulkhead's two Ø5 mm
cord-anchor holes. It never passes through the three M3 screws that hold
the neck onto the camera assembly. Those three screws only ever carry the
nose section's own inertia — do not route recovery loads through them,
now or in any future revision.

Build order for what exists today:

1. **Gate:** trial-fit the test ring to the camera and nosecone (§1/§2
   above) before anything else.
2. Mount the CATS Vega on `06_VegaSled.stl` on M3 standoffs — antenna side
   faces **radially outward**, nothing between it and the airframe wall
   (spec §7.1).
3. Build the forward e-bay cartridge on the BENCH, not inside the tube
   (7th review, finding 1/2 — retired the 6th review's bolted feet, which
   could not physically be inserted once seated in the tube; see spec
   §7.2). Thread two M3 rods, **cut to 150–152 mm** (`R60Lib.scad`'s
   derived `R60_Vega_RodLength`, ≈152.8 mm — see that constant's own
   comment for the 4 terms it sums: fwd insert engagement + full rail
   length + aft clearance gap + aft pocket depth), into
   `04_EBayFwdBulkhead.stl`'s own inserts (fixed, permanent). **Do not
   cut long**: at 152.8 mm the rod's free tip exactly reaches the aft
   pocket's own floor (step 6 below) — any longer and the rod bottoms
   out in the pocket before the aft bulkhead can seat flush against the
   sled's rail. Cutting a little short costs some of that pocket's
   side-load support but is not otherwise unsafe; a rod cut to the old,
   undocumented assumption of the rail's own length alone (133.1 mm)
   is 20 mm short and never reaches the pocket at all — 9th review,
   finding 3, closes exactly this gap (no length was stated anywhere
   before this). Slide `06_VegaSled.stl` onto the two rods —
   antenna side still radially outward — until it hard-stops against the
   forward bulkhead's own boss face. Thread a nut+washer onto each rod's
   free end, against the sled's own rail face, drawing the sled snug
   against the forward bulkhead. Check the antenna orientation now — it
   cannot be corrected once the aft bulkhead closes the assembly in step
   6. Every fastener here is turned in open bench air; none is reached
   down a blind tube.
4. **Build the release stack (petal-deployment transplant; 10th review
   updated the mount, below):** assemble `15_ReleaseActivator.stl`
   through `20_ReleaseMagnetBracket.stl` per
   `CableReleaseBBMicro.scad`'s own hardware stack (the servo lives
   inside part 15 now, not in the bulkhead — one MG90S, not two; single
   deploy has no second, tumble-release phase). Bolt part 15 to
   `05_EBayAftBulkhead.stl`'s aft face with 2× #10-24 screws (~1-3/8in),
   through the bulkhead from its open forward face, into part 15's own
   `EBay_TopPlate` ring bosses — **not** the M3-ruthex-insert instruction
   an earlier draft of this document gave; that circle was never the
   right mounting feature (`Rocket60.scad`'s `R60_EBayAftBulkhead()`
   module comment has the full defect writeup).
5. Anchor the shock cord to the aft bulkhead. Do this before closing the
   e-bay — it is not accessible afterward.
6. Assemble the e-bay inside `02_EBayTube.stl`: insert the forward
   cartridge (step 3) forward-bulkhead-first and glue that bulkhead at
   its station; route the camera harness down through the neck's open
   centre into the e-bay (spec §3.1 invariant 2: no wire crosses the
   separation joint) before it is buried. Seat `05_EBayAftBulkhead.stl`
   last, at the aft opening, its own two rod holes threading over the
   cartridge's free rod ends as it seats — a blind guide pocket in this
   bulkhead's own face receives each rod's tip; no fastener is needed
   there, it only locates the rod against side-load. Both the sled's
   radial position and its clocking (antenna outward) were already fixed
   in step 3, by the two rods, not by anything in this step.
7. Bolt `01_Neck.stl` to the camera assembly with 3× M3×10 SHCS into the
   heat-set inserts (5.0 mm grip, 5.0 mm thread engagement — does not
   bottom out, spec §2.1), then to the nosecone base and e-bay tube.
8. Fit `07_AccessDoor.stl` with the external arming switch — reachable
   with the rocket vertical on the rail (spec §7.1). The door is a cover
   that overlaps the tube's opening on every side; 4× M2.5 into the
   tube's own bosses, not a flush plug.
9. **Glue `03_DeploymentBayTubeFwd.stl`'s aft spigot into
   `26_DeploymentBayTubeAft.stl`'s forward socket** (12th review, the
   tube split — spec §4.1): a snug, located joint (0.4mm clearance,
   this design's own standard spigot convention), NOT a bare butt bond
   — 6mm of real engagement, sized against the ejection charge's own
   pressure pulse (spec §4.1 has the load and glue-area numbers). Then
   **bond the assembled tube's own forward rim (part 3's own forward
   end) to `05_EBayAftBulkhead.stl`'s aft skirt** (same OD, flush
   joint) — PERMANENTLY: this is no longer a separable, serviceable
   joint (the spring-carrier/shear-pin design this step used to
   describe is deleted — see Status). The release stack (step 4) now
   sits inside this tube. Bolt `25_CenteringRingMount.stl` to `16_
   ReleaseTopRetainer.stl` (11th review, fix 4 — same
   `CRBBm_MountingBoltPattern` hardware class as the release stack's
   other internal joints), THEN thread the locking pin + extension rod
   (parts 21/22) through the lock ring, load the CS4323 spring over
   them (seated on part 25, not floating), and cap the free end with
   `23_ForwardSpringEnd.stl`, captive on the pin until the servo
   releases it. The pin→rod→piston tension member is a **#10-24
   all-thread rod, cut to ~58mm** (13th review — `R60Lib.scad`'s own
   `R60_ReleaseRodLen` echo has the derivation; bench-adjustable over
   the extension rod's own ~26mm span, so cut a little long and trim)
   — see spec §4.2 for the full mechanism.
10. Epoxy the 3 fins into `09_FinCan.stl`'s slots; screw
   `11_MotorRetainer.stl` to the fin can aft end (3× M3 into ruthex
   inserts). Glue `14_ThrustRing.stl` into the MMT's forward opening,
   flush with the fin can's own forward tip — do this before the next
   step, it is not reachable once the chute bay tube is bonded on.
   Nothing else reacts the motor's forward thrust: the aft retainer
   only resists motion out the back. Install `12_MotorSpacer.stl` for
   the G80T (re-export for `Motor_Class=1`/`2` for the H182R/H135W).
11. **Build the petal cage, THE separable joint** (petal-deployment
    transplant — this is no longer a shear-pin/tether design; see
    Status): glue `08_PetalHub.stl` to the fin can's forward end (its
    own aft spigot inserts into the fin can's forward opening — a
    located, concentric joint, not a bare butt bond — NOT bolted, this
    is a glued spigot like every other internal airframe joint in this
    design). **Not bolted to the hub either** — `13_Petals.stl` hinges
    to `08_PetalHub.stl` via 3× `24_PetalSpringHolder.stl` (11th
    review, fix 2, the hinge subsystem missing from the first
    transplant attempt): bolt each spring holder to a petal with 2×
    #4-40×1/2in through the petal's own only holes, drop a 5/16in OD
    coil spring into the holder's own receiver, then seat the holder's
    printed axle into the hub's own pivot socket (preloaded open by
    that spring) — 3× holders, 3× springs, 6× #4-40 total. Bolt
    `23_ForwardSpringEnd.stl` (already captive on the release stack's
    pin, step 9) so it seats against the petals directly (it "locks
    onto the bottom of the petals" — `R65_FwdSpringEnd()`'s own module
    comment — not onto the hub). Bonding the deployment bay tube to the
    fin can is NOT a step here any more: the two halves simply
    telescope together — `26_DeploymentBayTubeAft.stl`'s own open aft
    end slides over the petal cage as a plain sliding fit (its natural
    bore already gives the same clearance every other internal joint in
    this design uses), with no bond and no pins. Nothing in the
    airframe shears; the petals themselves hold the two halves together
    until the servo releases them (spec §4.2).
12. Route the permanent shock cord: tie off at `05_
    EBayAftBulkhead.stl`, through `23_ForwardSpringEnd.stl`'s own rope
    holes, through `08_PetalHub.stl`'s own Ø5 centre hole, tie off on
    `09_FinCan.stl`'s forward centring ring (its own 2× Ø5 axial
    holes). **Sleeve the cord and fit a Nomex chute protector between
    the packed main and the motor** — the G80T's ejection charge cannot
    be disabled and fires **~5.0s after apogee, undrilled** (13th
    review, correcting a "1-3s" figure that only matches a DRILLED
    delay — burnout 1.7s + the stock 14s delay grain = 15.7s from
    liftoff, vs 10.7s to apogee; drilling to ~11s (spec §9 item A5)
    gives the shorter ~2-3s the old figure actually described), venting
    straight up the open fin can/deployment bay toward the just-
    deployed main (spec §4.3).

---

## 6.1 Servicing the Vega board after final assembly

Stated explicitly (7th review) rather than left implicit: once the neck
is glued on (step 7) and the e-bay is closed, the ONLY opening into the
e-bay is the access door aperture (85 mm tall × 36 mm wide, tube
z=46–131). The Vega board itself is 100 mm long — it does not fit
through that aperture as a rigid rectangle, and neither the forward
bulkhead's own 22 mm centre bore nor the aft bulkhead's own small
functional holes are anywhere near large enough for it either, so full
board extraction genuinely has no route that does not also break the
glued neck joint. That is a real, stated limitation, not a solved one.

What IS serviceable without breaking anything: the board's own 3× M3
mounting screws (into `06_VegaSled.stl`'s standoffs) land at tube
z≈46.2 and z≈106.2 — the first is right at the door aperture's own lower
edge, reachable but tight; the second is well inside it. Reach a
screwdriver through the door, back both screws out, and the board comes
free of the sled (the sled itself stays on its rods — it is not part of
this step). A 100 mm board will not pull straight out through an 85 mm
opening, but a thin PCB can be walked out diagonally, tilted along its
own length, using the open e-bay bore behind the door for clearance —
standard practice for a long board through a short door. The sled itself
(and, with it, full removal of the rod/nut hardware) is not designed to
be extracted after the neck is glued — treat a sled failure as requiring
that joint to be broken, not as a routine service case.

---

## 7. CATS Vega configuration

Copied verbatim from spec §7.3.

| Setting | Value | Why |
|---|---|---|
| `main_altitude` | **150** | m AGL, main release. Firmware range 10–65535, default 200 |
| `liftoff_acc_threshold` | **40** | m/s². Manual wants ~20 below expected max; the G80T gives ~124 m/s² peak, the H182R ~207 |
| `servo1_init_pos` / `servo2_init_pos` | set on the bench | 0–1000; the locked positions |
| `enable_telemetry` | **true** | ⚠️ firmware default is `false`. Recovery depends on GNSS downlink — if this is left at default there is no tracking |
| `tele_link_phrase` | matched on the ground station | manual §4.3.5 step 17 |
| `enable_testing_mode` | **false** | manual §4.3.5 step 7 |
| `battery_type` | `LI_ION` or LiPo to match the pack | affects voltage warnings |

**11th review, corrected — this section described the deleted two-servo/
tether design.** Single deploy, one event, one servo (spec §4/§7.2):
`EV_APOGEE` drives servo 1, which rotates the release catch's lock ring,
freeing the spring into the petals. There is no servo 2, no
`EV_MAIN_DEPLOYMENT`, and no separate tether release at 150m — that
hardware does not exist in this design. Set the actual 0–1000
unlock position for servo 1 on the bench once the release hardware
exists (spec §7.2).

**Timers — the second TRIGGER, not a second path** (spec §7.4,
retracted from "third independent path" this session): barometric
detection and the timer both drive the SAME servo 1 → lock ring →
spring release — the timer backs up a missed/late barometric reading
only, not the servo, its wiring, the Vega servo rail, or the lock ring
themselves. The G80T's own ejection charge is **not** a third path
either (spec §4.3, retracted in full: the petal lock nubs are a
positive 2.25mm-engagement lock the petals' own 0.2mm of radial flare
cannot open under gas pressure) — **no mechanical backup exists** for
this release. Values for the G80T:

| Trigger | Apogee separation (single event) |
|---|---|
| 1. Barometric | `EV_APOGEE` → servo 1 |
| 2. Timer (backs up a missed barometric read only) | Timer 1: liftoff → **12.5 s** (apogee 10.7 s + margin) |

**This timer value is for the G80T only. Recompute before flying an H**
— apogee is 12.5 s for the H182R, 13.2 s for the H135W (spec §7.4, §9
item A5).

---

## 8. Pre-flight checks

Copied from spec §11, with one adaptation flagged below.

1. Trial-fit the neck to the physical camera carrier and to the nosecone —
   **before** printing anything downstream. (This is the same gate as §1
   above, restated for the neck specifically.)
2. **Bench-test the release mechanism (spec §4, A11/A12).** With the petal
   cage assembled and locked, measure the CS4323 spring's own compressed
   force and confirm it reliably pops the petals' printed lock nubs open.
   Separately, ground-test the G80T's ejection charge with the
   deployment bay/petal cage in the loop — it is an **unsealed** volume
   (spec §4.3, not the sealed pressure vessel a shear-pin design would
   assume) — and confirm it too pops the nubs within the motor's own
   delay window.
3. Cycle the release catch (servo 1 → lock ring → locking pin release)
   20 times on the bench: confirm it neither jams nor creeps open under
   the spring's own standing load between cycles. **This cycle test is
   the gate for a real substitution, not a formality** (13th review):
   the petal/hinge/spring/piston geometry (parts 8/13/23/24) IS the
   donor's own flown mechanism, but the ball-lock stack itself
   (parts 15-22) is not — Rocket6551 flies `CableReleaseBBMini`
   (LockPin_d=16, LockPin_Len=23), this design uses `CableReleaseBBMicro`
   (LockPin_d=12, LockPin_Len=18) instead, forced by mesh evidence, not
   chosen freely: BBMini's own Activator measures r=31.8mm and cannot
   enter this design's Ø56.8mm bore at all, where BBMicro's own
   Activator lands exactly on the coupler OD's own 0.4mm-clearance
   convention (spec §4.2 has the full measurement). A smaller, less-
   flown ball-lock family (BBMicro's own first print 2025-10-16 vs
   BBMini's 2025-09-21) is what this cycle test is actually there to
   de-risk before flight, not the donor-proven petal mechanism it sits
   next to.
4. Bench-test the full Vega sequence on the ground: arm → apogee servo.
5. Swing test or measured CG/CP check with the real, loaded rocket.
6. **Weigh the fully assembled rocket and compare against
   `tools/rocket60_model.py`'s own liftoff-mass figure (941 g, G80T
   config, 12th review) before flying.** Rail exit is what mass actually
   threatens on this rocket (20.0 m/s off the owner's 1.83 m rail
   against a ~15 m/s minimum, spec §6.1) — NOT stability, which clears
   its own 1.0 cal minimum with real room (spec §6.1, 1.69 cal). Roughly
   a quarter of the modelled 941 g is flat-gram hardware ESTIMATES, not
   measured mesh volumes, so the real liftoff mass could differ
   meaningfully:
   - camera assembly (60 g), 1× MG90S servo + small release hardware
     (~15 g, datasheet/estimate — one servo now, not two),
     parachute+cord+hardware (70 g), battery+wiring (45 g), CATS Vega
     board (25 g — its sled IS a measured mesh volume, the board itself
     is not), CS4323 spring (25 g, already flagged unverified — spec
     A11), switch hardware (8 g), rail buttons (4 g), neck bolts (3 g).
   - Every PRINTED part's own mass IS a measured mesh volume (STL_VOL in
     `tools/rocket60_model.py`) — but scaled by a single blended
     infill/print-density figure (`INFILL_EFF=0.78`) that is itself a
     stated, unverified assumption applied across every PETG part alike,
     not per-part infill actually measured off a scale (§3's own
     infill % differs 25–62% per part).
   - If the weighed rocket comes in meaningfully over 941 g, re-check
     rail exit against the ~15 m/s minimum before flying — a shorter or
     lower-thrust rail exit is the actual failure mode a heavier-than-
     modelled rocket produces, not a stability problem.
7. Confirm rail exit on the actual 1.83 m rail (20.4 m/s predicted).
8. **Confirm the arming switch can actually be reached and thrown with the
   rocket vertical on the rail.** The Vega calibrates once, automatically,
   as soon as it detects no motion after boot — it must not be powered up
   before the rocket is vertical on the rail, and disarming afterward is
   only possible by powering off (spec §7.1, §11 item 7).
9. Confirm `enable_telemetry` is `true` and the ground station shows a
   GNSS fix **before** the rocket leaves your hands. The firmware default
   is `false`.
10. First flight on the G80T-14A, single objective: recover the airframe
    and read the Vega log. Compare logged apogee to the 603 m prediction
    and correct Cd₀ before flying the H.

---

## 9. Known gaps — do not treat this as a finished rocket

- **Ball-lock plunger and rotating lock ring** — the invented spring/
  ball-lock carrier design's own fixed housing existed, but the two
  moving companion parts that actually catch and release the spring did
  not, and were never given part numbers (a rotating part and a printed
  housing cannot be one piece). **Resolved by the petal-deployment
  transplant** (spec §4): `15_ReleaseActivator.stl` through
  `22_ReleaseLockingPin.stl` are real, `use<>`-instantiated parts
  (`CableReleaseBBMicro.scad`) implementing exactly this rotating lock
  ring / ball-detent / magnetic over-centre catch, not a stated future
  task.
- **Spring force** — no spring rate or vendor figure for the CS4323 exists
  anywhere in this repo. Spec A11 calls this the single largest
  open risk in the recovery system; bench-test before flight (§8 item 2).
- **No mechanical backup exists for the primary release** (11th review,
  spec A13, replaces the retracted A12 "ejection-charge backup" claim)
  — the petal lock nubs are a positive, 2.25mm-engagement lock; the
  Ø56.4 petals have only 0.2mm of radial flare inside the Ø56.8 body
  bore, not enough to open under internal gas pressure. The G80T's
  ejection charge cannot open the petals; the barometric/timer servo
  path (servo, wiring, Vega servo rail, lock ring) is a single point of
  failure for recovery. A from-scratch redundancy design is out of this
  task's scope (spec §4.3).
- **The ejection charge cannot be disabled** and fires, undrilled,
  **~5.0s after apogee** (13th review, correcting a "1-3s" figure that
  only matches a DRILLED ~11s delay, not the stock 14s grain — burnout
  1.7s + 14s = 15.7s from liftoff vs 10.7s to apogee; see spec §9
  item A5 for the drilled case), venting up the open fin can/deployment bay toward
  the just-deployed main — fit a Nomex chute protector and sleeve the
  shock cord (spec §4.3, assembly step 12).
- **Chute-bay depth shortfall — RESOLVED (12th review, owner's
  ruling)** — the 11th review's ~12.2mm shortfall (measured at the
  then-current `R60_Petal_Len`=120/`R60_Chute_L`=240) was the correct
  finding, but growing `R60_Chute_L` in place turned out not to be a
  "give it more room" fix: the release stack's own footprint and the
  hub's own reach past the petal root do not depend on `R60_Chute_L` at
  all, so a longer tube pushes the fin can further AWAY from the hub's
  fixed reach, growing the gap rather than closing it (confirmed by
  mutation, below). The real fix is landing `R60_Chute_L` on the
  station the hub's own spigot actually needs (277.7mm minus a chosen
  2.7mm of real engagement = **275mm**, not tangent, not bottomed out)
  — see `R60Lib.scad`'s own `R60_Chute_L` comment for the full
  derivation. 275mm exceeds this project's own "fits 250mm Z" rule and
  the Bambu P1S's own 256mm build volume as one piece (true at either
  120mm or 140mm `R60_Petal_Len` — the 120mm minimum was already
  ~255mm), so the tube is now **two printed pieces**,
  `03_DeploymentBayTubeFwd.stl` + `26_DeploymentBayTubeAft.stl`, joined
  by a glued in-wall spigot/socket (spec §4.1 has the load this joint
  is sized against and the glue-area numbers).
- **Deployment-bay axial closure check — now genuinely two-sided, both
  directions mutation-tested** (11th/12th review —
  `tools/verify_rocket60_assembly.py`'s own `check_closure()`; mesh-
  based, independently confirms `tools/rocket60_model.py`'s own closure
  assert, which was already two-sided). The 11th-review version of this
  check was itself one-sided — it could only fail on a tube too SHORT,
  and would have silently PASSED a tube grown too LONG (the hub's
  spigot then never reaches the fin can at all, a real gap, the same
  defect class from the other direction) — found by this session's own
  attempt to "just add slack" to `R60_Chute_L`, which the check should
  have caught and did not. Fixed to compare `abs(over)`, matching
  `rocket60_model.py`'s own formula; mutation-tested both directions
  (`R60_Petal_Len`=200: SHORT by 57.2mm; `R60_Chute_L`=290: GAP of
  6.8mm, tube too long — both correctly FAIL). Scanned every
  neighbouring check in both harness files for the same one-sided-
  formula defect shape (not just "checks one direction by nature", a
  different, non-bug case) — none found; see
  `verify_rocket60_assembly.py`'s own "Neighbouring one-sidedness scan"
  comment for the full accounting. Still uncovered, unrelated to this
  fix: spring throw vs. the piston's real insertion travel; the lock
  nubs' own engagement FORCE (needs the still-undocumented CS4323
  spring rate, spec A11); the hinge's clearance through its full open
  swing, not just at rest; the 3x hinge-preload springs' own geometry;
  a hinge fit that is too LOOSE (not just too tight — an intersection-
  volume probe cannot see missing material, only colliding material);
  and the shock-cord route's clearance past the hinges/release stack —
  see `check_closure()`'s own module comment for the full list.
- **Packing volume — RESOLVED (12th/14th review), and the 11th
  review's own "~13% shortfall" figure retracted as an overestimate.**
  That figure was itself never measured — an assumed ~24mm fixed
  obstruction (hub floor + spring-holder bosses "~18mm", piston face
  "6mm", both eyeballed off the source). Mesh-probed (12th review,
  `check_packing()`, Pairs 42/43): the real hub/piston obstruction is
  16.3 cm³, not the ~53 cm³ the estimate implied. At the OLD
  `R60_Petal_Len`=120, net packing was 250.4 cm³ against the ~250 cm³
  requirement — tangent, not a 13% shortfall, but not a margin either.
  Owner ruling: grow `R60_Petal_Len` to 140 (Rocket6551.scad's own
  stated ceiling for a single CS4323 spring). **14th review: a THIRD
  obstruction source — `PD_Petals()`'s own lock nubs (r=24.2mm) and
  `AntiClimber()` ridges (r=22.26mm), found while checking
  `AntiClimber_h` — was reported, then closed the same session, not
  left unnetted.** Pair 44 (`r60_assembly.scad`) mesh-probes the WHOLE
  petals mesh against the same bore, at its real hub-relative offset:
  2.7 cm³, measured (not estimated) — the same "measure it, don't
  estimate it" standard that retracted the 11th review's own 13%
  figure, now applied a second time to a different feature. Net,
  correctly: **292.2 cm³ against the ~250 cm³ requirement, ~17% real
  margin** (was a provisional, incompletely-netted 294.9 cm³/~18%
  between the 12th and 14th review) — see spec §4.1 for the full
  record; the smaller-canopy and thinner-fabric-pack options once
  listed here are superseded, not still live alternatives. Printed-
  geometry intrusions into the bore are now believed complete (hub
  floor, spring-holder bosses, piston face, petal lock nubs/
  AntiClimber — four sources, all mesh-measured); NOT geometrically
  netted, and not expected to be, since they are not printed geometry:
  the 3x hinge-preload coil springs and the shock cord's own route,
  both loose hardware whose packed footprint is a density question
  (folded into the stated ~0.20 g/cm³ packing-density assumption), not
  a rigid-body volume subtraction.
- **Release-hardware mounting interference** — PARTIALLY resolved (10th
  review): part 15's own mount to the aft bulkhead (part 5) now has a
  mesh-against-mesh mating-fit AND fastener-reach check
  (`tools/r60_assembly.scad` Pairs 33/34) — this is the joint that was
  actually broken (wrong bolt circle, wrong fastener standard; see
  `Rocket60.scad`'s `R60_EBayAftBulkhead()` module comment). The REST of
  the internal release chain (16↔15, 17↔16, etc — all donor-native
  `CableReleaseBBMicro.scad` hardware, unmodified by this transplant)
  still has no bolt-to-bolt mounting-interference model, only the
  max-radius-vs-bore dimensional check in `tools/verify_rocket60.py`
  (which is what decided BBMicro vs. BBMini). A full model for that
  remainder is future work.
- **Rail button axial placement** — resolved (task 7; 10th review
  corrected the forward station's own reference frame): azimuth 180°,
  Z=630mm (aft) / Z=242mm (forward), §5 above.
- Spec §5/§6 (performance, stability) are analysis, reproduced by
  `tools/rocket60_model.py`, not built by any printable part.

**Fin sizing (unchanged by this task — parts 9/10 are protected).** The
fin planform (Cr 90/Ct 35/span 63/sweep 45/t 4.0mm) is exactly as it
was before the petal-deployment transplant; only the AIRFRAME'S overall
length changed (deployment bay 180→240→275mm, the last step the 12th
review's own tube-split/packing-margin ruling), moving both CP and the
fin can further aft each time. Re-run with the transplant's new
geometry, the G80T-14A margin **IMPROVED from 1.46 cal to 1.69 cal**
(10th/11th/12th review: this figure has moved several times since, from
an intermediate 1.68 cal when the aft bulkhead's own mass fix shifted
CG, to 1.56, to 1.53 when the hinge subsystem's own mass was added, to
1.69 when R60_Chute_L grew to 275 and R60_Petal_Len to 140 this round —
same station audit discipline this section's own history already
follows) — CP moved aft by more than CG did each time, since the added
length sits entirely forward of the fin can. Clears the physical
minimum, **1.0 cal**, with real room. H182R-14A gives **1.48 cal**,
H135W-14A **1.49 cal** on the same fins — comfortably above 1.0 cal, no
ballast needed. **Flutter formula fixed, not just re-run**: `flutter_Vf()`
computed t/c on the exposed panel's MEAN chord; the NAR/TIR-33 form it
implements (from NACA TN 4197) defines t/c on the exposed ROOT chord.
The previously-published 955 m/s was wrong by a factor of
(77.9/56.4)^1.5≈1.62×; the corrected figure is **589 m/s**. Still clears
the G80T (the sizing case) at 4.8× its Vmax; the flutter gate itself was
re-scoped from a single "3× the fastest motor overall" check (calibrated
against the wrong 955 m/s number) to a per-motor 1.5× floor — G80T 4.8×,
H182R 3.0×, H135W 3.2×, all clear. Rail exit on the G80T on the owner's
1.83 m rail is 20.0 m/s, comfortably above the ~15 m/s minimum. See
`tools/rocket60_model.py`'s own output for the full sweep.
