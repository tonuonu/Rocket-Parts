#!/usr/bin/env python3
"""Dry-mass estimate of the Peregrine L3 airframe (no motor, no nose ballast).

Printed parts are weighed from their CAD: each part is rendered with
OpenSCAD and its STL volume multiplied by material density and an effective
fill fraction (walls are solid, the rest is infill). Tubes, layups and the
nose cone are computed from their dimensions. Bought items are estimates.

Every item carries a low / nominal / high value; the totals feed
tools/l3_motor_survey.py (--dry, and the light/heavy cases).

Usage:
  tools/l3_mass.py
  OPENSCAD=/path/to/openscad tools/l3_mass.py
"""
import math, os, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPENSCAD = os.environ.get("OPENSCAD", "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD")

# Airframe (L3-Design.md §4)
BODY_OD, BODY_ID = 14.01, 13.678   # cm, BT137 (TubesLib.scad)
FINCAN_EXPOSED = 27.5              # cm, outer wall below the coupler
MAIN_L, DROGUE_L = 50.0, 35.0      # cm
NOSE_L, NOSE_SHOULDER_L = 45.0, 8.5
EBAY_L = 20.0
FINS = 4

# Densities, g/cm3
PC, PPS, PETG = 1.20, 1.35, 1.27
BLUE_TUBE = (1.10, 1.30, 1.40)     # OpenRocket "Blue tube" is 1.30
CF_LAMINATE = 1.50                 # wet layup, ~50 % fibre
GF_LAMINATE = 1.85
EPOXY = 1.15


def stl_volume_area(path):
    """Volume (cm3) and surface area (cm2) of an ASCII STL."""
    vol = area = 0.0
    tri = []
    with open(path) as fh:
        for line in fh:
            s = line.split()
            if s and s[0] == "vertex":
                tri.append(tuple(map(float, s[1:4])))
                if len(tri) == 3:
                    a, b, c = tri
                    tri = []
                    vol += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
                            + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6
                    u = [b[i] - a[i] for i in range(3)]
                    w = [c[i] - a[i] for i in range(3)]
                    cr = (u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0])
                    area += math.sqrt(sum(x * x for x in cr)) / 2
    return abs(vol) / 1000, area / 100


def cad(scad, part):
    """Render `part` of `scad` and return (volume cm3, surface cm2)."""
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "part.stl")
        r = subprocess.run([OPENSCAD, "--backend=manifold", "--export-format", "asciistl",
                            "-o", out, "-D", f"Render_Part={part}", os.path.join(REPO, scad)],
                           capture_output=True, text=True, env=dict(os.environ, OPENSCADPATH=REPO))
        if r.returncode or not os.path.exists(out):
            sys.exit(f"render of {scad} part {part} failed:\n{r.stderr[-1500:]}")
        return stl_volume_area(out)


def tube_cm3(od, id_, length):
    return math.pi / 4 * (od * od - id_ * id_) * length


def ogive_surface(r, length, n=400):
    """Lateral area (cm2) of a tangent ogive of base radius r."""
    rho = (r * r + length * length) / (2 * r)
    y = lambda x: math.sqrt(rho * rho - x * x) + r - rho   # x from the base
    a = 0.0
    for i in range(n):
        x0, x1 = length * i / n, length * (i + 1) / n
        y0, y1 = y(x0), y(x1)
        a += math.pi * (y0 + y1) * math.hypot(x1 - x0, y1 - y0)
    return a


def items():
    fc_v, fc_a = cad("PeregrineFinCan75.scad", 0)
    fin_v, fin_a = cad("PeregrineFin75.scad", 0)
    eb_v, _ = cad("PeregrineEBay.scad", 0)            # L2 e-bay, 101.5 mm x 178 mm
    eb_scale = (BODY_OD / 10.15) * (EBAY_L / 17.8)   # wall-dominated: circumference x length

    shell = math.pi * BODY_OD * FINCAN_EXPOSED       # fin can outer surface, cm2
    nose_a = ogive_surface(BODY_OD / 2, NOSE_L)
    tubes = tube_cm3(BODY_OD, BODY_ID, MAIN_L + DROGUE_L)

    g = lambda lo, nom, hi: (lo, nom, hi)
    return [
        ("Fin can, PC", f"CAD {fc_v:.0f} cm3, fill 0.80/0.88/0.95",
         g(*(fc_v * PC * f for f in (0.80, 0.88, 0.95)))),
        ("Fin can GF overwrap + fillets", f"{shell:.0f} cm2, 2 plies 0.2-0.3 mm; 4x2 root fillets",
         g(*(shell * t * GF_LAMINATE + 8 * 24 * 0.2 * EPOXY * k
             for t, k in ((0.04, 0.7), (0.05, 1.0), (0.06, 1.5))))),
        (f"Fin cores x{FINS}, PPS", f"CAD {fin_v:.0f} cm3 each, fill 0.60/0.67/0.75",
         g(*(FINS * fin_v * PPS * f for f in (0.60, 0.67, 0.75)))),
        (f"Fin CF skins x{FINS}", f"{fin_a:.0f} cm2 each, 0.6/0.75/0.9 mm",
         g(*(FINS * fin_a * t * CF_LAMINATE for t in (0.06, 0.075, 0.09)))),
        (f"Fin CF rods x{FINS}", "4 mm + 2 mm rods, ~30 cm", g(24, 30, 36)),
        ("Body tubes, Blue Tube", f"{MAIN_L + DROGUE_L:.0f} cm, {tubes:.0f} cm3",
         g(*(tubes * d for d in BLUE_TUBE))),
        ("E-bay, printed", f"L2 PeregrineEBay {eb_v:.0f} cm3 x{eb_scale:.2f}, PETG",
         g(*(eb_v * eb_scale * PETG * f for f in (0.85, 1.0, 1.2)))),
        ("E-bay contents", "2 altimeters, 2 batteries, 2 switches, wiring, charge wells",
         g(100, 150, 220)),
        ("Nose cone, printed", f"ogive {nose_a:.0f} cm2 x 2.2 mm + shoulder + bulkhead, PETG",
         g(*((nose_a * 0.22 + tube_cm3(BODY_ID - 0.04, BODY_ID - 0.64, NOSE_SHOULDER_L)
              + math.pi / 4 * BODY_ID ** 2 * 0.4) * PETG * f for f in (0.85, 1.0, 1.15)))),
        ("Main chute 60 in", "ripstop nylon", g(200, 260, 340)),
        ("Drogue 24 in", "ripstop nylon", g(40, 60, 80)),
        ("Shock cords", "2 x 9 m, 1 in tubular nylon ~30 g/m", g(400, 540, 650)),
        ("Chute protectors, quick links", "2 Nomex + 4 links", g(150, 190, 240)),
        ("Eyebolts / U-bolts", "nose, e-bay x2 (forged 3/8 in)", g(100, 150, 200)),
        ("Misc", "rail buttons, retainer cup, screws, shear pins, internal epoxy, paint",
         g(200, 300, 400)),
    ]


def main():
    rows = items()
    w = max(len(r[0]) for r in rows)
    print(f"{'item':{w}}  {'low':>5} {'nom':>5} {'high':>5}  basis")
    tot = [0.0, 0.0, 0.0]
    for name, basis, vals in rows:
        for i in range(3):
            tot[i] += vals[i]
        print(f"{name:{w}}  {vals[0]:5.0f} {vals[1]:5.0f} {vals[2]:5.0f}  {basis}")
    print(f"{'Dry mass (no motor, no ballast)':{w}}  {tot[0]:5.0f} {tot[1]:5.0f} {tot[2]:5.0f}")


if __name__ == "__main__":
    main()
