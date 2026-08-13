# Rocket 60 — printable meshes

**This rocket is not finished. Do not print past step 1 yet.** Four parts do
not exist, and the recovery mechanism is mid-redesign — see "Not yet built".

Generated from `Rocket60.scad`, OpenSCAD 2026.07.09, full render, binary STL.
Verify with `python3 tools/verify_rocket60.py` — every part is measured from
its rendered mesh, and mating fits are checked mesh-against-mesh rather than
against the constants that produced them.

## Print step 1 first, and stop

| File | Part | Height | OD | |
|---|---|---|---|---|
| `00_TestRing.stl` | 0 | 10.00 | 60.00 | **PRINT THIS FIRST** |

It gauges three fits on one 10 mm part: the flange against your nosecone base,
the three M3 bolt holes against the camera's heat-set inserts (Ø37.96 circle at
52.2°/−52.2°/180° — the asymmetry keys the camera's clocking), and the coupler
spigot against a body tube.

**If the bolt circle or the clocking is wrong, nothing downstream is worth
printing.** That is the whole reason this part exists.

## Then the rest of what exists

| File | Part | Height | OD | Notes |
|---|---|---|---|---|
| `NoseCone.stl` | — | 94.05 | 59.99 | **Your CAD**, converted not regenerated. Fixed part; the whole rocket is sized from its 59.99 base. |
| `01_Neck.stl` | 1 | 24.00 | 60.00 | Butt joint, no spigot — the camera fills the bore. 3× M3×10 into its inserts. |
| `02_EBayTube.stl` | 2 | 160.00 | 60.00 | Door aperture + arming switch hole, both on +Y. |
| `03_ChuteBayTube.stl` | 3 | 180.00 | 60.00 | 80 mm spring mechanism + 100 mm main. |
| `04_EBayFwdBulkhead.stl` | 4 | 6.00 | 56.40 | Harness pass-through. |
| `05_EBayAftBulkhead.stl` | 5 | 12.00 | 56.40 | Shock cord anchor, 2 servo pockets, drive bore. |
| `06_VegaSled.stl` | 6 | 8.00 | 44×112 | 60×27 M3 pattern. Antenna side faces radially OUT. |
| `07_AccessDoor.stl` | 7 | 84.30 | 60.00 | 4× M2.5. |

`06_VegaSled` is a flat plate, not a tube — 44 × 112 mm, not a 120 mm diameter.

## Not yet built

- **Spring separation + shear pins** — the cam-ramped bayonet was abandoned
  after it was proved it cannot work (a surface of revolution generates no
  torque from axial load). Being rebuilt around `SpringThingBooster` +
  `CableReleaseBBMini` and a fresh shear-pin joint.
- **Tether latch** — releases the main at 150 m.
- **Fin can and fins** — 228 mm, Ø29 MMT sized for a 216 mm H DMS.
- **Motor retainer and spacers.**
- **Print settings** — material, walls, infill, orientation per part.

## Material, when you do print

PETG for airframe and e-bay; PC for the fin can, centering rings, retainer and
spacers, which sit next to the motor. **No carbon-filled filament anywhere from
the neck to the chute bay** — the CATS manual states a carbon-fibre section
blocks all RF, and both the telemetry and GNSS antennas live inside the
airframe.

Tallest part 180 mm, inside the 250 mm envelope.
