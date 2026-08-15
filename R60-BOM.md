# Rocket 60 — Hardware Bill of Materials

**Date:** 2026-08-15
**Spec:** `docs/superpowers/specs/2026-08-13-rocket60-design.md`
**Method:** every quantity below was counted from the geometry that actually gets
printed (`Rocket60.scad`, `R60Lib.scad`, `CableReleaseBBMicro.scad`,
`PetalDeploymentLib.scad`, `R65Lib.scad`), not copied from a donor library's own
`***** Hardware *****` header comment. Two of those header comments turned out to be
stale — see the flags below — and one hole pattern turned out to be unmated (present
in the mesh, nothing bolts through it). Where OpenSCAD's own `echo()` gives an exact
number it is quoted; where a length is derived from a stack-up it is shown as
`term + term = length`; where nothing in the source states a figure it says so.

Rendered with `/Applications/OpenSCAD-dev.app` 2026.07.09 against this branch's
`Rocket60.scad`/`R60Lib.scad`. Confirmed by direct echo:

```
ECHO: "R60_Vega_RodLength (M3 rod, cut length): 152.8 mm"
ECHO: "R60_ReleaseRodLen (#10-24 all-thread, pin->rod->piston): 58 mm"
```

**Read this before ordering anything: two donor library header comments in this
repo are wrong for the hardware they actually cut.** `CableReleaseBBMicro.scad`'s own
`***** Hardware *****` block says 5/16in Delrin balls, an MR84-2RS bearing and a
6705-2RS bearing — the file's own live top-of-file constants (confirmed independently
by `R60Lib.scad`'s own restated `R60_Ball_d`/`R60_LockPin_d`) build 6mm balls, an
MR63-2RS lock bearing and a 6703-2RS main bearing instead. `PetalDeploymentLib.scad`'s
header claims 3× #4-40 SHCS bolt the petal hub down; this design's hub has that exact
hole pattern in its printed mesh but nothing bolts through it (the petals have no
matching holes) — 0 screws, not 3. **§1 and §3 below are counted from the code, not
either header — order from this table, not from opening the `.scad` files and reading
their own comments.**

**Update (2026-08-15, coordinator-authorised fixes):** three items previously reported
here as defects, not fixed, are now fixed in geometry (§1's part-25 screw length, §4's
forward rail-button boss, and §9's spring-seat clearance) — see each section for the
mutation-tested proof. The aft rail button remains an open item — see §4.

---

## 1. Release mechanism (`CableReleaseBBMicro.scad`, ×1 assembly)

**The file's own header hardware block is stale.** Its own revision-history line
(0.9.4, 11/10/2025) says so directly: *"Smaller and smaller 6mm balls 6703 bearing"*
— a change made after the header comment was last edited. `R60Lib.scad`'s own
`R60_LockPin_d`/`R60_Ball_d`/`R60_nBalls` constants (lines 710-713) independently
confirm this design uses the file's live "Smallest" parameter block, not the header.
Quantities below are the header's own stated "Req" counts (spot-verified where noted);
**sizes are read from the file's own top-of-file constants, not the header text.**

| Item | Header says | **Actual (live code)** | Qty | Used for |
|---|---|---|---|---|
| Ball | 5/16" Delrin (7.938mm) | **6mm ball** (`Ball_d=6`) | 3 | Ball-lock detent, holds the locking pin captive |
| Lock bearing | MR84-2RS (4×8×3) | **MR63-2RS (3×6×2.5)** (`LockBearing_*=BearingMR63_*`) | 3 | One per ball, low-friction detent race |
| Dowel pin | 4mm dia × 16mm | **3mm dia × 16mm** (`Dowel_d=LockBearing_ID=3`, `Dowel_Len=16`) | 3 | One per ball position, locates the lock bearing |
| Main pivot bearing | 6705-2RS (25×32×4) | **6703-2RS (17×23×4)** (`Bearing_*=Bearing6703_*`) | 1 | Lock-ring rotation bearing |
| Threaded rod | #10-24 | #10-24 (confirmed, `Thread1024_d=0.190"` major dia) | 1 | **58mm** — pin→rod→piston tension member (echoed exactly, see below) |
| Magnet | 3/16" × 1/8" N42 | 3/16" × 1/8" N42 (confirmed, `Magnet_d=3/16"`, `Magnet_t=1/8"`) | 2 | Magnetic over-centre catch |
| MG90S micro servo | 1 | 1 (confirmed) | 1 | Drives the lock ring |
| #4-40 × 1/4" BHCS | 4 Req | **Verified exact**: `CRBBm_MagnetBracket()` 2 + `CRBBm_TriggerPost()` 2 (both non-looped `Bolt4ButtonHeadHole()` call pairs) | 4 | Magnet bracket + trigger post mounts |
| #4-40 × 1/2" BHCS | 3 Req | Plausible, not individually re-traced past the header (loop counts `nBottomBolts=3`/`nLockRingBolts=3` are consistent with a 3-screw joint existing) | 3 | Release-stack joints |
| #4-40 × 3/8" SHCS | 3 Req | Same caveat as above | 3 | Release-stack joints |

**#10-24 release rod, 58mm** — echoed directly from `R60Lib.scad`'s own
`R60_ReleaseRodLen`, a four-term stack: locking-pin engagement (15mm) + extension rod
(26mm) + piston thread engagement (4mm) + BBMicro's shorter-pin free-span allowance
(13mm) = 58mm, "inside the review's own stated 55-60mm window — bench-adjustable."

**Additional joint, not in the header at all — length now resolved.** Part 25 (our own
spring centering ring mount, §2 below) bolts to part 16 via `CRBBm_MountingBoltPattern`
(3× #4-40 positions). This mount does not exist in the donor's own design the header
describes, so it is additive to the header's stated 10 (the header undercounts its own
base design by exactly one 3-bolt joint, independent of this addition — see the note
below). **Length, mesh-measured, not guessed**: part 25's own clearance cut
(`Bolt4ButtonHeadHole()`, `CableReleaseBBMicro.scad`) passes through its own 6mm
`Thickness`; the two parts sit **1.2mm apart** at their real assembled offset
(`tools/r60_assembly.scad`'s own Pair 38, cross-checked by rendering both parts at
that pair's real relative transform: part 25's mating face lands at z=−12.7, part 16's
nearest face at z=−11.5); part 16's own tapped boss is bounded by its `Flange_t=4mm` —
material beyond that is open interior, not more thread. Total reach before running out
of tapped material: 6+1.2+4=11.2mm. **#4-40 × 3/8" (9.525mm) BHCS** gives 9.525−7.2=
**2.325mm of engagement** — thinner than this design's usual ~5mm target (the joint's
own geometry, not a choice, bounds it there), but real, and comfortably clear of the
11.2mm ceiling. **Do not go to 1/2" (12.7mm)**: 12.7−7.2=5.5mm exceeds the 4mm flange
outright — it would punch through into the rotating lock-ring/trigger-post envelope
beyond, the worse failure (a screw that never seats and clamps, vs. one with thin but
real engagement).

**The header undercounts its own base design by one joint, independent of the above.**
Tallying every distinct #4-40 joint in the release stack by module (not just the
header's own 3 "Req" lines): LockRing↔TopRetainer (3), OuterBearingRetainer↔TopRetainer
(3, `Bolt4HeadHole`), CenteringRingMount↔TopRetainer (3, `Bolt4ButtonHeadHole` — this
design's own part 25 above), magnet bracket + trigger post (4, verified exact) = **13**,
not the header's 10. The header's "3× SHCS" and "3× BHCS" lines cover only two of the
three 3-bolt joints; which one they miss was not traced further, since part 25's own
joint (this design's own addition) is accounted for above regardless.

---

## 2. Our own release-stack addition

| Item | Spec | Qty | Used for |
|---|---|---|---|
| CS4323 compression spring | 8in free length, 1.75in OD, 1.606in ID, 12 coils, 0.82 lb/in | 1 | Primary ejection spring — see §9 (Task 2) for the closed force question and the seat-clearance fix |
| #4-40 × 3/8" (9.525mm) BHCS | see "Additional joint" above — ~2.3mm engagement, does not bottom | 3 | Seats the spring (part 25), bolts to part 16 |

---

## 3. Petal deployment (`PetalDeploymentLib.scad` + `R65Lib.scad`'s `R65_PetalHub`, ×3 petals)

**One header line does not apply to this design.** `PetalDeploymentLib.scad`'s header
lists *"#4-40 x 3/8" SHCS (3 req) PetalHub"* — but this design's hub is `R65Lib.scad`'s
`R65_PetalHub()`, not `PetalDeploymentLib.scad`'s own `PD_PetalHub`. `R65_PetalHub()`
(R65Lib.scad:1149-1211) **does** cut `PD_PetalHubBoltPattern(OD=OD, nBolts=nPetals*2)`
— 6 real `Bolt4ClearHole()` holes in the printed mesh — but `PD_Petals()` (part 13)
"has no axial holes at all" (spec §3.2, part 13's own row), confirmed by reading
`PD_Petals()`'s own source: nothing in this design bolts through those 6 holes. **They
are real, printed, and unmated — 0 screws, not 3.** The hub is glued (spigot) into the
fin can instead (spec §4.1).

| Item | Spec | Qty | Used for |
|---|---|---|---|
| #4-40 × 1/4" BHCS | header confirms; `PD_Petals()`'s only 2 holes per petal, tapped 7mm/9.5mm into `PD_PetalSpringHolder()`'s own pilot (self-tap, not an insert) | 2 per petal × 3 = **6** | Bolts each petal's only holes to its `PetalSpringHolder` hinge (part 24) |
| Hinge preload spring | `PD_PetalSpringHolder()`'s own `Spring_d=5/16*25.4=7.9375mm` OD, ~19mm pocket | 1 per petal × 3 = **3** | Preloads each hinge open; pops the petal's lock nubs when driven |
| ~~#4-40 × 3/8" SHCS (hub)~~ | header only, unmated in this build | **0** | — |

**Spring flag**: the donor header calls this same spring "CS3715 (0.3in dia × 1.25in)."
0.3in = 7.62mm vs the code's literal `5/16*25.4` = 7.9375mm — a 0.32mm difference, close
enough that CS3715 is probably still the intended off-the-shelf part, but this was not
independently confirmed against the full hub+holder cavity depth (the holder's own
pocket alone is ~19mm, short of CS3715's stated 1.25in/31.75mm free length — the
remainder may be inside the hub's own mating boss, not traced here).

---

## 4. Our own — airframe hardware

| Item | Length derivation | Qty | Used for |
|---|---|---|---|
| M3 SHCS | 5.0mm grip (neck flange) + 5.0mm engagement (camera's own ruthex insert, not ours) = **M3×10** | 3 | Neck (part 1) → camera assembly. Insert already exists in the purchased camera — nothing to insert here. |
| M3 threaded rod, all-thread | **152.8mm**, echoed exactly (`R60_Vega_RodLength`: 6.7mm insert engagement + 133.1mm rail span + 5.0mm aft clearance + 8.0mm pocket depth) | 2 | Vega sled rails — fwd end is a permanent stud, aft end floats in a guide pocket |
| ruthex RX-M3×5.7 insert (Ø4.0×6.7mm blind boss) | — | 2 | Fwd bulkhead (part 4) — anchors the 2 sled rods. **Not** "2 per end" as spec's part-6 table row states — that predates the 7th-review fix; the aft end is an unthreaded guide pocket, no insert |
| M3 hex nut + M3 washer | — | 2 + 2 | Captures the Vega sled at the rail's aft face (stated in source: nut ~2.4mm + washer ~0.5mm, not modelled dimensionally) |
| M3 screw | 8mm clearance stack (4mm standoff + 4mm sled plate) + ~1.6mm PCB + nut ⇒ **M3×16** (recommend; verify against real board thickness) | 3 | CATS Vega board → its own printed standoffs on the sled (L-pattern A/B/C) |
| M3 nut | — | 3 | Captures the Vega board screws (Hole_d=3.4mm is a plain clearance bore the full 8mm stack, not a threaded boss) |
| #10-24 screw | **~35mm** ("~1-3/8in", stated directly in `Rocket60.scad`'s `R60_EBayAftBulkhead()` module comment) | 2 | Aft bulkhead (part 5) → release activator (part 15), threading into the activator's own **printed thread boss** (no insert, no nut). **Supersedes** spec's part-5 table row ("3× ruthex inserts for the release activator") — that text is stale; `R60-PrintSettings.md`'s own "10th review, critical fix" and the module code both confirm the current joint is 2× #10-24, not 3× M3-into-ruthex |
| M3 clearance (Ø3.4) + ruthex RX-M3×5.7 insert | 6mm retainer plate + up to 5mm engagement (of a 6.7mm insert) ⇒ **M3×12** recommended (11mm minimum) | 3 + 3 | Motor retainer (part 11) → fin can (part 9) aft face |
| M2.5 self-tapping screw | 2.0mm cover shell (clearance) + 6.0mm pilot engagement = **M2.5×8**, self-tapped into PETG, not an insert | 4 | Access door (part 7) → e-bay tube boss |
| Panel-mount toggle switch, 12mm hole | — | 1 | Arming switch, cut into the door itself; rated for full battery current (CATS manual §4.3.4) |
| RailButton (printed, `RailGuide.scad`) | — | 2 | 1010-rail buttons, `OD=11, Flange_h=2, Slot_w=2.8`, at Az=180°, Fwd_Z=242mm / Aft_Z=630mm |
| M3 machine screw + ruthex RX-M3×5.7 insert | **FORWARD button only** — 2.0mm button flange + up to 5mm engagement (of a 6.7mm insert) ⇒ **M3×8**, 0.7mm margin, does not bottom | 1 + 1 | Forward rail button (part 2, e-bay tube) — new boss, fixed this session |
| **Aft rail button fastener — still a geometry gap, still not fixed** | — | — | See note below |

**Forward rail button (Az=180°, Fwd_Z=242mm, on part 2/e-bay tube) — FIXED.** Neither
`R60_FinCan()` nor `R60_EBayTube()` cut a matching hole or boss for either button
before this session — a button screw went straight into a plain 1.6mm wall and would
have pulled through. `R60_EBayTube()` now carries a ruthex-boss, same idiom as every
other insert in this design (local wall thickening inward, flush with the true OD,
Ø4.0×6.7mm blind pocket, 0.7mm backing — thinner than this design's usual 1.0mm
because this exact station's own radial budget is tighter against the Vega board's own
worst-case corner clearance; caught by a new `assert()`, not by eye, on the first
attempt at the usual 1.0mm). `tools/verify_rocket60.py` gates it with two new,
mutation-tested checks (OD stays true at the boss station; the boss's own material
reaches its calculated tip radius, 45.2mm read vs 56.8mm plain-wall — removing the
boss addition drops the reading to 56.8mm AND regresses genus 5→6, both fail).
`RailButton()` itself (`RailGuide.scad`) is a plain disc with a Ø4.6mm through-bore and
no threaded feature of its own — loose but workable clearance for the M3 screw.

**Aft rail button (nominally Az=180°, Aft_Z=630mm, on part 9/fin can) — NOT fixed,
flagged for a decision, not resolved unilaterally.** Two independent problems, found
while fixing the forward button:
1. **No boss exists here either** — same defect class as the forward button.
2. **The 630mm station is now stale, not just unbossed.** Its own comment
   ("at the mid centring ring, `S_FIN+L_FINCAN/2`") was computed when `S_FIN`=516
   (516+228/2=630 exactly). `S_FIN` is now 551 (the deployment-bay tube's own growth,
   12th review) — the real mid ring sits at 551+114=**665mm**, not 630. **630mm today
   lands 35mm forward of the ring it was meant to sit on, on plain unbacked wall** —
   the exact pull-through risk this fix exists to close, compounded.

Fixing this means editing `09_FinCan.stl` — a part marked "UNCHANGED by this task"
through nine-plus review rounds and treated everywhere in this repo (spec, print
settings) as hardened/stable. **This was not fixed here because the owner may already
have this part printed**, and there are two live options once it's confirmed safe to
touch: rebase the boss on the real 665mm ring position (restores the original
"backed by a ring" intent) or keep 630mm and add local reinforcement without the ring
(a plain boss, weaker but no station change). This needs an explicit answer, not an
assumption — see the task reply.

---

## 5. Ruthex insert tally (buy these — do not confuse with the camera's own, already-installed inserts)

| Location | Qty | Note |
|---|---|---|
| E-bay fwd bulkhead (part 4), Vega rod anchors | 2 | |
| Fin can (part 9) aft face, motor retainer bolts | 3 | Pre-exists this task, part 9 unchanged |
| E-bay tube (part 2), forward rail button | 1 | New this session — fix 2 |
| **Total (excluding the aft rail button, still open)** | **6** | Camera's own 3 inserts are pre-installed in the purchased assembly, not sourced by the owner. Add 1 more once the aft rail button's own fix is resolved (§4). |

---

## 6. Consumables / commodity items (category only — owner's choice)

| Item | Note |
|---|---|
| 2S LiPo, ~850mAh | Spec A4: Vega needs 7V+ (2S minimum); 45g budget covers this size |
| 24in (610mm) main parachute | Ripstop nylon or similar, packed inside the petal cage |
| Nomex chute protector | Sized for the 24in main (spec §4.3, recommended — not dimensioned in source) |
| Shock cord | **No length anywhere in the source.** Route: e-bay aft bulkhead anchor → through the release stack/spring ID → piston's rope holes → petal hub's centre hole → fin can's forward centring-ring anchor. Sleeved (Nomex or similar) per spec §4.3. Owner's choice of length; a few metres of tubular nylon is typical practice for this size class — this is a recommendation, not a derived figure |

---

## 7. Sourcing

Only suppliers verified in the task brief are cited. Where nothing was verified, the
line says so — no invented product URLs or prices.

| Item | Supplier |
|---|---|
| #4-40 UNC screws (BHCS/SHCS, all lengths) | **Accu** (accu-components.com) — stocks imperial UNC, UK, ships EU |
| #10-24 threaded rod / screws | **Accu** — stocks imperial UNC |
| M3/M2.5 DIN 912 / ISO 4762 screws, nuts, washers | **Accu** — stocks metric alongside imperial, single order |
| MR63-2RS bearing (3×6×2.5) | Source not verified — task brief's verified bearing suppliers (123Bearing, EuroRC, Quality Bearings Online) were checked against **MR84-2RS**, not MR63; do not assume the same price/stock applies to the smaller size actually needed |
| 6703-2RS bearing (17×23×4) | Source not verified — same reason; the header's stale "6705-2RS" is not what this design needs |
| 6mm Delrin/acetal ball ×3 | Source not verified for this exact size — task brief's verified suppliers (Simply Bearings, Ball and Roller Store, High Performance Polymer) were checked against 5/16in (7.94mm), not 6mm |
| 3/16" × 1/8" N42 magnet | Source not verified |
| CS4323 / CS3715 springs | **Century Spring / MW Components** (centuryspring.com, mwcomponents.com), US |
| ruthex RX-M3×5.7 heat-set inserts | Source not verified |
| MG90S servo, 2S LiPo, panel-mount switch, parachute, Nomex, shock cord | Commodity — category named above, owner's choice of vendor |

**Note on the bearing/ball resourcing:** because the release mechanism's real geometry
(§1) uses smaller hardware than the header comment describes, the specific verified
suppliers in the task brief (which were checked against the header's stale sizes) do
not automatically transfer. Re-verify MR63-2RS, 6703-2RS and 6mm ball stock/pricing at
the same suppliers before ordering — they may well carry them, this just was not
checked here.

---

## 8. The imperial problem

| Item | Imperial | Metric equivalent | Drop-in? |
|---|---|---|---|
| #4-40 screw | major Ø2.845mm | M3 Ø3.0mm | **No.** M3 is 0.155mm larger — will not enter a #4-40 clearance/tapped hole or thread into a #4-40 pilot. Clearance holes and pilot pockets across the release stack and petal hinges would need enlarging. |
| 5/16" ball → this design actually uses 6mm | 7.938mm (5/16") vs **6mm (as-built)** | — | Not applicable here — this design's live code already uses a 6mm ball, not 5/16". No conversion needed; it is already metric. |
| 3/16" × 1/8" N42 magnet | 4.76 × 3.18mm | 5 × 3mm | **No.** A 5mm-diameter magnet will not enter a 4.76mm pocket. Needs a model change if going metric. |
| #10-24 threaded rod | major Ø4.83mm | M5 Ø5.0mm | **No.** M5 is 0.17mm larger than #10-24; will not thread into the printed #10-24 boss or an existing #10-24 nut/insert. |
| M2.5/M3 screws already in this design | — | already metric | Neck, Vega sled, motor retainer, door and (per §1's correction) the aft-bulkhead-to-activator joint are **already metric** (M3, M2.5) or use rod that is already metric (Vega sled's M3 rod) — nothing to convert there. |

**Recommendation: buy imperial for the release mechanism, do not convert the model.**
Accu stocks both #4-40 and #10-24 alongside the metric hardware this design already
uses (M3, M2.5) — a single order covers everything in §1 and §4 without touching a
model file. Converting the release-stack hardware to metric is a real geometry change
(enlarging every #4-40 clearance/pilot hole in `CableReleaseBBMicro.scad`'s and
`PetalDeploymentLib.scad`'s own modules, and the ball/lock-bearing pockets sized around
`Ball_d`), and it would need to be done by someone who can re-verify the fit
(mesh-measure the reworked holes, not just resize a constant) — that is out of this
task's scope and was not done here. Given the mechanism already mixes metric (M3 door,
M3 Vega rod, M3 motor retainer) with imperial (#4-40 release stack, #10-24 rod) with no
fit problems at that boundary today, buying the small remaining imperial set from one
EU-shipping supplier is simpler than a model conversion whose main payoff (avoiding a
handful of #4-40/#10-24 items on one Accu order) is small next to its risk (re-opening
mesh-verified clearances across two donor libraries).

---

## 9. Task 2 — closing assumption A11 (see spec §4.2/§10 for the full text)

Century Spring's own catalog for CS4323: free length 8in (203.2mm), OD 1.75in
(44.45mm), ID 1.606in (40.79mm), 12 coils, rate 0.82 lb/in = **0.1436 N/mm**.

**Installed force.** This design's own `tools/rocket60_model.py` models the spring's
installed (captive, compressed) span as exactly 50mm — `SCR_OFFSET`(22.5mm) to
`SPRINGEND_OFFSET`(72.5mm), stated in that file's own comment as *"the span it actually
occupies once compressed."* Compression = 203.2−50 = 153.2mm → **≈22.0N**. (An
independently-floated ~29–33mm span gives ≈24–25N — still under 30N either way; the
50mm figure above is the one actually modelled in this repo's own tool, so it is
reported as primary.) Both readings are comfortably short of the ~178mm compression
that would reach coil-bound (200mm nominal free length − 22mm coil-bound length, per
`R60Lib.scad`'s own `R60_Spring_CBL`), so the spring is not slamming its own hard stop.

**Did anything depend on ≥30N?** One place: `R60Lib.scad`'s `R60_ChuteSplit_Engage`
glue-joint sizing (lines ~117-142) used **~31.5N** as the spring's own conservative
*maximum possible* force (computed from an estimated k≈0.177 N/mm at full coil-bound
compression, 178mm — a deliberately pessimistic upper bound, not the installed force).
That case is explicitly **non-governing**: the same comment states the ejection-charge
pressure pulse is "the governing case, ~8x the spring load" (~262N vs ~31.5N), and the
joint is sized against the larger number. At the real ~22-25N, this stays exactly as
conservative as before — nothing here needed 30N of *authority*, only used 31.5N as a
safe ceiling that the real spring falls well under. No other calculation in the design
references a spring-force figure at all — the petal lock-nubs' own release force (the
number that actually matters for "does the spring open the petals") was never
estimated anywhere, catalog or otherwise; it remains the open item the bench test (spec
§11 item 2) exists to answer.

*Note on that same comment's own worked numbers*: `R60_ChuteSplit_Engage`'s own prose
(wire d=1.9mm, mean coil d=42.4mm, etc.) was hand-computed from the OLD 44.30/40.50
literals, now superseded by `R60_Spring_OD`/`_ID`'s own catalog update above (this
comment is prose, not a live formula referencing those constants, so updating the
constants did not update it). Left untouched — out of this fix's scope, and the actual
sized quantity (`R60_ChuteSplit_Engage=7`) is a fixed literal that never read those
constants either — but flagged here so the ~0.3% staleness in that worked example
doesn't surprise a future reader.

**Does the catalog spring still fit the seat and piston? — seat FIXED this session
(coordinator fix 1), piston confirmed fine, no change.**

- **Seat (part 25, `CRBBm_CenteringRingMount`, our own addition) — FIXED, real
  clearance in both directions, not a tangent.** Was cut at exactly `Spring_OD` with
  **zero clearance** (mesh-measured pre-fix at Ø44.29 against a then-modelled 44.30mm
  spring — already tight before the catalog's real 44.45mm made it worse by another
  0.15mm, and a compression spring's OD grows slightly further as it compresses, so the
  real mismatch was if anything worse than that free-length figure). **Fixed two ways
  together, not one:**
  1. `R60Lib.scad`'s `R60_Spring_OD`/`R60_Spring_ID` now carry the catalog's own real
     figures (44.45/40.79, were 44.30/40.50) — the spring's true size, not a hole size.
  2. A new `R60_Spring_Clear=0.4` (this design's own established diametral-clearance
     convention, matching `R60_Coupler_OD` etc.) is applied as a real, separate
     parameter on `CableReleaseBBMicro.scad`'s `CRBBm_CenteringRingMount()`
     (additive-only — default 0, no other caller of that shared module is affected):
     the **entry pocket grows to `Spring_OD+Spring_Clear`** (mesh-measured **44.84mm**
     post-fix — the spring must physically enter, so it gets a real clearance to enter
     with) and the **shoulder bore under the coil's own inner edge shrinks to
     `Spring_ID-Spring_Clear`** (mesh-measured **40.38mm** post-fix — the coil's inner
     edge now lands on solid support material with **0.2mm of radial margin**, not
     tangent to the support's own rim, the same class of margin-not-tangent fix this
     spec already applied to the chute-packing volume).
  
  **Mutation-tested**: `tools/verify_rocket60.py`'s new "part 25 spring pocket clears
  catalog OD" check gates the entry side (floor: `R60_Spring_OD+0.2`, a real print-
  tolerance floor, not the full nominal). Forcing `Spring_Clear` back to 0 (the exact
  pre-fix state) reproduces the pocket at 44.45mm and **FAILS** (0.211mm shortfall);
  reverted, the real 44.84mm pocket **PASSES** (0.0mm shortfall). `R60_Spring_OD`
  itself was deliberately NOT the thing mutated — the check's own floor derives from
  it, so moving both sides together would prove nothing.
- **Piston (part 23, `R65_FwdSpringEnd`) — confirmed fine, deliberately NOT
  parameterised to the catalog constants.** Its own centering boss is sized to
  `Spring_ID` as an OD (`Tube(OD=Spring_ID, ID=Spring_ID-4.4, ...)`, R65Lib.scad:1419)
  — a spigot the spring's coil sits AROUND, not a bore the spring sits IN — hardcoded
  to `SE_Spring_CS4323_ID()`=40.50, the donor's own generic figure. This is correct
  **by accident**: the catalog's real ID (40.79mm) is larger than that hardcoded 40.50,
  giving 0.29mm of diametral clearance the boss was never designed to need but has.
  **Left untouched on purpose** — pointing it at the new `R60_Spring_ID`=40.79 instead
  would set the boss's own OD exactly equal to the coil's real ID, recreating the
  SAME zero-clearance defect on the piston that was just fixed on the seat. Documented
  in `R60Lib.scad`'s own constants comment so a future reader does not "fix" this into
  a regression.

---

## 10. Summary counts

- **Distinct hardware line items** (excluding printed parts and consumables): 25
  (release mechanism 10, petal deployment 2, our airframe hardware 13 — +1 for the
  forward rail button's own new M3+insert line).
- **Fasteners by type and length**:
  - **#4-40**: 3× 1/2in BHCS + 4× 1/4in BHCS (verified exact) + 3× 3/8in SHCS
    (release stack, per header) + **3× 3/8in (9.525mm) BHCS, ~2.3mm engagement,
    resolved this session** (part 25 → part 16, additive, not in the header) + 6× 1/4in
    BHCS (petal hinges, verified exact) = **19**.
  - **#10-24**: 1× 58mm (release rod, echoed exact) + 2× ~35mm (aft bulkhead →
    activator, stated in source) = **3**.
  - **M3**: 3× M3×10 (neck → camera) + 2× M3×152.8mm all-thread (Vega sled rails,
    echoed exact) + 3× M3×~16 (Vega board → standoffs, derived, verify against real
    board) + 3× M3×12 (motor retainer → fin can, derived) + **1× M3×8 (forward rail
    button → its own new insert, resolved this session)** = **12**, plus 2× M3 nut +
    2× M3 washer (sled aft retention) + 3× M3 nut (Vega board) = **7** nuts/washers.
  - **M2.5**: 4× M2.5×8 (door, derived, self-tapping).
- **Catalog spring dimensions vs our seat**: piston clears (unchanged, confirmed safe
  as-is); **centering-ring-mount seat — FIXED this session**: real clearance in both
  directions (entry pocket 44.84mm measured, shoulder bore 40.38mm measured), mutation-
  tested against a regression back to the zero-clearance state.
- **Anything depended on ≥30N?** One non-governing structural ceiling
  (`R60_ChuteSplit_Engage`, 31.5N) — stays conservative at the real ~22-25N. No
  calculation depended on the spring *reaching* 30N; the real open question (nub-release
  force) was never estimated at all.
- **Imperial vs metric**: buy imperial for the release mechanism (Accu, one order,
  alongside the metric hardware already in this design) — do not convert the model.
- **Rail buttons**: forward (part 2) fixed this session — real boss, real insert,
  mutation-tested checks. **Aft (part 9/fin can) still open** — no boss AND the
  630mm station itself is stale (the real mid-ring position moved to 665mm when
  `S_FIN` grew); fixing it means editing a part marked unchanged/hardened across
  9+ review rounds, which the owner may already have printed — flagged for an
  explicit decision, not resolved unilaterally.
