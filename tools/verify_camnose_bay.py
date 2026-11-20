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
        # ruthex: blind pocket >= L+1 (5.7+1); the design gives L+2 = 7.7.
        insert = cylinder(3.8,7.6,[x,y,262.35])
        clear("floor insert %d has seat pocket" % a,insert,m[3])
        # A solid 1 mm layer must remain below each pocket.
        back = cylinder(3.8,1,[x,y,261.2])
        record("floor insert %d is blind" % a,
               intersection_volume(back,m[3]) > back.volume*0.99)
        head = cylinder(6,2.4,[x,y,274.01])
        clear("floor screw %d head clears carrier" % a,head,m[6])

    for x,y in [(27,0),(-27,0)]:
        clear("tray screw clearance",cylinder(3.2,6.2,[x,y,346.9]),m[7])
        clear("tray insert pocket",cylinder(3.8,7.6,[x,y,339.35]),m[6])
        clear("tray screw tip relief",cylinder(3.2,3.9,[x,y,335.35]),m[6])
        back = cylinder(3.8,1,[x,y,334.2])
        record("tray insert pocket is blind",
               intersection_volume(back,m[6]) > back.volume*0.99)
        # The boss must be fused to the sleeve, not a free-standing post.
        web = box([0.7,4,60],[22.3 if x>0 else -23.0,-2,276])
        record("tray boss is joined to the sleeve wall",
               intersection_volume(web,m[6]) > web.volume*0.99)
        # M3 button head (ISO 7380: 5.7 x 1.65; envelope 6.0 x 1.8) on the
        # screw column, level with the bath rim (Z=353).
        head=cylinder(6.0,1.8,[x,y,353.01])
        clear("tray screw head clears tray",head,m[7])
        clear("tray screw head clears shell",head,m[4])
        clear("tray screw head clears converter",head,converter)
        bearing=trimesh.boolean.difference(
            [cylinder(5.7,0.5,[x,y,352.49]),cylinder(3.6,0.7,[x,y,352.39])],engine="manifold")
        record("tray screw head bears on solid column",
               intersection_volume(bearing,m[7]) > bearing.volume*0.99)
        # The head must also be able to go in: its straight path from
        # above, not only its seated position. The converter may stay in
        # its bath while the tray screws come out for cell access.
        path=cylinder(6.2,20,[x,y,353.01])
        clear("tray screw head insertion path",path,m[7])
        clear("tray screw driver path clears converter",path,converter)

    # The epoxy bath must hold liquid to its rim (Z=353): the empty space
    # below the rim that holds the bath centre must not reach the outside.
    # A leak (e.g. a notch through the end wall) merges it with the open
    # air around the tray, so the component then spans the whole slab.
    slab=box([80,50,2.96],[-40,-25,350.02])
    empty=trimesh.boolean.difference([slab,m[7]],engine="manifold")
    inside=[b for b in empty.split(only_watertight=False)
            if np.all(b.bounds[0][:2] < 0) and np.all(b.bounds[1][:2] > 0)]
    bath=min(inside,key=lambda b:abs(b.volume)) if inside else None
    reach=None if bath is None else [round(float(v),2) for v in np.max(np.abs(bath.bounds[:,:2]),axis=0)]
    record("converter bath is closed below its rim",
           reach is not None and reach[0] < 24.0 and reach[1] < 13.5,
           {"bath_half_extent_xy": reach})

    # Hardware depths from the repository's Schurter drawing, with a
    # conservative 16 mm body/nut envelope behind the flat 6 mm panel.
    def od(z):
        r,l=101.5/2,574.55
        arc=(r*r+l*l)/(2*r)
        return 2*(r-arc+math.sqrt(arc*arc-(z-15)**2))
    face = od(304)/2+0.8
    # Service screws: axis normal to the outer surface where it crosses
    # Z=299.28, 5 mm above part 04's lower edge (Z=294.28).
    zj = 299.28
    tilt = math.atan((od(zj-0.01)-od(zj+0.01))/2/0.02)
    z4 = m[4].bounds[0][2]
    fc,fn=m[4].triangles_center,m[4].face_normals
    for a in [90,210,330]:
        c,s=math.cos(math.radians(a)),math.sin(math.radians(a))
        surf=np.array([od(zj)/2*c,od(zj)/2*s,zj])
        n=np.array([math.cos(tilt)*c,math.cos(tilt)*s,math.sin(tilt)])
        shaft=cylinder(3.2,8,surf+n,-n)
        for p in [3,4]:
            clear("service screw %d clears part %d" % (a,p),shaft,m[p])
        # Countersunk flush: a 90-degree M3 head (6.0 mm) sits below the
        # outer surface, and the insert pocket is L+1 deep or more.
        profile=np.array([[0,0],[1.6,0],[3,1.4],[0,1.4],[0,0]])
        head=trimesh.creation.revolve(profile,sections=96)
        head.apply_transform(trimesh.geometry.align_vectors([0,0,1],n))
        head.apply_translation(surf-1.45*n)
        clear("service screw %d countersunk head" % a,head,m[4])
        # Straight insertion path of the head along its own axis: a seat
        # cut square to a sloping surface leaves a lip that blocks it.
        clear("service screw %d head insertion path" % a,
              cylinder(6.2,20,surf+0.01*n,n),m[4])
        pocket=cylinder(3.8,6.7,surf-2.2*n,-n)
        clear("service insert %d pocket >= L+1" % a,pocket,m[3])
        # Shell left between the hole/seat and 04's free lower edge, read
        # from the mesh: hole and seat faces below the axis face upward;
        # the shell's own skin, bore and edge faces do not.
        radial=fc[:,0]*c+fc[:,1]*s
        tangential=-fc[:,0]*s+fc[:,1]*c
        sel=(np.abs(tangential)<4)&(radial>30)&(fc[:,2]<zj+4)&(fn[:,2]>0.3)
        edge=float(m[4].triangles[sel][:,:,2].min()-z4) if sel.any() else None
        record("service screw %d seat >= 1.5 mm above part 04 lower edge" % a,
               edge is not None and edge >= 1.5,
               None if edge is None else round(edge,3))
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

    # Recovery ribbon slots are T-shaped: 16 x 4 bar plus a 4 mm stem
    # reaching 8 mm toward the axis for a copper guide wire.
    for sy in [-1,1]:
        yb = sy*(94.3/2-4)
        clear("ribbon bar %+d passes bulkhead" % sy,
              box([15,3,6],[-7.5,yb-1.5,-1]),m[1])
        # 2 mm wire gauge; the stem's far end is rounded (R2).
        clear("guide-wire stem %+d passes bulkhead" % sy,
              box([2,7.7,6],[-1,yb-sy*2-(7.7 if sy>0 else 0),-1]),m[1])

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

    # The service insert bosses must not print as floating ledges. Below
    # the insert holes (whose arches are normal bridges) no face of the
    # middle slice may face down flatter than 30 degrees from horizontal.
    n,c,area=m[3].face_normals,m[3].triangles_center,m[3].area_faces
    ledge=((n[:,2]<-math.cos(math.radians(30)))&(c[:,2]>280)&(c[:,2]<296)
           &(np.hypot(c[:,0],c[:,1])>26))
    record("service insert bosses have no floating underside",
           area[ledge].sum()<1,round(float(area[ledge].sum()),2))

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
