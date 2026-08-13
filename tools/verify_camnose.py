#!/usr/bin/env python3
"""Render and measure PeregrineCamNose parts, and prove the graft fits.

A part that does not fit still renders cleanly, so every mating dimension is
measured from the STL rather than inferred from parameters. In particular the
adapter-spigot-to-shell-bore fit is checked mesh against mesh (part 4's
actual bore vs part 5's actual spigot OD), not against the constants that
produced them -- that convention is used elsewhere in this repo and has
caught real interference that the constants alone would have missed.

The camera itself no longer lives in this file -- it lives in a separate CAD
nosecone (STL Files/Rocket60/NoseCone.stl) that bolts onto the adapter, so
there is nothing here to check the camera's fit against.
"""
import math, os, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
SCAD = os.path.join(REPO, "PeregrineCamNose.scad")

CUT1_Z, CUT2_Z, CUT3_Z = 147.14, 294.29, 383.23
WALL = 2.2
CAD_BOLT_R = 18.98            # bolt circle radius on the CAD nosecone, measured
M3_CLEAR = 3.4
EPOXY_GAP = 0.4                # adapter spigot vs shell bore, diametral

GENUS = {0: 1, 1: 2, 4: 1, 5: 4}   # 5 = adapter: 1 harness bore + 3 screw holes


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


def volume(stl):
    v = 0.0
    for (x1,y1,z1),(x2,y2,z2),(x3,y3,z3) in _tris(stl):
        v += (x1*(y2*z3-y3*z2) - x2*(y1*z3-y3*z1) + x3*(y1*z2-y2*z1)) / 6.0
    return abs(v) / 1000.0


NAMES = {0:"test ring", 1:"shoulder", 2:"bottom slice", 3:"middle slice",
         4:"top slice", 5:"adapter"}


def main(argv):
    parts = [int(a) for a in argv[1:]] or [0, 1, 2, 3, 4, 5]
    m, genus, stls, tmp = {}, {}, {}, tempfile.mkdtemp()
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
        checks += [("top slice zmax (Cut3)", m[4]["zmax"], CUT3_Z, 0.2),
                   ("top slice outer dia at Cut3", top_outer, 60.0, 0.2),
                   ("top slice bore dia at Cut3", top_inner, 60.0 - 2*WALL, 0.2)]
    if 5 in m:
        checks += [("adapter flange outer dia", m[5]["dmax"], 60.0, 0.1),
                   ("adapter height", m[5]["height"], 4.5 + 15, 0.1)]
    if 2 in m and 3 in m:
        checks += [("joint 1 overlap", m[2]["zmax"] - m[3]["zmin"], 7.0, 0.2)]
    if 3 in m and 4 in m:
        checks += [("joint 2 overlap", m[3]["zmax"] - m[4]["zmin"], 7.0, 0.2)]
    if 1 in m:
        checks += [("shoulder height", m[1]["height"], 115.0, 0.2),
                   ("shoulder body dia", m[1]["dmax"], 98.7, 0.2)]
    for p in m:
        checks += [("part %d fits 250mm Z" % p, m[p]["height"],
                    min(m[p]["height"], 250.0), 0.01)]
    for p, g in genus.items():
        if p in GENUS and g is not None:
            checks += [("part %d genus" % p, g, GENUS[p], 0)]

    # Adapter spigot vs shell bore: mesh against mesh, not constants. Part 4
    # is rendered with its own Z origin at Cut2_Z, so its bore near Cut3 is
    # sampled a few mm below its top edge; part 5 (adapter) is rendered with
    # its flange top at Z=0 and its spigot hanging below, so the spigot OD
    # is sampled a few mm up from its (negative-Z) bottom edge.
    if 4 in m and 5 in m:
        # The bore narrows monotonically toward Cut3 (the shell converges
        # toward the tip), so the tightest point along the spigot's 15mm
        # insertion depth is right at the rim it enters through -- sample
        # there, not deeper in where the shell is roomier.
        shell_inner, _ = bore(stls[4], m[4]["zmax"] - 0.3, m[4]["zmax"] - 0.05)
        _, spigot_outer = bore(stls[5], m[5]["zmin"] + 1.0, m[5]["zmin"] + 3.0)
        clearance = shell_inner - spigot_outer
        checks += [("SPIGOT CLEARS SHELL BORE (diametral)", clearance,
                    EPOXY_GAP, 0.1)]
        checks += [("spigot outer dia < shell inner dia", spigot_outer < shell_inner,
                    True, 0)]

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
