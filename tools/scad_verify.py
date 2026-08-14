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


def render(scad, part, out, var="Render_Part", return_log=False):
    """Render `part` of `scad` to `out`. Returns the OpenSCAD-reported
    genus (int), or None if the render statistics did not contain a Genus
    line.

    `var` names the `-D <var>=<part>` selector used to pick which
    part/class gets rendered -- defaults to "Render_Part"
    (Rocket60.scad/PeregrineNoseCone.scad/PeregrineCamNose.scad's shared
    convention), overridable per-call for a .scad file with its own
    dispatch variable (e.g. MotorDummy29.scad's `Motor_Class`,
    verify_motordummy29.py's `render(SCAD, p, out, var="Motor_Class")`).

    `return_log`, when True, returns `(genus, err)` instead of just
    `genus` -- `err` is the raw stdout+stderr OpenSCAD produced, for a
    caller that needs to scrape its own echo() lines out of the same
    render (verify_motordummy29.py cross-checks MotorDummy29.scad's
    echoed ballast masses this way) without paying for a second,
    identical render just to capture output this function already has in
    hand. Defaults False so every existing single-value caller
    (verify_rocket60.py, verify_nosecone.py, verify_camnose.py) is
    unaffected."""
    env = dict(os.environ, OPENSCADPATH=REPO)
    r = subprocess.run(
        [OPENSCAD, "--export-format", "asciistl", "-o", out,
         "-D", "%s=%d" % (var, part), scad],
        capture_output=True, text=True, env=env, timeout=900)
    err = r.stdout + r.stderr
    if (r.returncode != 0 or "ERROR:" in err.upper()
            or "Can't find include file" in err
            or "Ignoring unknown module" in err
            or not os.path.exists(out) or os.path.getsize(out) < 200):
        raise RuntimeError("render of part %d failed:\n%s" % (part, err[-2000:]))
    g = re.search(r"Genus:\s*(-?\d+)", err)
    genus = int(g.group(1)) if g else None
    return (genus, err) if return_log else genus


# Bounded (4th review, should-fix 13): maxsize=None retained every parsed
# mesh for the process lifetime -- unbounded growth over a run that renders
# 15 parts x several checkers x (2nd/3rd/4th review re-renders). The actual
# benefit this cache exists for is the 3-4 back-to-back calls checks() (or
# an assembly-probe driver) makes on the SAME just-rendered path before
# moving to the next part/pair -- a handful of live entries covers that;
# nothing needs a stale part's mesh once the run has moved on to the next
# one. 8 covers the widest realistic overlap (a pair render plus the 2-3
# per-part meshes referenced alongside it) with headroom to spare.
@functools.lru_cache(maxsize=8)
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


def components(stl):
    """Number of connected components in the mesh, by shared-vertex
    adjacency (4th review, harden-the-harness item 1).

    Genus is a topological invariant of a SINGLE connected solid -- it
    cannot see a part that renders as two (or more) disjoint solids
    sharing no material at all, because Euler characteristic is computed
    the same way whether a part is "one stepped tube" or "a tube plus a
    loose ring floating in its own bore": both are unions of simple
    closed surfaces, and nothing about chi or genus counts HOW MANY of
    them there are. This is exactly finding 1 (3rd->4th review): the
    chute tube's fin-can spigot rendered as a second, disconnected
    component entirely inside the tube's own bore, radius 26.6..28.2mm
    against the tube's 28.4mm ID -- a 0.2mm gap with zero shared
    geometry -- and every existing check (genus, bore(), measure())
    passed, because none of them can see "how many pieces".

    Union-find over vertex COORDINATES (rounded to 1e-4mm, well below
    OpenSCAD's own STL-export precision, to merge floating-point-adjacent
    copies of what is geometrically the same point): two triangles are in
    the same component if they share any vertex position. A print that
    left the slicer as two separate solids is not "connected" by any
    weaker test that matters here -- the two pieces have no shared
    material at their nearest approach, only proximity, so vertex-sharing
    (not edge- or face-adjacency, which would give the identical answer
    for a manifold mesh at strictly more bookkeeping) is the right and
    sufficient test."""
    parent = {}

    def find(v):
        root = v
        while parent[root] != root:
            root = parent[root]
        while parent[v] != root:
            parent[v], v = root, parent[v]
        return root

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    def key(v):
        return (round(v[0], 4), round(v[1], 4), round(v[2], 4))

    for tri in tris(stl):
        ks = [key(v) for v in tri]
        for k in ks:
            parent.setdefault(k, k)
        union(ks[0], ks[1])
        union(ks[1], ks[2])
    if not parent:
        return 0
    return len(set(find(k) for k in parent))


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


def overshoot(value, limit):
    """max(0.0, value - limit), but nan-safe.

    verify_camnose.py/verify_nosecone.py/verify_motordummy29.py's own
    build-volume checks all report "how much a part overshoots the
    printer's limit" as `max(0.0, height - LIMIT)` -- 0 for anything that
    fits, the actual excess otherwise. But measure()'s own convention
    (its docstring above) is to return nan height for a degenerate,
    zero-triangle mesh, so a totally empty/broken render used to sail
    through that check silently: Python's `max(0.0, nan - LIMIT)` picks
    0.0, because every comparison against nan is False and max() just
    returns its first argument when the second never compares greater.
    That is a silent PASS for exactly the case (no geometry at all) this
    check most needs to catch. Return +inf for a nan input instead, so it
    fails whatever `<= tolerance` check the caller runs against it --
    consistent with every other nan-as-loud-failure convention in this
    file (see measure()'s own docstring)."""
    if math.isnan(value):
        return float("inf")
    return max(0.0, value - limit)


@functools.lru_cache(maxsize=8)
def _bore_cached(stl, st_mtime_ns, st_size, zlo, zhi):
    """Actual bore() body, memoised on (path, mtime, size, band) -- see
    bore() below for why mtime/size are part of the key, not just path.

    Bounded to 8 (5th review, finding 10), matching _tris_cached's own
    policy just above -- maxsize=None was left unbounded here for the
    same reason _tris_cached was bounded (defect 12/13, 4th review): a
    verify run re-renders every part several times across
    checks()/assembly probes, and an unbounded cache keeps every
    (path, band) result live for the whole process instead of just the
    handful of live overlapping calls any one part's checks actually
    make."""
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
