# Complete Rocket Designs

## Design Pattern

Complete rockets follow the pattern `Rocket<diameter>[variant].scad` and import component libraries.

## Peregrine (Tõnu's Custom - L2/L3 Certification)

### Peregrine L2 (98mm / 4")
Apogee Peregrine kit, modified with custom 3D-printed components. 98mm body, 54mm motor mount.
- PeregrineFin.scad - NACA 0012 trapezoidal fins (v0.7.0, 3 fins)
- PeregrineFinCan.scad - Integrated fin can (3 fins at 0°/120°/240°)
- PeregrineNoseCone.scad - Custom nose cone
- PeregrineEjection.scad - Active bayonet ejection
- Target motors: H128W, I327DM, J420R
- J420R sim: Vmax=187.6 m/s, Mach 0.55, Alt=1035m
- Body tube fiberglass overwrap: R&G 201115 sleeve (100mm)
- Print material: Bambu PC, 70% infill (no composite overwrap on printed parts)

### Peregrine L3 (137mm / 5.5")
Upscaled Peregrine for L3 certification. BT137 body, 75mm motor mount.
- PeregrineFin75.scad - Composite fin core (same planform as L2)
- PeregrineFinCan75.scad - Split-print fin can (4 fins, changed from 3)
- L3-Design.md - Complete design document
- Motor: AeroTech M1297W-PS (5417 N·s)
- Total length: ~1741mm, loaded mass ~9.7-9.9 kg
- Fin construction: 7mm PPS core + 2×0.75mm CF cloth = 8.5mm total
- Branch: feature/fincan75, PR #7, Issue #6

## 38mm Rockets

### RocketU38.scad
38mm ULine mailing tube, 29mm motor. Motors: G74W, H235T. Built and ground tested 9/2025.

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

### Rocket75A.scad
75mm variant A.

### Rocket75C.scad
75mm body, 54mm motor. Target motor L1000W. Dual deploy with Mission Control V3 / RocketServo X2.

### Rocket75D.scad / Rocket75D2.scad
75mm variants D configurations.

### RocketOmega75.scad
75mm Omega-style design.

## 98mm (4") Rockets - Most Developed

### Rocket98.scad - "The Red One"
Apogee-only deploy, 5 fins, 54mm motor. Cable Puller deployment, Mission Control V3.

### Rocket98Dual.scad - "The Green One"
Dual deploy capable. 3x Cable Puller, Spring Thing, Stager, Fairing. First flight: J350W-P, 2600ft.

### Rocket98C.scad
98mm variant C configuration.

### Rocket98D.scad
98mm variant D configuration.

### Rocket98G.scad
98mm body, 54mm motor. Different fin shape from Rocket98. See Rocket98Dual.scad for forward section.

### Rocket98Goblin.scad
Goblin-style 98mm design.

### Rocket98IceProbe.scad
Payload-focused 98mm design.

### Rocket98Stabber.scad
Pointed nose 98mm variant.

## 102mm (ULine 4") Rockets

### Rocket102UL.scad
ULine 4" mailing tube, 54mm motor. Dual deploy with Mission Control V3 / RocketServo. PETG-CF printed.

### Rocket10252D.scad
ULine 4" mailing tube, 54mm motor, dual deploy. Similar to Rocket102UL.

### Rocket1025175.scad
ULine 4" mailing tube, 75mm motor. Dual deploy. PETG-CF printed.

## 137mm (5.5") Rockets

### RocketOmega.scad
5.5" upscale of Estes Astron Omega. Two-stage with 137mm body.

### RocketOmegaU157.scad
157mm upscale Omega.

## 157mm (6") Rockets

### Rocket157.scad
Big fat mailing tube rocket. 75mm single grain motor K750ST-PS.

## 203mm (8") Rockets

### Rocket20351D.scad
Level 3 rocket. 203mm mailing tube, five fins, single stage, dual deploy, redundant electronics, non-pyro deployment. Target: L3 cert in 7000ft AGL. PETG+CF fins and nosecone.

## Multi-Stage Rockets

### Rocket9832.scad
Two-stage 98mm → 32mm sustainer. Booster: J800T-P, Sustainer: K185W-P. 2x Mission Control V3.

### Rocket9852.scad
Two-stage 98mm, 5 fins. Motors: J460T/J275W and J180T/J90W-P/I115W-P. Flew to 4200' on J615ST → J275W. Skill level 11. Non-pyro staging.

### Rocket13732.scad
Two-stage 137mm → 32mm. Booster: 54mm + 3x 38mm cluster. Sustainer: 54mm. 3/4/5 fin options.

### Rocket1379852.scad
Two-stage: 137mm booster (K1000T-P, 75mm motor) → 98mm sustainer (K270W-P, 54mm motor). 3-5 fins.

### Rocket_Toad.scad
Two-stage 137mm body. J460T-P to J180W-P. Designed to be as short as possible.

### RocketBoosterPooper3/4/5.scad
Parallel staging with strap-on boosters. 4" core with 2" strap-ons. Work in progress.

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

### CinerocU157.scad
Camera rocket 157mm.

### SCR_Beta.scad
Sounding rocket beta design.

### Rocket_Loc_Graduator.scad
Parts for LOC Graduator kit. MG90S servo, MR84-2RS bearings, STB mechanism.

## Non-flight 3MF Files

- PeregrineEjection.3mf - Pre-sliced ejection system
- PeregrineNoseCone.3mf - Pre-sliced nose cone
- PeregrineEjectioncoupler.3mf - Pre-sliced ejection coupler

## Altimeter

Designs use Mission Control V3 altimeter. Bays sized accordingly.
CATS Vega flight computer also being integrated for Peregrine (100×33mm board, 3×M3 mounting).
