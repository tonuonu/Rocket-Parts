# Fine gauge — 98.85 to 99.10 in 0.05 mm steps

`FitGauge_Peregrine_FINE.stl` — 6 bands, 42 mm tall. Generated from
`FitGauge.scad` with `-D Gauge_Mode=0 -D Gauge_Target_d=98.975
-D Gauge_Step=0.05 -D Gauge_Count=6`.

Follows up the coarse gauge, where 98.10/98.35/98.60/98.85 all entered
cleanly and 99.10 went tight. The answer lies in that 0.25 mm gap, so this
sweeps it at 0.05 mm.

```
   98.85   ← known GOOD from the coarse gauge (offer this end first)
   98.90
   98.95
   99.00
   99.05
   99.10   ← known TIGHT from the coarse gauge (on the bed)
```

The two endpoints are deliberately the ones you already tested. If they do
not reproduce the same feel this time, the print differed — not the tube —
and the run should be repeated before trusting the middle four.

## Caveat worth knowing

0.05 mm is at the edge of what FDM resolves in XY. Adjacent bands may feel
identical. That is itself a useful result: it means anything in that range
works, and you should take the middle for margin rather than chasing a
number the process cannot hold.

## Reading it

The largest band that still slides in without forcing is your working
diameter. Note whether it needs the band below as a lead-in — a fit that
only starts because a smaller step guided it is too tight for a part you
have to assemble under field conditions.

## What it feeds

`Shoulder_OD` (98.6) is `Peregrine_Body_ID` (99.0) minus a deliberate 0.4 mm
diametral clearance, not the tube's own ID (see `PeregrineNoseCone.scad`).
This gauge sweeps 98.85–99.10 — all of it *above* the 98.6 design target —
so a reading anywhere in this range means clearance survives:

- Near 99.10: the printer is close to dimensionally accurate for this tube;
  the full 0.4 mm clearance (or more) is available.
- Near 98.85: about 0.25 mm of the 0.4 mm clearance survives.

**Neither end says to move `Shoulder_OD`.** A reading in this range is a
good result and needs no correction — raising `Shoulder_OD` toward it would
spend the margin the 0.4 mm was there to protect. The result that *would*
need root-cause correction is a reading **below** 98.60 (not reachable by
this gauge — that is what the coarse gauge's 98.10/98.35/98.60 bands are
for): it would mean the designed shoulder does not fit this tube at all,
and the fix is finding out why the tube/print combination differs from
assumed, not copying the gauge number into `Shoulder_OD`.
