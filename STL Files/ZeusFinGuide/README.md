# LOC Zeus 2.26" fin alignment guide

Source: `ZeusFinGuide.scad`. It works like the LOC fin alignment guide: it
slides down the booster and rests on the fins, holding all four 1/8" fins
radial and 90° apart. The slots are open at the outside, so any fin span or
sweep fits.

| File | What |
|------|------|
| `ZeusFinGuide.stl` | Guide: 127.4 mm across, 40 mm tall, Ø57.8 bore, 3.53 mm slots |
| `ZeusFinGuide-FitTest.stl` | 10 mm ring with the same bore and slots, to check fits first |

- **Print:** flange down, no supports. PLA or PETG, 0.2 mm layers, 3 walls.
- **Use:** slide the guide on from the forward end until its collar band
  stops on the fin roots. If there is tube left behind the fins, a second
  guide can go on from the aft end.
- **Glue:** the slot is 1.5 mm wider each side next to the tube, so the root
  glue bead does not reach the guide. Wax or tape the slot faces anyway.

Defaults are nominal: tube OD 2.26" (57.40 mm) and fin 1/8" (3.175 mm).
Neither has been measured on the kit, and there has been no physical test
print. If the fit-test ring is loose or tight, change `Tube_OD`, `Fin_T` or
the clearances in the .scad.

CAD checks (trimesh/manifold, at the default parameters):
- The part is one watertight solid.
- A Ø57.40 tube passes through the bore.
- A 3.175 mm fin passes through every slot, and a 3.6 mm fin is rejected.
- The collar band stops the fin root.
- No face points downward above the bed, so there are no overhangs.
