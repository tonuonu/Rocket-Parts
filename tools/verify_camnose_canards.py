#!/usr/bin/env python3
"""Render the canard section of PeregrineCamNose and check it as CAD.

Checks: printable parts are closed single solids; Canards_Enabled=false
reproduces the committed shoulder, bottom and middle slices and carrier; servos, output arms,
cassette, canards, slice and shoulder do not intersect; each canard is
free at +-(stop - 0.5 deg) and blocked at +-(stop + 0.5 deg); the
cassette with its servos, and the Vega mast unit with the board, slide in
from the bottom without touching the slices or the Vega switch; every
radial screw's centre line is clear through both parts it joins; static
ports, the USB window and the camera-floor pass are open; the index key
reaches into the body tube's wall at rail + 45 deg.

18650 cells in the cassette (2026-11-19): the four cell envelopes (with
their top pads) and the cell keeper (part 19) and its screws clear the
shoulder, slices, cassette, servos, arms, mast unit, Vega and the canards
at every checked deflection; the keeper's insert pockets sit in a sound
boss (1.6 mm walls, 1.2 mm cap); the lug-bolt driver lines and nut-insertion
paths stay clear of the cells; the servo switch (drilled into the printed
02, saddle part 12) clears everything inside, stays inside the body-tube
silhouette on the rail side, and does not block the mast unit's insertion;
the roof pass can be reamed to Ø11 without touching the mast. Printed or
unchanged parts (01, 02, 03, 06, 07, 10, 14, 15, 16, 17 and the flag-off
parts) render to exactly the committed triangles.

Servo and arm solids are envelopes from the MKS HV6160 dimension drawing;
lead stub and arm sizes are estimates. This verifies CAD, not printed fits,
strength, sealing or flight behaviour.

Requires numpy, trimesh, manifold3d (tools/requirements-camnose.txt).
Usage: verify_camnose_canards.py [--output-dir DIR] [--json FILE]
"""
import argparse
import hashlib
import struct
import json
import math
import subprocess
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np
import trimesh

REPO = Path(__file__).resolve().parents[1]
SCAD = REPO / "PeregrineCamNose.scad"
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
COMMITTED = REPO / "STL Files" / "PeregrineCamNose"
results = []


def record(name, ok, value=None):
    results.append({"check": name, "passed": bool(ok), "value": value})
    print(("PASS " if ok else "FAIL ") + name +
          ("  " + str(value) if value is not None else ""), flush=True)


def render(out_dir, name, defines):
    out = out_dir / (name + ".stl")
    cmd = [OPENSCAD, "--backend=manifold", "--render", "-o", str(out)]
    for k, v in defines.items():
        cmd += ["-D", "%s=%s" % (k, v)]
    cmd.append(str(SCAD))
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=1800,
                       env={"OPENSCADPATH": str(REPO), "PATH": "/usr/bin:/bin"})
    log = r.stdout + r.stderr
    if r.returncode != 0 or "ERROR" in log or "WARNING" in log or not out.exists():
        raise RuntimeError("render %s failed:\n%s" % (name, log[-3000:]))
    return name, out, log


def stl_vertices(path):
    """Triangle vertices of a binary or ASCII STL as float32 (header and
    normals ignored). OpenSCAD's ASCII digits round-trip to the float32
    values of its binary export."""
    b = Path(path).read_bytes()
    if len(b) >= 84 and len(b) == 84 + 50 * struct.unpack("<I", b[80:84])[0]:
        dt = np.dtype([("n", "<f4", 3), ("v", "<f4", 9), ("a", "<u2")])
        return np.frombuffer(b[84:], dtype=dt)["v"]
    v = [ln.split()[1:] for ln in b.decode().splitlines() if ln.lstrip().startswith("vertex")]
    return np.array(v, dtype=np.float64).astype(np.float32).reshape(-1, 9)


def inter(a, b):
    if np.any(a.bounds[1] <= b.bounds[0]) or np.any(b.bounds[1] <= a.bounds[0]):
        return 0.0
    r = trimesh.boolean.intersection([a, b], engine="manifold")
    return 0.0 if r.is_empty else abs(float(r.volume))


def clear(name, a, b, tol=1e-3):
    v = inter(a, b)
    record(name, v < tol, round(v, 4))


def radial_rod(angle_deg, z, r_out, r_in, d=2.9):
    a = math.radians(angle_deg)
    direction = np.array([math.cos(a), math.sin(a), 0.0])
    length = r_out - r_in
    t = trimesh.geometry.align_vectors([0, 0, 1], direction)
    t[:3, 3] = direction * (r_in + length / 2) + np.array([0, 0, z])
    return trimesh.creation.cylinder(radius=d / 2, height=length, sections=48, transform=t)


def annulus(r0, r1, z0, z1):
    outer = trimesh.creation.cylinder(radius=r1, height=z1 - z0, sections=360)
    inner = trimesh.creation.cylinder(radius=r0, height=z1 - z0 + 1, sections=360)
    ring = trimesh.boolean.difference([outer, inner], engine="manifold")
    ring.apply_translation([0, 0, (z0 + z1) / 2])
    return ring


def echo_values(log, key):
    for line in log.splitlines():
        if key in line:
            return [float(x) for x in line.split(key, 1)[1].strip().strip('"').split()]
    raise RuntimeError("no %s echo" % key)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--output-dir", type=Path)
    ap.add_argument("--json", type=Path,
                    default=COMMITTED / "canard-verification.json")
    args = ap.parse_args()
    out_dir = args.output_dir or Path(tempfile.mkdtemp(prefix="canards-"))
    out_dir.mkdir(parents=True, exist_ok=True)

    # stop angle comes from the SCAD itself
    _, _, log0 = render(out_dir, "part9", {"Render_Part": 9})
    p = echo_values(log0, "CANARD_PARAMS")
    stop = p[7]
    chk = echo_values(log0, "CANARD_CHECK")
    rf, cas_z, sh_z, sh_r, pocket, cas_floor, cas_top, key_a, key_h, a0, plug_x0 = chk
    (vu, vn, vz, roof_z, roof_r, port_z, fpx, fpy, bfz, bft, mast_top,
     rail_a, roof_z0) = echo_values(log0, "CANARD_VEGA")

    jobs = {"part1": {"Render_Part": 1}, "part2": {"Render_Part": 2},
            "part10": {"Render_Part": 10}, "servos": {"Render_Part": 20},
            "part10_arm": {"Render_Part": 10, "Horn_Type": '"arm"'},
            "horns": {"Render_Part": 21}, "shoulder_asm": {"Render_Part": 23},
            "part1_off": {"Render_Part": 1, "Canards_Enabled": "false"},
            "part2_off": {"Render_Part": 2, "Canards_Enabled": "false"},
            "part3": {"Render_Part": 3}, "part6": {"Render_Part": 6},
            "part3_off": {"Render_Part": 3, "Canards_Enabled": "false"},
            "part6_off": {"Render_Part": 6, "Canards_Enabled": "false"},
            "part14": {"Render_Part": 14}, "part15": {"Render_Part": 15},
            "part16": {"Render_Part": 16}, "part17": {"Render_Part": 17},
            "vega": {"Render_Part": 24}, "vswitch": {"Render_Part": 25},
            "part7": {"Render_Part": 7},
            "part7_off": {"Render_Part": 7, "Canards_Enabled": "false"},
            "part12": {"Render_Part": 12}, "part19": {"Render_Part": 19},
            "cells": {"Render_Part": 26}, "kscrews": {"Render_Part": 27},
            "sswitch": {"Render_Part": 28}, "part2_drilled": {"Render_Part": 29}}
    for d in (0, stop - 0.5, -(stop - 0.5), stop + 0.5, -(stop + 0.5)):
        jobs["canards_%+.1f" % d] = {"Render_Part": 22, "Canard_View_Defl": d}
    with ThreadPoolExecutor(max_workers=6) as ex:
        done = list(ex.map(lambda kv: render(out_dir, kv[0], kv[1]), jobs.items()))
    m = {name: trimesh.load_mesh(path) for name, path, _ in done}
    m["part9"] = trimesh.load_mesh(out_dir / "part9.stl")

    # parts that are printed already or must not change: the render gives
    # exactly the committed triangles (STL header and normals ignored)
    for name, stl in (("part1", "Canards/Shoulder.stl"), ("part2", "Canards/SliceBottom.stl"),
                      ("part3", "Canards/SliceMiddle.stl"), ("part6", "Canards/BatteryCarrier.stl"),
                      ("part7", "ConverterTray.stl"), ("part10", "Canards/Canard.stl"),
                      ("part14", "Canards/VegaMast.stl"), ("part15", "Canards/ChargeWell.stl"),
                      ("part16", "Canards/Coupon_Slice.stl"), ("part17", "Canards/Coupon_Shoulder.stl"),
                      ("part1_off", "Shoulder.stl"), ("part2_off", "SliceBottom.stl"),
                      ("part3_off", "SliceMiddle.stl"), ("part6_off", "BatteryCarrier.stl"),
                      ("part7_off", "ConverterTray.stl")):
        a, b = stl_vertices(out_dir / (name + ".stl")), stl_vertices(COMMITTED / stl)
        record("%s triangles identical to committed %s" % (name, stl),
               a.shape == b.shape and np.array_equal(a, b), {"triangles": [len(a), len(b)]})

    # printable solids
    for name in ("part1", "part2", "part3", "part6", "part9", "part10", "part12", "part14",
                 "part15", "part16", "part17", "part19"):
        mesh = m[name]
        record("%s is watertight" % name, mesh.is_watertight)
        record("%s has outward winding" % name, mesh.is_volume)
        bodies = len(mesh.split(only_watertight=False))
        record("%s is one connected solid" % name, bodies == 1, bodies)

    # flag off reproduces the committed (already printed) parts
    for name, stl in (("part1_off", "Shoulder.stl"), ("part2_off", "SliceBottom.stl"),
                      ("part3_off", "SliceMiddle.stl"), ("part6_off", "BatteryCarrier.stl")):
        ref = trimesh.load_mesh(COMMITTED / stl)
        dv = abs(m[name].volume - ref.volume)
        db = float(np.max(np.abs(m[name].bounds - ref.bounds)))
        record("%s matches committed %s (volume)" % (name, stl),
               dv < 1e-4 * ref.volume, round(dv, 4))
        record("%s matches committed %s (bounds)" % (name, stl), db < 0.01, round(db, 4))
        sym = trimesh.boolean.difference([m[name], ref], engine="manifold")
        sym_v = 0.0 if sym.is_empty else abs(float(sym.volume))
        record("%s minus committed %s is empty" % (name, stl), sym_v < 0.05, round(sym_v, 4))

    slice_, cas, servos, horns = m["part2"], m["part9"], m["servos"], m["horns"]
    shoulder = m["shoulder_asm"]
    neutral = m["canards_+0.0"]

    clear("servos clear the cassette", servos, cas)
    clear("servos clear the canard slice", servos, slice_)
    clear("output arms clear the slice", horns, slice_)
    clear("output arms clear the cassette", horns, cas)
    clear("cassette clears the slice", cas, slice_)
    clear("shoulder clears the slice", shoulder, slice_)
    clear("shoulder clears the cassette", shoulder, cas)
    clear("shoulder clears the servos", shoulder, servos)
    clear("canards (neutral) clear the slice", neutral, slice_)
    clear("canards (neutral) clear the servos", neutral, servos)
    clear("canards (neutral) clear the output arms (arm sits in the plug pocket)", neutral, horns, tol=0.01)
    for d in (stop - 0.5, -(stop - 0.5)):
        clear("canards free at %+.1f deg" % d, m["canards_%+.1f" % d], slice_)
    for d in (stop + 0.5, -(stop + 0.5)):
        v = inter(m["canards_%+.1f" % d], slice_)
        record("canards blocked by the stop at %+.1f deg" % d, v > 0.01, round(v, 4))

    # cassette + servos + cells slide out of the bottom (shoulder and keeper off)
    payload = trimesh.util.concatenate([cas, servos, m["cells"]])
    worst, worst_d = 0.0, None
    for d in np.arange(0, cas_top + 3, 3.0):
        moved = payload.copy()
        moved.apply_translation([0, 0, -d])
        v = inter(moved, slice_)
        if v > worst:
            worst, worst_d = v, d
    record("cassette with servos and cells slides out of the slice", worst < 1e-3,
           {"worst_mm3": round(worst, 4), "at_drop_mm": worst_d})

    # every screw centre line is free through both parts it joins
    shell_r = 51.5
    for k in range(4):
        a = a0 + 45 + 90 * k
        rod = radial_rod(a, cas_z, shell_r, rf - pocket)
        clear("cassette screw %d line clears the slice" % k, rod, slice_)
        clear("cassette screw %d line clears the cassette" % k, rod, cas)
    for k in range(4):
        a = a0 + 45 + 90 * k
        rod = radial_rod(a, roof_z, shell_r, roof_r - pocket)
        clear("roof screw %d line clears the slice" % k, rod, slice_)
        clear("roof screw %d line clears the mast unit" % k, rod, m["part14"])
    for k in range(12):
        a = 15 + 30 * k
        rod = radial_rod(a, sh_z, shell_r, sh_r - pocket)
        clear("shoulder screw %d line clears the slice" % k, rod, slice_)
        clear("shoulder screw %d line clears the shoulder" % k, rod, shoulder)

    # servo lug bolts: the M2.5 line through each lug hole and block is clear
    # of servo and cassette, and the near-side wall leaves driver access
    lug = echo_values(log0, "CANARD_LUGS")
    lug_x, lug_zs, y_far = lug[0], lug[1:3], lug[3]
    for k in range(4):
        a = math.radians(a0 + 90 * k)
        rot = trimesh.transformations.rotation_matrix(a, [0, 0, 1])
        for z in lug_zs:
            # nut path: a Ø5.8 rod (across the nut's corners) from the
            # trap's open face out through the quadrant
            for name, d, y0, y1, parts in (("bolt", 2.4, -1.0, y_far, (servos, cas)),
                                           ("driver", 4.5, -30.0, -1.2, (servos, cas, m["cells"])),
                                           ("nut path", 5.8, y_far + 2.45, 30.0,
                                            (servos, cas, m["cells"])),
                                           # M2.5x10 from the lug's near face
                                           # (y=-1) ends at y=9, past the nut
                                           ("M2.5x10 tip", 2.5, y_far + 2.0, 9.0,
                                            (servos, cas, m["cells"]))):
                rod = trimesh.creation.cylinder(radius=d / 2, height=y1 - y0, sections=36)
                rod.apply_transform(trimesh.transformations.rotation_matrix(-math.pi / 2, [1, 0, 0]))
                rod.apply_translation([lug_x, (y0 + y1) / 2, z])
                rod.apply_transform(rot)
                for pn, part in zip(("servos", "cassette", "cells"), parts):
                    clear("servo %d lug at z=%+.1f: %s line clears the %s" % (k, z, name, pn),
                          rod, part)

    # ---- plug-to-hub screws -------------------------------------------
    # M2 countersunk screws, from the head top (flush on the
    # seat) inward: the tip must stay >= 0.3 mm above the hub/arm base (the
    # servo case top is 0.3 below it). The clamp hub's tapped holes need
    # >= 3 mm (1.5 d) of thread; the fallback arm is only 2.5 mm thick, so
    # its engagement is reported, not required.
    logs = {name: log for name, _, log in done}
    for variant, log in (("clamp hub", log0), ("arm", logs["part10_arm"])):
        clamp, length, seat_lo, seat_hi, base, top = echo_values(log, "CANARD_PLUG_SCREWS")
        tip_lo, tip_hi = seat_lo - length, seat_hi - length
        record("plug screw M2x%g tip >= 0.3 mm above the %s base" % (length, variant),
               tip_lo - base >= 0.3, {"tip": round(tip_lo, 2), "base": base})
        engaged = top - max(tip_hi, base)
        if clamp:
            record("plug screw M2x%g engages >= 3 mm of the clamp hub's thread" % length,
                   engaged >= 3.0, {"engagement_mm": round(engaged, 2)})
        else:
            record("plug screw M2x%g engagement in the arm (informational)" % length,
                   True, {"engagement_mm": round(engaged, 2)})
    # The head must reach its seat: the Ø3.8 head envelope, from the seat
    # outward past the skin, is clear of the canard (no lip over the head).
    # Part 10 prints rotated: local radial x -> print Z = x - plug_x0.
    skin_r = p[9]
    for variant, name, log in (("clamp hub", "part10", log0), ("arm", "part10_arm", logs["part10_arm"])):
        seat_lo = echo_values(log, "CANARD_PLUG_SCREWS")[2]
        for r in echo_values(log, "CANARD_PLUG_HOLES"):
            head = trimesh.creation.cylinder(radius=3.8 / 2, height=skin_r + 2 - seat_lo - 0.01, sections=48)
            head.apply_translation([0, r, (seat_lo + 0.01 + skin_r + 2) / 2 - plug_x0])
            clear("plug screw head at r=%+g (%s) has a clear path to its seat" % (r, variant),
                  head, m[name])

    # ---- Vega bay -----------------------------------------------------

    mast, vega, vsw, mid = m["part14"], m["vega"], m["vswitch"], m["part3"]
    # Each Vega standoff ends half-way into the mast flange. Behind
    # that end only the flange (or its tab) can back it: a disc there, in
    # the flange's back half, must be solid part 14. Margin = how far the
    # backing reaches past the standoff footprint (bisection, to 0.01 mm),
    # required >= 0.3. Backed = solid to within 0.001 mm3.
    mst = echo_values(log0, "CANARD_MAST")
    n_front, mast_t, sd = mst[:3]
    holes = list(zip(mst[3::2], mst[4::2]))        # Vega_Holes, STEP x, y
    au = math.radians(a0)
    uhat = np.array([math.cos(au), math.sin(au), 0.0]); nhat = np.array([-math.sin(au), math.cos(au), 0.0])
    n0, n1 = n_front - mast_t + 0.05, n_front - mast_t / 2 - 0.05

    def backing(u, z, d):
        disc = trimesh.creation.cylinder(radius=d / 2, height=n1 - n0, sections=72)
        disc.apply_transform(trimesh.geometry.align_vectors([0, 0, 1], nhat))
        disc.apply_translation(u * uhat + (n0 + n1) / 2 * nhat + np.array([0, 0, z]))
        return inter(disc, mast) >= disc.volume - 1e-3

    for hx, hy in holes:
        u, z = vu - hy, vz - hx
        margin = None                              # footprint itself not backed
        if backing(u, z, sd):
            lo, hi = sd, 40.0
            for _ in range(13):
                mid_d = (lo + hi) / 2
                lo, hi = (mid_d, hi) if backing(u, z, mid_d) else (lo, mid_d)
            margin = round((lo - sd) / 2, 2)
        record("Vega standoff at u=%.1f, Z=%.0f: footprint backed by the mast flange" % (u, z),
               margin is not None and margin >= 0.3, {"margin_mm": margin})
    clear("Vega clears the mast unit", vega, mast, tol=0.01)
    clear("Vega clears slice 02", vega, slice_)
    clear("Vega clears slice 03", vega, mid)
    clear("mast unit clears slice 02", mast, slice_)
    clear("mast unit clears slice 03", mast, mid)
    clear("mast unit clears the cassette", mast, cas)
    clear("mast unit clears the servos", mast, servos)
    clear("Vega switch body clears the Vega", vsw, vega)
    clear("Vega switch body clears the mast unit", vsw, mast)
    clear("Vega switch body clears the cassette", vsw, cas)
    ssw, saddle = m["sswitch"], m["part12"]
    payload = trimesh.util.concatenate([mast, vega])
    worst, worst_d = 0.0, None
    for d in np.arange(0, mast_top + 3, 4.0):
        moved = payload.copy()
        moved.apply_translation([0, 0, -d])
        v = max(inter(moved, slice_), inter(moved, mid), inter(moved, vsw),
                inter(moved, ssw), inter(moved, saddle))
        if v > worst:
            worst, worst_d = v, d
    record("mast unit with the Vega slides in past both slices and both switches",
           worst < 1e-3, {"worst_mm3": round(worst, 4), "at_drop_mm": worst_d})
    for k in range(4):
        a = a0 + 45 + 90 * k
        clear("static port %d open" % k, radial_rod(a, port_z, 50, 40, d=2.0), mid)
    # USB-C axis: from the connector mouth out through the window
    au = math.radians(a0)
    uhat = np.array([math.cos(au), math.sin(au), 0]); nhat = np.array([-math.sin(au), math.cos(au), 0])
    p0 = (vu - 16.5 - 1) * uhat + (vn + 1.15) * nhat + np.array([0, 0, vz - 10.4])
    rod = trimesh.creation.cylinder(radius=2.5, height=14, sections=36)
    rod.apply_transform(trimesh.geometry.align_vectors([0, 0, 1], -uhat))
    rod.apply_translation(p0 - uhat * 7)
    clear("USB-C axis passes the window", rod, mid)
    rod = trimesh.creation.cylinder(radius=1.8, height=bft + 2, sections=24)
    rod.apply_translation([fpx, fpy, bfz + bft / 2])
    clear("servo-power pass open in the camera-bay floor", rod, m["part6"])

    # ---- 18650 cells in the cassette, cell keeper (19), servo switch (12, 28)
    (cell_r, cell_d, cell_z0, cell_z1, pad_t, kz0, kfx, kfy, cfz, pocket_top,
     kboss_top, kscrew_l, khead_d) = echo_values(log0, "CELLS_GEOM")
    (ssw_a, ssw_z, ssw_face_r, bezel_d, bezel_h, pass_u, pass_n, pass_d, ream_d,
     roof_z0b, roof_t, roof_rim_h, body_r) = echo_values(log0, "SSW_GEOM")
    cells, keeper, kscrews = m["cells"], m["part19"], m["kscrews"]
    drilled = m["part2_drilled"]
    deflections = [k for k in m if k.startswith("canards_")]
    for pn, part in (("the cassette", cas), ("slice 02", slice_), ("the shoulder", shoulder),
                     ("the servos", servos), ("the output arms", horns), ("the mast unit", mast),
                     ("the Vega", vega), ("the Vega switch", vsw)):
        clear("cells clear %s" % pn, cells, part, tol=0.01)
    for dk in deflections:
        clear("cells clear the canards at %s deg" % dk.split("_")[1], cells, m[dk])
    clear("cells clear the keeper (rims rest on the seat rings)", cells, keeper, tol=0.01)
    for pn, part in (("the shoulder", shoulder), ("slice 02", slice_), ("the cassette", cas),
                     ("the servos", servos), ("the output arms", horns), ("the mast unit", mast)):
        clear("keeper clears %s" % pn, keeper, part, tol=0.01)
    for dk in deflections:
        clear("keeper clears the canards at %s deg" % dk.split("_")[1], keeper, m[dk])
    for pn, part in (("the shoulder", shoulder), ("the keeper", keeper), ("the cassette", cas),
                     ("the cells", cells), ("the servos", servos)):
        clear("keeper screws clear %s" % pn, kscrews, part, tol=0.01)
    # the keeper's lowest point against the highest shoulder feature under it
    v = shoulder.vertices
    under = v[np.hypot(v[:, 0], v[:, 1]) < 46.0]
    gap = float(keeper.bounds[0][2] - under[:, 2].max())
    record("keeper plate >= 1 mm above the shoulder's insert bosses", gap >= 1.0,
           {"keeper_bottom_z": round(float(keeper.bounds[0][2]), 2),
            "shoulder_top_inside_r46_z": round(float(under[:, 2].max()), 2)})
    # keeper insert pockets: a 1.6 mm wall all round and a 1.2 mm cap, in solid
    for k in range(4):
        a = math.radians(a0 + 90 * k)
        c = np.array([kfx * math.cos(a) - kfy * math.sin(a), kfx * math.sin(a) + kfy * math.cos(a)])
        outer = trimesh.creation.cylinder(radius=2.0 + 1.6, height=pocket_top + 1.2 - (cfz + 0.05),
                                          sections=48)
        outer.apply_translation([c[0], c[1], (pocket_top + 1.2 + cfz + 0.05) / 2])
        inner = trimesh.creation.cylinder(radius=2.0 + 0.02, height=pocket_top + 0.02 - cfz, sections=48)
        inner.apply_translation([c[0], c[1], (pocket_top + 0.02 + cfz) / 2])
        shell = trimesh.boolean.difference([outer, inner], engine="manifold")
        miss = trimesh.boolean.difference([shell, cas], engine="manifold")
        mv = 0.0 if miss.is_empty else abs(float(miss.volume))
        record("keeper insert %d: 1.6 mm wall and 1.2 mm cap are solid" % k, mv < 0.05, round(mv, 4))
        rod = trimesh.creation.cylinder(radius=1.45, height=kscrew_l, sections=36)
        rod.apply_translation([c[0], c[1], kz0 + kscrew_l / 2])
        clear("keeper screw %d line clears the cassette (runs in the pocket)" % k, rod, cas)
        clear("keeper screw %d line clears the shoulder" % k, rod, shoulder)

    # servo switch: body behind the drilled 02 and the saddle, bezel outside
    for pn, part in (("the mast unit", mast), ("the Vega", vega), ("the cassette", cas),
                     ("the cells", cells), ("the servos", servos), ("the output arms", horns),
                     ("the Vega switch", vsw), ("drilled slice 02", drilled),
                     ("the saddle", saddle)):
        clear("servo switch clears %s" % pn, ssw, part, tol=0.01)
    for dk in deflections:
        clear("servo switch clears the canards at %s deg" % dk.split("_")[1], ssw, m[dk])
    clear("saddle clears drilled slice 02 (epoxy gap)", saddle, drilled, tol=0.01)
    clear("saddle clears the mast unit", saddle, mast)
    clear("saddle clears the Vega", saddle, vega)
    rail = np.array([math.cos(math.radians(rail_a)), math.sin(math.radians(rail_a)), 0.0])
    reach = float((ssw.vertices @ rail).max())
    record("servo switch stays inside the body-tube silhouette toward the rail",
           reach < body_r, {"max_toward_rail_mm": round(reach, 2), "body_r": body_r})
    # roof pass reamed Ø9 -> Ø11, from below: the reamer and the leads' bend
    # (15 mm above the roof plate) meet nothing of part 14 but the plate
    au = math.radians(a0)
    pc = pass_u * np.array([math.cos(au), math.sin(au)]) + pass_n * np.array([-math.sin(au), math.cos(au)])
    for z0, z1, what in ((roof_z0b + roof_t + 0.05, roof_z0b + roof_t + 15.0, "within 15 mm above the roof plate"),
                         (roof_z0b - 20.0, roof_z0b - 0.05, "below the roof")):
        rod = trimesh.creation.cylinder(radius=ream_d / 2, height=z1 - z0, sections=48)
        rod.apply_translation([pc[0], pc[1], (z0 + z1) / 2])
        clear("Ø%.0f roof-pass ream clears the mast unit %s" % (ream_d, what), rod, mast)
        clear("Ø%.0f roof-pass ream clears the servo switch %s" % (ream_d, what), rod, ssw)

    # index key reaches into the tube wall annulus (ID 99.1 .. OD 101.5)
    key = trimesh.boolean.intersection(
        [shoulder, annulus(99.1 / 2 + 0.05, 101.5 / 2, -key_h + 1, -0.05)], engine="manifold")
    kv = 0.0 if key.is_empty else abs(float(key.volume))
    ka = None
    if kv > 0:
        c = key.centroid
        ka = round(math.degrees(math.atan2(c[1], c[0])), 2)
    record("index key protrudes into the tube wall", kv > 1.0, {"mm3": round(kv, 2), "angle": ka})
    record("index key at Index_Key_A", ka is not None and abs((ka - key_a + 180) % 360 - 180) < 0.5,
           {"expected": key_a, "measured": ka})

    # overhang screen (informational): downward faces steeper than 45 deg,
    # not on the bed. Horizontal insert holes, the plug-hole crowns and the
    # cassette's upper-ledge bridges are expected here.
    for name in ("part1", "part2", "part9", "part10", "part12", "part14", "part15", "part19"):
        mesh = m[name]
        n, a, tri = mesh.face_normals, mesh.area_faces, mesh.triangles
        sel = (n[:, 2] < -math.sqrt(0.5) - 1e-6) & (tri[:, :, 2].max(axis=1) > mesh.bounds[0][2] + 0.01)
        record("%s overhang area mm2 (informational)" % name, True, round(float(a[sel].sum()), 1))

    # mass input for tools/canard_estimate.py
    vols = {n: round(abs(float(m[n].volume)) / 1000, 3) for n in
            ("part1", "part2", "part3", "part6", "part9", "part10", "part12", "part14", "part15",
             "part19", "part1_off", "part2_off", "part3_off", "part6_off")}
    record("volumes cm3", True, vols)

    failed = [r for r in results if not r["passed"]]
    report = {"tool": "verify_camnose_canards.py",
              "openscad": OPENSCAD, "trimesh": trimesh.__version__,
              "scad_sha256": {f: hashlib.sha256((REPO / f).read_bytes()).hexdigest()
                              for f in ("PeregrineCamNose.scad", "PeregrineCamCanards.scad",
                                        "PeregrineCamBay.scad")},
              "passed": len(results) - len(failed), "failed": len(failed),
              "results": results}
    args.json.write_text(json.dumps(report, indent=1) + "\n")
    print("%d/%d checks passed; report %s" % (len(results) - len(failed), len(results), args.json))
    raise SystemExit(1 if failed else 0)


if __name__ == "__main__":
    main()
