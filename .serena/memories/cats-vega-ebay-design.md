# CamRocket E-Bay Design — Baseline v0.2.0

## File: CamRocket/CamRocket.scad
## Branch: feature/cam-rocket
## Baseline commit: 392bba7

## Rocket specs (body tube already printed)
- Body tube: OD=75mm, ID=71.4mm, wall=1.8mm, height=250mm
- Fin can shoulder: 30mm into body tube bottom
- Nosecone shoulder: 25mm into e-bay top socket
- Motor: 24mm (Estes D/E)
- Shoulder clearance: 0.2mm per side

## Architecture: 4-part stack + door
1. **Fin can** (bottom) — 4 fins, motor tube, shoulder up into body tube
2. **Body tube** — ALREADY PRINTED, DO NOT MODIFY
3. **E-bay coupler** (between body tube and nosecone) — 145mm total
   - Bottom shoulder 20mm (into body tube, OD=71.0mm)
   - Exposed body 100mm (OD=75mm, bore=71mm)
   - Top socket 25mm (receives nosecone shoulder, bore=71.4mm)
4. **Nosecone** — tangent ogive, 150mm, tip truncated 1mm flat
5. **Door** — curved panel, 4x M2.5 bolts, sits in sill recess

## E-bay coupler features
- CATS Vega rail on +Y wall, 3x M3 standoffs (L-shaped pattern)
- Access door on -Y wall: 36x85mm opening, 5mm frame, 4mm inward projection
- 4x M2.5 bolt bosses in frame corners
- SMA antenna hole through top bulkhead (6.5mm)
- Open bore for ejection gas flow

## CATS Vega mounting holes — L-SHAPED (verified from PCB drill data)
- A=(-13.5, -25): one long edge, 25mm from end
- B=(-13.5, +35): same edge, 85mm from end (60mm from A)
- C=(+13.5, +35): opposite edge, same end as B (27mm from B)
- Source: catsystems/cats-hardware NC drill T11 (3.2mm)

## Nosecone camera
- M12 x 0.5 lens bore (12mm) through solid tip
- Tip solid from z=135mm (hollowing stops there)
- Tip truncated at z=149mm (flat face)
- Known issue: thin spike artifact at tip (cosmetic, deferred)
- Camera PCB mounting inside nosecone: deferred until board dimensions provided

## Known issues
- Nosecone tip spike artifact (ogive point approximation) — cosmetic
- Door bolt boss fit needs test print verification
- CATS Vega hole positions need physical board measurement confirmation
