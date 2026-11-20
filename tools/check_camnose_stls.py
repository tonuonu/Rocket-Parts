#!/usr/bin/env python3
"""Compare every committed STL under STL Files/PeregrineCamNose with a fresh render.

Used by tools/precommit_camnose.sh; see "Pre-commit guard" in
STL Files/PeregrineCamNose/README.md.

  check_camnose_stls.py render-extra OUT_DIR
      Renders the one part the verifiers do not leave behind (Canard_Span20).
  check_camnose_stls.py compare --meshes DIR --canards DIR --extra DIR [--worktree DIR]
      Fails when a committed STL differs from its render. Warns about .3mf
      files (read from --worktree, never modified) whose triangle count
      differs from the STL of the same name.

Tolerance: triangle count exact; volume within 1e-5 relative; bounds within
0.001 mm. The committed STLs and the renders agree to about 4e-7 relative
volume and 1e-5 mm (float32 and ASCII-STL rounding), so these catch any real
feature change (a 0.1 mm wall change moves the volume by 1e-4 or more) while
ignoring the OpenSCAD ASCII/binary export noise.
"""
import argparse
import os
import re
import subprocess
import sys
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
NOSE = "STL Files/PeregrineCamNose"
VOL_REL, BOUNDS_MM = 1e-5, 1e-3

# committed STL (relative to NOSE) -> (render dir, render file)
# canards = verify_camnose_canards.py --output-dir, meshes = verify_camnose.py
# --output-dir (Canards_Enabled=false), extra = render-extra.
MAP = {
    "Canards/Shoulder.stl": ("canards", "part1"),
    "Canards/SliceBottom.stl": ("canards", "part2"),
    "Canards/SliceMiddle.stl": ("canards", "part3"),
    "Canards/BatteryCarrier.stl": ("canards", "part6"),
    "Canards/ServoCassette.stl": ("canards", "part9"),
    "Canards/Canard.stl": ("canards", "part10"),
    "Canards/ServoSwitchSaddle.stl": ("canards", "part12"),
    "Canards/VegaMast.stl": ("canards", "part14"),
    "Canards/ChargeWell.stl": ("canards", "part15"),
    "Canards/Coupon_Slice.stl": ("canards", "part16"),
    "Canards/Coupon_Shoulder.stl": ("canards", "part17"),
    "Canards/CellKeeper.stl": ("canards", "part19"),
    "Canards/Canard_Span20.stl": ("extra", "span20"),
    "Shoulder.stl": ("canards", "part1_off"),
    "SliceBottom.stl": ("canards", "part2_off"),
    "SliceMiddle.stl": ("canards", "part3_off"),
    "BatteryCarrier.stl": ("canards", "part6_off"),
    "ConverterTray.stl": ("canards", "part7_off"),
    "TestRing.stl": ("meshes", "part0"),
    "SliceTop.stl": ("meshes", "part4"),
    "Adapter.stl": ("meshes", "part5"),
}


def render_extra(out):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    cmd = [OPENSCAD, "--backend=manifold", "--render", "-o", str(out / "span20.stl"),
           "-D", "Render_Part=10", "-D", "Canard_Span=20", str(REPO / "PeregrineCamNose.scad")]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=1800,
                       env={"OPENSCADPATH": str(REPO), "PATH": "/usr/bin:/bin"})
    log = r.stdout + r.stderr
    if r.returncode or "ERROR" in log or not (out / "span20.stl").exists():
        print("render span20 failed:\n" + log[-2000:])
        return 1
    return 0


def tri_count_3mf(path):
    n = 0
    with zipfile.ZipFile(path) as z:
        for name in z.namelist():
            if name.endswith(".model"):
                n += len(re.findall(rb"<triangle[ >/]", z.read(name)))
    return n


def compare(a):
    import numpy as np
    import trimesh
    dirs = {"meshes": Path(a.meshes), "canards": Path(a.canards), "extra": Path(a.extra)}
    root = REPO / NOSE
    fails, ok = [], 0
    stls = sorted(p.relative_to(root).as_posix() for p in root.rglob("*.stl"))
    for rel in stls:
        if rel not in MAP:
            fails.append("%s: no render mapping; add it to MAP in tools/check_camnose_stls.py" % rel)
            continue
        d, name = MAP[rel]
        fresh_path = dirs[d] / (name + ".stl")
        if not fresh_path.exists():
            fails.append("%s: fresh render %s missing" % (rel, fresh_path))
            continue
        c = trimesh.load_mesh(root / rel)
        f = trimesh.load_mesh(fresh_path)
        dv = abs(f.volume - c.volume) / abs(c.volume)
        db = float(np.max(np.abs(f.bounds - c.bounds)))
        if len(f.faces) != len(c.faces) or dv > VOL_REL or db > BOUNDS_MM:
            fails.append("%s differs from source render: triangles %d (committed) vs %d, "
                         "volume %+.3g rel, bounds %.4g mm"
                         % (rel, len(c.faces), len(f.faces), dv, db))
        else:
            ok += 1
    for rel in MAP:
        if not (root / rel).exists():
            print("note: mapped STL %s not present" % rel)
    warns = []
    wt = Path(a.worktree) / NOSE if a.worktree else None
    if wt and wt.is_dir():
        for m in sorted(wt.rglob("*.3mf")):
            rel = m.relative_to(wt).with_suffix(".stl").as_posix()
            if rel not in MAP or not (root / rel).exists():
                continue
            try:
                n3, ns = tri_count_3mf(m), len(trimesh.load_mesh(root / rel).faces)
            except Exception as e:  # unreadable project: say so, never fail
                warns.append("%s: cannot read (%s)" % (m.name, e))
                continue
            if n3 != ns:
                warns.append("%s has %d triangles but %s has %d (stale slicer project?)"
                             % (m.relative_to(wt).as_posix(), n3, rel, ns))
    for w in warns:
        print("WARN " + w)
    for f_ in fails:
        print("FAIL " + f_)
    print("STLS %d/%d match fresh render; %d stale .3mf warning(s)" % (ok, len(stls), len(warns)))
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("render-extra")
    r.add_argument("out")
    c = sub.add_parser("compare")
    c.add_argument("--meshes", required=True)
    c.add_argument("--canards", required=True)
    c.add_argument("--extra", required=True)
    c.add_argument("--worktree")
    a = ap.parse_args()
    sys.exit(render_extra(a.out) if a.cmd == "render-extra" else compare(a))


if __name__ == "__main__":
    main()
