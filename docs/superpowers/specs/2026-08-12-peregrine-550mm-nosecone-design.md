# Peregrine 550 mm Sliced Nosecone — Design

Date: 2026-08-12
Target file: `PeregrineNoseCone.scad`
Status: awaiting review

## Goal

Replace the current 300 mm two-piece nosecone with one that stands **550 mm proud of
the body tube**, matching the proportions of the original Apogee Peregrine cone, and
split it into pieces that fit a Bambu P1S.

Every component is 3D printed. No purchased coupler tube, no metal hardware.
Pieces are joined with superglue.

## Constraints

| Constraint | Value | Source |
|---|---|---|
| Exposed height above tube | 550 mm | Measured from original |
| Shoulder length inside tube | 100 mm (1 caliber) | User decision |
| Max printed piece height | 250 mm usable Z | Bambu P1S |
| Body tube OD / ID | 101.5 / 99.0 mm | `PeregrineNoseCone.scad:22-23` |
| All parts printed | yes | User requirement |
| Joining method | superglue | User requirement |

## Geometry

Spherically blunted tangent ogive, via the existing `BluntOgiveNoseCone` in
`NoseCone.scad`.

```
NC_Length  = 574.55   // ogive parameter, NOT the finished height
Base_L     = 15       // full-OD skirt at the bottom
Tip_R      = 8        // tip sphere radius
Wall_T     = 2.2
```

Fineness ratio 5.42:1, against the current file's 3:1.

### The height formula

Finished exposed height is **not** `Base_L + NC_Length`. Blunting shortens the cone,
and `Tip_Z` inside the module is the tip *sphere centre*, not the apex:

```
exposed = Base_L + NC_Length - X0(NC_Length) + Tip_R
```

where `X0` is `NC_OGiveTipX0(R, L, Tip_R)` (`NoseCone.scad:69`). With `Tip_R = 8`,
blunting removes 47.6 mm and the sphere radius adds 8 mm back.

Omitting the `+ Tip_R` term produces a cone 8 mm too tall. This was caught by
measuring a rendered STL, not by reading the code — **verify by render, not by
formula.**

### Slice planes

Three equal 183.33 mm slices of the exposed cone:

| Cut | Z | `Cut_d` |
|---|---|---|
| 1 | 183.33 | 92.85 |
| 2 | 366.67 | 63.66 |

`Cut_d` is a *diameter*; the module derives Z via `Ogive_Cut_Z` (`NoseCone.scad:73`).

## Parts

| # | Part | Height | Base dia | PETG mass |
|---|---|---|---|---|
| 1 | Shoulder + bulkhead + anchor | 115 mm | 98.6 | ~123 g |
| 2 | Bottom slice | 190.3 mm | 101.5 | ~163 g |
| 3 | Middle slice | 190.3 mm | 92.9 | ~131 g |
| 4 | Top slice, filled tip | 183.3 mm | 63.7 | ~62 g |
| 5 | Guide ring, lower | 6 mm | 88.0 | ~7 g |
| 6 | Guide ring, upper | 6 mm | 58.9 | ~3 g |

Total ~489 g in PETG. Tallest piece 190.3 mm against the 250 mm limit.

Mass is significant — half a kilo at the nose. It shifts CG forward, which helps
stability, but if it proves too heavy, `Wall_T = 1.8` brings the set to ~390 g
without changing any other number in this spec.

## Slicing approach

`BluntOgiveNoseCone` accepts a single `Cut_d` and yields two pieces. The lower piece
grows an integral 7 mm gluing flange, offset `Wall_T + IDXtra` inward, that the upper
piece slides over (`NoseCone.scad:842-885`). That flange is the whole joint design:
self-aligning, generous glue area, no separate parts.

Three slices are produced by calling the module once per slice and clipping:

```
bottom = BluntOgiveNoseCone(Cut_d = 92.85, LowerPortion = true)
middle = intersection(
             BluntOgiveNoseCone(Cut_d = 63.66, LowerPortion = true),
             slab z >= 183.33 )
top    = BluntOgiveNoseCone(Cut_d = 63.66, LowerPortion = false, FillTip = true)
```

The middle slice keeps the flange the module put at its top, and its clean lower cut
slides over the bottom slice's flange with `IDXtra` = 0.2 mm clearance.

**`NoseCone.scad` is not modified.** It is shared by roughly 20 rocket designs; the
blast radius of changing `BluntOgiveNoseCone` to accept a cut list is not justified
by one nosecone. All new code lives in `PeregrineNoseCone.scad`.

Rejected alternatives:

- **Extend the library to take a list of cuts.** Cleaner in the abstract, but edits
  a file 20 designs depend on.
- **Slab cuts plus separate `Splice_BONC` rings.** Two extra prints and twice the
  glue surfaces per joint, with the joint depending entirely on a loose ring.

## Shoulder

The current file leaves a 97.5 mm bore expecting a purchased coupler. A printed
shoulder that fits the 99.0 mm tube must be ~98.6 mm OD — larger than the bore it
has to enter. The shoulder is therefore **stepped**:

| Section | Length | OD | Fit |
|---|---|---|---|
| Spigot (upper) | 15 mm | 96.7 | into nosecone shell ID 97.1, 0.4 clearance |
| Body (lower) | 100 mm | 98.6 | into body tube ID 99.0, 0.4 clearance |
| Bulkhead | 4 mm | — | closes the bottom, carries the anchor |

`Peregrine_Coupler_OD` changes from 97.5 to **97.1** — the shell's own inner
diameter (`101.5 - 2 × 2.2`), making the skirt a plain 2.2 mm wall tube.

`NoseconeBase` (`NoseCone.scad:999`) provides the single-diameter tube, bulkhead and
printed strap slots, but not the step. A local module in `PeregrineNoseCone.scad`
builds the stepped version, reusing `NoseconeBase`'s slot geometry.

## Parachute anchor

**Primary anchor: the shoulder bulkhead**, using printed strap slots
(`HasUBolt = false` geometry — two `RoundRect` slots, no metal).

The load path is the reason. Anchoring at a slice joint would put full deployment
shock in tension across every glue joint below it, and superglued PETG loaded in
tension across print layers is the weakest element in the assembly. Anchored at the
bulkhead, shock passes straight into the body tube and the glue joints only ever
carry the cone's own inertia.

**Guide rings** at both slice joints: printed rings captured at the gluing flange,
with a central pass-through hole, keeping the strap centred and preventing it from
chafing the shell. Each ring's OD is the shell inner diameter at that joint, less
clearance — `Cut_d - 2 × Wall_T`, giving 88.0 mm at joint 1 (shell ID 88.45) and
58.9 mm at joint 2 (shell ID 59.26). Pass-through hole 12 mm. These matter only if the parachute packs inside the cone volume;
if it packs below the nosecone, they can be omitted without affecting anything else.

## Render selection

`Render_Part` keeps its existing role as a single selector:

| Value | Renders |
|---|---|
| 0 | Test ring (fit check, print first) |
| 1 | Shoulder with bulkhead and anchor |
| 2 | Bottom slice |
| 3 | Middle slice |
| 4 | Top slice |
| 5 | Guide ring, lower (fits joint 1) |
| 6 | Guide ring, upper (fits joint 2) |

The existing values 1–3 change meaning. That is acceptable: the file is the only
consumer, and the old 300 mm two-piece configuration is being replaced, not kept.

`TestRing()` is updated to the new 97.1 bore so it still verifies the real fit.

## Verification

1. Every `Render_Part` value renders with `Status: NoError` under OpenSCAD 2026.07.09.
2. Measured from rendered STLs:
   - assembled apex at 550.0 ± 0.1 mm
   - each joint overlap 7.0 ± 0.1 mm
   - no piece taller than 250 mm
   - shoulder body 98.6 mm, spigot 96.7 mm
3. Preview mode applies a quarter cutaway (`$preview` guards). Export with F6 or
   `-o file.stl`, never F5.

Render command:

```
OPENSCADPATH=/Users/tonu/Rocket-Parts \
/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD \
  -o part.stl -D Render_Part=N PeregrineNoseCone.scad
```

## Print notes

- Print the test ring first and confirm fit before committing to 190 mm pieces.
- Suggested: 3 perimeters, 15% infill, PETG or ASA.
- Slice 4 has a filled tip (`FillTip = true`) so the apex is solid rather than a
  fragile shell.

## Out of scope

- Modifying `NoseCone.scad`.
- The `nosecone-ogive-hollow-bug.md` hollowing defect. That lesson notes the bug was
  *hidden* on a 100 mm tube because the diameter was large enough to mask it, so a
  clean render here is not proof the wall is correct. Wall thickness must be checked
  on the physical print.
- Any other Peregrine component.
