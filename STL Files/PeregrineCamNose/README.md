# Peregrine camera nosecone and electronics bay

Two upright tabbed 18650 cells sit below a 47 × 26 × 13 mm DC-DC converter.
The upper shell and camera adapter are **one printed part**. Three side
screws release that upper assembly for servicing; the camera remains
separately bolted to its flange. The lower slice joints stay glued.

This is a CAD-verified prototype, with the initial 04/06 trial fit reported
below. Full assembly fit, insert strength, mechanical loads, temperatures
and ejection protection have not been bench-tested.

## Canard section and Vega in the nose — 2026-11-16, cells in the cassette 2026-11-19 (branch `feature/nose-canards`)

Printed so far: 01, 02, 10, 14 and 15. Their geometry is frozen; the
2026-11-19 change adds hand work to 02 and 14 only (see below). 09 and the
new 12 and 19 are not printed yet.

Source: `PeregrineCamCanards.scad`, switched on by `Canards_Enabled` in
`PeregrineCamNose.scad`. With it set to `false`, parts 01, 02, 03 and 06
match the committed (printed) versions. Volume, bounds and boolean
difference are checked.

### Architecture

The nose carries:
- the camera and its DC-DC converter. The camera-bay sleeves in 06 stay
  empty; 06 and 07 print unchanged (the sleeves web 07's boss columns);
- **four 18650 slots in the servo cassette (09)**, in the quadrants between
  the servos. The servo pair feeds the servos and the camera; the optional
  FC pair feeds the Vega;
- the **CATS Vega**, on the FC pair or on its own 2S 320 mAh LiPo (the
  pocket on the mast stays);
- the four servo canards;
- the **main** charge, on the shoulder bulkhead.

The forward tube holds the 48" main and the aft tube the 18" drogue. The
e-bay is passive: a 2-wire drogue lead passes through it.

| | Vega output | Fires | Location |
|---|---|---|---|
| Drogue | pyro 1 | at apogee | aft, while the nose joint is still closed |
| Main | pyro 2 | at main | on the nose bulkhead; the nose comes off |

The nose does **not** separate at apogee. The shoulder bulkhead is the gas-seal plane.

### Mechanism (unchanged in principle)

- **Direct drive.** Each MKS HV6160 stands in the servo cassette (09) with its output radial.
- **Output hub.** The first choice is an aluminium clamp-type hub with a flat face and two tapped M2 holes. The canard's root plug bolts to it through round holes.
  - Fallback (`Horn_Type = "arm"`): the servo's own arm sits in a form-fit pocket and is held by the centre screw plus one cross screw.
  - There are no slots. The neutral offset goes in firmware `ctrl_trimN`.
  - The spline is parametric (`Servo_Spline_Teeth`, `Servo_Spline_OD`, `Servo_Shaft_H`, `Servo_Centre_Screw`). There is no HV6160 spline data yet, so measure it.
- **Identical units.** The four units are identical at 90°, so opposite servos are 180° apart. One Y-cable **at the Vega** gives roll with no reverser. Stage 2 drives the four servos independently with no mechanical change.
- **Stops:** ±11°. The canards are checked free at ±10.5° and blocked at ±11.5°.
- **Pivot:** 5% MAC ahead of the panel CP, so a limp canard trails to neutral.

### Clocking

Angles are taken from `PeregrineL2.ork`, the standard kit positions: fins at 0/120/240° and rail buttons at 60°.
- The canards sit at **rail + 45° + 90°·k = 15/105/195/285°**.
- The index key and the notch filed in the tube rim are at **rail + 45° = 105°**. The key keeps the canards off the rail. It also carries the canard roll torque into the airframe (~2 N·m, ~40 N at the key).
- **Vega board orientation:**
  - Its long axis runs along the rocket axis.
  - Its plane is parallel to the 15–195° canard axis, 15 mm off-axis. Its axes are therefore aligned with the canards. The GNSS-patch side faces the wall at 105°.

### Vega bay

The bay runs from Z 86 to 270, sealed between the cassette roof and the camera-bay floor.

**Board**
- The board spans Z 120–220.
- Clearances:
  - 35 mm above the cassette cells' top pads (Z 85);
  - 37 mm above the servos;
  - the SMA tip is 21 mm below the camera-bay corbel (Z 245).
- Data from `CATS-Vega.step`:
  - M3 holes at (−30,−13.5), (30,−13.5) and (30,13.5). The 60 × 27 pattern is confirmed.
  - USB-C on the +Y long edge, facing **sideways**: no 90° adapter.
  - Right-angle SMA at the −X end. It is at the top, so the 2.4 GHz whip runs up the wall.
  - The 2×3 right-angle servo header exits the −Y edge.
- The STEP has **no** models of the GNSS patch or the WAGO terminals. The BOM gives an 18×18 THT patch, feed at X −17, and two WAGO 2601-1104. They are envelopes: 6 mm on the patch side and 14.3 mm on the other side.

**Mast unit (14)**
- Roof disc at Z 85–91 with a groove for a Ø5 closed-cell foam cord.
  - The cord seals to the shell and squeezes past the plug-hole rings on the way in.
  - Total leak budget: ≤ 2 mm², with the wire pass potted.
- Four radial M3 screws hold it to the shell, between the canards.
- Channel-section mast, 3 mm walls, up to Z 208.
- Three Ø8 standoffs with ruthex M3 inserts.
- Library `LiPo2S320mAh_BattPocket` on the back of the mast.
- A cup for the 1000 µF capacitor.
- One Ø9 pass in the roof for the servo, power, pyro and camera leads.
  **Ream it to Ø11 by hand** for the extra pack leads. The source keeps Ø9
  so the STL stays the printed part. In CAD nothing of part 14 but the roof
  plate lies in a Ø11 path; the foot gusset is 1.3 mm from it.

**Shell openings**
- **Vega switch:** a second Schurter 0033.4513, same keyed cut and pad as the camera's, on 02 at 300°, Z 120.
- **Servo switch:** a third Schurter 0033.4513 on the printed 02 at **30°, Z 106**, 15° off canard 1 and 30° off the rail.
  - Drill Ø12.7 on the switch axis and file the R1.2 key relief upward (13.6 mm overall), as the camera switch.
  - Epoxy the saddle (part 12) inside the shell over the hole. Its flat back carries the nut, 6 mm behind the bezel's seat (the switch allows 8.5).
  - The flat bezel sits on the curved skin: it touches at its lowest point; the top edge stands 0.4 mm off and the sides about 0.6 mm. Bed it in a thin epoxy fillet or a foam washer.
  - Checked in CAD: the rear envelope (Ø16 × 23.5) clears the mast, its foot gusset, the Vega, the reamed roof pass, the cassette, the cells and canard 1 at ±11.5°; the bezel stays inside the body-tube silhouette on the rail side.
- **USB window:** 12 × 7 on 03 at ~174°, Z 160 on the connector's axis. Tape it or plug it for flight.
- **Static ports:** 4 × Ø2.5 on 03 at Z 160 (60/150/240/330°), above the glued lap. They can be drilled in the printed 03.

### 18650 cells in the servo cassette

**Geometry (part 09).**
- Four identical Ø19.5 sleeves at r 25.5 on 60/150/240/330°. Cell body Z 18–83 (envelope Ø18.5 wrapped × 65, tabs extra), with 2 mm of tab relief at each end.
- The neighbouring cradle walls form the sleeve sides. 1.6 mm wall arcs (OD 22.7) close the rest; they are fused to both walls and, by a web, to the quadrant screw boss. The insert drilling of that boss ends at r 38.5, the bore at r 35.25.
- The diamond windows in the cradle walls are gone: they would open into the cells.
- Each sleeve has a 6 mm full-height tab/lead slot facing the axis. It opens into the channel between the two cradle walls.
- Floor: a Ø19.5 through-hole per sleeve, so the cell hangs through the floor onto the keeper. A 6 × 5 mm notch toward the axis passes the top-tab lead into the shoulder cavity. The notch stops at the cradle walls, so no wall overhangs it.
- Two Ø2.5 lacing holes per sleeve, in the floor of the neighbouring cradle (below the servo), for a strain-relief tie on the pack leads under the floor. Thread the cord before the servos go in and leave it threaded.
- 09 still prints floor-down without supports: every new feature is vertical or stands on the floor.

**Keeper (part 19).**
- Plate Z 13.5–16, Ø76, above the shoulder's insert bosses (tops at Z 12) and inside the spigot.
- Four seat rings, ID 14.5, OD 19.5, 2 mm high, with a 6 mm slot toward the axis. They bear on each cell's insulated bottom rim; the tab and its solder joint sit in the ring's window.
- Central Ø12 lead hole.
- Four Ø8 columns up to the cassette floor (Z 29.2), each held by an **M3×20 90° countersunk** screw, head flush under the plate, into a ruthex M3×5.7 set from below into the cassette.
- The insert sits in a Ø8 boss standing on the floor against the outer face of each cradle's −y wall, at canard-local (31, −10.5). That boss has 2.0 mm walls and a 1.6 mm cap over the 7.7 mm pocket. The screw engages 4.3 mm.

**Top retention.** The underside of the mast roof (Z 85, printed part 14, unchanged) holds the cells down through a **C-ring pad**: 1.5 mm fishpaper or G10 plus 0.5 mm closed-cell foam, OD 18, ID 12, the gap toward the slot. It bears on the rim, never on the tab. The seat-ring top (Z 18) to the roof (Z 85) is 67 mm, so **pad thickness = 67 mm − the cell's rim-to-rim length** (bottom face to the shoulder rim around the + cap, not to the cap top; usually 0.5–1 mm less than the 65 mm overall). Make it up from fishpaper/G10 plus 0.5 mm foam, and keep it at least 0.5 mm thicker than the cap height plus the tab, so the roof never touches the tab.
- **No soldered lead at the top of a cell:** only about 2 mm separates the cell top from the roof, and a soldered lead would be crushed there. Bring the welded nickel strip out through the pad's gap and down the 6 mm slot, and solder the lead to it below the floor.

**Pairs.**
- **Servo pair: 60° and 240°.** It feeds the servos and the camera.
- **FC pair: 150° and 330°.** Optional: it feeds the Vega. The slots may stay empty, with the Vega on its LiPo.
- In each pair, one cell is + up and one + down. The series link and the pack terminals are **below the floor**, in the shoulder cavity.
- Cells have spot-welded tabs and soldered leads. **There are no spring contacts.** Tabs and solder joints carry no load: the cells bear only on their rims.

### Power and wiring

- **Servo pack (2S, servo pair):**
  - 7.5 A fuse at the pack, under the floor;
  - up the roof pass to the **servo switch** (02, 30°, Z 106);
  - then to the 1000 µF / 16 V capacitor in its cup on the roof (unchanged) and the servo power bus.
  - There is **no 5 V supply**. 8.40 V (full charge) is the HV6160's maximum; keep the capacitor.
- **Camera:** stays on the servo pack. A 22 AWG pair with a 2 A fuse at the pack runs up the roof pass, through the Ø4 potted pass in the Z 270 floor (part 06) to the camera switch (Z 315) and the DC-DC converter on 07. The camera switch now switches only the camera. 06 and 07 print unchanged.
- **Vega:**
  - **FC pack** (FC pair): 10 A fuse at the pack, a JST-XH 3-pin pigtail in the shoulder cavity, the existing Vega switch at 300°.
  - **Or LiPo:** the pocket on the mast stays. The Vega's battery lead ends in the same JST-XH, so either pack plugs in, **never both**.
  - Firmware: LI_ION auto-detects 2S at 4.3–8.6 V, with LOW at 6.8 V and CRIT at 6.4 V. Both are below the Vega's 7 V floor, so **fly the FC pack at ≥ 7.4 V at rest**.
- **Charging:**
  - servo/camera pack: through the 3 existing contact screws at Z 321 (+, mid, −);
  - FC pack: through its JST-XH pigtail (balance lead).
- **Grounds:** the two packs are tied only through the servo-connector ground pins. There is no second bond. The servo return runs straight to the servo pack's negative.
- **Leads:** the servo leads run up the cassette's central channel and through the roof pass to the Vega header. The Y-cables are there.
- **Pyro:** the Vega's leads go down through the roof pass, the channel, the floor hole and the keeper's Ø12 hole to the four M3 brass posts in the bulkhead. Main is local; the drogue lead goes out to the tube.

### Shoulder bulkhead and joint

- **Joint:** 12 × M3×8 **button-head** screws at 15° + 30°·k in plain Ø3.4 holes, into ruthex M3×5.7 in gusseted bosses. A countersink would leave ~0.8 mm of the 2.2 mm skirt in bearing. **Pull-test the coupon (parts 16 + 17) to ≥ 3.0 kN before flying.**
- **Bulkhead:** 6.5 mm thick. The ribbon loop through the two T-slots is **permanent**: pot the slots and stems with high-temperature RTV.
- **Charge well:** library `ChargeHolder` (Ø14, 3 cc), on 2 × M3 through-bolts.
- **Terminals:** 4 × M3 brass posts (main pair, drogue pair), RTV-sealed.
- **Facing disc:** G10 1.5 mm (or 3 mm plywood), Ø94.7. Cutting template: part 18, `Canards/FacingDisc.svg`. It is located by the two well bolts and four posts and bonded with high-temperature RTV.
  - There is no recess or lip. The shoulder prints bulkhead-down, so either would leave a 95 mm bridge on the bed face.

### Numbers

`tools/canard_estimate.py` and `tools/nose_mass_cg.py` print these.

**Static margin and CG limits**
- **Why limits, not margins:** the `.ork` has a 2.8 kg stage-mass override, so it is no basis for the CG.
- **Method:** the tool moves the OpenRocket CP from the kit nose to the camera nose (nose CP 320 mm ahead of the rim against 269 mm for the kit nose), then adds the canards.
- **CG limit for ≥ 1.0 cal, measured aft of the forward body-tube rim:**
  - **574 mm at rail exit**. This is the binding case; the kit nose without canards allowed 620 mm.
  - 639 mm at max speed.
- **Canards jammed at 11° with the CG at that limit:**
  - one pair: 3.4° AoA at rail exit, 4.6° at max speed;
  - all four diagonally: 4.8° and 6.5°.

**Other numbers**
- **Hinge moment:** ≤ 0.43 kg·cm, about 3% of the HV6160's ≥ 14.5 kg·cm on the 2S pack.
- **Roll authority:** 360°/s is stopped in 1.4 s at 30 m/s and 0.12 s at 100 m/s. This is canard-alone; fin-wake interaction is not modelled.
- **Rail:** the canard tips are 54 mm beside the rail centre line.

**Nose mass and balance point** (complete, flight-ready, `tools/nose_mass_cg.py`). Two configurations:
- **2-cell:** the servo pair in the cassette, the Vega on its LiPo;
- **4-cell:** both pairs in the cassette, no LiPo.

| Group | 2-cell, g | 4-cell, g | Source |
|---|---:|---:|---|
| Printed parts 01, 02, 03, 04, 06, 07, 09, 10×4, 12, 14, 15, 19 + CAD camera nose, G10 facing disc | 892 | 892 | CAD: solid PETG 1.27 g/cm³ |
| Cells INR18650-25R (45 g each), Vega (25 g), 4× HV6160 (30.7 g) | 238 (2 cells) | 328 (4 cells) | spec |
| Camera internals, DC-DC, LiPo (2-cell only), switches, fuses, hubs, fasteners, inserts, wiring, glue, RTV, charge | 200 | 191 | estimated |
| **Total** | **1330** | **1411** | |
| **Balance point, forward of the forward body-tube rim** | **123 mm** | **117 mm** | |
| Balance point, aft of the nose tip (nose length 483 mm) | 360 mm | 366 mm | |

Before the cells moved (two cells in the camera bay): 1266 g, 146 mm. The
per-item list, with Z, source and configuration, is in the tool's output.

**Print assumption for the mass:** 0.2 mm layers, 4 perimeters, solid
infill. The 2.2 mm shells print solid anyway. With 15% infill the thick
blocks weigh less, so the printed-part figure is an upper bound.

**Spare canards:** `Canards/Canard_Span20.stl` has a 20 mm span. It moves
the CP 2.7 / 3.6 cm forward instead of 3.9 / 5.2, so the rail-exit CG limit
becomes 586 mm instead of 574.

### Parts

| Part | Render_Part | Print |
|---|---|---|
| 01 shoulder (`Canards/Shoulder.stl`) | 1 | Bulkhead down. 12 insert bosses with gussets; key at 105°. |
| 02 canard slice (`Canards/SliceBottom.stl`) | 2 | Wide end down. **Support the four Ø27.6 plug-hole crowns and the switch pad.** Printed: drill the servo-switch hole by hand. |
| 03 middle slice (`Canards/SliceMiddle.stl`) | 3 | As before. Adds ports and the USB window; can be drilled/cut in the printed 03. |
| 06 battery carrier (`Canards/BatteryCarrier.stl`) | 6 | As before, plus the Ø4 pass. Can be drilled in the printed 06. |
| 09 servo cassette (`Canards/ServoCassette.stl`) | 9 | Floor down, no supports. Four cell sleeves, four keeper-insert bosses. |
| 12 servo-switch saddle (`Canards/ServoSwitchSaddle.stl`) | 12 | Flat back down. Epoxied inside 02 at 30°, Z 106. |
| 10 canard ×4 (`Canards/Canard.stl`; spare `Canard_Span20.stl`) | 10 | Plug down, support under the blade root ends. |
| 14 Vega mast unit (`Canards/VegaMast.stl`) | 14 | Roof down. The LiPo-pocket floor bridges 22 mm between the webs. Printed: ream the roof pass to Ø11. |
| 15 charge well (`Canards/ChargeWell.stl`) | 15 | Base down. |
| 16 + 17 joint coupon (`Canards/Coupon_Slice.stl`, `Coupon_Shoulder.stl`) | 16, 17 | As the parts. |
| 18 facing disc template (`Canards/FacingDisc.svg`) | 18 | Cut from G10. |
| 19 cell keeper (`Canards/CellKeeper.stl`) | 19 | Plate down, no supports. |

**No carbon- or metal-filled filament on 02 or 03** (GNSS and 2.4 GHz).

### Assembly order (from below; the shoulder off)

0. **Servo switch, before the mast unit** (its nut is in the Vega bay, above the roof): drill 02, epoxy the saddle (12) inside, fit the switch and its leads.
1. **Mast unit:** fit the Vega, the LiPo (if flown) and the capacitor. Hang the servo-extension, power, pyro and camera leads down through the roof pass (reamed Ø11), including both packs' harness leads (servo pack to the servo switch, FC pack to the Vega switch). Slide the unit up and fit 4 × M3×10 button.
2. **Cassette:** melt the four keeper inserts into the floor bosses from below and thread the lacing cords through the tie holes. Fit the servos with their lugs, M2.5 bolts and nuts. Run the pack harness leads down the central channel and out through the floor hole. Connect the servo leads below the roof, slide the cassette up and fit 4 × M3×8 countersunk.
3. **Cells, from below:** lay a C-ring pad on each cell's top rim, gap toward the slot. Push each wired cell up through its floor hole, top lead in the slot and out through the notch, until the pad meets the roof. Hold the cells (tape) until the keeper is on.
4. **Keeper:** make the series links, fuses and pack terminals under the floor, onto the harness leads. Tie the pack leads with the lacing cords now (the keeper plate covers the tie holes once fitted). Push the keeper up so the seat rings take the cells' bottom rims, then fit 4 × M3×20 countersunk.
5. **Canards, from outside:** fit the hub on the spline, then the centre screw, then the plug with 2 × M2×8. Set the neutral offset in the firmware trim.
6. **Shoulder:** wire the four posts, then screw the shoulder on with 12 × M3×8 button head. The key goes into the notch at 105°.

**Service:** shoulder off; keeper off (4 screws, support the cells); untie the lacing cords (leave them threaded: they cannot be re-threaded with the servos in); the cells drop out with their leads. The cassette stays in.

### Still unverified

- **HV6160:**
  - the spline (teeth, OD, shaft height, centre-screw thread);
  - the lead stub;
  - the aluminium hub (the clamp hub Ø12 × 5 is assumed).
- **Vega:** the GNSS patch and WAGO envelopes and positions; their side of the board is inferred from the STEP plus "100 × 33 × 21 mm".
- **Cells:** the real rim-to-rim length (sets the pad thickness), the + cap height, and strip/lead routing through the slots and notches.
- **Servo switch:** the Schurter 0033.4513 is rated 6.3 A / 250 VAC (300 no-load cycles); no DC rating is given, and the servo fuse is 7.5 A.
- **Masses:** every item marked est in the mass table.
- **Joint strength:** to be shown by the ≥ 3.0 kN pull test.
- **Sealing:** the foam seal and the actual leak area.
- **Fits:** printed fits and insertion.
- **Aerodynamics:** canard-wake/fin interaction.

Checks: `tools/verify_camnose_canards.py`, report in `canard-verification.json` (276/276 on 2026-11-19). Besides the earlier checks, it covers:
- the four cell envelopes with their top pads, the keeper and its screws against the shoulder, 02, 09, 14, the Vega, the servos, the arms and the canards at 0, ±10.5 and ±11.5°;
- the keeper above the shoulder's boss tops (Z 13.5 against Z 12);
- the keeper inserts' 1.6 mm walls and 1.2 mm cap;
- the lug-bolt driver lines and nut-insertion paths against the cells;
- the servo switch and saddle, and the mast unit's insertion past both switches;
- the Ø11 ream;
- that 01, 02, 03, 06, 07, 10, 14, 15, 16, 17 and the flag-off parts render to exactly the committed triangles.

The new sleeves add no overhang to 09: its overhang area rises from 455 to 505 mm², and the 50 mm² are the four Ø4 ceilings of the keeper-insert pockets.

## Revision 2026-11-08 — sleeves, insert pockets, flush screws, ribbon slots

Changes from the owner's first full print:

- **06 carrier:** the cell cups are now **full-height sleeves** and the two
  tray screw bosses are moulded into their outer ends along the whole
  height. The free-standing 8 mm posts are gone. Each sleeve has one
  full-height 6 mm slot, both on **−Y**, so a cell with soldered tabs (or a
  pair already joined at the bottom) slides in from above with its lower tab
  running down the slot.
- **07 tray:** the short cups around the cell tops are gone (the sleeves
  locate the cells); the keeper ring and its ribs remain. The bath rim is
  notched where the countersunk tray screws go in — before, the rim
  overhung each head by 1.8 mm, so the screw could not be inserted.
- **All blind heat-set pockets are 7.7 mm deep** (insert 5.7 + 2). ruthex
  specifies at least L + 1 mm; the old 5.9 mm pockets left the displaced
  plastic nowhere to go, and it ran into the thread. Tray bosses also have a
  Ø3.4 relief below the pocket for the screw tip.
- **04 top shell:** the three service-joint screws are **countersunk**, flush
  with the shell (M3 90°, head ≤6.2 mm). The seat is 1.4 mm deep in the
  2.2 mm wall — do not over-tighten.
- **01 shoulder:** each recovery slot is **T-shaped**: a 4 mm stem runs 8 mm
  from the middle of the 16 × 4 mm slot toward the axis, for a copper guide
  wire to pull the ribbon through after assembly.
- **03 middle slice:** the three service-joint insert bosses used to stick
  7.4 mm out of the wall with a flat underside, and the slicer flagged them as
  floating cantilevers. Each now has a gusset below it that runs down into
  the shell wall, about 34° from vertical, so the slice prints without
  support. The gussets stay inside the boss footprint, so the carrier floor
  still passes them through its scallops.

**Reprint 01, 06 and 07.** The printed 03 and 04 can be reworked instead:

- 03, three floor-seat pockets (on the seat face at Z=270): drill Ø4.0 mm to
  7.7 mm deep before fitting inserts. The CAD keeps ≥1 mm of corbel under
  that depth.
- 03, three service-joint bosses: drill Ø4.0 mm to 7.7 mm deep from the
  boss face (was 6.0 mm); a Ø3.4 hole already continues beyond.
- 04, three side holes: countersink 90° to Ø6.2 mm.

A reworked 03 keeps its old bosses without gussets. That is fine if they
printed cleanly. To print a new 03, use the current STL.

02 is unchanged. The board stays with its 47 mm side along X: turned 90°,
it blocks the switch body when the top shell lifts off. CAD checks for this
revision: `sleeve-revision-verification.json` (114/114).

## Shoulder insertion chamfer and tube fit — 2026-11-03

**The owner reports four gauge bands entered, while the fifth did not:**
Ø98.9 mm entered and Ø99.1 mm did not. The current 01 therefore retains
its **Ø98.7 mm body**, 0.2 mm smaller than the largest band that entered,
to allow some margin along the 100 mm insertion length.

**Print the updated 01 bulkhead-down.** Its insertion end now starts at
Ø96.7 mm and tapers smoothly to Ø98.7 mm over the first 2 mm. This external
lead-in helps centre the shoulder and avoids a square edge catching the
tube rim. The main bore, existing internal chamfer, ribbon slots and upper
Ø96.7 × 15 mm spigot are unchanged. The already printed parts need no
reprint for this change. The full-length shoulder still needs a dry fit.

The gauge and its measured result are documented below for reference.
Current shoulder CAD checks are in `entry-chamfer-verification.json`;
Bambu Studio was not used for this revision.

### Stepped gauge

**The owner reports that the Ø99.7 mm ring does not enter the tube.**
That +1 mm trial is rejected. The tube's outside-profile difference did
not establish the inside clearance. Part 00 is now a stepped insertion
gauge spanning Ø98.3–99.1 mm in 0.2 mm increments, 15 mm tall overall.

Print it **largest end down**, as supplied. Insert the **smallest end
first**, without forcing it. From that small end, each 3 mm band is:

| Band from insertion end | Diameter | Depth reached when that band has entered |
|---|---:|---:|
| 1 | 98.3 mm | 3 mm |
| 2 | 98.5 mm | 6 mm |
| 3 | 98.7 mm | 9 mm |
| 4 | 98.9 mm | 12 mm |
| 5 | 99.1 mm | 15 mm |

The first four bands entered in the owner's trial. The tip has a 0.3 mm lead-in;
judge the full cylindrical band, not just the beveled tip. A similar relief
at the bed keeps first-layer flare away from the largest test surface.

The gauge supports retaining the original **Ø98.7 mm** shoulder body.
A short gauge does not prove that a full 100 mm-long shoulder will fit
an oval or bowed tube. Parts 02/03/04/06/07 remain unchanged.

Use the current numbered STLs. The initial Ø101.5 outside-profile ring and
the subsequent Ø99.7 insertion ring are superseded. Existing 3MF projects
contain earlier shoulder geometry; import the current STL. The gauge's
original CAD check is recorded in `fit-gauge-verification.json`.

## How 04 and 06 fit together

**06 does not go completely inside 04.** Its bottom is supposed to remain
**24.28 mm below the wide lower edge of 04**. The carrier floor sits in
**03**, which surrounds that lower portion. Insert 06 sleeves-first through
04's wide end for a trial fit; do not force the carrier floor up to the
04 rim. The screw bosses (±X) must face the shell sides away from the
switch (+Y) and charging pads (−Y). Part 07 screws to the tops of the bosses.

The owner printed 04/06/07 and reported approximately 24 mm remaining
outside, which matches this arrangement. That observation does not require
those parts to be reprinted. As of 2026-11-03, the owner has printed every
required part except 01; full assembly fit has not yet been reported.

![Centre section showing the carrier floor 24.28 mm below part 04](AssemblyPosition.png)

## Recovery ribbon

The recovery strap goes through **01-Shoulder**, not through the electronics
barrier. Its two rounded slots are **16 × 4 mm**, suitable as a nominal
opening for the owner's approximately 15 mm-wide ribbon; they clear a solid
15 × 3 mm test gauge. Since 2026-11-08 each slot is **T-shaped**: a 4 mm
stem runs 8 mm from the middle of the slot toward the axis (both stems point
at each other). With the nosecone assembled, push a copper wire through the
stem, hook the ribbon, and pull it through the slot. Actual ribbon thickness
and printed clearance still need checking.

## Shoulder chamfer — 2026-11-03

The preceding chamfer revision replaced the internal ledge. The bore now
narrows gradually over 2 mm at the spigot instead of leaving a 1 mm radial
horizontal ledge. Print bulkhead-down as before. Outside mating surfaces,
115 mm total height and both 16 × 4 mm ribbon slots are unchanged; the
already printed parts need no revision for this fix.

Bambu Studio 02.08.02.61 was run on the old and new shoulder with the same
P1S/0.4 mm, 0.2 mm-layer settings and automatic tree supports enabled. The
old mesh produced support paths; the new mesh produced **zero support or
support-interface paths**. Geometry checks also confirm the unchanged fit
to 02 and clearance for a 15 × 3 mm ribbon gauge. This verifies the CAD and
sliced paths, not a physical print. See `shoulder-verification.json`.

![Bay cutaway: blue cells, green converter, orange carrier](BayCutaway.png)

The camera itself is the owner's existing CAD design, not the grey flange
in this view. Its mesh is on `feature/rocket60` at
`STL Files/Rocket60/NoseCone.stl`.

## Print these parts

| Part | Mesh | Height | Bed orientation |
|---|---|---:|---|
| 0 | `TestRing.stl` | 15 mm | Largest end down; five Ø98.3–99.1 fit bands |
| 1 | `Shoulder.stl` | 115 mm | Bulkhead down |
| 2 | `SliceBottom.stl` | 154.15 mm | Wide end down |
| 3 | `SliceMiddle.stl` | 154.13 mm | Wide end down; includes floor seat and service-joint bosses |
| 4 | `SliceTop.stl` | 94.95 mm | **Camera flange down**; rotate 180° about X or Y |
| 6 | `BatteryCarrier.stl` | 77 mm | Solid floor down; sleeves and bosses print upright, no supports |
| 7 | `ConverterTray.stl` | 11.4 mm | Bath opening down; rotate 180°; support under the bath floor |

**Do not print or install `Adapter.stl` with this bay top.** Part 5 is kept
only for the previous separate-adapter design (`Bay_Enabled=false`). The
new top has an integral flange, with no spigot or adapter-to-shell glue joint.

Repository meshes retain their assembly coordinates: orient, then drop to
bed. The downloadable print pack is already oriented at Z=0. Part 2 keeps
its previous shape; part 1 has both internal and entry chamfers at Ø98.7. Parts
3 and 4 replace the pre-bay versions; the owner's already printed bay
versions remain current. Part 8 is a cutaway view, not a printable part.

Use PETG or ASA as before. Start with 0.2 mm layers and at least four
perimeters; use local solid-infill modifiers for the floor, flange, screw
bosses and insert seats. Inspect the slicer's paths. Support the tray bath
floor; check whether the top shell's internal panel pads need
local support. Clear all tab reliefs and cable-tie tunnels after printing.

## Hardware

| Item | Quantity | Use |
|---|---:|---|
| ruthex RX-M3×5.7 inserts, Ø4.0 × 7.7 mm pockets | 11 | 3 camera, 3 service joint, 3 floor, 2 tray bosses |
| M3×8 button-head screws | 3 | Carrier-floor screws |
| M3×8 **90° countersunk** screws, head ≤6.2 mm | 5 | 3 shell side screws, 2 converter tray; all heads flush |
| Camera's existing M3 screws | 3 | Match actual camera base; ≤5.7 mm insert engagement |
| Schurter 0033.4513 + 0098.0043 nut | 1 each | Switch; nut may be a separate order |
| M3 countersunk screws, nuts and terminations | As wired | Three unassigned charging-contact seats |
| 2.5 mm cable ties | 2 | Converter restraint |
| Insulating liners/end pads, sealant, optional epoxy | As fitted | Insulation, floor seal, optional converter bond |

The owner supplies series wiring, charging, polarity and tab connections.
There are no battery spring contacts. The three exterior screw seats are
mechanical provisions, not a circuit or charger specification; unused
seats can be closed with insulating plugs.

## Check before the large prints

- Cell envelope: **18.5 mm wrapped diameter × 65 mm body**, excluding tabs.
  Cup ID 19.5 mm; 2 mm lower tab relief, at least 5 mm above the body,
  and 6 mm-wide exits. Measure actual cells and tabs; adjust `Bay_Cell_D`
  and `Bay_Cell_Body_L` if needed, then regenerate and recheck the model.
- The sleeves (ID 19.5 mm) locate the cells; each has a 6 mm loading slot
  on −Y. The keeper ring on 07 has 0.6 mm axial clearance, taken up with an
  insulating annular pad. Ø14.5 mm centre openings and split exits leave terminals
  accessible. Bear on the insulated rim, not solder tabs or the vent.
  Do not fill these reliefs with epoxy.
- Converter envelope: 47 × 26 × 13 mm; bath footprint 47.8 × 26.8 mm.
  Support surface Z=350. Allow at most about 1 mm adhesive underneath
  without rechecking. Real terminals, wiring and cooling still need a fit check.
- Switch: nominal Ø12.7 hole plus R1.2 key relief, overall keyed height
  13.6 mm, in a 6 mm flat panel. Finish to the actual part; drawing range
  is 12.6–12.7 mm. A conservative Ø16 × 23.5 mm rear envelope was checked.
  The flat back supports the nut. Datasheets are in `docs/datasheets/`.

Print the carrier and tray first to check the real cells, tabs, pads and
converter. The nominal values are an envelope, not measurements of the
owner's cells. Tray ears have relatively little shell clearance: dry-fit
the complete assembly in the actual top before bonding.

## Assembly and service

1. Fit all inserts with the parts empty; let them cool before adding
   electronics. The three service inserts go into the middle slice from
   outside with the top removed, not into the thin top-shell screw holes.
2. Dry-fit the carrier through the middle slice's upper opening, aligning
   its three scallops with the joint bosses. The floor rests on the seat
   at Z=270. Its screws are offset 60° from the joint screws. A long driver
   reaches the floor screws from above.
3. Seal the full floor-to-seat perimeter, including beneath the scallops
   and around the floor fasteners. Nominal seal land is at least 3 mm at
   the scallops. Use a thin bedding layer, keeping the designed floor
   height. Epoxy makes this floor permanent; a suitable removable seal
   preserves removal. Seat insert pockets are blind. No wire hole passes
   through the barrier; all current wiring stays above it.
4. Slide the insulated cells into the sleeves from above, lower tabs down
   the −Y loading slots and out through the reliefs, then fit the
   keeper/tray with two flush countersunk M3×8 screws into the bosses. Confirm
   retention without loading tabs. The keeper provides axial retention;
   potting cells is unnecessary. Leave vents and terminals unobstructed.
5. Secure the converter using both ties through the 3.2 × 1.2 mm tunnels.
   Optional epoxy can supplement restraint where the real converter
   permits it. Keep solder joints, hot components and screw paths clear.
6. Fit the switch and desired charging hardware. Provide strain relief
   and service slack or a disconnect so the top can lift clear. Switch
   is on +Y, contact seats on −Y; no rail-button clocking is assumed.
7. Bolt the camera to the integral flange. Its Ø37.96 bolt circle remains
   **52.2°, −52.2°, 180°**, preserving the original camera orientation.
   The harness passes through the Ø29.56 central bore.
8. Attach the top with three countersunk M3×8 side screws, flush with the
   shell; the seat is only 1.4 mm deep, so do not over-tighten. **Do not glue this service
   joint.** After trial assembly, epoxy shoulder-to-bottom and
   bottom-to-middle as before. Dry-fit the shoulder's 98.7 mm outer body
   through the full insertion depth before bonding it to the nosecone.

For normal service, remove the three side screws and lift the top with
its camera attached. Remove two tray screws for cell access. The entire
carrier can also pass through the opening if its floor seal is removable.
The integral flange does not obstruct these operations.

The supported, sealed 4 mm floor is a **proposed debris/gas barrier**, not
an established pressure vessel or validated blast shield. Charge location,
size, temperature and printed-part response remain unverified. The selected
Schurter switch is rated 6.3 A/250 VAC and 300 no-load cycles in its datasheet;
no DC rating is given. Retaining it does not establish a DC rating.

## Pre-commit guard

```sh
tools/install_hooks.sh            # once per clone; the hook is shared by all worktrees
export CAMNOSE_PYTHON=/path/to/python   # optional; needs tools/requirements-camnose.txt
```

The hook runs only when the staged change touches a `.scad` file the cam nose
uses (`PeregrineCamNose.scad`, `PeregrineCamCanards.scad`, `PeregrineCamBay.scad`
and what they include) or anything under `STL Files/PeregrineCamNose/`; other
commits and branches without `tools/precommit_camnose.sh` are not affected. It
checks the **staged** content (about 90 seconds): `verify_camnose_canards.py`,
`verify_camnose.py` and `verify_camnose_bay.py` must pass, and every committed
STL here must match a fresh render of the staged source (same triangle count,
volume within 1e-5 relative, bounds within 0.001 mm). A `.3mf` next to an STL
with a different triangle count only prints a warning; the `.3mf` files are
never touched. Emergency bypass: `git commit --no-verify`.

## Verification and regeneration

```sh
python3 tools/verify_camnose.py --output-dir /tmp/camnose-meshes
python3 -m venv /tmp/camnose-venv
/tmp/camnose-venv/bin/pip install -r tools/requirements-camnose.txt
/tmp/camnose-venv/bin/python tools/verify_camnose_bay.py /tmp/camnose-meshes
```

The first check renders meshes and measures dimensions, topology, overlaps
and camera holes. The second checks connected/watertight solids, component,
tab and hardware intersections, blind insert seats, a continuous carrier
insertion envelope and shell/switch removal at 1 mm intervals. It must reject
an oversized converter and an unscalloped floor. `verification.json` records
the 2026-11-02 bay baseline; `shoulder-verification.json` records the
2026-11-03 chamfer checks and slicer comparison before the diameter change.
`tube-fit-verification.json` records the subsequently rejected Ø99.7 trial's
CAD checks. `fit-gauge-verification.json` records the stepped gauge and
restored Ø98.7 shoulder before the external lead-in was added.
`entry-chamfer-verification.json` records the shoulder with its external
lead-in, the owner's gauge result, and unchanged mating geometry.
`sleeve-revision-verification.json` records the 2026-11-08 revision: sleeves
and fused bosses, 7.7 mm blind pockets, tray-screw insertion path,
countersunk service screws and the T-slot stems. Every new check there also
fails on the previous meshes.
No slicer was used for these later revisions. To repeat dimensions and
overhang regression, use
`python3 tools/verify_camnose.py 0 1 --output-dir /tmp/camnose-shoulder`.
Tests do not simulate print tolerances, strength, heat, leaks or flexible wiring.

Sources: `PeregrineCamNose.scad`, `PeregrineCamBay.scad` and repository
libraries. Keep `Render_Part=0` committed. Export an individual part with:

```sh
OPENSCADPATH="$PWD" /Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD \
  --render --export-format binstl -o part.stl -D Render_Part=6 PeregrineCamNose.scad
```

Use full render (F6), never the library's F5 cutaway. Part 8 is an inspection
view only. The original camera-to-ogive slope change remains; the camera
housing itself is unchanged.
