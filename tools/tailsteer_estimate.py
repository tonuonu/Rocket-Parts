#!/usr/bin/env python3
"""Hand estimates for the PeregrineTailSteer ailerons, per airframe (Peregrine,
Zephyr): roll authority, hinge moment against servo torque, bearing and
shaft loads, printed-part stresses, servo heating, mass and CG against the
stock fixed-fin aft section, and the stability margin.

Geometry comes from PeregrineTailSteer.scad (its TS_PARAMS echo) and, for
masses, from the STLs in "STL Files/<Airframe>TailSteer/" (run
tools/verify_tailsteer.py --export first). Loads come from the CFD study in
MyLevel1Peregrine (cfd/REPORT.md, results/*.csv) for the fin normal force
slope, and from the airframe's OpenRocket model (tools/ORSimMass.java): the
design point is the fastest motor's max speed at sea-level density
(Peregrine), or Mach 0.8 with Prandtl-Glauert on every load (Zephyr). Rocket
mass, CG and CP are that model's design simulation.

Everything here is an ESTIMATE: strip theory with thin-airfoil flap
effectiveness scaled to the CFD fin lift slope for authority, and 2-D
thin-airfoil hinge moments (no 3-D or viscous relief, so conservative) for
servo and structure sizing.

Usage: tailsteer_estimate.py [--airframe Peregrine|Zephyr] [--fins-csv FILE]
  --fins-csv  writes the fin outline OpenRocket should fly with the tail
              steering (fixed fin + aileron, mm, x aft from the root LE): the
              airframe's fin outline less what the aileron clip removes
"""
import argparse
import math
import shutil
import os
import struct
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
OPENSCAD_DEV = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
OPENSCAD = (os.environ.get("OPENSCAD")
            or (OPENSCAD_DEV if os.path.exists(OPENSCAD_DEV) else shutil.which("openscad")))
STL = REPO / "STL Files" / "PeregrineTailSteer"

# ---- CFD study (MyLevel1Peregrine cfd/results/cfd_cases.csv, drag_stability.csv)
RHO, A_SOUND = 1.225, 340.29
D_REF = 0.1016
A_REF = math.pi * D_REF ** 2 / 4
# Per airframe: the OpenRocket model, its fastest motors (tools/ORSimMass.java, as saved
# and with the tail-steering change), the design motor and the stability inputs.
AIRFRAME = {
    # Max speed of every simulation in PeregrineL2-CamNose.ork (OpenRocket 24.12), as saved
    # and with the tail-steering mass change added (+0.460 kg at 1.531 m from the tip, as a
    # zero-length mass). The highest is the J350; the J420R that L2-PrintSettings.md names
    # reaches 130.0 m/s in the .ork, not the ~200 m/s that file quotes for an earlier,
    # lighter design. Design q uses the J350 as saved (lighter, faster) at sea-level density.
    "Peregrine": dict(
        ork="PeregrineL2-CamNose.ork",
        or_vmax={"J350W": (132.7, 119.7), "J420R": (130.0, 117.1), "HP-J270W": (128.6, None),
                 "I327DM": (106.2, 95.2), "H550ST": (70.6, None)},
        v_design=132.7,
        env_extra=200.0, roll_v=(85.1, 132.7),
        # sim "Langtora Airfield 21 Feb 2026" (J350W)
        or_states={"liftoff": (4.491, 0.968), "max speed / burnout": (4.122, 0.922)},
        or_cp=1.219, cfd_cp=1.262, base_x=1.65168, sim_label="J350",
        canard_net=-0.0030, canard_alone=0.0087,       # canards + fins / canards alone, M 0.25, delta 5 (REPORT.md B)
        or_tab=(92.075, 124.46, 30.0355),              # .ork fin tab: from the root LE, length, depth
        tube_note="kept from the flown tube", compress=False,
        fin_rho=None, fin_name="1/4 in birch ply", fin_G=None, cn_scale=1.0),
    # Zephyr-CamNose.ork (MyLevel1Peregrine): Apogee's RockSim kit with the camera nose, no
    # canards, the fastest H/I of Apogee's list and every 38 mm AeroTech/Cesaroni J. Max
    # speed as saved and with the tail (the mass change folded into the stage override and
    # the fin outline of --fins-csv).
    "Zephyr": dict(
        ork="Zephyr-CamNose.ork",
        # ORSimMass on the .ork as saved (it is the build), J510W; rod exit from tools/or_sim
        or_tail="J510W: max speed 237.4 m/s, CG 0.900 / CP 1.094 m -> 1.91 cal; rod exit 1.07 cal"
                " (8 ft rail, 3 m/s wind); 60 in parachute 6.5 m/s",
        # the .ork models the whole build (tail steering included): (None, max speed); ISA, 8 ft rail
        or_vmax={"J510W": (None, 237.4), "1115J530-15A": (None, 232.4), "J825R": (None, 226.6),
                 "999J600-16A": (None, 222.8), "J570W": (None, 218.5), "634I540-16A": (None, 156.5)},
        design_mach=0.8,              # design point: Mach 0.8 at sea-level pressure, above every motor
        env_extra=None, roll_v=(85.1, 272.2),
        or_states=None,               # no stock model: the .ork is the build itself
        or_cp=1.0935, cfd_cp=1.059, base_x=1.39768, sim_label="J510W",
        canard_net=None, canard_alone=None,            # no canards on this build
        or_tab=(98.425, 124.46, 30.0355),              # Zephyr.rkt fin tab
        tube_note="cut from the kit's slotted tube, above the slots",
        # loads x Prandtl-Glauert at the design Mach (1.67 at M 0.8; the brief's 1.5 is less)
        compress=True,
        # woven 0/90 carbon/epoxy plate: 1.5 g/cm3, in-plane shear modulus ~4 GPa (assumed, typical 3.5-5)
        fin_rho=1.5, fin_name="1/4 in carbon plate", fin_G=4.0e9,
        # the CFD fin CN_alpha is for the kit fin: scaled to the 125 mm fin by Barrowman
        # (fin set with body interference, trapezoid approximation of the kit fin)
        cn_scale=1.171,
        # 38 mm x 609.6 motor tube for 38/1080 J motors up to 584 mm. The kit's slotted ring
        # seals the can at Z 251; the eyebolt ring caps the tube's forward end, in the recovery bay
        mmt_l=609.6, ring_item=("kit slotted ring at Z 251 (seal)", 29.2, 254.0),
        extra=[("kit eyebolt ring + eyebolt at the motor tube's forward end", 29.2 + 25.1, 12.7 + 609.6 - 3.2)],
        stock_pts=[(0, 0), (150.749, 112.852), (223.749, 112.852), (269.494, 12.548),
                   (245.034, 12.548), (228.27, 0)]),
}
V_DESIGN = Q_MAX = OR_STATES = OR_CP = BASE_X = None   # set per airframe in main()
CANARD_NET_PER_DEG = CANARD_ALONE_PER_DEG = None
FACTOR_MIN = 2.0                    # servo margin, bearing C0r/P and shaft factor all >= this
# fin-set normal force at alpha 4 deg minus alpha 0, M 0.25, pitch plane phi = 60
CN_FINS = {"Peregrine": (0.731968 - 0.00956957), "Zephyr": (0.713916 - (-0.00538825))}
ALPHA_DESIGN = 4.0                  # deg, as the CFD incidence cases
ALPHA_MARGIN = 1.5                  # on the CFD fin load
VISCOUS = 0.85                      # flap effectiveness factor (gap, viscous), estimate
# ---- parts
SERVO = dict(name="MKS HV6160", stall_Nm={6.0: 1.422, 7.4: 1.667, 8.4: 1.824}, mass=30.7,
             speed_s60=0.133)       # retailer/servodatabase figures; 8.4 V torque 18.6 kg cm
BEARING = dict(name="NSK 684AZZ", d=4, D=9, B=4, Cr=705.0, C0r=225.0, mass=1.01)
SHAFT_YIELD = 450.0                 # MPa, annealed silver steel 1.2210 (assumed, typical)
PC = dict(rho_solid=1.20, fill=1.0, sigma_in=45.0, sigma_cross=20.0)   # printed PC; the can is walls <= 2.4 mm = all perimeters, so solid
PLY_RHO = 0.725                     # g/cm3, .ork "Aircraft plywood (LOC)"
PAPER_RHO = 1.12129                 # g/cm3, .ork paper
FIN_PTS = {
    "Peregrine": [(0, 0), (50.8, 41.91), (93.98, 76.2), (127.0, 95.25), (152.4, 105.41),
                  (177.8, 111.76), (203.2, 114.3), (228.6, 112.776), (254.0, 107.442),
                  (279.4, 98.552), (304.8, 85.09), (317.5, 76.454), (324.104, 71.12),
                  (324.983, 69.4722), (323.342, 68.326), (304.8, 63.754), (279.4, 49.276),
                  (266.7, 36.576), (259.08, 25.4), (254.0, 15.494), (248.92, 0)],
    "Zephyr": [(0, 0), (167.0, 125.0), (257.0, 125.0), (228.27, 0)],     # Mach 0.8 build (SCAD FinZ_Pts)
}


def scad_params(airframe):
    keys = ("R_Out R_In MMT_OD MMT_Z0 MMT_L Hinge_Z Hinge_X Fin_Base_X Flap_Span Flap_Root_Gap "
            "Flap_Gap Flap_LE_R Shaft_D Shaft_X0 Shaft_X1 Brg_In_X0 Brg_Out_X1 Brg_B Brg_D Crank_A "
            "Horn_R Crank_Xk Servo_Theta Servo_Rc Servo_ZO Pushrod_L Horn_Ball_U Fin_T Can_L Total_H "
            "Rail_A Rail_Aft_Z Tube_Piece_L Ply_CR_Z0 Flap_Max Sw_A Sw_Z Flap_X_Max Fixed_Aft_X "
            "Lipo_Z0 Lipo_L Ball_Off Horn_Arm_T Pin_D Pin_L Clamp_Relief").split()
    stop_keys = ("Stop_On Stop_Contact Stop_Gap Stop_Shelf_Z0 Stop_Shelf_Z1 Stop_Washer_D Stop_Washer_H Stop_Hole_D"
                 " Stop_Shelf_W Stop_Shelf_Arm Horn_Clevis Horn_Strap_T Horn_Screw_L Horn_Strap_X Horn_Strap_Shim"
                 " Horn_Cap_X0 Horn_Cap_X1 Ball_D Horn_Pin_L Link_Eye_W Link_Eye_D").split()
    crank_keys = ("Clevis_Gap Cheek_T Crank_Arm_H Link_Eye_W Crank_Win_Y0 Crank_Hub_R Crank_Arm_W "
                  "Pivot_D Pivot_L Pin_Z0 Web_T Web_Top Shaft_Flat Cheek_T_In").split()
    if not OPENSCAD:
        raise RuntimeError("OpenSCAD not found: set OPENSCAD to its binary")
    p = {}
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "p.echo")
        subprocess.run([OPENSCAD, "-o", out, "-D", "Render_Part=-1", "-D", 'Airframe="%s"' % airframe,
                        str(REPO / "PeregrineTailSteer.scad")], capture_output=True, text=True, check=True)
        for line in open(out):
            for tag, ks in (("TS_PARAMS", keys), ("TS_CRANK", crank_keys), ("TS_STOP", stop_keys)):
                if tag in line:
                    v = [float(x) for x in line.split(tag, 1)[1].strip().strip('"').split()]
                    p.update(zip(ks, v))
    if "R_Out" not in p or "Clevis_Gap" not in p:
        raise RuntimeError("no TS_PARAMS / TS_CRANK echo")
    return p


def crossings(pts, y):
    xs = []
    P = pts + pts[:1]
    for (x1, y1), (x2, y2) in zip(P, P[1:]):
        if (y1 - y) * (y2 - y) < 0:
            xs.append(x1 + (y - y1) * (x2 - x1) / (y2 - y1))
    return sorted(xs)


def area(pts):
    a = 0.0
    P = pts + pts[:1]
    for (x1, y1), (x2, y2) in zip(P, P[1:]):
        a += x1 * y2 - x2 * y1
    return abs(a) / 2


def thin_airfoil(E, alpha, delta, n=6000):
    """2-D thin airfoil, plain flap of chord fraction E. Returns per unit chord and q:
    flap normal force Nf/c, hinge moment H/c^2 (magnitude), tau."""
    th_h = math.acos(2 * E - 1)
    A0 = alpha + delta * (math.pi - th_h) / math.pi
    Nf = Hf = 0.0
    dth = (math.pi - th_h) / n
    for i in range(n):
        th = th_h + (i + 0.5) * dth
        dcp = 4 * (A0 * (1 + math.cos(th)) / math.sin(th) +
                   delta / math.pi * math.log(abs(math.sin((th + th_h) / 2) / math.sin((th - th_h) / 2))))
        x = 0.5 * (1 - math.cos(th))
        dx = 0.5 * math.sin(th) * dth
        Nf += dcp * dx
        Hf += dcp * (x - (1 - E)) * dx
    tau = 1 - (th_h - math.sin(th_h)) / math.pi
    return Nf, Hf, tau


def flap_strips(p, pts, n=120):
    """Strips over the aileron span: y (from the body surface), local fin chord c, flap chord cf."""
    out = []
    y0, y1 = p["Flap_Root_Gap"], p["Flap_Span"]
    for i in range(n):
        y = y0 + (i + 0.5) * (y1 - y0) / n
        xs = crossings(pts, y)
        le, te = xs[0], xs[1]          # first segment: leading edge to trailing edge
        te = min(te, p.get("Flap_X_Max", 1e9))   # the clip removes the fin aft of it (Zephyr)
        cf = te - p["Hinge_X"]
        if cf > 0:
            out.append((y, te - le, cf, (y1 - y0) / n))
    return out


def region_moments(pts, y0, y1, xmin=-1e9, xmax=1e9, n=2000):
    """Area (mm2) and x-centroid of the outline clipped to xmin <= x <= xmax, y0 <= y <= y1."""
    A = Mx = 0.0
    dy = (y1 - y0) / n
    for i in range(n):
        y = y0 + (i + 0.5) * dy
        xs = crossings(pts, y)
        for j in range(0, len(xs) - 1, 2):
            a, b = max(xs[j], xmin), min(xs[j + 1], xmax)
            if b > a:
                A += (b - a) * dy
                Mx += (b - a) * dy * (a + b) / 2
    return A, (Mx / A if A else 0.0)


def render_mass_cg(part, rho, defines=()):
    """Render a Render_Part of PeregrineTailSteer.scad (assembled pose) and return mass, centroid Z."""
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "p.stl")
        extra = [x for d in defines for x in ("-D", d)]
        subprocess.run([OPENSCAD, "--backend=manifold", "--render", "--export-format", "binstl", "-o", out,
                        "-D", "Render_Part=%d" % part, *extra, str(REPO / "PeregrineTailSteer.scad")],
                       capture_output=True, text=True, check=True)
        return stl_mass_cg(out, rho)


def stl_mass_cg(path, rho):
    """Mass (g) and centroid Z (mm) of a binary STL at density rho (g/cm3)."""
    b = Path(path).read_bytes()
    n = struct.unpack("<I", b[80:84])[0]
    vol = cz = 0.0
    for i in range(n):
        o = 84 + 50 * i + 12
        a = struct.unpack("<3f", b[o:o + 12]); bb = struct.unpack("<3f", b[o + 12:o + 24])
        c = struct.unpack("<3f", b[o + 24:o + 36])
        v = (a[0] * (bb[1] * c[2] - bb[2] * c[1]) - a[1] * (bb[0] * c[2] - bb[2] * c[0]) +
             a[2] * (bb[0] * c[1] - bb[1] * c[0])) / 6
        vol += v
        cz += v * (a[2] + bb[2] + c[2]) / 4
    return vol / 1000 * rho, cz / vol


def clip_halfplane(P, inside, cross):
    """Sutherland-Hodgman: clip polygon P by one half-plane (inside(pt) -> bool, cross(a, b) -> point)."""
    out = []
    for i in range(len(P)):
        a_, b_ = P[i - 1], P[i]
        if inside(b_):
            if not inside(a_):
                out.append(cross(a_, b_))
            out.append(b_)
        elif inside(a_):
            out.append(cross(a_, b_))
    return out


def or_outline(p, pts):
    """The fin OpenRocket flies with the tail steering: the fin outline less the part aft of
    Flap_X_Max below the aileron's outer gap (the clip). The aileron's 0.8 mm gaps are left
    closed. Stdlib only: neither airframe's clip bites (the fixed fin's swept trailing edge
    reaches further aft than the aileron), so the outline is returned as is; a future outline
    whose clip does bite needs shapely for the polygon difference."""
    X, Y = p["Flap_X_Max"], p["Flap_Span"] + p["Flap_Gap"]
    q = clip_halfplane(pts, lambda v: v[0] >= X,
                       lambda a, b: (X, a[1] + (X - a[0]) * (b[1] - a[1]) / (b[0] - a[0])))
    q = clip_halfplane(q, lambda v: v[1] <= Y,
                       lambda a, b: (a[0] + (Y - a[1]) * (b[0] - a[0]) / (b[1] - a[1]), Y)) if q else q
    if not q or area(q) < 1e-6:
        return [(round(x, 3), round(y, 3)) for x, y in pts], area(pts)
    from shapely.geometry import Polygon, box        # only when the clip bites
    out = Polygon(pts).difference(box(X, -1, 1000, Y))
    if out.geom_type == "MultiPolygon":             # keep the piece on the root (it holds the root LE)
        out = max(out.geoms, key=lambda g: g.area)
    xy = [(round(x, 3), round(y, 3)) for x, y in list(out.exterior.coords)[:-1]]
    i0 = min(range(len(xy)), key=lambda i: math.hypot(*xy[i]))    # start at the vertex nearest the root LE
    xy = xy[i0:] + xy[:i0]
    if Polygon(xy).exterior.is_ccw != Polygon(pts).exterior.is_ccw:
        xy = [xy[0]] + xy[:0:-1]
    return xy, out.area


def main():
    global V_DESIGN, Q_MAX, OR_STATES, OR_CP, BASE_X, CANARD_NET_PER_DEG, CANARD_ALONE_PER_DEG, STL
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--airframe", default="Peregrine", choices=sorted(AIRFRAME))
    ap.add_argument("--fins-csv")
    ap.add_argument("--stl-dir", help="STLs to weigh (default: the airframe's export folder)")
    a = ap.parse_args()
    fs = a.airframe
    AF = AIRFRAME[fs]
    # design point: Peregrine, the fastest motor's speed at ISA sea level; Zephyr, a Mach number,
    # whose q = 0.7 p M^2 at sea-level pressure holds in any temperature (speeds below are ISA)
    V_DESIGN = AF.get("v_design") or AF["design_mach"] * A_SOUND
    top = sorted(((v[1], k) for k, v in AF["or_vmax"].items() if v[1]), reverse=True)
    saved = {k: v[0] for k, v in AF["or_vmax"].items() if v[0]}
    AF["load_note"] = ("fastest with the tail steering: " + ", ".join(
        "%s %.1f m/s (M %.2f%s)" % (k, v, v / A_SOUND, "; %.1f as saved" % saved[k] if k in saved else "")
        for v, k in top[:3]))
    AF["env_v"] = (top[0][0], AF["env_extra"] or V_DESIGN)
    PG_DESIGN = 1 / math.sqrt(1 - (V_DESIGN / A_SOUND) ** 2) if AF["compress"] else 1.0
    Q_MAX = 0.5 * RHO * V_DESIGN ** 2 * PG_DESIGN      # effective: loads scale with q x PG
    OR_STATES, OR_CP, BASE_X = AF["or_states"], AF["or_cp"], AF["base_x"]
    CANARD_NET_PER_DEG, CANARD_ALONE_PER_DEG = AF["canard_net"], AF["canard_alone"]
    STL = Path(a.stl_dir) if a.stl_dir else REPO / "STL Files" / ("%sTailSteer" % fs)
    p = scad_params(fs)
    pts = FIN_PTS[fs]
    xy, a_or = or_outline(p, pts)
    if a.fins_csv:
        Path(a.fins_csv).write_text("# %s fin with the tail steering, mm (x aft from the root LE, y out)\n" % fs
                                    + "".join("%.3f,%.3f\n" % q for q in xy))
    kit = AF.get("stock_pts", pts)
    print("OpenRocket outline with the tail steering: %.0f mm2 (the airframe's stock fin %.0f mm2, %+.0f mm2)"
          % (a_or, area(kit), a_or - area(kit)))
    R = p["R_Out"]
    S_fin = area(pts)
    cna_fin = CN_FINS[fs] * AF["cn_scale"] / math.radians(ALPHA_DESIGN) / 1.5     # one fin, full incidence, ref A
    cla_own = cna_fin * A_REF / (S_fin * 1e-6)
    k3 = cla_own / (2 * math.pi)
    strips = flap_strips(p, pts)
    Sf = sum(cf * dy for _, _, cf, dy in strips)
    E_all = [cf / c for _, c, cf, _ in strips]
    print("== %s, aileron hinge %.2f mm from the root LE (%.1f mm above the base)" %
          (fs, p["Hinge_X"], p["Hinge_Z"]))
    print("Fin %.0f mm2; aileron %.0f mm2 per fin (%.1f%%), span %.1f-%.1f mm off the body, "
          "chord %.1f-%.1f mm, flap/fin chord %.2f-%.2f" %
          (S_fin, Sf, 100 * Sf / S_fin, p["Flap_Root_Gap"], p["Flap_Span"],
           min(s[2] for s in strips), max(s[2] for s in strips), min(E_all), max(E_all)))
    print("CFD fin CN_alpha: set %.2f /rad (CFD fin) x %.3f (fin scale) = %.2f /rad; one fin %.2f /rad (ref A),"
          " own-area CL_alpha %.2f /rad = %.2f x 2 pi"
          % (CN_FINS[fs] / math.radians(ALPHA_DESIGN), AF["cn_scale"],
             CN_FINS[fs] * AF["cn_scale"] / math.radians(ALPHA_DESIGN), cna_fin, cla_own, k3))

    # ---- roll authority (strip theory)
    num = sum(c * thin_airfoil(cf / c, 0, 1)[2] * (R + y) * dy for y, c, cf, dy in strips)
    cl_d = 3 * 2 * math.pi * k3 * VISCOUS * num * 1e-9 / (A_REF * D_REF)   # per rad
    cl_deg = cl_d * math.pi / 180
    q25 = 0.5 * RHO * (0.25 * A_SOUND) ** 2
    print("\nRoll authority (ESTIMATE: strip theory, thin-airfoil tau x %.2f, scaled to the CFD fin slope):"
          % VISCOUS)
    # magnitude only: the roll sense follows from the CAD deflection sign (README), not from here
    print("  |Cl_delta| = %.4f /deg (3 ailerons, all deflected for roll)" % cl_deg)
    if CANARD_NET_PER_DEG:
        print("  vs canards: net |%.4f| /deg -> %.0fx; canards alone |%.4f| /deg -> %.1fx"
              % (abs(CANARD_NET_PER_DEG), abs(cl_deg / CANARD_NET_PER_DEG),
                 CANARD_ALONE_PER_DEG, cl_deg / CANARD_ALONE_PER_DEG))
    print("  1 deg at M 0.25 (q %.0f Pa): %.3f N m; at the design point: %.3f N m" %
          (q25, cl_deg * q25 * A_REF * D_REF, cl_deg * Q_MAX * A_REF * D_REF))
    print("  at full travel (%g deg): Cl %.3f = %.1fx the fins' own induced roll at 4 deg incidence"
          " (Cl ~0.011, the brief's figure)" % (p["Flap_Max"], cl_deg * p["Flap_Max"], cl_deg * p["Flap_Max"] / 0.011))
    # roll damping of the 3 fins (strip, own-area slope) for a steady-rate scale
    n = 300
    ymax = max(y for _, y in pts)
    damp = 0.0
    for i in range(n):
        y = (i + 0.5) / n * ymax
        xs = crossings(pts, y)
        c = sum(xs[j + 1] - xs[j] for j in range(0, len(xs) - 1, 2))
        damp += 3 * cla_own * c * 1e-3 * ((R + y) * 1e-3) ** 2 * (ymax / n) * 1e-3
    for v in AF["roll_v"]:
        qq = 0.5 * RHO * v * v
        M = cl_d * math.radians(1) * qq * A_REF * D_REF
        pss = M / (0.5 * RHO * v * damp)
        print("  steady roll at %.0f m/s for 1 deg aileron: %.2f rev/s (fin roll damping only)"
              % (v, pss / (2 * math.pi)))

    # ---- hinge moment and flap load (2-D thin airfoil, conservative)
    def loads(delta_deg, alpha_deg):
        dd, al = math.radians(delta_deg), math.radians(alpha_deg)
        H = F = Fy = 0.0
        for y, c, cf, dy in strips:
            E = cf / c
            Nd, Hd, _ = thin_airfoil(E, 0, dd)
            Na, Ha, _ = thin_airfoil(E, al, 0)
            # deflection part 2-D unreduced; incidence part scaled to the CFD 3-D slope
            h = Q_MAX * (c * 1e-3) ** 2 * (abs(Hd) + abs(Ha) * k3)
            f = Q_MAX * (c * 1e-3) * (Nd + Na * k3)
            H += h * dy * 1e-3
            F += f * dy * 1e-3
            Fy += f * dy * 1e-3 * y
        return H, F, Fy / F
    print("\nLoad case (%s): %s. Design q = %.2f kPa at sea level (%.1f m/s, M %.2f)%s."
          % (AF["ork"], AF["load_note"], Q_MAX / PG_DESIGN / 1e3, V_DESIGN, V_DESIGN / A_SOUND,
             "" if PG_DESIGN == 1 else ", x %.2f Prandtl-Glauert = %.1f kPa effective for every load below"
             % (PG_DESIGN, Q_MAX / 1e3)))
    print("Hinge moment and aileron load at q = %.2f kPa, 2-D thin airfoil (conservative):" % (Q_MAX / 1e3))
    chd = [-thin_airfoil(e, 0, 1)[1] / e ** 2 for e in (min(E_all), max(E_all))]
    cha = [-thin_airfoil(e, 1, 0)[1] / e ** 2 for e in (min(E_all), max(E_all))]
    print("  thin-airfoil Ch_delta %.2f to %.2f /rad, Ch_alpha %.2f to %.2f /rad (on the flap chord, c_f/c %.2f-%.2f);"
          " alpha part x %.2f (3-D slope)" % (chd[0], chd[1], cha[0], cha[1], min(E_all), max(E_all), k3))
    worst = None
    for dl, al in ((min(10, p["Flap_Max"]), ALPHA_DESIGN), (p["Flap_Max"], ALPHA_DESIGN * ALPHA_MARGIN)):
        H, F, yc = loads(dl, al)
        Ts = H / (p["Crank_A"] / p["Horn_R"])
        print("  aileron %4.1f deg, alpha %.1f deg: hinge %.3f N m, aileron normal force %.1f N at r %.1f mm"
              " from the axis; servo sees %.3f N m (link %.2f:1)" %
              (dl, al, H, F, yc + R, Ts, p["Crank_A"] / p["Horn_R"]))
        worst = (H, F, yc, Ts, dl, al)
    H, F, yc, Ts, dl, al = worst
    for V, T in SERVO["stall_Nm"].items():
        print("  %s stall %.2f N m at %.1f V -> margin %.1fx" % (SERVO["name"], T, V, T / Ts))
    rate = 60 / SERVO["speed_s60"] / (p["Crank_A"] / p["Horn_R"])
    print("  aileron rate, no load at 8.4 V: %.0f deg/s" % rate)

    # ---- bearing reactions: aileron force F along the fin normal at r = R + yc,
    # pushrod force along Z at the crank ball (x = Crank_Xk); bearings at their centres
    xi = p["Brg_In_X0"] + p["Brg_B"] / 2
    xo = p["Brg_Out_X1"] - p["Brg_B"] / 2
    L = xo - xi
    xf = R + yc
    Fp = H / (p["Crank_A"] * 1e-3)

    def reactions(Fn, Fz, xn, xz):
        # two-support beam along x; loads at xn (normal, y) and xz (axial, z)
        Ro_y = Fn * (xn - xi) / L; Ri_y = Fn - Ro_y
        Ro_z = Fz * (xz - xi) / L; Ri_z = Fz - Ro_z
        return math.hypot(Ro_y, Ro_z), math.hypot(Ri_y, Ri_z)
    Ro, Ri = reactions(F, Fp, xf, p["Crank_Xk"])
    print("\nBearings %s (d %d, D %d, B %d; Cr %.0f N, C0r %.0f N), centres %.2f mm apart:" %
          (BEARING["name"], BEARING["d"], BEARING["D"], BEARING["B"], BEARING["Cr"], BEARING["C0r"], L))
    print("  flight (%.0f deg, alpha %.0f deg): aileron %.1f N at r %.1f, pushrod %.1f N at %.1f mm"
          " along the shaft" % (dl, al, F, xf, Fp, p["Crank_Xk"]))
    print("  outer bearing %.1f N (static factor C0r/P %.1f), inner %.1f N (%.1f); dynamic: oscillation"
          " under +-%g deg, life is not a limit at Cr/P %.1f" %
          (Ro, BEARING["C0r"] / Ro, Ri, BEARING["C0r"] / Ri, p["Flap_Max"], BEARING["Cr"] / Ro))
    # shaft bending at the outer bearing
    Z = math.pi * p["Shaft_D"] ** 3 / 32 * 0.88    # D-flat reduces the section ~12%
    M_out = F * (xf - xo) * 1e-3
    sig = M_out * 1e3 / Z
    print("  shaft %g mm silver steel: bending at the outer bearing %.2f N m -> %.0f MPa"
          " (yield %.0f assumed: factor %.1f)" % (p["Shaft_D"], M_out, sig, SHAFT_YIELD, SHAFT_YIELD / sig))
    # landing / handling: aileron force that yields the shaft, and bearing loads then
    My = SHAFT_YIELD * Z * 1e-3
    Fy_ = My / ((xf - xo) * 1e-3)
    Ro_l, Ri_l = reactions(Fy_, 0, xf, 0)
    print("  landing/handling: the shaft yields at %.0f N on the aileron centre of pressure;"
          " bearings then see %.0f / %.0f N (static factor %.1f / %.1f)" %
          (Fy_, Ro_l, Ri_l, BEARING["C0r"] / Ro_l, BEARING["C0r"] / Ri_l))
    # tail-first landing: aft-most points of the notched fixed fin and of the aileron planform
    aft_fixed = p["Fixed_Aft_X"] - p["Fin_Base_X"]
    aft_flap = 0.0
    for i in range(2001):
        y = p["Flap_Root_Gap"] + i * (p["Flap_Span"] - p["Flap_Root_Gap"]) / 2000
        xs = crossings(pts, y) or [0, 0]
        aft_flap = max(aft_flap, min(xs[1], p["Flap_X_Max"]))
    aft_flap -= p["Fin_Base_X"]
    print("  aft of the base: notched fixed fin %.1f mm, aileron %.1f mm (clipped %.0f mm ahead of the"
          " fixed fin): tail-first, the fixed fin touches first" % (aft_fixed, aft_flap, aft_fixed - aft_flap))

    # ---- printed-part stresses
    print("\nPrinted PC (allowables ~%.0f MPa in-layer, ~%.0f across layers, estimates):" %
          (PC["sigma_in"], PC["sigma_cross"]))
    print("  bearing seats: %.2f MPa outer, %.2f inner (P/(D B)); at shaft yield %.1f / %.1f MPa"
          % tuple(v / (p["Brg_D"] * p["Brg_B"]) for v in (Ro, Ri, Ro_l, Ri_l)))
    web = p["Web_T"] * p["Web_Top"]
    print("  inner housing -> web and motor-tube glue: %.1f N over web %.0f mm2 (%.2f MPa) + glue face"
          % (Ri, web, Ri / web))
    # crank: clevis, pivot ball on a dowel between two cheeks, centred on the
    # pushrod line (no arm torsion); horn: the servo's metal arm with an M2 12.9
    # screw through it as a cantilevered stud
    gap, cheek, arm_h, win0 = p["Clevis_Gap"], p["Cheek_T"], p["Crank_Arm_H"], p["Crank_Win_Y0"]
    arm_w = p["Crank_Arm_W"]
    eye, pin_d, pin_yield = p["Link_Eye_W"], p["Pivot_D"], 1200.0   # hardened dowel (ISO 8734), yield assumed
    pin_eng = (p["Pivot_L"] - gap) / 2             # dowel length in each cheek
    # M2 x 10 12.9 through the horn arm; the ball load acts Ball_Off (CAD) from the arm mid-plane.
    # With the horn clevis cap (Zephyr) the pivot is a Ø2 hardened dowel between the arm and the
    # cap's strap: a clevis pin, bending M = P (L/4 - b/8) over the plates' mid-planes.
    clevis = bool(p.get("Horn_Clevis"))
    stud_minor, stud_yield, stud_arm = 1.57, 1080.0, p["Ball_Off"]
    AL7075 = 500.0                                    # MPa, 7075-T6 yield (arm and cap, assumed)
    if clevis:
        L_cp = p["Ball_Off"] + p["Ball_D"] / 2 + p["Horn_Strap_Shim"] + p["Horn_Strap_T"] / 2

    def horn_stress(Fpp):
        """(pivot stress, its allowable): bending as a stud, or as a clevis pin."""
        if clevis:
            return Fpp * (L_cp / 4 - p["Ball_D"] / 8) / (math.pi * 2.0 ** 3 / 32), 1200.0
        return Fpp * stud_arm / (math.pi * stud_minor ** 3 / 32), stud_yield
    print("  crank (clevis: cheeks %.1f x %.0f at the pivot (inner %.1f elsewhere), Ø%.0f x %.0f dowel, %.1f in each"
          " cheek, eye %.1f; no torsion) and horn stud:"
          % (cheek, arm_h, p["Cheek_T_In"], pin_d, p["Pivot_L"], pin_eng, eye))
    for lab, T_ in (("flight", Ts), ("servo stall 8.4 V", SERVO["stall_Nm"][8.4])):
        Fpp = T_ / (p["Horn_R"] * 1e-3)
        s_cheek = (Fpp / 2) * (p["Crank_A"] - win0) / (cheek * arm_h ** 2 / 6)
        s_root = Fpp * (p["Crank_A"] - p["Crank_Hub_R"]) / (arm_w * arm_h ** 2 / 6)
        L_pin = gap + pin_eng                     # between the cheeks' bearing centres
        s_pin = Fpp * (L_pin / 4 - eye / 8) / (math.pi * pin_d ** 3 / 32)
        s_brg = (Fpp / 2) / (pin_d * pin_eng)
        s_stud, a_stud = horn_stress(Fpp)
        print("    %s: pushrod %.0f N | cheek %.1f MPa (x%.1f) | arm root %.1f MPa (x%.1f) | pin %.0f MPa"
              " (x%.1f) | pin bearing in PC %.1f MPa (x%.1f) | horn pivot %s %.0f MPa (x%.2f)"
              % (lab, Fpp, s_cheek, PC["sigma_in"] / s_cheek, s_root, PC["sigma_in"] / s_root, s_pin,
                 pin_yield / s_pin, s_brg, PC["sigma_in"] / s_brg, "clevis dowel" if clevis else "M2 stud",
                 s_stud, a_stud / s_stud))
    s1, a1 = horn_stress(1.0)
    T_stud = a1 / s1 * p["Horn_R"] * 1e-3            # servo torque at which the horn pivot yields
    if clevis:
        # free body of the clevis cap, no clamping assumed: the dowel loads the arm and the cap's
        # strap with P/2 each (Z) at R. The strap cantilevers from the saddle face (X0); the cap's
        # moment about the cap screw's axis, P/2 (Xc - R), goes into the arm's two edges at the
        # saddle's ends as a couple, plus P/2 on one edge. The cap screw carries no load in the
        # plane (it only keeps the cap on the arm). The arm takes the whole P R at the hub. The load
        # lies in the arm's and the strap's plane, so both bend edgewise: Z = t w^2 / 6.
        Fst = SERVO["stall_Nm"][8.4] / (p["Horn_R"] * 1e-3)
        R_, X0, X1 = p["Horn_R"], p["Horn_Cap_X0"], p["Horn_Cap_X1"]
        Ls = X1 - X0
        s_strap = (Fst / 2 * (X0 - R_)) / (p["Horn_Strap_T"] * 5.0 ** 2 / 6)   # 5 wide (its narrow end)
        M_cap = Fst / 2 * ((X0 + X1) / 2 - R_)
        F_edge = M_cap / Ls + Fst / 2
        s_edge = F_edge / (2.5 * 1.0)                  # on the arm's 2.5 mm edge, over about 1 mm
        s_arm = Fst * R_ / (2.5 * 5.5 ** 2 / 6)         # arm 2.5 thick, 5.5 wide
        s_dw, a_dw = horn_stress(Fst)
        weakest = min((a_dw / s_dw, "the dowel"), (AL7075 / s_arm, "the arm at the hub"), (AL7075 / s_strap, "the strap"))
        T_stud = SERVO["stall_Nm"][8.4] * weakest[0]
        print("    horn clevis cap (7075; Ø2 x %.0f hardened dowel pivot), free body at full stall, pushrod %.0f N:"
              % (p["Horn_Pin_L"], Fst))
        print("      dowel as a clevis pin %.0f MPa (x%.1f) | strap, %.1f mm from the saddle, edgewise, %.0f MPa (x%.1f) |"
              " cap moment %.2f N m into the arm's edges: %.0f N over %.1f mm, %.0f MPa on the edge (x%.1f) |"
              " arm at the hub, edgewise, %.0f MPa (x%.1f) | cap screw: no in-plane load"
              % (s_dw, a_dw / s_dw, X0 - R_, s_strap, AL7075 / s_strap, M_cap / 1e3, F_edge, Ls, s_edge,
                 1.5 * AL7075 / s_edge, s_arm, AL7075 / s_arm))
        print("      the horn yields first at %s, at %.2f N m of servo torque (%.2fx stall)"
              % (weakest[1], T_stud, T_stud / SERVO["stall_Nm"][8.4]))
    else:
        print("    the horn stud (ball %.2f mm off the arm mid-plane) yields at %.2f N m of servo torque"
              " (%.1fx the flight need)" % (stud_arm, T_stud, T_stud / Ts))
    f_stud = T_stud / Ts
    Tlug = SERVO["stall_Nm"][8.4]
    print("  servo lugs: stall reaction %.2f N m over 39 mm -> %.0f N per M2.5 bolt; pedestal bearing"
          " %.1f MPa on the 2 x 8 mm lug face" % (Tlug, Tlug / 0.039, Tlug / 0.039 / (2 * 8) * 1))
    # aileron drive. D-flat alone: the flat is 2 sqrt(r^2 - d^2) wide; a slight rotation loads
    # half of it triangularly, so the resultant acts ~0.9 mm off the axis over a 1.32 mm band,
    # peak = 2 x mean. Dowel drive: Ø2 pin along the chord through the shaft, bearing in the
    # halves with pressure growing linearly from the axis to the pin's aft end.
    ratio = p["Crank_A"] / p["Horn_R"]
    eng = p["Shaft_X1"] - (R + p["Flap_Root_Gap"])
    rs = p["Shaft_D"] / 2
    flat_w = 2 * math.sqrt(rs ** 2 - (rs - p["Shaft_Flat"]) ** 2)
    pin_aft = p["Pin_L"] - p["Pin_Z0"]            # pin length aft of the axis
    k_pin = p["Pin_D"] / pin_aft * ((pin_aft ** 3 - rs ** 3) / 3)   # T = sigma_max * k_pin (from the shaft surface)
    print("  aileron drive (flat %.2f mm wide, %.0f mm engaged; Ø%.0f dowel %.0f mm aft of the axis):"
          % (flat_w, eng, p["Pin_D"], pin_aft))
    cases = [("flight", H)] + ([] if clevis else [("horn-screw yield", T_stud * ratio)]) + \
        [("servo stall 8.4 V", SERVO["stall_Nm"][8.4] * ratio)]
    for lab, T_ in cases:
        s_flat = 2 * (T_ * 1e3 / 0.9) / ((flat_w / 2) * eng)
        s_pinpc = T_ * 1e3 / k_pin
        s_pinsh = (T_ * 1e3 / (2 * (p["Shaft_D"] / 2))) / (math.pi * p["Pin_D"] ** 2 / 4)
        print("    %s, %.2f N m at the aileron: D-flat alone peak %.0f MPa | dowel in PC peak %.0f MPa"
              " (x%.1f) | dowel shear %.0f MPa" % (lab, T_, s_flat, s_pinpc, PC["sigma_in"] / s_pinpc, s_pinsh))
    # shaft torsion (D-flat section ~0.88 of the round), annealed silver steel, shear yield 0.577 x yield
    T_tor = 0.577 * SHAFT_YIELD * math.pi * p["Shaft_D"] ** 3 / 16 * 0.88 * 1e-3
    if clevis:
        print("    the dowel carries the torque; the D-flat and clamp only locate. In a jam at the aileron the"
              " fuse is the 4 mm shaft: it yields in torsion at %.2f N m at the aileron (servo %.2f N m, %.0f%% of"
              " the 8.4 V stall), before the dowel's PC bearing (x%.1f at stall) and every crank part"
              % (T_tor, T_tor / ratio, 100 * T_tor / ratio / SERVO["stall_Nm"][8.4],
                 PC["sigma_in"] / (SERVO["stall_Nm"][8.4] * ratio * 1e3 / k_pin)))
    else:
        print("    the dowel carries the torque; the D-flat and clamp only locate. In a jam the horn screw yields"
              " before the dowel's PC bearing reaches its allowable")
    # aileron as a chordwise cantilever from the shaft, root of the widest strip
    cfmax = max(s[2] for s in strips)
    w = F / (Sf * 1e-6)     # mean pressure
    Mc = w * (cfmax * 1e-3) ** 2 / 2          # per metre of span
    sig_a = Mc * 1e3 / (p["Fin_T"] ** 2 / 6) / 1e3
    print("  aileron plate, chordwise bending at the bore (mean %.1f kPa, %.0f mm chord): %.1f MPa"
          % (w / 1e3, cfmax, sig_a))

    # ---- load envelope: every aero load scales with q
    f_servo = SERVO["stall_Nm"][6.0] / Ts
    f_brg = BEARING["C0r"] / Ro
    f_shaft = SHAFT_YIELD / sig
    f_min = min(f_servo, f_brg, f_shaft, f_stud)
    q_lim = Q_MAX * f_min / FACTOR_MIN
    pg = lambda v: 1 / math.sqrt(1 - (v / A_SOUND) ** 2)
    q_eff = lambda v: 0.5 * RHO * v * v * (pg(v) if AF["compress"] else 1.0)
    print("\nLoad envelope (%g deg, alpha 6 deg; loads scale with q%s):"
          % (p["Flap_Max"], " x Prandtl-Glauert" if AF["compress"] else ""))
    print("  at %.2f kPa%s: servo %.1fx (6.0 V), bearing C0r/P %.1f, shaft %.1f, horn screw %.1f"
          % (Q_MAX / 1e3, " effective" if AF["compress"] else "", f_servo, f_brg, f_shaft, f_stud))
    if AF["compress"]:
        print("  all >= %.1f up to an effective q of %.1f kPa (speed below, with Prandtl-Glauert)"
              % (FACTOR_MIN, q_lim / 1e3))
    else:
        print("  all >= %.1f up to q = %.1f kPa = %.0f m/s at sea level" % (FACTOR_MIN, q_lim / 1e3, math.sqrt(2 * q_lim / RHO)))
    for v in AF["env_v"]:
        k = q_eff(v) / Q_MAX
        print("  at %.0f m/s (q %.1f kPa%s): servo %.1fx, C0r/P %.1f, shaft %.1f, horn screw %.1f"
              % (v, 0.5 * RHO * v * v / 1e3, ", M %.2f" % (v / A_SOUND) if AF["compress"] else "",
                 f_servo / k, f_brg / k, f_shaft / k, f_stud / k))
    # compressibility: Prandtl-Glauert scales every aero load by 1/sqrt(1 - M^2)
    if not AF["compress"]:
        print("  with Prandtl-Glauert (loads x 1/sqrt(1 - M^2)): at the design %.1f m/s (M %.2f, x %.2f) servo %.1fx,"
              " C0r/P %.1f, shaft %.1f, horn screw %.1f" % (V_DESIGN, V_DESIGN / A_SOUND, pg(V_DESIGN),
              f_servo / pg(V_DESIGN), f_brg / pg(V_DESIGN), f_shaft / pg(V_DESIGN), f_stud / pg(V_DESIGN)))
    lo, hi = 1.0, A_SOUND * 0.95
    for _ in range(60):
        v = (lo + hi) / 2
        if f_min * Q_MAX / (0.5 * RHO * v * v) / pg(v) >= FACTOR_MIN:
            lo = v
        else:
            hi = v
    a_cold = math.sqrt(1.4 * 287.05 * 268.15)      # a -5 C day (the Langtora February sims' base)
    print("  all >= %.1f with Prandtl-Glauert up to M %.2f = %.0f m/s at ISA sea level, %.0f m/s on a -5 C day"
          " (q %.1f kPa at sea-level pressure)" % (FACTOR_MIN, lo / A_SOUND, lo, lo / A_SOUND * a_cold,
                                                   0.5 * RHO * lo * lo / 1e3))

    # ---- mechanical travel stop (Zephyr): nut-and-washer stacks on the pushrod either side of a
    # shelf on the servo bay's fin-side web. The stop reaction goes from the rod into the can, so
    # the crank, shaft, bearings and aileron carry only the aero load at the stop angle.
    if p.get("Stop_On"):
        a_s = p["Stop_Contact"]
        ratio_s = p["Crank_A"] / p["Horn_R"]
        H_s, F_s, yc_s = loads(a_s, ALPHA_DESIGN * ALPHA_MARGIN)
        Fp_s = H_s / (p["Crank_A"] * 1e-3)
        Ro_s, Ri_s = reactions(F_s, Fp_s, R + yc_s, p["Crank_Xk"])
        sig_s = F_s * (R + yc_s - xo) * 1e-3 * 1e3 / Z
        print("\nTravel stop at +-%.1f deg of aileron (pushrod stacks %.2f mm off a %.0f mm shelf at Z %.0f-%.0f):"
              % (a_s, p["Stop_Gap"], p["Stop_Shelf_Z1"] - p["Stop_Shelf_Z0"], p["Stop_Shelf_Z0"], p["Stop_Shelf_Z1"]))
        print("  shaft and bearings at the stop angle, alpha 6 deg, %.1f kPa effective (aero %.1f N at r %.1f +"
              " pushrod %.1f N; the stop reaction stays in the rod and the can):" % (Q_MAX / 1e3, F_s, R + yc_s, Fp_s))
        print("    outer bearing %.1f N (C0r/P %.1f), inner %.1f N (%.1f); shaft %.0f MPa (factor %.1f); servo %.1fx"
              % (Ro_s, BEARING["C0r"] / Ro_s, Ri_s, BEARING["C0r"] / Ri_s, sig_s, SHAFT_YIELD / sig_s,
                 SERVO["stall_Nm"][6.0] / (H_s / ratio_s)))
        w_, t_, arm_ = p["Stop_Shelf_W"], p["Stop_Shelf_Z1"] - p["Stop_Shelf_Z0"], p["Stop_Shelf_Arm"]
        a_w = math.pi * ((p["Stop_Washer_D"] / 2) ** 2 - (p["Stop_Hole_D"] / 2) ** 2)
        d_root = 1.6                                   # M2 thread root
        L_b = p["Servo_ZO"] - (p["Stop_Shelf_Z1"] + p["Stop_Gap"] + p["Stop_Washer_H"])   # upper stack to the horn ball
        P_cr = math.pi ** 2 * 200e3 * (math.pi * d_root ** 4 / 64) / L_b ** 2
        Fr = SERVO["stall_Nm"][8.4] / (p["Horn_R"] * 1e-3)
        s_sh = Fr * arm_ * 6 / (w_ * t_ ** 2)          # as a cantilever from the nearer corbel (conservative)
        s_pv, a_pv = horn_stress(Fr)
        print("  stop path at full servo stall (8.4 V, rod %.0f N), factor >= 1.5 wanted:" % Fr)
        print("    shelf %.1f MPa (x%.1f, PC in-layer; %.0f x %.0f section, %.1f mm from the corbel) | washer on the PC"
              " %.1f MPa | M2 rod tension %.0f MPa (x%.1f, A2-70) | compression vs Euler %.0f N over %.1f mm (x%.1f)"
              " | horn pivot %.0f MPa (x%.1f)"
              % (s_sh, PC["sigma_in"] / s_sh, w_, t_, arm_, Fr / a_w, Fr / (math.pi * d_root ** 2 / 4),
                 450 / (Fr / (math.pi * d_root ** 2 / 4)), P_cr, L_b, P_cr / Fr, s_pv, a_pv / s_pv))
        print("    the horn-end ball link must hold %.0f N (x1.5 on stall): metal-body links, pull-tested" % (1.5 * Fr))
        print("  crank, shaft, bearings and aileron: aero only at the stop (above)")

    # ---- flutter, rough. Panel flutter by the NACA TN 4197 fin formula (as used in
    # Apogee's flutter calculator) for the aileron and the fixed fin, and the
    # aileron's hinge-mode frequency on an assumed linkage stiffness.
    def tn4197(G, span, area, cr, ct, t):
        ar = span ** 2 / area
        lam = ct / cr
        tc = t / (area / span)
        den = 1.337 * ar ** 3 * 101325 * (lam + 1) / (2 * (ar + 2) * tc ** 3)
        return A_SOUND * math.sqrt(G / den)
    cfs = [s_[2] for s_ in strips]
    span_a = p["Flap_Span"] - p["Flap_Root_Gap"]
    v_ail = tn4197(0.6e9, span_a, Sf, cfs[0], cfs[-1], p["Fin_T"])
    ymax_f = max(y for _, y in pts)
    cr_f = crossings(pts, 0.5)[-1] - crossings(pts, 0.5)[0]
    xt_ = crossings(pts, ymax_f - 0.5)
    taper = (xt_[-1] - xt_[0]) / cr_f if AF["fin_G"] else 0.3
    v_fin = tn4197(AF["fin_G"] or 0.38e9, ymax_f, S_fin - Sf, cr_f, taper * cr_f, p["Fin_T"])
    rho_pc = PC["rho_solid"] * 1e3
    I_h = sum(rho_pc * (p["Fin_T"] * 1e-3) * (dy * 1e-3) * ((cf * 1e-3) ** 3 / 3) for _, _, cf, dy in strips)
    k_servo = SERVO["stall_Nm"][7.4] / math.radians(3.0)     # holds full torque within ~3 deg (assumed)
    k_h = k_servo * (p["Crank_A"] / p["Horn_R"]) ** 2
    f_h = math.sqrt(k_h / I_h) / (2 * math.pi)
    print("\nFlutter (rough):")
    print("  aileron panel, NACA TN 4197 (printed PC, G 0.6 GPa assumed): %.0f m/s" % v_ail)
    if AF["fin_G"]:
        print("  fixed fin, NACA TN 4197 (%s, G %.1f GPa assumed, taper %.2f, sea level): %.0f m/s = %.1fx the design %.0f m/s"
              % (AF["fin_name"], AF["fin_G"] / 1e9, taper, v_fin, v_fin / V_DESIGN, V_DESIGN))
    else:
        print("  fixed fin, NACA TN 4197 (birch ply, G 0.38 GPa, taper 0.3 assumed): %.0f m/s" % v_fin)
    print("  aileron hinge mode: I %.1e kg m2 about the hinge, linkage %.0f N m/rad (servo holds full torque"
          " within 3 deg, assumed) -> %.0f Hz; not mass-balanced" % (I_h, k_h, f_h))

    # ---- thermal
    print("\nServo and LiPo heating (lumped, assumptions in the README):")
    sb = 5.67e-8
    # faces toward the motor tube: servo 33 x 35.2 (L x H), LiPo 61 x 15 (length x width along u)
    # gap to the floor plate (CAD): servo inner face at lx -5, floor at -7.5; LiPo 0.3 off the floor
    for name, A_face, m_g, c_, gap_f in (("servo", 33 * 35.2e-6, 30.7, 0.9, 2.5e-3),
                                         ("LiPo", 61 * 15e-6, 28.0, 1.0, 0.3e-3)):
        T = 303.0
        Tw = 303.0
        cw = 1.6e-3 * A_face * 1200 * 1250   # floor plate behind it: m3 x kg/m3 x J/(kg K) = J/K
        dt = 0.05
        hist = {}
        for step in range(int(600 / dt) + 1):
            t = step * dt
            Tm = 303.0 + 70.0 * min(1.0, t / 30.0)    # motor tube outer surface: 100 C after 30 s
            q1 = A_face * (sb * 0.9 * (Tm ** 4 - Tw ** 4) + 0.026 / 8e-3 * (Tm - Tw))
            q2 = A_face * (sb * 0.9 * (Tw ** 4 - T ** 4) + 0.026 / gap_f * (Tw - T))
            Tw += (q1 - q2) / cw * dt
            T += q2 / (m_g * c_) * dt
            for mark in (15, 60, 600):
                if abs(t - mark) < dt / 2:
                    hist[mark] = T - 303.0
        print("  %s: +%.1f C at 15 s (apogee ~12 s), +%.1f C at 60 s (landing), +%.1f C at 10 min"
              % (name, hist[15], hist[60], hist[600]))

    # ---- mass and CG (needs the exported STLs)
    if not (STL / "FinCan.stl").exists():
        print("\nMass and CG: no STLs in %s (run tools/verify_tailsteer.py --export first)" % STL)
        return
    print("\nMass and CG (Z above the base; x from the tip = %.2f - Z):" % (BASE_X * 1e3))
    items = []
    fill = PC["rho_solid"] * PC["fill"]
    m_, z_ = stl_mass_cg(STL / "FinCan.stl", fill)          # printed upright: Z is the assembled Z
    items.append(("FinCan (PC, %.0f%% fill)" % (PC["fill"] * 100), m_, z_))
    m_, z_ = render_mass_cg(30, PC["rho_solid"], ['Airframe="%s"' % fs])   # three covers, assembled pose
    items.append(("hatch covers x3 (PC solid)", m_, z_))
    m_, z_ = render_mass_cg(24, PC["rho_solid"], ['Airframe="%s"' % fs])   # three cranks, assembled pose
    items.append(("cranks x3 (PC solid)", m_, z_))
    ymax = max(y for _, y in pts)
    zx = lambda x: p["Fin_Base_X"] - x                       # fin x -> Z above the base
    # ailerons: mass from the STL volume, centroid from the planform
    def ail(h):
        q = next((q for q in (STL / ("Aileron%sHalf_%s.stl" % (h, fs)), STL / ("Aileron%sHalf.stl" % h)) if q.exists()), None)
        if q is None:
            raise SystemExit("Mass and CG: no Aileron%sHalf STL for %s in %s (run tools/verify_tailsteer.py --export first)"
                             % (h, fs, STL))
        return q
    m_ = sum(stl_mass_cg(ail(h), PC["rho_solid"])[0] for h in ("Screw", "Tapped"))
    _, xa = region_moments(pts, p["Flap_Root_Gap"], p["Flap_Span"], p["Hinge_X"] - p["Flap_LE_R"], p["Flap_X_Max"])
    items.append(("ailerons x3 (PC solid)", 3 * m_, zx(xa)))
    # fixed fins: outline minus the notch plus the new tab (plywood, from the outlines)
    A_o, x_o = region_moments(pts, 0, ymax)
    A_n, x_n = region_moments(pts, 0, p["Flap_Span"] + p["Flap_Gap"],
                              xmin=p["Hinge_X"] - p["Flap_LE_R"] - p["Flap_Gap"])
    tab_d = R - (p["MMT_OD"] / 2 + 0.2)
    A_t, x_t = (175 - 55) * tab_d, p["Fin_Base_X"] - (55 + 175) / 2
    A_f = A_o - A_n + A_t
    x_f = (A_o * x_o - A_n * x_n + A_t * x_t) / A_f
    items.append(("fixed fins x3, %s (notched, new tab)" % AF["fin_name"],
                  3 * A_f * p["Fin_T"] * (AF["fin_rho"] or PLY_RHO) / 1000, zx(x_f)))
    mmt_l = AF.get("mmt_l", 279.4)
    items += [("shafts 4 x %.0f mm steel x3" % (p["Shaft_X1"] - p["Shaft_X0"]),
               3 * math.pi * 4 * (p["Shaft_X1"] - p["Shaft_X0"]) * 7.85e-3, p["Hinge_Z"]),
              ("bearings %s x6" % BEARING["name"], 6 * BEARING["mass"], p["Hinge_Z"]),
              ("servos %s x3" % SERVO["name"], 3 * SERVO["mass"], p["Servo_ZO"] + 10.5),
              ("ball links, studs, M2 rods, nuts x3 (est)", 3 * 4.0, (p["Hinge_Z"] + p["Servo_ZO"]) / 2),
              ("LiPo Tattu 450 mAh 2S (spec)", 28.0, p["Lipo_Z0"] + p["Lipo_L"] / 2),
              ("switch, fuse, 1000 uF, harness (est)", 22.0, 175.0),
              ("inserts, screws, nuts (est)", 14.0, 110.0),
              ("paper tube %.1f mm (%s)" % (p["Tube_Piece_L"], AF["tube_note"]),
               math.pi * (50.8 ** 2 - 49.53 ** 2) * p["Tube_Piece_L"] * PAPER_RHO / 1000,
               p["Can_L"] + p["Tube_Piece_L"] / 2),
              ("motor tube 38 mm x %.1f" % mmt_l, 55.2 * mmt_l / 279.4, 12.7 + mmt_l / 2),
              AF.get("ring_item", ("plywood CR + eyebolt (kit)", 29.2 + 25.1, p["Ply_CR_Z0"] + 3))] + AF.get("extra", []) + [
              ("rail buttons (kit, unchanged)", 3.8, 200.0)]
    m_new = sum(x[1] for x in items)
    z_new = sum(x[1] * x[2] for x in items) / m_new
    for nm, mm, zz in items:
        print("  %-52s %7.1f g at Z %6.1f" % (nm, mm, zz))
    print("  %-52s %7.1f g at Z %6.1f" % ("NEW AFT SECTION", m_new, z_new))
    # current fixed-fin aft section (.ork components)
    tube = math.pi * (50.8 ** 2 - 49.53 ** 2) * 457.2 * PAPER_RHO / 1000
    # .ork fin: full outline plus the TTW tab (from or_tab[0] behind the root LE, or_tab[1] x or_tab[2])
    t0, tl, td = AF["or_tab"]
    A_ot, x_ot = tl * td, t0 + tl / 2
    A_so, x_so = region_moments(AF.get("stock_pts", pts), 0, max(y for _, y in AF.get("stock_pts", pts)))
    A_old = A_so + A_ot
    x_old = (A_so * x_so + A_ot * x_ot) / A_old
    fins_old = 3 * A_old * 6.35 * PLY_RHO / 1000
    old = [("aft tube 457.2 (.ork paper)", tube, 228.6),
           ("fins x3 with tab (.ork ply)", fins_old, zx(x_old)),
           ("motor tube (.ork)", 55.2, 152.4),
           ("centering rings x2 (.ork ply)", 58.5, (28.6 + 158.75) / 2),
           ("eyebolt (.ork)", 25.1, 161.9),
           ("rail buttons (.ork)", 3.8, 200.0)]
    m_old = sum(x[1] for x in old)
    z_old = sum(x[1] * x[2] for x in old) / m_old
    print("  current section from the .ork: %.1f g at Z %.1f (epoxy and paint excluded on both sides)"
          % (m_old, z_old))
    dm = m_new - m_old
    print("  change: %+.1f g; signal cable through the rocket ~10 g more (spread)" % dm)
    print("  as one mass for tools/ORSimMass.java: %+.3f kg at %.4f m from the tip"
          % (dm / 1000, (m_new * (BASE_X - z_new / 1000) - m_old * (BASE_X - z_old / 1000)) / dm))
    print("\nStability (OpenRocket %s sim; CP %.3f m, CFD CP %.3f m):" % (AF["sim_label"], OR_CP, AF["cfd_cp"]))
    for st, (M, cg) in (OR_STATES or {}).items():
        x_new_item = BASE_X - z_new / 1000
        x_old_item = BASE_X - z_old / 1000
        cg2 = (M * cg - m_old / 1000 * x_old_item + m_new / 1000 * x_new_item) / (M + dm / 1000)
        print("  %-20s mass %.3f -> %.3f kg, CG %.3f -> %.3f m (%+.1f mm), margin %.2f -> %.2f cal"
              % (st, M, M + dm / 1000, cg, cg2, (cg2 - cg) * 1e3, (OR_CP - cg) / D_REF, (OR_CP - cg2) / D_REF))
    if AF.get("or_tail"):
        print("  OpenRocket model of the build: " + AF["or_tail"])


if __name__ == "__main__":
    main()
