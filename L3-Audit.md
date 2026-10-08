# Peregrine L3 — Design Audit

**Date:** 2026-10-08
**Scope:** L3-Design.md, L3-TestFlights.md, PeregrineFinCan75.scad v0.8.0,
PeregrineFin75.scad, PeregrineL3.scad (assembly view)
**Status:** Findings only. Nothing in here has been changed in the design yet.
§4 is a layout **proposal** waiting for approval.

The audit started from a cutaway of `PeregrineL3.scad`: the electronics bay
is an open tube with no bulkheads, so an ejection charge would pressurise the
whole rocket. Everything forward of the fin can turned out to be undesigned.
The fin can itself is sound.

---

## 1. Summary

| # | Severity | Finding | Applies to |
|---|---|---|---|
| B1 | Blocker | No sealed e-bay — no bulkheads, no static ports | Both |
| B2 | Blocker | Main chute does not fit above the M motor | Both |
| B3 | Blocker | Redundant electronics not designed (one CATS Vega = one system) | Both |
| B4 | Blocker | No motor retainer; thrust bears on a 1.7 mm PC lip | Both |
| M1 | Major | Ribbon band and cord holes narrower than 1" tubular nylon | Both |
| M2 | Major | With the K1499N the motor ends below the ribbon band | Both |
| M3 | Major | No shear pins or bay vent holes | BP / Both |
| M4 | Major | Short couplers: fin can 0.25 cal, nose shoulder 0.6 cal | Both |
| M5 | Major | Aft rail button at 45° lands on a vertical tube in the fin can | Both |
| M6 | Major | Open 9 × 25 mm pocket ahead of each fin leading edge | Both |
| m1 | Minor | ~10 inconsistencies in L3-Design.md (§7) | — |
| T | TAP | Design package incomplete (§8) | — |

"Both" means the finding applies to black powder and to servo release alike.

**Verified OK:** the fin can is a closed pressure boundary. The four vertical
tubes end blind at the coupler ring, the slot gaps ahead of the fins are
walled off from the ribbon band, and the cord holes open only into the closed
band. The one leak path is the 0.3 mm radial gap between the motor case and
the MMT bore (76.0 mm bore, 75.4 mm case) — small; a wrap of tape on the
case closes it.

---

## 2. Deployment Method: Black Powder or Servo

Both must stay possible. Black powder (BP) is the normal HPR method and is
"not impossible" for the candidate. The older design document
(`~/MyLevel1Peregrine/docs/certification/l3-design-document.md`) rules BP out
for a builder in Estonia and proposes a servo C-latch release instead.

**BP legality:** the test flights are in Sweden (Långtora, SMRK) and the M
flight is at another site. Confirm with the RSO / club at **each** site who
may supply, possess and load BP, before choosing the variant for that flight.

### 2.1 Common to both variants

- Sealed e-bay with two real bulkheads (B1)
- Static ports in the e-bay only (B1)
- Chute bays sized for the chutes, not for the charges (B2)
- Two independent altimeters, each with its own battery and switch (B3)
- Motor retainer and thrust ring (B4)
- Rated recovery hardware: U-bolts or eyebolts tied through by threaded rod,
  quick links, swivel, chute protectors

### 2.2 Black powder only

- Charge wells on the outside of each bulkhead — 2 per event (primary +
  backup), each fired by a different altimeter
- 3–4 nylon 2-56 shear pins per separating joint (M3)
- Ground test of every charge, in every motor configuration (charge size
  changes with the motor — §5)

### 2.3 Servo only

- One release device per altimeter per event, either one alone able to
  separate the joint. The older doc's C-latch does this: two latches 180°
  apart, each with its own servo, spring preload pushes the sections apart
  when either latch opens.
- Mount the latch servos on the **e-bay side** of each joint so no wire
  crosses a separating joint.
- The second altimeter must have a servo output, or drive a servo through a
  pyro-triggered driver. CATS Vega has 2 servo + 2 pyro channels; most
  altimeters have pyro only.
- No shear pins; the latches carry drag separation and the spring preload.
- Ground test: latches release under full spring load, and the springs push
  the packed chute clear.

### 2.4 Question for the TAPs

Tripoli wants redundant, fully independent electronics **and energetics** for
every recovery event. Two BP charges from two altimeters clearly meet this.
Two servos on two latches at the same joint is our reading of "independent" —
ask the TAPs early whether they accept it, and how they want the spring
ejection proven.

A hybrid (BP at one joint, servo at the other) is also possible and lets the
BP variant run where BP is available.

---

## 3. Blockers

### B1 — No sealed electronics bay

`PeregrineL3.scad` draws the e-bay as a plain 200 mm tube with no bulkheads.
With BP, the apogee charge pulse reaches the barometers and can make them
read a sudden altitude drop — both altimeters may then fire the main at
apogee, a failed certification flight. With servos there is no pulse, but the
bay still needs to be closed so the barometers see clean static pressure and
loose chute parts cannot reach the electronics.

Needed:

- Two bulkheads, **6 mm G10 or plywood**, not 3 mm printed plastic. At
  15 psi the pressure on a BT137 bulkhead (ID 136.8 mm, 14 698 mm²) is
  **1.52 kN**; recovery opening shock adds to this.
- U-bolt or eyebolt per bulkhead, the two bulkheads tied through by threaded
  rods so the recovery load runs through steel, not the coupler.
- Wire passthroughs potted with epoxy or putty.
- Static ports in the e-bay band only, 3–4 equally spaced, sized to the
  altimeter makers' guidance.
- Reuse candidates in this repo: `EB_Electronics_Bay55` (BT137, two
  altimeters) and `EB_Electronics_BayUniversal` in `ElectronicsBayLib.scad`;
  `PeregrineEBay.scad` (L2 heritage, `PeregrineBulkhead`, BP cups);
  `ChargeHolder.scad`.

### B2 — Main chute has no room above the M motor

Current order (aft → fore): fin can, main tube (500 mm, main chute), e-bay,
drogue tube (350 mm, drogue), nose.

The M1297W (75/5120, 602.5 mm) ends at Z = 594.5 mm; the main tube ends at
790.9 mm. That leaves 196 mm, minus the e-bay coupler shoulder:

| E-bay shoulder | Free length | Volume |
|---|---|---|
| 105 mm (0.75 cal) | 91 mm | 1.3 L |
| 140 mm (1 cal) | 56 mm | 0.8 L |

The main bay needs about **2.5–3 L** clear. This assumes a 60" ripstop main
(L3-Design §9.3), 9 m of 1" tubular nylon, a protector and ~30 % packing
margin — check against the packed size of the chute actually bought. See §4
for the proposed fix.

### B3 — Redundancy not designed

One CATS Vega has 2 pyro channels, 2 servo channels, one battery and one
switch. That is **one** system. Tripoli requires a second, independent one.

- Second altimeter, preferably a different make (different firmware, no
  common-mode bug)
- Own battery each. CATS Vega needs 7–25 V, so 2S LiPo minimum.
- Own switch each, reachable with the rocket on the rail (switch positions
  must clear the rail at 45°)
- Wiring diagram showing primary/backup per event (TAP package, §8)
- L3-Design §9.2 still names MCV3 / StratoLogger — update once chosen

### B4 — No motor retainer

The aft closure bears on a 1.7 mm PC lip at the aft end of the fin can. Peak
thrust is 2049 N on the M1297W. The fin can has a 3¼"/3⅜" 8 TPI male thread
for a retainer cup, but no retainer is designed.

Needed: an aluminium thrust ring that carries the aft closure load into the
fin can, plus a commercial 75 mm retainer (or a printed cup proven by test).
The 54 mm adapter for J/K test motors needs its own retention.

---

## 4. Layout Proposal (needs approval)

Swap the bays and lengthen both tubes:

| Section | Now | Proposed | Change |
|---|---|---|---|
| Main tube (above fin can) | 500 mm, **main** chute | 550 mm, **drogue** | +50 mm |
| E-bay | 200 mm, open tube | 200 mm band + 140 mm (1 cal) shoulder each side, two bulkheads | sealed |
| Forward tube | 350 mm, **drogue** | 450 mm, **main** | +100 mm |
| Overall length | 1791 mm | ~1941 mm | +150 mm |

With the M motor this gives:

| Bay | Free length | Free volume | Needs |
|---|---|---|---|
| Aft (drogue) | 106 mm | 1.6 L | ~1.2 L (24" drogue + 9 m cord) |
| Forward (main) | 225 mm | 3.3 L | 2.5–3 L |

Drogue-aft / main-forward is the usual dual-deploy arrangement: at apogee the
booster separates from the e-bay; the main comes out of the forward tube at
main altitude.

Effects to check before building:

- Mass: +150 mm of BT137 ≈ +100 g, plus the e-bay coupler shoulders. The
  10 kg limit is only for the home field, where the J/K test motors keep the
  rocket well below it.
- Stability: added length and mass forward help; re-run CP/CG for every
  motor in OpenRocket.
- L3-TestFlights.md: the calculated dry mass and the drag both change —
  re-run `tools/l3_mass.py` and `tools/l3_motor_survey.py`.

Other options considered:

- **Keep the order, lengthen the main tube ~150–200 mm.** Possible, but
  all the added length is aft, which costs stability (more nose ballast),
  and the 350 mm forward tube stays oversized for a drogue.
- **Main in the nose cone.** The 450 mm ogive has the volume, but it holds
  ballast and possibly the camera; not recommended.

---

## 5. Charge Sizing (BP variant)

    m [g] = ΔP · V / (R·T)        R·T ≈ 219 J/g for BP combustion gas
                                   (≈ 0.00052 g per psi·in³)

V is the free volume of the bay; taking the empty bay overestimates the
charge, which is the safe side for a first ground test. Target 10–15 psi,
well above the shear pin load (3 × 2-56 nylon at ~35 lbf each ≈ 0.5 kN ≈ 4.6 psi on BT137).

Example values for the **proposed** layout at 15 psi:

| Bay | Motor | Volume | Charge |
|---|---|---|---|
| Forward (main) | any | 3.3 L | 1.6 g |
| Aft (drogue) | M1297W | 1.6 L | 0.7 g |
| Aft (drogue) | K1499N | 5.9 L | 2.8 g |

The aft charge depends on the motor: the short K1499N leaves the MMT above
it and the whole main tube empty. A charge sized for the M will not separate
the rocket on a K; a charge sized for the K is four times what the M flight
needs. Every motor configuration needs its own ground test, and the flight
card must say which charge goes with which motor.

Earlier figures (1.1 g fore, 1.9 g aft M, 2.6 g aft K1499N) were for the
current layout and are superseded. Recompute once the layout is approved.

---

## 6. Major Findings

**M1 — Ribbon band and cord holes are narrow.** The shock cord wraps the MMT
in a 16 mm band under the forward centering ring and exits through 18 mm
holes. Flat 1" tubular nylon is 25 mm wide; it will fold. Pull-test a printed
section with the real cord to the expected opening load.

**M2 — K1499N leaves the MMT unbacked under the band.** The K1499N
(75/1280, 260 mm) ends at Z ≈ 252 mm; the ribbon band is at Z 270–286 mm.
The cord load squeezes an empty printed MMT there. Use a spacer to fill the
MMT above the short motor, or check the hoop strength.

**M3 — No shear pins or vent holes.** BP: 3–4 × 2-56 nylon pins per joint.
Both variants: one small vent hole (2–3 mm) per chute bay so trapped air
doesn't push the sections apart at altitude.

**M4 — Short couplers.** The fin can coupler is 35 mm (0.25 cal); the nose
shoulder 85 mm (0.6 cal). The fin can joint is glued, so 35 mm may be
acceptable — state that to the TAPs. The nose shoulder should be ≥ 1 cal.

**M5 — Aft rail button lands on a vertical tube.** The aft button
(Z = 200 mm, at 45° between two fins) falls on one of the four vertical
tubes in the fin can. Filling those tubes (3 % infill like the rest) would give the
screw something to bite and saves an estimated 100–150 g of tube walls.

**M6 — Open pocket ahead of the fins.** `FinSlot()` cuts the slot up to
`CR_Positions[3]` (Z = 285.9 mm), but the 240 mm fin tab ends at `Slot_End`
(Z = 260.9 mm). That leaves a 9 × 25 mm open pocket ahead of each fin
leading edge. It is sealed
from the band, so not a leak; fill it with epoxy at assembly or end the cut
at `Slot_End`.

---

## 7. Document Inconsistencies (L3-Design.md and sources)

- §2 lists a ≥ 50 % sub-scale flight as a Tripoli requirement — there is
  none (also §11 step 2 and §13).
- §9 subsections are numbered 8.x; §10 subsections 9.x.
- §9.2 names MCV3 / StratoLogger; the primary is CATS Vega.
- §9.2 says "own deployment charges" — servo variant needs different wording.
- §9.4 says "eye bolts through bulkheads"; the fin can uses a ribbon wrap.
- Stability: §2 target 1.5–2.0 cal, §6 estimate 0.9–1.4 cal, §6.2 "required
  1.5+". Pick one requirement and show it per motor.
- §4.4 heading has the fin at v0.1.0; §12 table v0.2.0.
- §4.2 order (main aft, drogue forward) — update if §4 is approved.
- `PeregrineFinCan75.scad` echoes "v0.7.0" (file is v0.8.0); comments still
  mention a retainer eyebolt and a forward MMT extension.
- §9.3 deploys the main at 300 m; L3-TestFlights.md §5 assumes 150 m to
  stay inside the 500 m landing radius at Långtora. Use one value per site.

---

## 8. TAP Package — Missing Items

Tripoli wants the design package approved by both TAPs **before**
construction. Missing:

- [ ] Dimensioned drawings of the whole rocket and each section
- [ ] Bill of materials
- [ ] Recovery wiring diagram (both altimeters, batteries, switches,
      charges / servos, per event)
- [ ] OpenRocket file with CP/CG and stability for the M and every test
      motor
- [ ] Charge calculations and ground-test plan (BP), or latch/spring test
      plan (servo)
- [ ] Retainer and thrust ring drawing
- [ ] Checklists: assembly, arming on the pad, recovery
- [ ] TRA flight log (L2 → L3)

---

## 9. Next Steps

1. Approve or change the layout in §4.
2. Choose the second altimeter.
3. Rebuild the forward half of `PeregrineL3.scad` from library parts with
   real bulkheads, so the cutaway shows the sealed bay — both variants.
4. Build the OpenRocket model; re-run `tools/l3_mass.py` and
   `tools/l3_motor_survey.py` on the new layout.
5. Fix the L3-Design.md inconsistencies (§7).
6. Design the retainer / thrust ring and the 54 mm adapter retention.
