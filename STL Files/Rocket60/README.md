# Rocket 60 — printable meshes

Ø60 mm camera rocket, 744 mm, built around the user's own CAD nosecone.
Regenerated from `Rocket60.scad` at branch HEAD after the petal-deployment
transplant (the invented spring/ball-lock carrier + shear-pin + servo-
tether design replaced by a flown design's own petal-deployment + cable-
release libraries — see `docs/superpowers/specs/2026-08-13-rocket60-
design.md` sec 4 and `tasks/lessons.md`); every file below was measured
after export and checked against the geometry that part is supposed to
have.

Verify with `python3 tools/verify_rocket60.py`, the assembly harness
(`verify_rocket60_assembly.py`, 23 pairs), and `verify_docs_sync.py`.

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
| `02_EBayTube.stl` | 2 | 177.00 | 60.00 | 47.1 cm³ | PETG |
| `03_DeploymentBayTube.stl` | 3 | 240.00 | 60.00 | 70.4 cm³ | PETG |
| `04_EBayFwdBulkhead.stl` | 4 | 7.70 | 56.40 | 12.7 cm³ | PETG |
| `05_EBayAftBulkhead.stl` | 5 | 27.00 | 56.40 | 39.4 cm³ | PETG |
| `06_VegaSled.stl` | 6 | 8.00 | 133.1×45.6 flat | 23.8 cm³ | PETG |
| `07_AccessDoor.stl` | 7 | 97.00 | 64.00 | 11.3 cm³ | PETG |
| `08_PetalHub.stl` | 8 | 26.50 | 56.40 | 24.8 cm³ | PETG |
| `09_FinCan.stl` | 9 | 228.00 | 60.00 | 114.0 cm³ | **PC** |
| `10_Fin.stl` | 10 | 4.00 | flat | 15.8 cm³ | PETG, print 3 |
| `11_MotorRetainer.stl` | 11 | 6.00 | 60.00 | 13.4 cm³ | **PC** |
| `12_MotorSpacer.stl` | 12 | 98.00 | 29.00 | 16.6 cm³ | **PC** |
| `13_Petals.stl` | 13 | 120.00 | 56.40 | 34.2 cm³ | PETG |
| `14_ThrustRing.stl` | 14 | 6.00 | 28.90 | 0.6 cm³ | **PC** |

Airframe total 440.3 cm³. Tallest part 228 mm, inside the 250 mm envelope
with 22 mm to spare. `NoseCone.stl` is the user's `Nose Cone.STEP`
converted, not regenerated.

`12_MotorSpacer.stl` is the G80T spacer (`Motor_Class = 0`); set
`Motor_Class` to 1 or 2 and re-export for the H182R or H135W.

## Release hardware (petal-deployment transplant)

`use<>`-instantiated from a flown design's own libraries
(`CableReleaseBBMicro.scad`, `R65Lib.scad`) rather than designed here --
see the spec's sec 4 for the mechanism and why BBMicro, not the flown
BBMini. All PETG.

| File | Part | Height | Vol |
|---|---|---|---|
| `15_ReleaseActivator.stl` | 15 | 27.00 | 7.3 cm³ |
| `16_ReleaseTopRetainer.stl` | 16 | 24.20 | 5.4 cm³ |
| `17_ReleaseLockRing.stl` | 17 | 20.00 | 3.6 cm³ |
| `18_ReleaseOuterBearingRetainer.stl` | 18 | 5.70 | 1.6 cm³ |
| `19_ReleaseTriggerPost.stl` | 19 | 8.00 | 0.3 cm³ |
| `20_ReleaseMagnetBracket.stl` | 20 | 11.38 | 0.4 cm³ |
| `21_ReleaseExtensionRod.stl` | 21 | 26.00 | 1.1 cm³ |
| `22_ReleaseLockingPin.stl` | 22 | 18.00 | 1.5 cm³ |
| `23_ForwardSpringEnd.stl` | 23 | 25.00 | 10.5 cm³ |

Release hardware total 31.7 cm³. Plus loose hardware this design does
not model as its own solid: 6mm Delrin balls (3), 6703-2RS bearing, 3×
MR63 lock bearings, 2× N42 magnets, dowel pins, #4-40 screws — see
`CableReleaseBBMicro.scad`'s own header for the full catalog list (note:
that header's own BOM comment is stale, listing 5/16in balls and a 6705
bearing; the parts above are built from the LIVE code, 6mm balls/6703).

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
Re-run after the petal-deployment transplant (spec sec 4).

| Motor | Liftoff | Margin | Rail exit (1.83 m) |
|---|---|---|---|
| G80T-14A | 907 g | 1.56 cal | 20.4 m/s |
| H182R-14A | 973 g | 1.36 cal | 30.4 m/s |
| H135W-14A | 976 g | 1.36 cal | 23.4 m/s |

Fin flutter Vf = 589 m/s (root-chord t/c, NAR/TIR-33 form). Per-motor
margin against each motor's own Vmax, floor 1.5×: G80T 4.7×, H182R 2.9×,
H135W 3.1×.

## Launch

1010 rail. The user's Estes Pro Series II rail (1.83 m, two 3-foot sections)
is 1010-compatible per Estes, so `RailButton(OD=11, Flange_h=2, Slot_w=2.8)`
from `RailGuide.scad` fits directly. Axial placement (task 7): azimuth
180°, aft button Z=630mm (fin can, forward of the fins), forward button
Z=242mm (e-bay tube) — `R60Lib.scad`'s `R60_RailButton_*` constants.

Rail exit on that rail: **G80T 20.4 m/s**, H182R 30.4, H135W 23.4 — all
comfortably above the ~15 m/s minimum.

The 3 mm rod is not usable at this mass. The TSP E20-P is excluded: 8.9 m/s
off the 1.83 m rail, well under the minimum.

## Verification

Every file above was measured after export and checked against what that
part should be. This matters: an earlier export in this project silently
wrote every part under the *next* part's filename — each STL internally
valid, every one wrong — and only the dimension cross-check caught it.
If you regenerate these, re-run that check rather than trusting the loop.
