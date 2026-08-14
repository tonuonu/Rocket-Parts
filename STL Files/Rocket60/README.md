# Rocket 60 — printable meshes

Ø60 mm camera rocket, 684 mm, built around the user's own CAD nosecone.
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
| `02_EBayTube.stl` | 2 | 177.00 | 60.00 | 50.0 cm³ |
| `03_ChuteBayTube.stl` | 3 | 185.50 | 60.00 | 55.7 cm³ |
| `04_EBayFwdBulkhead.stl` | 4 | 6.00 | 56.40 | 12.7 cm³ |
| `05_EBayAftBulkhead.stl` | 5 | 27.00 | 56.40 | 54.4 cm³ |
| `06_VegaSled.stl` | 6 | 8.00 | 44×112 flat | 20.0 cm³ |
| `07_AccessDoor.stl` | 7 | 97.00 | 64.00 | 10.6 cm³ |
| `08_SpringCarrier.stl` | 8 | 65.00 | 56.40 | 52.9 cm³ |
| `09_FinCan.stl` | 9 | 228.00 | 60.00 | 114.0 cm³ |
| `10_Fin.stl` | 10 | 4.00 | flat | 15.8 cm³ |
| `11_MotorRetainer.stl` | 11 | 6.00 | 60.00 | 13.4 cm³ |
| `12_MotorSpacer.stl` | 12 | 98.00 | 29.00 | 16.6 cm³ |
| `13_TetherLatch.stl` | 13 | 16.00 | 41.78 | 3.0 cm³ |
| `14_ThrustRing.stl` | 14 | 6.00 | 28.90 | 0.6 cm³ |

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

Re-exported again after the 3rd code-review fix pass: part 2 shrank
(45.7→44.9 cm³) -- the Vega rails' Z window is now derived per-end from
what actually sits there (the aft bulkhead's disc, the neck skirt/forward
bulkhead) instead of a flat 5mm margin that overlapped all three (defect
2). Part 3 grew (180.00→186.00mm, 53.5→55.2 cm³) -- a new Ø56.4 spigot
onto the fin can, the same concentric-coupler treatment every other
internal joint already had (should-fix 6). Part 8 shrank (55.1→52.9 cm³)
-- its tether relief channel now runs the carrier's full 65mm length
instead of 5mm, so the chute tube's tether lug has clearance for the
whole assembly stroke, not just the seated position (defect 1). Part 12
shrank (104.00→98.00mm, 17.6→16.6 cm³) to make room for the new part 14.
**`14_ThrustRing.stl` is new** (defect 3): nothing previously reacted the
motor's forward thrust reaction -- the aft `11_MotorRetainer.stl` only
ever resisted aft motion -- so under thrust the motor+spacer stack had
only a 0.3mm slip fit standing between it and the packed parachute. Glues
into the MMT's forward opening, flush with the fin can's own tip,
Ø26.8mm lip catching the motor+spacer stack's forward face.

Re-exported again within the 3rd review's fix pass: part 2 grew again
(165.00mm, 44.9→46.2 cm³) -- R60_EBay_L grew 160→165 (should-fix 9) so
the arming-switch Z window is a genuine ~3mm margin instead of a 0.5mm
hair gap, and its 2 zip-tie slots (per Z station) became 4, straddling
the sled tangentially at each rail's own azimuth instead of both
sharing one (defect 11) -- the old pair shared an azimuth 40mm apart
and never actually crossed the sled, so cinching them provided zero
retention. Total airframe length 662→667mm.

Re-exported again within the 4th review's fix pass: part 2 grew again
(165.00→177.00mm, 46.2→50.0 cm³) -- R60_EBay_L grew again (critical 3):
the 3rd review's own Sw_Z0 fix measured the arming-switch's clearance
from the door APERTURE's own edge, not from R60_Door()'s actual built
footprint (a COVER, R60_Door_Overlap=6mm larger than the aperture on
every side) -- correctly counting that overlap needed 12mm more of
R60_EBay_L to restore a genuine ~3mm window (the switch was measured
1.5mm INSIDE the door cover's own footprint at the old length). Part 3
shrank slightly (186.00→185.50mm, 55.2→55.7 cm³) -- R60_FinCanSpigot_L
now derives a genuine 0.5mm axial clearance from the fin can's own open
annulus instead of exactly matching it (should-fix 8, a bare tangency
that bottomed the joint before the airframe's outer OD faces could close
flush), while a new internal weld ring (critical 1) bridges the spigot to
the tube's own wall with real shared material -- the chute tube used to
export as TWO disconnected solids (the spigot floating entirely inside
the tube's own bore, a 0.2mm gap with zero shared geometry); genus could
not see this, only a new connected-component check (`components()` in
`tools/scad_verify.py`) could. Two tether-lug/spring-tab features
embedded further into this part's own wall (critical 4) also add a
little material. Part 13 shrank (3.5→3.0 cm³, height/OD unchanged) --
its base is now clipped to a radius that clears the spring carrier's own
counterbore rim AND the chute tube's own bore (critical 2: the base's
far corners previously reached 0.6-1mm past both), and gained a
pass-through cut so the base no longer seals the servo-2 horn slot shut
(critical 5) -- net genus 4→5 (one new through-hole).

Tallest part 228 mm, inside the 250 mm envelope with 22 mm to spare.

## Mass — measured from the exported meshes

Per-part mass now comes from these measured mesh volumes (PETG 1.27 g/cm³,
PC 1.20 g/cm³ per `R60-PrintSettings.md` sec 3, at a stated 78% effective
print density), not a round-number estimate — see
`tools/rocket60_model.py`. **Liftoff mass on the G80T-14A (the sizing
motor) is 871 g**, giving **18.9 m/s** off
a 1.5 m 1010 rail (clears its 15 m/s target) but only **1.45 cal** static
margin — BELOW the 1.5 cal target (4th review: a full station audit,
coordinator override, found the previously-published 1.53 cal -- itself
already a correction of an inflated 1.61 cal -- was still short six more
station errors; see the design spec §6 for the full audit table). No
design change was made to force this back above 1.5 cal. H182R-14A gives
938 g / 1.27
cal / 27.9 m/s; H135W-14A gives 941 g / 1.28
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
