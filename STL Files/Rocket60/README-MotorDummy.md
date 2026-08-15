# Mass-equivalent inert motors

`MotorDummy_G80T.stl` · `MotorDummy_H182R.stl` · `MotorDummy_H135W.stl`
Generated from `MotorDummy29.scad`.

Same envelope *and* same mass as the real motor, so ground tests load the
rocket the way it actually flies. A 128 g motor sits ~480 mm aft of the nose
and is the single largest mass in the airframe — swing-testing or
drop-testing without it measures a different rocket, and separation tests
with an empty motor tube let the aft section move far too easily.

## Ballast

Print the shell, **weigh it**, then fill the cavity to the target. The
figures below assume PETG at 1.27 g/cm³ and 100 % walls; your printer will
differ, which is why you weigh it rather than trusting the number.

| Dummy | Shell | Cavity | Ballast → loaded | Ballast → burnout | Total loaded / burnout |
|---|---|---|---|---|---|
| G80T-14A | 28.4 g | 58.4 cm³ | 99.6 g | 36.6 g | 128 g / 65 g |
| H182R-14A | 45.3 g | 96.6 cm³ | 161.7 g | 46.7 g | 207 g / 92 g |
| H135W-14A | 48.0 g | 102.9 cm³ | 164.0 g | 82.0 g | 212 g / 130 g |

Required ballast density is 1.6–1.7 g/cm³ loaded — dry sand (~1.5) is
marginal, steel shot (~4.5) or lead shot (~6.5) is comfortable. Loose fill
is deliberate: **one print covers both cases.** Fill to the loaded figure,
test, pour some out to the burnout figure, test again.

The burnout case is the one that matters. Deployment happens after burnout,
when the motor has lost its propellant — 63 g of the G80T's 128 g. Testing
separation only at loaded mass tests the wrong condition.

## CG

The real motor's CG is not published. A uniformly-filled dummy puts it at
mid-length, which is fine for fit, separation and ejection testing. If you
need CG fidelity for a swing test, bias the ballast aft and note that you
did — do not assume this part is faithful there.

## Print

Aft end down, no supports. The cavity is a plain bore and the open forward
end needs no bridging. Two grip flats near the forward rim let you pull it
back out of the motor tube. Retain the ballast with tape or a printed plug —
deliberately not a thread, so the fill can be changed between tests without
tools.

Ø28.8 gives 0.2 mm clearance in a 29 mm motor tube.

## Verified

Each export was checked against its expected geometry after rendering:
124.00 / 203.00 / 216.00 mm at Ø28.80.

The first version sealed the cavity at both ends — ballast could not go in.
The render caught it as **genus −1** (two surface components, i.e. an
enclosed void) instead of the expected 0. Bounding box and mass would both
have looked correct.
