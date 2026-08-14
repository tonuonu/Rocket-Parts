# PR #23 4th code-review fix pass — Rocket 60

Branch `feature/rocket60`, worktree `wt-rocket60`. Status: **done**, 3 commits
this session (harden harness, fix defects, re-export+doc sync).

## Commits
- `dce313e` Harden the Rocket 60 assembly-interference harness — the 7
  harness gaps named in this round's task, proven against pre-fix
  geometry BEFORE any fix landed, per the task's "do this first"
  instruction.
- `a95912c` Fix Rocket 60 critical and should-fix defects — findings 1-12.
- `53bf936` Re-export changed parts and sync published numbers.

## Harness hardening (do this first)

1. **Per-part connected-component check.** New `components()` in
   `tools/scad_verify.py` (union-find over triangle vertices, rounded to
   1e-4mm). Genus cannot distinguish "one stepped tube" from "a tube plus
   a loose ring" — both are unions of simple closed surfaces with the
   same Euler characteristic arithmetic regardless of how many pieces
   they are. **Proof**: rendered against the pre-fix `Rocket60.scad`
   (git HEAD at session start), part 3 (chute tube) read
   `components()==2`; every other part read 1. Wired into
   `verify_rocket60.py`'s generic per-part loop for all 15 parts.

2. **Completed pair matrix.** `r60_assembly.scad` now carries a full
   pair-enumeration comment block, read off each module's own stated
   mating relationships, not hand-listed — every part 0-14 is accounted
   for, with excluded pairs justified (test ring/nosecone/camera/Vega
   board/MotorDummy are external or non-modelled; fin-can/retainer/
   thrust-ring/fin pairs are plain concentric or prismatic fits already
   fully covered by `verify_rocket60.py`'s own dimensional checks with no
   off-axis feature a probe would add rigor to). Five new pairs (12-16):
   - **Pair 12** (tether latch vs spring carrier): pre-fix **0.0973cm³**,
     matching finding 2's own reported number exactly.
   - **Pair 13** (tether latch vs chute tube, stroke): a collision
     discovered while diagnosing finding 2, not one of the original 15 —
     the same off-axis base corners that hit the carrier also reach
     0.57mm past the chute tube's own bore. Pre-fix: 0.0026cm³.
   - **Pair 14** (spring carrier vs aft bulkhead): enumeration
     completeness (both bond the same face the latch does).

3. **Moving-element path check.** Pair 15: a probe-only solid standing in
   for the servo-2-horn/pin-release actuation path, vs. the tether latch.
   Pre-fix: **0.36cm³** solid collision (the latch's base entirely sealed
   the opening the bulkhead's own horn slot was extended through).

4. **Modelled switch.** Pair 16: a probe-only solid — the SAME cylinder
   `R60_EBayTube()` cuts for the real hole — vs. the access door.
   Pre-fix, at the old geometry's own switch Z (135.5mm): **16.3mm³**,
   matching finding 3's own reported number exactly. Positioned via new
   `switch_hole_z()` (`verify_rocket60.py`), MEASURED off part 2's
   rendered mesh, not a second restated formula.

**All four pre-fix numbers were verified by rendering the new harness
against the actual pre-fix `Rocket60.scad`/`R60Lib.scad` (git HEAD), not
asserted from the review text.**

5. `:58` sweep — was a fixed 5mm grid while the comment claimed a
   "closing to 1mm near the transition" refinement that did not exist.
   That scheme cannot catch a jam invisible at 5mm (no hit to refine
   around). Now a genuine, unconditional 1mm sweep (`INS_SWEEP`, 81
   samples/stroke pair) — full 17-pair matrix runs in ~90s.
6. `:115` `measure_facing_y()` called `render()` outside any try/except.
   Fixed (and the new `measure_switch_z()` built with the guard from the
   start) — a failed render now drops only the affected pair(s).
7. `:25` dropped unused `math`/`tris` imports.

Folded in here (shares the file with `components()`): `scad_verify.py`'s
`_tris_cached` bounded to `maxsize=8` (was unbounded) — should-fix 13.

## Critical (1-5)

1. **Chute tube exported as two disconnected solids.** Fixed with a
   short (2mm) internal weld ring bridging the wall to the spigot's own
   OD/ID, built *inside* the tube's existing length. `components()`
   confirmed 2→1; genus unchanged (4). A first version of the ring
   extended 0.05mm past the tube's own boundary and fouled the fin can's
   forward tip once assembled (0.0147cm³, caught by pair 7) — fixed by
   ending the ring flush instead.
2. **Tether latch base collided with the spring carrier** (0.0973cm³,
   matching the review) **and, newly discovered, the chute tube's own
   bore** (0.57mm past it). Both off-axis on the same shared mount face —
   no round counterbore can clear an off-axis rectangle without exceeding
   the carrier's own OD. Fixed by clipping the latch's own geometry to a
   circle (r=24.9mm) centred on that axis instead of growing the
   counterbore.
3. **Switch hole overlapped the door cover.** `Sw_Z0` now counts
   `R60_Door_Overlap`; `R60_EBay_L` grown 165→177 (closed-form) to
   restore a genuine ~3mm window.
4. **Tether lug/spring tabs embedded** into the wall (`Wall_Fuse_R`
   =1.2mm, same idiom as the existing rail/boss overlap constants) — 3
   tabs now give 4.5MPa under the spring's 130N target (was 57MPa).
5. **Servo-2 horn slot no longer sealed** by the latch's base — cut a
   pass-through sized to the gap *between* the two posts (10mm, narrower
   than the bulkhead's full 24mm slot on purpose, so the posts' own base
   support for the pin load isn't undermined). The actual pin-release
   actuator remains an explicitly declared, unmodelled companion piece,
   matching `R60_SpringCarrier()`'s own precedent.

## Should-fix (8-14)

- **8** `R60_FinCanSpigot_L` now derives from the fin can's own open
  annulus (`R60_FinCan_FwdOpen_L`, shared) minus a stated 0.5mm axial
  clearance, instead of a second independently-typed "6" that was a bare
  tangency.
- **9** stale zip-tie-slot comment (claimed an "outer only" cut design
  the code doesn't build) rewritten to match the actual full-cross-
  section cut.
- **10** thrust ring station fixed `TOTAL-T/2` → `S_FIN+T/2` (it glues
  into the fin can's forward opening, not the nozzle end).
- **11** spring-carrier and aft-bulkhead+skirt stations re-derived from
  where their geometry actually sits once assembled (was off by 39.5mm
  and 14mm from their true midpoints). **This drops the reported G80T
  static margin from an inflated 1.61 cal to a true 1.53 cal** — still
  clears the 1.5 cal gate, but by only 0.03 cal, not 0.11. No fin/span
  change was made on the strength of this alone — see "Stability margin"
  below.
- **12** `TOTAL` now counts the neck's own 5mm flange (previously
  omitted). Physical stack 94+5+177+180+228=684mm.
- **13** `scad_verify.py`'s `_tris_cached` bounded (see harness section).
- **14** design spec's stale "MMT (223mm)"/"99mm spacer" corrected to
  228mm/98mm, matching `R60_MMT_L`'s own (already-fixed) derivation.

## Stability margin — read this before flying the G80T

The previously-published **1.61 cal** static margin was inflated by two
uncaught station bugs (should-fix 11): the aft-bulkhead+skirt and spring
carrier CG stations were never derived from where their own geometry
sits once assembled, pulling reported CG ~3.7mm forward of reality. The
corrected figure, after also applying critical 3's `R60_EBay_L` growth
(which moves CP aft and largely offsets the CG error), is **1.53 cal** —
still clears the 1.5 cal gate, but with a 0.03 cal margin, not 0.11. This
was reported, not patched around by growing fin span further (per the
task's own instruction not to improvise a fix for a gate that still
passes). Anyone changing aft mass or fin span in future work must re-run
`tools/rocket60_model.py` rather than assume the old headroom exists.

## Verification (mesh, not reasoning)

- `tools/verify_rocket60.py`: **0 checks failed** (all 15 parts + test
  ring, including the new connected-component check on every part).
- `tools/verify_rocket60_assembly.py`: **0/17 pairs failed**, ~90s
  runtime (full 1mm stroke sweep, 3 stroke pairs).
- `tools/verify_nosecone.py`, `tools/verify_camnose.py`: unaffected, all
  checks pass.
- `tools/rocket60_model.py`: exits 0. Liftoff 871g (G80T) / 938g (H182R)
  / 941g (H135W), margins **1.53**/1.34/1.35 cal, rail exit 18.9/27.9
  m/s, apogee 624m/10.9s (G80T).
- Parts 2, 3, 13 re-exported (`openscad --export-format binstl`) and
  cross-checked with a standalone binary-STL reader against the ASCII
  renders `verify_rocket60.py` itself used — genus/components/dimensions
  match in both.

## Not fixed / out of scope

Noticed while re-deriving should-fix 11's station formulas, not one of
the 15 listed findings — same "never derived from assembled geometry"
defect class, but not touched, per "report don't fix" for anything
outside the review's own scope:

- `tools/rocket60_model.py`'s tether-latch station (`S_EBAY+L_EBAY-5`
  ≈254mm) vs. where the latch's own geometry sits once assembled
  (≈S_CHUTE+23mm ≈300mm) — roughly 28mm off.
- The CS4323 spring's station (`S_CHUTE+40`) vs. a rough estimate of
  where it actually sits (≈S_CHUTE+59mm) — roughly 19mm off, though this
  one is inherently fuzzier (the spring's own compressed/uncompressed
  state during flight isn't modelled at all).

Neither materially changes the sizing-case margin (0.03 cal headroom is
tight, but a ~4-5g item moving ~20-30mm shifts CG well under 0.1mm) —
flagged for a future pass, not fixed here.

**Tether latch pin serviceability (harness item 3's "pin", unverified).**
Harness item 3 names three moving elements -- "servo horn, pin, cord".
This round covers the horn (pair 15) and the cord path is already
covered by existing lug/notch checks + the full-stroke pairs 6/13 (see
`r60_assembly.scad`'s own enumeration comment). The PIN itself -- the
"3mm steel dowel, not printed" that is the tether latch's actual load
path -- is not checked by anything: its own bore
(`Base_L+2=40.6mm`, centred) implies at least that much clear axial
travel to insert or withdraw it, and nothing here confirms that travel
is actually free once the spring carrier is bonded on around it (the
carrier's own counterbore, r=25.5mm, is far short of the ~20mm+ the pin
would need to travel to one side). This may mean the pin cannot be
withdrawn/re-inserted after the carrier is permanently bonded -- a
possible one-shot-assembly defect, not confirmed. Flagged in
`r60_assembly.scad`'s own comment block; no redesign attempted.
