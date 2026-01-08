# Complete Rocket Designs

## Design Pattern

Complete rockets follow the pattern `Rocket<diameter>[variant].scad` and import component libraries.

## 54mm Rockets

### Rocket54.scad
Minimum diameter HPR rocket. 54mm body, 38mm motor.

### RocketLoc54.scad
LOC Precision style 54mm rocket.

### RocketOmega54.scad
Omega-style 54mm design.

## 65mm Rockets

### Rocket65.scad
2.6" body tube rocket.

### Rocket6551.scad / Rocket6552.scad
65mm variants with different configurations.

## 75mm (3") Rockets

### Rocket75.scad
Basic 75mm single-stage.

### Rocket75A/C/D/D2.scad
Variants with different fin configurations and features.

### RocketOmega75.scad
75mm Omega-style design.

## 98mm (4") Rockets - Most Developed

### Rocket98.scad - "The Red One"
Apogee-only deploy, 5 fins, 54mm motor.
- Cable Puller deployment
- Mission Control V3 altimeter

### Rocket98Dual.scad - "The Green One"
Dual deploy capable.
- 3x Cable Puller, Spring Thing, Stager, Fairing
- First flight: J350W-P, 2600ft

### Rocket98C.scad
98mm variant C configuration.

### Rocket98Goblin.scad
Goblin-style 98mm design.

### Rocket98IceProbe.scad
Payload-focused 98mm design.

### Rocket98Stabber.scad
Pointed nose 98mm variant.

## Multi-Stage Rockets

### Rocket9832.scad
Two-stage 98mm -> 32mm sustainer.
- Booster: 54mm motor (J800T-P)
- Sustainer: 54mm motor (K185W-P)
- 2x Mission Control V3

### Rocket13732.scad
Two-stage 137mm -> 32mm.
- Booster: 54mm + 3x 38mm cluster
- Sustainer: 54mm motor
- 3, 4, or 5 fin options

### RocketBoosterPooper3/4/5.scad
Parallel staging with strap-on boosters.
- 4" core with 2" strap-ons
- Work in progress

## Specialty Designs

### Rocket9Ball.scad
Spherical payload section.

### RocketMiniNuke.scad
Compact high-performance design.

### RocketScooter.scad
Fast-build simple design.

### RocketSkippy.scad
Lightweight design.

### RocketStubby.scad
Short, wide configuration.

### RocketOmegaU157.scad
157mm upscale Omega.

### SCR_Beta.scad
Sounding rocket beta design.

### CinerocU157.scad
Camera rocket 157mm.

## Altimeter

Designs use Mission Control V3 altimeter. Bays sized accordingly.
