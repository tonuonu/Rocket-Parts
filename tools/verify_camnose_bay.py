#!/usr/bin/env python3
"""Check rendered bay solids, hardware access and the full carrier insertion.

Run verify_camnose.py --output-dir DIR first; this consumes those meshes.
Requires numpy, trimesh and manifold3d (tools/requirements-camnose.txt).
Dimensions here are independent default-design acceptance envelopes, not
values read back from the SCAD. This verifies CAD, not printed strength,
gas sealing, battery compatibility, or flight qualification.
"""
import argparse
import itertools
import json
import math
import hashlib
import importlib.metadata
from pathlib import Path
import subprocess
import tempfile

import numpy as np
import trimesh

REPO = Path(__file__).resolve().parents[1]
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
results = []


def record(name, ok, value=None):
    results.append({"check": name, "passed": bool(ok), "value": value})
    print(("PASS " if ok else "FAIL ") + name +
          ("  " + str(value) if value is not None else ""), flush=True)


def intersection_volume(a, b):
    if np.any(a.bounds[1] <= b.bounds[0]) or np.any(b.bounds[1] <= a.bounds[0]):
        return 0.0
    result = trimesh.boolean.intersection([a, b], engine="manifold")
    with np.errstate(divide="ignore", invalid="ignore"):
        return abs(float(result.volume)) if not result.is_empty else 0.0


def clear(name, a, b, tolerance=0.001):
    volume = intersection_volume(a, b)
    record(name, volume < tolerance, round(volume, 6))


def cylinder(d, length, start, axis=(0, 0, 1)):
    direction = np.array(axis, dtype=float)
    direction /= np.linalg.norm(direction)
    transform = trimesh.geometry.align_vectors([0, 0, 1], direction)
    transform[:3, 3] = np.array(start) + direction * length/2
    return trimesh.creation.cylinder(radius=d/2, height=length,
                                    sections=96, transform=transform)


def box(size, corner):
    mesh = trimesh.creation.box(size)
    mesh.apply_translation(np.array(corner)+np.array(size)/2)
    return mesh


def moved(mesh, dz):
    result = mesh.copy()
    result.apply_translation([0, 0, dz])
    return result


def render_probe(folder, name, source):
    scad = folder / (name+".scad")
    out = folder / (name+".stl")
    scad.write_text("include <" + str(REPO / "PeregrineCamNose.scad") + ">\n" + source)
    import os
    result = subprocess.run([OPENSCAD, "-D", "Render_Part=99", "-o", str(out), str(scad)],
                            env=dict(os.environ, OPENSCADPATH=str(REPO)),
                            capture_output=True, text=True, timeout=900)
    errors = result.stdout+result.stderr
    if result.returncode or "ERROR:" in errors or "WARNING:" in errors:
        raise RuntimeError(errors)
    return trimesh.load_mesh(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mesh_dir", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    m = {p: trimesh.load_mesh(args.mesh_dir / ("part%d.stl" % p)) for p in range(8)}
    for p, mesh in m.items():
        record("part %d is watertight" % p, mesh.is_watertight)
        record("part %d has outward winding" % p, mesh.is_volume)
        bodies = len(mesh.split())
        record("part %d is one connected solid" % p, bodies == 1, bodies)

    for a, b in itertools.combinations([3, 4, 6, 7], 2):
        clear("parts %d/%d do not intersect" % (a, b), m[a], m[b])

    cells = [cylinder(18.5, 65, [x,0,276]) for x in [-10.5,10.5]]
    converter = box([47,26,13], [-23.5,-13,350])
    for i, cell in enumerate(cells):
        for p in [3,4,6,7]:
            clear("cell %d clears part %d" % (i,p), cell, m[p])
        # Tab envelopes include 5 mm above, 2 mm below, and radial exits.
        for name, z, h in [("lower tab",274.05,1.90),("upper tab",341,5)]:
            tab = box([5,24,h], [-10.5+21*i-2.5,-12,z])
            for p in [6,7]:
                clear("cell %d %s clears part %d" % (i,name,p),tab,m[p])
    for p in [3,4,6,7]:
        clear("converter clears part %d" % p, converter, m[p])

    # Floor screws must fit BOTH printed parts with the same centre line.
    for a in [30,150,270]:
        x,y = 28*math.cos(math.radians(a)),28*math.sin(math.radians(a))
        shaft = cylinder(3.2,4.2,[x,y,269.9])
        clear("floor screw %d clears carrier" % a,shaft,m[6])
        insert = cylinder(3.8,5.6,[x,y,264.3])
        clear("floor insert %d has seat pocket" % a,insert,m[3])
        # A solid 1 mm layer must remain below each pocket.
        back = cylinder(3.8,1,[x,y,262.9])
        record("floor insert %d is blind" % a,
               intersection_volume(back,m[3]) > back.volume*0.99)
        head = cylinder(6,2.4,[x,y,274.01])
        clear("floor screw %d head clears carrier" % a,head,m[6])

    for x,y in [(27,0),(-27,0)]:
        clear("tray screw clearance",cylinder(3.2,3.1,[x,y,346.9]),m[7])
        clear("tray insert pocket",cylinder(3.8,5.6,[x,y,341.3]),m[6])
        # Flush 90-degree head, 6.0 mm at the top and 3.2 mm at the neck.
        profile=np.array([[0,0],[1.6,0],[3,1.4],[0,1.4],[0,0]])
        head=trimesh.creation.revolve(profile,sections=96)
        head.apply_translation([x,y,348.6])
        clear("tray screw head clears tray",head,m[7])
        clear("tray screw head clears shell",head,m[4])
        clear("tray screw head clears converter",head,converter)

    # Hardware depths from the repository's Schurter drawing, with a
    # conservative 16 mm body/nut envelope behind the flat 6 mm panel.
    def od(z):
        r,l=101.5/2,574.55
        arc=(r*r+l*l)/(2*r)
        return 2*(r-arc+math.sqrt(arc*arc-(z-15)**2))
    face = od(304)/2+0.8
    for a in [90,210,330]:
        c,s=math.cos(math.radians(a)),math.sin(math.radians(a))
        shaft=cylinder(3.2,8,[39*c,39*s,297.785],[-c,-s,0])
        for p in [3,4]:
            clear("service screw %d clears part %d" % (a,p),shaft,m[p])
    switch = cylinder(16,17.5,[0,face-6.01,315],(0,-1,0))
    clear("switch body/nut clears shell",switch,m[4])
    for p in [6,7]:
        clear("switch body/nut clears part %d" % p,switch,m[p])
    for i,cell in enumerate(cells):
        clear("switch body/nut clears cell %d" % i,switch,cell)
    clear("switch round cutout",cylinder(12.55,6.2,[0,face+0.1,315],(0,-1,0)),m[4])
    clear("switch R1.2 key relief",cylinder(2.2,6.2,[0,face+0.1,321.05],(0,-1,0)),m[4])
    charge_face=od(315)/2+0.8
    for x in [-8,0,8]:
        clear("charging screw %d passes panel" % x,
              cylinder(3.2,10,[x,-charge_face-0.1,321],(0,1,0)),m[4])

    with tempfile.TemporaryDirectory() as tmp:
        # A continuous extrusion of the carrier's maximum plan covers every
        # intermediate position, including all the way past the insert
        # bosses. Unlike checking a few translated frames it cannot skip a
        # thin obstacle. Its bottom starts just above the bearing surface.
        sweep=render_probe(Path(tmp),"carrier-sweep",
                           "translate([0,0,270.02]) Bay_Carrier_Plan(h=120);\n")
        clear("continuous carrier insertion path",sweep,m[3])
        remainder=trimesh.boolean.difference([m[6],moved(sweep,-0.03)],engine="manifold")
        with np.errstate(divide="ignore", invalid="ignore"):
            record("insertion sweep encloses the actual carrier",abs(remainder.volume)<0.001)
        blocked=cylinder(64,40,[0,0,270.02])
        record("uncut floor is rejected at joint bosses",intersection_volume(blocked,m[3])>1)

    barrier=cylinder(45,3.9,[0,0,270.05])
    record("floor has a continuous solid centre",
           intersection_volume(barrier,m[6]) > barrier.volume*0.999)

    # Top shell translates upward. Test densely over the entire overlap
    # with the installed bay, including the internal switch envelope.
    for label, moving, fixed in [
        ("shell",m[4],[m[3],m[6],m[7],*cells,converter]),
        ("switch",switch,[m[6],m[7],*cells,converter]),
    ]:
        worst=0.0
        for dz in np.arange(0,80.1,1):
            step=moved(moving,dz)
            for target in fixed:
                worst=max(worst,intersection_volume(step,target))
        record(label+" removal path (1 mm sampling)",worst<0.001,round(worst,6))

    # Prove the collision test can reject an oversized converter.
    too_wide=box([64,26,13],[-32,-13,350])
    record("oversized converter is rejected",intersection_volume(too_wide,m[4])>1)
    failed=sum(not r["passed"] for r in results)
    if args.report:
        sources=["PeregrineCamNose.scad","PeregrineCamBay.scad","NoseCone.scad"]
        report={
            "scope":"Default CAD geometry only; no physical or flight qualification",
            "source_sha256":{name:hashlib.sha256((REPO/name).read_bytes()).hexdigest()
                             for name in sources},
            "mesh_sha256":{f"part{p}.stl":hashlib.sha256((args.mesh_dir/f"part{p}.stl").read_bytes()).hexdigest()
                           for p in m},
            "packages":{name:importlib.metadata.version(name)
                        for name in ["numpy","trimesh","manifold3d","networkx"]},
            "checks":results,"failed":failed,
        }
        args.report.write_text(json.dumps(report,indent=2)+"\n")
    print("\n%d/%d checks passed" % (len(results)-failed,len(results)))
    return bool(failed)


if __name__ == "__main__":
    raise SystemExit(main())
