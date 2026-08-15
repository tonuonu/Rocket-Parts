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
E20-P gives T/W 2.3 and **8.9 m/s off the owner's 1.83 m rail** — well under the ~15 m/s needed for
the fins to stabilise before rail exit. Apogee 66 m. No Ø60 mm airframe carrying the camera +
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
          │   NECK     │   5 mm   3× M3 axial into camera carrier, Ø37.96 BC (flange only --
          │            │          the 19mm skirt telescopes inside the e-bay tube below)
      99  ├────────────┤
          │   E-BAY    │ 177 mm   CATS Vega, battery, 1× servo, access door, 3× vent port
     276  ├────────────┤ ◄─────────  plain bonded joint (petal-deployment transplant, sec 4 --
          │ DEPLOYMENT │ 240 mm       no shear pins any more, nothing separable here)
          │    BAY     │          release stack (servo-driven lock ring), CS4323 spring,
          │            │          forward spring end -- fixed, never separates
     516  ╞════════════╡ ◄─────────  SEPARATION JOINT -- the petal cage itself (sec 4);
          │  FIN CAN   │ 228 mm   petal hub + petals bolt to the fin can and hold the two
          │ +petal cage│          sections together via printed lock nubs, not a shear load
     744  └────────────┘   Ø29 mm MMT (228 mm), 3 fins, retainer + fwd thrust ring
```

Tube/fin-can stack **744 mm** as diagrammed. Overall airframe length **750 mm**:
the motor retainer bolts to the OUTSIDE of the fin can's aft
face, not flush within its printed length, adding a further 6 mm past the 744 mm
stack above — see `tools/rocket60_model.py`'s own OVERALL_LEN. OD **60.0 mm**,
**L/D 12.5**.

The e-bay is 177 mm, not the 130 mm first specified. Two upright MG90S servos plus the
100 mm Vega need 129 mm of interior and 130 mm of tube only yields 112 mm once the
bulkheads are subtracted. Lengthening was chosen over thinner packaging because it also
improves stability: margin rises from 1.48 to 1.55 cal loaded, and Mach falls only 0.01.
Grew a further 5 mm (160->165, 3rd review, should-fix 9) so the arming-switch Z window
between the door aperture and the neck skirt is a genuine ~3 mm margin on both sides
instead of a 0.5 mm hair gap. Grew another 12 mm (165->177, 4th review, critical 3): that
3rd-review fix measured the switch's clearance from the door APERTURE's own edge, not from
`R60_Door()`'s actual built footprint (a COVER 6 mm larger than the aperture on every
side) -- correctly counting that overlap needed 12 mm more to restore the same ~3 mm
window. Total airframe length also now counts the neck's own 5 mm flange explicitly
(previously omitted -- see §5's mass-budget note).

That switch-window derivation is now HISTORY, not the current design (5th review, finding
1): the arming switch has moved off the tube wall entirely, onto the access door itself
(`R60_Door()`), which sidesteps the window it kept re-breaking (it inverted twice --
3rd review's own fix, then again at the current `R60_EBay_L`) rather than growing the
e-bay a third time to patch it. `R60_EBay_L` stays 177 mm -- it is not shrunk back down --
but is no longer switch-derived; its remaining justification is fitting the Vega 100 +
upright MG90S 29 + slack.

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

Numbered by `Render_Part` (Rocket60.scad's own dispatch, `-D Render_Part=N`) —
the SAME numbering `tools/verify_rocket60.py`, `tools/r60_assembly.scad`,
`R60-PrintSettings.md` and every other tool in this tree already use.
Rewritten (6th review) after five review rounds left this table's own
P-numbers, tube lengths, fin span and P4's mechanism all stale relative to
the as-built design; see git history for the retired P1-P14 scheme.

**Petal-deployment transplant** (replaces the spring/ball-lock carrier +
shear-pin + servo-tether design across parts 3, 5, 8, 13; adds parts
15-23) — see §4 below and `tasks/lessons.md` for why: nine review rounds
hardened a mechanism that, underneath the hardening, could not work (its
own ball-lock plunger/lock ring were never modelled; the pin-load spec
used a per-pin shear figure as a pair total; a spring strong enough to
shear real pins overloaded a tether latch bench-specced at 13N). Replaced
by transplanting a flown design's own libraries (Rocket6551.scad, 2.6"
single-deploy, one CS4323 spring) instead of re-deriving a mechanism from
scratch a second time.

| # | Part | Print | Notes |
|---|---|---|---|
| 0 | Test ring | new | Print-fit gauge, not a flight part — flange OD, camera bolt circle/clocking, coupler spigot, all on one 10 mm print. Print this first. |
| 1 | Neck | new | **Butt joint, no spigot** — the camera fills the bore and is flush at the base, so nothing can enter it. Flat Ø59.98 top face bearing on the nosecone base annulus *and* the camera's bottom face; located by 3× **Ø3.4 clearance holes** on Ø37.96 BC, no counterbore (M3×10 SHCS into the camera's heat-set inserts, heads proud on the aft face where nothing bears); open-centre spider for the harness; skirt down into the e-bay tube. |
| 2 | E-bay tube | new | Ø60 OD, 1.6 mm wall, 177 mm, door cutout 36 × 85 mm (§3's own history above); 3× Ø4.5mm static vent ports at 120°, task 6. |
| 3 | Deployment bay tube | new | Ø60 OD, 1.6 mm wall, **240 mm, plain tube, no cuts**. Fixed (bonds to part 5's skirt; never separates). Houses the release stack (15-20), the CS4323 spring, and the forward spring end (23) with an OPEN aft end the petal cage (8/13) telescopes through at deployment. Grew from 180mm — was sized for the abandoned mechanism; 240mm houses the release stack + spring + petal cage, measured this session (226.5mm + margin). |
| 4 | E-bay fwd bulkhead | new | Neck interface + harness pass-through. Carries 2× ruthex inserts (a local boss, since its 6 mm disc alone is shallower than the insert) for the Vega sled's forward foot (part 6). |
| 5 | E-bay aft bulkhead | new | Shock-cord anchor (unchanged, permanent) + skirt (plain glue joint now, no pins) + 3× ruthex inserts for the release activator (part 15), bolt circle derived from `CRBBm_BottomBoltCircle_d()`. **One servo now, not two** — it lives inside part 15's own printed body, not this bulkhead; the second servo (the old design's tumble-release servo) is deleted outright, single deploy has no tumble phase. |
| 6 | Vega sled | new | M3 standoffs on the L-pattern A (−13.5, −25), B (−13.5, +35), C (+13.5, +35) — 60 × 27 mm spacing per manual §4.3.3. Patch antenna faces radially outward, nothing between it and the wall. Bridges the full e-bay span and bolts to parts 4/5 at each end, 2× M3 into ruthex inserts per end — both radial position and clocking about the tube axis are fixed by those 4 holes, not by resting against anything (6th review, finding 1; retired a rail/zip-tie scheme that failed three review rounds running). |
| 7 | Access door | new (hand-built) | 4× M2.5, curved panel, plus a panel-mount arming switch cut into the door itself (moved off the tube wall, 5th review) operable with the rocket vertical on the rail. |
| 8 | Petal hub | `use<>` `R65Lib.scad`'s `R65_PetalHub()` | Spigots (glued, skirt/-z face) into the fin can's own forward opening — the section that separates and pulls away — same joint the old chute-tube spigot made. **Not bolted to part 13** — `PD_PetalHubBoltPattern` is this part's own axial bolt circle, unused in this design (11th review, retracted from the row below too); the real petal joint is part 24's hinges, below. |
| 24 | Petal spring holder ×3 | `use<>` `PetalDeploymentLib.scad`'s `PD_PetalSpringHolder()` | THE hinge (11th review — missing entirely from the first transplant attempt, `tasks/lessons.md`). Bolts to each petal (2× #4-40 through the petal's own only holes); its axle rides in part 8's pivot socket, preloaded open by a 5/16in coil spring seated in part 8's own bosses. |
| 25 | Spring centering ring mount | `use<>` `CableReleaseBBMicro.scad`'s `CRBBm_CenteringRingMount()`, parameterised for the CS4323 | Seats the release spring (11th review, fix 4) — bolts to part 16. Without it the spring's preload rested on part 15's own 1.2mm spokes/servo braces, pad to apogee. |
| 9 | Fin can | adapt `FinCan2Lib.scad` | 228 mm, Ø29 MMT (228 mm), 3 fin slots, 3 centering rings. **UNCHANGED by this task.** |
| 10 | Fins ×3 | new | Cr 90 / Ct 35 / span 63 / sweep 45 / t 4.0. **UNCHANGED by this task.** |
| 11 | Motor retainer | adapt `MotorAdapter29.scad` patterns | 29 mm aft retainer — resists AFT motion only; see part 14. |
| 12 | Motor spacer | new | 98 mm for the G80T, 19 mm for the H182R (228 mm MMT − 6 mm part-14 ring − motor length); ~6 mm for the H135W. |
| 13 | Petals | `use<>` `PetalDeploymentLib.scad`'s `PD_Petals()` | Hinges to part 8 via part 24 (not bolted to part 8 directly — `PD_Petals()` has no axial holes). `Len`=140mm (12th review, grown from 120 for real packing margin — §4.1), `Lock_Span_a`=30 (donor's own flown value — 11th review, was omitted, defaulting to a full-circumference lock ridge; 13th review added a mesh-level guard, `verify_rocket60.py`'s own `petal_lock_arcs()`, after this same constant regressed once already), `AntiClimber_h`=4 (13th review — the donor's own print convention, not the ShowRocket()-embedded display call this used to follow), `HasLocks=true` for the small printed catch nubs the spring overcomes (the charge does **not** — §4.3, retracted). **This IS the separable joint** — nothing else in this design shears. |
| 14 | Forward thrust ring | new | Reacts the motor's FORWARD thrust reaction (part 11 alone only resists aft motion); Ø26.8 mm lip, flush with the fin can's own forward tip. |
| 15 | Release activator | `use<>` `CableReleaseBBMicro.scad`'s `CRBBm_Activator()` | Servo mount + lock-ring driver; bolts to part 5's aft face. **BBMicro, not the flown BBMini** — see §4 below for the mesh-measured reason. |
| 16-20 | Release stack | `use<>` `CableReleaseBBMicro.scad` | Top retainer, lock ring, outer bearing retainer, trigger post, magnet bracket — the rotating-lock-ring/ball-detent/magnetic-over-centre release the abandoned design left "deliberately incomplete". |
| 21-22 | Release rod + pin | `use<>` `CableReleaseBBMicro.scad` | Extension rod + locking pin, running through the CS4323 spring's own ID to part 17's lock ring. |
| 23 | Forward spring end | `use<>` `R65Lib.scad`'s `R65_FwdSpringEnd()` | The moving piston: captive on the locking pin until released, then driven by the spring into the petals. Bolts inside part 8's petal cage. |

Rail buttons (2×, 1010, `RailGuide.scad`'s `RailButton(OD=11, Flange_h=2,
Slot_w=2.8)`) and the nosecone itself are external hardware/reused stock, not
`Render_Part` numbers in `Rocket60.scad`. Axial placement (task 7,
previously unspecified): azimuth 180°, aft button at Z=630mm (fin can,
forward of the fins, at the mid centring ring), forward button at
Z=230mm (e-bay tube) — keeps the G80T's own liftoff CG (394mm) between
the two.

New library file `R60Lib.scad` follows the existing `R65Lib.scad` / `R75Lib.scad` convention.

---

## 4. Recovery

**Single deploy, no drogue, no tumble phase.** The invented spring/ball-lock-carrier +
shear-pin + servo-tether design described in this section through nine review rounds is
**deleted**. It never had a working release (its own ball-lock plunger/lock ring were
explicitly "deliberately incomplete"), its pin-load spec was self-contradictory (a nylon
2-56 pin's own *per-pin* shear figure, ~110-155N, restated as "2 pins ≈130N combined" — a
pair total using a single-pin number), and a spring strong enough to shear real pins put
several hundred N of snatch into a tether latch bench-specced at 13N. **Replaced by
transplanting a flown design's own libraries** — `PetalDeploymentLib.scad` +
`CableReleaseBBMicro.scad` + `R65Lib.scad`'s `R65_FwdSpringEnd()`, the same mechanism
class Rocket6551.scad (2.6", single-deploy, one CS4323 spring, first built and flown) uses
— rather than re-deriving a mechanism from scratch a second time. See `tasks/lessons.md`
for the pattern this instance of.

**Petals never separate the airframe against a shear load at all.** The spring ejects the
chute *through* petals a servo unlocks — the entire "how much force must a joint take"
problem the deleted design spent nine rounds hardening around does not exist here, because
it was never created in the first place.

| t | Alt | Event | Mechanism |
|---|---|---|---|
| 0 | — | Launch | Estes Pro Series II rail, 1.83 m, 1010-compatible, exit 20.1 m/s |
| 10.7 s | 588 m | Apogee, single deploy | Servo 1 (in part 15's activator) rotates the release catch's lock ring, freeing the forward spring end (part 23); the CS4323 spring drives it into the petals (part 13), popping their printed lock nubs and pushing the fin-can section clear. Main is drawn out immediately — no tumble phase. **No mechanical backup exists** — see §4.3: the G80T's ejection charge cannot open the petal locks (11th review, retracts the earlier "acts on the same lock nubs directly" claim). |
| — | 588→0 m | Descent under the 24in main | ~8.0 m/s (stated calc, §4.1 — not yet a `tools/rocket60_model.py` simulation), ~74 s |

### 4.1 The joint, the chute, and the descent estimate

**The joint IS the petal cage — there is no second, independent shear feature.** The petal
hub (part 8) spigots (glued, not bolted) into the fin can's own forward opening — the same
joint the chute tube used to make, now carried by the hub instead (11th review: the hub was
printed upside down in the first transplant attempt, spigot on the wrong face, and is fixed
now — see `tasks/lessons.md`). The petals (part 13) do **not** bolt to the hub either —
`PD_Petals()` has no axial holes at all. The real joint is 3x printed hinges
(`PD_PetalSpringHolder()`, part 24): each bolts to one petal through its only holes (radial,
2x #4-40) and carries an axle that rides in the hub's own pivot socket, preloaded open by a
5/16in coil spring seated in the hub's integral bosses. Closed, the petals' own printed lock
nubs (`PD_PetalLocks`) hold the hinge shut against that preload — a light catch, not a
structural joint sized against flight loads. The spring (captive until servo 1 releases it)
is what actually separates the sections, by ramming `R65_FwdSpringEnd()` into the petals
hard enough to pop those nubs, driving the hinges open. The shock cord (unchanged,
permanent) keeps the aft section attached through the whole descent, exactly as before this
transplant — route: e-bay aft bulkhead's own tie-off → through the forward spring end's own
rope holes (part 23, `nRopes`=6, `R65_FwdSpringEnd()`'s own Ø4 holes just outside the spring
OD) → through the petal hub's own Ø5 centre hole (part 8, `PD_PetalHub()`'s own
`CenterHole_d`) → tied off on the fin can's forward centring ring's own 2x Ø5 axial holes
(`R60_FinCan()`'s own shock-cord anchor). Separate from the cord path: the forward spring
end's own centre bore is a #10-24 threaded stud (`Thread1024_d`, `R65_FwdSpringEnd()`'s own
`ExternalThread()` boss) — that is how the piston threads onto the locking pin/extension
rod (parts 21/22), not a cord attachment.

**Chute packing (12th review — retracts the 11th review's own "~13% shortfall" figure,
which was itself never measured).** The 24in main is packed **inside the petal cage
itself** — `PD_Petals`' own tube between the hub and the forward spring end. Bore ID at
`Wall_t`=1.6mm is `R60_Coupler_OD`-2×1.6=53.2mm, area 22.24 cm²/cm — at the (then) 120mm
length, 267 cm³ gross bore volume, first corrected from an over-published "+7% margin" to
an ESTIMATED "~13% shortfall" (~24mm of assumed fixed obstruction: "~18mm" for the hub
floor + 3x spring-holder bosses, "6mm" for the piston's own base disk, both eyeballed off
the source, not rendered). Mesh-probed this session instead of estimated
(`tools/verify_rocket60_assembly.py`'s own `check_packing()`, Pairs 42/43,
`r60_assembly.scad`): intersect the SAME 53.2mm bore against the real assembled geometry —
hub + 3x `R60_PSH_Placed()` occupy **9.3 cm³** of it (not a full-diameter ~18mm slab; 3
discrete hinge bosses, mostly open between them), `R65_FwdSpringEnd()` occupies **6.9 cm³**
— **16.3 cm³ total, not the ~53 cm³ the ~24mm estimate implied.** At the OLD 120mm:
net 266.7-16.3=**250.4 cm³ against the stated ~250 cm³ requirement** (ripstop nylon +
Nomex protector + shroud lines, ~50g at ~0.20 g/cm³ packing density) — **tangent, zero
real margin**, not a 13% shortfall, but not a margin either.

"Same as Rocket6551's own flown 120mm" does not rescue this: that comparison used the same
LENGTH on a DIFFERENT bore. Rocket6551's own cage ID is 61.6mm (its own `Coupler_OD` is
larger than this design's 56.4mm), so its 120mm holds 357 cm³ gross, not 267 — the two
designs are not interchangeable at the same length just because the length matches.

**Decision (12th review, owner's ruling) — length, not canopy or fabric.** `R60_Petal_Len`
120→**140mm**: Rocket6551.scad's own stated ceiling ("140 is max for a single 4323 spring")
and its own preferred/flown value. Net at 140: 311.2-16.3=**294.9 cm³, ~18% real margin**.
A tangent fit on the one system whose job is getting the camera back is not a margin, and
the closure fix below needs the tube's own length to grow regardless of which packing
option was picked — so there was nothing to buy by shrinking the canopy or the fabric pack
instead. Do not re-litigate this without a real reason: the smaller-canopy and thinner-
fabric options once documented here are superseded, not still live.

**Consequence: the deployment bay tube no longer fits the print envelope as one piece,
and is split (12th review).** `R60_Chute_L`'s own required length for a correct (not
tangent, not bottomed-out) hub-to-fin-can spigot engagement is **275mm** (see §4.1's
closure discussion below and `R60Lib.scad`'s own `R60_Chute_L` comment for the full
derivation) — this exceeds both this project's own "fits 250mm Z" convention and the Bambu
P1S's own 256mm build volume in every orientation, as one piece, at EITHER 120mm or 140mm
`R60_Petal_Len` (the minimum at 120 is already ~255mm). Split into
`R60_ChuteTubeFwd()`/`R60_ChuteTubeAft()` (parts 3/26, `Rocket60.scad`), joined by a glued
in-wall spigot/socket at `R60_ChuteSplit_Z`=137mm — NOT a bore-reducing internal sleeve:
the release stack (parts 15-23) and the retracted petal cage already fill this tube's
56.8mm bore through most of its own length (`verify_rocket60.py`'s own max-radius-vs-bore
checks on parts 15-23 prove it), so any joint that narrows the CLEAR bore anywhere along it
collides with something real. Splitting the 1.6mm WALL itself instead (the tube's own inner
half as a spigot, the receiving piece's own outer half as a socket) keeps both the bore and
the OD unbroken through the joint, so the split can land anywhere. Sized against the
post-separation ejection charge's own pressure pulse (the governing case, ~8x the CS4323's
own estimated max force) at a conservative, stated 15psi assumption (the charge itself is
undocumented, same gap class as spec A11's spring rate) — ~200mm² of glue area required, a
6mm real engagement around the ~57.6mm mean glue diameter gives ~1086mm², >5x margin. Same
gluing-flange technique as `NoseCone.scad`'s own field-proven `GluingflangeHeight`
(the owner's own printed 3-slice Peregrine nosecone), applied within the wall instead of
across the whole shell since this tube, unlike a nosecone, is a plain constant-diameter
cylinder.

**Descent estimate (stated calculation, not a model output — `tools/rocket60_model.py` has
no descent/drift simulator).** Terminal velocity under the 24in main, V=√(2mg/(ρ·Cd·A)):
burnout mass 877g, Cd≈0.75 (typical round/hemispherical chute), A=0.292 m² (24in dia.) →
**V≈8.0 m/s**. From 584m apogee: **~73 s to ground**, drift ≈365m at 5 m/s wind (5×73s).
CATS Vega transmits GNSS position at 10 Hz on 2.4 GHz FHSS (flight-tested to 10 km), so
recovery is "walk to the last fix", not a search, regardless of drift distance.

### 4.2 Release catch: CableReleaseBBMicro, not the flown CableReleaseBBMini

Rocket6551.scad — the design this transplant sources the petal cage and spring end from —
itself flies `CableReleaseBBMini.scad` for the release catch. This design uses
`CableReleaseBBMicro.scad` instead, on **mesh-measured evidence, not flight history**:

`CRBBm_Activator(OD=56.4)` — the servo-carrying top plate, and the one part in either
family whose own geometry does **not** derive from its OD argument (its own source file
carries an explicit warning on this exact module: *"Designed and works for Loc65 tube, may
not scale"*) — was rendered and measured at this airframe's own coupler OD this session:

| | Max radius | vs. 28.4mm bore |
|---|---|---|
| CableReleaseBBMini's Activator | 31.8 mm | **past the bore** |
| CableReleaseBBMicro's Activator | 28.2 mm | lands exactly on `R60_Coupler_OD`/2 — this repo's own 0.4mm-clearance convention |

Every other shared part (lock ring, top retainer, outer bearing retainer) clears either
family's bore with 10+mm to spare — the Activator is the one part that actually decides
this, and the flown family's does not fit. BBMicro is the newer, less-flown family (first
print 2025-10-16 vs. BBMini's 2025-09-21) — a part that cannot pass through the airframe
wall as printed is not a live option regardless. Hardware note: BBMicro's own header BOM
comment is stale (5/16in balls, a 6705 bearing); the **live code** (cut 2025-11-10) uses
6mm balls, a 6703-2RS bearing, MR63 lock bearings — build from the code, not that comment.

### 4.3 The ejection charge: no mechanical backup exists (11th review, retraction)

**Retracted:** earlier drafts of this spec claimed the G80T's ejection charge acts on the
petals' own lock nubs directly, "genuinely independent of servo/lock-ring state" — a real
mechanical backup path. That claim does not survive contact with `PD_PetalLocks()`'s own
geometry. The nubs are a **positive lock**, not a friction catch: **2.25mm of engagement**
between the nub and its socket, and the Ø56.4 petals sit with only **0.2mm of radial
flare** available inside the Ø56.8 body bore they close against — there is no room for the
petals to flex out far enough to clear a 2.25mm-deep lock under internal pressure. Gas
pressure pushing outward on the petals loads the lock nubs in shear/bearing, the same
direction the primary (spring) release also has to overcome, but the spring's job is to
drive `R65_FwdSpringEnd()` far enough to physically flex the petals past that engagement —
raw internal pressure, with nothing to react against but the petals' own 0.2mm of flare,
cannot do the same thing. **The barometric/timer servo path is a single point of failure
for recovery: the servo itself, its wiring, the Vega servo rail, and the lock ring it turns
all have no backup if any one of them fails.**

The deployment bay (part 3) is a plain, open, unsealed tube — there is no diaphragm
anywhere between the motor's own forward face and the petal cage — but that only means the
charge's gas reaches the lock nubs at all; it does not mean the gas can open them.

The charge **cannot be disabled** (it is the motor's own ejection charge, not a separate,
switchable device) and fires on its own timer, independent of the recovery system.
**Undrilled, ~5.0 seconds after apogee** (13th review, correcting a "1-3 second" figure
that matches only a DRILLED delay: burnout 1.7s + the stock 14s delay grain = 15.7s from
liftoff, against 10.7s to apogee — the ~2-3s range the old wording described only holds if
the delay is drilled to ~11s, spec §9 item A5) — venting straight up the
open fin can/deployment bay toward the just-deployed main. This is a real hazard to the
canopy and lines regardless of the retracted backup claim above: **specify a Nomex chute
protector between the charge and the packed main, and a sleeved (Nomex or similar) shock
cord run**, not because the charge helps deployment, but because it fires close behind it
either way.

> **A11 (carried forward) — spring force is undocumented.** No spring rate, Newton figure,
> or vendor appears in any of the CS4323's source files. Bench-test before flight.
>
> **A13 (new, replaces the retracted A12) — no mechanical backup exists for the primary
> release.** If the servo, its wiring, the Vega servo rail, or the lock ring fails, the
> petals do not open — the ejection charge cannot do it for them (see above). This is the
> single largest open risk in the recovery system: a from-scratch redundancy analysis (a
> second servo, a CO2/pyro backup release, or an accepted single-string design with a
> documented failure rate) is out of this task's scope but should not be deferred silently.

---

## 5. Performance

Simulated by direct integration (1 ms steps), exponential atmosphere, Cd₀ = 0.52 with a
transonic rise above M 0.75, A = 28.27 cm².

| Motor | Liftoff | T/W | v@1m rail | Vmax | Mach | Apogee | t(apogee) |
|---|---|---|---|---|---|---|---|
| **G80T-14A** (owned) | 941 g | 8.4 | 14.7 m/s | 122 m/s | **0.36** | 583 m | 10.7 s |
| **H182R-14A** (29 mm DMS) | 1007 g | 18.4 | 21.8 m/s | 196 m/s | **0.58** | 952 m | 12.5 s |
| H135W-14A (29 mm DMS) | 1010 g | 11.7 | 16.7 m/s | 183 m/s | **0.54** | 996 m | 13.2 s |

Rail-exit speed off the owner's actual Estes Pro Series II rail (1.83 m,
not the 1.5 m this table used to assume) is reported separately in §6.1
-- **G80T-14A 20.0 m/s**, comfortably above the 15 m/s minimum.

(Figures from `tools/rocket60_model.py`'s own output, re-run after the
petal-deployment transplant (§4) -- see §6 below for the matching
stability table. Liftoff mass moved from 874/941/944g to
933/1000/1003g at the transplant itself (the transplant removes the
spring carrier, tether latch, shear pins and one MG90S servo (-82g
combined) and adds the petal cage, release hardware and the grown
deployment bay tube (+~113g net) -- see `tools/rocket60_model.py`'s
STL_VOL comment for the full per-part breakdown), then to 907/973/976g
(10th review: the aft bulkhead's own mount fix also hollowed its
15mm skirt, -~26g -- `R60_EBayAftBulkhead()`'s own module comment), then
to 924/991/994g (11th review: the hinge subsystem, part 24 x3 + its
springs/bolts, and the spring centering ring mount, part 25, add
~17g net -- fixes 2/4, `tools/rocket60_model.py`'s STL_VOL comment).
Apogee/Mach move with the mass and CP changes; margins are updated in
§6.)

Motor data, all from thrustcurve.org:

| Motor | Impulse | Avg thrust | Burn | Total | Propellant | Size | Delays |
|---|---|---|---|---|---|---|---|
| G80T | 136.6 Ns | 77.6 N | 1.7 s | 128 g | 63 g | 29 × 124 mm | 6–14 |
| H182R | 218.0 Ns | 182.0 N | 1.2 s | 207 g | 115 g | 29 × 203 mm | 6–14 adjustable |
| H135W | 225.8 Ns | 115.9 N | 2.0 s | 212 g | 82 g | 29 × 216 mm | 6–14 adjustable |

**Mach 0.60 is the realistic ceiling for this airframe**, and only on an H. Ø60 mm and
~800 g are both forced — by the nosecone base and by the payload — and together they cap
what any 29 mm motor can do. If a higher Mach number ever becomes the priority it needs a
different, smaller-diameter rocket, not a change to this one.

**The fin can (228 mm) and MMT (228 mm) are sized for the longest H, not the G80T.**
(4th review, should-fix 14: this used to say "MMT 223 mm" and "99 mm spacer" -- both
superseded when `R60_MMT_L` was fixed to derive from `R60_FinCan_L` instead of a second,
independently-typed 223 that let the motor slam 5 mm aft on ejection; see R60Lib.scad's own
`R60_MMT_L` comment.) That is the whole point of the H-ready choice: the G80T flies now on
a 98 mm spacer, and either H drops in later with no new printed parts.

### 5.1 Mass budget (G80T configuration, PETG at 1.27 g/cm³)

**Superseded by `tools/rocket60_model.py`**, which sources every printed
part's mass from its measured mesh volume (`STL Files/Rocket60/README.md`)
rather than the estimates below, and includes hardware this table
predates (the petal cage/release hardware, upright servo, fin span
grown to 63mm — see §6). Kept here for history; do not use it as the
current mass source.

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
| **Total** | **886.7 g** | CG 350.7 mm |

---

## 6. Stability

**Re-run after the petal-deployment transplant (§4).** Fins, nose and body
diameter are unchanged (parts 9/10 are protected — this task does not
touch them); the transplant's mass/length changes (deployment bay tube
180→240→275mm, the last step the 12th review's own tube-split/packing-
margin ruling; spring carrier/tether latch/pins deleted, petal cage +
release hardware added) move both CP (the fin can — and everything on
it — sits ~179mm further aft than the pre-2026-08-15 60mm-airframe
baseline had it, 144mm through the 11th review plus this round's own
further +35mm growth) and CG.

Barrowman on the EXPOSED fin panel (root 77.9 / tip 35 / span 49.1 / sweep
35.1 mm, measured at the body OD, r=30mm — see `tools/rocket60_model.py`'s
`exposed_geom()`), 3 fins:

- CN(nose) = 2.00 at 43.8 mm; CN(fins) = 4.73 at ~721 mm
- **CP = 519.8 mm** from the nose tip (shifted +24.6mm this round from
  495.2, +66.8mm cumulative from 453.0: CP moves with `S_finLE`, which
  tracks `TOTAL` — the deployment bay's own growth pushes the whole
  fin-can/motor stack, and therefore CP, aft by CN(fins)/CN of that
  growth each time)

| Motor | Liftoff g | CG loaded | Margin | CG burnout | Margin burnout |
|---|---|---|---|---|---|
| G80T-14A | 941 g | 418.2 mm | **1.69 cal** | 396.7 mm | 2.05 cal |
| H182R-14A | 1007 g | 431.0 mm | **1.48 cal** | 399.3 mm | 2.01 cal |
| H135W-14A | 1010 g | 430.6 mm | **1.49 cal** | 409.4 mm | 1.84 cal |

**The G80T-14A margin IMPROVED, 1.46→1.69 cal** (10th/11th/12th review:
this figure has moved several times since, from an intermediate 1.68
cal when the aft bulkhead's own mass fix shifted CG, to 1.56, to 1.53
when the 11th review's hinge subsystem (part 24 x3 + springs/bolts) and
CS4323 seat (part 25) added their own mass, to 1.69 when the 12th
review's owner ruling grew R60_Chute_L to 275 (the tube split, printed
as two pieces) and R60_Petal_Len to 140 (real packing margin) — see §4.1
for that decision's own record), despite the added liftoff mass over
every prior figure — CP moved aft by more than CG did at every step,
because the deployment bay's own growth is entirely FORWARD of the fin
can, pushing the fins (which dominate CN) further from the nose without
adding mass there. H182R clears 1.0 cal at 1.48 cal, H135W at 1.49 cal
— both with real room. **If this had come out below 1.0 cal the answer
would have been to stop and report it, not to force a fix** — it did
not; no design change was needed to reach this figure. Margin
*increases* through the burn on every configuration (burnout G80T
margin is 2.05 cal).

### 6.1 Stability gate: 1.0 cal minimum (unchanged), rail exit re-verified on the real rail

The stability gate in `tools/rocket60_model.py` remains **1.0 cal** — the
physical minimum for the accepted 1.0-2.0 cal high-power-rocketry band,
not a re-litigated target (see git history for the 5th-round ruling that
retired an earlier 1.5 cal comfort target; that reasoning is unchanged
and not repeated here). G80T (1.69 cal), H182R (1.48 cal) and H135W
(1.49 cal) all clear it with real room.

**Rail exit, on the owner's actual rail.** `tools/rocket60_model.py`'s
rail-exit sim used to hardcode a 1.5m rail no one owns; fixed to
`RAIL_LEN`=1.83m (Estes Pro Series II, 1010-compatible, the rail actually
used). At the current 940g liftoff mass, the G80T leaves the
rail at **20.0 m/s**, comfortably above the 15 m/s minimum (H182R
29.8 m/s, H135W 23.0 m/s). Roughly a quarter of liftoff mass is still
unweighed hardware ESTIMATES, not measured mesh volumes — see
`R60-PrintSettings.md`'s own pre-flight weigh-in step.

**Fin flutter — formula fixed, not just re-run.** `flutter_Vf()` computed
t/c on the exposed panel's MEAN chord ((root+tip)/2); the NAR/TIR-33 form
it implements (itself sourced from NACA TN 4197) defines t/c on the
exposed ROOT chord alone. Vf scales as (t/c)^1.5, and mean chord (56.4mm)
is smaller than root chord (77.9mm), so t/c-on-mean reads LARGER than
t/c-on-root — inflating the published Vf by (77.9/56.4)^1.5 ≈ 1.62×. The
previously-published **955 m/s was wrong; the corrected figure is 589 m/s.**

Vf=589 m/s still clears the G80T (the sizing case) with real margin, but
not the old blanket "3× the single fastest Vmax across all motors" gate,
which was calibrated against the inflated number — H182R (the fastest
motor overall) sits at 3.0×, below a 3× floor. Re-scoped to a per-motor
1.5× floor (same physical-floor-vs-engineering-margin split as the 1.0
cal stability gate above; the true physical floor is 1.0×, Vf>Vmax):

- **4.8× the G80T's ~122 m/s Vmax**
- **3.0× the H182R's ~196 m/s Vmax**
- **3.2× the H135W's ~183 m/s Vmax**

All three clear the 1.5× floor with real room. Do not make the fins
thinner, or grow the span further, without recomputing both stability
AND flutter — they move in opposite directions as span grows.

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
| Servo channels: regulated 5 V, **3 A**, endpoints configurable | manual §4.3.4 | One MG90S servo (petal-deployment transplant §4 — single deploy needs one release event, not two) runs directly off the Vega. No separate BEC. |
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

Rocket 60 uses (**single deploy, petal-deployment transplant §4 — one
event, one servo**; `EV_MAIN_DEPLOYMENT`/servo 2 are deleted, single
deploy has no separate main-release event):

| Event | Action | Purpose |
|---|---|---|
| `EV_APOGEE` | `ACT_SERVO_ONE` → unlock position | Servo 1 (in part 15's activator) rotates the release catch's lock ring, freeing the spring; petals open, main is drawn out immediately |

This event is bound to servo 1's PWM channel in the configurator as part of normal setup.

### 7.3 Settings

| Setting | Value | Why |
|---|---|---|
| `liftoff_acc_threshold` | **40** | m/s². Manual wants ~20 below expected max; the G80T gives ~124 m/s² peak, the H182R ~207 |
| `servo1_init_pos` | set on the bench | 0–1000; the **locked** position |
| `enable_telemetry` | **true** | ⚠️ **firmware default is `false`.** Recovery depends on GNSS downlink — if this is left at default there is no tracking |
| `tele_link_phrase` | matched on the ground station | manual §4.3.5 step 17 |
| `enable_testing_mode` | **false** | manual §4.3.5 step 7 |
| `battery_type` | `LI_ION` or LiPo to match the pack | affects voltage warnings |

### 7.4 Timers — the second TRIGGER, not a second path (11th review, retraction)

**Retracted:** this section used to describe barometric detection, a timer, and the G80T's
own ejection charge as "three independent paths" tolerating any single failure. They are
not independent. §4.3 (retracted there in full) establishes that the ejection charge cannot
open the petal locks at all — it is not a path. What remain, barometric and timer, are two
different **triggers into the same single mechanism**: both fire `EV_APOGEE`/servo 1, which
rotates the same lock ring, which releases the same spring, through the same servo, its
same wiring, and the same Vega servo rail. A timer backs up a missed **barometric reading**
(a sensor fault or a flight profile the algorithm reads wrong); it backs up nothing about
the servo, wiring, rail, or lock ring themselves — if any of those fails, both triggers fail
the same way. The manual (§4.3.5 steps 13–15) offers the timer for exactly that narrower
purpose:

| Trigger | Apogee separation (single event) |
|---|---|
| 1. Barometric | `EV_APOGEE` → servo 1 |
| 2. Timer (backup for a missed/late barometric read only) | Timer 1: liftoff → **12.5 s** (apogee 10.7 s + margin) |

Both drive the SAME servo 1 → lock ring → ball-chain release — see A13 (§4.3) for the
single-point-of-failure this design still carries with no mechanical backup.

Timer value is for the G80T. **It must be recomputed for an H** (apogee 12.5 s for the
H182R, 13.2 s for the H135W) — see §9 A5.

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
| ~~A8~~ | ~~The aft bulkhead's servo pocket floor was sized against steady servo torque, not the ejection-charge backup's impulsive reaction~~ | — | **Superseded, petal-deployment transplant (§4):** the servo now lives inside part 15's own Activator print, not a pocket in the aft bulkhead; the ejection charge acts on the petal cage's own lock nubs, not the bulkhead at all. See A12. |
| ~~A10~~ | ~~The repo's spring/cable-release libraries parameterise down to a Ø60 airframe~~ | — | **Resolved by this transplant:** `CableReleaseBBMicro.scad`'s Activator does, mesh-measured (§4.2); `CableReleaseBBMini.scad`'s does not. |
| A9 | Servo-pocket dividing wall is 1.2 mm (3 perimeters at a 0.4 mm nozzle) | Below ~0.8 mm the slicer drops to thin-wall mode and the two pockets can fuse | **No longer applies** — one servo now, no dividing wall between two pockets (petal-deployment transplant §4) |
| A11 | CS4323 spring force is undocumented (no spring rate, Newton figure, or vendor in any source file) | Spring may not reliably pop the petals' own lock nubs | Bench-test the physical spring (§11.2) |
| A12 | Ejection-charge backup force is undocumented, and the deployment bay is an open (unsealed) volume, not a sealed pressure vessel (§4.3) | Backup may not build enough pressure fast enough before venting through the joint's own clearances | Ground-test the charge with the bay in the loop (§11.2) |

## 11. Verification before first flight

1. Trial-fit the neck to the physical camera carrier and to the nosecone — **before** printing anything downstream.
2. Bench-test the release mechanism (A11/A12): with the petal cage assembled and locked,
   measure the CS4323 spring's own compressed force and confirm it reliably pops the
   petals' printed lock nubs open. Separately, ground-test the G80T's ejection charge with
   the deployment bay/petal cage in the loop (an unsealed volume, §4.3 — not assumed
   airtight) and confirm it too pops the nubs within the motor's own delay window.
3. Cycle the release catch (servo 1 → lock ring → locking pin release) 20 times on the
   bench, confirm it neither jams nor creeps open under the spring's own standing load
   between cycles.
4. Bench-test the full Vega sequence on the ground: arm → apogee servo.
5. Swing test or measured CG/CP check with the real, loaded rocket.
6. Confirm rail exit on the actual 1.83 m rail before flying (20.1 m/s predicted, §6.1).
7. Confirm the arming switch can actually be reached and thrown with the rocket vertical
   on the rail — the Vega calibrates once at boot and must not be powered up before then.
8. Confirm `enable_telemetry` is `true` and the ground station shows GNSS fix **before**
   the rocket leaves your hands. The firmware default is `false`.
9. First flight on the G80T-14A, single objective: recover the airframe and read the Vega log.
   Compare logged apogee to the 588 m prediction and correct Cd₀ before flying the H.
