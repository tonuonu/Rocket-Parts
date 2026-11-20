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

Two flight configurations (2026-11-19, 18650 cells in the servo cassette):
  2-cell = servo pair (servos + camera) in the cassette, Vega on its LiPo
  4-cell = servo pair + FC pair in the cassette, no LiPo
The camera-bay sleeves (06) stay empty in both.

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

from rocket60_mesh import rocket60_nose_stl

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
    "12 servo-switch saddle": (12, {}, 0.0),
    "14 Vega mast unit": (14, {}, 0.0),
    "19 cell keeper": (19, {}, 0.0),
}
CONFIGS = ("2-cell", "4-cell")



def render(out_dir, name, part, defines):
    # Always render: a mesh left in --mesh-dir may be from older source.
    out = out_dir / ("p%d.stl" % part)
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

    items = []   # (name, grams, Z, source, configs)
    for name, mesh in meshes.items():
        g = abs(mesh.volume) * PETG
        z = float(mesh.center_mass[2])
        if name == "15 charge well":
            # bolted under the bulkhead on the facing disc, well opening aft
            z = -SHOULDER_L - 1.5 - (z - mesh.bounds[0][2])   # base on the disc
        items.append((name, g, z, "CAD", CONFIGS))

    blob = rocket60_nose_stl()
    cam = trimesh.load(trimesh.util.wrap_as_stream(blob), file_type="stl")
    items.append(("camera CAD nose shell (printed)", abs(cam.volume) * PETG,
                  389.23 + float(cam.center_mass[2]), "CAD", CONFIGS))

    CELL_Z = 18.0 + 65.0 / 2   # cassette cell body Z 18..83
    PACK_Z = 22.0              # series link, fuses, terminals under the floor
    ALL, TWO, FOUR = CONFIGS, ("2-cell",), ("4-cell",)
    items += [(n, g, z, src, ALL) for n, g, z, src in [
        ("camera module, lens, PCB (in the CAD nose)", 15.0, 471.0, "est"),
        ("camera screws 3x M3 + 3 ruthex in the flange", 3.0, 388.0, "est"),
        ("DC-DC converter 47x26x13", 20.0, 356.5, "est"),
        ("keeper pad, tray screws/inserts (camera bay)", 3.0, 340.0, "est"),
        ("Schurter 0033.4513 + nut, camera (camera only)", 6.0, 315.0, "est"),
        ("3 charging-contact screws + nuts (servo pack)", 2.0, 321.0, "est"),
        ("bay service joint 3x M3x8 + 3 ruthex", 3.0, 297.8, "est"),
        ("bay floor 3x M3x8 + 3 ruthex", 3.0, 270.0, "est"),
        ("camera lead 22 AWG pair + 2 A fuse, pack to Z 315", 5.0, 170.0, "est"),
        ("servo pack: 2x Samsung INR18650-25R", 90.0, CELL_Z, "spec"),
        ("servo pack: tabs, leads, series link, C-ring pads", 4.0, CELL_Z, "est"),
        ("servo pack: 7.5 A fuse + holder at the pack", 3.0, PACK_Z, "est"),
        ("servo pack: charge leads to the Z 321 contacts", 4.0, 200.0, "est"),
        ("Schurter 0033.4513 + nut, servo switch", 6.0, 106.0, "est"),
        ("keeper 4x M3x20 countersunk + 4 ruthex", 6.6, 23.0, "est"),
        ("CATS Vega", 25.0, 170.0, "spec"),
        ("Vega 3x M3 screws + 3 ruthex", 2.6, 170.0, "est"),]]
    items += [
        ("2S LiPo (Vega): 2x 362543 290 mAh + series link", 13.5, 170.0, "est", TWO),
        ("FC pack: 2x Samsung INR18650-25R", 90.0, CELL_Z, "spec", FOUR),
        ("FC pack: tabs, leads, series link, C-ring pads", 4.0, CELL_Z, "est", FOUR),
        ("FC pack: 10 A fuse + holder, JST-XH pigtail", 4.0, PACK_Z - 6.0, "est", FOUR),
        ("FC pack: lead up to the Vega switch", 3.0, 100.0, "est", FOUR),
    ]
    items += [(n, g, z, src, ALL) for n, g, z, src in [
        ("Schurter 0033.4513 + nut, Vega", 6.0, 120.0, "est"),
        ("1000 uF / 16 V capacitor", 3.0, 92.0, "est"),
        ("closed-cell foam ring (roof seal)", 0.6, 88.0, "est"),
        ("mast-unit 4x M3x10 + 4 ruthex", 4.2, 89.5, "est"),
        ("4x MKS HV6160", 4 * 30.7, 60.5, "spec"),
        ("4x aluminium clamp hubs + centre screws", 4 * 2.8, 50.0, "est"),
        ("8x M2x8 countersunk (plug to hub)", 1.6, 50.0, "est"),
        ("8x M2.5x10 + nuts (servo lugs)", 5.0, 60.5, "est"),
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
    ]]
    print("%-52s %8s %8s  %-5s %s" % ("item", "g", "Z mm", "src", "configs"))
    for n, g, z, src, cf in items:
        print("%-52s %8.1f %8.1f  %-5s %s" % (n, g, z, src, "all" if cf == CONFIGS else cf[0]))
    out = {"items": [dict(item=n, grams=round(g, 1), z_mm=round(z, 1), source=s, configs=list(cf))
                     for n, g, z, s, cf in items], "configs": {}}
    for cfg in CONFIGS:
        sel = [i for i in items if cfg in i[4]]
        total = sum(i[1] for i in sel)
        zcg = sum(i[1] * i[2] for i in sel) / total
        by = {}
        for n, g, z, src, _ in sel:
            by[src] = by.get(src, 0) + g
        print("%s: TOTAL %.1f g; balance point %.0f mm FORWARD of the forward body-tube rim,"
              " %.0f mm aft of the nose tip (nose length %.1f mm); by source: %s"
              % (cfg, total, zcg, TIP_Z - zcg, TIP_Z,
                 ", ".join("%s %.0f g" % kv for kv in sorted(by.items()))))
        out["configs"][cfg] = {"total_g": round(total, 1), "cg_z_mm": round(zcg, 1),
                               "cg_from_tip_mm": round(TIP_Z - zcg, 1),
                               "by_source_g": {k: round(v, 1) for k, v in by.items()}}
    if a.json:
        a.json.write_text(json.dumps(out, indent=1) + "\n")


if __name__ == "__main__":
    main()
