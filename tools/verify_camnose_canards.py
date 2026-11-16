#!/usr/bin/env python3
"""Render the canard section of PeregrineCamNose and check it as CAD.

Checks: printable parts are closed single solids; Canards_Enabled=false
reproduces the committed shoulder and bottom slice; servos, disc horns,
cassette, canards, slice and shoulder do not intersect; each canard is
free at +-(stop - 0.5 deg) and blocked at +-(stop + 0.5 deg); the
cassette with its servos slides out of the bottom without touching the
slice; every radial screw's centre line is clear through both parts it
joins; the index key reaches into the body tube's wall.

Servo and horn solids are envelopes from the Savox SV-1250MG+ drawing/STEP
(stand-in for the SH-1250MG). This verifies CAD, not printed fits,
strength, sealing or flight behaviour.

Requires numpy, trimesh, manifold3d (tools/requirements-camnose.txt).
Usage: verify_camnose_canards.py [--output-dir DIR] [--json FILE]
"""
import argparse
import hashlib
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
    rf, cas_z, sh_z, sh_r, pocket, cas_floor, cas_top, key_a, key_h, a0, horn_r = chk

    jobs = {"part1": {"Render_Part": 1}, "part2": {"Render_Part": 2},
            "part10": {"Render_Part": 10}, "servos": {"Render_Part": 20},
            "horns": {"Render_Part": 21}, "shoulder_asm": {"Render_Part": 23},
            "part1_off": {"Render_Part": 1, "Canards_Enabled": "false"},
            "part2_off": {"Render_Part": 2, "Canards_Enabled": "false"}}
    for d in (0, stop - 0.5, -(stop - 0.5), stop + 0.5, -(stop + 0.5)):
        jobs["canards_%+.1f" % d] = {"Render_Part": 22, "Canard_View_Defl": d}
    with ThreadPoolExecutor(max_workers=6) as ex:
        done = list(ex.map(lambda kv: render(out_dir, kv[0], kv[1]), jobs.items()))
    m = {name: trimesh.load_mesh(path) for name, path, _ in done}
    m["part9"] = trimesh.load_mesh(out_dir / "part9.stl")

    # printable solids
    for name in ("part1", "part2", "part9", "part10"):
        mesh = m[name]
        record("%s is watertight" % name, mesh.is_watertight)
        record("%s has outward winding" % name, mesh.is_volume)
        bodies = len(mesh.split(only_watertight=False))
        record("%s is one connected solid" % name, bodies == 1, bodies)

    # flag off reproduces the committed (already printed) parts
    for name, stl in (("part1_off", "Shoulder.stl"), ("part2_off", "SliceBottom.stl")):
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
    clear("disc horns clear the slice", horns, slice_)
    clear("disc horns clear the cassette", horns, cas)
    clear("cassette clears the slice", cas, slice_)
    clear("shoulder clears the slice", shoulder, slice_)
    clear("shoulder clears the cassette", shoulder, cas)
    clear("shoulder clears the servos", shoulder, servos)
    clear("canards (neutral) clear the slice", neutral, slice_)
    clear("canards (neutral) clear the servos", neutral, servos)
    clear("canards (neutral) clear the disc horns", neutral, horns, tol=0.01)
    for d in (stop - 0.5, -(stop - 0.5)):
        clear("canards free at %+.1f deg" % d, m["canards_%+.1f" % d], slice_)
    for d in (stop + 0.5, -(stop + 0.5)):
        v = inter(m["canards_%+.1f" % d], slice_)
        record("canards blocked by the stop at %+.1f deg" % d, v > 0.01, round(v, 4))

    # cassette + servos slide out of the bottom (shoulder removed)
    payload = trimesh.util.concatenate([cas, servos])
    worst, worst_d = 0.0, None
    for d in np.arange(0, cas_top + 3, 3.0):
        moved = payload.copy()
        moved.apply_translation([0, 0, -d])
        v = inter(moved, slice_)
        if v > worst:
            worst, worst_d = v, d
    record("cassette with servos slides out of the slice", worst < 1e-3,
           {"worst_mm3": round(worst, 4), "at_drop_mm": worst_d})

    # every screw centre line is free through both parts it joins
    shell_r = 51.5
    for k in range(4):
        a = a0 + 45 + 90 * k
        rod = radial_rod(a, cas_z, shell_r, rf - pocket)
        clear("cassette screw %d line clears the slice" % k, rod, slice_)
        clear("cassette screw %d line clears the cassette" % k, rod, cas)
    for k in range(8):
        a = a0 + 22.5 + 45 * k
        rod = radial_rod(a, sh_z, shell_r, sh_r - pocket)
        clear("shoulder screw %d line clears the slice" % k, rod, slice_)
        clear("shoulder screw %d line clears the shoulder" % k, rod, shoulder)

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
    for name in ("part1", "part2", "part9", "part10"):
        mesh = m[name]
        n, a, tri = mesh.face_normals, mesh.area_faces, mesh.triangles
        sel = (n[:, 2] < -math.sqrt(0.5) - 1e-6) & (tri[:, :, 2].max(axis=1) > mesh.bounds[0][2] + 0.01)
        record("%s overhang area mm2 (informational)" % name, True, round(float(a[sel].sum()), 1))

    # mass input for tools/canard_estimate.py
    vols = {n: round(abs(float(m[n].volume)) / 1000, 3) for n in
            ("part1", "part2", "part9", "part10", "part1_off", "part2_off")}
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
