# PeregrineFin Structural Analysis

## Overview

Structural assessment of the 3D-printed Peregrine fin under aerodynamic
bending loads, with particular attention to layer adhesion failure in the
print orientation. Analysis covers two velocity scenarios, two print
orientations, rod channel reinforcement options, and safety margins.

## Fin Geometry

| Parameter | Value |
|---|---|
| Root chord | 249 mm |
| Tip chord | 90 mm |
| Span | 137 mm |
| LE sweep | 120 mm |
| Root thickness | 6.35 mm (t/c = 2.55%) |
| Tip thickness | 4.45 mm (t/c = 4.94%, tapers to 70%) |
| Planform area | 23,222 mm² |
| Aspect ratio | 0.81 |
| Airfoil | NACA symmetric (0012-like coefficients) |

### Cross-Section Properties (Root)

For a NACA symmetric airfoil, the second moment of area about the
thickness axis is approximately:

    I_xx ≈ 0.036 × chord × thickness³ = 0.036 × 249 × 6.35³ = 2,295 mm⁴
    A_cross ≈ 0.68 × 249 × 6.35 = 1,075 mm²

## Print Orientations

### Option A: Full fin on trailing edge (Render_Part=1)

The original orientation. Each printed layer forms one airfoil
cross-section slice. Layer lines run chord-wise (LE to TE).

**Critical bending axis:** Span-wise bending loads stress **across layer
boundaries** — the weakest direction for FDM prints. Relevant strength:
**35 MPa** (cross-layer, Bambu PC).

**Advantage:** Smooth airfoil surfaces straight off the printer (hundreds
of layers define each cross-section).

### Option B: Split at 60% chord, each half on cut face (Render_Part=2/3)

The fin is cut along the 60% chord rod channel line. Each half prints
standing on the cut face. Layers stack chord-wise.

**Critical bending axis:** Span-wise bending loads stress **along layers**
— the strong direction. Relevant strength: **60 MPa** (along-layer,
Bambu PC).

**Assembly:** The 2mm carbon rod at 60% chord sits in half-round channels
on each cut face, providing self-centering alignment. Epoxy the joint.
The 25% chord rod remains fully enclosed inside the forward (LE) half.

**Advantage:** 1.7× higher effective strength in the bending direction.
**Tradeoff:** Two prints per fin, bonding step, seam at 60% chord.

## Flight Conditions

### Velocity Scenarios

Two velocity cases are analyzed:

| Scenario | Motor | Peak velocity | Mach | Dynamic pressure q |
|---|---|---|---|---|
| **Current: J420R** | AeroTech J420R (ORK L2 sim) | 187.6 m/s | 0.55 | 21,556 Pa |
| **Future: larger motor** | Higher-impulse J or K class | 250 m/s | 0.74 | 38,281 Pa |

The J420R values come from the PeregrineL2.ork OpenRocket simulation.
The 250 m/s case covers potential future flights with faster motors.

### Aerodynamic Loads

Normal force coefficient per fin (thin airfoil theory with finite AR
correction):

    CN_alpha = 2π / (1 + 2/AR) = 2π / (1 + 2/0.81) = 1.808 /rad

Root bending moment uses center of pressure at 40% span (appropriate
for tapered planform):

    M = F × (0.40 × Span) = F × 54.8 mm

Root bending stress:

    σ = M × (thickness/2) / I_root

#### J420R (187.6 m/s)

| AoA | CN | Force/fin | Root moment | Root stress |
|---|---|---|---|---|
| 5° | 0.158 | 79 N (8.1 kg) | 4,329 N·mm | 6.0 MPa |
| 10° | 0.316 | 158 N (16.1 kg) | 8,658 N·mm | 12.0 MPa |
| 15° | 0.473 | 237 N (24.2 kg) | 12,987 N·mm | 18.0 MPa |

#### Future larger motor (250 m/s)

| AoA | CN | Force/fin | Root moment | Root stress |
|---|---|---|---|---|
| 5° | 0.158 | 140 N (14.3 kg) | 7,688 N·mm | 10.6 MPa |
| 10° | 0.316 | 281 N (28.6 kg) | 15,375 N·mm | 21.3 MPa |
| 15° | 0.473 | 421 N (42.9 kg) | 23,063 N·mm | 31.9 MPa |

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

## Safety Factors

Design safety factor target: ≥2.0 for hobby rocketry.

### Option A: Full fin, standing on trailing edge (cross-layer: 35 MPa)

| AoA | J420R (187.6 m/s) | 250 m/s |
|---|---|---|
| 5° | **5.84** Excellent | **3.29** Good |
| 10° | **2.92** Good | **1.65** Below target |
| 15° | **1.95** Marginal | **1.10** Inadequate |

### Option B: Split-print, halves on cut face (along-layer: 60 MPa)

| AoA | J420R (187.6 m/s) | 250 m/s |
|---|---|---|
| 5° | **10.01** Excellent | **5.64** Excellent |
| 10° | **5.01** Excellent | **2.82** Good |
| 15° | **3.34** Good | **1.88** Marginal |

### Summary

| Configuration | SF at 10° AoA (J420R) | SF at 10° AoA (250 m/s) |
|---|---|---|
| Option A (full, cross-layer) | 2.92 | 1.65 |
| Option A + carbon rods | 2.92 + delam resistance | 1.68 + delam resistance |
| Option B (split, along-layer) | 5.01 | 2.82 |
| PLA, Option A | 2.09 | 1.18 |

**For J420R:** Option A without reinforcement is adequate (SF 2.92).
Carbon rods add delamination resistance as insurance.

**For 250 m/s motors:** Option A drops below 2.0 at 10° AoA. Either use
Option B (split-print) for SF 2.82, or add carbon rod reinforcement to
Option A for delamination resistance (bending SF still 1.65, but failure
mode changes from brittle delamination to more ductile).

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
| Length | ~176 mm (fwd), ~158 mm (aft) — root tab face to tip |
| Minimum wall | 0.58 mm (aft channel at tip) |

Channels are straight (hull of two spheres in OpenSCAD), following the
local chord fraction from root to tip. The sweep causes both channels to
angle forward along the span.

**Note:** Early development used 3.2mm channels (visible in git history
commit c07af82). The design settled on 2.2mm channels for 2mm pultruded
carbon rods, which are widely available and provide sufficient
reinforcement for this application.

### Split-Print Joint (Option B)

When printed as two halves, the aft rod channel (60% chord) is bisected
by the cut plane, creating half-round grooves on each cut face. The
2mm carbon rod drops into these grooves, acting as:

1. **Alignment dowel** — self-centers the halves during glue-up
2. **Structural pin** — carries shear across the joint
3. **Delamination resistance** — continuous span-wise reinforcement

Joint shear capacity: π × 2mm × 158mm × 20 MPa ≈ 19,800 N, versus
max aero force of 281 N at 10° AoA (250 m/s). Safety factor: 70×.

### Why Horizontal Spread at Z=0

Placing rods at Z=0 (neutral axis) rather than offset vertically:

1. **The fin is only 6.35mm thick at root, 4.45mm at tip.** Two 2.2mm
   channels stacked vertically would overlap or leave paper-thin walls.

2. **Primary purpose is delamination resistance, not bending stiffness.**
   Rods at Z=0 don't add bending stiffness (they're on the neutral axis)
   but they provide continuous span-wise material that crosses every
   printed layer boundary. This is the critical failure mode for Option A.

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

**Sources:** RC hobby shops, drone suppliers, AliExpress (0.5m × 8pcs
packs). Cut to ~160–180mm with a rotary tool. Rough surface with
220-grit sandpaper before bonding.

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
1. Dry-fit rod to check length (~160–180mm depending on channel)
2. Mix slow-cure epoxy (30-minute pot life recommended)
3. Coat rod with epoxy
4. Slide into channel from tab face
5. Top up channel entry with epoxy
6. Cure horizontally (fin flat) so epoxy doesn't drain out

### Option 4: Leave Empty

For J420R flights (187.6 m/s), Option A baseline SF = 2.92 at 10° AoA —
adequate without reinforcement. The channels remain as insurance.

For faster motors (250+ m/s), **leaving channels empty is not
recommended** in Option A (SF 1.65). Use Option B (split-print) or
reinforce with carbon rods.

## Assumptions and Limitations

1. **Thin airfoil theory** used for CN_alpha — valid for this subsonic regime
   (Mach 0.55–0.74) and low aspect ratio.
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
7. **Split-print joint** analysis assumes proper epoxy bonding of cut
   faces and rod. Poor bonding would negate the orientation advantage.
