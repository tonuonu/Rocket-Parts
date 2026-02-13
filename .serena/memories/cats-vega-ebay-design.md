# CATS Vega Flight Computer - Mounting Specs

## Board Dimensions
- Length: 100mm
- Width: 33mm
- Total height: 15mm

## Mounting Holes
- 3× M3 screw holes
- Pattern: 60mm × 27mm spacing
- Spacers recommended to keep electronics off mounting surface

## Mounting Notes
- No specific orientation required (auto-detects gravity vector)
- Must be in radio-transparent section (fiberglass or cardboard, NOT carbon fiber)
- GNSS patch antenna needs sky view
- Keep telemetry antenna away from metallic objects
- 3D files available from CATS github

## Peregrine Integration Notes
- Target tube: Body_OD=101.5mm, Body_ID=99.0mm (from PeregrineEjection.scad)
- Closest library tube: BT98 (OD=101.9mm, ID=98.9mm)
- 33mm board width fits easily inside 99mm ID
- Design approach: keep current library style (Alt_BayDoorFrame pattern)
- Existing Alt_BayDoorFrame designed for MissionControl V3 — needs door resizing for CATS Vega
- Door must accommodate 33mm board width plus side connectors (screw terminals, SMA)

## Library Pattern for Electronics Bays (from Rocket98.scad example)
1. `Tube()` — tube section
2. `CenteringRing()` — top and bottom (typically 15mm inset from ends)
3. `Alt_BayFrameHole()` — difference cut for door opening
4. `Alt_BayDoorFrame()` — door mounting frame
5. Coupler/bolt interfaces for adjacent sections
