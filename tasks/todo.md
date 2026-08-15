# 9th review fixes (PR #23) — todo

Worktree: wt-rocket60, branch feature/rocket60. Do NOT touch the 4 protected
STLs (09_FinCan.stl, 10_Fin.stl, 00_TestRing.stl, NoseCone.stl).

## Order (advisor-approved)
1. [x] scad_verify.render(): add "Ignoring unknown variable" guard + static
       var-name preflight check. Mutation confirmed: var="Render_Prat" typo
       used to silently render part 0 (genus 4) instead of raising; now
       raises immediately.
2. [x] SwitchProbe sign flip (r60_assembly.scad) — rotate([90,0,0]).
       Mutation confirmed: -D SW_REACH=100 was empty before, now 2.37cm3.
3. [x] RodSweep_Sled Engage extension — now reads R60Lib's
       R60_Vega_RodLength directly (shared constant with rod BOM).
       Mutation: shared -D RodPocket_Depth=0 stays near-zero (correct,
       not circular-bug); DECISIVE mutation (hardcoded pocket cut 3mm,
       constant untouched) gives real 0.0908cm3 collision. Pairs 25/26
       clean at defaults (0.0/2e-8 cm3).
4. [x] RetainerBoltSweep frame fix — translate([24,0,6]) rotate([180,0,0]);
       Pair30_B unions in rotate([180,0,0]) R60_FinCan() (NO translate --
       retainer z=0 coincides with fin can's own aft tip per
       rocket60_model.py's own station-audit comment). First attempt
       (translate([0,0,6]) on fin can) was WRONG -- caught by mutation
       test itself (0.0626cm3 at defaults, no mutation needed). Y-axis
       flip alternative empirically WRONG too (0.0191cm3 spurious at
       defaults, misaligned boss azimuth). Decisive mutation (Insert_h
       6.7->3.0): 0.1008cm3 real collision; reverted, defaults clean
       (0.0 cm3). Full pairs 0-32 regression: 0 failures.
5. [x] verify_docs_sync.py: run_model() propagates model rc==1 as a FAIL
       row now. Mutation confirmed: MIN_MARGIN_CAL 1.0->2.0 makes model
       exit 1 (3 checks failed); unfixed script printed all-OK, exit 0;
       fixed script now prints the FAIL row and exits 1. Reverted.
6. [x] verify_docs_sync.py: stale_bold_cal() added (scoped to bold
       two-decimal "X.XX cal" figures). This caught a LIVE bug: R60-
       PrintSettings.md had "**1.47 cal**" (stale) surviving next to the
       corrected "**1.46 cal**" — real mutation evidence, not synthetic.
7. [ ] verify_nosecone.py: 4 bare bore() calls need safe() wrapping
       (move safe() to scad_verify.py from verify_rocket60.py, both import)
8. [x] Rod length DONE: R60_Vega_RodLength derived in R60Lib.scad
       (152.8mm, shares all 4 terms with RodSweep_Sled's Engage), echoed.
       R60-PrintSettings.md step 3 now states "cut to 150-152mm" with
       explicit ceiling reasoning (>152.8 = bulkhead can't seat).
       doc-sync gate checks it via render+echo-scrape (vega_rod_length()).
       Mutation confirmed: RodPocket_Depth 8.0->15.0 shifts derived value
       to 159.8mm, gate correctly FAILs (missing '159.8 mm'); reverted,
       clean pass. NOTE: deviated from review's ~151mm estimate (nut sits
       AROUND the rod inside AftClear, not as an extra 3mm segment) —
       152.8mm is geometrically derived, matches RodSweep_Sled's own
       Engage exactly — noted in final report.
9. [x] Stale comments fixed: Rocket60.scad:1238-1239 (959->955, 3.0x->
       4.9x), R60Lib.scad ~595 (1.45->1.46), ~601-607 (annotated 1220/802
       as pre-correction, not re-verified), Rocket60.scad ~1514 (blind-
       channel claim was FALSE — fixed, matches GENUS[13]=5 "tunnel"),
       rocket60_model.py motor-retainer row (681/+27 -> 687/+33) and
       "every correction moves CG AFT" claim (2 places) -> except access
       door, with reason.
   Docs fixed: R60-PrintSettings.md 1.47->1.46 cal (x2), 959->955 (x2 at
   ~160, ~506), 1.53x->1.52x. verify_docs_sync.py: 0 failures after.
10. [x] verify_docs_sync.py: added SCOPE note in module docstring — why
       .scad free-prose comments are outside the doc-sync net
11. [x] Hygiene DONE: shortfall() moved to scad_verify.py, verify_camnose
        uses it; bore() gets r_lo=0.0 param+cache key, bore_annulus()
        deleted, call site updated; safe() moved to scad_verify.py (both
        verify_rocket60.py and verify_nosecone.py import it);
        verify_nosecone.py's 4 bare bore() calls now safe()-wrapped
        (mutation confirmed: moved SHOULDER_SPIGOT_BAND crashed whole
        script pre-fix, now 2 counted FAILs, rest of report prints);
        hole_azimuth_at_r() circular mean via unit vectors (numeric
        mutation confirmed: [179,-179] plain-mean=0.0, fixed=180.0; full
        verify_rocket60.py regression 0 failures); mkdtemp cleanup added
        (try/finally+shutil.rmtree) to verify_rocket60.py,
        verify_rocket60_assembly.py, verify_motordummy29.py only — dir
        counts confirmed stable across repeat runs. camnose/nosecone have
        the same latent mkdtemp gap, left alone (out of scope, noted in
        final report).
12. [x] Full regression: rocket60_model.py, verify_docs_sync.py,
        verify_rocket60.py, verify_nosecone.py, verify_camnose.py,
        verify_motordummy29.py, verify_rocket60_assembly.py (all 33
        pairs) — 0 failures across every script.
13. [x] git status check: only .scad comments, R60Lib.scad (one new
        constant), R60-PrintSettings.md (prose), and tools/*.py changed.
        No .stl touched at all — 4 protected STLs untouched.
14. [x] tasks/lessons.md: added lesson 9 (probe axis/direction assumed,
        not verified — SwitchProbe + RetainerBoltSweep, cross-referencing
        the 8th review's NutSweep_Sled fix) plus a "Cross-references"
        section mapping verify_docs_sync/verify_nosecone/scad_verify.render
        fixes to existing pattern 3, and the doc staleness fix to pattern 1.
15. [ ] Commit (no attribution lines), push branch

## Key derived numbers (for reference)
- R60_Vega_Rail_L = AftTip_Y - FwdTip_Y ≈ 133.1
- Rod length = RodInsert_h(6.7) + Rail_L(133.1) + Rail_AftClear(5.0) +
  RodPocket_Depth(8.0) ≈ 152.8mm (NOT the review's ~151 — nut sits AROUND
  the rod inside AftClear, not as a separate 3mm segment; note deviation
  in final report)
