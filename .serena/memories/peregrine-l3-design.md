# Peregrine L3 Design Summary

## Files
- PeregrineFin75.scad v0.1.0 — Composite fin core for BT137/75mm
- PeregrineFinCan75.scad v0.3.0 — Split-print fin can, **4 fins** (changed from 3 in v0.2.0)
- L3-Design.md — Complete design document

## Key Parameters
- Body: BT137 (140.1mm OD, 136.8mm ID)
- Motor: AeroTech M1297W-PS (5417 N·s, RMS-75/5120, 4.637 kg loaded)
- Total length: ~1741mm (68.5")
- **4 fins** (was 3) — same planform each (Root=249, Tip=90, Span=137, Sweep=120)
- Loaded mass: ~9.7-9.9 kg (under 10 kg limit, margin 100-300g)
- Dry mass: ~5.05-5.25 kg
- Fin construction: 7mm PPS core + 2×0.75mm CF cloth = 8.5mm total
- Stability: needs 200-400g nose ballast for ~1.5 cal (less than 3-fin design)

## 4-Fin Rationale
- CP moves ~53mm aft vs 3 fins → less ballast needed
- 3 fins CANNOT reach 1.5 cal under 10 kg limit; 4 fins CAN
- Flutter speed unchanged (same span per fin): ~555 m/s with CF
- Trade-off: ~5% more total drag → acceptable
- Stronger fin-body joint (4 shear planes vs 3)

## Critical Findings
- CF cloth REQUIRED for flutter resistance (GF marginal, FDM fails)
- Bending SF >50 (not the limiting mode)
- Simplified velocity model overestimates (gives ~450 m/s, real likely 250-350)
- ORK simulation essential before TAP review

## Branch
- feature/fincan75 on tonuonu/Rocket-Parts
- PR #7: https://github.com/tonuonu/Rocket-Parts/pull/7
- Issue #6: https://github.com/tonuonu/Rocket-Parts/issues/6
