# PeregrineFin Structural Analysis

## Overview

Structural assessment of the 3D-printed Peregrine fin under aerodynamic
bending loads, with particular attention to layer adhesion failure in the
print orientation. Analysis covers baseline strength, rod channel
reinforcement options, and safety margins.

## Fin Geometry

| Parameter | Value |
|---|---|
| Root chord | 249 mm |
| Tip chord | 90 mm |
| Span | 114 mm |
| LE sweep | 120 mm |
| Root thickness | 6.35 mm (t/c = 2.55%) |
| Tip thickness | 4.45 mm (t/c = 4.94%, tapers to 70%) |
| Planform area | 19,323 mm² |
| Aspect ratio | 0.67 |
| Airfoil | NACA symmetric (0012-like coefficients) |

### Cross-Section Properties (Root)

For a NACA symmetric airfoil, the second moment of area about the
thickness axis is approximately:

    I_xx ≈ 0.036 × chord × thickness³

At root:

    I_root = 0.036 × 249 × 6.35³ = 2,295 mm⁴
    A_cross ≈ 0.68 × 249 × 6.35 = 1,075 mm²

## Print Orientation and Critical Failure Mode

The fin is printed standing on its trailing edge, rotated 90° so each
printed layer forms one airfoil cross-section slice. Layer lines run
chord-wise (leading edge to trailing edge).

**Critical loading:** Aerodynamic forces act normal to the fin planform
(from angle of attack or wind gusts). This bending loads the fin in the
span-wise direction, meaning tensile and compressive stresses act
**across layer boundaries** — the weakest direction for FDM prints.

This is the expected failure mode: layer delamination at the root under
bending, not in-plane fracture.

## Flight Conditions

Estimated for Peregrine on AeroTech J420R motor:

| Parameter | Value |
|---|---|
| Peak velocity | ~250 m/s (Mach 0.73) |
| Air density (sea level) | 1.225 kg/m³ |
| Dynamic pressure q | 38,281 Pa (38.3 kPa) |

### Angle of Attack Cases

Effective angle of attack from wind gusts, launch rod whip, or
asymmetric thrust. 5° is normal flight, 10° is a strong gust, 15° is
extreme.

Normal force coefficient per fin (thin airfoil theory with finite AR
correction):

    CN_alpha = 2π / (1 + 2/AR) = 2π / (1 + 2/0.67) = 1.576 /rad

| AoA | CN | Force/fin | Root moment | Root stress |
|---|---|---|---|---|
| 5° | 0.138 | 102 N (10.4 kg) | 4,654 N·mm | 6.4 MPa |
| 10° | 0.276 | 204 N (20.8 kg) | 9,309 N·mm | 12.9 MPa |
| 15° | 0.414 | 306 N (31.2 kg) | 13,963 N·mm | 19.3 MPa |

Root bending moment uses center of pressure at 40% span (appropriate
for tapered planform):

    M = F × (0.40 × Span) = F × 45.6 mm

Root bending stress:

    σ = M × (thickness/2) / I_root

## Material Properties — Bambu PC

Bambu PC (polycarbonate) filament, printed with 50% gyroid infill.

| Property | Along layers | Across layers (critical) |
|---|---|---|
| Tensile strength | ~60 MPa | ~35 MPa |
| Elastic modulus | ~4,200 MPa | ~3,500 MPa |
| Elongation at break | ~6% | ~2% |

The across-layer values are conservative estimates for well-bonded PC
with enclosed chamber printing at appropriate temperatures (nozzle
~270°C, bed 110°C, chamber >50°C). Poor layer adhesion can reduce
cross-layer strength to 20–25 MPa. Good drying and high chamber
temperature are essential.

**For comparison — other filaments across layers:**

| Material | Across-layer tensile | Notes |
|---|---|---|
| PLA | ~25 MPa | Brittle, poor layer adhesion |
| PETG | ~30 MPa | Better adhesion than PLA |
| ASA | ~28 MPa | Moderate |
| PC (Bambu) | ~35 MPa | Good adhesion, tough |

## Safety Factors — Baseline (No Rods)

Design safety factor target: ≥2.0 for hobby rocketry.

Using across-layer strength of 35 MPa for Bambu PC:

| AoA | Stress | Safety Factor | Assessment |
|---|---|---|---|
| 5° | 6.4 MPa | 5.47 | Excellent |
| 10° | 12.9 MPa | 2.72 | Adequate |
| 15° | 19.3 MPa | 1.81 | Marginal |

**Conclusion:** Bambu PC without reinforcement is adequate for normal
flight (SF > 2.7 at 10° AoA) but marginal under extreme gust loading.
PLA would be marginal even at 10° (SF = 1.94).

## Rod Channel Design

Two channels running span-wise through the fin, accessible from the tab
face for inserting reinforcement material.

### Channel Geometry

| Parameter | Forward channel | Aft channel |
|---|---|---|
| Chord position | 25% local chord | 60% local chord |
| Z position | 0 (centerline) | 0 (centerline) |
| Root X | 62.3 mm | 149.4 mm |
| Tip X | 142.5 mm (Sweep + 25% Tip) | 174.0 mm (Sweep + 60% Tip) |
| Root spacing | 87 mm | — |
| Tip spacing | 31 mm | — |
| Diameter | 2.2 mm (for 2mm rods + 0.1mm clearance per side) |
| Length | ~150 mm each (root tab face to tip) |
| Minimum wall | 0.58 mm (aft channel at tip) |

Channels are straight (hull of two spheres in OpenSCAD), following the
local chord fraction from root to tip. The sweep causes both channels to
angle forward along the span.

### Why Horizontal Spread at Z=0

Placing rods at Z=0 (neutral axis) rather than offset vertically:

1. **The fin is only 6.35mm thick at root, 4.45mm at tip.** Two 2.2mm
   channels stacked vertically would overlap or leave paper-thin walls.

2. **Primary purpose is delamination resistance, not bending stiffness.**
   Rods at Z=0 don't add bending stiffness (they're on the neutral axis)
   but they provide continuous span-wise material that crosses every
   printed layer boundary. This is the critical failure mode.

3. **Spreading chord-wise covers more of the fin.** Two channels 87mm
   apart at the root mean reinforcement in both the forward and aft
   regions of the airfoil.

### Impact of Empty Channels

If no rods are inserted and channels are left empty:

    Area lost: 2 × π × (1.1)² = 7.6 mm² (0.7% of 1,075 mm²)
    I lost: 2 × [π(1.1)⁴/4 + π(1.1)² × 0²] = 4.6 mm⁴ (0.2% of 2,295)

**Negligible.** Empty channels do not meaningfully weaken the fin.

## Reinforcement Options

### Option 1: 2mm Pultruded Carbon Fiber Rods

Pultruded carbon rods have continuous unidirectional fibers aligned along
the rod axis — ideal for bridging layer boundaries.

| Property | Value |
|---|---|
| Diameter | 2.0 mm |
| Elastic modulus | ~150,000 MPa |
| Tensile strength | ~1,500 MPa |
| Stiffness ratio E_carbon/E_PC | 36× |

Per rod:

    I_rod = π × 2⁴ / 64 = 0.79 mm⁴
    Equivalent PC I = 0.79 × 150,000/4,200 = 28 mm⁴

Two rods at Z=0 (no parallel axis contribution):

    I_effective = 2,295 + 2 × 28 = 2,351 mm⁴ (+2.4%)

The stiffness improvement is modest because the rods sit on the neutral
axis. However, the rods physically prevent layer separation by acting as
continuous span-wise fibers bonded with epoxy to the surrounding
plastic. This changes the failure mode from brittle delamination to a
more ductile fiber-pullout mechanism.

**Sources:** RC hobby shops, drone suppliers, online (search "2mm carbon
fiber rod pultruded"). Available in 1m lengths. Cut to ~150mm with a
rotary tool. Rough surface with 220-grit sandpaper before bonding.

### Option 2: Epoxy Fill

Fill channels with thickened epoxy (e.g., West System 105/205 with 407
Low-Density filler or milled carbon fiber).

| Property | Value |
|---|---|
| Elastic modulus (neat epoxy) | ~3,000 MPa |
| Tensile strength | ~50–70 MPa |

Stiffness contribution is small (~1%), but the epoxy bonds to the
channel walls and creates a continuous span-wise material that resists
layer separation. Simpler than inserting rods.

### Option 3: Carbon Rod + Epoxy (Recommended)

Insert rod, coat with epoxy, fill remaining gap. The rod provides high
tensile strength along the span; the epoxy bonds it to every layer it
passes through. This is standard practice in reinforced 3D-printed
RC aircraft wings.

**Installation:**
1. Dry-fit rod to check length (~150mm)
2. Mix slow-cure epoxy (30-minute pot life recommended)
3. Coat rod with epoxy
4. Slide into channel from tab face
5. Top up channel entry with epoxy
6. Cure horizontally (fin flat) so epoxy doesn't drain out

### Option 4: Leave Empty

With Bambu PC and good print settings, baseline SF = 2.72 at 10° AoA.
This is adequate for L1/L2 flights. The channels remain as insurance —
if a fin shows signs of weakness, reinforce it post-print.

## Summary

| Configuration | Root I (mm⁴) | SF at 10° AoA | Recommendation |
|---|---|---|---|
| Bambu PC, no channels | 2,295 | 2.72 | Adequate |
| Bambu PC, empty channels | 2,291 | 2.71 | Negligible penalty |
| Bambu PC + 2mm carbon rods | 2,351 | 2.72 (+ delam resistance) | Recommended |
| Bambu PC + epoxy fill | 2,309 | 2.72 (+ delam resistance) | Good alternative |
| PLA, no channels | 2,295 | 1.94 | Marginal — not recommended |

The rod channels add delamination resistance with negligible weight or
structural penalty when empty. Reinforcement with 2mm carbon rods or
epoxy is recommended but optional for Bambu PC.

## Assumptions and Limitations

1. **Thin airfoil theory** used for CN_alpha — valid for this subsonic regime
   (Mach 0.73) and low aspect ratio.
2. **Uniform load distribution** assumed for center of pressure at 40% span.
   Real distribution is more complex but conservative for root moment.
3. **Cross-layer strength of 35 MPa** assumes good print conditions (dry
   filament, enclosed chamber, proper temperatures). Test coupons
   recommended for critical flights.
4. **Static analysis only.** Flutter, fatigue, and vibration not assessed.
   For L1/L2 flights with total impulse under 1280 N·s, these are
   unlikely to be limiting.
5. **50% gyroid infill** assumed. Lower infill reduces cross-section
   strength roughly proportionally.
6. **NACA section properties** approximated with empirical coefficients
   (I = 0.036 × c × t³). Exact integration gives similar values.
