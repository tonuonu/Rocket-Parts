# Rocket-Parts Project Overview

OpenSCAD parametric library for 3D printed high power rocketry (HPR) components.

Forked from [DavidMFlynn/Rocket-Parts](https://github.com/DavidMFlynn/Rocket-Parts).

## Purpose

Design and generate STL files for 3D printing rocket components. All parts are parametric - dimensions can be adjusted via OpenSCAD customizer or by editing variables.

## File Organization

- **Root directory**: OpenSCAD source files (.scad) and some .3mf slicer files
- **STL Files/**: Pre-rendered printable models
- **Pictures/**: Reference images and renders
- **PDF Parachute/**: Parachute construction documentation
- **zOldCode/**: Archived/deprecated code

## File Count

~110+ .scad files, 3 .3mf files (Peregrine parts), 1 parts list (.txt)

## Naming Conventions

### Body Tube Diameters (RxxLib.scad pattern)

- R65 = 65mm (2.6")
- R75 = 75mm (3") - Common HPR
- R98 = 98mm (4") - Standard HPR
- R102UL = 102mm (4") - ULine mailing tube variant
- R137 = 137mm (5.5")
- R157 = 157mm (6")
- R203 = 203mm (8")

### File Types

- `*Lib.scad` - Reusable component libraries (modules/functions)
- `Rocket*.scad` - Complete rocket designs using libraries
- `*.scad` (other) - Standalone components, tools, or utilities
- `*.3mf` - Pre-sliced 3D print files (Peregrine project)

## Motor Standards

Primarily designed for Aerotech RMS (Reloadable Motor System):
- 29mm, 38mm, 54mm, 75mm, 98mm motor mounts
- `AT_RMS_Lib.scad` contains motor tube dimensions

## Custom/Tõnu Files

### Fins
- PeregrineFin.scad - Trapezoidal NACA 0012 fin for Peregrine (v0.7.0: Span=137mm, 2×2.2mm rod channels at 25%/60% chord, planform ~23,222mm²)
- PeregrineFin-StructuralAnalysis.md - Structural analysis (SF 1.65 at 10° AoA, carbon rod reinforcement required)

### Fin Cans
- PeregrineFinCan.scad - 3-fin can for L2 (BT98/4"), 3 fins at 0°/120°/240°, tubes at 60°/180°/300°, cord passage 21×10mm at 0° fwd ring offset 8mm
- PeregrineFinCan75.scad - 4-fin can for L3 (BT137/5.5"), split-print design, 4 fins

### Other Peregrine Parts
- PeregrineEjection.scad - Active bayonet ejection for Apogee Peregrine
- PeregrineNoseCone.scad - Nose cone for Peregrine (Bambu P1S compatible)
- PeregrineEjection.3mf / PeregrineNoseCone.3mf / PeregrineEjectioncoupler.3mf

### Documentation
- L2-PrintSettings.md - PC filament print settings (70% infill, no composite overwrap)
- L3-Design.md - Complete L3 design document (M1297W motor, 4 fins, CF cloth required)

## Units

All dimensions in millimeters. SAE conversion utilities in `CommonStuffSAEmm.scad`.
