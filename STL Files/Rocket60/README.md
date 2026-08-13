# Rocket 60 — printable meshes

Ø60 mm camera rocket, 662 mm, built around the user's own CAD nosecone.
Generated from `Rocket60.scad`, OpenSCAD 2026.07.09, full render, binary STL.
Verify with `python3 tools/verify_rocket60.py` — every part is measured from
its rendered mesh, and mating fits are checked mesh-against-mesh rather than
against the constants that produced them.

Print settings, assembly order and the CATS Vega configuration are in
`R60-PrintSettings.md`.

## Print part 0 first, and stop there

| File | Part | Height | Max OD | Vol |
|---|---|---|---|---|
| `00_TestRing.stl` | 0 | 10.00 | 60.00 | 19.9 cm³ |

It gauges three fits on one 10 mm print: the flange against the nosecone base,
the three M3 holes against the camera's heat-set inserts (Ø37.96 circle at
52.2°/−52.2°/180° — the asymmetry keys the camera's clocking), and the coupler
spigot against a body tube. **If the bolt circle or its clocking is wrong,
nothing downstream is worth filament.**

It is also the scale check. Printed-to-printed fits survive shrinkage because
both halves shrink alike; printed-to-CAD fits do not. That Ø37.96 circle has to
line up with inserts in a PCB that does not shrink.

## Full part list

| File | Part | Height | Max OD | Vol |
|---|---|---|---|---|
| `NoseCone.stl` | — | 94.05 | 59.99 | 29.4 cm³ |
| `00_TestRing.stl` | 0 | 10.00 | 60.00 | 19.9 cm³ |
| `01_Neck.stl` | 1 | 24.00 | 60.00 | 16.2 cm³ |
| `02_EBayTube.stl` | 2 | 160.00 | 60.00 | 41.5 cm³ |
| `03_ChuteBayTube.stl` | 3 | 180.00 | 60.00 | 53.3 cm³ |
| `04_EBayFwdBulkhead.stl` | 4 | 6.00 | 56.40 | 12.7 cm³ |
| `05_EBayAftBulkhead.stl` | 5 | 27.00 | 56.40 | 54.8 cm³ |
| `06_VegaSled.stl` | 6 | 8.00 | 44×112 flat | 20.0 cm³ |
| `07_AccessDoor.stl` | 7 | 84.30 | 60.00 | 5.1 cm³ |
| `08_SpringCarrier.stl` | 8 | 65.00 | 56.40 | 55.0 cm³ |
| `09_FinCan.stl` | 9 | 228.00 | 60.00 | 114.1 cm³ |
| `10_Fin.stl` | 10 | 4.00 | flat | 13.8 cm³ |
| `11_MotorRetainer.stl` | 11 | 6.00 | 60.00 | 13.4 cm³ |
| `12_MotorSpacer.stl` | 12 | 99.00 | 29.00 | 16.8 cm³ |
| `13_TetherLatch.stl` | 13 | 16.00 | 30.53 | 2.7 cm³ |

Print 3 fins from `10_Fin.stl`. `12_MotorSpacer.stl` is the G80T spacer
(`Motor_Class = 0`); set `Motor_Class` to 1 or 2 and re-export for the H182R or
H135W. `NoseCone.stl` is the user's `Nose Cone.STEP` converted, not
regenerated.

Tallest part 228 mm, inside the 250 mm envelope with 22 mm to spare.

## Mass — the design estimate was optimistic

The spec's budget assumed **412 g** of printed parts. The exported meshes total
**439.2 cm³ = 558 g at 100 % density**. Real infill brings that down, but the
model was optimistic either way:

| Effective density | Printed | Liftoff on the G80T |
|---|---|---|
| 100 % | 558 g | 1003 g |
| ~78 % | 435 g | 880 g |
| ~65 % | 363 g | 808 g |

The spec's figure is 887 g, which corresponds to roughly 78 % effective density
— plausible but not verified.

**This matters because rail exit is already the binding constraint.** At 887 g
the rocket leaves a 1.5 m rail at 15.2 m/s, right on the ~15 m/s minimum. If
the real build lands nearer 1000 g it will be below it.

**Weigh the parts as they come off the printer** and compare against the spec's
mass budget before committing to a rail length. A 2 m rail is recommended for
G80T flights regardless.

## Verification

Each file above was checked after export: measured height and max OD compared
against what that part is supposed to be. An earlier export silently wrote
every part under the *next* part's filename — each STL internally valid, each
one wrong. Only the dimension cross-check caught it. If you regenerate these,
re-run that check rather than trusting the loop.
