# Why OpenSCAD Files Appear Empty

## The Pattern

OpenSCAD library files contain **only module and function definitions** - nothing renders by default. This is intentional:

1. **Library files** (`*Lib.scad`) define reusable modules but render nothing
2. **Rocket design files** (`Rocket*.scad`) import libraries and also render nothing by default
3. **To see geometry**, you must uncomment lines in the `***** for STL output *****` section

## How to Render Parts

Look for commented-out lines like:
```scad
// ***********************************
//  ***** for STL output *****
//
// MotorRetainer(Tube_OD=BT54Mtr_OD, Tube_ID=BT54Mtr_ID, Mtr_OD=54, MtrAC_OD=58);
// CenteringRing(OD=PML98Body_ID, ID=PML54Body_OD, Thickness=5, nHoles=0);
```

**Uncomment the line** (remove `//`) to render that part.

Alternatively, look for `ShowRocket98();` or similar viewing functions at the bottom - uncomment to see assembled rocket.

## Import Statements

- `include<file.scad>` - Executes file, makes variables AND modules available
- `use<file.scad>` - Only makes modules available, no variable execution

## File Categories

| Type | Pattern | Purpose | Renders by Default |
|------|---------|---------|-------------------|
| Core Library | `CommonStuffSAEmm.scad` | Bolt holes, utilities | No |
| Tube Library | `TubesLib.scad` | Tube dimensions, centering rings | No |
| Component Lib | `*Lib.scad` | Reusable components | No |
| Complete Rocket | `Rocket*.scad` | Full rocket designs | No |
| Standalone | Other `.scad` | Specific parts | Usually no |

## Quick Start: See Something

1. Open `Rocket98.scad`
2. Find `//ShowRocket98();` near bottom
3. Remove `//` to uncomment
4. Press F5 (Preview) or F6 (Render)
