# CATS Vega Flight Computer — Reference

Authoritative dimensions and mounting details for the CATS Vega flight computer,
sourced from the **CATS User Manual v2.0.0** (16 July 2023).

This document exists because the wrong Vega dimensions have been propagated into
rocket parts multiple times. **Consult this file before designing any mount.**

## Official Source

- Manual: https://github.com/catsystems/cats-embedded/raw/main/CATS%20User%20Manual.pdf
- Manual section: 4.1 Hardware, page 8 (specs) and 4.3.3 Mounting, page 19 (hole layout)
- Hardware repo (3D CAD, schematics): https://github.com/catsystems/cats-hardware
- Vega 3D CAD direct: https://github.com/catsystems/cats-hardware/tree/main/CATS-Vega/3D

## Board Dimensions

| Parameter | Value | Source |
|-----------|-------|--------|
| Length (L) | **100 mm** (without antenna) | Page 8 spec table |
| Width (W)  | **33 mm**  | Page 8 spec table |
| Height (H) | **15 mm** total | Page 19 Mounting section |
| Weight     | 25 g      | Page 8 spec table |

> ⚠️ **Common error: Vega_H = 21mm.** That value is wrong. The manual explicitly
> states "a total height of 15 mm" on page 19. Do not copy 21mm from any SCAD
> file without verifying here first.

## Mounting Hole Pattern

**Three mounting holes in an L-pattern.** The bottom-right corner is blank —
that's where the SMA antenna connector and pyro terminal blocks are located.

```
                      battery / switch (top edge)
    ┌─────────────────────────────────────────────┐
    │  ●                                     ●    │   ← holes A & B, 27mm apart
    │  │                                          │
    │  │ 60mm                                     │
    │  │                                          │
    │  ●                 [SMA]  [pyros]           │   ← hole C (bottom-left)
    │                                             │        no hole bottom-right
    └─────────────────────────────────────────────┘
                      pyro / SMA (bottom edge)
```

| Hole | Position (on board)     | Notes |
|------|-------------------------|-------|
| A    | Top-left  (battery end) | Near battery/switch terminal |
| B    | Top-right (battery end) | Near "+" battery terminal, 27mm from A |
| C    | Bottom-left (SMA end)   | Between UART header and CH indicators, 60mm from A |

**Mount specs:**
- Hole diameter: M3 clearance (3.4mm recommended, manual says "M3 screws")
- Spacing: 60 mm (along length) × 27 mm (across width)
- Recommended: M3 screws with additional spacers to keep electronics from touching the mount

### Hole position estimate (from image)

**Important:** The manual gives relative spacing (60 × 27) but does not publish
absolute positions on the board. Estimated from page 19 figure:

- Top holes (A, B): ~17 mm from top edge (battery end)
- Bottom hole (C): ~23 mm from bottom edge (SMA end)
- Hole A and C are both ~3 mm from left edge of board
- Hole B is ~3 mm from right edge of board

**Verify against actual board or download Vega 3D CAD from CATS hardware repo
before committing to printed parts.**

## Electrical Specifications

| Parameter | Value |
|-----------|-------|
| Input voltage | 7 – 24 V (2S–6S LiPo/Li-ion) |
| Power consumption | 100 mA |
| Pyro channels | 2 (battery voltage out, 1A continuous / 5A with solder bridge) |
| Servo channels | 2 (5V / 3A max total) |
| Low-level I/O | 1 (3.3V / 10mA, signal only — NOT for recovery actuation) |
| UART | 1 additional IO |
| Microcontroller | STM32F4 |
| Flash memory | 16 MB |
| IMU | LSM6DSO32 |
| Barometer | MS5607 |
| Radio | ISM 2.4 GHz, up to 1W (tested to 10km @100mW) |

## Antenna

- Type: External 2.4 GHz flexible dipole via SMA connector
- Approximate envelope: ~65 mm × 12 mm × 6 mm (half-wave at 2.4 GHz)
- Pigtail: ~40–50 mm RG-178/316 coax between SMA and antenna body
- **Manual warning:** "Do not mount your system in a carbon fiber section as it
  will block all RF signals. Keep your telemetry antenna away from any metallic
  objects."
- Polycarbonate (Bambu PC, used on Peregrine) is RF-transparent → OK.

## Onboard GNSS Patch Antenna

- Ceramic patch visible as the yellow square in the middle of the board
- Directional: receives from **one side only** (perpendicular to board face)
- **Manual guidance:** "Make sure the Patch Antenna on the board has a view of
  the sky for optimal GNSS reception."
- **Rocket design implication:** if Vega is mounted flat inside a body tube
  oriented vertically, the patch faces radially outward, NOT skyward. GNSS
  reception during powered vertical ascent will be degraded. Typical during
  chute descent / tumbling it recovers. For Peregrine this is acceptable
  but track integrity may be poor during boost phase.

## Other Manual Warnings Worth Reading

- Board gets hot ("HOT Surface" labeled on board). Do not touch when powered.
- Only power up once rocket is upright on launch pad. Calibration happens once
  after boot; rotating after calibration breaks state estimation.
- Pyro channels: 1A continuous default (PTC fuse). Solder jumper on back
  bypasses fuse for up to 5A continuous / 20A burst.
- Gravity vector auto-detected — no specific mounting orientation required
  *for flight computer algorithms*, but see GNSS patch caveat above.

## Standard Vega Variables for SCAD

```openscad
// ============================================
// CATS VEGA — see CATS-Vega-Reference.md
// DO NOT change these without updating the reference doc.
// ============================================
Vega_L = 100;   // Length (without antenna)
Vega_W = 33;    // Width
Vega_H = 15;    // Total height — NOT 21!

// Mounting: 3-hole L-pattern, bottom-right corner omitted (SMA + pyros there)
Vega_Mount_Spacing_L = 60;    // Hole spacing along length
Vega_Mount_Spacing_W = 27;    // Hole spacing across width
Vega_Mount_Hole_D = 3.4;      // M3 clearance

// Antenna (external 2.4 GHz dipole)
Vega_Antenna_L = 65;
Vega_Antenna_W = 12;
Vega_Antenna_H = 6;
Vega_Antenna_Cable_L = 50;
```
