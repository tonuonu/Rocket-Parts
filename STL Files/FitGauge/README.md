# Fit gauge — find the diameter that actually fits

| File | Parameters | Bands |
|---|---|---|
| `FitGauge_Peregrine_98.6.stl` | `Gauge_Mode=0` (all else default: `Gauge_Target_d=98.6, Gauge_Step=0.25, Gauge_Count=5`) | Ø98.10 → Ø99.10 in 0.25 mm steps. 35 mm tall, ~92.10 mm bore. |
| `FitGauge_Peregrine_FINE.stl` | `Gauge_Mode=0 -D Gauge_Target_d=98.975 -D Gauge_Step=0.05 -D Gauge_Count=6` | Ø98.85 → Ø99.10 in 0.05 mm steps. 42 mm tall, ~92.85 mm bore. See `README-FINE.md`. |

Both generated from `FitGauge.scad`.

## How to use it

1. Print it in the **same material and profile** you print flight parts in.
   A gauge printed in a different filament or profile measures that
   filament and profile, not the parts you care about.
2. Offer the **small end** (Ø98.10, engraved, at the top as printed) to the
   tube and push gently.
3. It stops at the first band too big to enter. **The largest band that
   entered is your working diameter.**

## Reading the result

The bands are centered on Ø98.6 — the Peregrine shoulder's *designed* OD,
which is `Peregrine_Body_ID (99.0) − 0.4 mm` of deliberate diametral
clearance (see `PeregrineNoseCone.scad`). It is **not** the tube's own ID.

The reading tells you the largest nominal diameter that this tube and this
printer, together, will actually accept — which is how much of that 0.4 mm
clearance survives your printer's own dimensional error. The gauge cannot
tell you separately whether the tube or the printer is the reason; it only
tells you the combined result.

| Largest band that entered | What it means |
|---|---|
| 99.10 | Clearance survives with margin to spare beyond the 0.4 mm designed in. No change needed. |
| 98.85 | About 0.25 mm of the 0.4 mm clearance survives. No change needed. Print the fine gauge (`README-FINE.md`) to narrow it down further. |
| 98.60 | **Zero clearance left.** A Ø98.6 shoulder is the largest this tube+printer combination will accept — it fits, but with no margin. Do not enlarge the shoulder past this. |
| 98.35 or below | The designed Ø98.6 shoulder will **not** enter this tube as drawn — the clearance has been consumed and part of the gap is now interference. Reduce `Shoulder_OD` (or find why the tube/printer differs from assumed) before printing the real part. |

**A high reading is not license to size the shoulder up to it.** Growing
`Shoulder_OD` toward the reading is exactly what consumes the clearance the
0.4 mm was there to protect — the .scad header calls that guarantee out
explicitly. The gauge's job is to catch clearance that has shrunk below
what the design assumed, not to invite spending what is left of it.

Whatever it reads, that number is the truth for your printer, your
filament and your tube together. It replaces having to separately diagnose
material shrinkage, slicer horizontal expansion, and nominal tube
tolerance — none of which you need to know if the gauge tells you the
answer directly. What it cannot do is tell you *which* of those three is
responsible.

## Other diameters

Edit the parameters at the top of `FitGauge.scad`:

```
Gauge_Target_d = 98.6;   // the diameter you are trying to hit
Gauge_Step     = 0.25;   // step between bands
Gauge_Count    = 5;      // how many bands
```

The shoulder's spigot fit into the nose cone, for example, is
`Gauge_Target_d = 96.7` (see `PeregrineNoseCone.scad` / `PeregrineCamNose.scad`,
`TestRing()`).

Set `Gauge_Mode = 1` and `Gauge_Index = 0..4` if you would rather print
separate rings than one staircase.

## Regenerating

```
OPENSCADPATH=<repo> /Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD \
  --render --export-format binstl -o out.stl -D Gauge_Mode=0 FitGauge.scad
```

For the fine gauge, add `-D Gauge_Target_d=98.975 -D Gauge_Step=0.05
-D Gauge_Count=6` (see the parameters table above).
