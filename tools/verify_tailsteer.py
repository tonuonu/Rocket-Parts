#!/usr/bin/env python3
"""Render PeregrineTailSteer.scad and check it as CAD.

Checks: printable parts are closed single solids that fit the P1S; the can
clears the motor tube, retainer, servos, horns, bearings, shafts, cranks,
ailerons, fixed fins, LiPo, switch and hatch covers; every bearing sits in
its seat; walls (outer wall, bearing housings, insert bosses) are at least
their minimum; servos, LiPo and switch keep their air gap to the motor tube;
each aileron is free through +-Flap_Max with the linkage solved at every
step (crank, pushrod, horn, servo), with a gap of at least 0.78 mm to the can
and the fixed fin (0.8 by design) and 1.2 mm from the pushrod links to the can; the aft rail button sits on the 60 deg line at the .ork
station, its insert pocket is sound, hatch screw heads stay off the rail
strip and the fins never reach the rail. The Zephyr fin set is rendered and
its ailerons checked the same way.

Servo, horn, LiPo and switch solids are envelopes (MKS HV6160 drawing,
Tattu 450 mAh 2S long pack, Schurter 0033.4513). This verifies CAD, not
printed fits, strength or flight behaviour.

Requires numpy, trimesh, manifold3d, rtree, scipy, shapely.
OpenSCAD: $OPENSCAD, else /Applications/OpenSCAD-dev.app, else openscad on PATH.
Usage: verify_tailsteer.py [--output-dir DIR] [--json FILE] [--export]
  --export  also writes the STLs and DXFs to "STL Files/PeregrineTailSteer/"
"""
import argparse
import json
import math
import os
import shutil
import subprocess
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np
import trimesh
from scipy.optimize import brentq
from shapely.geometry import Polygon
from shapely.ops import polylabel, unary_union

REPO = Path(__file__).resolve().parents[1]
SCAD = REPO / "PeregrineTailSteer.scad"
OPENSCAD_DEV = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
OPENSCAD = (os.environ.get("OPENSCAD")
            or (OPENSCAD_DEV if os.path.exists(OPENSCAD_DEV) else shutil.which("openscad")))
OUT_STL = REPO / "STL Files" / "PeregrineTailSteer"
results = []

PRINTS = {   # name: (Render_Part, defines)
    "FinCan": (1, {}),
    "HatchServo": (2, {}),
    "HatchServoLipo": (3, {}),
    "Crank": (4, {}),
    "AileronScrewHalf_Peregrine": (5, {}),
    "AileronTappedHalf_Peregrine": (8, {}),
    "AileronScrewHalf_Zephyr": (5, {"Fin_Set": '"Zephyr"'}),
    "AileronTappedHalf_Zephyr": (8, {"Fin_Set": '"Zephyr"'}),
    "BearingCoupon": (6, {}),
    "ShaftDrillJig": (9, {}),
}
ENVS = {
    "servos": 20, "horns": 21, "bearings": 22, "shafts": 23, "cranks": 24,
    "ailerons": 25, "fins": 26, "mmt": 27, "lipo": 28, "switch": 29,
    "covers": 30, "retainer": 31, "aileron0": 32, "crank0": 33, "servo0": 34,
    "horn0": 35, "fin0": 36, "tube": 37, "ail_m": 38, "ail_p": 39, "shaft0": 40,
}
ZEPHYR = {"z_aileron0": 32, "z_fin0": 36, "z_fins": 26, "z_ailerons": 25}
DXF = {"FixedFin_Peregrine": {}, "FixedFin_Zephyr": {"Fin_Set": '"Zephyr"'}}


def record(name, ok, value=None):
    results.append({"check": name, "passed": bool(ok), "value": value})
    print(("PASS " if ok else "FAIL ") + name +
          ("  " + str(value) if value is not None else ""), flush=True)


def run_scad(out, part, defines, fmt="binstl"):
    cmd = [OPENSCAD, "--backend=manifold", "--render", "--export-format", fmt, "-o", str(out),
           "-D", "Render_Part=%d" % part]
    for k, v in defines.items():
        cmd += ["-D", "%s=%s" % (k, v)]
    cmd.append(str(SCAD))
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=1800,
                       env={"OPENSCADPATH": str(REPO), "PATH": "/usr/bin:/bin"})
    log = r.stdout + r.stderr
    if r.returncode != 0 or "ERROR" in log or "WARNING" in log or not out.exists():
        raise RuntimeError("render %s failed:\n%s" % (out.name, log[-3000:]))
    return log


def echo_values(log, key):
    for line in log.splitlines():
        if key in line:
            return line.split(key, 1)[1].strip().strip('"')
    raise RuntimeError("no %s echo" % key)


def inter(a, b):
    if np.any(a.bounds[1] <= b.bounds[0]) or np.any(b.bounds[1] <= a.bounds[0]):
        return 0.0
    r = trimesh.boolean.intersection([a, b], engine="manifold")
    return 0.0 if r.is_empty else abs(float(r.volume))


def clear(name, a, b, tol=1e-3):
    v = inter(a, b)
    record(name, v < tol, round(v, 4))
    return v


_SAMPLES = {}


def _samples(mesh, n, seed):
    key = (id(mesh), n, seed)
    if key not in _SAMPLES:
        pts, _ = trimesh.sample.sample_surface_even(mesh, n, seed=seed)
        _SAMPLES[key] = np.vstack([pts, mesh.vertices])
    return _SAMPLES[key]


def min_gap(moving, fixed, n=4000, seed=1):
    """Smallest surface-to-surface distance between `moving` and `fixed`,
    sampled both ways (points on each body against the other), 0 if they
    overlap."""
    return min(_min_gap_one_way(moving, fixed, n, seed),
               _min_gap_one_way(fixed, moving, n, seed, dense=True))


def _min_gap_one_way(moving, fixed, n=4000, seed=1, dense=False):
    """Distance from points on `moving` to the surface of `fixed`. With dense,
    `moving` is a large body: it is sampled finely and only the points near
    `fixed` are used."""
    if dense:
        pts = _samples(moving, 60000, seed)
    else:
        pts, _ = trimesh.sample.sample_surface_even(moving, n, seed=seed)
        pts = np.vstack([pts, moving.vertices])
    lo, hi = fixed.bounds[0] - 5, fixed.bounds[1] + 5
    near = pts[np.all((pts > lo) & (pts < hi), axis=1)]
    if len(near) == 0:      # far away: distance from the box is a lower bound
        return float(np.min(np.max(np.c_[lo - pts, pts - hi, np.zeros(len(pts))], axis=1)))
    pts = near
    inside = fixed.contains(pts)
    if inside.any():
        return 0.0
    _, d, _ = trimesh.proximity.closest_point(fixed, pts)
    return float(d.min())


def rot_x(deg, z0):
    return trimesh.transformations.rotation_matrix(math.radians(deg), [1, 0, 0], [0, 0, z0])


def capsule(p0, p1, r):
    p0, p1 = np.asarray(p0, float), np.asarray(p1, float)
    L = np.linalg.norm(p1 - p0)
    # circumscribed: the faceted capsule is never thinner than r (sagitta added)
    c = trimesh.creation.capsule(height=L, radius=r / math.cos(math.pi / 32), count=[32, 32])
    T = trimesh.geometry.align_vectors([0, 0, 1], (p1 - p0) / L)
    T[:3, 3] = (p0 + p1) / 2
    c.apply_transform(T)
    return c


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--output-dir")
    ap.add_argument("--json")
    ap.add_argument("--export", action="store_true")
    a = ap.parse_args()
    if not OPENSCAD:
        raise SystemExit("OpenSCAD not found: set OPENSCAD to its binary")
    tmp = Path(a.output_dir) if a.output_dir else Path(tempfile.mkdtemp(prefix="tailsteer-"))
    tmp.mkdir(parents=True, exist_ok=True)

    jobs = [(tmp / (n + ".stl"), p, d) for n, (p, d) in PRINTS.items()]
    jobs += [(tmp / (n + ".stl"), p, {}) for n, p in ENVS.items()]
    jobs += [(tmp / (n + ".stl"), p, {"Fin_Set": '"Zephyr"'}) for n, p in ZEPHYR.items()]
    jobs += [(tmp / (n + ".dxf"), 7, d, "dxf") for n, d in DXF.items()]
    logs = {}
    with ThreadPoolExecutor(max_workers=8) as ex:
        futs = {ex.submit(run_scad, *j): j[0].stem for j in jobs}
        for f, n in futs.items():
            logs[n] = f.result()
    record("all parts render without warnings", True, len(jobs))

    P = [float(x) for x in echo_values(logs["FinCan"], "TS_PARAMS").split()]
    keys = ("R_Out R_In MMT_OD MMT_Z0 MMT_L Hinge_Z Hinge_X Fin_Base_X Flap_Span Flap_Root_Gap "
            "Flap_Gap Flap_LE_R Shaft_D Shaft_X0 Shaft_X1 Brg_In_X0 Brg_Out_X1 Brg_B Brg_D Crank_A "
            "Horn_R Crank_Xk Servo_Theta Servo_Rc Servo_ZO Pushrod_L Horn_Ball_U Fin_T Can_L Total_H "
            "Rail_A Rail_Aft_Z Tube_Piece_L Ply_CR_Z0 Flap_Max Sw_A Sw_Z Flap_X_Max Fixed_Aft_X "
            "Lipo_Z0 Lipo_L Ball_Off Horn_Arm_T Pin_D Pin_L Clamp_Relief").split()
    p = dict(zip(keys, P))
    m = {n: trimesh.load(tmp / (n + ".stl")) for n in list(PRINTS) + list(ENVS) + list(ZEPHYR)}

    # ---------- printable parts
    for n in PRINTS:
        mm = m[n]
        ok = mm.is_watertight and len(mm.split(only_watertight=False)) == 1 and mm.volume > 0
        record("%s is one closed solid" % n, ok, "%.1f cm3" % (mm.volume / 1000))
    record("can height fits the P1S (<= 250.5)", m["FinCan"].extents[2] <= 250.5,
           round(m["FinCan"].extents[2], 2))
    record("hatch covers print standing (<= 250)", max(m["HatchServo"].extents[2],
           m["HatchServoLipo"].extents[2]) <= 250, round(m["HatchServoLipo"].extents[2], 1))
    can = m["FinCan"]
    # supportless: every downward-facing patch (steeper than 45 deg, more than
    # 0.1 mm, i.e. under one layer, above the bed) is a narrow ledge or a short
    # bridge: its true narrow width (twice the largest inscribed circle of its
    # plan view) is <= 7 mm
    worst_w = (0, None)
    for n in PRINTS:
        mm = m[n]
        sel = (mm.face_normals[:, 2] < -0.71) & (mm.triangles_center[:, 2] > mm.bounds[0, 2] + 0.1)
        if not sel.any():
            continue
        sub = mm.submesh([np.where(sel)[0]], append=True)
        for q in sub.split(only_watertight=False):
            plan = unary_union([Polygon(t[:, :2]).buffer(0.01) for t in q.triangles
                                if Polygon(t[:, :2]).area > 1e-9])
            w = 0.0
            for poly in getattr(plan, "geoms", [plan]):
                if poly.is_empty:
                    continue
                c_ = polylabel(poly, tolerance=0.02)
                w = max(w, 2 * poly.boundary.distance(c_) - 0.02)
            if w > worst_w[0]:
                c = q.bounds.mean(0)
                worst_w = (w, "%s at Z %.1f" % (n, c[2]))
    record("supportless: no downward patch wider than 7 mm (inscribed circle)", worst_w[0] <= 7.0,
           "widest %.1f mm, %s" % worst_w)

    # ---------- static fits
    for n in ("mmt", "retainer", "servos", "horns", "shafts", "cranks", "ailerons", "fins",
              "lipo", "switch", "covers", "tube"):
        clear("can clears %s" % n, can, m[n])
    v = inter(can, m["bearings"])
    record("bearings sit in their seats without interference", v < 0.05, round(v, 4))
    for a_, b_ in (("servos", "fins"), ("servos", "lipo"), ("horns", "lipo"), ("lipo", "covers"),
                   ("servos", "covers"), ("horns", "covers"), ("cranks", "bearings"),
                   ("cranks", "shafts"), ("ailerons", "fins"), ("ailerons", "shafts"),
                   ("servos", "horns")):
        clear("%s clear %s" % (a_, b_), m[a_], m[b_])
    # every bearing is supported: points on the lower half of its OD lie within 0.1 of the can
    Z = p["Hinge_Z"]
    sup = []
    for xc in (p["Brg_In_X0"] + p["Brg_B"] / 2, p["Brg_Out_X1"] - p["Brg_B"] / 2):
        ang = np.radians(np.linspace(200, 340, 15))
        pts = np.c_[np.full(15, xc), (p["Brg_D"] / 2 + 0.06) * np.cos(ang),
                    Z + (p["Brg_D"] / 2 + 0.06) * np.sin(ang)]
        _, d, _ = trimesh.proximity.closest_point(can, pts)
        sup.append(float(d.max()))
    record("both bearing seats touch the lower half of the outer ring (gap <= 0.1)",
           max(sup) <= 0.1, [round(s, 3) for s in sup])
    # shaft passes through both bearings and ends inside the aileron bore
    ok = (p["Shaft_X0"] < p["Brg_In_X0"] + 0.5 and
          p["Shaft_X1"] < p["R_Out"] + p["Flap_Span"] - 1)
    record("shaft spans both bearings and stops inside the aileron", ok,
           [p["Shaft_X0"], p["Shaft_X1"]])
    # glue gap round the motor tube
    rmin = float(np.min(np.hypot(can.vertices[:, 0], can.vertices[:, 1])))
    record("can bore leaves the 0.2 mm epoxy gap on the motor tube", abs(rmin - (p["MMT_OD"] / 2 + 0.2)) < 0.05,
           round(rmin, 3))

    # ---------- aileron clamp screws: measured tap depth vs screw length. A ray
    # along +Y on each screw axis passes the clearance hole and countersink in the
    # -Y half and stops at the tap hole's bottom in the +Y half. The head's top
    # face is flush with the -Y face (y = -Fin_T/2).
    cl = [float(x) for x in echo_values(logs["FinCan"], "TS_CLAMP").replace("[", " ").replace("]", " ")
          .replace(",", " ").split()]
    screw_l, fin_t, pos = cl[0], cl[1], cl[2:]
    ail = trimesh.util.concatenate([m["ail_m"], m["ail_p"]])
    room = []
    for i in range(0, len(pos), 2):
        o = np.array([pos[i], -10.0, pos[i + 1]])
        loc, _, _ = ail.ray.intersects_location([o], [[0, 1, 0]], multiple_hits=True)
        ys = sorted(float(y) for y in loc[:, 1])
        bottom = next((y for y in ys if y > 0.05), None)     # first hit past the split face
        room.append(None if bottom is None else bottom + fin_t / 2)
    ok = all(r is not None and screw_l <= r - 0.3 for r in room)
    record("aileron clamp screws M2x%g stop >= 0.3 mm short of the tap bottom" % screw_l, ok,
           "seat-to-tap-bottom %s mm" % [None if r is None else round(r, 2) for r in room])
    # each clamp screw is over the shaft (within its engaged length and <= 5 mm aft of
    # the axis, so the shaft reacts it) or over solid contact (split faces touching on a
    # ring 3 mm round the screw)
    bad = []
    for i in range(0, len(pos), 2):
        x0_, z0_ = pos[i], pos[i + 1]
        over_shaft = (p["R_Out"] + p["Flap_Root_Gap"] <= x0_ <= p["Shaft_X1"]) and (Z - z0_) <= 5.0
        touch = 0
        for a_ in np.radians(np.arange(0, 360, 45)):
            o_ = np.array([x0_ + 3 * math.cos(a_), -10.0, z0_ + 3 * math.sin(a_)])
            loc, _, _ = ail.ray.intersects_location([o_], [[0, 1, 0]], multiple_hits=True)
            inner = sorted(float(y) for y in loc[:, 1] if -1 < y < 1)
            if len(inner) < 2 or inner[-1] - inner[0] < 0.02:
                touch += 1
        if not (over_shaft or touch >= 6):
            bad.append((round(x0_, 1), round(z0_, 1), over_shaft, touch))
    record("every aileron clamp screw sits over the shaft or over solid face contact", not bad, bad or "ok")

    # ---------- aileron drive play: rays from the shaft axis to the D-groove in the
    # assembled halves, against the shaft profile (r 2, flat at 1.5 toward -Z). The
    # split plane (+-12 deg of +-Z) is skipped: the clamp relief is open there.
    sh_r, sh_flat = p["Shaft_D"] / 2, p["Shaft_D"] / 2 - 0.5
    half_chord = math.sqrt(sh_r ** 2 - sh_flat ** 2)
    c_round, c_flat = [], []
    for xs_ in (58.0, 75.0):
        for a_deg in np.arange(0, 360, 4):
            if min(abs(a_deg - 90), abs(a_deg - 270)) < 12:
                continue
            a_ = math.radians(a_deg)
            d_ = np.array([0, math.cos(a_), math.sin(a_)])
            o_ = np.array([xs_, 0, Z])
            loc, _, _ = ail.ray.intersects_location([o_], [d_], multiple_hits=False)
            if len(loc) == 0:
                continue
            r_b = float(np.linalg.norm(loc[0] - o_))
            on_flat = math.sin(a_) < 0 and abs(math.cos(a_)) / -math.sin(a_) <= half_chord / sh_flat
            r_s = sh_flat / -math.sin(a_) if on_flat else sh_r
            (c_flat if on_flat else c_round).append(r_b - r_s)
    cf_, cr_ = max(c_flat), max(c_round)
    play = math.degrees(math.asin(min(1.0, max(0.0, cf_ + cr_) / half_chord)))
    o_ = np.array([57.0, -10.0, Z - 5.5])   # inside the relief band, clear of screws and dowel
    loc, _, _ = ail.ray.intersects_location([o_], [[0, 1, 0]], multiple_hits=True)
    ys = sorted(float(y) for y in loc[:, 1])
    inner = [y for y in ys if -1 < y < 1]
    gap_c = (inner[1] - inner[0]) if len(inner) >= 2 else 0.0
    record("aileron drive: angular play < 0.5 deg at the trailing edge, clamp gap > 0",
           play < 0.5 and gap_c > 0.05,
           "flat clearance %.3f, round %.3f -> play %.2f deg; split-face gap %.2f mm" % (cf_, cr_, play, gap_c))

    # ---------- fin-root fillets: the hatch rebates and openings stay clear of a
    # Fillet_Max leg + 2 mm, measured on the outer skin from each fin face
    hv = [float(x) for x in echo_values(logs["FinCan"], "TS_HATCH").split()]
    fillet_max = hv[-1]
    angs = np.radians(np.arange(5.0, 30.0, 0.2))   # from just past the fin slot (3.9 deg)
    zs = np.arange(40.0, 215.0, 2.5)
    worst_f = 99.0
    for k in range(3):
        for side in (-1, 1):
            A, Zg = np.meshgrid(angs, zs)
            th_ = math.radians(120 * k) + side * A.ravel()
            org = np.c_[60 * np.cos(th_), 60 * np.sin(th_), Zg.ravel()]
            d_ = -np.c_[np.cos(th_), np.sin(th_), np.zeros(th_.size)]
            loc, ir, _ = can.ray.intersects_location(org, d_, multiple_hits=False)
            r_hit = np.full(len(org), 0.0)
            r_hit[ir] = 60 - np.linalg.norm(loc - org[ir], axis=1)
            recess = r_hit < p["R_Out"] - 0.3
            if recess.any():
                worst_f = min(worst_f, float(np.min(A.ravel()[recess])) * p["R_Out"] - p["Fin_T"] / 2)
    record("hatch rebates clear a %.0f mm fin-root fillet by >= 2 mm" % fillet_max, worst_f >= fillet_max + 2,
           "nearest recess %.1f mm from a fin face" % worst_f)

    # ---------- air gaps to the motor tube (thermal)
    def rmin_surface(mesh):
        pts, _ = trimesh.sample.sample_surface_even(mesh, 20000, seed=2)
        return float(np.min(np.hypot(pts[:, 0], pts[:, 1])))
    r_mmt = p["MMT_OD"] / 2
    for n, lim in (("servos", 8.0), ("lipo", 8.0), ("switch", 5.0)):
        g = rmin_surface(m[n]) - r_mmt
        record("%s keep >= %.0f mm of air to the motor tube" % (n, lim), g >= lim, round(g, 2))

    # ---------- wall thickness
    # outer wall: radial rays that enter at the full OD; thickness to the first exit.
    # Rays within 1 mm of an opening, slot or hole edge are skipped (edge facets).
    thz, tha = np.meshgrid(np.linspace(4, 214, 85), np.radians(np.arange(0, 360, 2.5)))
    org = np.c_[60 * np.cos(tha.ravel()), 60 * np.sin(tha.ravel()), thz.ravel()]
    dirs = -np.c_[np.cos(tha.ravel()), np.sin(tha.ravel()), np.zeros(tha.size)]
    loc, ir, _ = can.ray.intersects_location(org, dirs, multiple_hits=True)

    def enters_at_od(origins):
        # per ray: does its first hit lie on the full OD?
        l2, i2, _ = can.ray.intersects_location(origins, dirs, multiple_hits=False)
        ok = np.zeros(len(origins), bool)
        ok[i2] = np.abs(60 - np.linalg.norm(l2 - origins[i2], axis=1) - p["R_Out"]) <= 0.05
        return ok
    # skip rays that graze an edge: neighbours 1 mm either side must also enter at the OD
    edge_ok = enters_at_od(org - [0, 0, 1.0]) & enters_at_od(org + [0, 0, 1.0])
    thin, n_wall = [], 0
    for i in range(len(org)):
        if not edge_ok[i]:
            continue
        h = np.unique(np.round(np.linalg.norm(loc[ir == i] - org[i], axis=1), 3))
        if len(h) < 2 or abs((60 - h[0]) - p["R_Out"]) > 0.05:
            continue
        n_wall += 1
        if h[1] - h[0] < 2.25:   # 2.4 nominal; 0.05 overlaps at the shaft reliefs
            thin.append((round(math.degrees(tha.ravel()[i]), 1), round(thz.ravel()[i], 1), round(h[1] - h[0], 2)))
    record("outer wall >= 2.25 mm (radial rays entering at the OD)", not thin,
           "%d rays, thin: %s" % (n_wall, thin[:8]))
    # bearing housings: from each seat surface outward, all directions except the crank window
    hz = []
    for xc in (p["Brg_In_X0"] + 2, p["Brg_Out_X1"] - 2):
        for k in (0, 1, 2):
            ang = np.radians(np.arange(0, 360, 10))
            o = np.c_[np.full(ang.size, xc + [-1.5, 0, 1.5][k]), np.zeros(ang.size), np.full(ang.size, Z)]
            d = np.c_[np.zeros(ang.size), np.cos(ang), np.sin(ang)]
            loc, ir, _ = can.ray.intersects_location(o, d, multiple_hits=True)
            for i in range(ang.size):
                h = np.unique(np.round(np.linalg.norm(loc[ir == i] - o[i], axis=1), 3))
                # first hit is the seat bore (r ~4.55, up to 6.5 in the teardrop tip)
                if len(h) >= 2 and 4.4 < h[0] < 6.5:
                    hz.append(h[1] - h[0])
    record("bearing housing walls >= 1.95 mm (2.0 nominal)", min(hz) >= 1.95, round(min(hz), 2))

    # insert pockets: material all round at the manufacturer wall W
    def ring_ok(axis_o, axis_d, depth, r_wall, n_ang=24, n_dep=6):
        axis_d = np.asarray(axis_d, float) / np.linalg.norm(axis_d)
        u = np.cross(axis_d, [0, 0, 1.0])
        if np.linalg.norm(u) < 1e-6:
            u = np.cross(axis_d, [1.0, 0, 0])
        u /= np.linalg.norm(u)
        v = np.cross(axis_d, u)
        pts = []
        for s in np.linspace(0.5, depth - 0.5, n_dep):
            for t_ in np.radians(np.arange(0, 360, 360 / n_ang)):
                pts.append(np.asarray(axis_o) + axis_d * s + r_wall * (np.cos(t_) * u + np.sin(t_) * v))
        return float(np.mean(can.contains(np.array(pts))))
    ra = math.radians(p["Rail_A"])
    rail_o = np.array([p["R_Out"] * math.cos(ra), p["R_Out"] * math.sin(ra), p["Rail_Aft_Z"]])
    rail_d = -np.array([math.cos(ra), math.sin(ra), 0])
    frac = ring_ok(rail_o, rail_d, 8.1, 5.6 / 2 + 2.1 - 0.15)
    record("rail-button insert pocket has 2.1 mm of wall all round (RX-M4x8.1)", frac == 1.0, frac)
    empty = not can.contains([rail_o + rail_d * 4])[0]
    record("rail-button pocket is open on the 60 deg line at the .ork station", empty,
           [p["Rail_A"], p["Rail_Aft_Z"]])
    hs = [float(x) for x in echo_values(logs["FinCan"], "TS_SCREWS").replace("[", " ").replace("]", " ")
          .replace(",", " ").replace("|", " ").split()]
    scr_a, scr_bc = hs[:6], hs[6:]
    th = math.radians(p["Servo_Theta"])
    worst = 1.0
    heads = []
    for k in range(3):
        sc = scr_a if k == 0 else scr_bc
        for i in range(0, len(sc), 2):
            u, z = sc[i], sc[i + 1]
            fa = th - u / p["R_Out"] + math.radians(120 * k)     # radial screw axis
            d = -np.array([math.cos(fa), math.sin(fa), 0])
            o0 = np.array([(p["R_Out"] - 1.6) * math.cos(fa), (p["R_Out"] - 1.6) * math.sin(fa), z])
            worst = min(worst, ring_ok(o0, d, 5.7, 2.0 + 1.6 - 0.15))
            heads.append((math.degrees(fa) % 360, z))
    record("hatch insert pockets have 1.6 mm of wall all round (RX-M3x5.7)", worst == 1.0, worst)
    strip = math.degrees(math.asin((12.7 + 3.0) / p["R_Out"]))   # 1010 rail half width + head
    bad = [h for h in heads if abs(((h[0] - p["Rail_A"] + 180) % 360) - 180) < strip]
    record("no hatch screw head on the rail strip (60 +- %.1f deg)" % strip, not bad,
           [round(h[0], 1) for h in heads])

    # ---------- service: servos (with horns) and the LiPo lift straight out through their hatches.
    # Sector A has the T-shaped servo + LiPo hatch, sector B a gable-topped servo hatch.
    def about_z(deg):
        return trimesh.transformations.rotation_matrix(math.radians(deg), [0, 0, 1])
    for name, parts, sector in (("sector A servo with horn", [m["servo0"], m["horn0"]], 0),
                                ("sector B servo with horn", [m["servo0"], m["horn0"]], 1),
                                ("LiPo", [m["lipo"]], 0)):
        th0 = math.radians(p["Servo_Theta"] + 120 * sector)
        out_dir = np.array([math.cos(th0), math.sin(th0), 0.0])
        body = trimesh.util.concatenate(parts)
        body.apply_transform(about_z(120 * sector))
        stuck = []
        for t_ in np.arange(0.5, 30.1, 0.5):
            b_ = body.copy(); b_.apply_translation(out_dir * t_)
            pieces = b_.split(only_watertight=False)
            if not all(q.is_volume for q in pieces):
                stuck.append((float(t_), "non-volume piece"))
                break
            v = sum(inter(q, can) for q in pieces)
            if v > 1e-3:
                stuck.append((float(t_), round(v, 2)))
        record("%s lifts out through its hatch (0.5-30 mm, no contact)" % name, not stuck, stuck[:4] or "free")

    # ---------- field service of a hinge, fins glued in place: the aileron halves
    # come off sideways (+-Y), then the shaft slides outward until its inner end
    # clears the wall and leaves the notch sideways. Insertion is the reverse.
    blocked = []
    for name, half, sgn in (("screw half", m["ail_m"], -1), ("tapped half", m["ail_p"], 1)):
        for t_ in np.arange(0.5, 12.1, 0.5):
            h1 = half.copy(); h1.apply_translation([0, sgn * t_, 0])
            for n_, B in (("can", can), ("fixed fin", m["fin0"])):
                if inter(h1, B) > 1e-3:
                    blocked.append((name, float(t_), n_))
    shaft0 = m["shaft0"]
    travel = p["R_Out"] + 0.5 - p["Shaft_X0"]
    for t_ in np.arange(0.5, travel + 0.01, 0.5):
        s1 = shaft0.copy(); s1.apply_translation([t_, 0, 0])
        for n_, B in (("can", can), ("fixed fin", m["fin0"])):
            if inter(s1, B) > 1e-3:
                blocked.append(("shaft out", float(t_), n_))
    for t_ in np.arange(0.5, 10.1, 0.5):
        for sgn in (-1, 1):
            s1 = shaft0.copy(); s1.apply_translation([travel, sgn * t_, 0])
            for n_, B in (("can", can), ("fixed fin", m["fin0"])):
                if inter(s1, B) > 1e-3:
                    blocked.append(("shaft sideways", float(t_), n_))
    record("shaft extraction path clear with the fins glued (aileron halves off sideways, shaft out"
           " %.1f mm into the notch, then sideways)" % travel, not blocked, blocked[:4] or "clear")

    # ---------- linkage kinematics and travel
    a_, h_, Lp = p["Crank_A"], p["Horn_R"], p["Pushrod_L"]
    xk, rc, zo, hu = p["Crank_Xk"], p["Servo_Rc"], p["Servo_ZO"], p["Horn_Ball_U"]

    def crank_ball(d):
        d = math.radians(d)
        return np.array([xk, a_ * math.cos(d), Z + a_ * math.sin(d)])

    def horn_ball(phi, fin=0):
        ph = math.radians(phi)
        lx, ly, lz = -h_ * math.cos(ph), -hu, h_ * math.sin(ph)
        t_ = th + math.radians(120 * fin)
        return np.array([(rc + lx) * math.cos(t_) - ly * math.sin(t_),
                         (rc + lx) * math.sin(t_) + ly * math.cos(t_), zo + lz])

    def solve_phi(d):
        f = lambda ph: np.linalg.norm(horn_ball(ph) - crank_ball(d)) - Lp
        return brentq(f, -80, 80) if d != 0 else brentq(f, -30, 30)
    b0, h0 = crank_ball(0), horn_ball(0)
    record("pushrod axial at neutral (balls in line)", np.hypot(*(b0 - h0)[:2]) < 0.05,
           round(float(np.hypot(*(b0 - h0)[:2])), 4))
    fm = p["Flap_Max"]
    defl = sorted({-fm, fm, 0.0, -5.0, 5.0} | {5.0 * k for k in range(-int(fm // 5), int(fm // 5) + 1)})
    phis = {d: solve_phi(d) for d in defl}
    record("servo travel for +-%.0f deg aileron is within +-35 deg" % p["Flap_Max"],
           max(abs(v) for v in phis.values()) <= 35,
           {d: round(v, 2) for d, v in phis.items()})
    gain = (phis[5] - phis[-5]) / 10
    ratio = p["Crank_A"] / p["Horn_R"]
    record("linkage gain near neutral (servo deg per aileron deg) within 5%% of Crank_A/Horn_R = %.2f" % ratio,
           abs(gain - ratio) < 0.05 * ratio, round(gain, 3))

    ax_dir = np.array([-math.sin(th), math.cos(th), 0.0])
    ax_pt = np.array([rc * math.cos(th), rc * math.sin(th), zo])
    stat = m["servo0"]
    worst_flap_can = worst_flap_fin = worst_link = worst_horn = 99.0
    hits = []
    for d in defl:
        R = rot_x(d, Z)
        ail = m["aileron0"].copy(); ail.apply_transform(R)
        crk = m["crank0"].copy(); crk.apply_transform(R)
        hrn = m["horn0"].copy()
        hrn.apply_transform(trimesh.transformations.rotation_matrix(math.radians(phis[d]), ax_dir, ax_pt))
        lnk = capsule(crank_ball(d), horn_ball(phis[d]), 3.5)
        rod = capsule(crank_ball(d) + np.array([0, 0, 4]), horn_ball(phis[d]) - np.array([0, 0, 4]), 1.2)
        for n_, A, B in (("aileron/can", ail, can), ("aileron/fixed fin", ail, m["fin0"]),
                         ("crank/can", crk, can), ("horn/can", hrn, can), ("horn/servo", hrn, stat),
                         ("link/can", lnk, can), ("link/servo", lnk, stat), ("link/covers", lnk, m["covers"]),
                         ("link/lipo", lnk, m["lipo"]), ("rod/crank", rod, crk), ("horn/covers", hrn, m["covers"])):
            v = inter(A, B)
            if v > 1e-3:
                hits.append((d, n_, round(v, 3)))
        worst_flap_can = min(worst_flap_can, min_gap(ail, can))
        worst_flap_fin = min(worst_flap_fin, min_gap(ail, m["fin0"]))
        worst_link = min(worst_link, min_gap(lnk, can, n=1500))
        worst_horn = min(worst_horn, min_gap(hrn, can, n=1500))   # (the horn sits on the servo spline)
    record("aileron travel +-%.0f deg: nothing collides (aileron, crank, pushrod, horn)" % p["Flap_Max"],
           not hits, hits[:6] if hits else len(defl))
    record("aileron to can gap >= 0.78 mm over the travel (0.8 by design)", worst_flap_can >= 0.78,
           round(worst_flap_can, 3))
    record("aileron to fixed fin gap >= 0.78 mm over the travel (0.8 by design)", worst_flap_fin >= 0.78,
           round(worst_flap_fin, 3))
    record("pushrod/ball-link envelope to can gap >= 1.2 mm", worst_link >= 1.2, round(worst_link, 2))
    record("horn (nut as its across-corners circle) to can >= 0.3 mm over the travel",
           worst_horn >= 0.3, round(worst_horn, 2))

    # rail: fins and ailerons at full travel stay off the 1010 rail (25.4 wide, face >= R_Out + 2)
    rail_box = trimesh.creation.box(extents=[40, 25.4, 900])
    T = trimesh.transformations.rotation_matrix(ra, [0, 0, 1])
    T[:3, 3] = [(p["R_Out"] + 2 + 20) * math.cos(ra), (p["R_Out"] + 2 + 20) * math.sin(ra), 0]
    rail_box.apply_transform(T)
    gaps = []
    for d in (-p["Flap_Max"], p["Flap_Max"]):
        for k in range(3):
            one = m["aileron0"].copy(); one.apply_transform(rot_x(d, Z))
            one.apply_transform(trimesh.transformations.rotation_matrix(math.radians(120 * k), [0, 0, 1]))
            gaps.append(min_gap(one, rail_box, n=800))
    gaps.append(min_gap(m["fins"], rail_box, n=3000))
    record("fins and ailerons at full travel stay off the rail", min(gaps) > 10, round(min(gaps), 1))

    # ---------- tail-first landing: the fixed fin reaches further aft than every aileron point
    for fs_, fin_, ail_ in (("Peregrine", m["fin0"], m["aileron0"]), ("Zephyr", m["z_fin0"], m["z_aileron0"])):
        lead = []
        for d in (-p["Flap_Max"], 0, p["Flap_Max"]):
            a1 = ail_.copy(); a1.apply_transform(rot_x(d, Z))
            lead.append(a1.bounds[0, 2] - fin_.bounds[0, 2])
        record("%s: fixed fin reaches >= 3 mm further aft than the aileron at 0 and +-%.0f deg"
               % (fs_, p["Flap_Max"]), min(lead) >= 3.0,
               "fixed fin Z %.1f, aileron lead %s mm" % (fin_.bounds[0, 2], [round(float(x), 1) for x in lead]))

    # ---------- Zephyr fin set
    zh = []
    for d in (-p["Flap_Max"], 0, p["Flap_Max"]):
        ail = m["z_aileron0"].copy(); ail.apply_transform(rot_x(d, Z))
        for n_, B in (("can", can), ("fixed fin", m["z_fin0"])):
            if inter(ail, B) > 1e-3:
                zh.append((d, n_))
    record("Zephyr: ailerons free through the travel (can, fixed fin)", not zh, zh or "ok")
    clear("Zephyr: can clears the fixed fins", can, m["z_fins"])

    # ---------- report
    n_ok = sum(r["passed"] for r in results)
    print("%d/%d checks passed" % (n_ok, len(results)))
    if a.json:
        Path(a.json).write_text(json.dumps({"checks": results, "params": p}, indent=1))
    if a.export and n_ok != len(results):
        print("not exported: checks failed, the committed STLs/DXFs stay as they are")
    elif a.export:
        OUT_STL.mkdir(parents=True, exist_ok=True)
        for n in PRINTS:
            shutil.copy(tmp / (n + ".stl"), OUT_STL / (n + ".stl"))
        for n in DXF:
            shutil.copy(tmp / (n + ".dxf"), OUT_STL / (n + ".dxf"))
        (OUT_STL / "verification.json").write_text(json.dumps({"checks": results, "params": p}, indent=1))
        print("exported to", OUT_STL)
    raise SystemExit(0 if n_ok == len(results) else 1)


if __name__ == "__main__":
    main()
