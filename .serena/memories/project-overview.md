# Rocket-Parts Project Overview

OpenSCAD parametric library for 3D printed high power rocketry (HPR) components.

Forked from [DavidMFlynn/Rocket-Parts](https://github.com/DavidMFlynn/Rocket-Parts).

## Purpose

Design and generate STL files for 3D printing rocket components. All parts are parametric - dimensions can be adjusted via OpenSCAD customizer or by editing variables.

## File Organization

- **Root directory**: OpenSCAD source files (.scad)
- **STL Files/**: Pre-rendered printable models
- **Pictures/**: Reference images and renders
- **PDF Parachute/**: Parachute construction documentation
- **zOldCode/**: Archived/deprecated code

## Naming Conventions

### Body Tube Diameters (RxxLib.scad pattern)

- R54 = 54mm (2.1") - Minimum HPR
- R65 = 65mm (2.6")
- R75 = 75mm (3") - Common HPR
- R98 = 98mm (4") - Standard HPR
- R102 = 102mm (4") - Blue Tube variant
- R137 = 137mm (5.5")
- R157 = 157mm (6")
- R203 = 203mm (8")

### File Types

- `*Lib.scad` - Reusable component libraries (modules/functions)
- `Rocket*.scad` - Complete rocket designs using libraries
- `*.scad` (other) - Standalone components or utilities

## Motor Standards

Primarily designed for Aerotech RMS (Reloadable Motor System):
- 29mm, 38mm, 54mm, 75mm, 98mm motor mounts
- `AT_RMS_Lib.scad` contains motor tube dimensions

## Units

All dimensions in millimeters. SAE conversion utilities in `CommonStuffSAEmm.scad`.
