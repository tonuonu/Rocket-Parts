# 29mm MMT Motor Adapter — Baseline v0.5

## File: MotorAdapter29.scad
## Branch: feature/motor-adapter-29
## Baseline commit: c65a766

## Purpose
Printed sleeve that sits inside a 29mm motor mount tube (MMT) so a 29mm-designed
rocket can fly smaller standard motors (18mm or 24mm). Host rocket's existing
29mm aft retainer engages the adapter's aft rim; the adapter holds the motor.

## Host MMT
- MMT_ID = 29.0 mm
- MMT_Depth = 113 mm (aft end → forward thrust ring)

## Three-zone internal geometry (aft → forward)
1. **Exhaust throat** — Ø Motor_OD + 3 mm, gives nozzle plume room to expand
   so hot gas doesn't blast the thin 18/24 mm wall. Skipped if remaining
   axial space < 5 mm.
2. **Motor bore** — Ø Motor_OD + 0.3 mm slip fit, length = Motor_L + 2 mm
   buffer. Motor slides in from aft, forward rim bottoms against ring.
3. **Thrust ring** (forward) — ANNULUS 3.5 mm thick, inner Ø = Motor_OD − 2 mm
   (matches motor internal diameter). Open center lets paper forward cap and
   ejection gases pass unrestricted. Works for both ejection-charge and
   plugged (-P) motors.

## Motor presets (Motor_Class = 0..6, -1 for manual)
| Class | Motor | OD | L | Tag |
|------:|-------|---:|--:|-----|
| 0 | 18mm 1/2A short | 18 | 45 | 18mm-short |
| 1 | 18mm Estes A8/B6/C6 | 18 | 70 | 18mm-std |
| 2 | 24mm Estes D12 | 24 | 70 | 24mm-EstesD |
| 3 | 24mm Aerotech 24/40 | 24 | 89 | 24mm-AT2440 |
| 4 | 24mm Estes E9/E12 | 24 | 95 | 24mm-EstesE |
| 5 | 18mm Klima plugged | 18 | 69 | 18mm-Klima |
| 6 | 24mm TSP E20-P plugged | 24 | 94 | 24mm-TSP-E20P |

## Print settings
- Bambu P1S, PC (preferred) or PETG. **Not PLA** (softens at motor casing temp).
- Vertical, aft (open) end down on bed. Ring prints last, bridges fine.
- 4+ perimeters, 40–60% infill, 0.2 mm layers, brim recommended.

## Exported preset files on disk
- `MotorAdapter29.scad` — source
- `MotorAdapter29.3mf` — default export
- `MotorAdapter29_18.3mf` — 18 mm preset (class 5, Klima)
- `MotorAdapter29_24.3mf` — 24 mm preset (class 6, TSP E20-P)

## Motor retention (aft) — NOT integrated
Rely on one of:
- Rocket's existing 29 mm aft retainer catching the adapter rim
- Masking tape around adapter aft + motor
- Wire motor hook taped to adapter outside

For **plugged (-P)** motors: no ejection back-pressure, so friction/hook is the
only post-burnout retention. Tape wrap recommended.

## Graph-visibility note
The flying-rocket fleet in README.md (98G, 98 Red One, 9832, 13732, BoosterPooper,
Peregrine L2/L3) all use 54 mm+ motors. No documented consumer for this 29 mm
adapter yet — confirm intended host rocket before flight testing.

## Known issues / deferred
- Motor-bore wall < 1.5 mm triggers echo warning (24 mm in 29 mm MMT = 2.2 mm
  wall, marginal — 4+ perimeters mandatory).
- Ring inner reduction (2 mm) assumed for paper-cased motors. Increase to
  3–4 mm for thicker-walled composite reloads.
- Ground-test deployment with adapter in place before trusting ejection-charge
  motors in flight.
