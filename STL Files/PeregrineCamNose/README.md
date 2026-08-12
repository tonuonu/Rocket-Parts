# PeregrineCamNose — printable meshes

Generated from `PeregrineCamNose.scad` with OpenSCAD 2026.07.09, full render
(F6 equivalent), binary STL.

| File | Part | Height | Notes |
|---|---|---|---|
| `TestRing.stl` | Render_Part 0 | 15 mm | Print FIRST. Disposable fit check, not glued into the assembly. |
| `Shoulder.stl` | 1 | 115 mm | Stepped: 98.6 into the tube, 96.7 spigot into the cone. Bulkhead + strap slots. |
| `SliceBottom.stl` | 2 | 154 mm | Skirt sits on the tube. Gluing flange on top. |
| `SliceMiddle.stl` | 3 | 154 mm | |
| `SliceTop.stl` | 4 | 146 mm | Lens hole and the four countersunk M3 camera mounts. |
| `SpacerFront.stl` | 5 | 2.83 mm | Print 2. Front mount station. |
| `SpacerRear.stl` | 6 | 6.08 mm | Print 2. Rear mount station. |

Tallest piece 154 mm — inside the Bambu P1S 250 mm envelope.

## Why STL and not STEP

OpenSCAD is a mesh kernel and cannot write STEP. Converting the mesh to STEP
via FreeCAD works but produces one planar face per triangle: `SliceTop` alone
came out at **221 MB with 113,908 faces** and took 48 s to convert. That is not
a smoother model than the STL — it is the same faceting in a heavier container,
and it will bog down any slicer. All seven parts would approach a gigabyte.

If you need STEP for CAD editing rather than printing, the right route is to
rebuild the profile as a native revolved solid, not to convert the mesh.

3MF is not provided because this OpenSCAD build's 3MF exporter fails silently —
it reports `Status: NoError` and exit 0 while writing a 0-byte file.

## Regenerating

```
OPENSCADPATH=<repo> /Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD \
  --render --export-format binstl -o out.stl -D Render_Part=N PeregrineCamNose.scad
```

Verify the geometry first with `python3 tools/verify_camnose.py` — it renders
every part, measures the STLs, and checks the camera actually fits.
