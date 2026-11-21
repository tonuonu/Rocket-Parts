# Zephyr tail steering: a Mach 0.8 build

This is a clean build of the Apogee Zephyr (kit 04997), not yet built, flown with the camera
nose and CATS Vega. It uses the Peregrine's tail steering: each of three fixed fins carries a
trailing-edge aileron on a steel shaft, with a printed PC fin can holding the hinges, servos
and LiPo. It is sized for Mach 0.8.

All of it is generated from the same `PeregrineTailSteer.scad` with `Airframe = "Zephyr"`.
The Peregrine parts are unchanged (byte-identical; see Verification).

**Status:** CAD-verified design. Nothing is printed or bench-tested. Every load below is a
hand estimate, marked for confirmation against the Zephyr CFD at Mach 0.25–0.8. That study
runs the earlier `Fin_Set = "Zephyr"` ailerons on the kit fin, so its hinge moments and
Cl_δ need scaling to this aileron and fin.

![Assembly, ailerons at +5 deg](AssemblySide.png)
![Cutaway at fin 0: hinge, crank, pushrod and servo](HingeCutaway.png)

## What changes for Mach 0.8

| | Peregrine (164 m/s design) | Zephyr (Mach 0.8) |
|---|---|---|
| Design point | q 10.8 kPa (J350, 132.7 m/s), no compressibility | q 45.4 kPa at M 0.80 (272 m/s), loads × 1.67 (Prandtl–Glauert), so 75.7 kPa effective |
| Fastest motor with the tail | J350W 119.7 m/s | J510W 237.4 m/s (M 0.70) |
| Motor mount | 38 mm × 279.4 (kit) | 38 mm × 609.6, for 38/1080-class J motors up to 584 mm |
| Fins | 1/4 in birch ply, Peregrine outline | 1/4 in carbon-fibre plate; span 125, tip chord 90, trailing edge swept 12 mm past the base |
| Fixed-fin flutter (TN 4197) | — | 1350 m/s, 5.0× the design speed |
| Aileron | 2623 mm², ±15° | 1282 mm², **±5°** |
| Link ratio (crank / horn) | 14 / 9 = 1.56 | 16 / 8 = 2.00 (servo lash counts half) |
| Roll authority at full travel | Cl 1.09 (0.073 /deg × 15°) | Cl 0.32 (0.064 /deg × 5°) = 29× the fins' own induced roll |
| Factors at the design point (servo / bearing / shaft / horn screw) | 5.7× / 3.4 / 3.1 / 3.8 | 12.1× / 2.8 / 2.5 / 7.1 |
| Cleared to (all factors ≥ 2) | 164 m/s (155 with Prandtl–Glauert) | M 0.85 with Prandtl–Glauert (288 m/s ISA, 277 m/s on a −5 °C day) |
| Travel limit | Servo end points and firmware | End points and firmware (mandatory), plus a **mechanical stop at ±6.5°** on the pushrod |
| Canards | On the nose | Removed |
| Tail mass change | +460 g | +877 g against the stock kit fin section |
| Margin at max speed | 2.32 cal | 1.91 cal (OpenRocket model of the build) |

The can, bearings, shaft, servo, crank design, hatches and wiring stay the Peregrine's. At
±5° the 4 mm shaft and the 684 bearings hold Mach 0.8 with a factor of 2.5 or more, so the
can only needed a new servo angle for the 2.0 link ratio. Shrinking the aileron instead was
not possible: its chord runs from the hinge to the trailing edge, and the hinge (Z 34)
cannot move aft into the motor retainer's keep-out.

## Design choices

- **Motor mount: 38 mm.**
  - `Zephyr-CamNose.ork` (MyLevel1Peregrine) models this build part by part: OpenRocket component masses, every tail-steering part at its CAD station, 43 motors that all fit the 609.6 mm tube, Långtora conditions (ISA, 3 m/s wind) on an 8 ft rail. The fastest buildable motors reach M 0.67–0.70, under the target:

    | Motor | Length | v max | Mach (ISA) | Rod exit | Margin at v max | Apogee |
    |---|---:|---:|---:|---:|---:|---:|
    | AeroTech J510W | 584 mm | 237.4 m/s | 0.70 | 31.3 m/s, 1.07 cal | 1.91 cal | 1514 m |
    | Cesaroni 1115J530-15A (Pro38 6XL) | 500 mm | 232.4 m/s | 0.68 | 30.5 m/s, 0.98 cal | 1.89 cal | 1447 m |
    | AeroTech J825R (38/1080) | 478 mm | 226.6 m/s | 0.67 | 35.5 m/s, 1.15 cal | 1.86 cal | 1260 m |

  - A 54 mm tube was not taken for its geometry. Its bore (r 28.9) takes the place of the inner bearing (r 25–29), and the servos would lose their 8 mm air gap; the hinge would need a new layout. This is reasoned by hand, not CAD-checked.
  - 54 mm motors would reach the target. An early scan (kit-span fins, a lighter mass estimate) had several J and K motors at M 0.86–0.90 and some K motors at M 0.98–1.0.
  - The motor tube is 24 in (609.6 mm) so that the longest pick, the J510W, sits fully inside it.
  - The hinge is sized for Mach 0.8, above every buildable motor, so a lighter build than the model (each 100 g is worth about 6 m/s) stays inside it.
- **Fins: 1/4 in (6.35 mm) carbon-fibre plate** (woven 0/90 epoxy, ~1.5 g/cm³, in-plane shear modulus ~4 GPa assumed).
  - The aileron has to be 6.35 mm thick to hold the Ø4 shaft and the M2 clamp screws. A fixed fin of the same thickness keeps the aileron flush at Mach 0.8 and keeps the can's fin slot.
  - At this thickness, carbon is 19 % lighter than G10 (626 g against 773 g for these three fins). That is worth about 8 m/s (OpenRocket).
  - 1/4 in birch ply would sit at the limit on this outline: about 415 m/s (1.5×), on an assumed G of 0.38 GPa.
- **Fin outline.** The root chord (228.27) and root LE station (Z 245.03) are the kit's.
  - Span 125 (kit 112.9), tip chord 90, tip LE 167 aft of the root LE. The trailing edge is straight from the root TE to the tip TE, 12 mm past the base.
  - The kit's notched aft extension is gone, and with it the old aileron clip.
  - The larger span keeps 1.91 cal at max speed despite +877 g at the tail. The kit fin outline, at the same mass, gives 1.64 cal.
  - The swept TE puts the fixed fin's tip on the ground first: it reaches 12 mm past the base, while the ailerons end 4 mm ahead of the base, 16 mm short of the fin tip.
- **Aileron: ±5°, the Peregrine planform rule.** It spans y 0.8–55 and runs from the hinge to the trailing edge, a chord of 17.5–29.8 mm aft of the hinge.
  - The span is fixed by field service: the 54 mm shaft must come out into the cut-out.
  - Authority is 29× the 0.011 target. Travel, not size, sets the hinge loads, so travel is what is limited.
  - **Servo end points at ±10° of servo (±5° aileron) and the Vega's ±5° command limit are mandatory.** A mechanical stop at ±6.5° is the backup (next item).
- **Mechanical travel stop at ±6.5°, on the pushrod.**
  - **How it works:** two M2 nuts, each over a Ø6 washer, are locked on the pushrod either side of a 6 mm PC shelf. The shelf grows out of the servo bay's fin-side web at Z 57–63, and the rod passes it through a Ø3 hole. Each washer sits 1.81 mm off the shelf at neutral, which is the rod's travel at 6.5° of aileron (crank 16 × sin 6.5°).
  - **Why here:** the stop's reaction goes from the rod straight into the can. The crank, shaft, bearings and aileron never carry more than the aero load. An earlier pin stop at the aileron root sent T / 13 mm through the shaft outboard of the outer bearing: about 330 N at full stall, past C0r. A crank stop would also have kept the force off the shaft, but a shelf under the crank arm blocks fitting the crank from the aft end.
  - **Shaft and bearings at the stop:** aero at ±6.5°, α 6°, the design q gives outer bearing C0r/P 2.2, shaft 2.0, servo 9.8×.
  - **The stop's own load:**
    - At full servo stall the rod pushes 228 N into the shelf: 17.0 MPa of bending (×2.7, in-layer), 10.8 MPa under the washer, and the 19 mm of M2 rod above the shelf is far from buckling (Euler 1200 N).
    - In practice the horn's M2 pivot screw, the existing fuse, yields first, at a rod force of 104 N. The shelf is then at ×5.8.
  - **What the verifier checks:** it sweeps the servo's whole reachable throw in 0.25° steps.
    - The stacks clear the shelf through ±5° and touch nothing inside ±6.5°.
    - A washer lands on the shelf by ±6.8°.
    - Up to the stop nothing else touches (aileron, crank, horn, ball links, rod, stacks).
    - It also measures the shelf section.
- **Servo and bearings: MKS HV6160 and NSK 684AZZ, as on the Peregrine.**
  - At the design point the servo margin is 12.1×. The bearings' C0r/P is 2.8, and the shaft's factor is 2.5.
  - A Ø5–6 shaft would need a thicker aileron (and fin) for no gain at ±5°.
- **Link ratio 2.0.** Crank 16 mm and horn 8 mm (Peregrine 14 / 9).
  - The servo turns ±10° for ±5° of aileron, so its gear lash counts half at the aileron.
  - The servo sits at 62.2° from its fin (Peregrine 60.4°). The hatch rebates then stay 15.4 mm from a fin face.
- **Fin can: polycarbonate, as the Peregrine.**
  - Loads on the can stay small. The hatch covers see about 23 kPa of suction (Cp −0.3 × the effective q), which is 22 MPa of bending in the 1.6 mm cover (×2) and 25–37 N per M3 insert.
  - Stagnation heating at M 0.70 is about +25 K, for seconds. PC's HDT is about 130 °C.
  - PA-CF would be stiffer but takes up moisture, and nothing here is stiffness-limited.
- **Flutter and buzz.**
  - Fixed fin: NACA TN 4197 gives 1350 m/s, 5.0× the design speed (sea level, G 4 GPa).
  - Aileron: not mass-balanced; very stiff instead. The 30 mm-chord PC panel gives 1617 m/s (TN 4197). The hinge mode is about 1290 Hz with the linkage at 127 N·m/rad (servo holding full torque within 3°, assumed).
  - **Free play < 0.5° at the trailing edge, including the servo gears.**
    - Budget: servo gear lash ÷ 2, plus the two ball links (about 0.07° each with tight new links), plus 0 for the D-flat, dowel and set screw (line-to-line in CAD; the verifier measures 0.00°).
    - That leaves about 0.7° of servo lash. MKS publishes no lash figure for the HV6160.
    - Bench item: with the servo powered at neutral, rock the trailing edge by hand. The total movement at a 30 mm chord must be under 0.26 mm (0.5°).
- **Nose: the camera nose with the canards removed.**
  - That means the canard fin set, servo cassette and its screws, 4 servos, servo pack, switch, saddle and cell keeper: 404.6 g, leaving a 916.5 g nose.
  - The canards reverse roll control (CFD). They are printed PETG, and at Mach 0.8 they would be the weakest, flutter-prone surfaces. Ahead of the CG they also cost margin.
  - Print the plain (non-canard) shoulder and bottom slice; the OpenRocket model keeps the canard-version masses as proxies.

## Layout and stations

Frame: Z = 0 at the base, +Z forward; x from the nose tip = 1397.68 − Z. Fins are at 0/120/240° and the rail buttons at 60°, as on the Peregrine.

| Item | Where |
|---|---|
| Printed PC can (`FinCan.stl`) | Z 0–220 (x 1177.7–1397.7), 30 mm shoulder into the tube |
| Paper aft tube | The forward 237.2 mm of the kit's slotted AT-98/18 tube (x 940.5–1177.7). The 220 mm cut off its aft end carries all the kit slots |
| Kit coupler (AC-98, 203.2) | At the joint with the forward AT-98/18 tube (x 940.5), glued as the kit |
| Fixed fins | 1/4 in carbon plate to `FixedFin_Zephyr.dxf`. Through-the-wall tab Z 55–175 glued to the motor tube; root LE at Z 245.0 (x 1152.65, the drawing's station) |
| Ailerons | Peregrine design, 1282 mm² each; hinge radial at Z 34; ±5° (mechanical stop ±6.5° on the pushrod) |
| Stop shelf | On each servo bay's fin-side web, Z 57–63, round the pushrod (Ø3 hole), with the stop nuts above and below it |
| Motor tube | 38 mm × 609.6, aft end Z 12.7 (as the kit), forward end Z 622.3 (x 775.4); motors hang 12.7 mm out of its aft end (as the Peregrine) |
| Can seal | The kit's slotted ring at Z 251 (x 1146.7), on the motor tube over the can's shoulder: the can's gas seal |
| Motor-tube top | The kit ring with the eyebolt at Z 616–622 (x 775–782): it carries the tube's forward end, seals the annulus and anchors the shock cord, in the recovery bay |
| Rail buttons | Kit stations: aft on the can (Z 53.98, x 1343.7) in an RX-M4x8.1 boss; forward on the paper tube (x 1045.3) with the kit weld nut |
| Recovery bay | From the nose shoulder's end (x 583) to the motor-tube top (x 775): 192 mm × Ø99 |

## Parts to print

All the files are in this folder. Print settings are as for the Peregrine (`../PeregrineTailSteer/README.md`, Parts to print; PC per `L2-PrintSettings.md`).

`FinCan.stl`, `HatchServo.stl`, `HatchServoLipo.stl` and `Crank.stl` differ from the Peregrine's (servo at 62.2°, 16 mm crank), so use these. `BearingCoupon.stl` and `ShaftDrillJig.stl` also come from the Zephyr render. `AileronScrewHalf_Zephyr.stl` and `AileronTappedHalf_Zephyr.stl`: 3 each. `FixedFin_Zephyr.dxf`: 3 off in 1/4 in carbon plate (waterjet or CNC).

## Checks (hand estimates; confirm against the CFD)

Run `tools/tailsteer_estimate.py --airframe Zephyr`.

### Roll authority
- |Cl_δ| = 0.064 /deg; at ±5°, Cl 0.32 = 29× the fins' induced roll at 4° (0.011).
- Strip theory with thin-airfoil flap effectiveness × 0.85, scaled to the CFD kit-fin CN_α × 1.171. The 1.171 is the Barrowman ratio of the 125 mm fin to the kit fin.
- The CFD study runs the kit fin with the earlier aileron. Its aileron Cl_δ and hinge moments, scaled by area and chord², replace these numbers when they come in.

### Hinge moment, servo, bearings, shaft (at 75.7 kPa effective: q 45.4 kPa × 1.67)

| Case | Hinge | Servo (÷ 2.0) | Aileron force | Factors |
|---|---|---|---|---|
| 5°, α 4° | 0.217 N·m | 0.109 N·m | 26.0 N | — |
| 5°, α 6° (sizing) | 0.234 N·m | 0.117 N·m | 27.7 N at r 81.5 | servo 12.1× (6.0 V), bearing C0r/P 2.8 (outer 80.9 N), shaft 2.5 (179 MPa), horn screw 7.1 |

- **Envelope:** all factors ≥ 2 up to M 0.85 with Prandtl–Glauert. That is 288 m/s at ISA sea level and 277 m/s on a −5 °C day. The design point is a Mach number, and its q = 0.7 p M² at sea-level pressure does not depend on temperature. At the J510W's 237.4 m/s (ISA) the factors are servo 19.1×, bearing 4.4, shaft 3.9, horn screw 11.1. The speeds and Mach numbers in this README are ISA (the sims' atmosphere).
- **At the stop (±6.5°):** servo 9.8×, bearing 2.2, shaft 2.0; the stop's reaction stays in the rod and the can (see Design choices).
- **Crank and horn:** in flight the pushrod carries 15 N and every crank part has a factor of 22 or more. At servo stall into a jammed aileron, the horn's M2 × 10 12.9 pivot screw yields first, at 0.83 N·m of servo torque.
- **Aileron drive:** the dowel's bearing pressure in the PC is ×17.8 in flight and ×2.5 when the horn screw yields.
- **Landing:** the 4 mm annealed silver-steel shaft yields at about 70 N on the aileron, as on the Peregrine; it is the fuse.
- **Fin root:** at α 6° the fin normal force is about 520 N, and the root bending about 23 N·m. That is about 15 MPa in the carbon root and is carried by the 120 mm tab glued to the motor tube plus the root fillets.

### Mass, CG and stability

New aft section, Z above the base (carbon 1.5 g/cm³, PC 1.20 g/cm³ solid; the can, covers and cranks weighed from their meshes):

| Item | Mass | Z |
|---|---:|---:|
| FinCan | 339.0 g | 108.8 |
| Hatch covers ×3 | 33.0 g | 113.4 |
| Cranks ×3 | 8.1 g | 33.3 |
| Ailerons ×3 | 30.6 g | 23.5 |
| Fixed fins ×3, carbon (notched, with tab) | 626.5 g | 97.9 |
| Shafts, bearings | 22.1 g | 34 |
| Servos ×3 | 92.1 g | 96.5 |
| Links, LiPo, switch/fuse/harness, inserts (est.) | 76.0 g | — |
| Paper tube 237.2 mm | 106.5 g | 338.6 |
| Motor tube 38 × 609.6 | 120.4 g | 317.5 |
| Kit rings ×2 + eyebolt | 83.5 g | — |
| Rail buttons | 3.8 g | 200 |
| **Total** | **1541.5 g** | **155.2** |

- **Against the stock kit fin section:** the kit's tube, plywood fins with tabs, motor tube, rings, eyebolt and buttons come to 664.6 g at Z 141.1. Epoxy and paint are left out of both. The change is +877 g.
- **OpenRocket:** `Zephyr-CamNose.ork` carries these parts as components and mass components, with OpenRocket's own masses for the kit parts (see Mass basis). Dry mass is 3.18 kg; with the J510W, 4.26 kg at liftoff.
- **Stability** (J510W, 8 ft rail, 3 m/s wind):

  | State | Margin |
  |---|---|
  | Max speed (237 m/s) | **1.91 cal** (CG 0.900, CP 1.094 m) |
  | Rod exit (31.3 m/s) | 1.07 cal |

  - The fin recheck: the kit fin outline, at the same mass, gives 1.64 cal (CP 1.066 m); the new fin (19892 mm² against 19200) puts the CP 28 mm further aft. The kit-outline concern (the 643 mm² the old aileron clip removed) no longer applies: this outline has no clip, and OpenRocket flies the fixed fin and aileron as one outline (the 0.8 mm gaps closed), not as two fin sets.
  - The CFD CP of the kit-fin Zephyr is 1.059 m at M 0.25, 2.4 cm ahead of OpenRocket's.
- **Mass basis:** OpenRocket's component masses from the RockSim file's densities: 1.498 kg for the kit with its plastic nose. That is the highest of the three figures; RockSim's own known-mass override is 1.096 kg and Apogee's page says 1.247 kg. The difference is mostly the RockSim 204 g shock cord and 161 g coupler. A lighter real build flies faster; the hinge is sized for Mach 0.8, above that.

## Wiring and separation joints

One separation joint: nose shoulder / forward tube at x 483.3. The Vega fires the nose charge at apogee; the motor delay, where the motor has one, is a backup. Everything aft of the nose is glued: the coupler joint at x 940.5, the can shoulder at x 1177.7, and both rings.

| Station (mm from tip) | Joint | Opens | Crossing |
|---|---|---|---|
| 483.3 | Nose shoulder / forward tube | At apogee: the Vega's nose charge | Potted pass through the nose bulkhead, then a pull-apart JST RCY pair just aft of it, with Kevlar lanyards to each side |
| 775–782 | Kit eyebolt ring at the motor-tube top (annulus seal) | — | Potted pass |
| 940.5 | Forward tube / aft tube (kit coupler) | Never (glued) | None. Tape the pair to the tube wall |
| 1146.7 | Kit slotted ring (can seal) | — | Potted pass into the can annulus |

- **Cable:** about 1.0 m of 26 AWG silicone twisted pair (signal + ground), taped along the tube wall in the recovery bay.
- **Power, switch, fuse and capacitor:** as the Peregrine.
- **Firmware:**
  - Limit commands to ±5°.
  - Centre the ailerons before the apogee charge; after the connector parts the servos see no pulses.
- **Recovery:** a 60 in (1.5 m) parachute at apogee lands the 3.6 kg rocket at 6.5 m/s in the model (the kit's 36 in would give about 11). Apogee on the J510W is 1.5 km, so expect long drift on a single deployment.

## Build order from the bare kit

1. Print `BearingCoupon.stl` and check the bearing seats, the shaft through the wall and the crank, as for the Peregrine.
2. Print the can, hatches, cranks and aileron halves from this folder. Fit the inserts: 7 × RX-M3x5.7, 1 × RX-M4x8.1, 3 × RX-M3x4.0 SHORT.
3. **Tubes.**
   - Cut 220 mm off the aft end of the kit's slotted aft tube. The cut-off piece, which carries all the slots, is scrap.
   - **Check the can shoulder (OD 98.4) in this tube and the can's 101.5 OD against it.** These figures were measured on the Peregrine's tube. Sand the shoulder for a slip fit if needed.
   - Leave the kit motor tube and the spacer rails out. Kit fins: not used. Both kit rings are used (steps 11 and 12).
4. Cut three fins from 1/4 in carbon plate to `FixedFin_Zephyr.dxf`. Round the leading and tip edges to about R1.5.
5. **Shafts:** three Ø4 h9 silver-steel rods, 54.0 mm, with a 0.5 mm D-flat. Drill the Ø2 cross hole in `ShaftDrillJig.stl`.
6. **Bearings and cranks:** as for the Peregrine (Loctite 641; Ø2 × 10 dowel; crank arm toward the servo).
7. **Motor tube:** a 38 mm × 609.6 mm tube (24 in). Epoxy it into the can bore, aft end 12.7 mm above the base.
8. **Fins:** tabs through the slots onto the motor tube.
   - Root fillets: leg at most 10 mm (the hatch rebates are 15.4 mm away), and stop 5 mm forward of the aileron cut-out (Z ≥ 43).
   - Swing the aileron through ±5° loosely before the epoxy cures.
9. **Shafts and ailerons:** as for the Peregrine (dowel, halves, 0.8 mm root shim, then the crank set screw). 
10. **Switch:** sector B, as for the Peregrine.
11. **Forward end of the can.**
    - Run the signal pair through the kit's slotted ring and pot it; fill its slots with epoxy so it seals.
    - Epoxy the ring onto the motor tube at Z 251–257.4.
    - Glue the 237.2 mm tube piece over the shoulder and the ring.
    - Fillet the fin roots Z 220–245 onto the paper.
12. **Upper end.**
    - Glue the kit coupler into the tube piece's forward end as the kit does (half out).
    - Epoxy the kit's eyebolt ring onto the motor tube's forward end (Z 616–622), eyebolt forward, with the signal pair potted through it. Tie the shock cord to the eyebolt.
    - Slide the forward kit tube over ring and coupler and glue it.
13. **Servos.**
    - Centre each servo at 1520 µs.
    - Drill the metal arm Ø2.1 at **8 mm** from the spline. Fit the pivot (M2 × 10 12.9, 0.3 shim, ball, nut on the case side).
    - Stop stacks: before fitting the second ball link, thread a nut and a Ø6 washer onto the rod, pass the rod through the shelf hole, and add a washer and a nut. Fit the links (52 mm between ball centres), centre the aileron, and set each washer 1.81 mm off the shelf with a feeler (a 1.8 mm drill shank). Lock the nuts with thread locker.
    - Fit the lug bolts.
    - **Program the end points to ±10° of servo (±5° of aileron). This is mandatory**; the ±6° stop is only the backup. Check by commanding full travel: the washers must not touch the shelf.
14. **Wiring and LiPo:** in sector A, as for the Peregrine. The nose-joint connector gets its lanyards.
15. **Rail buttons:** the aft one in the can's insert, the forward one with the kit weld nut at x 1045.3. **Retainer:** AeroPack RA38L on the motor tube's aft end.
16. **Bench:**
    - Free play under 0.5° at the trailing edge, with the servo powered.
    - Servo sign, 3.3 V signal, behaviour without pulses.
    - Fly from an **8 ft (2.44 m) or longer rail**.

## Hardware (differences from the Peregrine list)

| Item | Qty | Use |
|---|---:|---|
| 1/4 in (6.35 mm) woven carbon-fibre plate | ~3 × 260 × 160 mm | Fixed fins (instead of birch ply) |
| 38 mm motor tube, 609.6 mm (24 in) | 1 | Motor mount (instead of the kit's 279.4) |
| Kit rings 38/98, both | 2 | Slotted ring: can seal at Z 251. Eyebolt ring: motor-tube top and shock-cord anchor |
| M2 nut + M2 large washer (Ø6) | 6 each | Travel stop stacks on the pushrods |
| JST RCY pair + Kevlar | 1 (not 2) | Only the nose joint separates |
| 26 AWG twisted pair | ~1.0 m | Vega to the tail |
| 60 in parachute | 1 | Replaces the kit's 36 in |
| Motors | — | AeroTech J510W, Cesaroni 1115J530-15A, AeroTech J825R (and their 38 mm hardware) |

Unchanged from the Peregrine list:
- NSK 684AZZ ×6, Ø4 silver steel, MKS HV6160 ×3, ball links;
- Ø2 × 10 and Ø2 × 14 dowels, M2 × 5 clamp screws, the M2 × 10 12.9 horn pivot;
- inserts and screws, Tattu 450 mAh 2S, Schurter switch, fuse, capacitor;
- AeroPack RA38L.

The kit's plastic nose cone, spacer rails and fins are not used.

## Concerns and items to confirm

- **CFD.** The hinge moments, aileron Cl_δ and fin loads are thin-airfoil estimates × 1.67 for compressibility. The running Zephyr CFD (M 0.25–0.8, kit fin, earlier aileron) gives real numbers, and the freestream Mach at which the flow first goes locally sonic. If that is below 0.70, the flight speed must come down.
- **Rod exit margin:** 0.98–1.15 cal on an 8 ft rail in 3 m/s wind. If the wind is above 3 m/s, add 150 g of nose ballast: in an earlier run that raised the rod-exit margin by about 0.3 cal, for 8 m/s less top speed.
- **Recovery bay:** 192 mm × Ø99 (about 1.5 l) holds the 60 in parachute, the shock cord and the protector. It is not checked: pack it before committing to the 24 in motor tube. With the J825R (478 mm) or the J530 (500 mm) as the longest motor, a shorter tube gives the bay more room.
- **Mach 0.70, not 0.8.** On the component-mass basis no commercial 38 mm motor gets the built rocket above M 0.70. Reaching 0.8 needs about 500 g less mass, or a 54 mm mount (a new hinge layout). The hinge is cleared to M 0.85 either way.
- **Tail mass +877 g.** The carbon fins are 626 g of it.
- **Servo lash** is unpublished. The bench check decides; at a 2.0 ratio, up to about 0.7° at the servo still meets 0.5° at the aileron.
- **Travel stop:** the stop angle is set by the nut positions (0.1 mm of gap is about 0.36°), not by print tolerance. Re-check the gaps after any pushrod adjustment.
- **Drift:** single deployment at apogee from about 1.5 km.

## Verification

```
~/.cache/camnose-venv/bin/python -I tools/verify_tailsteer.py --export          # both airframes; exports only if every check passes
~/.cache/camnose-venv/bin/python -I tools/tailsteer_estimate.py --airframe Zephyr
java -Djava.awt.headless=true -cp OpenRocket-24.12.jar tools/ORSimMass.java Zephyr-CamNose.ork   # max q, CG/CP per motor
```

`verification.json` holds the last Zephyr run: 71/71 passed (137/137 with the Peregrine's 66). The checks are those of the Peregrine (every part a closed supportless solid, clearances, walls, bearings, clamp screws, play, fillet room, air gaps, rail, servo and LiPo lift-out, shaft extraction with the fins glued, travel with the linkage solved in 0.5° steps, gaps over the travel, tail-first landing), run on the Zephyr render, plus five for the travel stop. Measured:
- stop stacks 0.41 mm clear of the shelf at ±5°, nothing touching inside ±6.5°, a washer on the shelf by ±6.8°, nothing else touching over the servo's throw up to the stop (servo ±13.1°, 53 steps), shelf 6.0 mm deep where the washer lands;
- aileron-to-can and aileron-to-fin gaps 0.8 mm;
- horn nut to can 0.65 mm;
- pushrod links to can 3.3 mm;
- fins 18 mm off the rail;
- fixed fin 12 mm past the base, with the ailerons 15.9 mm short of it.

OpenRocket: `Zephyr-CamNose.ork` in MyLevel1Peregrine (PR #46) is this build (kit tubes and buttons, camera nose without canards, the carbon fins, the 24 in motor tube, both rings, every tail-steering part), 43 motors.
