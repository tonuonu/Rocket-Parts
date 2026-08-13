# Fit gauge — find the diameter that actually fits

`FitGauge_Peregrine_98.6.stl` — stepped plug, 5 bands, Ø98.10 → Ø99.10 in
0.25 mm steps. 35 mm tall, ~92 mm bore. Generated from `FitGauge.scad`.

## How to use it

1. Print it in the **same material and profile** you print flight parts in.
   A gauge printed in a different filament or profile measures that
   filament and profile, not the parts you care about.
2. Offer the **small end** (Ø98.10, engraved, at the top as printed) to the
   tube and push gently.
3. It stops at the first band too big to enter. **The largest band that
   entered is your working diameter.**

## Reading the result

The Peregrine shoulder is designed at Ø98.6 into a 99.0 ID tube.

| Largest band that entered | What it means |
|---|---|
| 98.85 or 99.10 | Parts print undersize; mating ODs want increasing |
| 98.60 | Nominal is correct — the design fits as drawn |
| 98.35 or 98.10 | Parts print oversize by that much; mating ODs want reducing |

Whatever it reads, that number is the truth for your printer, your
filament and your tube together. It replaces having to separately diagnose
material shrinkage, slicer horizontal expansion, and nominal tube
tolerance — none of which you need to know if the gauge tells you the
answer directly.

## Other diameters

Edit the parameters at the top of `FitGauge.scad`:

```
Gauge_Target_d = 98.6;   // the diameter you are trying to hit
Gauge_Step     = 0.25;   // step between bands
Gauge_Count    = 5;      // how many bands
```

Rocket 60's coupler, for example, is `Gauge_Target_d = 56.4`.

Set `Gauge_Mode = 1` and `Gauge_Index = 0..4` if you would rather print
separate rings than one staircase.

## Regenerating

```
OPENSCADPATH=<repo> /Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD \
  --render --export-format binstl -o out.stl -D Gauge_Mode=0 FitGauge.scad
```
