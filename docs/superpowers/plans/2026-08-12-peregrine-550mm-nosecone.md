# Peregrine 550 mm Sliced Nosecone Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite `PeregrineNoseCone.scad` to produce a 550 mm blunted-ogive nosecone for the 100 mm Apogee Peregrine, split into six 3D-printable parts that glue together.

**Architecture:** All new geometry lives in `PeregrineNoseCone.scad`. The shared library `NoseCone.scad` is **not modified** — its `BluntOgiveNoseCone` is called once per slice with a different `Cut_d`, and the middle slice is clipped out with `intersection()`. A Python harness renders each part via the OpenSCAD CLI and measures the resulting STL, because a part that does not fit still renders `Status: NoError`.

**Tech Stack:** OpenSCAD 2026.07.09 (`/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD`), Python 3 (stdlib only — no pip installs), git.

## Global Constraints

- **Never modify `NoseCone.scad`.** ~20 other rocket designs depend on it. If a change there seems necessary, stop and ask.
- **Every part must be 3D printed.** No purchased coupler tube, no metal hardware (no U-bolts, no rivets). Parts are joined with superglue.
- **No printed piece may exceed 250 mm tall** (Bambu P1S usable Z).
- **All clearances are diametral, not radial.**
- Spec: `docs/superpowers/specs/2026-08-12-peregrine-550mm-nosecone-design.md`
- Work on branch `feature/nosecone-550mm-sliced`.
- Render with `-o file.stl` (full render). Never trust F5 preview — the module applies a quarter cutaway under `$preview`.
- `OPENSCADPATH` must point at the repo root or `include<NoseCone.scad>` silently resolves to nothing and renders an empty object.
- **No self-attribution in commits.** No `Co-Authored-By`, no "Generated with" lines.

## Frozen Geometry Values

Copy these verbatim. They were solved and verified against rendered STLs; do not recompute.

```
Peregrine_Body_OD    = 101.5
Peregrine_Body_ID    = 99.0
Peregrine_Coupler_OD = 97.1      // = Body_OD - 2*Wall_T (shell ID)

NC_Length  = 574.55              // gives apex at exactly 550.0
NC_Base_L  = 15
NC_Tip_R   = 8
NC_Wall_T  = 2.2
NC_nRivets = 0

Cut1_d = 92.85                   // lands at Z = 183.33
Cut2_d = 63.66                   // lands at Z = 366.67
Cut1_Z = 183.33                  // clip plane for the middle slice

Shoulder_L         = 100
Shoulder_OD        = 98.6
Shoulder_Spigot_L  = 15
Shoulder_Spigot_OD = 96.7
Shoulder_Bulk_T    = 4

Ring_T     = 6
Ring1_OD   = 82.0                // seats in joint-1 flange bore 82.47
Ring2_OD   = 52.0                // seats in joint-2 flange bore 52.41
Ring_Eye_d = 12
Ring_Wall  = 4
```

Exposed height is `NC_Base_L + NC_Length - X0 + NC_Tip_R`. The `+ NC_Tip_R` term is easy to miss — `Tip_Z` inside the module is the tip *sphere centre*, not the apex.

## File Structure

| File | Responsibility |
|---|---|
| `PeregrineNoseCone.scad` | **Modify (full rewrite of body).** All parameters, the six part modules, and the `Render_Part` selector. |
| `tools/verify_nosecone.py` | **Create.** Renders a part and measures its STL. The acceptance gate for every task. |
| `NoseCone.scad` | **Do not touch.** Provides `BluntOgiveNoseCone`, `RoundRect`, `IDXtra`, `Overlap`. |

`tools/` is a new directory — this repo has no existing Python or shell tooling. That is a deliberate, flagged addition: the spec requires measured acceptance criteria, and there is no other way to check them repeatably.

## Render Part Map

| `Render_Part` | Part |
|---|---|
| 0 | Test ring (print first) |
| 1 | Shoulder + bulkhead + anchor |
| 2 | Bottom slice |
| 3 | Middle slice |
| 4 | Top slice (filled tip) |
| 5 | Guide ring, lower (82.0) |
| 6 | Guide ring, upper (52.0) |

---

### Task 1: Verification harness

Build the measuring tool first. Every later task uses it as its test.

**Files:**
- Create: `tools/verify_nosecone.py`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `render(part: int, out: str) -> None` — raises `RuntimeError` if OpenSCAD errors or writes no file.
  - `measure(stl: str) -> dict` with keys `zmin`, `zmax`, `height`, `dmax` (floats).
  - `bore(stl: str, zlo: float, zhi: float) -> tuple[float, float]` — `(min_dia, max_dia)` over vertices in that Z band.
  - `volume(stl: str) -> float` — cm³.
  - CLI: `python3 tools/verify_nosecone.py [part ...]` prints a PASS/FAIL table, exits 1 on any FAIL.

- [ ] **Step 1: Write the harness**

```python
#!/usr/bin/env python3
"""Render and measure PeregrineNoseCone parts.

A part that does not fit still renders cleanly, so every mating dimension
is measured from the STL rather than inferred from parameters.
"""
import math, os, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
SCAD = os.path.join(REPO, "PeregrineNoseCone.scad")


def render(part, out):
    env = dict(os.environ, OPENSCADPATH=REPO)
    r = subprocess.run(
        [OPENSCAD, "--export-format", "asciistl", "-o", out,
         "-D", "Render_Part=%d" % part, SCAD],
        capture_output=True, text=True, env=env)
    err = r.stdout + r.stderr
    # Do NOT test `"ERROR" in err.upper()` -- that matches the ERROR inside
    # NOERROR, and OpenSCAD's success line is "Status: NoError".
    # A missing include or undefined module only WARNS and exits 0, so the
    # geometry silently vanishes; both must be treated as failures.
    if (r.returncode != 0 or "ERROR:" in err.upper()
            or "Can't find include file" in err
            or "Ignoring unknown module" in err
            or not os.path.exists(out) or os.path.getsize(out) < 200):
        raise RuntimeError("render of part %d failed:\n%s" % (part, err[-2000:]))


def _tris(stl):
    vs = []
    with open(stl) as fh:
        for line in fh:
            s = line.lstrip()
            if s.startswith("vertex"):
                vs.append(tuple(map(float, s.split()[1:4])))
                if len(vs) == 3:
                    yield vs
                    vs = []


def measure(stl):
    zmin, zmax, dmax = 1e9, -1e9, 0.0
    for tri in _tris(stl):
        for x, y, z in tri:
            zmin = min(zmin, z); zmax = max(zmax, z)
            dmax = max(dmax, 2 * math.hypot(x, y))
    return {"zmin": zmin, "zmax": zmax, "height": zmax - zmin, "dmax": dmax}


def bore(stl, zlo, zhi):
    lo, hi = 1e9, 0.0
    for tri in _tris(stl):
        for x, y, z in tri:
            if zlo <= z <= zhi:
                d = 2 * math.hypot(x, y)
                lo = min(lo, d); hi = max(hi, d)
    if lo > hi:
        raise RuntimeError("no geometry in Z band %.2f-%.2f of %s" % (zlo, zhi, stl))
    return lo, hi


def volume(stl):
    v = 0.0
    for (x1, y1, z1), (x2, y2, z2), (x3, y3, z3) in _tris(stl):
        v += (x1 * (y2 * z3 - y3 * z2)
              - x2 * (y1 * z3 - y3 * z1)
              + x3 * (y1 * z2 - y2 * z1)) / 6.0
    return abs(v) / 1000.0


NAMES = {0: "test ring", 1: "shoulder", 2: "bottom slice",
         3: "middle slice", 4: "top slice", 5: "ring lower", 6: "ring upper"}


def checks(m):
    """Return list of (label, actual, expected, tolerance)."""
    c = []
    a = lambda p, k: m[p][k]
    if 2 in m:
        c += [("bottom zmin", a(2, "zmin"), 0.0, 0.1),
              ("bottom outer dia", a(2, "dmax"), 101.5, 0.3)]
    if 3 in m:
        c += [("middle zmin", a(3, "zmin"), 183.33, 0.2)]
    if 4 in m:
        c += [("APEX HEIGHT", a(4, "zmax"), 550.0, 0.15)]
    if 2 in m and 3 in m:
        c += [("joint 1 overlap", a(2, "zmax") - a(3, "zmin"), 7.0, 0.2)]
    if 3 in m and 4 in m:
        c += [("joint 2 overlap", a(3, "zmax") - a(4, "zmin"), 7.0, 0.2)]
    if 1 in m:
        c += [("shoulder height", a(1, "height"), 115.0, 0.2),
              ("shoulder body dia", a(1, "dmax"), 98.6, 0.2)]
    if 5 in m:
        c += [("ring lower dia", a(5, "dmax"), 82.0, 0.2)]
    if 6 in m:
        c += [("ring upper dia", a(6, "dmax"), 52.0, 0.2)]
    for p in m:
        c += [("part %d fits 250mm Z" % p, m[p]["height"], min(m[p]["height"], 250.0), 0.01)]
    return c


def main(argv):
    parts = [int(a) for a in argv[1:]] or [0, 1, 2, 3, 4, 5, 6]
    m, tmp = {}, tempfile.mkdtemp()
    for p in parts:
        out = os.path.join(tmp, "part%d.stl" % p)
        try:
            render(p, out)
        except RuntimeError as e:
            print("FAIL  render part %d (%s)\n%s" % (p, NAMES.get(p, "?"), e))
            return 1
        m[p] = measure(out)
        m[p]["vol"] = volume(out)
        print("  part %d %-14s h=%7.2f  dia=%7.2f  z=%7.2f..%7.2f  %5.0f g PETG"
              % (p, NAMES.get(p, "?"), m[p]["height"], m[p]["dmax"],
                 m[p]["zmin"], m[p]["zmax"], m[p]["vol"] * 1.27))
    print()
    bad = 0
    for label, actual, expected, tol in checks(m):
        ok = abs(actual - expected) <= tol
        bad += not ok
        print("%-4s %-26s %10.2f  expected %8.2f +/- %.2f"
              % ("PASS" if ok else "FAIL", label, actual, expected, tol))
    print("\n%d check(s) failed" % bad if bad else "\nall checks passed")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
```

- [ ] **Step 2: Run it against the current unmodified file to confirm it reports failure**

```bash
cd <worktree>
python3 tools/verify_nosecone.py 2
```

Expected: FAIL. The current file's `Render_Part=2` is the old two-piece top, ~300 mm tall with the wrong diameter. This proves the harness detects wrong geometry rather than rubber-stamping it.

- [ ] **Step 3: Commit**

```bash
git add tools/verify_nosecone.py
git commit -m "Add STL measurement harness for nosecone verification

Renders a Render_Part via the OpenSCAD CLI and measures the resulting
STL. A part that does not fit still renders Status: NoError, so mating
dimensions must be measured rather than inferred."
```

---

### Task 2: Ogive parameters and the three slices

**Files:**
- Modify: `PeregrineNoseCone.scad` (replace lines 15–110, the parameter block and render logic)

**Interfaces:**
- Consumes: `BluntOgiveNoseCone` from `NoseCone.scad`.
- Produces: `NC_Slice_Bottom()`, `NC_Slice_Middle()`, `NC_Slice_Top()`; the frozen parameter names listed above; `Render_Part` values 2, 3, 4.

- [ ] **Step 1: Replace the parameter block and add the slice modules**

Keep the existing file header comment (lines 1–13) and the `include<NoseCone.scad>` line. Replace everything from the first `// ====` banner to the end of the render logic with:

```openscad
// ============================================
// BODY TUBE — measure yours and adjust
// ============================================
Peregrine_Body_OD    = 101.5;   // outside diameter of body tube
Peregrine_Body_ID    = 99.0;    // inside diameter of body tube
Peregrine_Coupler_OD = 97.1;    // shell ID = Body_OD - 2*Wall_T

// ============================================
// NOSE CONE — 550mm exposed, 5.42:1 ogive
// ============================================
// Exposed height = NC_Base_L + NC_Length - X0 + NC_Tip_R.
// The +NC_Tip_R term matters: Tip_Z in BluntOgiveNoseCone is the tip
// SPHERE CENTRE, not the apex. NC_Length=574.55 gives exactly 550.
NC_Length  = 574.55;
NC_Base_L  = 15;
NC_Tip_R   = 8;
NC_Wall_T  = 2.2;
NC_nRivets = 0;   // shoulder is glued via its spigot, not pinned

// Slice planes. Cut_d is a DIAMETER; the module derives Z from it.
Cut1_d = 92.85;   // -> Z = 183.33
Cut2_d = 63.66;   // -> Z = 366.67
Cut1_Z = 183.33;  // clip plane for the middle slice

// ============================================
// RENDER SELECTION — change this value!
// ============================================
// 0 = Test ring (print first!)
// 1 = Shoulder + bulkhead + parachute anchor
// 2 = Bottom slice
// 3 = Middle slice
// 4 = Top slice (filled tip)
// 5 = Guide ring, lower
// 6 = Guide ring, upper
Render_Part = 0;

// ============================================
// PARTS
// ============================================
module NC_Slice_Bottom(){
    BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD,
        L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets,
        Tip_R=NC_Tip_R, Wall_T=NC_Wall_T,
        Cut_d=Cut1_d, LowerPortion=true);
} // NC_Slice_Bottom

module NC_Slice_Middle(){
    // Everything below cut 2 (with its gluing flange), clipped above cut 1.
    // The clean lower cut slides over the bottom slice's flange.
    intersection(){
        BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD,
            L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets,
            Tip_R=NC_Tip_R, Wall_T=NC_Wall_T,
            Cut_d=Cut2_d, LowerPortion=true);

        translate([0,0,Cut1_Z])
            cylinder(d=Peregrine_Body_OD+2, h=NC_Length, $fn=$preview? 90:360);
    } // intersection
} // NC_Slice_Middle

module NC_Slice_Top(){
    BluntOgiveNoseCone(ID=Peregrine_Coupler_OD, OD=Peregrine_Body_OD,
        L=NC_Length, Base_L=NC_Base_L, nRivets=NC_nRivets,
        Tip_R=NC_Tip_R, Wall_T=NC_Wall_T,
        Cut_d=Cut2_d, LowerPortion=false, FillTip=true);
} // NC_Slice_Top

// ============================================
// RENDERING LOGIC — don't edit below
// ============================================
if (Render_Part == 2) NC_Slice_Bottom();
if (Render_Part == 3) NC_Slice_Middle();
if (Render_Part == 4) NC_Slice_Top();
```

Leave the existing `TestRing()` module in place for now — Task 5 updates it. `Render_Part = 0` will render the old ring until then; that is expected.

- [ ] **Step 2: Run the slice checks**

```bash
python3 tools/verify_nosecone.py 2 3 4
```

Expected: PASS on all of — bottom zmin 0.0, bottom outer dia 101.5, middle zmin 183.33, **APEX HEIGHT 550.0**, joint 1 overlap 7.0, joint 2 overlap 7.0, and all three heights under 250.

If APEX HEIGHT reports 558, `NC_Tip_R` was omitted from the height solve — `NC_Length` must be 574.55, not 583.3.

- [ ] **Step 3: Commit**

```bash
git add PeregrineNoseCone.scad
git commit -m "Rewrite Peregrine nosecone as 550mm three-slice ogive

5.42:1 blunted ogive standing 550mm proud of the body tube, split into
three ~190mm slices joined by the gluing flange BluntOgiveNoseCone
already generates on its lower portion. NoseCone.scad is untouched; the
middle slice is produced by clipping a second lower-portion call."
```

---

### Task 3: Stepped printed shoulder

**Files:**
- Modify: `PeregrineNoseCone.scad` (add `NC_Shoulder()`, extend the render logic)

**Interfaces:**
- Consumes: `RoundRect`, `Overlap` from `NoseCone.scad`; `NC_Wall_T` from Task 2.
- Produces: `NC_Shoulder()`; `Render_Part` value 1.

A plain cylinder will not do. A shoulder that fits the 99.0 mm tube is ~98.6 mm OD, which is larger than the 97.1 mm bore it must enter, so it is stepped: 98.6 for the 100 mm inside the tube, 96.7 for a 15 mm spigot into the nosecone.

- [ ] **Step 1: Add the shoulder parameters after the `Cut1_Z` line**

```openscad
// ============================================
// SHOULDER — stepped, printed, all-in-one
// ============================================
// Body enters the tube (99.0 ID), spigot enters the shell (97.1 ID).
// Both clearances are 0.4mm diametral.
Shoulder_L         = 100;    // length inside the body tube
Shoulder_OD        = 98.6;
Shoulder_Spigot_L  = 15;     // length inside the nosecone skirt
Shoulder_Spigot_OD = 96.7;
Shoulder_Bulk_T    = 4;      // bulkhead thickness, carries the anchor
```

- [ ] **Step 2: Add the module before the rendering logic**

```openscad
module NC_Shoulder(){
    // Printed replacement for a bought coupler. The bulkhead is the
    // parachute anchor: shock passes straight into the body tube, so no
    // glue joint is ever loaded in tension.
    difference(){
        union(){
            cylinder(d=Shoulder_OD, h=Shoulder_L, $fn=$preview? 90:360);

            translate([0,0,Shoulder_L])
                cylinder(d=Shoulder_Spigot_OD, h=Shoulder_Spigot_L,
                         $fn=$preview? 90:360);
        } // union

        // Hollow the body, leaving the bulkhead at the bottom
        translate([0,0,Shoulder_Bulk_T])
            cylinder(d=Shoulder_OD-NC_Wall_T*2,
                     h=Shoulder_L-Shoulder_Bulk_T+Overlap,
                     $fn=$preview? 90:360);

        // Hollow the spigot separately so its wall stays NC_Wall_T
        translate([0,0,Shoulder_L])
            cylinder(d=Shoulder_Spigot_OD-NC_Wall_T*2,
                     h=Shoulder_Spigot_L+Overlap, $fn=$preview? 90:360);

        // Strap slots — printed anchor, no metal hardware
        translate([0, Shoulder_OD/2-NC_Wall_T-4, -Overlap])
            RoundRect(X=16, Y=4, Z=Shoulder_Bulk_T+1, R=1.5);
        translate([0, -Shoulder_OD/2+NC_Wall_T+4, -Overlap])
            RoundRect(X=16, Y=4, Z=Shoulder_Bulk_T+1, R=1.5);
    } // difference
} // NC_Shoulder
```

Add to the rendering logic:

```openscad
if (Render_Part == 1) NC_Shoulder();
```

- [ ] **Step 3: Verify dimensions and the spigot fit**

```bash
python3 tools/verify_nosecone.py 1
```

Expected: PASS on shoulder height 115.0 and shoulder body dia 98.6.

Then confirm the step and the spigot clearance by hand:

```bash
python3 - <<'PY'
import sys, tempfile, os
sys.path.insert(0, "tools")
from verify_nosecone import render, bore
out = os.path.join(tempfile.mkdtemp(), "s.stl")
render(1, out)
# NOTE: bands must CONTAIN mesh vertices. A plain cylinder() has vertices only
# at its ends -- this part's are at Z = 0, 4, 100, 100.05, 115 -- so a band like
# 50..60 samples empty space and bore() raises "no geometry in Z band".
print("body   Z 0-60    dia %.2f .. %.2f  (expect outer 98.60)" % bore(out, 0, 60))
print("spigot Z 105-115 dia %.2f .. %.2f  (expect outer 96.70)" % bore(out, 105, 115))
print("spigot clearance in 97.1 bore: %.2f mm diametral" % (97.1 - bore(out,105,115)[1]))
PY
```

Expected: body outer 98.60, spigot outer 96.70, clearance 0.40.

- [ ] **Step 4: Commit**

```bash
git add PeregrineNoseCone.scad
git commit -m "Add stepped printed shoulder with bulkhead anchor

98.6mm body into the tube, 96.7mm spigot into the shell bore, both with
0.4mm diametral clearance. Bulkhead carries printed strap slots so the
parachute anchors at the base and no glue joint sees deployment shock in
tension."
```

---

### Task 4: Guide rings

**Files:**
- Modify: `PeregrineNoseCone.scad` (add `NC_GuideRing()`, extend the render logic)

**Interfaces:**
- Consumes: `Overlap` from `NoseCone.scad`.
- Produces: `NC_GuideRing(OD)`; `Render_Part` values 5 and 6.

Ring OD is set by the **flange bore**, not the shell bore. The gluing flange occupies the joint plane and tapers over its 7 mm height: measured clear bore is 82.47 at joint 1 and 52.41 at joint 2. A ring sized to the shell would not pass its own flange.

- [ ] **Step 1: Add ring parameters after the shoulder parameters**

```openscad
// ============================================
// GUIDE RINGS — keep the strap off the shell
// ============================================
// OD is the measured flange bore less 0.4-0.5mm diametral clearance.
// Flange bores: 82.47 at joint 1, 52.41 at joint 2.
Ring_T     = 6;
Ring1_OD   = 82.0;
Ring2_OD   = 52.0;
Ring_Eye_d = 12;   // strap pass-through
Ring_Wall  = 4;
```

- [ ] **Step 2: Add the module before the rendering logic**

```openscad
module NC_GuideRing(OD=Ring1_OD){
    // Annulus + 3 spokes + central eyelet. A solid disc would add ~39g
    // at joint 1 and block the cone interior.
    intersection(){
      difference(){
        union(){
            difference(){
                cylinder(d=OD, h=Ring_T, $fn=$preview? 90:360);
                translate([0,0,-Overlap])
                    cylinder(d=OD-Ring_Wall*2, h=Ring_T+Overlap*2,
                             $fn=$preview? 90:360);
            } // difference

            difference(){
                cylinder(d=Ring_Eye_d+Ring_Wall*2, h=Ring_T, $fn=$preview? 90:180);
                translate([0,0,-Overlap])
                    cylinder(d=Ring_Eye_d, h=Ring_T+Overlap*2, $fn=$preview? 90:180);
            } // difference

            for (j=[0:2]) rotate([0,0,120*j])
                translate([0,-Ring_Wall/2,0]) cube([OD/2, Ring_Wall, Ring_T]);
        } // union

        // The spoke cubes start at x=0, the ring's AXIS, so unioning them
        // after the eyelet's own difference() fills the strap bore with a
        // solid hub. The bore must be cut LAST or the eyelet is webbed shut
        // -- and no outer-diameter check can see that.
        translate([0,0,-Overlap])
            cylinder(d=Ring_Eye_d, h=Ring_T+Overlap*2, $fn=$preview? 90:180);
      } // difference

        // Clamp to OD. Each spoke cube is Ring_Wall wide and centred on
        // y=0, so its far CORNERS reach sqrt((OD/2)^2 + (Ring_Wall/2)^2),
        // which is larger than OD/2. Without this clamp the ring measures
        // 82.10 / 52.15 instead of 82.0 / 52.0 and joint 2's clearance
        // drops to 0.26mm, under the 0.3mm floor.
        translate([0,0,-Overlap])
            cylinder(d=OD, h=Ring_T+Overlap*2, $fn=$preview? 90:360);
    } // intersection
} // NC_GuideRing
```

Add to the rendering logic:

```openscad
if (Render_Part == 5) NC_GuideRing(OD=Ring1_OD);
if (Render_Part == 6) NC_GuideRing(OD=Ring2_OD);
```

- [ ] **Step 3: Verify ring diameters and clearance against the real flange bores**

```bash
python3 tools/verify_nosecone.py 5 6
```

Expected: PASS on ring lower dia 82.0 and ring upper dia 52.0.

Then check each ring against the flange it must enter:

```bash
python3 - <<'PY'
import sys, tempfile, os
sys.path.insert(0, "tools")
from verify_nosecone import render, bore, measure
d = tempfile.mkdtemp()
for part, zlo, zhi, ring in ((2, 189.0, 190.4, 5), (3, 372.0, 373.7, 6)):
    slice_stl = os.path.join(d, "p%d.stl" % part)
    ring_stl  = os.path.join(d, "r%d.stl" % ring)
    render(part, slice_stl); render(ring, ring_stl)
    flange_bore = bore(slice_stl, zlo, zhi)[0]
    ring_od = measure(ring_stl)["dmax"]
    print("joint via part %d: flange bore %.2f, ring OD %.2f, clearance %.2f mm"
          % (part, flange_bore, ring_od, flange_bore - ring_od))
    assert 0.3 <= flange_bore - ring_od <= 0.6, "ring does not fit"
print("both rings fit")
PY
```

Expected: joint 1 clearance ≈ 0.47, joint 2 ≈ 0.41, then `both rings fit`.

- [ ] **Step 4: Commit**

```bash
git add PeregrineNoseCone.scad
git commit -m "Add guide rings sized to measured flange bores

Ring OD is set by the gluing flange bore (82.47 / 52.41), not the shell
inner diameter -- the flange occupies the joint plane and tapers over its
7mm height, so a shell-sized ring would not pass its own flange."
```

---

### Task 5: Test ring, print notes, and full acceptance sweep

**Files:**
- Modify: `PeregrineNoseCone.scad` (update `TestRing()`, replace the print-notes block)

**Interfaces:**
- Consumes: everything above.
- Produces: `Render_Part` value 0 matching the new bore.

- [ ] **Step 1: Update `TestRing()` to the new bore**

Replace the existing `TestRing()` module with:

```openscad
module TestRing(){
    // Print this FIRST. Verifies both fits before committing to 190mm parts.
    // OD must sit flush on the body tube (no step).
    // Bore must accept the shoulder spigot (96.7) with a light push fit.
    difference(){
        cylinder(d=Peregrine_Body_OD, h=15, $fn=90);
        translate([0,0,-Overlap])
            cylinder(d=Peregrine_Coupler_OD, h=15+Overlap*2, $fn=90);
    } // difference
} // TestRing
```

Confirm the rendering logic contains `if (Render_Part == 0) TestRing();`.

- [ ] **Step 2: Replace the print-notes block at the end of the file**

```openscad
// ============================================
// PRINT NOTES
// ============================================
//
// Parts (all 3D printed, superglued together):
//   0  Test ring          15mm    -- print first, verify fit
//   1  Shoulder          115mm
//   2  Bottom slice      190mm
//   3  Middle slice      190mm
//   4  Top slice         183mm
//   5  Guide ring lower    6mm
//   6  Guide ring upper    6mm
//
// Assembly, bottom to top:
//   shoulder spigot -> bottom slice bore, glue
//   bottom slice flange -> middle slice, glue (drop ring 5 in first)
//   middle slice flange -> top slice, glue (drop ring 6 in first)
//   thread the parachute strap through the bulkhead slots and both rings
//
// Print settings: 3 perimeters, 15% infill, PETG or ASA.
// Total ~508g in PETG.
//
// ALWAYS export with F6 (full render). F5 preview applies a quarter
// cutaway and will silently export a broken part.
//
// ***********************************
```

- [ ] **Step 3: Run the full acceptance sweep**

```bash
python3 tools/verify_nosecone.py
```

Expected: every part renders, every check PASSes, `all checks passed`, exit 0.

- [ ] **Step 4: Confirm `NoseCone.scad` was never touched**

```bash
git diff main --stat -- NoseCone.scad
```

Expected: no output. If anything appears, revert it — the global constraint was violated.

- [ ] **Step 5: Commit and open the PR**

```bash
git add PeregrineNoseCone.scad
git commit -m "Update test ring to new bore and rewrite print notes

Test ring now checks the 97.1 bore against the shoulder spigot. Print
notes cover all six printed parts and the assembly order."
git push -u origin feature/nosecone-550mm-sliced
```

Then open a PR against `main` describing the six parts, the verified apex height, and the fact that `NoseCone.scad` is unmodified. Stop there — do not merge.

---

## Self-Review

**Spec coverage:**

| Spec section | Task |
|---|---|
| Geometry, height formula, slice planes | 2 |
| Slicing approach, library untouched | 2, 5 (step 4 asserts it) |
| Stepped shoulder | 3 |
| Parachute anchor — bulkhead slots | 3 |
| Parachute anchor — guide rings | 4 |
| Render selection map 0–6 | 2, 3, 4, 5 |
| Verification criteria | 1, then every task's test step |
| Print notes | 5 |
| `nRivets = 0` | 2 |

No spec requirement is unassigned.

**Placeholder scan:** none. Every code step contains complete, runnable content.

**Type consistency:** `render`/`measure`/`bore`/`volume` signatures in Task 1 match every later call site. Parameter names (`NC_Length`, `Cut1_d`, `Cut1_Z`, `Shoulder_Spigot_OD`, `Ring1_OD`, `Ring_Wall`) are identical across Tasks 2–5. `NC_GuideRing(OD)` is called with the named argument `OD=` in both places.

**Known risk carried forward:** the harness asserts geometry, not printability. Wall thickness on the physical print must still be checked by eye — per `.serena/memories/lessons-learned/nosecone-ogive-hollow-bug.md`, a hollowing defect was once *hidden* by a 100 mm tube's diameter, so a clean render is not proof of a correct wall.
