#!/usr/bin/env python3
"""Shared helpers for the Rocket-Parts verify_*.py scripts.

Render an OpenSCAD part to ASCII STL, then measure/bore/volume the actual
mesh -- a part that does not fit still renders cleanly, so every mating
dimension is measured from the STL rather than inferred from the parameter
that was supposed to produce it.

Consolidated 2026-08-13 out of verify_nosecone.py, verify_camnose.py and
verify_rocket60.py, which had each accumulated their own copy of these five
functions. The copies differed only cosmetically (docstrings, list vs
tuple, sentinel style) with one behavioural exception: verify_camnose.py's
render() carried a 900s subprocess timeout the other two lacked. That
timeout is adopted here for all callers -- see the Task 1 fix report for
the reasoning.
"""
import functools, math, os, re, subprocess

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"


def render(scad, part, out):
    """Render `part` of `scad` to `out`. Returns the OpenSCAD-reported
    genus (int), or None if the render statistics did not contain a Genus
    line."""
    env = dict(os.environ, OPENSCADPATH=REPO)
    r = subprocess.run(
        [OPENSCAD, "--export-format", "asciistl", "-o", out,
         "-D", "Render_Part=%d" % part, scad],
        capture_output=True, text=True, env=env, timeout=900)
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


@functools.lru_cache(maxsize=None)
def _bore_cached(stl, st_mtime_ns, st_size, zlo, zhi):
    """Actual bore() body, memoised on (path, mtime, size, band) -- see
    bore() below for why mtime/size are part of the key, not just path."""
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


def bore(stl, zlo, zhi):
    """Return (min_dia, max_dia) of material within the Z band [zlo, zhi].

    min_dia is the smallest radius seen doubled, i.e. the bore; max_dia the
    largest, i.e. the OD. Vertices outside the band are ignored.

    Memoised (in _bore_cached) on (path, mtime_ns, size, zlo, zhi): callers
    routinely re-check the same band on the same part (verify_rocket60.py
    calls bore() on the same (stl, band) pair from several independent
    checks, e.g. per bulkhead and at lines scattered through checks()), and
    each call re-reads and re-parses the ENTIRE ascii STL from scratch --
    part 9 alone is ~114 cm^3 of triangles.

    Keyed on path ALONE, this was unsafe (defect 3d): the docstring's "stl
    paths are never reused for different content within a run" is a
    property of today's CALLERS, not of this function, and nothing enforces
    it -- re-rendering to a path already measured (e.g. looping Motor_Class
    over the same tempfile) would silently return the FIRST render's stale
    geometry for every subsequent call on that path, wrong and undetected.
    Including the file's own mtime/size in the key makes a re-render (which
    always changes at least one of them) a cache miss instead."""
    st = os.stat(stl)
    return _bore_cached(stl, st.st_mtime_ns, st.st_size, zlo, zhi)


def volume(stl):
    """Signed mesh volume in cm^3 (divergence theorem over the triangles)."""
    v = 0.0
    for (a, b, c) in _tris(stl):
        v += (a[0] * (b[1] * c[2] - b[2] * c[1])
              - a[1] * (b[0] * c[2] - b[2] * c[0])
              + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
    return abs(v) / 1000.0
