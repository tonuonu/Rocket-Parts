# Peregrine L3 — Test Flights on L2 Motors

**Project:** Peregrine L3 Certification Rocket  
**Author:** Tõnu Samuel  
**Date:** 2026-10-08  
**Status:** PRELIMINARY — 1-DOF estimates and a calculated mass; requires an
OpenRocket model and a weighed airframe  
**Related:** [L3-Design.md](L3-Design.md)

---

## 1. Plan

Build the Peregrine L3 airframe first as a **test airframe** and fly it on
L2-class (J/K) motors with electronic dual deploy. Then build a **new**
certification rocket from the same design, improved by what the test flights
taught, for the M-motor L3 flight.

Why:

- Validates the 3D-printed fin can, composite fins and redundant recovery
  electronics at low energy before the M flight.
- Fits the home field (Långtora, Enköping — SMRK): **≤ 10 kg** liftoff mass,
  **≤ 1340 m** apogee, **500 m** landing radius.
- The flights count toward the Tripoli L2→L3 flight-log requirement.

The L3 flight itself does not fit this field. Its apogee is estimated at
1.5–3 km, and the calculated liftoff mass is ~9.9 kg before nose ballast
(§3.2), which is 10.1–10.3 kg with the 200–400 g of ballast it needs.

## 2. Tripoli Rules That Shape the Plan

Source: [tripoli.org/level3](https://tripoli.org/level3) (checked 2026-10-08).

| Rule (Tripoli text) | Effect on plan |
|---|---|
| "A new rocket must be built for a candidate's first L3 certification attempt." | The test airframe cannot be the cert rocket; the cert rocket is a new build of the same design. *Our reading:* the rule stops an already-flown rocket being used for the cert flight, and does not forbid reusing the design. Confirm with the TAPs. |
| 3 successful flights on L2 motors; the L2 cert flight counts as one | L2 cert flight (2026-02-22, J350, dual deploy via CATS Vega) = flight 1. **Two more needed.** |
| At least 2 of those "successfully flown and recovered using Electronic Deployment" | The L2 cert flight was electronic = 1. The test flights must be recovered by the altimeters. A deployment by motor ejection would not count (§5.4). |
| Design package approved by both TAPs before construction begins | **Get both TAPs to agree to the two-airframe plan before building the test airframe.** |
| TRA Flight Log (Level 2 to Level 3) submitted with the design document | The formal design package goes in after the test flights, with the log. |
| Redundant, fully independent electronics for every recovery event | Fly the test flights with the full L3 recovery setup. |
| No sub-scale flight requirement | `L3-Design.md` §2 lists one; that line is wrong. |

Tripoli Unified Safety Code ([tripoli.org/safetycode](https://www.tripoli.org/safetycode)):
liftoff thrust-to-weight **≥ 5:1** typical (RSO may approve down to 3:1);
landing velocity **≤ 11 m/s (35 ft/s)**. The code gives no numeric rail-exit
speed. Used here: rail exit ≥ 5 × wind speed, so **15 m/s** (the floor) suits
~3 m/s wind and **24 m/s** suits ~5 m/s wind.

## 3. Method

Two scripts (Python 3, standard library only):

```sh
tools/l3_mass.py                                     # dry mass from CAD (needs OpenSCAD)
tools/l3_motor_survey.py                             # calibration + motor survey + rail table
tools/l3_motor_survey.py survey --dry 5.4 --spread 0.1 --rail 2.4   # weighed mass, club rail
tools/l3_motor_survey.py --refresh                   # re-download ThrustCurve data
```

Motor data is cached in `~/.cache/rocket-parts/thrustcurve.json`.

### 3.1 Flight model

- **1-DOF vertical model:** thrust-curve interpolation, mass decreasing with
  delivered impulse, ISA atmosphere, constant Cd with mild rise above Mach 0.8,
  no wind, no rail friction.
- **Rail exit** is taken when the aft rail button leaves the rail. The button
  is assumed 0.2 m above the aft end, so a 1.8 m rail gives 1.6 m of travel.
- **Motors:** all AeroTech and Cesaroni J/K/L motors (reloads and single-use)
  in 54 mm and 75 mm with regular availability, avg thrust ≥ 300 N, and thrust
  curves on [ThrustCurve.org](https://www.thrustcurve.org): 107 motors.
- **Calibration** against OpenRocket on the L2 rocket, with identical inputs
  (sim "Långtora Airfield 21 Feb 2026" in `PeregrineL2.ork`: 99 mm, 3.451 kg,
  J350W-OLD, 1.2 m rail):

  | | Model (Cd 0.50) | OpenRocket | Flight (CATS Vega) |
  |---|---|---|---|
  | Apogee | 1006 m | 1002 m | 986 m (~938 m temperature-corrected) |
  | Rail exit | 21.2 m/s | 21.6 m/s | — |
  | Max velocity | 173.6 m/s | 173.2 m/s | 172.6 m/s |

  The model reproduces OpenRocket within 2 %, and the real flight agrees with
  OpenRocket. The flight log gives 3.1 kg liftoff and the OpenRocket sim
  3.45 kg; this does not change the picture.
- **Drag** of the L3 airframe is not known yet. Cases use Cd 0.40 (low drag,
  for the ceiling check), 0.50 (as calibrated) and 0.60.

### 3.2 Mass

`tools/l3_mass.py` weighs the printed parts from their CAD (OpenSCAD volume ×
density × effective fill). It computes the tubes, layups and nose cone from
their dimensions and estimates the bought items. Airframe without motor and
without nose ballast:

| Group | Low | Nominal | High | Basis |
|---|---|---|---|---|
| Fin can (PC) + GF overwrap | 0.96 | 1.08 | 1.20 kg | CAD 879 cm³ |
| 4 fins (PPS core + CF skins + rods) | 0.66 | 0.77 | 0.88 kg | CAD 127 cm³ per core |
| Body tubes (Blue Tube, 850 mm) | 0.68 | 0.80 | 0.86 kg | 1.1–1.4 g/cm³ |
| E-bay (printed) + electronics | 0.43 | 0.54 | 0.69 kg | L2 e-bay CAD, scaled |
| Nose cone (printed) | 0.50 | 0.59 | 0.67 kg | ogive 1339 cm², 2.2 mm wall |
| Recovery (chutes, cords, protectors, links) | 0.79 | 1.05 | 1.31 kg | 2 × 9 m cords |
| Eyebolts, misc hardware | 0.30 | 0.45 | 0.60 kg | |
| **Dry mass** | **4.3** | **5.3** | **6.2 kg** | |

The fin can is calculated with the 9 mm slots of PeregrineFinCan75 v0.7.0;
the 8 mm slots on `main` add ~20 g. With motor, liftoff is ~6.4–7.2 kg on
the J/K test motors and ~9.9 kg on the M1297W. Weigh the parts as they are
built and re-run with `--dry`.

The survey flies three cases:

| Case | Dry mass | Cd | Used for |
|---|---|---|---|
| Light | 4.35 kg | 0.40 | Highest apogee (ceiling check), max Mach |
| Nominal | 5.30 kg | 0.50 | Likely apogee, liftoff mass, peak acceleration |
| Heavy | 6.25 kg | 0.60 | Slowest rail exit, 10 kg check |

54 mm motors add 0.3 kg for an adapter.

**Classes:**
- *Robust:* light-case apogee ≤ 1160 m (≥ 13 % under the ceiling) and
  heavy-case rail exit ≥ 24 m/s.
- *Out:* light-case apogee > 1340 m, rail exit < 15 m/s, avg
  thrust-to-weight < 5, or liftoff > 10 kg.
- *Marginal:* everything in between.

## 4. Results

All results are on a 1.8 m rail. Peak acceleration uses the higher of the
sampled curve peak and ThrustCurve's listed peak thrust.

### 4.1 Candidates

| Motor | Hardware | Class | Likely apogee | Highest apogee | Rail exit (heavy) | Peak thrust | Peak accel | Max Mach |
|---|---|---|---|---|---|---|---|---|
| AeroTech J1299N | RMS-54/852, plugged | marginal: rail exit 23.9 | 575 m | 730 m | 23.9 m/s | 1468 N | 22 g | 0.44 |
| AeroTech J1265T | single-use, 6–14 s delay | marginal: rail exit 23.0 | 756 m | 941 m | 23.0 m/s | 1745 N | 26 g | 0.53 |
| AeroTech J1799N | RMS-54/1280, plugged | **robust** | 760 m | 943 m | 27.3 m/s | 2966 N | **44 g** | 0.55 |
| AeroTech K1499N | **RMS-75/1280, plugged, no adapter** | **robust** | 935 m | 1144 m | 24.6 m/s | 1720 N | 24 g | 0.62 |
| AeroTech K2050ST | RMS-54/1706, plugged | marginal: apogee | 1016 m | 1235 m | 27.7 m/s | 2168 N | 31 g | 0.68 |
| CTI 1408K2045-17A | Pro54-4G, 7–17 s delay | marginal: apogee | 1029 m | 1249 m | 28.2 m/s | 2231 N | **32 g** | 0.70 |

J1299N and J1265T miss the robust rail-exit line only in the heavy case
(6.25 kg). At the nominal mass they exit at 25.6 and 24.6 m/s; weighing the airframe
decides. Every candidate stays below Mach 0.7, so fin flutter is not a
concern on these flights. All are far under the 10 kg limit.

### 4.2 Other marginal motors

| Motor | Why |
|---|---|
| AeroTech J800T, CTI 1266J760-19A | Rail exit ~17.5 m/s |
| AeroTech J615ST-20A | Rail exit 16.3 m/s |
| AeroTech J540R, K750ST | Rail exit 15.1–15.4 m/s |
| AeroTech K695R | Highest apogee 1310 m, rail exit 16.0 m/s |

### 4.3 Ruled out

- **All L motors.** Highest apogee 2100–3800 m.
- **Most K motors.** They exceed the ceiling (e.g. K1100T 1391 m, K550W,
  K1103X, K805G, K780R, CTI 1633K940).
- **Slow-burning J/K.** Rail exit below 15 m/s (e.g. J415W, J460T, J550ST,
  K456DM, K400C, K513FJ, CTI 1412K530). The J350W flown on L2 is 38 mm and not
  in the survey; it is far too weak for this airframe.

### 4.4 Rail length

Rail exit in the heavy case (m/s), aft button 0.2 m above the aft end:

| Motor | 1.8 m | 2.4 m | 3.0 m |
|---|---|---|---|
| J1299N | 23.9 | 28.1 | 31.8 |
| J1265T | 23.0 | 27.1 | 30.4 |
| J1799N | 27.3 | 32.3 | 37.0 |
| K1499N | 24.6 | 28.9 | 33.0 |
| K2050ST | 27.7 | 32.8 | 37.4 |
| 1408K2045 | 28.2 | 33.3 | 37.4 |
| J800T | 17.5 | 20.5 | 23.1 |
| K695R | 16.0 | 19.1 | 21.7 |

The rocket is 1.79 m long, the same as a 1.8 m rail. A 2.4 m rail adds
~4 m/s and puts every candidate comfortably above 24 m/s. It is the cheapest
safety gain; check what SMRK has, and use a stiff 1515 rail.

## 5. Open Risks

1. **Overstability and weathercocking.** Without the 4.6 kg M motor and the
   nose ballast, CG moves well forward. A heavy, overstable rocket with modest
   rail-exit speed turns into the wind. This is the most likely failure mode.
   It cannot be computed without the full OpenRocket model, which is the
   **first ORK task**. The safety code also requires documented CG and CP for
   the configuration flown.
2. **Acceleration and loads.** CATS Vega's accelerometer is configured for
   ±32 g (`lsm6dso32.hpp`). J1799N (44 g) exceeds it and CTI K2045 (32 g)
   reaches it. Barometric deployment still works, but the acceleration log
   clips. J1799N, K2050ST and K2045 also exceed the M1297W's 2049 N peak
   thrust. Altimeter sleds, battery retention and bulkheads must take the
   higher acceleration. The gentlest choices are J1299N, K1499N and J1265T
   (22–26 g).
3. **No motor backup on plugged reloads.** Most candidates are plugged, so the
   altimeters are the only deployment. That is required anyway (redundant
   electronics) and keeps the flight counting as Electronic Deployment.
4. **Single-use and delay motors.** J1265T (single-use) and CTI K2045 have
   fixed delays. The coast to apogee is ~10–12 s. If a motor ejection fires
   before the altimeters, the flight was not deployed electronically and may
   not count. Plug the delay or choose the longest delay, and agree on this
   with the TAPs.
5. **Motor adapter.** All 54 mm options need a 75→54 mm adapter that carries
   thrust and retains the motor. Commercial adapters exist (e.g. AeroPack).
   Check retention with this fin can's retainer. K1499N is the only robust
   option without an adapter.
6. **Hardware cost.** The reloads need cases that are not owned yet:
   RMS-75/1280 for K1499N, or 54 mm cases plus the adapter. The RMS-75/5120
   planned for L3 cannot fly any of these.
7. **Availability.** AeroTech "N" (Warp-9) and "ST" propellants and CTI's
   fast-burning reloads are niche in Europe. Swedish supply is not verified.
8. **Landing radius.** The L2 flight took 89 s to descend from 986 m. For
   ~6 kg, with a 24 in drogue (~15–20 m/s) and a 60 in main at 150 m, expect
   ~65–90 s from ~1000 m. In 5 m/s wind that is 330–450 m of drift, and winds
   aloft are usually stronger. The L2 analysis already found main-only recovery
   from 1000 m exceeds 500 m above 4 m/s. Limit ~1000 m flights to ~4–5 m/s
   surface wind; the ~600 m flight has real margin.
9. **Recovery for a bigger airframe.**
   - Ejection charges sized for the 99 mm L2 do not fit the ~5 L BT137 bays.
     Size them and ground-test both bays.
   - Use shear pins on both separations so drag at burnout cannot pull the
     rocket apart.
10. **Model limits.** The model is vertical with no wind, constant Cd and no
    rail friction. The mass is calculated, not weighed. Weigh the airframe and
    re-run.

## 6. Suggested Progression

| Flight | Motor | Apogee | Purpose |
|---|---|---|---|
| Test 1 | J1299N | ~575 m | Gentle and low: first check of airframe, recovery, redundant electronics |
| Test 2 | K1499N (no adapter) | ~935 m | Near-ceiling flight, full recovery sequence at altitude |
| L3 cert | M1297W in **new** airframe | 1.5–3 km | At a field with a higher ceiling and mass limit |

Both test flights must be recovered by the altimeters, intact, to count:
land under the main.

## 7. Next Steps

- [ ] Get both TAPs to agree to the two-airframe plan, before building
- [ ] Ask SMRK for available rail lengths (1515)
- [ ] Check Swedish/EU availability of the §4.1 motors and cases
- [ ] Choose motor path: 75 mm (K1499N, no adapter) vs 54 mm (+ adapter)
- [ ] Build `PeregrineL3.ork`: stability margin with the test motors and M1297W
- [ ] Weigh parts as they are built; re-run both scripts
- [ ] Size and ground-test ejection charges for the BT137 bays
- [ ] Fix `L3-Design.md` §2: remove the sub-scale line
- [x] `L3-Design.md` §5: calculated mass budget (M flight exceeds 10 kg)
- [ ] After the test flights: formal design package with the TRA Flight Log
