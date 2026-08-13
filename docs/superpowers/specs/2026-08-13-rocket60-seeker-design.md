# Rocket 60 "Seeker" — Design

**Date:** 2026-08-13
**Status:** design approved, not yet implemented
**Goal:** a recoverable high-subsonic camera rocket built around an existing,
unmodifiable nosecone that carries the "Seeker" camera assembly and films forward.

---

## 1. Requirements

| # | Requirement | Source |
|---|---|---|
| R1 | Carry the existing Seeker camera in `Nose Cone.STEP`, filming forward from the nose | user |
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
the fins to stabilise before rail exit. Apogee 99 m. No Ø60 mm airframe carrying Seeker +
Vega + recovery can be made light enough to fix this: the motor, camera, nosecone, Vega and
battery alone are ~227 g before any structure exists. **The E20-P is excluded from this
design.** The 29 mm MMT still accepts the existing `MotorAdapter29` if the user wants to
static-test or fly it at their own discretion.

**R4 (high subsonic) is met only on an H motor.** See §5. On the G80T-14A this rocket
reaches Mach 0.42. The airframe is sized for a 29 mm H DMS from day one so that
Mach 0.71 is available with a motor purchase and no redesign or reprint.

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

Both screw stations are consumed by the **Seeker camera assembly** (`~/Desktop/camera.STEP`,
37.60 × 94.00 × 54.04 mm, 25 842 mm³ of solids), which fills the nosecone and sits flush
with the base plane. The neck therefore cannot use the bore or the radial screws.

### 2.1 Neck ↔ camera bolt interface (derived from `camera.STEP`)

Three Ø3.3 mm holes open on the camera assembly's bottom face, each with a Ø7.0 concentric
feature 5 mm deep, all lying on one bolt circle:

| Hole | X (mm) | Z (mm) | Radius from axis | Angle |
|---|---|---|---|---|
| A | +11.62 | +15.00 | 18.97 | +52.2° |
| B | +11.62 | −15.00 | 18.98 | −52.2° |
| C | −18.98 | 0.00 | 18.98 | 180.0° |

**Bolt circle Ø37.96 mm**, deliberately *not* 120°-symmetric — the asymmetry keys the
camera's clocking. Holes A and B continue upward as Ø6.0 mm pillars 55.5 mm long.

> **ASSUMPTION A1** — this pattern is CAD-derived. The concentric Ø7.0/Ø3.3 pair could be
> counterbores *or* bosses. **Confirm the thread type (heat-set insert / tapped / through-bolt)
> and the head clearance before printing the neck.**
>
> **ASSUMPTION A2** — `Nose Cone.STEP` and `camera.STEP` use different origins, so the
> rotational clocking between the two is inferred, not proven. Mitigated by making the neck
> axisymmetric except for the three bolt holes, so clocking only affects which way the
> camera faces, not fit.

---

## 3. Architecture

```
station 0 ┌────────────┐
          │  NOSECONE  │  94 mm   fixed part; Seeker camera inside, flush at base
      94  ├────────────┤
          │   NECK     │          3× M3 axial into camera carrier, Ø37.96 BC
          │   E-BAY    │ 130 mm   CATS Vega, battery, 2× servo, access door
     224  ╞════════════╡ ◄─────────  SEPARATION JOINT (cam-ramped servo bayonet)
          │ CHUTE BAY  │ 130 mm   24 in main + shock cord
     354  ├────────────┤
          │  FIN CAN   │ 215 mm   Ø29 mm MMT (H-length), 3 fins, retainer
     569  └────────────┘
```

Total length **569 mm**, OD **60.0 mm**, **L/D 9.5**.

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
| P1 | Neck | new | **Butt joint, no spigot** — the camera fills the bore and is flush at the base, so nothing can enter it. Flat Ø59.98 top face bearing on the nosecone base annulus *and* the camera's bottom face; located by the 3× M3 on Ø37.96 BC; open-centre spider for the harness; skirt down into the e-bay tube. |
| P2 | E-bay tube | new | Ø60 OD, 1.6 mm wall, 130 mm, door cutout 36 × 85 mm |
| P3 | E-bay fwd bulkhead | new | Neck interface + harness pass-through |
| P4 | E-bay aft bulkhead | new | Shock-cord anchor, 2× servo mounts, bayonet ring drive |
| P5 | Vega sled | new | CATS Vega L-pattern: A (−13.5, −25), B (−13.5, +35), C (+13.5, +35) |
| P6 | Access door | reuse `DoorLib.scad` | 4× M2.5, curved panel |
| P7 | Bayonet ring + lugs | adapt `PeregrineEjection.scad` | 101.5 mm → 60 mm; 3 lugs, 20° cam ramp |
| P8 | Chute bay tube | new | Ø60 OD, 1.6 mm wall, 130 mm |
| P9 | Fin can | adapt `FinCan2Lib.scad` | 215 mm, Ø29 MMT, 3 fin slots, 3 centering rings |
| P10 | Fins ×3 | new | Cr 90 / Ct 35 / span 55 / sweep 45 / t 4.0 |
| P11 | Motor retainer | adapt `MotorAdapter29.scad` patterns | 29 mm aft retainer |
| P12 | Rail buttons ×2 | reuse `RailGuide.scad` | `RailButton(OD=11, Flange_h=2, Slot_w=2.8)` — 1010 |
| P13 | G80T spacer | new | 86 mm spacer (210 mm MMT − 124 mm motor) so the G80T sits flush at the aft end |

New library file `R60Lib.scad` follows the existing `R65Lib.scad` / `R75Lib.scad` convention.

---

## 4. Recovery

**Dual deploy, no drogue**, both events electronic, one chute, one break.

| t | Alt | Event | Mechanism |
|---|---|---|---|
| 0 | — | Launch | 1010 rail, 1.5 m, exit 19.8 m/s |
| 11.0 s | 667 m | Apogee separation | Vega servo 1 rotates the bayonet ring; spring pushes sections apart. **Backup:** G80T ejection charge, delay set to ~11 s, cams the same ring open. |
| — | 667→150 m | Tumble descent | Sections held ~50 mm apart by a servo-latched tether; chute stays packed. ~23 m/s, 25 s, drift ~124 m |
| — | 150 m | Main release | Vega servo 2 releases the tether; sections separate fully, 24 in main is drawn out |
| — | 150→0 m | Descent | 6.9 m/s, 22 s, drift ~109 m |

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

### 4.1 Cam-ramped bayonet

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
| **G80T-14A** (owned) | 798 g | 9.9 | 19.8 m/s | 142 m/s | **0.42** | 667 m | 11.0 s |
| **H182R-14A** (29 mm DMS) | 877 g | 21.2 | 28.7 m/s | 243 m/s | **0.71** | 1113 m | 12.9 s |
| H135W-14A (29 mm DMS) | 870 g | 15.8 | 20.0 m/s | 221 m/s | 0.65 | 1067 m | 12.9 s |

Motor data from thrustcurve.org: G80T = 136.6 Ns / 77.6 N / 1.7 s / 128 g / 63 g prop /
29 × 124 mm. 29 mm H DMS = 29 × 203 mm, ~207 g, 115 g prop.

**The fin can (215 mm) and MMT (210 mm) are sized for the 203 mm H motor, not the G80T.**
This is the whole point of the H-ready choice: the G80T flies now on a 79 mm spacer, and the
H drops in later with no new parts.

### 5.1 Mass budget (G80T configuration, PETG at 1.27 g/cm³)

| Item | Mass | Station |
|---|---|---|
| Motor G80T-14A | 128.0 g | 507 mm |
| Fin can tube | 80.2 g | 462 mm |
| Parachute + cord + hardware | 70.0 g | 283 mm |
| Camera assembly (Seeker) | 60.0 g | 47 mm |
| CATS Vega + sled | 60.0 g | 159 mm |
| Bayonet + 2 servos | 58.0 g | 232 mm |
| E-bay tube | 48.5 g | 159 mm |
| Chute bay tube | 48.5 g | 289 mm |
| Battery + wiring | 45.0 g | 159 mm |
| MMT | 38.3 g | 462 mm |
| Nosecone shell | 37.0 g | 42 mm |
| Fins ×3 (62 % infill) | 32.5 g | 512 mm |
| Retainer + rail buttons | 26.0 g | 539 mm |
| E-bay bulkheads | 24.0 g | 159 mm |
| Neck + bolts | 22.0 g | 106 mm |
| Centering rings ×3 | 19.8 g | 462 mm |
| **Total** | **797.7 g** | CG 302.8 mm |

---

## 6. Stability

Barrowman, 3 fins, Cr 90 / Ct 35 / span 55 / sweep 45 mm.

- CN(nose) = 2.00 at 43.8 mm; CN(fins) = 5.78 at 469.8 mm
- **CP = 387.8 mm** from the nose tip

| Motor | CG loaded | Margin | CG burnout | Margin burnout |
|---|---|---|---|---|
| G80T-14A | 302.8 mm | **1.42 cal** | 285.2 mm | 1.71 cal |
| H182R-14A | 311.8 mm | **1.27 cal** | 288.3 mm | 1.66 cal |
| H135W-14A | 310.6 mm | **1.29 cal** | 287.9 mm | 1.67 cal |

All configurations sit in the 1.0–2.0 cal band, and margin *increases* through the burn.
The H — the heaviest and most aft-loaded case — is the sizing case at 1.27 cal.

**Fin flutter:** AR 0.88, λ 0.389, t/c 0.064, G ≈ 0.5 GPa for printed PETG →
**Vf ≈ 850 m/s**, 3.5× the H182R's 243 m/s. The deliberately low aspect ratio is what buys
this margin; do not make the fins thinner or longer-span without recomputing.

---

## 7. Materials and print

- **PETG throughout.** Not PLA (softens near the motor), and **no carbon-filled filament
  anywhere from the neck to the chute bay** — the Vega's 2.4 GHz telemetry and GNSS antenna
  are inside the airframe and CF is conductive.
- Airframe wall **1.6 mm**; 0.4 mm nozzle, 0.2 mm layers, 4 perimeters.
- All tubes print vertically; the longest part (fin can, 215 mm) fits the Bambu P1S 256 mm Z.
- Fins print flat, 62 % infill, oriented so layer lines run spanwise.

## 8. Launch

**1010 rail only.** Two rail buttons via `RailButton(OD=11, Flange_h=2, Slot_w=2.8)` from
`RailGuide.scad`, whose verified 8020-1010 profile matches the user's 6.2 mm slot.
**The 3 mm launch rod is not usable** — at 798 g and this length a 3 mm rod would whip badly
and rail exit would be unstable.

---

## 9. Assumptions and open items

| ID | Item | Impact if wrong | Resolve by |
|---|---|---|---|
| A1 | Camera bolt pattern is Ø37.96 BC / 52.2°, −52.2°, 180°, M3 | Neck won't bolt on | Measure the physical carrier before printing P1 |
| A2 | Nosecone ↔ camera clocking | Camera faces the wrong way about the roll axis | Neck is axisymmetric; trial fit |
| A3 | Camera assembly mass = 60 g ±20 g | CG shifts ≤4 mm; margin stays >1.2 cal | Weigh it |
| A4 | Camera battery lives in the e-bay, harness through the neck | E-bay volume | Confirm camera power requirement |
| A5 | G80T-14A delay is adjustable 14 s → ~11 s with the AeroTech DMS delay tool | Late deployment, ~3 s past apogee | Verify the tool's actual increments |
| A6 | Cd₀ = 0.52 | ±0.07 changes apogee ±80 m, Mach ±0.02 | Compare against Vega's logged altitude on flight 1 |
| A7 | Printed-PETG shear modulus 0.5 GPa for flutter | Vf scales as √G; 4× margin absorbs a lot | — |

## 10. Verification before first flight

1. Trial-fit the neck to the physical camera carrier and to the nosecone — **before** printing anything downstream.
2. **(§10.2)** Bench-test the bayonet on a pull rig: measure the actual cam release force.
   Accept 80–130 N. Below 80 N it risks opening in flight; above 150 N the motor-eject backup
   loses authority. Adjust the ramp angle from 20° until it lands in band.
3. Bench-test the full Vega sequence on the ground: arm → apogee servo → tether servo.
4. Swing test or measured CG/CP check with the real, loaded rocket.
5. Confirm rail exit on a 1.5 m rail before committing to a shorter one.
6. First flight on the G80T-14A, single objective: recover the airframe and read the Vega log.
   Compare logged apogee to the 667 m prediction and correct Cd₀ before flying the H.
