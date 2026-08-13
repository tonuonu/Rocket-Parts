# PeregrineCamNose.scad: graft the CAD nosecone on instead of reinventing the camera housing

## What changed

- `Cut3_d = 60` added, following the existing `Cut1_d`/`Cut2_d` pattern. Its
  Z is *derived* in-file with the library's own `Ogive_Cut_Z()` call (not
  hand-interpolated): `Cut3_Z = 383.229`.
- All camera-specific geometry deleted: `CN_MountHoles()`, `CN_Spacer()`,
  the lens hole and mount holes in the top slice, `Lens_D`, `Cam_Mount_R`,
  `Cam_Mount_B`, `Spacer_Front_T`, `Spacer_Rear_T`, `M3_Head`, and old
  `Render_Part` 5/6 (spacers). `Apex_Z` also removed -- nothing references
  the true apex anymore since nothing above Cut3 is ever printed.
- `NC_Tip_R` restored to `8` (was `26`).
- New `CN_Adapter()` (`Render_Part = 5`): flange flush with the shell/CAD
  base (OD 60), 3x Ø3.4 clearance holes on the CAD cone's own bolt circle
  (R18.98, angles 52.2/-52.2/180, no counterbore), and a 15mm spigot
  (Ø55.2) epoxied into the shell's Ø55.6 Cut3 bore. The flange's own bore
  is narrower than the spigot's hollow, leaving a solid shelf for the screw
  holes to pass through with the screw heads seated on its underside and
  the wider spigot hollow open beneath for a screwdriver and the camera
  harness (genus 4, confirmed by render: 1 harness bore + 3 screw tunnels).
- `tools/verify_camnose.py` reworked: dropped the camera-envelope/lens/
  spacer checks (nothing left to check), added Cut3 dimension checks and a
  mesh-against-mesh check that the adapter's spigot OD actually clears the
  shell's actual bore ID at the tightest point (right at the Cut3 rim,
  where the bore is narrowest).

## Status: all checks pass

```
all checks passed
```
17 checks, including genus (parts 0/1/4/5), joint overlaps, and the new
spigot-vs-bore mesh check: measured clearance 0.39mm vs the 0.40mm design
target -- confirms the fit is real, not just consistent constants.

## Parts 2 and 3: proven unaffected

Rendered both parts before and after the edit and diffed the meshes:

| | part 2 (bottom) before | after | part 3 (middle) before | after |
|---|---|---|---|---|
| bbox (zmin/zmax/dmax) | 0 / 154.147 / 101.5 | identical | 147.14 / 301.280 / 96.112 | identical |
| volume | 106.229760 cc | Δ = -6e-14 cc | 93.028840 cc | Δ = +3e-13 cc |
| facets | 15060 | 15050 | 11934 | 11932 |

Bounding box and volume match to double-precision noise. The facet-count
difference (10 and 2 triangles) traced to individual vertices: every single
"extra" vertex in the new mesh sits exactly on the flat join-plane
(Z=147.147 / Z=294.280) and nowhere else -- it's CGAL re-triangulating the
flat cut-cap face slightly differently because `NC_Tip_R` feeds into the
same boolean pipeline (even though the tip itself is 165-390mm away and
irrelevant), not a change to the ogive surface. No vertex differs off that
plane. Confirmed analytically too: `Cut_Z` in `BluntOgiveNoseCone` depends
only on `R, L, Base_L, Cut_d`, never `Tip_R`, and the tip-blend region
starts at Z=418.6 (old Tip_R=26) or Z=543.3 (new Tip_R=8) -- both far above
either cut plane. Nothing that was already printed changes.

## Cut3_Z: derived value vs. the interpolated estimate

The task's coarse interpolation (60.10 @ Z=383.0, 59.91 @ Z=384.0) suggested
Z~383.5. The derived formula gives **Z=383.229**. I independently bisected
the actual mesh's facets (not just a 1mm grid) and found OD=60.00 at
**Z=383.13** -- 0.10mm from the formula, consistent with ordinary `$fn`
tessellation chording, not a real disagreement. The formula-derived value
is more trustworthy than the coarse grid estimate and is what's in the file.

## Slope kink at the joint (measured, not assumed)

- Peregrine ogive, local half-angle at Cut3 (analytic, cross-checked
  against the mesh by finite difference): **~6.5°**.
- CAD nosecone base: it's a curved profile too, not a straight cone --
  **~0.4°** right at the base plane (linear fit of mesh crossings,
  Z=0.1-1.0mm), rising to ~3° by 25mm up.
- Net visible kink at the joint: **~6°**, somewhat sharper than the task's
  rough "5.4° vs 1.15°" estimate. Inherent to grafting two different
  cones; not fixable without redesigning one of them.

## Concerns / things to check before printing

- The CAD nosecone STL itself (`STL Files/Rocket60/NoseCone.stl`) lives on
  another branch, not this worktree; I worked from the measured
  dimensions given and independently verified the angle/Cut3 numbers by
  extracting that file via `git show` for measurement only -- I did not
  merge it in or add it to this branch.
- Adapter flange thickness (4.5mm) and epoxy gap (0.4mm) are my design
  choices, derived from the given M3x10/insert-5.7mm spec and the file's
  existing epoxy-gap convention respectively -- not dictated by the task,
  worth a sanity check against the actual screws on hand.
