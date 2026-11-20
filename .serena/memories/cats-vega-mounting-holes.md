# CATS Vega Mounting Hole Pattern — VERIFIED FROM PCB DRILL DATA

## Source
catsystems/cats-hardware, CATS-Vega/FAB/PT20221219/NC Drill/CATS-Vega-Nutzen-RoundHoles.TXT
Tool T11 = 3.2mm PTH (M3 mounting holes), 15 holes total (5 boards × 3)

## Board: 100 × 33 × 21mm

## L-SHAPED Pattern (NOT symmetric triangle)
- A and B on the SAME long edge, 60mm apart along board LENGTH
- B and C at the SAME end of the board, 27mm apart across board WIDTH
- B is at the corner of the "L"

## Board-local coordinates (origin = corner)
- A = (25, 3) — 25mm from one end, 3mm from one edge
- B = (85, 3) — 85mm from same end, same edge
- C = (85, 30) — same position as B along length, 3mm from OPPOSITE edge

## Board-relative coordinates (origin = board center)
- A = (-25.0, -13.5)
- B = (+35.0, -13.5)
- C = (+35.0, +13.5)

## OpenSCAD code (X = across width, Y = along length)
```
cv_holes = [
    [-13.5, -25],   // A: one edge, far from antenna end
    [-13.5, +35],   // B: same edge, near antenna end
    [+13.5, +35]    // C: opposite edge, same end as B
];
```

## Common mistakes to avoid
- ~~Pair at same END~~ — WRONG, pair is on same EDGE
- ~~Symmetric triangle~~ — WRONG, it's an L-shape
- ~~Single hole centered~~ — WRONG, it's aligned with hole B
