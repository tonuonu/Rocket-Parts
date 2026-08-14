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


@functools.lru_cache(maxsize=None)
def _tris_cached(stl, st_mtime_ns, st_size):
    """Actual STL parse, memoised on (path, mtime, size) -- see tris()
    below. Materialised as a tuple (not left as a generator) so the same
    cached result can be iterated more than once, by different callers,
    without re-reading the file."""
    vs, out = [], []
    with open(stl) as fh:
        for line in fh:
            s = line.lstrip()
            if s.startswith("vertex "):
                vs.append(tuple(float(x) for x in s.split()[1:4]))
                if len(vs) == 3:
                    out.append(tuple(vs))
                    vs = []
    return tuple(out)


def tris(stl):
    """(v0, v1, v2) vertex triples from an ASCII STL.

    Memoised on (path, mtime_ns, size) (defect 12): bore() already had its
    own private cache for exactly this reason (re-parsing the whole file
    per call is real cost -- part 9 alone is ~114 cm^3 of triangles), but
    every OTHER scanner in verify_rocket60.py (hole_azimuth_at_r,
    hole_max_reach, pin_hole_diameter, the fin-can slot scanners,
    xy_extent_in_window, rail_facing_gap) and volume() below all called
    the plain per-call parse directly and re-read/re-parsed the file from
    scratch on every single call, even when checking the SAME rendered
    part repeatedly -- the common case, since verify_rocket60.py's
    checks() calls several of these on the same a(p, "stl") path back to
    back. This is also the shared cache those scanners were reaching past
    the module boundary for a private _tris() to approximate (defect 14)
    -- this is now the one public entry point every caller (including
    scad_verify's own measure()/volume()/bore() below) uses instead.

    Keyed on mtime/size, not path alone, for the same reason bore()'s own
    cache is (defect 3d): a path that gets re-rendered to (temp files are
    reused across Motor_Class variants, for instance) must be a cache
    miss, not a silent return of the first render's stale geometry."""
    st = os.stat(stl)
    return _tris_cached(stl, st.st_mtime_ns, st.st_size)


def measure(stl, genus=None):
    """Bounding box, height and max diameter about the Z axis."""
    xs = ys = zs = None
    dmax = 0.0
    for tri in tris(stl):
        for (x, y, z) in tri:
            xs = (x, x) if xs is None else (min(xs[0], x), max(xs[1], x))
            ys = (y, y) if ys is None else (min(ys[0], y), max(ys[1], y))
            zs = (z, z) if zs is None else (min(zs[0], z), max(zs[1], z))
            dmax = max(dmax, 2.0 * math.hypot(x, y))
    if xs is None:
        # Zero-triangle mesh (defect 13) -- render() already guards
        # against a too-small/missing STL file, but an ASCII STL that
        # parses as syntactically valid with zero "vertex " lines (e.g. a
        # degenerate empty solid CGAL still happily wrote out) used to
        # reach here and raise TypeError on zs[1]-zs[0] against None,
        # crashing the WHOLE verify run instead of failing the one check
        # that measured this part. nan compares false against every
        # tolerance, same convention as a missing genus (see the genus
        # checks in verify_nosecone.py/verify_rocket60.py/
        # verify_camnose.py) -- a loud FAIL instead of a crash or a
        # silently wrong number.
        nan = float("nan")
        return {"stl": stl, "genus": genus, "dmax": nan,
                "xmin": nan, "xmax": nan, "ymin": nan, "ymax": nan,
                "zmin": nan, "zmax": nan, "height": nan}
    return {"stl": stl, "genus": genus, "dmax": dmax,
            "xmin": xs[0], "xmax": xs[1], "ymin": ys[0], "ymax": ys[1],
            "zmin": zs[0], "zmax": zs[1], "height": zs[1] - zs[0]}


@functools.lru_cache(maxsize=None)
def _bore_cached(stl, st_mtime_ns, st_size, zlo, zhi):
    """Actual bore() body, memoised on (path, mtime, size, band) -- see
    bore() below for why mtime/size are part of the key, not just path."""
    rmin, rmax = None, 0.0
    for tri in tris(stl):
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
    checks, e.g. per bulkhead and at lines scattered through checks()).
    tris() below is itself cached now (defect 12), so a repeat call no
    longer re-reads the file from disk -- but re-scanning even an
    in-memory tuple of every triangle (part 9 alone is ~114 cm^3 of them)
    for the same exact band is still real, avoidable work this layer
    skips.

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
    """Signed mesh volume in cm^3 (divergence theorem over the triangles).

    Uses the shared tris() cache (defect 12) -- this used to re-parse the
    whole file on every call, same as every scanner in verify_rocket60.py
    did before that fix."""
    v = 0.0
    for (a, b, c) in tris(stl):
        v += (a[0] * (b[1] * c[2] - b[2] * c[1])
              - a[1] * (b[0] * c[2] - b[2] * c[0])
              + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
    return abs(v) / 1000.0
