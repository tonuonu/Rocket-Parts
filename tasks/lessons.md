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
