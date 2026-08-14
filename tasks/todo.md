# PR #23 6th code-review fix pass -- Rocket 60

Branch `feature/rocket60`, worktree `wt-rocket60`. Status: **done**.

## Summary

1. **Rail retention abandoned (finding 1).** Removed the 2-rail/4-zip-tie
   scheme from `R60_EBayTube()` entirely (3rd distinct failure across
   3 review rounds -- see R60Lib.scad's "Sled retention" comment for the
   closed-form proof the rails' capturing frame had no solution).
   Replaced with a bolted bridge: `R60_VegaSled()` now spans the full
   e-bay window and bolts to both bulkheads, 2x M3 into ruthex inserts
   per end. Radial position (`R60_Vega_Facing_Y_Nom`) is now closed-form
   (deepest position clearing the tube ID), not a number that fell out of
   the retired rail math. Verified: assembly harness pairs 23/24 (flush-
   fit, real interference probes) and a new mesh-measured coaxiality
   check in `verify_rocket60.py` (foot holes vs bulkhead inserts) --
   caught and fixed a real 0.0937cm3 collision (a boss-placement bug in
   the first draft of this fix) before it shipped.
2. **Probes that cannot fail (finding 2).** Deleted pairs 16/18/20 (each
   structurally incapable of failing -- see r60_assembly.scad's own pair-
   enumeration comment for why). Pair 22's `SW_REACH` is now a stated
   hardware envelope, not derived from the board's own position (was
   circular -- see tasks/lessons.md #7). `render_probe()`'s error checks
   now run before the "empty" check, AND r60_assembly.scad asserts on any
   undispatched Pair -- mutation-tested with a bogus pair number, fails
   as expected. Tether-lug width check no longer reads the skirt's own
   OD tessellation; mutation-tested at `R60_Tether_Clear=0`.
3. **Real geometry defects.** Door boss engagement depth now derives from
   a stated functional target (6mm self-tap), asserted against the
   board-clearance ceiling, not "however much happened to be left." Door
   cover screw holes now have a real, measured wall margin (~2.1mm, was
   ~0.6mm) -- `Cover_W` derives from the larger of the overlap and
   wall-margin requirements. `S2_Y` now reads `R60_Tether_Y` directly.
4. **Tooling and docs.** Fixed the `return 1`-out-of-the-loop bug in
   verify_rocket60.py/verify_nosecone.py/verify_camnose.py's `main()`.
   Build-volume checks now report overage-past-limit instead of
   `min(actual, LIMIT)` (verify_rocket60.py, verify_nosecone.py,
   verify_camnose.py). Added `tools/verify_motordummy29.py` (previously
   no harness at all); fixed MotorDummy29.scad's genus comment (0, not 1)
   and documented the Body_OD/29.0 relationship to Pair 11's stand-in.
   Design doc's part table rewritten to the current Render_Part numbering
   and as-built dimensions (was P1-P14 stale numbering, 130mm tubes,
   55mm fin span, a superseded bayonet description). Mass model
   (`rocket60_model.py`) STL_VOL and design-doc mass/stability figures
   re-synced to the re-exported geometry (+3-4g per motor config).
   `tools/verify_camnose.py:10`'s `import math` is NOT dead (used at
   line 24) -- that specific review finding was incorrect, not applied.

## Not done / deferred

- `tools/verify_rocket60_assembly.py`'s 1mm sweep performance (243 full
  CGAL intersections). Investigated: switching to `import()`-based
  per-step invocations does not help (measured ~0.36s either way,
  dominated by per-process CGAL/Nef overhead, not CSG source rebuild).
  Unioning the whole sweep into one invocation IS ~17x faster (1.7s vs
  ~30s per stroke pair) but produced a non-empty result where the
  trusted per-step computation reads clean at every step -- a
  correctness regression risk in a verification tool, not shipped.
  Left as documented, accepted cost (full run: a few minutes).
- `verify_camnose.py:10` dead-import finding: not applied, `math` is
  used (`math.sqrt`, line 24).
- Some downstream recovery-timeline figures in the design doc (tumble/
  main descent times, drift distances) were not re-derived against the
  6th review's small mass shift -- only the rail-exit/apogee row, which
  came directly from `rocket60_model.py`'s own fresh output, was updated.

## Verification

- `tools/verify_rocket60.py`: 0 failed (full run, all 15 parts).
- `tools/verify_rocket60_assembly.py`: 0 failed (full run, all pairs incl.
  new 23/24, deleted 16/18/20 absent).
- `tools/verify_nosecone.py`, `tools/verify_camnose.py`: all checks pass.
- `tools/verify_motordummy29.py` (new): 0 failed, all 3 motor classes;
  mutation-tested (wrong Filament_Density correctly fails 3 checks).
- `tools/rocket60_model.py`: runs clean; liftoff 874/941/944g
  (G80T/H182R/H135W), margins 1.46/1.28/1.29 cal loaded.
- Parts 2, 4, 5, 6, 7 re-exported (binary STL); parts 0, 1, 3, 8-14
  confirmed BYTE-IDENTICAL to their committed STLs (unaffected by this
  round's changes).
- `r60_assembly.scad`'s dispatch-guard assert mutation-tested (bogus pair
  99 and deleted pair 18 both fail loudly, not silently pass).
- Door screw hole wall-margin check and tether-lug width check both
  mutation-tested against their own pre-fix formulas/values, confirmed
  to read the ORIGINAL review-reported defect numbers (0.659mm and
  0.000mm respectively) when reverted.
