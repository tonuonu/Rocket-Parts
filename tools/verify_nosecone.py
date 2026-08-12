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
        [OPENSCAD, "-o", out, "-D", "Render_Part=%d" % part, SCAD],
        capture_output=True, text=True, env=env)
    err = r.stdout + r.stderr
    if "ERROR" in err.upper() or not os.path.exists(out) or os.path.getsize(out) < 200:
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
