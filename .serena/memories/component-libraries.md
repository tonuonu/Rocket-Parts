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

### SpringThingInside.scad
Ball lock parachute deployment (A.K.A. Ball Lock). Custom for LOC65 and PetalLock. MG90S servo, Rocket Servo PCB.

### CablePuller.scad
Cable puller deployment mechanism.

### CableRelease.scad
Ball lock device. Pin held by 5× 5/16" Delrin balls. Push-to-release. Supports HS-5245MG servo.

### CableReleaseBB.scad / CableReleaseBBMini.scad / CableReleaseBBMicro.scad
Ball bearing cable release variants (standard, compact, smallest).

### FairingJointLib.scad
Payload fairing separation joints.

## Ejection & Charge

### ChargeHolder.scad
Black powder ejection charge holder. Parametric well diameter and powder volume (CC). Bolt-mounted.

### PeregrineEjection.scad
Active bayonet ejection system for Apogee Peregrine (100mm body tube). Custom design by Tõnu.

### PeregrineNoseCone.scad
Nose cone for Apogee Peregrine. Designed for Bambu P1S, supports two-piece printing. Custom by Tõnu.

## Fairings

### Fairing54.scad
54mm fairing with SG90 servo, cable puller deployment, spring-loaded.

### Fairing137.scad
137mm fairing, stiffer design for large fairings. Spring-deployed.

### FairingNoseconeLib.scad
Generic fairing nosecone library. Falcon 9-style shape. Originally for BP3 (98mm ebay, 102mm fairing).

## Staging

### Stager3Lib.scad
Active staging mechanism with electronic release.

### Stager75BBLib.scad
75mm ball-bearing stager for reliable separation.

### BoosterDropperLib.scad / BoosterDropper5Lib.scad
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

## Tube Libraries (By Diameter)

### R65Lib.scad - 65mm
### R75Lib.scad - 75mm
### R98Lib.scad - 98mm
### R102ULLib.scad - 102mm ULine mailing tube parts. Ball lock with 6806 bearing.
### R137Lib.scad - 137mm
### R157Lib.scad - 157mm
### R203Lib.scad - 203mm

## Strap-On Boosters

### R75StrapOn.scad
75mm strap-on booster. 78mm diameter, 800mm long, 54mm motor. Mission Control V3.

### RU102StrapOn.scad
102mm ULine strap-on booster. 54mm motor (J460T). 300mm button spacing. Mission Control V3.

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

## Tools & Accessories

### Parachute.scad
Parachute pattern generator. Export as PDF, print at 100%. Parametric panel count and pointyness.

### ShroudLineTool.scad
Tool for shroud line work.

### TubeCutter.scad
Tubing cutter for body/coupler tubes, 29mm to 150mm.

### SmallRocketStand.scad
Rocket display stand. Uses 1/2" aluminum tubing legs.

### RocketRotiserieDrive.scad
Motorized rotisserie for coating rocket tubes. 3-stage planetary gearbox (~5.2:1). ~4 RPM for 4" tubes.

### RangeBoxBins.scad
Bins for Dewalt drawers (range box organization). Not rocket-specific.

### LegTest.scad
Test/prototype for shock absorber leg mechanism.

## Miscellaneous

### CubeSat.scad
CubeSat form factor parts (analog variant).
