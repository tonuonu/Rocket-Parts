#!/usr/bin/env python3
"""Render and measure the default PeregrineCamNose bay and its legacy adapter.

A part that does not fit still renders cleanly, so every mating dimension is
measured from the STL rather than inferred from parameters. The default top slice now includes the camera flange. Part 5 remains a
legacy adapter, not an additional part of that assembly. Run the companion
verify_camnose_bay.py for solid intersections, hardware and service access.

The camera itself no longer lives in this file -- it lives in a separate,
already-finished CAD nosecone that bolts onto the adapter (see CN_Adapter()
in the .scad). That CAD nosecone's own mesh is not part of this branch, so
there is nothing here to check the camera's fit against.
"""
import argparse, math, os, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
SCAD = os.path.join(REPO, "PeregrineCamNose.scad")

CUT1_Z, CUT2_Z, CUT3_Z = 147.15, 294.29, 383.23
WALL = 2.2
CAD_BOLT_R = 18.98            # bolt circle radius on the CAD nosecone, measured
CAD_BOLT_A = (52.2, -52.2, 180.0)   # clocking, deliberately not 120 deg apart
INSERT_HOLE = 4.0             # heat-set insert hole, Insert_Hole_D in the .scad

GENUS = {0: 1, 1: 2, 4: 11, 5: 4}
# Top: bore, three service screws, switch, three charging + three camera holes.


def render(part, out):
    env = dict(os.environ, OPENSCADPATH=REPO)
    r = subprocess.run(
        [OPENSCAD, "--export-format", "asciistl", "-o", out,
         "-D", "Render_Part=%d" % part, SCAD],
        capture_output=True, text=True, env=env, timeout=900)
    err = r.stdout + r.stderr
    if (r.returncode != 0 or "ERROR:" in err.upper()
            or "Can't find include file" in err
            or "Ignoring unknown" in err
            or not os.path.exists(out) or os.path.getsize(out) < 200):
        raise RuntimeError("render of part %d failed:\n%s" % (part, err[-2000:]))
    g = None
    for line in err.splitlines():
        if "Genus:" in line:
            try:
                g = int(line.split("Genus:")[1].split()[0])
            except (ValueError, IndexError):
                pass
    return g


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
    """(inner, outer) diameter found by interpolating triangle edges that
    cross the mid-plane of [zlo, zhi] -- not just nearby vertices, so it
    is not fooled by the mesh's own $fn faceting."""
    zmid = (zlo + zhi) / 2.0
    ds = []
    for tri in _tris(stl):
        for i in range(3):
            x1, y1, z1 = tri[i]
            x2, y2, z2 = tri[(i + 1) % 3]
            if (z1 - zmid) * (z2 - zmid) < 0:
                t = (zmid - z1) / (z2 - z1)
                x = x1 + t * (x2 - x1)
                y = y1 + t * (y2 - y1)
                ds.append(2 * math.hypot(x, y))
    if not ds:
        raise RuntimeError("no geometry crossing Z=%.2f of %s" % (zmid, stl))
    return min(ds), max(ds)


def slice_points(stl, zlo, zhi):
    """(x, y) points where triangle edges cross the mid-plane of [zlo, zhi]."""
    zmid = (zlo + zhi) / 2.0
    pts = []
    for tri in _tris(stl):
        for i in range(3):
            x1, y1, z1 = tri[i]
            x2, y2, z2 = tri[(i + 1) % 3]
            if (z1 - zmid) * (z2 - zmid) < 0:
                t = (zmid - z1) / (z2 - z1)
                pts.append((x1 + t * (x2 - x1), y1 + t * (y2 - y1)))
    return pts


def bolt_pattern(stl, zlo, zhi, bolt_r, hole_d):
    """Cluster the small screw-clearance holes out of a Z-slice of the
    mesh and return each hole's (radius, angle_deg, diameter) -- measured,
    not read off the constants that were supposed to produce it. Filters
    to points near the expected bolt radius (comfortably excludes the
    flange's own outer edge and the harness bore, both much farther away),
    then splits by angle: sort and start a new cluster wherever the gap to
    the next point exceeds 20 deg -- fine for a handful of holes spread
    around a full circle, which is the only pattern this part uses."""
    margin = hole_d / 2.0 + 1.5
    cand = [(x, y) for x, y in slice_points(stl, zlo, zhi)
            if abs(math.hypot(x, y) - bolt_r) < margin]
    if not cand:
        return []
    cand.sort(key=lambda p: math.degrees(math.atan2(p[1], p[0])))
    clusters, cur = [], [cand[0]]
    for p in cand[1:]:
        a_prev = math.degrees(math.atan2(cur[-1][1], cur[-1][0]))
        a_cur = math.degrees(math.atan2(p[1], p[0]))
        if (a_cur - a_prev) % 360 > 20:
            clusters.append(cur)
            cur = [p]
        else:
            cur.append(p)
    clusters.append(cur)
    if len(clusters) > 1:
        a_first = math.degrees(math.atan2(clusters[0][0][1], clusters[0][0][0]))
        a_last = math.degrees(math.atan2(clusters[-1][-1][1], clusters[-1][-1][0]))
        if (a_first - a_last) % 360 < 20:
            clusters[0] = clusters[-1] + clusters[0]
            clusters.pop()

    holes = []
    for c in clusters:
        cx = sum(p[0] for p in c) / len(c)
        cy = sum(p[1] for p in c) / len(c)
        dia = (max(math.hypot(p[0] - q[0], p[1] - q[1]) for p in c for q in c)
               if len(c) > 1 else 0.0)
        holes.append((math.hypot(cx, cy), math.degrees(math.atan2(cy, cx)), dia))
    return holes


def volume(stl):
    v = 0.0
    for (x1,y1,z1),(x2,y2,z2),(x3,y3,z3) in _tris(stl):
        v += (x1*(y2*z3-y3*z2) - x2*(y1*z3-y3*z1) + x3*(y1*z2-y2*z1)) / 6.0
    return abs(v) / 1000.0


NAMES = {0:"test ring", 1:"shoulder", 2:"bottom slice", 3:"middle slice",
         4:"integrated top", 5:"legacy adapter", 6:"battery carrier", 7:"converter tray"}


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("parts", type=int, nargs="*")
    parser.add_argument("--output-dir", help="keep rendered ASCII STLs for mesh checks")
    args = parser.parse_args(argv[1:])
    parts = args.parts or list(range(8))
    if any(p not in range(8) for p in parts):
        parser.error("part numbers must be 0..7 (8 is a non-printable assembly)")
    tmp = args.output_dir or tempfile.mkdtemp()
    os.makedirs(tmp, exist_ok=True)
    m, genus, stls = {}, {}, {}
    for p in parts:
        out = os.path.join(tmp, "part%d.stl" % p)
        try:
            genus[p] = render(p, out)
        except (RuntimeError, subprocess.TimeoutExpired) as e:
            print("FAIL  render part %d (%s)\n%s" % (p, NAMES.get(p, "?"), e))
            return 1
        stls[p] = out
        m[p] = measure(out)
        print("  part %d %-14s h=%7.2f dia=%7.2f z=%7.2f..%7.2f %5.0f g"
              % (p, NAMES.get(p, "?"), m[p]["height"], m[p]["dmax"],
                 m[p]["zmin"], m[p]["zmax"], volume(out) * 1.27))
    checks = []
    if 2 in m:
        checks += [("bottom zmin", m[2]["zmin"], 0.0, 0.1),
                   ("bottom outer dia", m[2]["dmax"], 101.5, 0.3)]
    if 3 in m:
        checks += [("middle zmin", m[3]["zmin"], CUT1_Z, 0.2)]
    if 4 in m:
        top_inner, top_outer = bore(stls[4], m[4]["zmax"] - 0.3, m[4]["zmax"] - 0.05)
        checks += [("integrated top zmax", m[4]["zmax"], CUT3_Z+6, 0.2),
                   ("camera flange outer dia", top_outer, 60.0, 0.2),
                   ("camera flange harness bore", top_inner, 29.56, 0.2)]
        holes = bolt_pattern(stls[4],CUT3_Z+2,CUT3_Z+4,CAD_BOLT_R,INSERT_HOLE)
        checks += [("integral flange insert hole count",len(holes),3,0)]
        for exp_a in CAD_BOLT_A:
            if holes:
                r,a,d=min(holes,key=lambda h:abs(((h[1]-exp_a+180)%360)-180))
                checks += [("integral insert @%.1f radius" % exp_a,r,CAD_BOLT_R,0.15),
                           ("integral insert @%.1f angle error" % exp_a,((a-exp_a+180)%360)-180,0,1),
                           ("integral insert @%.1f diameter" % exp_a,d,INSERT_HOLE,0.15)]
    if 5 in m:
        checks += [("adapter flange outer dia", m[5]["dmax"], 60.0, 0.1),
                   ("adapter height", m[5]["height"], 6.0 + 15, 0.1)]

        # Bolt pattern: CAD_Bolt_A's clocking (52.2/-52.2/180, deliberately
        # not 120 deg apart -- it keys the camera's clocking) is marked
        # "preserve exactly" in the .scad, but until now nothing checked
        # the rendered mesh actually has holes there: genus only counts
        # holes, and passes identically whether they are at the right
        # radius and angles or not.
        holes = bolt_pattern(stls[5], m[5]["zmax"] * 0.3, m[5]["zmax"] * 0.7,
                              CAD_BOLT_R, INSERT_HOLE)
        checks += [("adapter bolt pattern hole count", len(holes), 3, 0)]
        if len(holes) == 3:
            for exp_a in CAD_BOLT_A:
                r, a, d = min(
                    holes, key=lambda h: abs(((h[1] - exp_a + 180) % 360) - 180))
                # normalize to the branch nearest exp_a (e.g. -180 vs 180 are
                # the same angle, but a plain subtraction would not see that)
                a_norm = exp_a + (((a - exp_a + 180) % 360) - 180)
                checks += [
                    ("adapter hole @%.1fdeg radius" % exp_a, r, CAD_BOLT_R, 0.15),
                    ("adapter hole @%.1fdeg angle" % exp_a, a_norm, exp_a, 1.0),
                    ("adapter hole @%.1fdeg diameter" % exp_a, d, INSERT_HOLE, 0.15),
                ]
    if 2 in m and 3 in m:
        checks += [("joint 1 overlap", m[2]["zmax"] - m[3]["zmin"], 7.0, 0.2)]
    if 3 in m and 4 in m:
        checks += [("joint 2 overlap", m[3]["zmax"] - m[4]["zmin"], 7.0, 0.2)]
    if 1 in m:
        checks += [("shoulder height", m[1]["height"], 115.0, 0.2),
                   ("shoulder body dia", m[1]["dmax"], 98.7, 0.2)]
    if 6 in m:
        checks += [("carrier floor z", m[6]["zmin"], 270.0, 0.01),
                   ("carrier height", m[6]["height"], 77.0, 0.01),
                   ("carrier max diameter", m[6]["dmax"], 64.0, 0.01)]
    if 7 in m:
        checks += [("tray keeper bottom z", m[7]["zmin"], 337.6, 0.01),
                   ("tray rim top z", m[7]["zmax"], 353.0, 0.01)]
    for p in m:
        checks += [("part %d fits 250mm Z" % p, m[p]["height"],
                    min(m[p]["height"], 250.0), 0.01)]
    for p, g in genus.items():
        if p in GENUS and g is not None:
            checks += [("part %d genus" % p, g, GENUS[p], 0)]

    print()
    bad = 0
    for label, actual, expected, tol in checks:
        ok = (actual == expected) if isinstance(expected, bool) \
            else abs(actual - expected) <= tol
        bad += not ok
        if isinstance(expected, bool):
            print("%-4s %-42s %10s  expected %8s"
                  % ("PASS" if ok else "FAIL", label, actual, expected))
        else:
            print("%-4s %-42s %10.2f  expected %8.2f +/- %.2f"
                  % ("PASS" if ok else "FAIL", label, actual, expected, tol))
    print("\n%d check(s) failed" % bad if bad else "\nall checks passed")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
