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
| `02_EBayTube.stl` | 2 | 160.00 | 60.00 | 45.7 cm³ |
| `03_ChuteBayTube.stl` | 3 | 180.00 | 60.00 | 53.5 cm³ |
| `04_EBayFwdBulkhead.stl` | 4 | 6.00 | 56.40 | 12.7 cm³ |
| `05_EBayAftBulkhead.stl` | 5 | 27.00 | 56.40 | 54.4 cm³ |
| `06_VegaSled.stl` | 6 | 8.00 | 44×112 flat | 20.0 cm³ |
| `07_AccessDoor.stl` | 7 | 97.00 | 64.00 | 10.6 cm³ |
| `08_SpringCarrier.stl` | 8 | 65.00 | 56.40 | 55.1 cm³ |
| `09_FinCan.stl` | 9 | 228.00 | 60.00 | 114.0 cm³ |
| `10_Fin.stl` | 10 | 4.00 | flat | 15.8 cm³ |
| `11_MotorRetainer.stl` | 11 | 6.00 | 60.00 | 13.4 cm³ |
| `12_MotorSpacer.stl` | 12 | 104.00 | 29.00 | 17.6 cm³ |
| `13_TetherLatch.stl` | 13 | 16.00 | 41.78 | 3.5 cm³ |

Print 3 fins from `10_Fin.stl`. `12_MotorSpacer.stl` is the G80T spacer
(`Motor_Class = 0`); set `Motor_Class` to 1 or 2 and re-export for the H182R or
H135W. `NoseCone.stl` is the user's `Nose Cone.STEP` converted, not
regenerated.

Re-exported after the code-review fix pass: part 2 grew (Vega retention
rails + door screw bosses, +4.2 cm³), part 5 shrank slightly (wider tether
notch), part 7 changed from a flush plug to an overlapping retaining cover
(+5.5 cm³, height 84.30→97.00, OD 60.00→64.00), part 9 shrank slightly
(shock-cord anchor holes), part 12 grew (99.00→104.00mm, corrected motor-tube
depth), part 13 grew (hole spacing moved clear of the horn slot,
16.00mm/30.53 OD→16.00mm/39.40 OD). Re-exported again after the fin
re-sizing (coordinator decision, group 2 re-target): part 10 grew span
55→63mm (+2.0 cm³ per fin, root/tip/sweep/thickness unchanged) to fix the
G80T-14A's static margin — see `R60-PrintSettings.md` §9's fin-sizing
note and the spec §6 for the full analysis. Parts 6 and 9 also changed
(Vega sled M3 holes widened 2.9→3.4mm; fin can's fin slot lengthened to
match — neither changes the part's own extent, only its interior).

Re-exported again after the 2nd code-review fix pass: part 2's door screw
holes now bore along the wall's true local radial direction instead of a
flat axis (defect 1a), the Vega retention rails now actually close on the
sled (defect 1b), and the door bosses no longer poke past the true OD --
Max OD 60.40→60.00 (defect 2a). Part 8's tether notch now matches the
skirt channel it must clear (8.00→9.20mm, defect 2c; no change to this
part's own extent). Part 13 grew again (Base_L 36.00→38.60mm, defect 2b
-- the old wall beyond the mounting holes was 0.30mm, below one extrusion
width) -- Max OD 39.40→41.78, +0.2 cm³.

Tallest part 228 mm, inside the 250 mm envelope with 22 mm to spare.

## Mass — measured from the exported meshes

Per-part mass now comes from these measured mesh volumes (PETG 1.27 g/cm³,
PC 1.20 g/cm³ per `R60-PrintSettings.md` sec 3, at a stated 78% effective
print density), not a round-number estimate — see
`tools/rocket60_model.py`. **Liftoff mass on the G80T-14A (the sizing
motor) is 868 g**, giving **1.62 cal** static margin and **18.9 m/s** off
a 1.5 m 1010 rail — both clear their targets (1.5 cal, 15 m/s) with
margin, despite the fin-span growth (+14 g total) needed to reach them.
H182R-14A gives 934 g / 1.43 cal / 28.0 m/s; H135W-14A gives 937 g / 1.44
cal. Full breakdown, all three motors, in `tools/rocket60_model.py`'s own
output.

**Weigh the parts as they come off the printer** and compare against
`tools/rocket60_model.py`'s per-part figures before committing to a rail
length.

## Verification

Each file above was checked after export: measured height and max OD compared
against what that part is supposed to be. An earlier export silently wrote
every part under the *next* part's filename — each STL internally valid, each
one wrong. Only the dimension cross-check caught it. If you regenerate these,
re-run that check rather than trusting the loop.
