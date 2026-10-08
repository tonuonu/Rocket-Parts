# Peregrine L3 — Test Flights on L2 Motors

**Project:** Peregrine L3 Certification Rocket  
**Author:** Tõnu Samuel  
**Date:** 2026-10-08  
**Status:** PRELIMINARY — 1-DOF estimates, requires OpenRocket validation  
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
  **≤ 1340 m** apogee, **500 m** landing radius. The L3 flight itself
  (M1297W, ~9.8 kg, est. 1.5–3 km) does not fit this field and needs another site.
- The flights count toward the Tripoli L2→L3 flight-log requirement.

## 2. Tripoli Rules That Shape the Plan

Source: [tripoli.org/level3](https://tripoli.org/level3) (checked 2026-10-08).

| Rule | Effect on plan |
|---|---|
| "A new rocket must be built for a candidate's first L3 certification attempt." | Test airframe cannot be the cert rocket. Cert rocket is a new build of the same design. The rule targets re-flying an existing (e.g. L2) rocket on an M. |
| 3 successful flights on L2 motors; L2 cert flight counts as one | L2 cert flight (2026-02-22, J350, dual deploy via CATS Vega) = flight 1. **Two more needed.** |
| At least 2 of those with Electronic Deployment (altimeter fires the chute ejection) | L2 cert flight was electronic = 1. Both test flights use electronic dual deploy, so this is covered. |
| Design approved by both TAPs before construction | Brief TAPs on the design first. Re-submit if test flights change the design. |
| TRA Flight Log (Level 2 to Level 3) submitted with the design document | Log the test flights there. |
| Redundant, fully independent electronics for every recovery event | Fly the test flights with the full L3 recovery setup. |
| No sub-scale flight requirement | `L3-Design.md` §2 lists one — that line is wrong. |

Tripoli Unified Safety Code ([tripoli.org/safetycode](https://www.tripoli.org/safetycode)):
liftoff thrust-to-weight **≥ 5:1** typical (RSO may approve down to 3:1);
landing velocity **≤ 11 m/s (35 ft/s)**. No numeric rail-exit velocity in the
code — used here: **15 m/s floor, 20+ comfortable, 25+ good** for a heavy,
likely overstable rocket.

## 3. Method

Script: [`tools/l3_motor_survey.py`](tools/l3_motor_survey.py) (Python 3,
standard library only). Motor data is cached in
`~/.cache/rocket-parts/thrustcurve.json`.

```sh
tools/l3_motor_survey.py                          # calibration + survey + rail table
tools/l3_motor_survey.py survey --dry 5.4 --rail 2.4   # re-run with weighed mass / club rail
tools/l3_motor_survey.py --refresh                # re-download ThrustCurve data
```

- **1-DOF vertical flight model:** thrust-curve interpolation, mass
  decreasing with delivered impulse, ISA atmosphere, constant Cd with mild
  rise above Mach 0.8, no wind, no rail friction, vertical rail.
- **Motors:** all AeroTech and Cesaroni J/K/L reloads in 54 mm and 75 mm,
  regular availability, avg thrust ≥ 300 N, with thrust curves on
  [ThrustCurve.org](https://www.thrustcurve.org) — 107 motors.
- **Calibration** against the L2 flight (Peregrine 99 mm, 3.1 kg, J350W,
  1.2 m rail):

  | | Model (Cd 0.55) | OpenRocket | Flight (CATS Vega) |
  |---|---|---|---|
  | Apogee | 991 m | 1002 m | 986 m |
  | Rail exit | 22.8 m/s | 21.6 m/s | — |
  | Max velocity | 192 m/s | 173 m/s | 172.6 m/s |

  Apogee matches at Cd ≈ 0.55. Rail exit reads ~5 % high, so rail-exit
  speeds below are multiplied by 0.95. Max velocity reads ~10 % high, so
  velocities below are conservative.

- **Test airframe:** BT137 (140.1 mm), dry mass **4.5–5.5 kg** (design
  budget 5.05–5.25 kg minus the 200–400 g nose ballast that only the M motor
  needs; real printed + overwrapped mass is unverified). 54 mm motors add
  0.3 kg for an adapter. Rail 1.8 m.
- **Cases bracketed:**
  - *High:* 4.5 kg dry, Cd 0.45 — upper bound on apogee (ceiling check).
  - *Mid:* 5.0 kg dry, Cd 0.55 — likely apogee.
  - *Heavy:* 5.5 kg dry, Cd 0.60 — slowest rail exit.
- **Classes:**
  - *Robust:* high-case apogee ≤ 1160 m (≥ 13 % under the ceiling) and
    heavy-case rail exit ≥ 24 m/s.
  - *Out:* high-case apogee > 1340 m, or rail exit < 15 m/s, or avg
    thrust-to-weight < 5.
  - *Marginal:* everything in between.

## 4. Results

1.8 m rail, default masses. Liftoff mass and peak thrust-to-weight are for
the mid case.

### 4.1 Robust choices

| Motor | Case | Liftoff | Likely apogee | Highest apogee | Rail exit (heavy) | Peak thrust | Peak T/W | Max Mach |
|---|---|---|---|---|---|---|---|---|
| AeroTech J1299N | RMS-54/852 + adapter | 6.1 kg | 584 m | 681 m | 25.5 m/s | 1452 N | 24 | 0.43 |
| AeroTech J1265T | 54 mm (case n/a) + adapter | 6.4 kg | 757 m | 877 m | 24.4 m/s | 1568 N | 25 | 0.51 |
| AeroTech J1799N | RMS-54/1280 + adapter | 6.4 kg | 759 m | 879 m | 28.9 m/s | 2114 N | 34 | 0.53 |
| AeroTech K1499N | **RMS-75/1280, no adapter** | 6.7 kg | 924 m | 1066 m | 25.9 m/s | 1720 N | 26 | 0.60 |
| AeroTech K2050ST | RMS-54/1706 + adapter | 6.6 kg | 996 m | 1148 m | 29.3 m/s | 2168 N | 34 | 0.66 |

**CTI 1408K2045-17A** (Pro54-4G + adapter) misses the robust line by 1 m
(highest apogee 1161 m) and otherwise behaves like K2050ST (likely 1007 m,
rail exit 29.8 m/s).

All stay below Mach 0.7, so fin flutter is not a concern on these flights.
All are far under the 10 kg limit.

### 4.2 Marginal

| Motor | Why |
|---|---|
| CTI 1408K2045-17A | Highest apogee 1161 m (see above) |
| AeroTech K1100T | Highest apogee 1308 m, rail exit 23.1 m/s |
| AeroTech K550W | Highest apogee 1339 m, rail exit 16.0 m/s |
| AeroTech K695R | Highest apogee 1220 m, rail exit 17.2 m/s |
| AeroTech HP-K535W | Highest apogee 1194 m, rail exit 15.9 m/s |
| AeroTech J800T, CTI 1266J760-19A | Rail exit ~18.7 m/s |
| AeroTech J615ST-20A | Rail exit 17.5 m/s |
| AeroTech J540R, K750ST, J550ST-14 | Rail exit 15–16 m/s |

### 4.3 Ruled out

- **All L motors** — highest apogee 1970–3540 m.
- **Most remaining K motors** — apogee over the ceiling (e.g. K1103X, K805G,
  K780R, CTI 1633K940).
- **Slow-burning J/K** — rail exit at or below 15 m/s (e.g. J415W, J460T, K456DM,
  K400C, K513FJ, CTI 1412K530). The J350W flown on L2 is 38 mm and not in
  the survey; it is far too weak for this airframe.

### 4.4 Rail length

Rail exit, heavy case, corrected (m/s):

| Motor | 1.8 m | 2.4 m | 3.0 m |
|---|---|---|---|
| J1299N | 25.5 | 29.5 | 33.1 |
| J1265T | 24.4 | 28.3 | 31.6 |
| J1799N | 28.9 | 34.2 | 38.1 |
| K1499N | 25.9 | 30.1 | 33.9 |
| K2050ST | 29.3 | 34.1 | 38.4 |
| 1408K2045 | 29.8 | 34.6 | 38.9 |
| K1100T | 23.1 | 26.4 | 29.4 |
| J800T | 18.6 | 21.4 | 24.0 |
| K695R | 17.2 | 20.0 | 22.6 |
| HP-K535W | 15.9 | 18.5 | 20.7 |

The rocket is 1.74 m long, barely shorter than a 1.8 m rail. A longer rail is
the cheapest safety gain — check what SMRK has.

## 5. Open Risks

1. **Overstability / weathercocking.** Without the 4.6 kg M motor and nose
   ballast, CG moves well forward. A heavy, overstable rocket with modest
   rail-exit speed turns into the wind. This is the most likely failure mode
   and cannot be computed without the full OpenRocket model — **first ORK task**.
   Fast-burning motors (§4.1) are preferred for this reason.
2. **Loads above the L3 flight.** J1799N, K2050ST and 1408K2045 peak at
   2.1–2.2 kN — slightly above the M1297W's 2049 N — and at a peak
   thrust-to-weight of ~34 versus ~21 on the M flight. Altimeter sleds,
   battery retention and e-bay bulkheads see more acceleration than on the
   cert flight. Gentlest robust options: J1299N, J1265T, K1499N (24–26).
3. **Motor adapter.** Every 54 mm option needs a 75→54 mm adapter that carries
   thrust and retains the motor. That part does not exist yet.
   K1499N is the only robust option with no adapter.
4. **Hardware cost.** Every path needs a case not owned: RMS-75/1280 for
   K1499N, or 54 mm case(s) plus adapter. The RMS-75/5120 planned for L3
   cannot fly any of these.
5. **Availability.** AeroTech "N" (Warp-9) and "ST" propellants and CTI's
   fast-burning reloads are niche in Europe. Swedish supply not verified.
6. **Landing radius.** From ~1000 m with drogue at apogee (~20 m/s) and main
   at 150 m (as on the L2 flight), descent takes ~60–70 s. At 5 m/s wind that
   is ~350 m drift. This fits the 500 m radius, with little slack above ~6 m/s
   wind. Use main at 150 m, not 300 m as in `L3-Design.md` §9.
7. **Model limits.** Vertical, no wind, constant Cd, no rail friction. Mass
   budget unverified. Weigh the built airframe and re-run the script.

## 6. Suggested Progression

| Flight | Motor | Apogee | Purpose |
|---|---|---|---|
| Test 1 | J1299N | ~585 m | Gentle and low: first check of airframe, recovery, redundant electronics |
| Test 2 | K1499N (no adapter) or K2050ST | ~1000 m | Near-ceiling flight, full recovery sequence at altitude |
| L3 cert | M1297W in **new** airframe | 1.5–3 km | At a field with a higher ceiling |

Both test flights must be recovered intact to count — land under main.

## 7. Next Steps

- [ ] Choose motor path: 75 mm (K1499N only, no adapter) vs 54 mm (more choices, new adapter)
- [ ] Ask SMRK for available rail lengths (1515)
- [ ] Check Swedish/EU availability of the §4.1 reloads
- [ ] Build `PeregrineL3.ork` — stability margin with test motors and M1297W
- [ ] Weigh printed fin can + fins once built; re-run with real mass
- [ ] Brief both TAPs on the design and this test-flight plan
- [ ] Fix `L3-Design.md` §2 (remove sub-scale line) and §9 (main at 150 m)
