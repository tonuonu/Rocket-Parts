# PR #23 3rd code-review fix pass — Rocket 60

Branch `feature/rocket60`, worktree `wt-rocket60`. Status: **done**, 3 commits
this session (harness, fixes, re-export+doc sync).

## Commits
- `27f6e58` Add assembly-interference check harness for Rocket 60 —
  `tools/r60_assembly.scad` + `tools/verify_rocket60_assembly.py`, built
  and proven to fail on findings 1/2 BEFORE either was fixed, per the
  task's "do this first" instruction.
- `d109e4d` Fix Rocket 60 critical, should-fix and tooling defects (3rd
  review) — findings 1-15.
- `63c3f4d` Re-export changed parts and sync published numbers (3rd
  review) — STL re-exports, STL README, print settings, design spec.

## Assembly-interference harness (do this first)

`tools/r60_assembly.scad` renders each of 12 mating pairs in their
assembled relative position; `tools/verify_rocket60_assembly.py` drives
it, intersects the pair via CGAL, and asserts zero volume (treating
OpenSCAD's "Current top level object is empty" — no output file — as a
genuine 0.0 cm³, not an error). Stroke pairs (aft bulkhead skirt and
spring carrier sliding into the chute tube) are swept across the full
0–80mm insertion range, not checked only seated.

**Proof it works**: run against the pre-fix geometry, the harness failed
on finding 1 (spring carrier notch, non-zero interference across most of
the stroke) and finding 2 (Vega rails overlapping the neck skirt/forward
bulkhead/aft bulkhead disc), with volumes matching the review's own
reported numbers, before either was touched.

**Current result — all 12 pairs pass**:

| Pair | Result |
|---|---|
| 0 neck vs e-bay tube | 0.0000 cm³ |
| 1 e-bay fwd bulkhead vs e-bay tube | 0.0000 cm³ |
| 2 e-bay aft bulkhead vs e-bay tube | 0.0000 cm³ |
| 3 Vega sled vs e-bay tube | 0.0000 cm³ |
| 4 access door vs e-bay tube | 0.0000 cm³ |
| 5 aft bulkhead skirt vs chute tube | 0.0000 cm³ across Ins=0..80mm (17 samples) |
| 6 spring carrier vs chute tube | 0.0000 cm³ across Ins=0..80mm (17 samples) |
| 7 chute tube vs fin can | 0.0000 cm³ |
| 8 motor spacer vs MMT (fin can) | 0.0000 cm³ |
| 9 tether latch vs aft bulkhead | 0.0000 cm³ |
| 10 thrust ring vs motor+spacer (forward trap) | 0.0000 cm³ flush, 0.1837 cm³ solid contact at 2mm overtravel |
| 11 motor retainer vs motor (aft trap) | 0.0000 cm³ flush, 0.1928 cm³ solid contact at 2mm overtravel |

Pairs 10/11 are inverted-polarity obstruction proofs, not clearance
checks: flush = clear (correct, the motor stack must fit), 2mm
overtravel = genuine solid contact (correct, both ends must be trapped).

## Critical (1-3)
- **1** spring carrier tether-relief notch only relieved local z 0..5,
  not the chute tube's tether lug at z 4..9 — blocked assembly and
  separation. Fixed: notch now runs the carrier's full 65mm length, with
  its radial inner bound matching the aft bulkhead's own formula (a
  first fix that only extended Z height left a residual 0.0223 cm³
  interference the harness caught — round 2 fixed the radial bound too).
- **2** Vega rails used a flat 5mm margin from both tube ends, actually
  overlapping the neck skirt/forward bulkhead (0.134/0.151 cm³) and the
  aft bulkhead disc (0.176 cm³). Fixed: rail Z window now derives
  per-end from what's actually there (`R60_AftBulk_T`/`R60_FwdBulk_T` +
  a stated 2mm clearance), with an assert against inversion.
- **3** nothing reacted the motor's forward thrust — the aft retainer
  only ever resisted aft motion, leaving a 0.3mm slip fit against the
  packed parachute under thrust. **New part 14, `R60_ThrustRing()`**:
  glues into the MMT's forward opening, Ø28.9 OD / Ø26.8 bore, 6mm
  thick, PC, `Render_Part=14`, exported to
  `14_ThrustRing.stl` (0.6 cm³), rows added to the STL README and
  `R60-PrintSettings.md`. The spacer's own length formula now stops
  short of it (`MMT_L - ThrustRing_T - Motor_L`). Obstruction proven
  both directions via harness pairs 10/11 above.

## Should-fix (4-11)
- **4/5** `verify_camnose.py`/`verify_rocket60.py`: a missing genus or an
  empty arming-switch Z scan were silently dropped/skipped instead of
  failing. Both now emit `nan`, which never falls within tolerance — a
  loud FAIL, not a quietly-absent check.
- **6** chute-bay-to-fin-can joint was a bare butt bond. Fixed:
  `R60_ChuteTube()` grows an additional Ø56.4 spigot past its own
  nominal length (180→186mm), the same coupler every other joint has.
- **7** flutter/AR comment had the direction backwards. Fixed, plus a
  fin-span check added to `verify_rocket60.py` (there wasn't one).
- **8** spec doc staleness (223mm MMT, 99mm spacer, 615m apogee,
  cam-ramped bayonet in the architecture diagram) — fixed in the 2nd
  commit; further station/mass numbers re-synced in the 3rd after
  should-fix 9's `R60_EBay_L` growth (see below).
- **9** arming-switch Z window was only 0.5mm wide. Fixed by growing
  `R60_EBay_L` 160→165mm — the window's own derivation gets 2.5mm of
  every 5mm added — giving a genuine ~3mm margin on both sides. This
  moved the total airframe length 662→667mm; the full cascade (part 2's
  own length/volume, station numbers, mass, CP, rail exit) was traced
  through and re-synced (3rd commit).
- **10** `MotorDummy29.scad`'s grip flats and ballast-fill opening were
  at the end its own comments called "aft" but which — loaded the same
  forward-closure-first way a real motor is — ends up buried ~104mm+
  deep. **Fixed by relabelling, not re-geometrying**: this is a
  body-symmetric standalone part with no orientation of its own baked
  into the STL; the builder chooses which end goes in first. Swapping
  which end the comments call "aft" vs "forward" is the complete,
  correct fix for a part like this — flagging this explicitly since it's
  a different kind of fix than the other findings, not a dodge.
- **11** zip-tie slots shared one azimuth 40mm apart in Z, so a tie
  strung between them ran entirely inside the ~15mm sled/wall gap —
  zero retention. Fixed: each Z station now gets a pair of holes at
  270°±Rail_HalfAng, straddling the sled tangentially at each rail's own
  azimuth. (An interim version that only opened the rail's outer portion
  left a thin free-hanging bridge and genus jumped to 11 instead of the
  expected 7 for 2 new holes — redesigned to sever the rail's full
  cross-section locally instead; see `Rocket60.scad`'s Tie_X0/Tie_Depth
  comment.)

## Tooling (12-15)
- **12** `scad_verify.tris()` (renamed from private `_tris`) is now
  memoised on `(path, mtime, size)` and shared by every scanner that used
  to re-parse the whole STL per call.
- **13** `measure()` returned via `TypeError` on a zero-triangle mesh;
  now returns `nan` sentinels.
- **14** `tris()` is the public entry point every caller uses now.
- **15** the "sled + Vega clears e-bay bore" check's (15.0 ±10.0) window
  couldn't fail for any plausible geometry. Replaced with a derived
  literal (8.64, computed from restated constituents) and a real ±0.5mm
  tolerance. On the double-count question specifically: re-derived the
  formula from the assembly geometry and could not find an actual
  double-count in the code as it stood — `a(6,"height")` (measured,
  T+Standoff_h) and `R60_Vega_H` (a restated hardware spec, the board's
  own total height per its own comment) are each counted once. Rewrote
  the `stack` comment to spell this out explicitly so it can't be
  misread as double-counting again, and fixed the tolerance regardless
  since that was the concrete, unambiguous half of the finding.

## Also fixed (not one of the 15, surfaced by the regression)
`tools/verify_rocket60.py`'s part-3-length check still wanted 180.0 after
part 3 grew to 186mm for should-fix 6 — a latent gap from earlier in this
review round, not itself one of the 15 findings, but a real FAIL once the
full regression was run. Fixed alongside rather than left red.

## Verification
- `tools/verify_rocket60.py`: **0 checks failed** (all 15 parts + test
  ring).
- `tools/verify_rocket60_assembly.py`: **0/12 pairs failed** (table
  above).
- `tools/verify_camnose.py`, `tools/verify_nosecone.py`: unaffected,
  all checks pass.
- `tools/rocket60_model.py`: exits 0. Liftoff 867g (G80T) / 934g (H182R)
  / 937g (H135W), margins 1.61/1.42/1.43 cal, rail exit 18.9/28.0 m/s,
  apogee 627m/10.9s (G80T) — apogee and margins unchanged from before
  should-fix 9; only length/mass/CP moved.
- Parts 2, 3, 8, 12 re-exported, part 14 new; each cross-checked against
  expected height/OD/bore/volume via `scad_verify`'s `measure()`/
  `volume()` directly on the files written to `STL Files/Rocket60/`, not
  just the `/tmp` renders used during verification.

## Not fixed / out of scope
- Noticed but not touched (not one of the 15 findings, per "report, don't
  fix" for anything discovered outside scope): the design spec's §5
  performance table's "Rail exit" column is actually populated with the
  model's `v@1m rail` figure (15.4/22.6/17.3 m/s), not the model's
  separately-reported 1.5m-rail exit speed (18.9/28.0/… m/s) — a
  pre-existing column/label mismatch, not something this session's
  changes affected.
