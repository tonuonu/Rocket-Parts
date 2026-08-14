# Rocket 60 — 3D Print Settings

**Project:** Rocket 60 camera rocket (60 mm body, CATS Vega dual-deploy)
**Author:** Tõnu Samuel
**Date:** 2026-08-13
**Spec:** `docs/superpowers/specs/2026-08-13-rocket60-design.md`
**Parts:** `STL Files/Rocket60/README.md`, generated from `Rocket60.scad`

---

## Status — read this before printing anything

**Updated after a code-review fix pass.** All 15 printable parts (test ring
through the forward thrust ring) plus the fixed `NoseCone.stl` now exist as
meshes and are covered below, including the separation mechanism and the
tether latch this section used to say had "no STL":

- The primary separation path (spec §4.2) is `08_SpringCarrier.stl`: servo 1
  releases a ball-lock, freeing a CS4323 spring that shears 2 nylon pins
  bridging `03_ChuteBayTube.stl` and `05_EBayAftBulkhead.stl`'s aft skirt —
  the cam-ramped bayonet originally planned for this joint was abandoned (it
  does not generate torque from axial load) and is not in this design.
  **This carrier is deliberately incomplete on its own**: the rotating lock
  ring and the sliding plunger/spring cap that physically release and react
  the spring are, by mechanical necessity, separate parts (a rotating part
  and a printed housing cannot be one piece) and are **not modeled or given
  their own part numbers by this design**. Do not consider the recovery
  system flight-ready until those two companion pieces exist and are built.
- `13_TetherLatch.stl` — releases the main at 150 m, mounts to
  `05_EBayAftBulkhead.stl`'s aft face — now exists.
- `14_ThrustRing.stl` — new. Glues into the MMT's forward opening,
  flush with the fin can's own tip, and reacts the motor's FORWARD
  thrust reaction, which `11_MotorRetainer.stl` alone cannot: that
  retainer only resists motion out the aft end. Without this ring the
  motor+spacer stack had only a 0.3mm slip fit standing between it and
  the packed parachute during the whole burn.
- `09_FinCan.stl` and `11_MotorRetainer.stl` fasten together with 3× M3 into
  ruthex heat-set inserts (`Rocket60.scad`'s "screws to the fin can" intent
  is now built, not sand-fit).
- Everything else listed in `STL Files/Rocket60/README.md` — test ring,
  neck, e-bay tube, chute bay tube, both e-bay bulkheads, Vega sled, access
  door, fin can, fins, motor retainer, motor spacer, forward thrust ring,
  plus the fixed `NoseCone.stl` — exists as a mesh and is covered below.

**Motors:** AeroTech G80T-14A (owned, 29 mm) is the sizing motor — fins were
originally sized for a 1.5 cal static-margin target at liftoff, but a
full station audit (coordinator override, 4th review) found the TRUE
margin is **1.46 cal**, not the 1.53 cal (itself already a correction of
an inflated 1.61 cal) previously published here. The 1.5 cal figure was
never a physical requirement — it was retired as the gate and replaced
with the actual physical minimum, **1.0 cal** (standard high-power
practice's accepted 1.0–2.0 cal band); 1.46 cal clears that with real
room and is accepted, not merely tolerated. See spec §6.1 for the full
reasoning and station-audit table. Airframe is sized for
a 29 mm H DMS (H182R-14A or H135W-14A) so Mach 0.60 is available later with
no reprint (spec §1.1, §5); both clear the same 1.0 cal minimum (§9).
**Envelope:** tallest printed part is the fin can at 228 mm, inside the
Bambu P1S's 256 mm Z with 28 mm to spare (spec §8).

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
from "G ≈ 0.5 GPa for printed PETG" → Vf ≈ 959 m/s (63mm-span fin, exposed
geometry — see §9's fin-sizing note), 1.52× the required 3× floor against
the H182R's 210 m/s Vmax. Moving the fins to PC would change that shear
modulus and orphan the documented margin without a recompute, and neither
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
| 3 | Chute bay tube | PETG | 4 (§8) | N/A — same as e-bay tube | 0.2 mm (§8) | Vertical, as modeled | No |
| 4 | E-bay fwd bulkhead | PETG | 4 (§8) | 25–30% gyroid **[practice default]** — 17 mm radial disc, not flight-critical (harness pass-through only) | 0.2 mm (§8) | Flat, either face down | No |
| 5 | E-bay aft bulkhead | PETG | 4 (§8) | **≥50% gyroid, or solid, in the servo-pocket floor / cord-anchor region [practice default, deliberately conservative]** | 0.2 mm (§8) | Flat, servo/cord-pocket face **up** — the pockets open on one face only; printing that face up avoids bridging the pocket floors | Recommended — this part must not warp out of flat |
| 6 | Vega sled | PETG | 4 (§8) | 25–30% gyroid **[practice default]** | 0.2 mm (§8) | Flat, standoffs up | No |
| 7 | Access door | PETG | 4 (§8) | N/A — 1.6 mm wall, matches tube wall | 0.2 mm (§8) | Vertical, curved face as modeled | No |
| 8 | Spring/ball-lock carrier | PETG | 4 (§8) | 25–30% gyroid **[practice default]**; the diaphragm floor and ball-pocket bosses print fully solid from walls regardless | 0.2 mm (§8) | Vertical, as a tube, aft face down (the face that glues flush to `05_EBayAftBulkhead.stl`'s skirt) — matches modeled Z | **Yes, plus supports under the diaphragm** — a Ø44.8 mm internal floor bridging open space on both sides; enable tree/normal supports touching build plate only, so they don't fuse into the spring bore |
| 9 | Fin can (incl. 3 integrated centering rings + MMT) | **PC** | 4 (outer 1.6 mm wall and 1.5 mm MMT wall both print fully solid at 4 loops of a 0.4 mm nozzle — see note) | 70% gyroid **[from `L2-PrintSettings.md` PC fin-can precedent]** — governs only the three ~12 mm-wide integrated ring bands, not the thin tube/MMT walls | 0.12 mm **[from L2 precedent]** | Vertical, aft (retainer) end down | **Yes, 5 mm** — PC warps; large footprint helps (per `L2-PrintSettings.md`) |
| 10 | Fin (×3) | PETG | — (solid from flat print, no wall-loop concept) | **62% (§8, literal)** — pattern not specified by spec; gyroid assumed **[practice default: pattern only]** | 0.2 mm (§8) | Flat, oriented so layer lines run spanwise (§8, literal) | No |
| 11 | Motor retainer | **PC** | 4+ **[from `MotorAdapter29.scad` PC print-settings precedent]** | 40–60% **[same precedent]** | 0.2 mm **[same precedent]** | Flat, 6 mm disc — print flat, either face down (unlike the adapter's own tall geometry, this part has no long axis to stand on) | Recommended (same precedent) |
| 12 | Motor spacer | **PC** | 4+ **[same `MotorAdapter29` precedent]** | 40–60% **[same precedent]** | 0.2 mm **[same precedent]** | Vertical, as a tube (98 mm for the G80T; re-export for `Motor_Class=1`/`2` for the H182R/H135W — 19/6 mm; stops short of part 14, not the full MMT) | Recommended (same precedent) |
| 14 | Forward thrust ring | **PC** | 4+ **[same `MotorAdapter29` precedent]** | Solid — 6 mm thick, 1.05 mm lip, no interior to fill | 0.2 mm **[same precedent]** | Flat, either face down — a 6 mm annulus, no long axis | Recommended (same precedent) |
| 13 | Tether latch | PETG | 4 (§8) | 40–50% **[practice default]** — small part, carries a cyclic tumbling load per §8 item 3, not just a static pull | 0.2 mm (§8) | Flat, base down, posts up — the horizontal Ø3.2 mm pin bore through each post is small enough to bridge cleanly without support at this layer height | No — small footprint and flat base |

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
6.2 mm slot (spec §9). **1010 rail only — the 3 mm launch rod is not
usable at this mass**; at this length a 3 mm rod would whip badly and rail
exit would be unstable (spec §9).

At the as-built liftoff mass (874 g on the G80T, from
`tools/rocket60_model.py`'s measured-mesh masses — see §9's fin-sizing
note) the rocket leaves a 1.5 m rail at **18.8 m/s**, comfortably clear of
the ~15 m/s minimum needed for the fins to stabilize the vehicle (spec
§5, §6) despite the fin-span growth. The H182R is unaffected (27.9 m/s off
1.5 m). A 1.5 m rail is adequate for the G80T; confirm actual rail exit
before committing to anything shorter (spec §11 item 6).

Exact axial station for the two rail buttons is not given in the spec or
the STL README — place them per normal practice (one near the loaded CG,
one further aft) and confirm the rocket balances and clears the rail
cleanly with both mounted; this is not a sourced number.

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
   §7.2). Thread two M3 rods into `04_EBayFwdBulkhead.stl`'s own inserts
   (fixed, permanent). Slide `06_VegaSled.stl` onto the two rods —
   antenna side still radially outward — until it hard-stops against the
   forward bulkhead's own boss face. Thread a nut+washer onto each rod's
   free end, against the sled's own rail face, drawing the sled snug
   against the forward bulkhead. Check the antenna orientation now — it
   cannot be corrected once the aft bulkhead closes the assembly in step
   6. Every fastener here is turned in open bench air; none is reached
   down a blind tube.
4. Install both MG90S servos in `05_EBayAftBulkhead.stl`'s upright
   pockets, shafts along the rocket axis (spec §3.2). Screw
   `13_TetherLatch.stl` to the bulkhead's aft face (2× M3 into ruthex
   inserts) so servo 2's horn can reach it.
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
9. Glue `08_SpringCarrier.stl`'s forward rim to `05_EBayAftBulkhead.stl`'s
   aft skirt (same OD, flush joint) — this closes the e-bay's pressure
   boundary and gives the (separately-sourced) ball-lock plunger/lock ring
   somewhere to seat. **The carrier alone does not make a working release
   — see Status.**
10. Epoxy the 3 fins into `09_FinCan.stl`'s slots; screw
   `11_MotorRetainer.stl` to the fin can aft end (3× M3 into ruthex
   inserts). Glue `14_ThrustRing.stl` into the MMT's forward opening,
   flush with the fin can's own forward tip — do this before the next
   step, it is not reachable once the chute bay tube is bonded on.
   Nothing else reacts the motor's forward thrust: the aft retainer
   only resists motion out the back. Install `12_MotorSpacer.stl` for
   the G80T (re-export for `Motor_Class=1`/`2` for the H182R/H135W).
11. Slide `03_ChuteBayTube.stl` forward over `05_EBayAftBulkhead.stl`'s
    aft skirt until the two shear-pin holes line up, and drive in the 2
    nylon 2-56 pins — this is the joint the ejection-charge backup shears
    (spec §4.2). Do not glue it; it must stay serviceable. Tie the tether
    off through the tube's forward-rim lug (part of the same tube) to
    `13_TetherLatch.stl`'s pin. Bond the chute bay tube to the fin can's
    forward end — its own aft end carries a Ø56.4 spigot that inserts
    into the fin can's forward opening, so this is a located, concentric
    joint, not a bare butt bond.

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

The two servo channels: `EV_APOGEE` drives servo 1 (releases the separation
joint) and `EV_MAIN_DEPLOYMENT` drives servo 2 (releases the tether at
150 m). Set the actual 0–1000 unlock/release positions on the bench once
the separation and tether hardware exist (spec §7.2).

**Timers — the third independent path** (spec §7.4), values for the G80T:

| Path | Apogee separation | Main release |
|---|---|---|
| 1. Barometric | `EV_APOGEE` → servo 1 | `EV_MAIN_DEPLOYMENT` @ 150 m → servo 2 |
| 2. Timer | Timer 1: liftoff → **12.5 s** (apogee 11.0 s + margin) | Timer 2: liftoff → **~50 s** |

**These timer values are for the G80T only. Recompute before flying an H**
— apogee is 12.4 s for the H182R, 13.1 s for the H135W (spec §7.4, §9
item A5).

---

## 8. Pre-flight checks

Copied from spec §11, with one adaptation flagged below.

1. Trial-fit the neck to the physical camera carrier and to the nosecone —
   **before** printing anything downstream. (This is the same gate as §1
   above, restated for the neck specifically.)
2. **Bench-test the separation joint on a pull rig: measure the force
   needed to shear both nylon pins.** Accept 80–130 N total. Below 80 N it
   risks opening in flight; above 150 N the motor-eject backup loses
   authority (spec §4.2). Separately, confirm the compression spring's
   actual force exceeds the pins' combined shear load with margin — spec
   §4.2 item A11 calls this "the single largest open risk in the recovery
   system," since no spring rate or vendor figure appears anywhere in the
   source files.
   > **Adaptation note:** spec §11 item 2 as written still refers to the
   > cam-ramped bayonet ("bench-test the bayonet on a pull rig... adjust
   > the ramp angle") and cites a nonexistent §10.2. §4.2 explicitly
   > supersedes that mechanism with the shear-pin + spring joint; the
   > 80–130 N force band and the pass/fail logic carry over unchanged, so
   > this item is restated above for the joint that actually exists rather
   > than copied verbatim for hardware that was abandoned.
3. Bench-test the **tether latch** separately: it carries the aft
   section's flopping load for the whole ~25 s tumble, not just a static
   pull. Load it to 3× the aft section weight (~13 N) with the latch
   closed, cycle it 20 times, confirm it neither creeps open nor jams.
4. Bench-test the full Vega sequence on the ground: arm → apogee servo →
   tether servo.
5. Swing test or measured CG/CP check with the real, loaded rocket.
6. **Weigh the fully assembled rocket and compare against
   `tools/rocket60_model.py`'s own liftoff-mass figure (874 g, G80T
   config) before committing to a rail length.** Rail exit is what mass
   actually threatens on this rocket (18.8 m/s off a 1.5 m rail against a
   ~15 m/s minimum, spec §6.1) — NOT stability, which now clears its own
   1.0 cal minimum with real room (spec §6.1). Roughly 269 g of the
   modelled 874 g (31%) is flat-gram hardware ESTIMATES, not measured
   mesh volumes, so the real liftoff mass could differ meaningfully from
   874 g:
   - camera assembly (60 g), 2× MG90S servos (27 g, datasheet),
     parachute+cord+hardware (70 g), battery+wiring (45 g), CATS Vega
     board (25 g — its sled IS a measured mesh volume, the board itself
     is not), CS4323 spring (25 g, already flagged unverified — spec
     §4.2 item A11), switch hardware (8 g), rail buttons (4 g), neck
     bolts (3 g), tether latch pin (1 g), shear pins (0.5 g).
   - Every PRINTED part's own mass IS a measured mesh volume (STL_VOL in
     `tools/rocket60_model.py`) — but scaled by a single blended
     infill/print-density figure (`INFILL_EFF=0.78`) that is itself a
     stated, unverified assumption applied across every PETG part alike,
     not per-part infill actually measured off a scale (§3's own
     infill % differs 25–62% per part).
   - If the weighed rocket comes in meaningfully over 874 g, re-check
     rail exit against the ~15 m/s minimum before flying — a shorter or
     lower-thrust rail exit is the actual failure mode a heavier-than-
     modelled rocket produces, not a stability problem.
7. Confirm rail exit on a 1.5 m rail before committing to a shorter one.
8. **Confirm the arming switch can actually be reached and thrown with the
   rocket vertical on the rail.** The Vega calibrates once, automatically,
   as soon as it detects no motion after boot — it must not be powered up
   before the rocket is vertical on the rail, and disarming afterward is
   only possible by powering off (spec §7.1, §11 item 7).
9. Confirm `enable_telemetry` is `true` and the ground station shows a
   GNSS fix **before** the rocket leaves your hands. The firmware default
   is `false`.
10. First flight on the G80T-14A, single objective: recover the airframe
    and read the Vega log. Compare logged apogee to the 625 m prediction
    and correct Cd₀ before flying the H.

---

## 9. Known gaps — do not treat this as a finished rocket

- **Ball-lock plunger and rotating lock ring** — `08_SpringCarrier.stl`'s
  fixed housing (mounting rim, diaphragm, ball pockets, spring bore) exists,
  but the two moving companion parts that actually catch and release the
  spring do not, and are not given part numbers by this design (a rotating
  part and a printed housing cannot be one piece — see `R60_SpringCarrier()`'s
  module comment). **The primary separation path is not flight-complete
  without them.**
- **Spring force** — no spring rate or vendor figure for the CS4323 exists
  anywhere in this repo. Spec §4.2 item A11 calls this the single largest
  open risk in the recovery system; bench-test before flight (§8 item 2).
- **Rail button axial placement** — not specified in any source.
- Spec §5/§6 (performance, stability) are analysis, reproduced by
  `tools/rocket60_model.py`, not built by any printable part.

**Fin sizing (resolved — 1.0 cal minimum, not 1.5 cal target).** The original Barrowman analysis counted the
fin's full 55mm span as exposed to the airflow, when 14mm of it
(`R60_Body_OD/2 - R60_MMT_OD/2`) actually sits buried under the epoxied
joint inside the fin can. Fed the correct exposed geometry, the as-shipped
fin gave the G80T-14A — the motor actually owned, and the sizing case —
only 1.05 cal at liftoff. Span was grown 55→63mm (root/tip/sweep/thickness
unchanged: span is the most mass-efficient lever, since `CN` scales with
`(exposed span/D)²`) originally targeting 1.5 cal on the G80T. A full station audit
(coordinator override, 4th review, spec §6) found the TRUE margin is
**1.47 cal**, not the 1.53 cal previously
published here (itself already a correction of an inflated 1.61 cal).
The 1.5 cal target was retired rather than chased with further span
growth (spec §6.1): it was never a physical requirement, only this
project's own earlier comfort target, and buying back the remaining
margin would cost mass on the exact G80T flight where rail exit, not
stability, is the binding constraint. The gate is now the real physical
minimum, **1.0 cal**, and 1.47 cal clears it with genuine room. H182R-14A gives 1.28 cal and H135W-14A gives 1.29 cal on the
same fins — both comfortably
above 1.0 cal, no ballast needed, though nose ballast is standard practice
if either H's margin is ever wanted higher. Flutter velocity dropped from
the fins growing (959 m/s vs. the original claim of ~850 m/s against the
WRONG, buried-root geometry) but stays 1.53× the required 3× floor against
the fastest motor (H182R-14A, 209 m/s Vmax → 627 m/s floor). Rail exit on
the G80T on a 1.5 m rail is 18.8 m/s, still comfortably above the ~15 m/s
minimum despite the added fin mass (+4.7g/fin, +14.0g total) and the mass
corrections in §9's own history. See `tools/rocket60_model.py`'s own
output for the full sweep and the rejected alternatives (growing root
chord alone costs more mass for the same margin; trimming tip chord or
thinning the fin were rejected because they cut into the flutter margin
this low-aspect-ratio planform exists to buy).
