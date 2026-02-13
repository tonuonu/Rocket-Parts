# Peregrine L2 — 3D Print Settings

**Project:** Peregrine L2 Certification Rocket (4" / 101.5mm body)  
**Author:** Tõnu Samuel  
**Date:** 2026-02-13  

---

## Overview

The L2 Peregrine uses PC (Polycarbonate) for all printed structural parts.
Unlike the L3 design, the L2 fin can and fins are **not** covered with
composite fabric — the printed parts are the final structure and must
carry all flight loads directly. This demands higher infill and wall
counts compared to parts that receive composite overwrap.

**Motor:** AeroTech J420R (38mm, RMS-38/720)  
**Expected Vmax:** ~200 m/s (Mach 0.59)

## 1. Fin Can — PeregrineFinCan v0.8.0

Single-piece print (248.7mm total height, fits P1S with AMS).

| Parameter | Value | Notes |
|---|---|---|
| Material | PC (Polycarbonate) | Tg ~147°C, high strength |
| Wall loops | 6 | 2.4mm total (matches design Wall=2.4) |
| Top/bottom layers | 5 | Solid faces on centering rings and retainer |
| Layer height | 0.12 mm | High Quality @BBS X1C profile |
| Infill pattern | Gyroid | Isotropic, good shear resistance |
| Infill density | 70% | No composite overwrap — printed part is final structure |
| Supports | None | Designed for supportless printing |
| Print orientation | Retainer end down | Single piece, aft end on bed |
| Bed adhesion | Brim 5mm | PC warps; large footprint helps |
| Chamber | Enclosed, heated | Required for PC |

**Rationale:** Higher infill (70% vs 50% on L3) because the fin can has
no fiberglass shell — the printed structure alone transfers fin thrust loads
to the body. The fin slot edges and centering ring-to-wall joints carry
shear loads during flight.

**Critical areas:**
- Fin slot edges: shear from fin bending during flight
- Retainer thread: must hold motor retention under thrust
- Centering rings: motor alignment under asymmetric loads
- Coupler shoulder: body tube attachment

## 2. Fins — PeregrineFin v0.7.0

Split print (2 halves per fin, 3 fins = 6 halves total).

| Parameter | Value | Notes |
|---|---|---|
| Material | PC (Polycarbonate) | Best strength for unskinned fins |
| Wall loops | 8 | 3.2mm × 2 sides = 6.4mm ≥ 6.35mm fin → solid |
| Top/bottom layers | 4 | Not critical (cut face is "top") |
| Layer height | 0.12 mm | High Quality @BBS X1C profile |
| Infill pattern | N/A | Fin is solid from wall loops |
| Infill density | N/A | No infill gap remains at 8 loops |
| Supports | None | Each half prints standing on cut face |
| Print orientation | Cut face down | Along-layer bending strength ~60 MPa |
| Bed adhesion | Brim 3mm | |
| Chamber | Enclosed, heated | Required for PC |

**Rationale:** At 0.4mm line width, 8 wall loops = 3.2mm from each side =
6.4mm total, which exceeds the 6.35mm fin thickness. The fin is effectively
**solid PC** — no infill needed or possible. This gives the maximum
achievable stiffness from a monolithic FDM print.

**Flutter note:** Solid PC fins at 6.35mm thickness give V_flutter ≈ 200-220
m/s (G ≈ 0.9 GPa cross-layer). This is adequate for the J420R motor
(~200 m/s Vmax) but without large margin. The 2mm carbon fiber rods at
25% and 60% chord add spanwise stiffness and help, but flutter remains
the limiting factor. If flight data shows higher-than-expected velocity,
consider CF cloth overlay for future flights.

## 3. Fin Assembly

| Step | Description |
|---|---|
| 1 | Print each fin as 2 halves (cut at 60% chord) |
| 2 | Insert 2mm CF rod at the cut line for alignment |
| 3 | Epoxy halves together on a flat surface |
| 4 | Insert 2mm CF rod at 25% chord channel |
| 5 | Sand surface lightly for aerodynamic smoothness |
| 6 | Insert fins into fin can slots, epoxy bond |

**Rod reinforcement:** 2× 2mm carbon fiber rods per fin (2.2mm channels)
at 25% and 60% local chord. The aft rod (60% chord) also serves as the
split-print alignment pin.

## 4. Material Summary

| Part | Material | Infill | Wall loops | Notes |
|---|---|---|---|---|
| Fin can | PC | Gyroid 70% | 6 | Final structure, no overwrap |
| Fins (6 halves) | PC | Solid | 8 | 6.35mm → solid from walls |
| Motor retainer cup | PC | Gyroid 70% | 6 | Heat exposure from aft closure |

**Why PC for everything:**
- Tg ~147°C — adequate for 38mm motor proximity
- Tensile strength ~55-65 MPa — strongest common FDM material
- Good layer adhesion — critical for fins (cross-layer shear in flight)
- No composite shell means the printed material IS the structure

**Why not PLA/PETG/ABS:**
- PLA: Tg 60°C, will deform near motor
- PETG: Tg 80°C, marginal; poor layer adhesion
- ABS: Tg 100°C, adequate temperature but weaker than PC
- None of these have adequate stiffness for unskinned fins at ~200 m/s

## 5. Comparison: L2 vs L3 Print Settings

| Parameter | L2 (4") | L3 (5.5") | Why different |
|---|---|---|---|
| Fin can material | PC | PC | Same |
| Fin can infill | 70% | 50% | L2 has no GF shell |
| Fin material | PC | PPS | L3 fins get CF overlay |
| Fin infill | Solid | Gyroid 40% | L2 solid for stiffness; L3 core is shear web only |
| Fin wall loops | 8 | 4 | L2 needs solid; L3 CF carries bending |
| Composite overlay | None | CF on fins + GF on fin can | L3 transonic → composite required |
