# Claude Guidelines for Rocket-Parts

This file contains repo-specific rules and references for AI assistants working on this codebase.

## Workflow

- **NEVER push to main.** Always use feature branches.
- **NEVER merge PRs.** Push branch, open PR, wait for Tõnu to merge.
- **NO UNAUTHORIZED CHANGES.** Recommend first. Implement only when explicitly asked.
- Use `vi` for CLI editing (not `nano`).
- After pushing shell scripts via GitHub API, the `+x` bit is stripped. Follow up locally with `git update-index --chmod=+x` as needed.

## Build & Verify

- OpenSCAD renders are verified by Tõnu via F6 (full render), not F5 (preview).
- Do not claim a geometry fix works without Tõnu confirming via F6.
- Read actual file state before claiming. Do not speculate or guess what's on screen.
- Bambu P1S max print height: 250mm with AMS (not 256mm).

## Component References

These reference docs contain dimensions, pinouts, and mounting details pulled from
official manuals. **Always consult these before designing mounts — values in code
comments may be stale.**

| Component | Reference |
|-----------|-----------|
| CATS Vega flight computer | [CATS-Vega-Reference.md](CATS-Vega-Reference.md) |

### Common Mistakes to Avoid

- **CATS Vega height is 15mm, NOT 21mm.** This error has appeared multiple times.
  The 21mm figure was apparently copied from an unverified source. Page 19 of the
  CATS User Manual clearly states 100 × 33 × **15** mm.
- Vega has **3 mounting holes in an L-pattern** (60 × 27 mm spacing), NOT 4 holes
  in a rectangle. The bottom-right corner is blank — that's where the SMA antenna
  connector and pyro terminal blocks live.
- Vega **cannot** be mounted inside a carbon fiber section — RF blocked.
  Polycarbonate (used on Peregrine) is fine.

## Project-Specific Notes

### Apogee Peregrine (100mm body)
- Body OD: 101.5mm
- Body ID: 99.0mm
- Coupler OD: 98.0mm (fits inside body tube)
- Coupler ID: 92.0mm
- Wall: 3.0mm
- Print material: Bambu PC (polycarbonate)

### Related Files
- `PeregrineEBay.scad` — existing E-Bay (pre-ejection design)
- `PeregrineEjection.scad` — new active bayonet ejection system
- `PeregrineFinCan.scad` — L2 3-fin fin can
- `PeregrineFinCan75.scad` — L3 4-fin split-print
- `PeregrineNoseCone.scad` — nose cone
