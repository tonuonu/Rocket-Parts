# Rocket 60 — Design

**Date:** 2026-08-13
**Status:** design approved, not yet implemented
**Goal:** a recoverable high-subsonic camera rocket built around an existing,
unmodifiable nosecone that carries the camera assembly and films forward.

---

## 1. Requirements

| # | Requirement | Source |
|---|---|---|
| R1 | Carry the existing camera assembly in `Nose Cone.STEP`, filming forward from the nose | user |
| R2 | `Nose Cone.STEP` geometry must not change; a neck may be added below it | user |
| R3 | Fly on motors the user owns: AeroTech G80T-14A (29 mm) or TSP E20-P (24 mm) | user |
| R4 | High subsonic speed | user |
| R5 | CATS Vega flight computer embedded in the airframe | user |
| R6 | Reliable recovery — parachute or equivalent; losing airframes is not acceptable | user |
| R7 | Electronic deployment preferred over pyro; pyro acceptable | user |
| R8 | Launch from a 1010 rail (0.245 in / 6.22 mm slot) | user |

### 1.1 Requirements that could not be met as stated

**R3 (TSP E20-P) is not satisfiable and is dropped.** Simulated in this airframe the
E20-P gives T/W 2.8 and **9.2 m/s off a 1.5 m rail** — well under the ~15 m/s needed for
the fins to stabilise before rail exit. Apogee 99 m. No Ø60 mm airframe carrying the camera +
Vega + recovery can be made light enough to fix this: the motor, camera, nosecone, Vega and
battery alone are ~227 g before any structure exists. **The E20-P is excluded from this
design.** The 29 mm MMT still accepts the existing `MotorAdapter29` if the user wants to
static-test or fly it at their own discretion.

**R4 (high subsonic) is only partly met.** See §5. On the G80T-14A this rocket reaches
Mach 0.42. The airframe is sized for a 29 mm H DMS from day one so that **Mach 0.65** is
available with a motor purchase and no redesign or reprint (**Mach 0.64**). Mach 0.8+ is not reachable at
Ø60 mm with this payload on any 29 mm motor.

---

## 2. Fixed constraints — measured from `Nose Cone.STEP`

Measured with FreeCAD 0.21.1 (`Part.Shape.read` + planar sections). The STEP is authored in
a parent-assembly frame: nose **tip at Y = 596.0**, **base plane at Y = 501.95**, axis = **+Y**.
All figures below are restated as *height above the base plane*.

| Feature | Value |
|---|---|
| Overall length | **94.05 mm** |
| Base outside diameter | **59.98 mm** ← sets the airframe OD |
| Base annulus | OD 59.98 / ID 54.25 |
| Bore, 0.5–1.5 mm above base | Ø53.25 (r 26.625) |
| Bore, general | Ø55.6, wall ≈ 2.0 mm |
| Internal lugs, ±X | reach in to Ø50.2 across flats, base → 10.55 mm up |
| Screw station 1 | 2× radial Ø3.4 mm, countersunk Ø7.3, at **5.55 mm** above base, ±X |
| Screw station 2 | 2× radial Ø3.6 mm, countersunk Ø9.3, at **35.55 mm** above base, ±X |
| Lens aperture at tip | Ø15.3 mm × 4.3 mm deep |
| Shell volume | 29 441 mm³ (≈ 37 g in PETG) |
| Nose fineness ratio | 1.57 (blunt — factored into Cd₀) |

Both screw stations are consumed by the **camera assembly** (`~/Camera.STEP` — authoritative;
`~/Desktop/camera.STEP` is an older export whose internal FILE_NAME string reads `Seeker.STEP`;
byte-different but
**geometrically identical** content: same 37.60 × 94.00 × 54.04 mm envelope, same 25 842 mm³,
same bolt pattern). It fills the nosecone and sits flush with the base plane. The neck therefore cannot use the bore or the radial screws.

### 2.1 Neck ↔ camera bolt interface (derived from `~/Camera.STEP`)

Three Ø3.3 mm holes open on the camera assembly's bottom face, each with a Ø7.0 concentric
feature 5 mm deep, all lying on one bolt circle:

| Hole | X (mm) | Z (mm) | Radius from axis | Angle |
|---|---|---|---|---|
| A | +11.62 | +15.00 | 18.97 | +52.2° |
| B | +11.62 | −15.00 | 18.98 | −52.2° |
| C | −18.98 | 0.00 | 18.98 | 180.0° |

**Bolt circle Ø37.96 mm**, deliberately *not* 120°-symmetric — the asymmetry keys the
camera's clocking. Holes A and B continue upward as Ø6.0 mm pillars 55.5 mm long.

**Confirmed by the user: the three holes carry M3 heat-set inserts** (ruthex RX-M3×5.7,
5.7 mm engagement). The Ø7.0 concentric feature is the boss around each insert. The neck
therefore gets three plain **Ø3.4 mm clearance holes** on the same circle — **no counterbore**
— and **M3×10** screws pull the neck up into the camera.

The counterbore was removed during implementation. It had been specified opening from the
neck's *underside*, but the neck is modelled flange-first: its Ø56.4 skirt cannot enter the
nosecone's Ø55.6 bore, only the Ø56.8 body tube, so the skirt points aft and the flange's
other face is what presses against the camera. The counterbore therefore opened into the
mating face — the one surface it must not be in. Removing it outright is better than flipping
it: the neck's aft face is inside the airframe and mates with nothing (the e-bay tube's end
lands at r=28.4–30, well clear of the r=18.98 bolt circle), so a proud screw head touches
nothing, and the full 5 mm flange becomes grip.

That gives **5.0 mm of grip** under the head and **5.0 mm of thread engagement** in the
5.7 mm insert — it cannot bottom out.
>
> **ASSUMPTION A2** — `Nose Cone.STEP` and `camera.STEP` use different origins, so the
> rotational clocking between the two is inferred, not proven. Mitigated by making the neck
> axisymmetric except for the three bolt holes, so clocking only affects which way the
> camera faces, not fit.

---

## 3. Architecture

```
station 0 ┌────────────┐
          │  NOSECONE  │  94 mm   fixed part; camera inside, flush at base
      94  ├────────────┤
          │   NECK     │          3× M3 axial into camera carrier, Ø37.96 BC
          │   E-BAY    │ 160 mm   CATS Vega, battery, 2× servo, access door
     254  ╞════════════╡ ◄─────────  SEPARATION JOINT (cam-ramped servo bayonet)
          │ CHUTE BAY  │ 130 mm   24 in main + shock cord
     384  ├────────────┤
          │  FIN CAN   │ 228 mm   Ø29 mm MMT (223 mm), 3 fins, retainer
     612  └────────────┘
```

Total length **612 mm**, OD **60.0 mm**, **L/D 10.2**.

The e-bay is 160 mm, not the 130 mm first specified. Two upright MG90S servos plus the
100 mm Vega need 129 mm of interior and 130 mm of tube only yields 112 mm once the
bulkheads are subtracted. Lengthening was chosen over thinner packaging because it also
improves stability: margin rises from 1.48 to 1.55 cal loaded, and Mach falls only 0.01.

The fin can is 228 mm because the longest 29 mm H DMS (H135W, **216 mm**) has to fit — the
H182R is 203 mm and the G80T only 124 mm.

### 3.1 Load path and electrical routing — two invariants

1. **The shock cord anchors on the e-bay aft bulkhead.** Deployment snatch (easily >100 N)
   is reacted by the bulkhead, never by the 3× M3 screws into the camera's Ø6 mm pillars.
   The camera bolt joint only ever carries the nose section's own inertia.
2. **No wire crosses the separation joint.** Camera, Vega, battery and both servos are all
   forward of station 224. The camera's harness runs down through the open centre of the
   neck into the e-bay.

### 3.2 Parts

| # | Part | Print | Notes |
|---|---|---|---|
| P1 | Neck | new | **Butt joint, no spigot** — the camera fills the bore and is flush at the base, so nothing can enter it. Flat Ø59.98 top face bearing on the nosecone base annulus *and* the camera's bottom face; located by 3× **Ø3.4 clearance holes** on Ø37.96 BC, no counterbore (M3×10 SHCS into the camera's heat-set inserts, heads proud on the aft face where nothing bears); open-centre spider for the harness; skirt down into the e-bay tube. |
| P2 | E-bay tube | new | Ø60 OD, 1.6 mm wall, 130 mm, door cutout 36 × 85 mm |
| P3 | E-bay fwd bulkhead | new | Neck interface + harness pass-through |
| P4 | E-bay aft bulkhead | new | Shock-cord anchor, 2× servo mounts, bayonet ring drive. **Servos stand upright with shafts along the rocket axis**, following `PeregrineEjection.scad`: servo 1 on the centreline rotates the bayonet ring through its centre, servo 2 sits beside it and drives the tether latch through a slot. A radial layout is geometrically impossible — from the drive bore (r=6) to the disc edge (r=28.2) is 22.2 mm and an MG90S body is 22.8 mm long. |
| P5 | Vega sled | new | M3 standoffs on the L-pattern A (−13.5, −25), B (−13.5, +35), C (+13.5, +35) — 60 × 27 mm spacing per manual §4.3.3. Patch antenna faces radially outward, nothing between it and the wall. |
| P6 | Access door | reuse `DoorLib.scad` | 4× M2.5, curved panel, plus an **external arming switch** operable with the rocket vertical on the rail |
| P7 | Bayonet ring + lugs | adapt `PeregrineEjection.scad` | 101.5 mm → 60 mm; 3 lugs, 20° cam ramp |
| P8 | Chute bay tube | new | Ø60 OD, 1.6 mm wall, 130 mm |
| P9 | Fin can | adapt `FinCan2Lib.scad` | 228 mm, Ø29 MMT (223 mm), 3 fin slots, 3 centering rings |
| P10 | Fins ×3 | new | Cr 90 / Ct 35 / span 55 / sweep 45 / t 4.0 |
| P11 | Motor retainer | adapt `MotorAdapter29.scad` patterns | 29 mm aft retainer |
| P12 | Rail buttons ×2 | reuse `RailGuide.scad` | `RailButton(OD=11, Flange_h=2, Slot_w=2.8)` — 1010 |
| P13 | Motor spacers | new | 99 mm for the G80T, 20 mm for the H182R (223 mm MMT − motor length); none for the H135W |

New library file `R60Lib.scad` follows the existing `R65Lib.scad` / `R75Lib.scad` convention.

---

## 4. Recovery

**Dual deploy, no drogue**, both events electronic, one chute, one break.

| t | Alt | Event | Mechanism |
|---|---|---|---|
| 0 | — | Launch | 1010 rail, 1.5 m, exit 19.7 m/s |
| 11.0 s | 656 m | Apogee separation | Vega servo 1 rotates the bayonet ring; spring pushes sections apart. **Backup:** G80T ejection charge, delay set to ~11 s, cams the same ring open. |
| — | 656→150 m | Tumble descent | Sections held ~50 mm apart by a servo-latched tether; chute stays packed. ~23 m/s, 25 s, drift ~124 m |
| — | 150 m | Main release | Vega servo 2 releases the tether; sections separate fully, 24 in main is drawn out |
| — | 150→0 m | Descent | 6.9 m/s, 22 s, drift ~109 m |

### 4.1 Two separate lines — do not conflate them

| | **Shock cord** | **Tether** |
|---|---|---|
| Length | ~3 m (5× body length) | ~50 mm |
| Attaches | e-bay aft bulkhead ↔ fin can forward centering ring | e-bay aft bulkhead ↔ chute bay forward rim |
| Released? | **Never** — permanent | Yes, by servo 2 at 150 m |
| Carries | both sections + chute, for the whole descent | the 50 mm apogee restraint only |

The shock cord runs the full length of the joint and is **permanently anchored at both ends**:
forward on the e-bay aft bulkhead, aft on the fin can's forward centering ring. The main's
shroud lines attach to a loop at the cord's midpoint. The tether is a separate short line
whose only job is to hold the sections 50 mm apart during the tumble phase; when servo 2
releases it, the shock cord — still attached at both ends — is what keeps the aft section
(chute bay + fin can + motor, ~440 g) hanging under the canopy.

**Chute packing and extraction.** The 24 in main is packed in the chute bay (aft section,
forward end), 56.8 mm ID × 130 mm = 329 cm³ of usable volume, in a Nomex protector. Its
shroud lines run to the shock cord, which anchors on the e-bay aft bulkhead. At apogee the
tether holds the sections ~50 mm apart, so the chute — packed 130 mm deep — stays put.
At 150 m the tether releases and the sections separate under drag differential (streamlined
nose section vs draggy fin can), drawing the chute out on the shock cord. A compression
spring at the joint gives the initial positive push at apogee.

**Total drift ≈ 233 m at 5 m/s wind, 47 s to ground** — versus 522 m / 104 s for single deploy.
CATS Vega transmits GNSS position at 10 Hz on 2.4 GHz FHSS (flight-tested to 10 km), so
recovery is "walk to the last fix", not a search.

### 4.2 Cam-ramped bayonet

Three lugs with **20° ramped faces** on a servo-rotated ring.

- Flight axial load on the joint (coast deceleration of the ~297 g forward section at ~3 g): **≈ 12 N**
- Cam release threshold: **≈ 100 N** → 8× margin against inadvertent release
- Motor ejection over the Ø56.8 mm bore at 0.6 bar: 0.6 bar × 25.34 cm² = **≈ 152 N** → 1.5× over
  the release threshold, so the charge reliably cams the ring open

Both margins matter and they pull in opposite directions: raising the threshold protects
against premature release but eats the ejection backup's authority. 100 N is the chosen
compromise and **must be measured on the bench, not assumed** (§10.2).

This makes the servo and the motor charge two genuinely independent paths to the same event,
which a square-cut positive lock cannot provide.

> **Note:** with the H182R (also an ejection-charge DMS) the delay must be re-matched to the
> new apogee time of 12.9 s. The E20-P is plugged and would have **no** backup — another
> reason it is excluded.

---

## 5. Performance

Simulated by direct integration (1 ms steps), exponential atmosphere, Cd₀ = 0.52 with a
transonic rise above M 0.75, A = 28.27 cm².

| Motor | Liftoff | T/W | Rail exit | Vmax | Mach | Apogee | t(apogee) |
|---|---|---|---|---|---|---|---|
| **G80T-14A** (owned) | 816 g | 9.7 | 19.7 m/s | 139 m/s | **0.41** | 656 m | 11.0 s |
| **H182R-14A** (29 mm DMS) | 895 g | 20.7 | 28.8 m/s | 218 m/s | **0.64** | 997 m | 12.4 s |
| H135W-14A (29 mm DMS) | 900 g | 13.1 | 17.8 m/s | 202 m/s | **0.59** | 1049 m | 13.1 s |

Motor data, all from thrustcurve.org:

| Motor | Impulse | Avg thrust | Burn | Total | Propellant | Size | Delays |
|---|---|---|---|---|---|---|---|
| G80T | 136.6 Ns | 77.6 N | 1.7 s | 128 g | 63 g | 29 × 124 mm | 6–14 |
| H182R | 218.0 Ns | 182.0 N | 1.2 s | 207 g | 115 g | 29 × 203 mm | 6–14 adjustable |
| H135W | 225.8 Ns | 115.9 N | 2.0 s | 212 g | 82 g | 29 × 216 mm | 6–14 adjustable |

**Mach 0.64 is the realistic ceiling for this airframe**, and only on an H. Ø60 mm and
~800 g are both forced — by the nosecone base and by the payload — and together they cap
what any 29 mm motor can do. If a higher Mach number ever becomes the priority it needs a
different, smaller-diameter rocket, not a change to this one.

**The fin can (228 mm) and MMT (223 mm) are sized for the longest H, not the G80T.**
That is the whole point of the H-ready choice: the G80T flies now on a 99 mm spacer, and
either H drops in later with no new printed parts.

### 5.1 Mass budget (G80T configuration, PETG at 1.27 g/cm³)

| Item | Mass | Station |
|---|---|---|
| Motor G80T-14A | 128.0 g | 520 mm |
| Fin can tube | 85.1 g | 468 mm |
| Parachute + cord + hardware | 70.0 g | 283 mm |
| Camera assembly | 60.0 g | 47 mm |
| CATS Vega + sled | 60.0 g | 159 mm |
| Bayonet + 2 servos | 58.0 g | 232 mm |
| E-bay tube | 59.7 g | 174 mm |
| Chute bay tube | 48.5 g | 289 mm |
| Battery + wiring | 45.0 g | 159 mm |
| MMT | 40.6 g | 468 mm |
| Nosecone shell | 37.0 g | 42 mm |
| Fins ×3 (62 % infill) | 32.5 g | 525 mm |
| Retainer + rail buttons | 26.0 g | 552 mm |
| E-bay bulkheads | 24.0 g | 159 mm |
| Neck + bolts | 22.0 g | 106 mm |
| Centering rings ×3 | 19.8 g | 468 mm |
| **Total** | **816.1 g** | CG 326.5 mm |

---

## 6. Stability

Barrowman, 3 fins, Cr 90 / Ct 35 / span 55 / sweep 45 mm.

- CN(nose) = 2.00 at 43.8 mm; CN(fins) = 5.78 at 482.8 mm
- **CP = 419.7 mm** from the nose tip

| Motor | CG loaded | Margin | CG burnout | Margin burnout |
|---|---|---|---|---|
| G80T-14A | 326.5 mm | **1.55 cal** | 307.8 mm | 1.87 cal |
| H182R-14A | 337.1 mm | **1.38 cal** | 311.5 mm | 1.80 cal |
| H135W-14A | 336.5 mm | **1.39 cal** | 319.7 mm | 1.67 cal |

All configurations sit in the 1.0–2.0 cal band, and margin *increases* through the burn.
The H182R — the most aft-loaded case — is the sizing case at 1.38 cal.

**Fin flutter:** AR 0.88, λ 0.389, t/c 0.064, G ≈ 0.5 GPa for printed PETG →
**Vf ≈ 850 m/s**, 3.9× the H182R's 218 m/s. The deliberately low aspect ratio is what buys
this margin; do not make the fins thinner or longer-span without recomputing.

---

## 7. CATS Vega integration and configuration

Sourced from `~/cats-embedded/CATS User Manual.pdf` (v2.0.0) and the firmware itself
(`~/cats-embedded/flight_computer/src`), which is the authority where the two differ.

### 7.1 Constraints the manual imposes on the airframe

| Constraint | Source | Consequence for this design |
|---|---|---|
| **Power up only once the rocket is vertical on the pad.** Calibration runs once, as soon as no motion is detected after boot. | manual §4.3.3 warning | The arming switch **must be operable with the rocket already on the rail** — this is why the e-bay has an external switch, not just a door. Disarming afterwards is only possible by powering off. |
| Do not mount in a carbon-fibre section — it blocks all RF | manual §4.3.3 | **PETG only** from neck to chute bay. Already in §8. |
| Patch antenna needs a view of the sky | manual §4.3.3 | Sled orients the board with the patch antenna facing **radially outward**, with no battery, wiring loom or metal between it and the airframe wall. |
| Battery port is **7–25 V** (2S–6S) | manual §4.3.4, Table 7 | **A 1S LiPo will not run the Vega.** Use 2S. Budgeted 45 g covers a 2S ~850 mAh pack. |
| Switch carries full battery current | manual §4.3.4 | Switch and wiring rated accordingly. |
| Mounting holes 60 mm × 27 mm, M3, spacers recommended | manual §4.3.3 | Matches the L-pattern already recorded: A (−13.5, −25), B (−13.5, +35), C (+13.5, +35). Sled uses M3 standoffs so nothing touches the board. |
| Servo channels: regulated 5 V, **3 A**, endpoints configurable | manual §4.3.4 | Two MG90S servos run directly off the Vega. No separate BEC. |
| Pyro channels: 1 A continuous default (PTC), 5 A with the solder jumper closed | manual §4.3.4 | Both pyro channels stay **unused and free** — available later as a third recovery path. |

> Board envelope: the manual states 100 × 33 × **15** mm, catsystems.io states 21 mm.
> The sled is cut for **100 × 33 × 21 mm** so either is accommodated.

### 7.2 Event → action mapping

The firmware exposes exactly these events and actions:

- Events: `EV_CALIBRATE`, `EV_READY`, `EV_LIFTOFF`, `EV_MAX_V`, `EV_APOGEE`,
  `EV_MAIN_DEPLOYMENT`, `EV_TOUCHDOWN`, `EV_CUSTOM_1`, `EV_CUSTOM_2`
- Actions: `ACT_NO_OP`, `ACT_OS_DELAY`, `ACT_HIGH_CURRENT_ONE/TWO` (pyro),
  `ACT_LOW_LEVEL_ONE`, `ACT_SERVO_ONE/TWO`, `ACT_SET_RECORDER_STATE`
- Up to 8 (action, argument) pairs per event; servo argument is a **0–1000 position**, not degrees

Rocket 60 uses:

| Event | Action | Purpose |
|---|---|---|
| `EV_APOGEE` | `ACT_SERVO_ONE` → unlock position | Rotate the bayonet ring, separate |
| `EV_MAIN_DEPLOYMENT` | `ACT_SERVO_TWO` → release position | Release the tether, main deploys |

Both events are bound to the PWM servo channels in the configurator as part of normal setup.

### 7.3 Settings

| Setting | Value | Why |
|---|---|---|
| `main_altitude` | **150** | m AGL, main release. Firmware range 10–65535, default 200 |
| `liftoff_acc_threshold` | **40** | m/s². Manual wants ~20 below expected max; the G80T gives ~124 m/s² peak, the H182R ~207 |
| `servo1_init_pos` / `servo2_init_pos` | set on the bench | 0–1000; the **locked** positions |
| `enable_telemetry` | **true** | ⚠️ **firmware default is `false`.** Recovery depends on GNSS downlink — if this is left at default there is no tracking |
| `tele_link_phrase` | matched on the ground station | manual §4.3.5 step 17 |
| `enable_testing_mode` | **false** | manual §4.3.5 step 7 |
| `battery_type` | `LI_ION` or LiPo to match the pack | affects voltage warnings |

### 7.4 Timers — the third independent path

The manual (§4.3.5 steps 13–15) offers timers as a backup to barometric detection. With
three paths the design tolerates any single failure:

| Path | Apogee separation | Main release |
|---|---|---|
| 1. Barometric | `EV_APOGEE` → servo 1 | `EV_MAIN_DEPLOYMENT` @ 150 m → servo 2 |
| 2. Timer | Timer 1: liftoff → **12.5 s** (apogee 11.0 s + margin) | Timer 2: liftoff → **~50 s** |
| 3. Mechanical | G80T ejection charge cams the bayonet open (§4.2) | — none — |

Timer values are for the G80T. **They must be recomputed for an H** (apogee 12.4 s for the
H182R, 13.1 s for the H135W) — see §9 A5.

---

## 8. Materials and print

- **PETG throughout.** Not PLA (softens near the motor), and **no carbon-filled filament
  anywhere from the neck to the chute bay** — the manual is explicit that a carbon-fibre
  section "will block all RF signals", and both the 2.4 GHz telemetry and the GNSS patch
  antenna are inside the airframe.
- Airframe wall **1.6 mm**; 0.4 mm nozzle, 0.2 mm layers, 4 perimeters.
- All tubes print vertically; the longest part (fin can, 228 mm) fits the Bambu P1S 256 mm Z with 28 mm to spare.
- Fins print flat, 62 % infill, oriented so layer lines run spanwise.

## 9. Launch

**1010 rail only.** Two rail buttons via `RailButton(OD=11, Flange_h=2, Slot_w=2.8)` from
`RailGuide.scad`, whose verified 8020-1010 profile matches the user's 6.2 mm slot.
**The 3 mm launch rod is not usable** — at 798 g and this length a 3 mm rod would whip badly
and rail exit would be unstable.

---

## 10. Assumptions and open items

| ID | Item | Impact if wrong | Resolve by |
|---|---|---|---|
| ~~A1~~ | ~~Camera bolt pattern / thread type~~ | — | **Resolved:** M3 heat-set inserts (ruthex RX-M3×5.7). Neck uses Ø3.4 clearance + M3×10 SHCS. Pattern still worth a trial fit before printing downstream parts. |
| A2 | Nosecone ↔ camera clocking | Camera faces the wrong way about the roll axis | Neck is axisymmetric; trial fit |
| A3 | Camera assembly mass = 60 g ±20 g | CG shifts ≤4 mm; margin stays >1.2 cal | Weigh it |
| A4 | Camera battery lives in the e-bay, harness through the neck | E-bay volume | Confirm camera voltage/current. Note the **Vega needs its own 2S+ pack (7 V min)** — a shared 1S supply is not an option |
| A5 | G80T-14A delay is adjustable 14 s → ~11 s with the AeroTech DMS delay tool | Late deployment, ~3 s past apogee | Verify the tool's actual increments. Vega **timer values must also be re-entered per motor** (§7.4) |
| A6 | Cd₀ = 0.52 | ±0.07 changes apogee ±80 m, Mach ±0.02 | Compare against Vega's logged altitude on flight 1 |
| A7 | Printed-PETG shear modulus 0.5 GPa for flutter | Vf scales as √G; 4× margin absorbs a lot | — |

## 11. Verification before first flight

1. Trial-fit the neck to the physical camera carrier and to the nosecone — **before** printing anything downstream.
2. **(§10.2)** Bench-test the bayonet on a pull rig: measure the actual cam release force.
   Accept 80–130 N. Below 80 N it risks opening in flight; above 150 N the motor-eject backup
   loses authority. Adjust the ramp angle from 20° until it lands in band.
3. Bench-test the **tether latch** separately: it carries the aft section's flopping load for
   the whole ~25 s tumble, not just a static pull. Load it to 3× the aft section weight
   (~13 N) with the latch closed, cycle it 20 times, confirm it neither creeps open nor jams.
4. Bench-test the full Vega sequence on the ground: arm → apogee servo → tether servo.
5. Swing test or measured CG/CP check with the real, loaded rocket.
6. Confirm rail exit on a 1.5 m rail before committing to a shorter one.
7. Confirm the arming switch can actually be reached and thrown with the rocket vertical
   on the rail — the Vega calibrates once at boot and must not be powered up before then.
8. Confirm `enable_telemetry` is `true` and the ground station shows GNSS fix **before**
   the rocket leaves your hands. The firmware default is `false`.
9. First flight on the G80T-14A, single objective: recover the airframe and read the Vega log.
   Compare logged apogee to the 656 m prediction and correct Cd₀ before flying the H.
