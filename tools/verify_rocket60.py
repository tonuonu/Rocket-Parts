#!/usr/bin/env python3
"""Render and measure Rocket 60 parts.

A part that does not fit still renders cleanly, so every mating dimension is
measured from the STL rather than inferred from the parameter that was
supposed to produce it.
"""
import math, os, re, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
SCAD = os.path.join(REPO, "Rocket60.scad")

NAMES = {0: "test ring", 1: "neck", 2: "e-bay tube", 3: "chute bay tube",
         4: "ebay fwd bulkhead", 5: "ebay aft bulkhead", 6: "vega sled",
         7: "access door", 8: "bayonet ring", 9: "fin can", 10: "fin",
         11: "motor retainer", 12: "motor spacer"}

# Expected genus per part (topological invariant, immune to the
# "bit-identical bounding box, wrong interior" failure mode: a solid is
# genus 0, each through-hole/handle adds 1).
#   part 0: open-centre ring (1) + 3 bolt holes (3) = 4
GENUS = {0: 4}

MAX_Z = 250.0   # Bambu P1S usable Z, repo convention


def render(part, out):
    """Render `part` to `out`. Returns the OpenSCAD-reported genus (int), or
    None if the render statistics did not contain a Genus line."""
    env = dict(os.environ, OPENSCADPATH=REPO)
    r = subprocess.run(
        [OPENSCAD, "--export-format", "asciistl", "-o", out,
         "-D", "Render_Part=%d" % part, SCAD],
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
    """Yield (v0, v1, v2) vertex triples from an ASCII STL."""
    vs = []
    with open(stl) as fh:
        for line in fh:
            s = line.lstrip()
            if s.startswith("vertex "):
                vs.append(tuple(float(x) for x in s.split()[1:4]))
                if len(vs) == 3:
                    yield tuple(vs)
                    vs = []


def measure(stl, genus=None):
    """Bounding box, height and max diameter about the Z axis."""
    xs = ys = zs = None
    dmax = 0.0
    for tri in _tris(stl):
        for (x, y, z) in tri:
            xs = (x, x) if xs is None else (min(xs[0], x), max(xs[1], x))
            ys = (y, y) if ys is None else (min(ys[0], y), max(ys[1], y))
            zs = (z, z) if zs is None else (min(zs[0], z), max(zs[1], z))
            dmax = max(dmax, 2.0 * math.hypot(x, y))
    return {"stl": stl, "genus": genus, "dmax": dmax,
            "xmin": xs[0], "xmax": xs[1], "ymin": ys[0], "ymax": ys[1],
            "zmin": zs[0], "zmax": zs[1], "height": zs[1] - zs[0]}


def bore(stl, zlo, zhi):
    """Return (min_dia, max_dia) of material within the Z band [zlo, zhi].

    min_dia is the smallest radius seen doubled, i.e. the bore; max_dia the
    largest, i.e. the OD. Vertices outside the band are ignored."""
    rmin, rmax = None, 0.0
    for tri in _tris(stl):
        for (x, y, z) in tri:
            if zlo <= z <= zhi:
                r = math.hypot(x, y)
                rmin = r if rmin is None else min(rmin, r)
                rmax = max(rmax, r)
    if rmin is None:
        raise RuntimeError("no geometry in Z band %.2f..%.2f of %s" % (zlo, zhi, stl))
    return 2.0 * rmin, 2.0 * rmax


def volume(stl):
    """Signed mesh volume in cm^3 (divergence theorem over the triangles)."""
    v = 0.0
    for (a, b, c) in _tris(stl):
        v += (a[0] * (b[1] * c[2] - b[2] * c[1])
              - a[1] * (b[0] * c[2] - b[2] * c[0])
              + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
    return abs(v) / 1000.0


# --- Z bands used to measure real mating surfaces -------------------------
# OpenSCAD's STL export puts vertices only at edge loops (Z-transitions),
# never mid-span on a plain cylinder wall, so a band must straddle the edge
# loop of the span it measures or bore() sees nothing there at all. Each
# band below reaches one true boundary of its span (z=0 base / z=10 top)
# while stopping short of the *other* span's boundary, so the reading isn't
# contaminated by a neighbouring diameter. Same convention as
# SHOULDER_SPIGOT_BAND/BOTTOM_SLICE_BASE_BAND in verify_nosecone.py, which
# likewise reach the spigot top (Z=115) and the base (Z=0) respectively.
TESTRING_FLANGE_BAND = (-0.01, 3.5)  # part 0: OD against the nosecone base
TESTRING_SPIGOT_BAND = (5.5, 10.01)  # part 0: coupler OD against a tube bore


def checks(m):
    """Return list of (label, actual, expected, tolerance)."""
    c = []
    a = lambda p, k: m[p][k]

    if 0 in m:
        _, flange_od = bore(a(0, "stl"), *TESTRING_FLANGE_BAND)
        _, spigot_od = bore(a(0, "stl"), *TESTRING_SPIGOT_BAND)
        c += [("test ring flange OD vs nosecone base", flange_od, 59.98, 0.15),
              ("test ring coupler OD", spigot_od, 56.40, 0.15),
              ("test ring height", a(0, "height"), 10.0, 0.1),
              ("test ring zmin", a(0, "zmin"), 0.0, 0.05)]

    # Build volume, every part.
    for p in m:
        c += [("part %d fits %.0fmm Z" % (p, MAX_Z),
               m[p]["height"], min(m[p]["height"], MAX_Z), 0.01)]

    # Topology, every part with a recorded expectation.
    for p in m:
        if m[p].get("genus") is not None and p in GENUS:
            c += [("part %d genus" % p, m[p]["genus"], GENUS[p], 0)]

    return c


def main(argv):
    parts = [int(x) for x in argv[1:]] or sorted(NAMES)
    m = {}
    tmp = tempfile.mkdtemp(prefix="r60-")
    for p in parts:
        out = os.path.join(tmp, "part%d.stl" % p)
        g = render(p, out)
        m[p] = measure(out, g)
        print("rendered %-2d %-20s  %.2f x %.2f x %.2f mm  %.1f cm3"
              % (p, NAMES.get(p, "?"), m[p]["xmax"] - m[p]["xmin"],
                 m[p]["ymax"] - m[p]["ymin"], m[p]["height"], volume(out)))
    bad = 0
    print()
    for (label, actual, expected, tol) in checks(m):
        ok = abs(actual - expected) <= tol
        bad += 0 if ok else 1
        print("%-4s %-42s %10.3f  want %.3f +/- %.3f"
              % ("OK" if ok else "FAIL", label, actual, expected, tol))
    print("\n%d check(s) failed" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
