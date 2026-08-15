# Lessons

Persistent, committed record of patterns this project's mistakes keep
following — not a per-round incident log (those live in `tasks/*-review.md`
and PR history). Written after PR #23's 5th review found the same shapes of
defect recurring across five rounds despite each round's own fixes being
individually correct. Review this file before starting review-fix work on
any part of this repo, not just Rocket 60 — the patterns are about how a
parametric-CAD-plus-verification-harness codebase fails, not about this one
design.

## 1. A restated literal silently drifts from the constant that produced it

This repo's own rule 4 ("restate as a literal in the harness, don't import
the SCAD constant") exists because Python verification code can't `include<>`
an OpenSCAD file — but every restatement is a second copy that can go stale
the moment the original changes, and nothing forces the two to be checked
against each other.

Concrete instances: `verify_rocket60.py`'s `DOOR_HOLE_Z_TUBE`/`DOOR_Z_OFFSET`
had to be hand-recomputed at each of the three `R60_EBay_L` growths
(160→165→177) because they were typed-out numbers, not a formula referencing
`R60_EBay_L`. `r60_assembly.scad`'s `PIN_BASE_L`/`PIN_D` restated
`R60_TetherLatch()`'s own `Base_L`/`Pin_d` — correct the day they were
written, silently wrong the moment the module's own formula changed under
them. A comment in `R60Lib.scad` cited "1.61 cal" and "the 1.5 cal target"
for two more review rounds after the coordinator had already retired both
numbers elsewhere in the same file tree.

**Guard against this**: when a literal is restated for a real reason (cross
file boundary, cross language), name the constant it restates in the same
comment, and grep for that constant's name whenever it changes. When a
restated value stops being *load-bearing* (the geometry it described no
longer derives from it — e.g. the arming switch moving off a Z-window
entirely), delete the restatement instead of letting it become a stale
history lesson masquerading as a current derivation.

## 2. A margin gets measured against the wrong boundary — specifically,
   a feature's centreline instead of its own radius

Twice in this project, a clearance check computed the reach of a
**cylindrical feature's centreline** to a circular boundary, and reported
that as "the margin" — when the feature has a nonzero radius, its farthest
point is the centreline reach *plus* an offset in whatever direction that
radius can bulge, not the centreline reach alone.

- The Vega rail capture gap (2nd review) was originally sized to the tube
  ID, not the rails' own *exposed, inward-of-ID* capturing surface — the
  angle was right for the wrong radius.
- The tether-latch pin's withdrawal clearance (5th review, finding 3) was
  computed as `sqrt(rim_r² − pin_offset²)` using the pin's **centreline**
  offset — reporting "1.27mm of real margin" against the spring carrier's
  counterbore rim. Correctly counting the pin's own 1.6mm radius (whose
  farthest point sits `pin_offset + pin_radius` off-axis, not
  `pin_offset`), the real margin was 0.15mm — inside print tolerance for a
  feature that has to be inserted and withdrawn.

**Guard against this**: for any cylindrical (or otherwise non-point) probe
measured against a circular/curved boundary, always add the probe's own
radius to whichever offset dimension increases distance from the boundary's
centre, and say so explicitly in the derivation comment (`+Pin_d/2`, not a
bare distance). When mutation-testing a clearance check, mutate to just past
the *corrected* ceiling, not just past the naive one — the naive ceiling
mutation ("+3.4mm") can pass a check that is still blind to the real,
much-smaller failure mode ("+0.15mm").

## 3. A check silently skips instead of failing

`if sw_zs:` (guard a computed check on a truthy scan result) and
`if not os.path.exists(out) or os.path.getsize(out) < 10: return 0.0` (treat
a missing/short render output as a pass) are the same bug shape: a check
that *should* run and *should* be able to fail instead quietly produces no
row, or a passing row, when its precondition isn't met. Both read as "OK" —
or as nothing at all — in a report that a human or CI is trusting to have
caught every real defect.

Every instance found and fixed across this project's review rounds followed
the same repair: replace the silent skip with a `nan`/`RuntimeError`-derived
sentinel that **fails loudly** (`nan` compares false against every
tolerance), and if the false-vs-true ambiguity is itself the bug (an empty
render can mean "genuinely clear" *or* "crashed silently" — see
`render_probe()`'s history), require the loud, positive signal ("Current top
level object is empty") before treating absence as success, not the mere
absence of an error string.

**Guard against this**: a harness function that reads geometry off a
rendered mesh should never have a code path that returns a "looks fine"
default when it can't find what it's looking for. Search new scanner
functions for `if not X: return 0.0`-shaped early-outs before calling them
done, not just their happy path.

## 4. Per-part verification cannot see cross-part interference

`verify_rocket60.py` checks each part's own rendered geometry against its
own expected numbers; nothing in that file can see two parts that each
individually pass every check and still physically collide once
assembled, because the collision exists only in the *relative position*
between them. This is why `tools/r60_assembly.scad` /
`verify_rocket60_assembly.py` exist as a second, structurally different
harness (render both parts in their real assembled transform, measure
`intersection()` volume) — and even that harness kept missing things
because it modelled the wrong stand-in: `Pair 3` rendered the Vega *sled*
but never the *board* sitting on top of it, so the board-vs-door-boss
collision (finding 2) went unseen for a full review round despite an
assembly harness already existing.

**Guard against this**: a per-part dimension check and an assembly
interference probe are not substitutes for each other, and neither one
substitutes for asking "what does this checked geometry actually touch,
including unmodelled hardware sitting on top of a modelled part?" When a
part carries something that isn't printed (a board on a sled, a switch's
installed envelope, a spring), the *envelope* of that unmodelled hardware
still needs its own probe against every real part it could reach — not
just the modelled carrier it sits on.

## 5. A check's tolerance is wider than the quantity it measures

`verify_rocket60_assembly.py`'s `EPS_CM3 = 0.001` was justified against the
harness's *largest* historical defects (0.02–0.42 cm³) and never checked
against its *smallest* resolvable feature. On a Ø3.2mm pin, a genuine
0.68mm-deep interference — nearly two-thirds of a millimetre of real,
solid-on-solid collision — measured only 0.0011 cm³, barely above that
threshold; anything shallower was invisible. The tolerance was sized for
the defects already found, not for the defects the checked geometry could
still produce.

**Guard against this**: size a tolerance against the smallest feature the
check has to resolve, not against the largest defect that happened to be
found so far — and get the number empirically (mutate a known-small,
just-past-threshold defect and measure what it actually produces) rather
than picking a round number that sounds conservative. A threshold justified
only by "bigger than every defect found so far" will always be retrospective
and can never bound what a *future*, smaller defect looks like.

## 6. Geometry that fits but cannot function

A design can pass every dimensional and interference check and still not
work: a slot that removes no material because the surfaces it claims to
relieve are already open by construction (the tether latch's "loop slot,"
finding 4 — the cut was exactly tangent to material that was never there);
a fastener boss sized correctly against the OD constraint but never checked
against what's on the *other* side of the wall it thickens (finding 2); an
arming switch positioned to satisfy its own Z-window in isolation, with
nobody checking whether the window's real-world purpose (a switch a human
can reach and wire) was still served once the window got squeezed to
0.5mm three review rounds running (finding 1). Each of these is a
"measures right, does nothing" failure — the same class spec 4.2 explicitly
rejected the original bayonet-release design for.

**Guard against this**: after a geometry check passes, ask what the
checked feature is *for* — can a human hand actually reach it, does the cut
remove material that was otherwise there, does the boss's other face clear
what's supposed to be inside it — not just whether its own stated dimension
matches its own stated tolerance. A dimension check proves the number; it
does not prove the number does anything.

## 7. A clearance check whose two sides derive from one constant can never fail

Distinct from pattern 5 (tolerance too wide for the smallest real defect):
here the *numbers themselves* are wrong, not just the tolerance around
them, because the "actual" and "target" sides of the comparison are not
independent measurements of two different things — they are the same
formula computed twice with a constant subtracted in between. Pair 22's
`SW_REACH` (6th review, finding 2) was `R60_Body_OD/2 -
R60_Vega_Board_Inner_Y - SW_REACH_Clear`: since `R60_Vega_Board_Inner_Y`
*is* the position of the thing being checked against, the probe's own
reach was defined to stop exactly `SW_REACH_Clear` short of the board,
by construction, for any value the board's position ever takes. Growing
`R60_Vega_H` (or the standoff height, or anything else that moves the
board) moved both sides of the comparison together and the check kept
reading a clean 2mm margin regardless. This is a different failure shape
from a check that samples the wrong location (round 6's own pairs 16/18/
20, or the tether-lug width check reading the tube's OD tessellation
instead of the notch) or one with a stale expected value (pattern 1) — the
sampling is correct and the formula is internally consistent; the defect
is that the comparison has only one true degree of freedom instead of two.

Three related shapes of "derives its own success" surfaced in the same
review round and are worth naming together: (a) an assembly clearance
whose probe reach is computed FROM the target's position (Pair 22, above)
— fixed by making the probe a stated, independent hardware envelope; (b) a
build-volume-style check whose "expected" is `min(actual, LIMIT)` — always
exactly equal to `actual` whenever the part is within budget, so a
comfortably-fitting part prints a self-comparing "177.000 want 177.000"
that looks like a no-op rather than the real constraint — fixed by
reporting the overage past the limit (0 when clear) against a stated 0;
(c) a check written during THIS fix that compared a derived quantity to
itself (`MMT_ID_EXPECT - body_od` against `MMT_ID_EXPECT - body_od`,
caught before it shipped) — fixed by comparing the measured value against
a stated target with real tolerance. All three read as passing rows in a
green report; none of them can ever produce a red one.

**Guard against this**: for any clearance/margin check, trace BOTH sides
back to their root inputs and ask whether they share a variable that
would move them in lockstep — if the "actual" side is defined as a
function of the same thing the "expected" side represents, the check
proves the arithmetic, not the geometry. The tell is a formula shaped
like `X - f(target) - clearance` compared against `target's own
position` — rewrite the probe's own reach as a stated, independent
figure (a hardware datasheet number, a fixed design allowance) so
growing the OTHER side's inputs can actually open a gap. When reviewing a
new check before claiming coverage, substitute each symbol with what it
ultimately traces to and confirm two genuinely different quantities are
being compared, not the same one under two names.

## 8. A fastener that cannot be inserted

The Vega sled's 6th-review bolted feet passed every check this harness
had: the mounting hole's own diameter was correct (bore()), the foot did
not collide with the bulkhead it bolted to (the assembly-interference
pairs), and genus even counted the hole as a real handle. All of that
proves the hole is the right SIZE, sitting in the right FINAL position.
None of it asks whether a screw can actually TRAVEL from an accessible
point to that position: the hole existed only inside the foot's own
short pad, never continuing through the board-carrying plate between it
and the tube's open end — the plate's own thickness was solid plastic at
every (x,z) that hole ever occupied, for the plate's full 112mm length.
A screw fed in from the only accessible point (deep inside the open
tube, per the module's own assembly instructions) had nowhere to enter.
Mutation test: sweeping the screw's own shank+head along its insertion
axis and intersecting against the sled's rendered mesh gave a real,
solid 3.91cm3 collision — three orders of magnitude over this harness's
own zero-tolerance threshold, not a marginal near-miss.

**Bore clearance and insertion clearance are two different checks.**
`bore(stl, zlo, zhi)` (and any dimensional check like it) answers "is
this cross-section wide enough" at a SAMPLED location. It cannot answer
"is there a continuous, sufficiently-wide passage all the way from
wherever a hand or tool can first reach the fastener to where it seats" —
that requires modelling the fastener's own swept volume (shank AND head,
since the head drags the same corridor the shank does) across its whole
travel, then intersecting that against the real assembled parts, exactly
like this repo's own mating-fit interference pairs already do for two
solids. A hole that is the right diameter everywhere it exists can still
be unreachable if it does not exist somewhere in between.

**Guard against this**: for every threaded fastener in a design, state
its ACCESS ROUTE explicitly (which face is reachable, at which assembly
step, per the real build order — not "reachable" in an abstract, empty
scene) and build the swept-insertion check from that stated point to the
seated position, not just a check at the seated position alone. When
building such a check, watch for three ways the check ITSELF can lie:
(a) reusing a UNION-cleanliness overlap value (this repo's `Overlap`,
sized for printed geometry) as the seam between the check's own head and
shank pieces will register as a false collision against real material
whenever the head is wider than what surrounds the shank there — use a
seam near-zero instead, since this is an intersection test, not a union;
(b) a sweep left at the file's default facet count ($fn) checked against
real geometry that was deliberately cut at a coarser, LOCAL $fn (common
for small bosses at odd azimuths in this repo) reads as a false collision
too — a rounder polygon is a larger-area one than a coarse one at the
same nominal diameter, and pokes past the coarse hole's own flat facets;
(c) a self-tapping fastener's pilot hole is deliberately NARROWER than
its own clearance shank elsewhere along its length (the thread is meant
to cut it) — sweeping one constant "shank" diameter the whole way treats
the material the screw is designed to displace as an obstruction. None
of these three are exotic: all three showed up writing this one check
class for a single design, and all three look identical to a genuine
defect (a non-zero intersection volume) until traced to their source.

## 9. A sweep probe's own axis/direction was assumed, not verified against the real assembly

Three probes in one review round (9th) all had the same shape: the
*geometry* they modelled was reasonable (a stated hardware envelope, a
fastener's shank+engagement) but the transform placing it in the shared
frame pointed the wrong way, so the probe swept clear, uncontested space
instead of the material it existed to check against — and rendered
"empty" (a clean pass) regardless of the real design, for reasons that
have nothing to do with the real design being clean. `SwitchProbe`
(`rotate([-90,0,0])`) swept OUTWARD from the tube wall, away from every
other part in the scene, when the stated hardware reaches INWARD —
confirmed by mutation, `SW_REACH` at 10x the real value still measured
zero. `RetainerBoltSweep` placed its own local origin at the wrong face
of the part it bears on (the INNER face instead of the EXPOSED one) with
no compensating translate, so its "engagement" segment swept 6.7mm of
open air on the wrong side of the part entirely, and the part it was
meant to check the engagement INTO (the fin can) was not even present in
the scene. This is the identical class the 8th review already fixed once
in `NutSweep_Sled` (a `rotate([-90,0,0])` vs `rotate([90,0,0])` sign
error swept the nut's own approach corridor INTO the rail instead of the
open bench space aft of it) — `SwitchProbe` did not get the same fix
applied, and `RetainerBoltSweep` was never checked at all, despite the
fix for one instance already being on record.

Getting the fix right is not just "flip the sign": for a placement that
also carries real X/Y asymmetry (a multi-boss pattern, not a plain
coaxial cylinder pair), the WRONG axis of a 180° flip does not fail
safe — it can produce a plausible-looking but spurious collision on a
correct design (confirmed: flipping `RetainerBoltSweep`'s fin-can
placement about the Y axis instead of X gave a real, non-zero 0.019cm3
"defect" at default parameters, not a clean empty result and not a
second silently-vacuous check). The two axis choices are NOT
interchangeable once the shape being placed has its own asymmetry, even
though they ARE interchangeable for a shape (like `FastenerSweep`
itself) that has none.

**Guard against this**: when a probe's `rotate([a,0,0])`/`rotate([0,a,0])`
was chosen by matching an existing idiom elsewhere in the file rather
than re-derived from the two real parts' own stated local-frame
conventions (which face is "local z=0", which direction is "into the
material"), render it and check the RESULT's own bounding box/volume
against what the real geometry's own placement comments say — do not
assume a fix already applied to one probe in the same file was
propagated to a sibling probe of the same shape, and do not assume a
result of "empty" means the check passed for the reason you think it
did. Every fix in this class needs the SAME mutation-test proof as a
brand-new check: show a stated hardware envelope well past its real
value still measuring zero before the fix, and a real, non-degenerate
collision after it, on a mutation that a correctly-aimed probe should
catch.

## Cross-references (9th review) to existing patterns above

- `verify_docs_sync.py`'s `run_model()` accepting the model's own
  regression exit code as success, and `verify_nosecone.py`'s four bare
  `bore()` calls aborting the whole report on one moved feature, are both
  pattern 3 (a check silently skips instead of failing) — not new
  shapes, just two more instances; fixed the same way (loud FAIL/`nan`,
  not a swallowed exception or an accepted non-zero exit code).
- `scad_verify.render()` trusting a caller-supplied `var` without
  checking it names a real top-level variable in the target file is also
  pattern 3's shape (a mistyped/renamed selector silently falls back to
  the file's own default part and reports success) — fixed with a static
  pre-flight check plus the same "Ignoring unknown variable" guard
  `render_probe()` already carried for the sibling bug class.
- `R60-PrintSettings.md`'s stale "1.47 cal" surviving next to an already-
  corrected "1.46 cal" is pattern 1 (a restated literal drifts from the
  constant that produced it) — the fix (`doc_has()` gaining a companion
  bold-cal staleness scan) is the general form of pattern 1's own
  "Guard against this": the gate needed to assert absence of the
  superseded value, not just presence of the current one.

## 10. An invented mechanism competed against a proven one in the same repo, and lost

Rocket 60's recovery system was designed from scratch across nine review
rounds: a spring carrier with a hand-built ball-lock (explicitly
"deliberately incomplete" -- its own rotating lock ring and sliding
plunger were never modelled, "a rotating part and a printed housing
cannot be one piece"), a shear-pin joint sized from a self-contradictory
spec (a nylon 2-56 pin's own PER-PIN shear figure, ~110-155N, restated as
"2 pins ~130N combined" -- a pair total using a single-pin number), and a
servo-released tether latch whose own actuation linkage ("a pushrod/cam/
bellcrank of some kind") was never designed either. Nine rounds of review
hardened the geometry AROUND these gaps -- real fixes to real defects --
without anyone asking whether the mechanism itself, underneath all of it,
could ever work. It could not: a spring strong enough to shear real pins
puts several hundred N of snatch into a tether latch bench-specced at
13N, and the "independent" ejection-charge backup could not back-drive a
ball-lock at all (a captive detent does not release under load by
design) -- the redesign's whole justification collapses on contact with
its own numbers.

Meanwhile the SAME repo already had a flown, proven answer: Rocket6551.scad
(2.6", single-deploy, one CS4323 spring, first built and flown before
this task started) uses a petal-deployment cage (PetalDeploymentLib.scad)
released by a rotating-lock-ring cable release (CableReleaseBBMini.scad)
-- the exact "rotating lock ring + sliding plunger" mechanism the
invented design declared out of scope, already fully designed, already
printed, already flown, in a file sitting in the same directory. Petals
never separate the airframe against a shear load at all: the spring
ejects the chute through petals a servo unlocks, so the entire "how much
force must the pins take" problem this task spent nine rounds hardening
around does not exist in the proven design, because it was never created
in the first place.

Replacing the invented system with the proven one (this transplant) was
NOT a bigger job than the nine rounds of hardening the invented one
already cost -- it was smaller: `use<>`-instantiating the donor's own
library modules at this airframe's OD needed one mesh-measured fit
decision (CableReleaseBBMini vs. CableReleaseBBMicro -- the flown family's
own Activator does not fit this bore; a render proved it in minutes) and
a station map read off the donor's own already-working Z arithmetic, not
nine rounds of discovering what a from-scratch mechanism was missing one
gap at a time.

**Guard against this**: before designing a mechanism from scratch --
especially one with moving parts (locks, latches, releases, hinges) --
search the rest of the repo (or the org's other projects) for a design
that already solves the same problem at a nearby scale. A `grep` across
sibling `Rocket*.scad`/`*Lib.scad` files for the mechanism class (spring
release, ball lock, petal deployment, cable release) costs minutes. Nine
rounds of review hardening a design's surrounding geometry is not evidence
the design itself is sound -- it is evidence reviewers were only ever
asked "does this part's own geometry do what its own comment claims",
never "does the assembled mechanism actually work, and has anyone here
already built one that does". A part that is explicitly documented as
"deliberately incomplete" or leaving a "companion piece... out of this
task's scope" is not a stated limitation to design around -- for a moving
mechanism, it is very often the one piece that decides whether the whole
thing works at all, and is exactly where a proven design already has a
real answer to copy instead of invent.

## 11. A transplanted mounting bolt circle was the DONOR's own internal
## joint, not a host-mount feature -- and nothing checked it

The petal-deployment transplant (lesson 10) correctly moved the release
catch (`CableReleaseBBMicro.scad`) into Rocket 60 wholesale, but the aft
bulkhead's own mount to `CRBBm_Activator()` (part 15) was invented, not
transplanted: it bolted 3x M3 to `CRBBm_BottomBoltCircle_d()`, a name
that sounds like a host-mount radius but is actually the Activator's own
INTERNAL joint to its neighbour (`CRBBm_TopRetainer()`, 22.5mm away in
the real, proven stack) -- on the wrong face, sized for the wrong screw
standard (#4-40, not M3, 0.16mm off). This survived because the harness's
own pair-enumeration comment had already written off parts 15-23 as a
"known gap" -- true of the REST of the internal release chain, but not
of part 15's OWN mount, which is exactly the joint a from-scratch
integration is most likely to get wrong (lesson 10's own point, one
layer deeper: even a proven library's SHARED parts can be joined to the
new host incorrectly, in a spot the "known gap" language quietly stopped
looking).

**Guard against this**: when a "known gap" comment excuses a class of
checks as future work, re-read it every time a NEW part in that class
gets its own novel mounting feature (not just the internal joints the
donor library already proves against itself) -- the new interface is
precisely the one thing the donor's own history cannot vouch for. Found
by actually rendering the shared library part and measuring which
feature it presents at the mating face, not by trusting a bolt-circle
accessor's own name.

Found and fixed together (10th review): the real host-mount feature
(`CRBBm_Activator()`'s own `EBay_TopPlate()` ring, at the part's aft-most
local Z) needed 2 new accessor functions in the donor file
(`CRBBm_EBayTopPlate_BC_d()`/`_BossAz()`, additive only, mirroring the
existing `CRBBm_BottomBoltCircle_d()` idiom) to reach from outside it;
clocking the Activator to clear the bulkhead's own shock-cord/rod-pocket
holes needed a real 0-360deg clearance scan, not an eyeballed rotation
(the unrotated position missed by 3.3mm, a real, mutation-tested
collision -- `tools/r60_assembly.scad` Pairs 33/34, `R60Lib.scad`'s
`R60_Act_Clock_a`); and every station downstream of the activator in
`tools/rocket60_model.py` (the whole release-stack-to-petal-hub chain)
turned out to share the SAME wrong-zero-gap assumption the SCAD mount
bug had, caught by a closure check (does the chain's own far end land on
the fin can it is stated to spigot into?) that failed loudly (23.5mm
short) before the fix and closed cleanly after it.

Mutation-tested at every layer, not just the SCAD render: the assembly
pair at the OLD implied placement (3.7cm3 real collision), the fastener
sweep at the OLD bolt circle (0.57cm3, "no free hole to bolt to" made
concrete), the clocking-clearance assert at the unrotated position
(3.3mm, matching the pair's own collision), and the Python closure
check at `ACT_MOUNT_GAP=0` (23.5mm short) -- four independent proofs
that would have caught this on its own, all previously absent.
