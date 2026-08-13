# Rocket 60 — printable meshes

**This rocket is not finished. Do not print past step 1 yet.** The recovery
mechanism (separation + tether latch) is mid-redesign and still doesn't
exist — see "Not yet built".

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
| `09_FinCan.stl` | 9 | 228.00 | 60.00 | Ø29.3 MMT, 3× fin slots, 3× M3 blind insert bosses (r=24, aft end) for the retainer. 228 mm sized for the 216 mm H135W, not the 124 mm G80T — the G80T flies on `12_MotorSpacer`. |
| `10_Fin.stl` | 10 | 4.00 | 90×55 | Flat print, 3 needed. Root 90 mm; aspect ratio 0.88 is deliberate — it's what puts flutter velocity at ~850 m/s. Do not thin or extend it. |
| `11_MotorRetainer.stl` | 11 | 6.00 | 60.00 | Traps the motor's aft rim. 3× M3 clearance (Ø3.4, r=24) into `09_FinCan`'s bosses. |
| `12_MotorSpacer.stl` | 12 | 99.00 | 29.00 | Motor_Class=0 (G80T) length. Re-render with Motor_Class=1 (H182R) or 2 (H135W) for the longer motors — those need no spacer at all once close to 223mm. |

`06_VegaSled` and `10_Fin` are flat plates, not tubes — dimensions are
width×length, not a diameter. `10_Fin`'s slot in `09_FinCan` gets 0.2 mm
clearance at each end (90.4 mm slot for the 90 mm root) as well as across its
4 mm thickness — a slip fit, since the fin is epoxied in, not bolted.
`09_FinCan` and `11_MotorRetainer` fasten together with 3× M3 into ruthex
RX-M3x5.7 heat-set inserts, on a bolt circle offset 60° from the fins so the
bolts land between them.

## Not yet built

- **Spring separation + shear pins** — the cam-ramped bayonet was abandoned
  after it was proved it cannot work (a surface of revolution generates no
  torque from axial load). Being rebuilt around `SpringThingBooster` +
  `CableReleaseBBMini` and a fresh shear-pin joint.
- **Tether latch** — releases the main at 150 m.
- **Print settings** — material, walls, infill, orientation per part.

## Material, when you do print

PETG for airframe and e-bay; PC for the fin can, centering rings, retainer and
spacers, which sit next to the motor. **No carbon-filled filament anywhere from
the neck to the chute bay** — the CATS manual states a carbon-fibre section
blocks all RF, and both the telemetry and GNSS antennas live inside the
airframe.

Tallest part 228 mm (`09_FinCan`), inside the 250 mm envelope.
