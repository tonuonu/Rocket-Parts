# PeregrineFin Design Summary

## Current Version: 0.7.0 (PR #5, branch feature/fin-rod-channels)

## Geometry
- Root chord: 249mm, Tip chord: 90mm, Span: 137mm (was 114mm pre-v0.6.0)
- LE sweep: 120mm
- Thickness: 6.35mm root (NACA 0012), tapers to 70% at tip
- Planform area: 23,222mm² (matches ORK freeform fin area of 23,130mm²)
- Aspect ratio: 0.81
- Tab: 190mm × ~19mm, shifted 5mm from trailing edge
- Print diagonal: 294mm — fits Bambu P1S (362mm limit)
- Print height: 249mm (1mm under 250mm AMS limit)

## Rod Channels
- 2× 2.2mm diameter channels at 25% and 60% local chord, Z=0 centerline
- Forward: ~176mm, Aft: ~158mm
- Root spacing: 87mm, Tip spacing: 31mm
- For 2mm carbon rods + epoxy
- NOTE: Early commit c07af82 used 3.2mm channels — settled on 2.2mm for 2mm rods
- Tõnu ordered 2mm and 4mm carbon rods from AliExpress (0.5m × 8pcs each)

## Print Modes (Render_Part)
- 0 = Full fin as mounted
- 1 = Full fin on trailing edge (original, cross-layer bending: 35 MPa)
- 2 = Forward half (LE side) on cut face (along-layer bending: 60 MPa)
- 3 = Aft half (TE side) on cut face (along-layer bending: 60 MPa)

Split at 60% chord rod line. Rod channel bisected → half-round alignment grooves.
Fwd half: root 149mm, tip 54mm. Aft half: root 100mm, tip 36mm.

## Structural Summary (Bambu PC, 10° AoA)

| Config | SF @ J420R (187.6 m/s) | SF @ 250 m/s |
|--------|------------------------|--------------|
| Full fin, no rods | 2.92 | 1.65 |
| Full fin + carbon rods | 2.92 + delam resist | 1.68 + delam resist |
| Split-print | 5.01 | 2.82 |

J420R velocity from PeregrineL2.ork. 250 m/s for future larger motors.

## ORK Reference
PeregrineL2.ork: 3 motor configs (H128W, J420R, I327DM).
J420R sim: Vmax=187.6 m/s, Mach 0.55, Alt=1035m.
L2 is full-length rocket (nose 503mm + body tubes), L1 was shortened.
