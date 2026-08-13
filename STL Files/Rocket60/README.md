# Rocket 60 — printable meshes

## NoseCone.stl — YOUR CAD, converted. Not regenerated.

Straight conversion of `~/Nose Cone.STEP` with FreeCAD 0.21.1
(LinearDeflection 0.02, AngularDeflection 0.15 — 67,368 facets). Nothing was
redesigned, re-lofted or approximated. The sunken screw heads, the lens bore
and the camera interface are exactly as you drew them.

The only change is placement: the STEP is authored in a parent-assembly frame
with its axis along +Y and its base plane at Y=501.95, which would land it
500 mm off the bed pointing sideways. It is rotated so the axis is +Z and
translated so the base plane sits at z=0. Tip up, ready to slice.

Verified against the exported mesh, not against the source parameters:

| | |
|---|---|
| Overall height | 94.05 mm |
| Base OD | 59.99 mm |
| Base bore ID | 54.25 mm |
| Lens bore at tip | 15.30 mm |

**This part is fixed.** Everything else in Rocket 60 is designed around it —
the 60 mm airframe diameter comes from that 59.99 mm base, and the neck bolts
to the three M3 heat-set inserts in the camera assembly behind it.

## Regenerating

```
freecadcmd export_nc.py   # see docs/ for the script
```
