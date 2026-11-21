# LOC Zeus 2.26" fin alignment guide

Source: `ZeusFinGuide.scad`. It works like the LOC fin alignment guide: it
slides down the booster and rests on the fins, holding all four 1/8" fins
radial and 90° apart. The slots are open at the outside, so any fin span or
sweep fits.

| File | What |
|------|------|
| `ZeusFinGuide.stl` | Guide: 127.4 mm across, 40 mm tall, Ø57.8 bore, 3.53 mm slots |
| `ZeusFinGuide-FitTest.stl` | 10 mm ring with the same bore and slots, to check fits first |
| `ZeusMidFinGuide-Split.stl` | Split guide for the mid-body fins: two halves, bolted together around the tube |

## Split guide for the mid-body fins

This is the same guide cut in two along a line halfway between fins, so
each half carries two whole fin slots. The halves close around the tube
anywhere along the body, so the guide does not have to pass the aft fins
or come in from an end.

- **Hardware:** 4 × M3×14 socket-head screws and 4 × M3 nuts. M3×12 and
  M3×16 also work. Each nut drops into the hex trap, and the screw head sits
  in the counterbore on the other half.
- **Use:**
  1. Close the halves around the tube just ahead of the fins.
  2. Tighten until the halves touch. The bore is the same as the one-piece
     guide, so it still slides rather than clamping.
  3. Slide it onto the fins until the collar band stops on the roots. Turn
     it around to work from the other side of the fins.
- **Print:** both halves together, flange down, no supports. The horizontal
  screw holes print as small arches.

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
