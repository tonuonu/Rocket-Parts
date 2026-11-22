# Zephyr tail steering: a Mach 0.8 build

This is a clean build of the Apogee Zephyr (kit 04997), not yet built, flown with the camera
nose and CATS Vega. It uses the Peregrine's tail steering: each of three fixed fins carries a
trailing-edge aileron on a steel shaft, with a printed PC fin can holding the hinges, servos
and LiPo. It is sized for Mach 0.8.

All of it is generated from the same `PeregrineTailSteer.scad` with `Airframe = "Zephyr"`.
The Peregrine parts are unchanged: after `--export`, `git status` shows no change under `STL Files/PeregrineTailSteer/`.

**Kit-fin Zephyr geometry (for the CFD study):** the earlier `Fin_Set = "Zephyr"` ailerons on the kit fin (±15°, aileron clipped 5 mm ahead of the fixed fin's tip) can be rebuilt from Rocket-Parts commit `8b1cddb` (main after PR #42): `git show 8b1cddb:PeregrineTailSteer.scad > kit.scad` and render with `-D 'Fin_Set="Zephyr"'`.

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
| Factors at the design point (servo / bearing / shaft / horn screw) | 5.7× / 3.4 / 3.1 / 3.8 | 12.1× / 2.8 / 2.5 / 49.1 (the clevis cap; its dowel sets it) |
| Cleared to (all factors ≥ 2) | 164 m/s (155 with Prandtl–Glauert) | M 0.85 with Prandtl–Glauert (288 m/s ISA, 277 m/s on a −5 °C day) |
| Travel limit | Servo end points and firmware | End points and firmware (mandatory), plus a **mechanical stop at about ±6.4°** on the pushrod |
| Canards | On the nose | Removed |
| Tail mass change | +460 g | +888 g against the stock kit fin section |
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
  - The larger span keeps 1.91 cal at max speed despite +877 g at the tail (the OpenRocket model's figure; see Mass, CG and stability). The kit fin outline, at the same mass, gives 1.64 cal.
  - The swept TE puts the fixed fin's tip on the ground first: it reaches 12 mm past the base, while the ailerons end 4 mm ahead of the base, 16 mm short of the fin tip.
- **Aileron: ±5°, the Peregrine planform rule.** It spans y 0.8–55 and runs from the hinge to the trailing edge, a chord of 17.5–29.8 mm aft of the hinge.
  - The span is fixed by field service: the 54 mm shaft must come out into the cut-out.
  - Authority is 29× the 0.011 target. Travel, not size, sets the hinge loads, so travel is what is limited.
  - **Servo end points at ±10° of servo (±5° aileron) and the Vega's ±5° command limit are mandatory.** A mechanical stop at about ±6.4° is the backup (next item).
- **Mechanical travel stop at about ±6.4°, on the pushrod.**
  - **How it works:** two M2 nuts, each over a Ø6 washer, are locked on the pushrod either side of a 6 mm PC shelf, and the rod passes the shelf through a Ø3 hole. Each washer sits 1.80 mm off the shelf at neutral: the rod's travel at 6.3° of aileron (crank 16 × sin 6.3°) plus 0.04 mm for the washer's tilt as the balls move sideways. The washers land at about 6.4°; the verifier measures the landing angle.
  - **The shelf** (Z 57–63) bridges from the servo bay's fin-side web to the floor and spine end. 45° corbels at both ends run to the washer's footprint, so the lower washer lands on a 6 mm bridge, not a cantilever. The web and floor are widened to the shelf's 6 mm.
  - **Why here:** the stop's reaction goes from the rod straight into the can. The crank, shaft, bearings and aileron never carry more than the aero load. An earlier pin stop at the aileron root sent T / 13 mm through the shaft outboard of the outer bearing: about 330 N at full stall, past C0r. A crank stop would also have kept the force off the shaft, but a shelf under the crank arm blocks fitting the crank from the aft end.
  - **Shaft and bearings at the stop:** aero at the 6.44° landing, α 6°, the design q gives outer bearing C0r/P 2.3, shaft 2.0 (221 MPa), servo 9.9×.
  - **The stop's own load:**
    - Driving into the stop puts full servo stall (228 N of rod force at 8.4 V) through the horn, the horn-end ball link, the rod and the shelf. Every part of that path holds it with a factor of 1.5 or more:

      | Part | At full stall | Factor |
      |---|---|---|
      | Shelf (taken as a cantilever 3 mm from the nearer corbel) | 19.0 MPa | ×2.4 |
      | Washer on the PC, across the layers (allowable 20 MPa) | 10.8 MPa | ×1.86 |
      | M2 rod, tension | 113 MPa | ×4.0 |
      | M2 rod, compression (19.1 mm from the upper stack to the horn ball) | 228 N against Euler 1740 N | ×7.6 |
      | Horn pivot: Ø2 × 10 hardened dowel as a clevis pin, M = P (L/4 − b/8) | 381 MPa | ×3.1 |
      | Clevis cap's strap, cantilevered 4 mm from the saddle, edgewise (2 × 5 mm) | 55 MPa | ×9.1 |
      | Saddle ends on the arm's two edges, 5.5 mm apart: the cap is a lever about them (197 N inner, 83 N outer) | 79 MPa bearing | ×9.5 |
      | Cap screw (M2 into the arm's tapped hole) | no in-plane load | — |
      | Servo arm (7075), at the hub, edgewise (2.5 × 5.5 mm): the whole F × 8 mm | 145 MPa | ×3.5 |
      | Horn-end ball link | 342 N (×1.5) | metal-body links, pull-tested |

    - **Horn clevis cap:** the old single-shear M2 stud would have yielded at 104 N, so a drive into the stop would have bent it.
      - **The part:** one 7075 cap. A saddle straddles the outer end of MKS's metal single arm, cut to 17.5 mm (the saddle spans 12–17.5 mm from the spline), with 1.5 mm cheeks over both of the arm's edges. From the saddle a 2 mm strap runs back over the far side of the ball (0.3 shim) to the pivot.
      - **The pivot:** a Ø2 × 10 hardened dowel pressed through the arm, a shim, the ball, a shim and the strap.
      - **Why a keyed saddle:** a strap held by one screw would turn about that screw. The ball load gives a moment of 0.74 N·m about the screw's axis, more than the screw's clamp can hold, and the pivot would fall back to single shear. The saddle's cheeks take that moment on the arm's edges. An M2 screw into a tapped hole at 14.5 mm only keeps the cap on; none of the numbers above count on its clamp.
      - **Space:** the cap clears the ball link's eye by 0.5 mm and the fin rib by 0.45 mm. Nothing fits inboard of the pivot: the link eye, the spline hub and the arm's retaining screw (modelled as an M3 cap head, Ø5.5 × 3, the larger of the likely sizes; check it).
      - **Weakest part:** the dowel, which yields at 5.74 N·m of servo torque (×3.15 on stall). The load lies in the plane of the arm and the strap, so both bend edgewise; the arm at the hub follows at ×3.5.
  - **What the verifier checks:** it sweeps the servo's whole reachable throw in 0.25° steps.
    - The stacks stay ≥ 0.1 mm off the can through ±5° and are free up to ±6.34°.
    - The washers land at ±6.39° (measured to 0.01°) and bite by 0.3° past it.
    - Up to the stop nothing else touches (aileron, crank, horn, ball links, rod, stacks).
    - It also measures the landing face: flat across the washer's footprint, with material falling away on both sides within 1 mm (a bridge, not a cantilever).
  - **In a real jam at the aileron** (not at the stop), the fuse is the 4 mm annealed shaft. It yields in torsion at 2.87 N·m at the aileron, which is 1.44 N·m at the servo, 79 % of the 8.4 V stall. That happens before the drive dowel's seat in the PC and before any crank part, whose factors at full stall are 1.9–3.1. The shaft is the field-replaceable part, as for landings. A sustained stall also opens the 7.5 A fuse.
- **Servo and bearings: MKS HV6160 and NSK 684AZZ, as on the Peregrine.**
  - At the design point the servo margin is 12.1×. The bearings' C0r/P is 2.8, and the shaft's factor is 2.5.
  - A Ø5–6 shaft would need a thicker aileron (and fin) for no gain at ±5°.
- **Link ratio 2.0.** Crank 16 mm and horn 8 mm (Peregrine 14 / 9).
  - The servo turns ±10° for ±5° of aileron, so its gear lash counts half at the aileron.
  - The servo sits at 62.2° from its fin (Peregrine 60.4°). The hatch opening is 3 mm wider on the fin side than the Peregrine's, for the horn clevis, and its rebate stays 12.6 mm from a fin face (≥ 12 for a 10 mm fillet). It is also 4 mm wider on the other side, and the cover screw on that edge sits below the servo's case instead of above its lead stub, so the servo can slide off its horn and come out (see Servo removal). Below its fin-side corner a stop window (u 15–36.5, Z 51.5–73) opens a side-on path to both stop nuts and their gaps; the cover grows a matching lobe with its own M3 screw below it. At Cp −1 on the design q the lobe sees 70 N of suction, against about 720 N for the button head to pull through the 1.6 mm cover (×10).
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
| Ailerons | Peregrine design, 1282 mm² each; hinge radial at Z 34; ±5° (mechanical stop about ±6.4° on the pushrod) |
| Stop shelf | Bridges the servo bay's fin-side web and the floor end, Z 57–63, round the pushrod (Ø3 hole), with the stop nuts above and below it |
| Horn | MKS metal single arm (5 mm output) cut to 17.5 mm, pivot at 8 mm; 7075 clevis cap: saddle over the arm's outer end (12–17.5 mm), strap back over the ball to the pivot dowel |
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
| 5°, α 6° (sizing) | 0.234 N·m | 0.117 N·m | 27.7 N at r 81.5 | servo 12.1× (6.0 V), bearing C0r/P 2.8 (outer 80.9 N), shaft 2.5 (179 MPa), horn 49.1 (the clevis cap's dowel) |

- **Envelope:** all factors ≥ 2 up to M 0.85 with Prandtl–Glauert. That is 288 m/s at ISA sea level and 277 m/s on a −5 °C day. The design point is a Mach number, and its q = 0.7 p M² at sea-level pressure does not depend on temperature. At the J510W's 237.4 m/s (ISA) the factors are servo 19.1×, bearing 4.4, shaft 3.9, horn 77.0. The speeds and Mach numbers in this README are ISA (the sims' atmosphere).
- **At the stop (6.44°):** servo 9.9×, bearing 2.3, shaft 2.0; the stop's reaction stays in the rod and the can (see Design choices).
- **Crank and horn:** in flight the pushrod carries 15 N and every crank part has a factor of 22 or more. At full stall (228 N): crank cheeks ×3.0, arm root ×2.5, pivot dowel ×3.1, its seat in the PC ×1.9; the horn clevis cap ×3.1 (the dowel) or better.
- **Aileron drive:** the dowel's bearing pressure in the PC is ×17.8 in flight. In a jam the shaft yields in torsion first (2.87 N·m at the aileron).
- **Landing:** the 4 mm annealed silver-steel shaft yields at about 70 N on the aileron, as on the Peregrine; it is the fuse.
- **Fin root:** at α 6° the fin normal force is about 520 N, and the root bending about 23 N·m. That is about 15 MPa in the carbon root and is carried by the 120 mm tab glued to the motor tube plus the root fillets.

### Mass, CG and stability

New aft section, Z above the base (carbon 1.5 g/cm³, PC 1.20 g/cm³ solid; the can, covers and cranks weighed from their meshes):

| Item | Mass | Z |
|---|---:|---:|
| FinCan | 335.5 g | 108.5 |
| Hatch covers ×3 | 40.3 g | 107.7 |
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
| Horn clevis caps ×3 (7075) | 4.1 g | 86 |
| Pivot dowels and cap-screw shanks ×3 (steel; the heads are in the caps) | 1.5 g | 86 |
| Stop stacks ×6 (M2 nut + Ø6 washer, est.) | 1.5 g | 60 |
| **Total** | **1552.4 g** | **154.5** |

- **Against the stock kit fin section:** the kit's tube, plywood fins with tabs, motor tube, rings, eyebolt and buttons come to 664.6 g at Z 141.1. Epoxy and paint are left out of both. The change is +888 g. The OpenRocket model carries +877 g: the clevis caps, dowels, stop stacks and the hatch changes came later. The 11 g at the tail moves the CG about 1 mm aft at max speed, about 0.01 cal.
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
2. Print the can, hatches, cranks and aileron halves from this folder. Fit the inserts: 10 × RX-M3x5.7 (one more per hatch, for the stop-window lobe), 1 × RX-M4x8.1, 3 × RX-M3x4.0 SHORT.
3. **Tubes.**
   - Cut 220 mm off the aft end of the kit's slotted aft tube. The cut-off piece, which carries all the slots, is scrap.
   - **Check the can shoulder (OD 98.4) in this tube and the can's 101.5 OD against it.** These figures were measured on the Peregrine's tube. Sand the shoulder for a slip fit if needed.
   - Leave the kit motor tube and the spacer rails out. Kit fins: not used. Both kit rings are used (steps 11 and 12).
4. Cut three fins from 1/4 in carbon plate to `FixedFin_Zephyr.dxf`. Round the leading and tip edges to about R1.5.
5. **Shafts:** three Ø4 h9 silver-steel rods, 54.0 mm, with a 0.5 mm D-flat. Drill the Ø2 cross hole in `ShaftDrillJig.stl`.
6. **Bearings and cranks:** as for the Peregrine (Loctite 641; Ø2 × 10 dowel; crank arm toward the servo).
7. **Motor tube:** a 38 mm × 609.6 mm tube (24 in). Epoxy it into the can bore, aft end 12.7 mm above the base.
8. **Fins:** tabs through the slots onto the motor tube.
   - Root fillets: leg at most 10 mm (the hatch rebates are 12.6 mm away), and stop 5 mm forward of the aileron cut-out (Z ≥ 43).
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
    - **Arm:** MKS's metal single arm for the 5 mm output, cut to **17.5 mm** from the spline centre with a rounded end (R 2.75, the arm 5.5 wide). Jig: a Ø5 pin for the spline and an end stop 17.5 mm from its centre. Ream a Ø2.0 press-fit hole at **8 mm** from the spline, and drill and tap an M2 hole at 14.5 mm. The stock arm's hole layout is not confirmed (one dealer gives MKS's 5 mm-output metal horn an outermost hole at 15.5 mm). If a stock hole lies between 13 and 15.5 mm, put the cap screw there instead (tapped M2) and drill the cap's screw hole to match; the saddle keys the cap wherever the screw sits. No stock hole may cut into the 8 mm pivot hole.
    - Machine the clevis cap from 7075.
      - **Saddle:** 5.5 mm long (12–17.5 mm from the spline, flush with the cut arm's end), with a 5.5 × 2.5 mm slot for the arm and 1.5 mm cheeks.
      - **Strap:** 2 mm thick, 5.5 mm wide at the pivot tapering to 5.0 mm at the cap screw, reaching from the saddle back to a Ø2.0 press-fit hole at the pivot. Its face is 5.4 mm (shim + ball + shim) from the arm's outer face.
      - Drill a Ø2.2 clearance hole for the cap screw at 14.5 mm.
    - **Horn, off the servo:** slide the cap onto the arm with the horn-end ball and the two shims between the strap and the arm. Press the Ø2 × 10 dowel through the arm, the shims, the ball and the strap, and fit the ISO 7380 M2 × 10 cap screw (thread-locked).
    - **Rod and stop stacks:** before fitting the second ball link, thread a nut and a Ø6 washer onto the rod, pass the rod through the shelf hole, and add a washer and a nut. Fit the links (52 mm between ball centres).
    - **Servo in:** put the servo into its bay 3.25 mm toward the far web, hold the aileron and the arm at neutral, and slide the spline into the arm's hub on the nearest tooth (as in Servo removal, in reverse).
    - Fit the lug bolts.
    - Fit the arm's retaining screw (thread-locked; removable grade, it is undone for servo removal).
    - **Set the stops through the stop window** (below the servo hatch's fin-side corner, under the cover's lobe), with the servo in and the aileron centred. Put a 1.8 mm feeler (a drill shank) into each gap between washer and shelf, run that stack's nut onto the washer with a 4 mm open-end wrench (15° head: flip it each stroke), and pull the feeler. Lock the nuts with thread locker. The verifier checks both the wrench's and the feeler's paths.
    - **Program the end points to ±10° of servo (±5° of aileron). This is mandatory**; the ±6.4° stop is only the backup.
    - Check by commanding full travel: the aileron reaches ±5° without the servo stalling, and, seen side-on through the stop window, the washers stay off the shelf.
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
| MKS metal single arm, 5 mm output (cut to 17.5 mm) | 3 | Horn (instead of the stock arm) |
| 7075 clevis cap (saddle + strap, machined) + ISO 7380 M2 × 10 | 3 each | Horn clevis (screw into a tapped hole in the arm at 14.5 mm) |
| Ø2 × 10 hardened dowel (ISO 8734) | 3 (+ spares) | Horn pivot through arm, ball and cap (replaces the M2 × 10 12.9 and its nut) |
| M3 button-head screw + RX-M3x5.7 insert | 3 each (more than the Peregrine) | Stop-window cover lobes, one per hatch |
| Metal-body M2 ball links, steel ball | 3 (horn end) | Stop load path: must hold 342 N (pull-test them) |
| JST RCY pair + Kevlar | 1 (not 2) | Only the nose joint separates |
| 26 AWG twisted pair | ~1.0 m | Vega to the tail |
| 60 in parachute | 1 | Replaces the kit's 36 in |
| Motors | — | AeroTech J510W, Cesaroni 1115J530-15A, AeroTech J825R (and their 38 mm hardware) |

Unchanged from the Peregrine list:
- NSK 684AZZ ×6, Ø4 silver steel, MKS HV6160 ×3, ball links;
- Ø2 × 10 and Ø2 × 14 dowels, M2 × 5 clamp screws;
- the other inserts and screws, Tattu 450 mAh 2S, Schurter switch, fuse, capacitor;
- AeroPack RA38L.

The kit's plastic nose cone, spacer rails and fins are not used.

## Servo removal (field)

The linkage is captive: both ball links are pinned, and the rod passes through the stop shelf between its two stacks. So the horn, its clevis cap, the ball link and the rod stay in the can on the crank, and the servo comes off its horn. A servo swap cannot move the stops: the shelf, rod, stacks, links and crank are not touched. They need resetting only after a rod or ball-link change, through the stop window as in the build (step 13).

1. Remove the hatch cover.
2. Undo the arm's retaining screw on the spline. Put a hex key's short leg into the screw along the spline axis, from the fin side: it passes the fin-side web's trimmed outer edge and leaves through the hatch opening. Turn it in part turns with the long leg, outside the can.
3. Undo the two lug bolts from outside.
4. Slide the servo 3.25 mm along its output axis, away from the horn, so the spline leaves the arm's hub.
5. Lift the servo out through the hatch. Steady the horn by hand; it hangs on the linkage.

To refit, reverse the steps:
- Centre the new servo at 1520 µs and hold the aileron at neutral.
- Slide the spline into the hub on the nearest tooth, then fit the lug bolts and the retaining screw (thread-locked).
- If the tooth leaves the aileron off neutral, trim it with the servo's centre setting.
- Check the end points (±10° of servo): at full command the aileron reaches ±5° without stalling, and the washers stay off the shelf (seen through the stop window).

The verifier checks the key's reach, the slide and the lift-out for both hatch types. The arm's retaining screw is modelled as an M3 cap head (2.5 mm key); check the real size, which sets the key.

## Concerns and items to confirm

- **CFD.** The hinge moments, aileron Cl_δ and fin loads are thin-airfoil estimates × 1.67 for compressibility. The running Zephyr CFD (M 0.25–0.8, kit fin, earlier aileron) gives real numbers, and the freestream Mach at which the flow first goes locally sonic. If that is below 0.70, the flight speed must come down.
- **Rod exit margin:** 0.98–1.15 cal on an 8 ft rail in 3 m/s wind. If the wind is above 3 m/s, add 150 g of nose ballast: in an earlier run that raised the rod-exit margin by about 0.3 cal, for 8 m/s less top speed.
- **Recovery bay:** 192 mm × Ø99 (about 1.5 l) holds the 60 in parachute, the shock cord and the protector. It is not checked: pack it before committing to the 24 in motor tube. With the J825R (478 mm) or the J530 (500 mm) as the longest motor, a shorter tube gives the bay more room.
- **Mach 0.70, not 0.8.** On the component-mass basis no commercial 38 mm motor gets the built rocket above M 0.70. Reaching 0.8 needs about 500 g less mass, or a 54 mm mount (a new hinge layout). The hinge is cleared to M 0.85 either way.
- **Tail mass +888 g.** The carbon fins are 626 g of it.
- **Servo lash** is unpublished. The bench check decides; at a 2.0 ratio, up to about 0.7° at the servo still meets 0.5° at the aileron.
- **Travel stop:** the stop angle is set by the nut positions (0.1 mm of gap is about 0.36°), not by print tolerance. Re-set it through the stop window after any rod or ball-link change; a servo swap does not touch it.
- **Drift:** single deployment at apogee from about 1.5 km.

## Verification

```
~/.cache/camnose-venv/bin/python -I tools/verify_tailsteer.py --export          # both airframes; exports only if every check passes
~/.cache/camnose-venv/bin/python -I tools/tailsteer_estimate.py --airframe Zephyr
java -Djava.awt.headless=true -cp OpenRocket-24.12.jar tools/ORSimMass.java Zephyr-CamNose.ork   # max q, CG/CP per motor
~/.cache/camnose-venv/bin/python -I tools/test_orsimmass.py PeregrineL2-CamNose.ork   # a mass change with --fins counts the fins once
```

`verification.json` holds the last Zephyr run: 79/79 passed (145/145 with the Peregrine's 66). The checks are those of the Peregrine (every part a closed supportless solid, clearances, walls, bearings, clamp screws, play, fillet room, air gaps, rail, servo and LiPo lift-out, shaft extraction with the fins glued, travel with the linkage solved in 0.5° steps, gaps over the travel, tail-first landing), run on the Zephyr render, plus nine for the travel stop (two are the wrench's and the feeler's access through the stop window) and four for servo removal (key access and slide, per hatch type; the lift-out checks then start from the slid position). Measured:
- stop stacks ≥ 0.27 mm off the can through ±5°; free up to ±6.34° and landing at ±6.39° (each side measured and swept to its own angle), biting by ±6.69°; nothing else touching over the servo's throw up to the stop (servo ±12.9°, 55 steps, the full pair list including rod and stacks against servo, covers and LiPo, and the clevis cap against the horn-end link eye (ball excluded; 0.5 mm clear)); the landing face flat across the washer footprint and falling away 1 mm on both sides (a 6 mm bridge);
- servo removal in both hatch types, with the horn left on the captive linkage: a Ø3 × 20 mm key leg along the spline axis reaches the arm's retaining screw clear of the can, fin, aileron, horn and clevis cap; the servo slides 3.25 mm off the hub touching nothing, then lifts 30 mm out clear of the can and the horn; horn to can 0.42 mm over the travel;
- through the stop window at neutral, with the servo in: a 4 mm open-end wrench (Ø9 × 2 head, 6 × 2 neck) on each stop nut swung ±15°, and a Ø1.7 feeler in each gap, clear of every other part;
- aileron-to-can and aileron-to-fin gaps 0.8 mm;
- pushrod links to can 3.3 mm;
- fins 18 mm off the rail;
- fixed fin 12 mm past the base, with the ailerons 15.9 mm short of it.

OpenRocket: `Zephyr-CamNose.ork` in MyLevel1Peregrine (PR #46) is this build (kit tubes and buttons, camera nose without canards, the carbon fins, the 24 in motor tube, both rings, every tail-steering part), 43 motors.
