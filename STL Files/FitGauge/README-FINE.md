# Fine gauge — 98.85 to 99.10 in 0.05 mm steps

`FitGauge_Peregrine_FINE.stl` — 6 bands, 42 mm tall.

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

`Peregrine_Body_ID` is currently assumed 99.0 and `Shoulder_OD` derives
from it as 98.6. If the gauge says the working diameter is nearer 99.0,
the shoulder is about 0.4 mm loose and both constants want correcting at
the root, so every dependent part re-derives.
