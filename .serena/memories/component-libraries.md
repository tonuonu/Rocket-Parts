# Component Libraries Reference

## Core Structural Components

### TubesLib.scad
Body tube definitions, couplers, tube sections. Central dependency for most designs.

### NoseCone.scad
Parametric nose cones: ogive, conical, elliptical, Von Karman profiles.

### Fins.scad
Fin generation: trapezoidal, clipped delta, elliptical. Includes fin can integration.

### FinCan2Lib.scad
Integrated fin can assemblies with motor mount, centering rings, fin slots.

### TransitionLib.scad
Body tube transitions/reducers between different diameters.

## Deployment Systems

### PetalDeploymentLib.scad
Petal-style parachute deployment mechanism. Spring-loaded petals.

### SpringEndsLib.scad / SpringThing*.scad
Spring-based deployment systems. Drogue/main separation.

### CablePuller.scad / CableRelease*.scad
Servo-actuated cable release mechanisms for deployment.
- CableReleaseBB.scad - Ball bearing variant
- CableReleaseBBMini.scad - Compact version
- CableReleaseBBMicro.scad - Smallest variant

### FairingJointLib.scad
Payload fairing separation joints.

## Staging

### Stager3Lib.scad
Active staging mechanism with electronic release.

### Stager75BBLib.scad
75mm ball-bearing stager for reliable separation.

### BoosterDropper*.scad
Booster separation/drop mechanisms for parallel staging.

## Electronics & Avionics

### ElectronicsBayLib.scad
Parametric electronics bay with sled mounting.

### AltBay.scad
Altimeter bay housing.

### BatteryHolderLib.scad
Battery retention: 9V, 18650, LiPo configurations.

### EggFinderCase.scad
GPS tracker housing (EggFinder/EggTimer).

## Motor Hardware

### AT_RMS_Lib.scad
Aerotech RMS motor dimensions: 29mm through 98mm.

### ATCase.scad
Motor case dimensions and retainer rings.

### MotorPodLockLib.scad
Removable motor pod locking mechanism.

### CaseHolders.scad
Motor case retention systems.

## Launch Equipment

### RailGuide.scad
Launch rail buttons/guides for 1010, 1515 rail.

### LaunchPad.scad
Portable launch pad components.

## Utilities

### CommonStuffSAEmm.scad
Shared utilities: SAE/metric conversion, common shapes, helper modules.

### ThreadLib.scad
Threaded connections for assembly.

### BearingLib.scad
Bearing dimensions and mounts.

### DoorLib.scad
Access doors/hatches for electronics bays.

### RacewayLib.scad
Wire routing channels.

### involute_gears.scad
Gear generation for mechanisms.

## Servo Libraries

- SG90ServoLib.scad - 9g micro servo
- HD0411MGServoLib.scad - Metal gear servo
- LD-20MGServoLib.scad - 20kg servo

## Camera Mounts

### CameraBay.scad
Onboard camera housing.

### GoProCamLib.scad
GoPro mounting system.
