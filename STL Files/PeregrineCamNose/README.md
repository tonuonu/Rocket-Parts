# PeregrineCamNose — printable meshes

Generated from `PeregrineCamNose.scad` with OpenSCAD 2026.07.09, full render,
binary STL. Verify first with `python3 tools/verify_camnose.py`.

**The camera does not live in these parts any more.** The generated cone is
truncated at OD 60 and the user's own CAD nosecone (`Nose Cone.STEP`, exported
as `STL Files/Rocket60/NoseCone.stl`) sits on top, carrying the camera, the
lens bore and the sunken screw heads exactly as drawn. The blunt spherical cap,
the lens hole, the through-shell camera mounts and the four loose spacers are
all gone.

| File | Part | Height | Max OD | Notes |
|---|---|---|---|---|
| `TestRing.stl` | 0 | 15.00 | 101.50 | Print FIRST. Gauges the tube fit; not glued into the assembly. |
| `Shoulder.stl` | 1 | 115.00 | 98.70 | **Changed** — body 98.6→98.7, spigot 96.7→96.9. Bulkhead + strap slots. |
| `SliceBottom.stl` | 2 | 154.15 | 101.50 | Skirt sits on the tube. Gluing flange on top. |
| `SliceMiddle.stl` | 3 | 154.14 | 96.11 | |
| `SliceTop.stl` | 4 | 88.95 | 77.62 | **Changed** — truncated at OD 60, all camera features removed. Was 146 mm. |
| `Adapter.stl` | 5 | 19.50 | 60.00 | **New.** Joins the truncated shell to the CAD nosecone. |

Tallest piece 154 mm, inside the 250 mm envelope.

## Already printed a slice? It is still good.

`SliceBottom` and `SliceMiddle` are byte-different from the previous export but
**geometrically identical** — verified by comparing the meshes, not by assuming:

```
volume    106.229763 -> 106.229763 cc   (delta 1.7e-13)
z span    unchanged
max radius difference over the whole profile:  0.000000 mm
```

The 10 and 2 missing facets are CGAL retriangulating the flat cut face. Both
cuts (147.14 and 294.29) sit far below the new truncation at 383.23, so nothing
in the retained ogive moved. `Cut_Z` never depended on `Tip_R` either.

## Assembly

1. Print the test ring, confirm it against the tube before anything else.
2. Glue the shoulder spigot into the bottom slice bore.
3. Glue the bottom slice flange into the middle slice, hold until set.
4. Glue the middle slice flange into the top slice, hold until set.
5. Bolt the adapter to the camera's three M3 heat-set inserts — Ø37.96 bolt
   circle at 52.2°, −52.2°, 180°, M3×10. The angles are deliberately not 120°
   apart; that asymmetry keys the camera's clocking.
6. The adapter's spigot enters the truncated shell bore.

Adhesive gap is `Glue_Gap` in the .scad: 0.2 for thin CA, 0.4 for epoxy. The
shoulder body deliberately does not use it — that joint is slip-fit because it
comes apart every flight.

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
