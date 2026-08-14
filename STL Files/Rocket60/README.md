# Rocket 60 — printable meshes

Ø60 mm camera rocket, 684 mm, built around the user's own CAD nosecone.
Regenerated from `Rocket60.scad` at branch HEAD after the 9th review round;
every file below was measured after export and checked against the geometry
that part is supposed to have.

Verify with `python3 tools/verify_rocket60.py`, the assembly harness
(`verify_rocket60_assembly.py`, 33 pairs), and `verify_docs_sync.py`.

## Print part 0 first, and stop there

| File | Part | Height | Max OD | Vol |
|---|---|---|---|---|
| `00_TestRing.stl` | 0 | 10.00 | 60.00 | 19.9 cm³ |

It gauges three fits on one 10 mm print: the flange flush on the nosecone
base, the three M3 holes against the camera's heat-set inserts (Ø37.96
circle at 52.2° / −52.2° / 180°), and the coupler spigot in a body tube.
The angles are deliberately not 120° apart — that asymmetry keys the
camera's clocking.

It is also the scale check. Printed-to-printed fits survive shrinkage
because both halves shrink alike; printed-to-CAD fits do not, and that bolt
circle must meet inserts in a PCB that does not shrink.

## Airframe

| File | Part | Height | Max OD | Vol | Material |
|---|---|---|---|---|---|
| `NoseCone.stl` | — | 94.05 | 59.99 | 29.4 cm³ | PETG |
| `01_Neck.stl` | 1 | 24.00 | 60.00 | 16.2 cm³ | PETG |
| `02_EBayTube.stl` | 2 | 177.00 | 60.00 | 47.2 cm³ | PETG |
| `03_ChuteBayTube.stl` | 3 | 185.50 | 60.00 | 55.6 cm³ | PETG |
| `04_EBayFwdBulkhead.stl` | 4 | 7.70 | 56.40 | 12.7 cm³ | PETG |
| `05_EBayAftBulkhead.stl` | 5 | 27.00 | 56.40 | 54.3 cm³ | PETG |
| `06_VegaSled.stl` | 6 | 8.00 | 144×44 flat | 23.8 cm³ | PETG |
| `07_AccessDoor.stl` | 7 | 97.00 | 64.00 | 11.3 cm³ | PETG |
| `08_SpringCarrier.stl` | 8 | 65.00 | 56.40 | 52.9 cm³ | PETG |
| `09_FinCan.stl` | 9 | 228.00 | 60.00 | 114.0 cm³ | **PC** |
| `10_Fin.stl` | 10 | 4.00 | flat | 15.8 cm³ | PETG, print 3 |
| `11_MotorRetainer.stl` | 11 | 6.00 | 60.00 | 13.4 cm³ | **PC** |
| `12_MotorSpacer.stl` | 12 | 98.00 | 29.00 | 16.6 cm³ | **PC** |
| `13_TetherLatch.stl` | 13 | 16.00 | 41.78 | 3.0 cm³ | PETG |
| `14_ThrustRing.stl` | 14 | 6.00 | 28.90 | 0.6 cm³ | **PC** |

Airframe total 457.2 cm³. Tallest part 228 mm, inside the 250 mm envelope
with 22 mm to spare. `NoseCone.stl` is the user's `Nose Cone.STEP`
converted, not regenerated.

`12_MotorSpacer.stl` is the G80T spacer (`Motor_Class = 0`); set
`Motor_Class` to 1 or 2 and re-export for the H182R or H135W.

## Ground-test motors

| File | Height | Ballast → loaded | → burnout | Totals |
|---|---|---|---|---|
| `MotorDummy_G80T.stl` | 124.00 | 99.6 g | 36.6 g | 128 / 65 g |
| `MotorDummy_H182R.stl` | 203.00 | 161.7 g | 46.7 g | 207 / 92 g |
| `MotorDummy_H135W.stl` | 216.00 | 164.0 g | 82.0 g | 212 / 130 g |

Loose ballast on purpose: one print covers both mass cases. Burnout is the
condition deployment actually happens in — 63 g lighter on the G80T — so a
separation test at loaded mass tests the wrong rocket.

## The access door stands 2 mm proud

`07_AccessDoor.stl` is Ø64 on a Ø60 airframe: it is an outer cover, not a
flush panel. That is forced by the 1.6 mm wall — a 2 mm cover cannot be
rebated into it. Consequence worth knowing: a 2 mm step over 97 mm of length
adds drag the flight model's Cd₀ = 0.52 does not account for, so predicted
apogee is slightly optimistic. Not enough to matter for recovery planning;
enough that it should not be a surprise.

## Flight figures

Kept here so `tools/verify_docs_sync.py` can gate them against the model.

| Motor | Liftoff | Margin | Rail exit (1.5 m) |
|---|---|---|---|
| G80T-14A | 874 g | 1.46 cal | 18.8 m/s |
| H182R-14A | 941 g | 1.28 cal | — |
| H135W-14A | 944 g | 1.29 cal | — |

## Launch

1010 rail. The user's Estes Pro Series II rail (1.83 m, two 3-foot sections)
is 1010-compatible per Estes, so `RailButton(OD=11, Flange_h=2, Slot_w=2.8)`
from `RailGuide.scad` fits directly.

Rail exit on that rail: **G80T 20.9 m/s**, H182R 30.8, H135W 23.8 — all
comfortably above the ~15 m/s minimum. On a shorter 1.5 m rail the G80T
gives 18.8 m/s, still acceptable.

The 3 mm rod is not usable at this mass. The TSP E20-P is excluded: 9.4 m/s
off the 1.83 m rail, well under the minimum.

## Verification

Every file above was measured after export and checked against what that
part should be. This matters: an earlier export in this project silently
wrote every part under the *next* part's filename — each STL internally
valid, every one wrong — and only the dimension cross-check caught it.
If you regenerate these, re-run that check rather than trusting the loop.
