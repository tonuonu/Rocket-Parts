# Lessons

Rules learned from corrections. Read at session start.

## GitHub
- This repo is a fork with an `upstream` remote (DavidMFlynn/Rocket-Parts).
  Always pass `--repo tonuonu/Rocket-Parts` to `gh pr` commands. Without it,
  `gh pr create` once opened a PR on the parent repo (closed at once).
- "Do what is right" is not an instruction to merge. Merge only on an
  explicit "merge".

## Simulation
- Calibrate a model against OpenRocket with **identical** inputs (mass,
  motor, rail). A calibration against a different mass looked fine and was
  wrong; the review caught it.

## CAD review
- Look at a cutaway of the whole assembly, not just the part in hand. The
  open e-bay (no bulkheads) was only visible in the half-section view.
