# Graph Report - .  (2026-04-18)

## Corpus Check
- 52 files · ~172,087 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 311 nodes · 402 edges · 23 communities detected
- Extraction: 96% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 14 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Peregrine L2 Fin Structural Design|Peregrine L2 Fin Structural Design]]
- [[_COMMUNITY_BoosterPooper Staging & Recovery Electronics|BoosterPooper Staging & Recovery Electronics]]
- [[_COMMUNITY_29mm Motor Adapter Parametric|29mm Motor Adapter Parametric]]
- [[_COMMUNITY_Cineroc Camera Payload (DorfflerJerauld)|Cineroc Camera Payload (Dorffler/Jerauld)]]
- [[_COMMUNITY_BoosterPooper4 Three-Body CAD|BoosterPooper4 Three-Body CAD]]
- [[_COMMUNITY_75mm Airframe (Rocket75 family)|75mm Airframe (Rocket75 family)]]
- [[_COMMUNITY_Rocket 1379852 Kit Assembly|Rocket 1379852 Kit Assembly]]
- [[_COMMUNITY_102UL Ultralight Airframe|102UL Ultralight Airframe]]
- [[_COMMUNITY_102UL Internals Dual-Deploy|102UL Internals Dual-Deploy]]
- [[_COMMUNITY_Ball Lock 75 Recovery Mechanism|Ball Lock 75 Recovery Mechanism]]
- [[_COMMUNITY_SpringThing2 Deployment Assembly|SpringThing2 Deployment Assembly]]
- [[_COMMUNITY_Parachute 12P45 Pattern (David Flynn)|Parachute 12P45 Pattern (David Flynn)]]
- [[_COMMUNITY_Parachute 10P32 Pattern|Parachute 10P32 Pattern]]
- [[_COMMUNITY_CableReleaseBB Detent Mechanism|CableReleaseBB Detent Mechanism]]
- [[_COMMUNITY_Rocket98 Goblin Assembly|Rocket98 Goblin Assembly]]
- [[_COMMUNITY_BoosterPooper4 Section Overview|BoosterPooper4 Section Overview]]
- [[_COMMUNITY_Omega Minimum-Diameter Family|Omega Minimum-Diameter Family]]
- [[_COMMUNITY_Carbon-Fiber Rod Fin Reinforcement|Carbon-Fiber Rod Fin Reinforcement]]
- [[_COMMUNITY_LOC Graduator Reference Kit|LOC Graduator Reference Kit]]
- [[_COMMUNITY_GoPro Onboard Camera Payload|GoPro Onboard Camera Payload]]
- [[_COMMUNITY_SmallRocketStand GSE|SmallRocketStand GSE]]
- [[_COMMUNITY_Fallout4 Mini-Nuke Prop|Fallout4 Mini-Nuke Prop]]
- [[_COMMUNITY_Mini-Nuke Reference Project|Mini-Nuke Reference Project]]

## God Nodes (most connected - your core abstractions)
1. `LOC Goblin Rocket Kit (Model 07664)` - 20 edges
2. `Cineroc camera payload` - 18 edges
3. `Rocket 75C (2.1" body, dual deploy option)` - 15 edges
4. `Peregrine L3 Certification Rocket` - 10 edges
5. `PeregrineFin (3D-Printed L2 Fin)` - 10 edges
6. `Rocket 75A - minimal variant with purple nosecone, short yellow ebay, purple swept fins` - 10 edges
7. `Rocket 75C - long yellow nosecone payload section, no visible ebay window, yellow fins` - 10 edges
8. `Rocket 75D - mid-body yellow ebay section between two blue body tubes, yellow fins` - 10 edges
9. `PeregrineFin75.scad v0.1.0/v0.2.0` - 9 edges
10. `Ball Lock Unit 75 Assembly` - 9 edges

## Surprising Connections (you probably didn't know these)
- `LOC Goblin Rocket Kit (Model 07664)` --inspires_custom_parachute_design--> `Parachute pattern 8 panels, D=20`  [AMBIGUOUS]
  Pictures/Goblin.pdf → PDF Parachute/Parachute8P20.pdf
- `Rocket 75C (2.1" body, dual deploy option)` --related_dual_deploy_design--> `Rocket 98 'The Red One' (4", 54mm motor, 5 fins)`  [AMBIGUOUS]
  Rocket75C_PartsList.txt → README.md
- `PeregrineFin75.scad v0.1.0/v0.2.0` --design_evolves_from--> `PeregrineFin (3D-Printed L2 Fin)`  [INFERRED]
  L3-Design.md → PeregrineFin-StructuralAnalysis.md
- `Print Option B: Split at 60% Chord, Halves on Cut Face` --informs_choice--> `Split-Print Fin Can (P1S 250mm limit)`  [INFERRED]
  PeregrineFin-StructuralAnalysis.md → L3-Design.md
- `PC (Polycarbonate) Filament` --same_material_family--> `Bambu PC Filament (layer-anisotropic)`  [INFERRED]
  L3-Design.md → PeregrineFin-StructuralAnalysis.md

## Communities

### Community 0 - "Peregrine L2 Fin Structural Design"
Cohesion: 0.06
Nodes (46): PeregrineFinCan v0.8.0 (L2), PeregrineFin v0.7.0 (L2), AeroTech J420R (38mm, RMS-38/720), Peregrine L2 Certification Rocket (4"), Solid PC Fin (8 wall loops, no infill), L2 Flutter Margin (~200-220 m/s V_flutter), Bambu P1S 3D Printer with AMS, Barrowman Stability Equations (+38 more)

### Community 1 - "BoosterPooper Staging & Recovery Electronics"
Cohesion: 0.07
Nodes (32): Mission Control V3 Altimeter, BoosterPooper Parallel-Staged Rocket (4", WIP), Cable Puller (deployment device), Fairing (deployment device), AeroTech I284W-P Motor, AeroTech J350W-P Motor, AeroTech J800T-P Motor, AeroTech K185W-P Motor (+24 more)

### Community 2 - "29mm Motor Adapter Parametric"
Cohesion: 0.1
Nodes (22): 29mm motor adapter, 38mm motor adapter, Thick-wall pre-slotted body tube, Plywood centering rings, CP Location 36.14 in (91.8 cm) from nose tip, Max Diameter 3.900 in (9.91 cm), Fin Count 4, Fin Span 18.250 in (46.36 cm) (+14 more)

### Community 3 - "Cineroc Camera Payload (Dorffler/Jerauld)"
Cohesion: 0.1
Nodes (21): Base OD 1.645 in, Cineroc camera payload, Mike Dorffler (original designer), Mike Jerauld (drawing, 4/17/2002), Fairing (lens/window), Fairing height 0.465 in (right 0.315, left 0.325), Fairing length 1.832 in, Indexing Block (part of base piece) (+13 more)

### Community 4 - "BoosterPooper4 Three-Body CAD"
Cohesion: 0.13
Nodes (20): Central core stage (yellow body with blue bands and swept fins) of BoosterPooper4, Central ebay/avionics section (yellow cylinder with access port and antenna pins) on the core of BoosterPooper4, Large yellow swept-delta fin set (three fins) on BoosterPooper4 core, RocketBoosterPooper4 - CAD render of BoosterPooper4 three-body rocket with yellow core, two blue/yellow strap-on boosters, large yellow swept fins, and visible ebay section, Strap-on booster pair (blue body tube, yellow nosecone) flanking the core stage of BoosterPooper4, Centering Ring / Perforated Plate Stack, Flanged Base Plate, Latching Pawls (+12 more)

### Community 5 - "75mm Airframe (Rocket75 family)"
Cohesion: 0.26
Nodes (17): 75mm main body tube (blue/grey airframe), Coupler ring (transition band between airframe sections), 75mm electronics bay (ebay) coupler section with avionics window, Ebay sled (avionics mounting plate visible through window), 75mm fincan / aft section housing motor mount, Swept trapezoidal fins (3-fin configuration), Motor mount tube (white/exposed aft section), 75mm nosecone (ogive/tangent-ogive profile) (+9 more)

### Community 6 - "Rocket 1379852 Kit Assembly"
Cohesion: 0.22
Nodes (16): 1379852 Inter-section Coupler, 1379852 Lower Body / Motor Tube Housing, 1379852 Lower Ebay (green band), 1379852 Lower Fin Set, 1379852 Nose Cone, 1379852 Upper Body Tube, 1379852 Upper Ebay (green section, dual switch bands), 1379852 Upper Fin Set (+8 more)

### Community 7 - "102UL Ultralight Airframe"
Cohesion: 0.22
Nodes (15): 102UL Main Body Tube, 102UL Electronics Bay, 102UL Fin Can, 102UL Nose Cone, 102UL Tailcone / Boattail, 98C Electronics Bay, 98C Fin Can (3 fins), 98C Lower Body / Booster Tube (+7 more)

### Community 8 - "102UL Internals Dual-Deploy"
Cohesion: 0.13
Nodes (15): Dual-deploy recovery, 102UL Coupler/Switchband, 102UL Avionics/E-Bay, 102UL Fincan with fins, Rocket102ULInternals.png, 102UL Motor Retainer / Nozzle exit, 102UL Motor Tube (MMT), 102UL Nosecone (orange) (+7 more)

### Community 9 - "Ball Lock 75 Recovery Mechanism"
Cohesion: 0.14
Nodes (14): Ball Lock Unit 75 Assembly, 3/8" Delrin Ball, N42 Disc Magnet 3/16" x 1/8", Main Parachute Bay, MG90S Micro Servo, MR84-2RS Bearing, PD_PetalHub (3D Printed), PD_Petals (3D Printed) (+6 more)

### Community 10 - "SpringThing2 Deployment Assembly"
Cohesion: 0.2
Nodes (14): Spring-driven deployment, SpringThing2 Assembly (exploded), Tan Base Stub, Tan Bearing Seat, Circlip / Retaining Ring (blue), Gray Flange Plate, Orange Main Body, Green Petal/Castellated Ring (+6 more)

### Community 11 - "Parachute 12P45 Pattern (David Flynn)"
Cohesion: 0.24
Nodes (13): David Flynn (Parachute.scad author), Parachute pattern 12 panels, D=45 (5 pages), 12P45 page 1 (panel edge A), 12P45 page 2 (panel edge B), 12P45 page 3 (trapezoid base segment), 12P45 page 4 (panel edge C), 12P45 page 5 (panel edge D), Parachute pattern 14 panels, D=63 (multi-page) (+5 more)

### Community 12 - "Parachute 10P32 Pattern"
Cohesion: 0.38
Nodes (12): Print calibration scale, Parachute 10ft 32 panel design, Parachute10P32 page 1, Parachute10P32 page 2, Parachute10P32 page 3, Parachute10P32 page 4, Parachute 14ft 63 panel design, Parachute14P63 page 3 (+4 more)

### Community 13 - "CableReleaseBB Detent Mechanism"
Cohesion: 0.24
Nodes (10): Actuator Cylinder (blue), Cable Release BB Assembly, Ball Bearing Detent, Flange Mounting Plate (tan), Gray Hook Bracket, Yellow Lever Arm / Frame, Outer Housing Shell (orange), Red Grommet/Seal (+2 more)

### Community 14 - "Rocket98 Goblin Assembly"
Cohesion: 0.43
Nodes (7): Rocket98 Goblin Full Assembly, Coupler Band (gray), Goblin Fin Can, Lower Body Tube, Motor Retainer Ring, Goblin Nosecone (gray), Upper Body Tube w/ Avionics Window

### Community 15 - "BoosterPooper4 Section Overview"
Cohesion: 0.33
Nodes (7): BP4 Core Sustainer, BP4 Booster Ejection Slots, BP4 Blue Aft Fins, BoosterPooper4.jpeg, Booster Pooper 4, BP4 Strap-on Boosters (x2), Strap-on booster staging

### Community 16 - "Omega Minimum-Diameter Family"
Cohesion: 0.4
Nodes (6): Minimum-diameter design, RocketOmega54.png, Rocket Omega 54mm, Omega family, RocketOmegaU157.png, Rocket Omega U157

### Community 17 - "Carbon-Fiber Rod Fin Reinforcement"
Cohesion: 0.4
Nodes (5): Epoxy Fill (Option 2), Pultruded 2mm CF Rod (Option 1), Rod Channels (2.2mm at 25% and 60% chord), Carbon Rod + Epoxy (Option 3, Recommended), West System 105/205 Epoxy + 407 Filler

### Community 18 - "LOC Graduator Reference Kit"
Cohesion: 0.4
Nodes (5): Commercial rocket kit reference - off-the-shelf kits used as design inspiration or comparison baseline, LOC Precision Graduator - commercial mid-power rocket kit, photographed on a chair, white body tube, gray ogive nosecone, 3 through-the-wall balsa fins, single coupler band mid-body, White cardboard body tube of LOC Graduator with spiral seam visible, Three through-the-wall balsa wood fins on LOC Graduator, Gray plastic ogive nosecone of LOC Graduator

### Community 19 - "GoPro Onboard Camera Payload"
Cohesion: 0.67
Nodes (4): Onboard Camera Payload category - action cameras mounted on rockets/boosters for in-flight imagery, GoPro camera booster view - onboard photo taken from booster showing white nosecone, fin, and interior/launch environment, GoPro action camera payload mounted on booster for flight video/photography, White plastic booster nosecone visible in GoPro frame (subject of camera payload)

### Community 20 - "SmallRocketStand GSE"
Cohesion: 0.5
Nodes (4): Ground Support Equipment category - non-flight accessories for rocket display, launch, and handling, SmallRocketStand - 3D-printed small rocket display/launch stand with triangular base, two curved truss-braced feet, central vertical post with stacked ball-bearing-like spacers, Triangular yellow base plate of SmallRocketStand with curved truss feet for stability, Central vertical support post on SmallRocketStand with 4 stacked spacer rings/bearings for holding rocket body

### Community 21 - "Fallout4 Mini-Nuke Prop"
Cohesion: 0.5
Nodes (4): Fo4 Mini-Nuke Rocket Prop, Green Body with Yellow Band, Red Nose Cap, Tail Fin / Thrust Ring Assembly

### Community 22 - "Mini-Nuke Reference Project"
Cohesion: 1.0
Nodes (2): Fallout 4 Mini Nuke reference image, STL Rocket Mini-Nuke project

## Ambiguous Edges - Review These
- `Rocket 98 'The Red One' (4", 54mm motor, 5 fins)` → `Rocket 75C (2.1" body, dual deploy option)`  [AMBIGUOUS]
  Rocket75C_PartsList.txt · relation: related_dual_deploy_design
- `LOC Goblin Rocket Kit (Model 07664)` → `Parachute pattern 8 panels, D=20`  [AMBIGUOUS]
  Pictures/Goblin.pdf · relation: inspires_custom_parachute_design

## Knowledge Gaps
- **105 isolated node(s):** `Blue Tube 2.1 (phenolic kraft)`, `AeroTech M1500G-PS Mojave Green (alternative)`, `NACA 0012 Symmetric Airfoil`, `Bambu P1S 3D Printer with AMS`, `Nylon PA6-CF (alternative)` (+100 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Mini-Nuke Reference Project`** (2 nodes): `Fallout 4 Mini Nuke reference image`, `STL Rocket Mini-Nuke project`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Rocket 98 'The Red One' (4", 54mm motor, 5 fins)` and `Rocket 75C (2.1" body, dual deploy option)`?**
  _Edge tagged AMBIGUOUS (relation: related_dual_deploy_design) - confidence is low._
- **What is the exact relationship between `LOC Goblin Rocket Kit (Model 07664)` and `Parachute pattern 8 panels, D=20`?**
  _Edge tagged AMBIGUOUS (relation: inspires_custom_parachute_design) - confidence is low._
- **Why does `Dual Deploy Recovery System` connect `Peregrine L2 Fin Structural Design` to `BoosterPooper Staging & Recovery Electronics`?**
  _High betweenness centrality (0.049) - this node is a cross-community bridge._
- **Why does `Mission Control V3 Altimeter` connect `BoosterPooper Staging & Recovery Electronics` to `Peregrine L2 Fin Structural Design`?**
  _High betweenness centrality (0.048) - this node is a cross-community bridge._
- **What connects `Blue Tube 2.1 (phenolic kraft)`, `AeroTech M1500G-PS Mojave Green (alternative)`, `NACA 0012 Symmetric Airfoil` to the rest of the system?**
  _105 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Peregrine L2 Fin Structural Design` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._
- **Should `BoosterPooper Staging & Recovery Electronics` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._