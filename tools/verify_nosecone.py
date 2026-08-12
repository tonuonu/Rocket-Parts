#!/usr/bin/env python3
"""Render and measure PeregrineNoseCone parts.

A part that does not fit still renders cleanly, so every mating dimension
is measured from the STL rather than inferred from parameters.
"""
import math, os, re, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
SCAD = os.path.join(REPO, "PeregrineNoseCone.scad")


def render(part, out):
    """Render `part` to `out`. Returns the OpenSCAD-reported genus (int),
    or None if the render statistics did not contain a Genus line."""
    env = dict(os.environ, OPENSCADPATH=REPO)
    r = subprocess.run(
        [OPENSCAD, "--export-format", "asciistl", "-o", out, "-D", "Render_Part=%d" % part, SCAD],
        capture_output=True, text=True, env=env)
    err = r.stdout + r.stderr
    if (r.returncode != 0 or "ERROR:" in err.upper()
            or "Can't find include file" in err
            or "Ignoring unknown module" in err
            or not os.path.exists(out) or os.path.getsize(out) < 200):
        raise RuntimeError("render of part %d failed:\n%s" % (part, err[-2000:]))
    g = re.search(r"Genus:\s*(-?\d+)", err)
    return int(g.group(1)) if g else None


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

# Expected genus per part (topological invariant, immune to the
# "bit-identical bounding box, wrong interior" failure mode: a solid
# is genus 0, each through-hole/handle adds 1). Ring genus 4 = 3 spoke
# gaps + 1 eyelet; a webbed eyelet collapses two of those gaps into
# the eyelet cavity and reads 6 instead.
GENUS = {0: 1, 1: 2, 2: 1, 3: 1, 4: 0, 5: 4, 6: 4}

# Z bands (in each part's own exported frame) used to measure real mating
# surfaces instead of trusting the design constants they are supposed to
# match. Chosen to sit within a single wall/flange span so bore() sees a
# clean, near-constant diameter rather than a taper.
FLANGE_TOP_BAND = {2: (189.0, 190.4), 3: (372.0, 373.7)}  # ring seats here
SHOULDER_SPIGOT_BAND = (105.0, 115.0)   # part 1: spigot OD
BOTTOM_SLICE_BASE_BAND = (0.0, 5.0)     # part 2: coupler bore at the base


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

    # --- interior checks: bounding box / OD alone cannot see these ---

    # 1. Genus per part. Catches an interior defect (e.g. a webbed
    # eyelet) that leaves every zmin/zmax/height/dmax check untouched.
    for p in m:
        if "genus" in m[p] and p in GENUS:
            c += [("part %d genus" % p, m[p]["genus"], GENUS[p], 0)]

    # 2. Ring-in-flange clearance, MEASURED bore vs MEASURED ring OD
    # (never against the hardcoded 82.0/52.0 design constants, which is
    # exactly what let an interference fit pass the old gate).
    if 2 in m and 5 in m:
        zlo, zhi = FLANGE_TOP_BAND[2]
        flange_bore, _ = bore(a(2, "stl"), zlo, zhi)
        c += [("ring5-in-flange clearance", flange_bore - a(5, "dmax"), 0.45, 0.15)]
    if 3 in m and 6 in m:
        zlo, zhi = FLANGE_TOP_BAND[3]
        flange_bore, _ = bore(a(3, "stl"), zlo, zhi)
        c += [("ring6-in-flange clearance", flange_bore - a(6, "dmax"), 0.45, 0.15)]

    # 3. Shoulder spigot: its own OD, and its measured clearance in the
    # bottom slice's actual coupler bore (not the Peregrine_Coupler_OD
    # constant it is only supposed to match).
    if 1 in m:
        _, spigot_od = bore(a(1, "stl"), *SHOULDER_SPIGOT_BAND)
        c += [("shoulder spigot dia", spigot_od, 96.7, 0.1)]
        if 2 in m:
            bottom_bore, _ = bore(a(2, "stl"), *BOTTOM_SLICE_BASE_BAND)
            c += [("spigot-in-bottom-bore clearance", bottom_bore - spigot_od, 0.4, 0.1)]
    return c


def main(argv):
    parts = [int(a) for a in argv[1:]] or [0, 1, 2, 3, 4, 5, 6]
    m, tmp = {}, tempfile.mkdtemp()
    for p in parts:
        out = os.path.join(tmp, "part%d.stl" % p)
        try:
            genus = render(p, out)
        except RuntimeError as e:
            print("FAIL  render part %d (%s)\n%s" % (p, NAMES.get(p, "?"), e))
            return 1
        m[p] = measure(out)
        m[p]["vol"] = volume(out)
        m[p]["stl"] = out
        if genus is not None:
            m[p]["genus"] = genus
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
