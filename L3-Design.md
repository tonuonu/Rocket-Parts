# Peregrine L3 — Design Document

**Project:** Peregrine L3 Certification Rocket  
**Author:** Tõnu Samuel  
**Date:** 2026-02-12  
**Status:** PRELIMINARY DESIGN — requires OpenRocket validation  

---

## 1. Overview

The Peregrine L3 is a single-stage, dual-deploy high-power rocket designed for
Tripoli Level 3 certification. It uses a BT137 (5.38") body tube with a 75mm
motor mount, 4 composite fins over 3D-printed cores, and a split-print fin can
with fiberglass overwrap.

The design reuses the proven PeregrineFin planform (NACA 0012 trapezoidal) from
the L2 rocket but with composite construction suitable for transonic flight.

## 2. Design Requirements

| Requirement | Value | Source |
|---|---|---|
| Motor class | M (≥5120.01 N·s) | Tripoli L3 |
| Motor | AeroTech M1297W-PS | RMS-75/5120 |
| Max loaded mass | 10 kg | Launch site limit |
| Recovery | Dual deploy, redundant altimeters | Tripoli L3 |
| Stability | ≥1.0 caliber (target 1.5-2.0) | Tripoli L3 |
| Design review | 2× TAP members | Tripoli L3 |
| Sub-scale model | ≥50% scale test flight | Tripoli L3 |

## 3. Motor

**AeroTech M1297W-PS** in **RMS-75/5120** reloadable hardware.

| Parameter | Value |
|---|---|
| Diameter | 75.4mm (case), 79.4mm (aft closure) |
| Length | 602.5mm (75/5120 case) |
| Total impulse | 5417 N·s (6% M) |
| Average thrust | 1297 N |
| Peak thrust | 2049 N |
| Burn time | 4.17 s |
| Isp | 199 s |
| Loaded mass | 4637 g |
| Propellant mass | 2722 g |
| Empty mass | 1915 g |

Alternative motors (same case): M1500G-PS (Mojave Green, 5220 N·s).

## 4. Dimensions

### 4.1 Body Tube — BT137

| Parameter | Value |
|---|---|
| OD | 140.1 mm (5.38") |
| ID | 136.8 mm |
| Wall | 1.65 mm |
| Material | Blue Tube 2.1 (phenolic kraft) |
| Linear density | ~650 g/m |

### 4.2 Layout (bottom to top)

| Section | Length (mm) | Notes |
|---|---|---|
| Motor retainer | 16 | Male threaded, protrudes aft |
| Fin can body | 310 | Split print: 171 + 155 mm |
| Main body tube | 500 | Motor extends 293mm into this |
| Electronics bay | 200 | Dual redundant altimeters |
| Drogue section | 350 | Drogue chute + shock cord |
| Nose cone | 450 | 3.2:1 ogive, 85mm shoulder |
| **Total** | **~1741** | **68.5" / 1.74m** |

Length-to-diameter ratio: 12.4:1

### 4.3 Fin Can — PeregrineFinCan75.scad v0.3.0

Split-print design for Bambu P1S (250mm max with AMS).

| Parameter | Value |
|---|---|
| Body OD | 140.1 mm (BT137) |
| MMT bore | 76.0 mm |
| Annular gap | ~27 mm |
| Body length | 310 mm |
| Fin slots | 4× 8.0mm W × 240mm L |
| Centering rings | 4× 5mm thick |
| Retainer thread | 3¼"/3⅜" 8 TPI |
| Coupler | 35mm long, 8× #8 screws |
| Split joint | Interlocking step + 4× 4mm alignment pins |
| Lower half | ~171 mm |
| Upper half | ~155 mm |

**Assembly sequence:**
1. Print lower and upper halves (PPS or Nylon)
2. Insert 4mm carbon rod alignment pins
3. Slide fins through slots spanning both halves
4. Epoxy fins in slots, bond halves together
5. Fiberglass fabric + epoxy wet layup over entire fin can + fin roots
6. Optionally embed 4mm carbon rods along body between fins before overwrap

### 4.4 Fins — PeregrineFin75.scad v0.1.0

Same planform as L2 PeregrineFin v0.7.0. Composite construction.

| Parameter | Value |
|---|---|
| Count | 4 |
| Root chord | 249 mm |
| Tip chord | 90 mm |
| Exposed span | 137 mm |
| LE sweep | 120 mm |
| Airfoil | NACA 0012 symmetric |
| Planform area | 23,222 mm² per fin |
| Aspect ratio | 0.81 |

**Composite construction:**

| Layer | Thickness | Material |
|---|---|---|
| CF overlay (outer) | 0.75 mm | Carbon fiber cloth + epoxy |
| Printed core | 7.0 mm | PPS or Nylon (FDM) |
| CF overlay (inner) | 0.75 mm | Carbon fiber cloth + epoxy |
| **Total** | **~8.5 mm** | |

**Rod reinforcement:** 2× 4mm carbon fiber rods at 25% and 60% chord,
spanning full length from tab to tip. Channels are 4.2mm diameter.

**Print:** Split at 60% chord rod line. Each half prints standing on cut face
(along-layer bending strength: 60 MPa for PPS). Rod provides alignment.

## 5. Mass Budget

| Component | Mass (g) | Notes |
|---|---|---|
| Fin can (printed + overwrap) | 1350 | PPS/Nylon + GF fabric (4 fin slots) |
| Fins 4× (core + CF cloth) | 800 | 200g each |
| Main body tube | 325 | BT137 Blue Tube, 500mm |
| Drogue body tube | 227 | BT137 Blue Tube, 350mm |
| Nose cone | 500 | FG or 3D printed + FG |
| Nose ballast | 200-400 | Lead shot for CG adjustment |
| Electronics bay | 700 | Dual altimeters + batteries |
| Recovery system | 600 | Main + drogue + cord + hardware |
| Misc hardware | 350 | Rail buttons, screws, epoxy |
| **Dry mass** | **~5050-5250** | |
| Motor (loaded) | 4637 | M1297W-PS |
| **Loaded mass** | **~9700-9900** | |

**10 kg launch site limit: PASS** with ~100-300g margin.

Margin is tighter with 4 fins + ballast. Exact tuning from ORK simulation.

## 6. Performance Estimates

**WARNING:** These are simplified analytical estimates. OpenRocket simulation
is required before finalizing the design or submitting to TAPs.

| Parameter | Estimated | Notes |
|---|---|---|
| T/W ratio (avg) | 13-14:1 | Well above 5:1 minimum |
| Max velocity | 250-350 m/s | Mach 0.74-1.03 (see §6.1) |
| Max dynamic pressure | 40,000-75,000 Pa | |
| Altitude | 1500-3000 m | 5,000-10,000 ft |
| Stability | 0.9-1.4 cal | 4 fins + 200-400g nose ballast |

### 6.1 Velocity Note

The simplified Tsiolkovsky + iterative drag model used in initial analysis
consistently overestimates Vmax for HPR rockets. It gave ~450 m/s for this
configuration, but real L3 flights on M1297W in similar rockets typically
achieve 250-350 m/s. The discrepancy is due to:

- Transonic drag rise (Cd increases 2-3× near Mach 1) not modeled
- Base drag and fin interference drag not modeled
- Launch rail friction not modeled

**OpenRocket with RASAero drag data is required for accurate estimates.**

### 6.2 Stability Note

The motor is 48% of loaded mass, concentrated at the aft end. This requires
nose ballast (200-400g) to achieve the required 1.5+ caliber stability margin.
The exact amount must be determined from ORK simulation.

The design uses 4 fins instead of 3 to improve stability at equal mass.
Barrowman analysis shows 4 fins moves CP ~53mm further aft compared to 3 fins,
reducing ballast needs by ~200g. At 9.5 kg loaded, 3 fins cannot reach 1.5
calibers within the 10 kg launch site limit; 4 fins can. Flutter speed is
unchanged (same span per fin). The trade-off is ~5% more total drag, which
is acceptable.

This ballast requirement is normal for L3 rockets on minimum-M motors where
the motor hardware dominates the mass budget.

## 7. Structural Analysis

### 7.1 Fin Bending (Composite)

With CF cloth overlay, the fin is a sandwich beam: CF face sheets carry
bending loads, PPS core carries shear.

At 300 m/s (realistic Vmax), 10° AoA:
- Root bending moment: ~13 N·m
- CF face stress: ~9 MPa
- Safety factor: **>50** (CF cloth failure ~500 MPa)

**Bending is not the limiting failure mode.** Flutter governs.

### 7.2 Flutter

Flutter is the critical failure mode for L3 fins at transonic speeds.
Simplified analysis (Theodorsen-type):

| Construction | G (GPa) | V_flutter (m/s) | Vmax/Vf at 300 m/s |
|---|---|---|---|
| FDM only (cross-layer) | 1.0 | ~163 | 1.84 — **FAILURE** |
| GF cloth composite | 3.5 | ~367 | 0.82 — MARGINAL |
| CF cloth composite (std) | 8.0 | ~555 | 0.54 — **SAFE** |
| CF cloth (high modulus) | 12.0 | ~680 | 0.44 — **SAFE** |

**Conclusion:** Carbon fiber cloth overlay is required. Standard modulus CF
provides adequate flutter margin. Glass fiber is marginal and not recommended.

### 7.3 Fin Can

The split-print fin can is not the primary structure after assembly. The
fiberglass overwrap + epoxied fins create a composite shell that carries
flight loads. The printed halves serve as mandrel/core.

The fin tab epoxy joint (240mm × ~20mm × 8mm, 4 fins) provides massive
shear area for fin-to-body attachment.

## 8. Recovery

### 8.1 Dual Deploy (Tripoli L3 requirement)

| Event | Device | Altitude |
|---|---|---|
| Apogee | Drogue deploy | At apogee |
| Main | Main chute deploy | ~300m AGL (1000ft) |

### 8.2 Electronics (Redundant)

Two independent altimeters, each with:
- Own battery (9V or 2S LiPo)
- Own switch (external, accessible on pad)
- Own deployment charges
- Primary: deploy at computed apogee / preset altitude
- Backup: deploy 1-2s after primary (apogee) / lower altitude (main)

Example: 2× Mission Control V3, or 1× MCV3 + 1× PerfectFlite StratoLogger.

### 8.3 Chute Sizing

| Parameter | Main | Drogue |
|---|---|---|
| Diameter | 60" (152cm) | 24" (61cm) |
| Descent rate | ~5 m/s | ~20 m/s |
| Material | Ripstop nylon | Ripstop nylon |
| Deployment | Altimeter at 300m | Altimeter at apogee |

### 8.4 Shock Cord

- Material: 1" tubular nylon
- Length: 25-30 ft (body length × 5)
- Attachment: forged eye bolts through bulkheads

## 9. Materials List

### 9.1 Available (already ordered/owned)

- 20m R&G glass fiber sleeve (art 201115): Ø100mm, 0.3mm thick
  - Usable for MMT reinforcement (76mm), NOT for fin can body (too stretched)
- 4mm carbon fiber rods, 50cm × 8pcs (AliExpress)
  - Alignment pins for fin can halves and fin rod channels
- 2mm carbon fiber rods, 50cm × 8pcs (AliExpress)
  - Optional additional reinforcement
- Bambu P1S 3D printer with AMS (250mm max height)

### 9.2 To Purchase

- BT137 Blue Tube 2.1 body tubes (2× sections)
- AeroTech RMS-75/5120 motor hardware
- AeroTech M1297W-PS reload kit
- Carbon fiber cloth (6oz or 8oz woven, for fin overlay)
- West System or similar laminating epoxy
- Nose cone (commercial FG or 3D printed + FG overlay)
- 2× altimeters + batteries + switches
- Recovery hardware (chutes, cord, quick links)
- Rail buttons (1515 rail)
- PPS or Nylon filament for fin can and fin cores
- Fiberglass cloth for fin can overwrap
- Lead shot for nose ballast

## 10. Build Sequence

1. **Design validation:** OpenRocket simulation, TAP review
2. **Sub-scale test:** L2 Peregrine serves as ~72% scale model (101.5/140.1)
3. **Print fin can halves** (PPS/Nylon, split print)
4. **Print fin cores** (PPS/Nylon, split print per fin)
5. **Assemble fin cores:** Glue halves with 4mm rod alignment
6. **CF overlay on fins:** Wet layup CF cloth + epoxy, vacuum bag cure
7. **Assemble fin can:** Insert alignment pins, slide fins through slots,
   epoxy fins + halves together
8. **Fin can overwrap:** GF fabric + epoxy over entire fin can + fin fillets
9. **Body tubes:** Cut to length, drill holes for e-bay screws and rail buttons
10. **Electronics bay:** Build sled, wire altimeters, test deployment charges
11. **Nose cone:** Purchase or fabricate, add ballast compartment
12. **Recovery:** Assemble chutes, cord, quick links, protectors
13. **Final assembly:** Coupler joints, rail buttons, finishing
14. **CG check:** Verify stability with and without motor
15. **Ground test:** Deployment charge testing (on ground)
16. **TAP inspection:** Pre-flight review by both TAP members
17. **Flight**

## 11. CAD Files

| File | Description | Version |
|---|---|---|
| PeregrineFinCan75.scad | Fin can for BT137/75mm | v0.3.0 |
| PeregrineFin75.scad | Fin core for BT137/75mm | v0.1.0 |
| (TBD) PeregrineNose75.scad | Nose cone for BT137 | — |
| (TBD) PeregrineEbay75.scad | Electronics bay for BT137 | — |
| (TBD) PeregrineL3.ork | OpenRocket simulation | — |

## 12. Open Items

- [ ] OpenRocket simulation for accurate velocity, altitude, stability
- [ ] Exact nose ballast amount (from ORK CG/CP analysis)
- [ ] CF cloth sourcing (type, weight, weave)
- [ ] Nose cone design or purchase decision
- [ ] Electronics bay detailed design
- [ ] TAP member selection
- [ ] Recovery system detailed sizing
- [ ] Flutter FEA (if TAPs require beyond analytical estimate)
- [ ] Sub-scale test flight analysis (L2 Peregrine as proxy)
- [ ] Cost estimate

## 13. References

- Tripoli L3 Certification Requirements
- AeroTech RMS-75/5120 motor data (ThrustCurve.org)
- Barrowman stability equations
- NASA SP-8003 (flutter of flat plates and shells)
- PeregrineFin.scad v0.7.0 (L2 fin, proven planform)
- PeregrineFinCan.scad v0.8.0 (L2 fin can, adapted for 75mm)
