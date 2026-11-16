#!/usr/bin/env python3
"""Mass and balance point of the complete flight-ready camera/canard nose.

Printed parts are rendered from PeregrineCamNose.scad (manifold backend)
and weighed as solid PETG: volume x 1.27 g/cm3, centroid from the mesh.
Solid is the stated print assumption: 0.2 mm layers, 4 perimeters (1.8 mm
per side), 100% infill for anything thicker. The shells and walls are
<= 3.6 mm, so they print solid anyway; for the few thick blocks this is an
upper bound. Everything else is listed with its source:
  CAD    = volume/centroid from the CAD
  spec   = manufacturer or owner figure
  est    = estimate (my number; weigh it)
Z is the assembled nose coordinate: Z = 0 at the nose base plane = the
forward rim of the forward body tube, + toward the tip.

Usage: nose_mass_cg.py [--mesh-dir DIR] [--json FILE]
Requires numpy, trimesh, manifold3d (tools/requirements-camnose.txt).
"""
import argparse
import json
import subprocess
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import trimesh

REPO = Path(__file__).resolve().parents[1]
SCAD = REPO / "PeregrineCamNose.scad"
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
PETG = 1.27e-3          # g/mm3
TIP_Z = 389.23 + 94.05  # camera flange top + CAD camera nose height
SHOULDER_L = 100.0

PRINTED = {   # name: (Render_Part, extra defines, description, Z offset)
    "01 shoulder (canard version)": (23, {}, 0.0),
    "02 bottom slice (canard version)": (2, {}, 0.0),
    "03 middle slice (ports, USB window)": (3, {}, 0.0),
    "04 top slice + camera flange": (4, {}, 0.0),
    "06 battery carrier": (6, {}, 0.0),
    "07 converter tray": (7, {}, 0.0),
    "09 servo cassette": (9, {}, 0.0),
    "10 canards x4 (assembled)": (22, {}, 0.0),
    "14 Vega mast unit": (14, {}, 0.0),
}


def render(out_dir, name, part, defines):
    out = out_dir / ("p%d.stl" % part)
    if not out.exists():
        cmd = [OPENSCAD, "--backend=manifold", "--render", "-o", str(out),
               "-D", "Render_Part=%d" % part]
        for k, v in defines.items():
            cmd += ["-D", "%s=%s" % (k, v)]
        r = subprocess.run(cmd + [str(SCAD)], capture_output=True, text=True,
                           env={"OPENSCADPATH": str(REPO), "PATH": "/usr/bin:/bin"})
        if r.returncode or "ERROR" in r.stdout + r.stderr:
            raise RuntimeError(r.stdout + r.stderr)
    return name, trimesh.load_mesh(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--mesh-dir", type=Path)
    ap.add_argument("--json", type=Path)
    a = ap.parse_args()
    out_dir = a.mesh_dir or Path(tempfile.mkdtemp(prefix="nosemass-"))
    out_dir.mkdir(parents=True, exist_ok=True)
    jobs = [(n, p, d) for n, (p, d, _) in PRINTED.items()] + [("15 charge well", 15, {})]
    with ThreadPoolExecutor(max_workers=6) as ex:
        meshes = dict(ex.map(lambda j: render(out_dir, *j), jobs))

    items = []   # (name, grams, Z, source)
    for name, mesh in meshes.items():
        g = abs(mesh.volume) * PETG
        z = float(mesh.center_mass[2])
        if name == "15 charge well":
            # bolted under the bulkhead on the facing disc, well opening aft
            h = mesh.bounds[1][2]
            z = -SHOULDER_L - 1.5 - (h - z)
        items.append((name, g, z, "CAD"))

    blob = subprocess.run(["git", "-C", str(REPO), "show",
                           "feature/rocket60:STL Files/Rocket60/NoseCone.stl"],
                          capture_output=True, check=True).stdout
    cam = trimesh.load(trimesh.util.wrap_as_stream(blob), file_type="stl")
    items.append(("camera CAD nose shell (printed)", abs(cam.volume) * PETG,
                  389.23 + float(cam.center_mass[2]), "CAD"))

    B = 270 + 4 + 2            # cell bottom (Bay_Cell_Bottom_Z)
    items += [
        ("camera module, lens, PCB (in the CAD nose)", 15.0, 471.0, "est"),
        ("camera screws 3x M3 + 3 ruthex in the flange", 3.0, 388.0, "est"),
        ("2x Samsung INR18650-25R", 90.0, B + 32.5, "spec"),
        ("DC-DC converter 47x26x13", 20.0, 356.5, "est"),
        ("cell tabs, keeper pads, tray screws/inserts", 6.0, 340.0, "est"),
        ("Schurter 0033.4513 + nut, camera", 6.0, 315.0, "est"),
        ("3 charging-contact screws + nuts", 2.0, 321.0, "est"),
        ("bay service joint 3x M3x8 + 3 ruthex", 3.0, 297.8, "est"),
        ("bay floor 3x M3x8 + 3 ruthex", 3.0, 270.0, "est"),
        ("camera switch -> 7.5 A fuse + holder", 3.0, 290.0, "est"),
        ("CATS Vega", 25.0, 170.0, "spec"),
        ("2S 320 mAh LiPo (Vega)", 20.0, 170.0, "est"),
        ("Vega 3x M3 screws + 3 ruthex", 2.6, 170.0, "est"),
        ("Schurter 0033.4513 + nut, Vega", 6.0, 120.0, "est"),
        ("1000 uF / 16 V capacitor", 3.0, 92.0, "est"),
        ("closed-cell foam ring (roof seal)", 0.6, 88.0, "est"),
        ("mast-unit 4x M3x10 + 4 ruthex", 4.2, 89.5, "est"),
        ("4x MKS HV6160", 4 * 30.7, 60.5, "spec"),
        ("4x aluminium clamp hubs + centre screws", 4 * 2.8, 50.0, "est"),
        ("8x M2x8 countersunk (plug to hub)", 1.6, 50.0, "est"),
        ("8x M2.5x8 + nuts (servo lugs)", 4.4, 60.5, "est"),
        ("cassette 4x M3x8 + 4 ruthex", 3.8, 34.1, "est"),
        ("shoulder joint 12x M3x8 button + 12 ruthex", 12.6, 7.5, "est"),
        ("wiring: servo extensions, pyro, power, switch", 25.0, 150.0, "est"),
        ("epoxy in the glued 02/03 lap", 6.0, 150.0, "est"),
        ("high-temp RTV: slots, posts, facing disc", 6.0, -SHOULDER_L + 2.0, "est"),
        ("4x M3 brass terminal posts + nuts", 4.8, -SHOULDER_L + 3.0, "est"),
        ("facing disc G10 1.5 mm, Ø94.7", 2 * 3.14159 * 47.35 ** 2 / 2 * 1.5 * 1.85e-3,
         -SHOULDER_L - 0.75, "CAD"),
        ("charge-well 2x M3 bolts + nuts", 1.4, -SHOULDER_L - 4.0, "est"),
        ("main charge: BP + e-match", 3.0, -SHOULDER_L - 10.0, "est"),
    ]
    total = sum(i[1] for i in items)
    zcg = sum(i[1] * i[2] for i in items) / total
    print("%-48s %8s %8s  %s" % ("item", "g", "Z mm", "source"))
    for n, g, z, src in items:
        print("%-48s %8.1f %8.1f  %s" % (n, g, z, src))
    print("%-48s %8.1f" % ("TOTAL", total))
    print("Balance point: %.0f mm FORWARD of the forward body-tube rim, %.0f mm aft of the"
          " nose tip (nose length %.1f mm)" % (zcg, TIP_Z - zcg, TIP_Z))
    by = {}
    for n, g, z, src in items:
        by[src] = by.get(src, 0) + g
    print("By source: " + ", ".join("%s %.0f g" % kv for kv in sorted(by.items())))
    if a.json:
        a.json.write_text(json.dumps({"items": [dict(item=n, grams=round(g, 1), z_mm=round(z, 1),
                                                     source=s) for n, g, z, s in items],
                                      "total_g": round(total, 1), "cg_z_mm": round(zcg, 1),
                                      "cg_from_tip_mm": round(TIP_Z - zcg, 1)}, indent=1) + "\n")


if __name__ == "__main__":
    main()
