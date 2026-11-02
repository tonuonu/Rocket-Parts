# PeregrineCamNose — printable meshes

Generated from `PeregrineCamNose.scad` with OpenSCAD 2026.07.09, full render,
binary STL. Verify first with `python3 tools/verify_camnose.py`.

**The camera does not live in these parts any more.** The generated cone is
truncated at OD 60 and the user's own CAD nosecone -- a straight FreeCAD
conversion of their own design, carrying the camera, the lens bore and the
sunken screw heads exactly as drawn -- sits on top. That CAD nosecone's own
mesh is not part of this branch (it lives on `feature/rocket60`); this repo
only defines the adapter it bolts to (see `CN_Adapter()` in the .scad). The
blunt spherical cap, the lens hole, the through-shell camera mounts and the
four loose spacers that an earlier version of this part used instead are all
gone.

| File | Part | Height | Max OD | Notes |
|---|---|---|---|---|
| `TestRing.stl` | 0 | 15.00 | 101.50 | Print FIRST. Gauges the tube fit; not glued into the assembly. Unchanged this pass. |
| `Shoulder.stl` | 1 | 115.00 | 98.70 | **Changed** — spigot 96.90→96.70 (`Glue_Gap` default corrected from 0.2, which matched an adhesive the print notes say not to use, to 0.4). Bulkhead + strap slots. |
| `SliceBottom.stl` | 2 | 154.15 | 101.50 | Skirt sits on the tube. Gluing flange on top. Unchanged this pass. |
| `SliceMiddle.stl` | 3 | 154.13 | 96.11 | **Changed** — clip plane 147.14→147.15 (`Cut1_Z` is now derived from `Cut1_d` instead of a separate hardcoded literal); geometrically the same part otherwise. |
| `SliceTop.stl` | 4 | 88.95 | 77.62 | Truncated at OD 60, all camera features removed. Unchanged this pass. |
| `Adapter.stl` | 5 | 21.00 | 60.00 | **Changed** — spigot is now tapered (was a straight cylinder that only engaged the tapered shell bore for the top ~1mm of its 15mm length; see below); flange thickened 4.5→6.0mm for a safer screw-bottoming margin (a code-review recommendation to thin it to 4.0mm instead had the direction backwards; see the .scad comment). |

Tallest piece 154 mm, inside the 250 mm envelope.

## Already printed a slice? It is still good.

From the graft pass (the CAD-nosecone truncation, not this fix pass):
`SliceBottom` and `SliceMiddle` were byte-different from the export before
that graft but **geometrically identical** — verified by comparing the
meshes, not by assuming, at the then-current cuts of 147.14 and 294.29:

```
volume    106.229763 -> 106.229763 cc   (delta 1.7e-13)
z span    unchanged
max radius difference over the whole profile:  0.000000 mm
```

The 10 and 2 missing facets are CGAL retriangulating the flat cut face. Both
cuts sat far below the truncation at 383.23, so nothing in the retained
ogive moved. `Cut_Z` never depended on `Tip_R` either.

This fix pass moves `SliceMiddle`'s own clip plane from 147.14 to 147.15
(`Cut1_Z` is now derived instead of a separate hardcoded literal -- see the
table above) -- 0.005mm, far below print resolution. A slice printed from
the previous export is still fine to use.

## Adapter spigot is now tapered

The shell's bore at Cut3 is a station on an ogive, not a cylinder -- it
widens measurably over the 15mm the adapter's spigot enters. A straight
spigot sized to the tight end (the rim) only actually engaged the bore for
about the first 1mm; the rest of the 15mm was a widening, unglued void up
to several mm across at the deep end. The spigot is now turned to the same
taper as the bore (see `Ogive_OD_At_Z()` in the .scad), so the diametral
epoxy gap stays close to `Adapter_Epoxy_Gap` (0.4) along the whole
engagement instead of only at the rim.

## Assembly

1. Print the test ring, confirm it against the tube before anything else.
2. Glue the shoulder spigot into the bottom slice bore.
3. Glue the bottom slice flange into the middle slice, hold until set.
4. Glue the middle slice flange into the top slice, hold until set.
5. Bolt the adapter to the camera's three M3 heat-set inserts — Ø37.96 bolt
   circle at 52.2°, −52.2°, 180°, M3×10. The angles are deliberately not 120°
   apart; that asymmetry keys the camera's clocking.
6. Epoxy the adapter's spigot into the truncated shell bore (Cut3) and hold
   until set. This joint is always epoxy, regardless of `Glue_Gap` (it
   carries the whole CAD nosecone + camera in flight) — unlike steps 2-4,
   which follow whatever `Glue_Gap` is set to, and unlike the shoulder
   (step 1's spigot), which is slip-fit and never glued because it comes
   apart every flight.

Adhesive gap for steps 2-4 is `Glue_Gap` in the .scad: 0.4 (default) for gel
CA or epoxy, 0.2 for thin CA on a small part. The shoulder body deliberately
does not use it — that joint is slip-fit because it comes apart every
flight.

**Print the adapter flange-down**, rotated 180° from how it's modeled
(spigot up instead of hanging below). As modeled, the flange's underside is
a horizontal shelf bridging the open spigot hollow, carrying the 3 screw
holes — unsupported, it droops or needs support material on the exact face
the screw heads bear on. Rotated 180°, every overhang is self-supporting.

## Expect a slope change at the joint

The Peregrine ogive arrives at the cut at about 6.5° half-angle; the CAD cone
leaves its base at about 0.4°, rising to ~3° by 25 mm up. About **6° of kink**,
visible as a slight shoulder. That is inherent to grafting two cones designed
for different base diameters, not a defect — and it is the cost of using the
real camera housing instead of a generated approximation of one.

## Regenerating

```
OPENSCADPATH=<repo> /Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD \
  --render --export-format binstl -o out.stl -D Render_Part=N PeregrineCamNose.scad
```
