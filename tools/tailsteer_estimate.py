#!/usr/bin/env python3
"""Hand estimates for the PeregrineTailSteer ailerons: roll authority, hinge
moment against servo torque, bearing and shaft loads, printed-part stresses,
servo heating, mass and CG against the current fixed-fin aft section, and
the stability margin.

Geometry comes from PeregrineTailSteer.scad (its TS_PARAMS echo) and, for
masses, from the STLs in "STL Files/PeregrineTailSteer/" (run
tools/verify_tailsteer.py --export first). Loads come from the CFD study in
MyLevel1Peregrine (cfd/REPORT.md, results/*.csv): max dynamic pressure is
the J350 flight peak, Mach 0.39, q = 10.79 kPa, and the fin normal force
slope is the CFD fin-set CN_alpha. Rocket mass, CG and CP are the saved
OpenRocket J350 simulation in PeregrineL2-CamNose.ork.

Everything here is an ESTIMATE: strip theory with thin-airfoil flap
effectiveness scaled to the CFD fin lift slope for authority, and 2-D
thin-airfoil hinge moments (no 3-D or viscous relief, so conservative) for
servo and structure sizing.

Usage: tailsteer_estimate.py [--fin-set Peregrine|Zephyr]
"""
import argparse
import math
import os
import struct
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"
STL = REPO / "STL Files" / "PeregrineTailSteer"

# ---- CFD study (MyLevel1Peregrine cfd/results/cfd_cases.csv, drag_stability.csv)
RHO, A_SOUND = 1.225, 340.29
D_REF = 0.1016
A_REF = math.pi * D_REF ** 2 / 4
# Design load case. Max speed of every simulation in PeregrineL2-CamNose.ork
# (OpenRocket 24.12, tools/ORSimMass.java), as saved and with the tail-steering
# mass change added (+0.460 kg at 1.531 m from the tip, as a zero-length mass). The highest is the J350;
# the J420R that L2-PrintSettings.md names reaches 130.0 m/s in the .ork, not the
# ~200 m/s that file quotes for an earlier, lighter design. Design q uses the
# J350 as saved (lighter, faster) at sea-level density.
OR_VMAX = {   # motor: (vmax as saved, vmax with the tail), m/s
    "J350W": (132.7, 119.7), "J420R": (130.0, 117.1), "HP-J270W": (128.6, None),
    "I327DM": (106.2, 95.2), "H550ST": (70.6, None)}
V_DESIGN = 132.7
Q_MAX = 0.5 * RHO * V_DESIGN ** 2   # 10.79 kPa
FACTOR_MIN = 2.0                    # servo margin, bearing C0r/P and shaft factor all >= this
# fin-set normal force at alpha 4 deg minus alpha 0, M 0.25, pitch plane phi = 60
CN_FINS = {"Peregrine": (0.731968 - 0.00956957), "Zephyr": (0.713916 - (-0.00538825))}
CANARD_NET_PER_DEG = -0.0030        # canards + fins, M 0.25, delta 5 (REPORT.md B)
CANARD_ALONE_PER_DEG = 0.0087       # canards' own Cl_delta (REPORT.md B)
ALPHA_DESIGN = 4.0                  # deg, as the CFD incidence cases
ALPHA_MARGIN = 1.5                  # on the CFD fin load
VISCOUS = 0.85                      # flap effectiveness factor (gap, viscous), estimate
# ---- OpenRocket PeregrineL2-CamNose.ork, sim "Langtora Airfield 21 Feb 2026" (J350W)
OR_STATES = {"liftoff": (4.491, 0.968), "max speed / burnout": (4.122, 0.922)}
OR_CP = 1.219                       # m from the tip at max speed (CFD: 1.262-1.264)
BASE_X = 1.65168                    # tip to base, m
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
    "Zephyr": [(0, 0), (150.749, 112.852), (223.749, 112.852), (269.494, 12.548),
               (245.034, 12.548), (228.27, 0)],
}


def scad_params(fin_set):
    keys = ("R_Out R_In MMT_OD MMT_Z0 MMT_L Hinge_Z Hinge_X Fin_Base_X Flap_Span Flap_Root_Gap "
            "Flap_Gap Flap_LE_R Shaft_D Shaft_X0 Shaft_X1 Brg_In_X0 Brg_Out_X1 Brg_B Brg_D Crank_A "
            "Horn_R Crank_Xk Servo_Theta Servo_Rc Servo_ZO Pushrod_L Horn_Ball_U Fin_T Can_L Total_H "
            "Rail_A Rail_Aft_Z Tube_Piece_L Ply_CR_Z0 Flap_Max Sw_A Sw_Z Flap_X_Max Fixed_Aft_X "
            "Lipo_Z0 Lipo_L Ball_Off Horn_Arm_T Pin_D Pin_L Clamp_Relief").split()
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "p.echo")
        subprocess.run([OPENSCAD, "-o", out, "-D", "Render_Part=-1", "-D", 'Fin_Set="%s"' % fin_set,
                        str(REPO / "PeregrineTailSteer.scad")], capture_output=True, text=True, check=True)
        for line in open(out):
            if "TS_PARAMS" in line:
                v = [float(x) for x in line.split("TS_PARAMS", 1)[1].strip().strip('"').split()]
                return dict(zip(keys, v))
    raise RuntimeError("no TS_PARAMS echo")


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


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--fin-set", default="Peregrine", choices=sorted(FIN_PTS))
    a = ap.parse_args()
    fs = a.fin_set
    p = scad_params(fs)
    pts = FIN_PTS[fs]
    R = p["R_Out"]
    S_fin = area(pts)
    cna_fin = CN_FINS[fs] / math.radians(ALPHA_DESIGN) / 1.5     # one fin, full incidence, ref A
    cla_own = cna_fin * A_REF / (S_fin * 1e-6)
    k3 = cla_own / (2 * math.pi)
    strips = flap_strips(p, pts)
    Sf = sum(cf * dy for _, _, cf, dy in strips)
    E_all = [cf / c for _, c, cf, _ in strips]
    print("== %s fin set, aileron hinge %.2f mm from the root LE (%.1f mm above the base)" %
          (fs, p["Hinge_X"], p["Hinge_Z"]))
    print("Fin %.0f mm2; aileron %.0f mm2 per fin (%.1f%%), span %.1f-%.1f mm off the body, "
          "chord %.1f-%.1f mm, flap/fin chord %.2f-%.2f" %
          (S_fin, Sf, 100 * Sf / S_fin, p["Flap_Root_Gap"], p["Flap_Span"],
           min(s[2] for s in strips), max(s[2] for s in strips), min(E_all), max(E_all)))
    print("CFD fin CN_alpha: set %.2f /rad, one fin %.2f /rad (ref A), own-area CL_alpha %.2f /rad"
          " = %.2f x 2 pi" % (CN_FINS[fs] / math.radians(ALPHA_DESIGN), cna_fin, cla_own, k3))

    # ---- roll authority (strip theory)
    num = sum(c * thin_airfoil(cf / c, 0, 1)[2] * (R + y) * dy for y, c, cf, dy in strips)
    cl_d = 3 * 2 * math.pi * k3 * VISCOUS * num * 1e-9 / (A_REF * D_REF)   # per rad
    cl_deg = cl_d * math.pi / 180
    q25 = 0.5 * RHO * (0.25 * A_SOUND) ** 2
    print("\nRoll authority (ESTIMATE: strip theory, thin-airfoil tau x %.2f, scaled to the CFD fin slope):"
          % VISCOUS)
    # magnitude only: the roll sense follows from the CAD deflection sign (README), not from here
    print("  |Cl_delta| = %.4f /deg (3 ailerons, all deflected for roll)" % cl_deg)
    print("  vs canards: net |%.4f| /deg -> %.0fx; canards alone |%.4f| /deg -> %.1fx"
          % (abs(CANARD_NET_PER_DEG), abs(cl_deg / CANARD_NET_PER_DEG),
             CANARD_ALONE_PER_DEG, cl_deg / CANARD_ALONE_PER_DEG))
    print("  1 deg at M 0.25 (q %.0f Pa): %.3f N m; at M 0.39: %.3f N m" %
          (q25, cl_deg * q25 * A_REF * D_REF, cl_deg * Q_MAX * A_REF * D_REF))
    # roll damping of the 3 fins (strip, own-area slope) for a steady-rate scale
    n = 300
    ymax = max(y for _, y in pts)
    damp = 0.0
    for i in range(n):
        y = (i + 0.5) / n * ymax
        xs = crossings(pts, y)
        c = sum(xs[j + 1] - xs[j] for j in range(0, len(xs) - 1, 2))
        damp += 3 * cla_own * c * 1e-3 * ((R + y) * 1e-3) ** 2 * (ymax / n) * 1e-3
    for v in (85.1, 132.7):
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
    print("\nLoad case: highest .ork max speed %.1f m/s (J350; J420R %.1f m/s); with the tail mass"
          " the J350 drops to %.1f m/s. Design q = %.2f kPa at sea level."
          % (V_DESIGN, OR_VMAX["J420R"][0], OR_VMAX["J350W"][1], Q_MAX / 1e3))
    print("Hinge moment and aileron load at q = %.2f kPa, 2-D thin airfoil (conservative):" % (Q_MAX / 1e3))
    chd = [-thin_airfoil(e, 0, 1)[1] / e ** 2 for e in (min(E_all), max(E_all))]
    cha = [-thin_airfoil(e, 1, 0)[1] / e ** 2 for e in (min(E_all), max(E_all))]
    print("  thin-airfoil Ch_delta %.2f to %.2f /rad, Ch_alpha %.2f to %.2f /rad (on the flap chord, c_f/c %.2f-%.2f);"
          " alpha part x %.2f (3-D slope)" % (chd[0], chd[1], cha[0], cha[1], min(E_all), max(E_all), k3))
    worst = None
    for dl, al in ((10, ALPHA_DESIGN), (p["Flap_Max"], ALPHA_DESIGN * ALPHA_MARGIN)):
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
          " under +-15 deg, life is not a limit at Cr/P %.1f" %
          (Ro, BEARING["C0r"] / Ro, Ri, BEARING["C0r"] / Ri, BEARING["Cr"] / Ro))
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
          % (Ro / (9 * 4), Ri / (9 * 4), Ro_l / 36, Ri_l / 36))
    web = 1.6 * (p["Hinge_Z"] + 9.26)
    print("  inner housing -> web and motor-tube glue: %.1f N over web %.0f mm2 (%.2f MPa) + glue face"
          % (Ri, web, Ri / web))
    # crank: clevis, pivot ball on a dowel between two cheeks, centred on the
    # pushrod line (no arm torsion); horn: the servo's metal arm with an M2 12.9
    # screw through it as a cantilevered stud
    gap, cheek, arm_h, win0 = 5.2, 2.5, 9.0, p["Crank_A"] - 3.5 - 1
    arm_w = p["Crank_Xk"] + gap / 2 + cheek - (p["Brg_In_X0"] + p["Brg_B"] + 0.15)
    eye, pin_d, pin_yield = 4.6, 2.0, 1200.0       # hardened dowel (ISO 8734), yield assumed
    # M2 x 10 12.9 through the horn arm; the ball load acts Ball_Off (CAD) from the arm mid-plane
    stud_minor, stud_yield, stud_arm = 1.57, 1080.0, p["Ball_Off"]
    print("  crank (clevis: cheeks %.1f x %.0f, Ø%.0f dowel, eye %.1f; no torsion) and horn stud:" % (cheek, arm_h, pin_d, eye))
    for lab, T_ in (("flight", Ts), ("servo stall 8.4 V", SERVO["stall_Nm"][8.4])):
        Fpp = T_ / (p["Horn_R"] * 1e-3)
        s_cheek = (Fpp / 2) * (p["Crank_A"] - win0) / (cheek * arm_h ** 2 / 6)
        s_root = Fpp * (p["Crank_A"] - 4.5) / (arm_w * arm_h ** 2 / 6)
        L_pin = gap + cheek
        s_pin = Fpp * (L_pin / 4 - eye / 8) / (math.pi * pin_d ** 3 / 32)
        s_brg = (Fpp / 2) / (pin_d * cheek)
        s_stud = Fpp * stud_arm / (math.pi * stud_minor ** 3 / 32)
        print("    %s: pushrod %.0f N | cheek %.1f MPa (x%.1f) | arm root %.1f MPa (x%.1f) | pin %.0f MPa"
              " (x%.1f) | pin bearing in PC %.1f MPa | horn M2 stud %.0f MPa (x%.2f)"
              % (lab, Fpp, s_cheek, PC["sigma_in"] / s_cheek, s_root, PC["sigma_in"] / s_root, s_pin,
                 pin_yield / s_pin, s_brg, s_stud, stud_yield / s_stud))
    T_stud = stud_yield * (math.pi * stud_minor ** 3 / 32) / stud_arm * p["Horn_R"] * 1e-3
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
    flat_w = 2 * math.sqrt((p["Shaft_D"] / 2) ** 2 - (p["Shaft_D"] / 2 - 0.5) ** 2)
    pin_aft = p["Pin_L"] - 2.2                    # pin length aft of the axis
    k_pin = p["Pin_D"] / pin_aft * ((pin_aft ** 3 - 2.0 ** 3) / 3)   # T = sigma_max * k_pin (from r 2 = shaft surface)
    print("  aileron drive (flat %.2f mm wide, %.0f mm engaged; Ø%.0f dowel %.0f mm aft of the axis):"
          % (flat_w, eng, p["Pin_D"], pin_aft))
    for lab, T_ in (("flight", H), ("horn-screw yield", T_stud * ratio), ("servo stall 8.4 V", SERVO["stall_Nm"][8.4] * ratio)):
        s_flat = 2 * (T_ * 1e3 / 0.9) / ((flat_w / 2) * eng)
        s_pinpc = T_ * 1e3 / k_pin
        s_pinsh = (T_ * 1e3 / (2 * (p["Shaft_D"] / 2))) / (math.pi * p["Pin_D"] ** 2 / 4)
        print("    %s, %.2f N m at the aileron: D-flat alone peak %.0f MPa | dowel in PC peak %.0f MPa"
              " (x%.1f) | dowel shear %.0f MPa" % (lab, T_, s_flat, s_pinpc, PC["sigma_in"] / s_pinpc, s_pinsh))
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
    print("\nLoad envelope (15 deg, alpha 6 deg; loads scale with q):")
    print("  at %.2f kPa: servo %.1fx (6.0 V), bearing C0r/P %.1f, shaft %.1f, horn screw %.1f"
          % (Q_MAX / 1e3, f_servo, f_brg, f_shaft, f_stud))
    print("  all >= %.1f up to q = %.1f kPa = %.0f m/s at sea level" % (FACTOR_MIN, q_lim / 1e3, math.sqrt(2 * q_lim / RHO)))
    for v in (OR_VMAX["J350W"][1], 200.0):
        k = (0.5 * RHO * v * v) / Q_MAX
        print("  at %.0f m/s (q %.1f kPa): servo %.1fx, C0r/P %.1f, shaft %.1f, horn screw %.1f"
              % (v, k * Q_MAX / 1e3, f_servo / k, f_brg / k, f_shaft / k, f_stud / k))

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
    v_fin = tn4197(0.38e9, ymax_f, S_fin - Sf, crossings(pts, 0.5)[-1] - crossings(pts, 0.5)[0],
                   0.3 * (crossings(pts, 0.5)[-1] - crossings(pts, 0.5)[0]), p["Fin_T"])
    rho_pc = PC["rho_solid"] * 1e3
    I_h = sum(rho_pc * (p["Fin_T"] * 1e-3) * (dy * 1e-3) * ((cf * 1e-3) ** 3 / 3) for _, _, cf, dy in strips)
    k_servo = SERVO["stall_Nm"][7.4] / math.radians(3.0)     # holds full torque within ~3 deg (assumed)
    k_h = k_servo * (p["Crank_A"] / p["Horn_R"]) ** 2
    f_h = math.sqrt(k_h / I_h) / (2 * math.pi)
    print("\nFlutter (rough):")
    print("  aileron panel, NACA TN 4197 (printed PC, G 0.6 GPa assumed): %.0f m/s" % v_ail)
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

    # ---- mass and CG (Peregrine only: needs the exported STLs)
    if fs != "Peregrine":
        return
    print("\nMass and CG (Z above the base; x from the tip = %.2f - Z):" % (BASE_X * 1e3))
    items = []
    fill = PC["rho_solid"] * PC["fill"]
    m_, z_ = stl_mass_cg(STL / "FinCan.stl", fill)          # printed upright: Z is the assembled Z
    items.append(("FinCan (PC, %.0f%% fill)" % (PC["fill"] * 100), m_, z_))
    m_, z_ = render_mass_cg(30, PC["rho_solid"])             # three covers, assembled pose
    items.append(("hatch covers x3 (PC solid)", m_, z_))
    m_, z_ = render_mass_cg(24, PC["rho_solid"])             # three cranks, assembled pose
    items.append(("cranks x3 (PC solid)", m_, z_))
    ymax = max(y for _, y in pts)
    zx = lambda x: p["Fin_Base_X"] - x                       # fin x -> Z above the base
    # ailerons: mass from the STL volume, centroid from the planform
    m_ = sum(stl_mass_cg(STL / ("Aileron%sHalf_%s.stl" % (h, fs)), PC["rho_solid"])[0] for h in ("Screw", "Tapped"))
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
    items.append(("fixed fins x3, 1/4 in birch ply (notched, new tab)", 3 * A_f * p["Fin_T"] * PLY_RHO / 1000, zx(x_f)))
    items += [("shafts 4 x %.0f mm steel x3" % (p["Shaft_X1"] - p["Shaft_X0"]),
               3 * math.pi * 4 * (p["Shaft_X1"] - p["Shaft_X0"]) * 7.85e-3, p["Hinge_Z"]),
              ("bearings %s x6" % BEARING["name"], 6 * BEARING["mass"], p["Hinge_Z"]),
              ("servos %s x3" % SERVO["name"], 3 * SERVO["mass"], p["Servo_ZO"] + 10.5),
              ("ball links, studs, M2 rods, nuts x3 (est)", 3 * 4.0, (p["Hinge_Z"] + p["Servo_ZO"]) / 2),
              ("LiPo Tattu 450 mAh 2S (spec)", 28.0, p["Lipo_Z0"] + p["Lipo_L"] / 2),
              ("switch, fuse, 1000 uF, harness (est)", 22.0, 175.0),
              ("inserts, screws, nuts (est)", 14.0, 110.0),
              ("paper tube %.1f mm (kept from the flown tube)" % p["Tube_Piece_L"],
               math.pi * (50.8 ** 2 - 49.53 ** 2) * p["Tube_Piece_L"] * PAPER_RHO / 1000,
               p["Can_L"] + p["Tube_Piece_L"] / 2),
              ("motor tube 38 mm x 279.4 (kit)", 55.2, 12.7 + 139.7),
              ("plywood CR + eyebolt (kit)", 29.2 + 25.1, p["Ply_CR_Z0"] + 3),
              ("rail buttons (kit, unchanged)", 3.8, 200.0)]
    m_new = sum(x[1] for x in items)
    z_new = sum(x[1] * x[2] for x in items) / m_new
    for nm, mm, zz in items:
        print("  %-52s %7.1f g at Z %6.1f" % (nm, mm, zz))
    print("  %-52s %7.1f g at Z %6.1f" % ("NEW AFT SECTION", m_new, z_new))
    # current fixed-fin aft section (.ork components)
    tube = math.pi * (50.8 ** 2 - 49.53 ** 2) * 457.2 * PAPER_RHO / 1000
    # .ork fin: full outline plus the TTW tab (from 92.075 behind the root LE, 124.46 x 30.0355)
    A_ot, x_ot = 124.46 * 30.0355, 92.075 + 124.46 / 2
    A_old = A_o + A_ot
    x_old = (A_o * x_o + A_ot * x_ot) / A_old
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
    print("\nStability (OpenRocket J350 sim; CP %.3f m, CFD CP 1.262 m):" % OR_CP)
    for st, (M, cg) in OR_STATES.items():
        x_new_item = BASE_X - z_new / 1000
        x_old_item = BASE_X - z_old / 1000
        cg2 = (M * cg - m_old / 1000 * x_old_item + m_new / 1000 * x_new_item) / (M + dm / 1000)
        print("  %-20s mass %.3f -> %.3f kg, CG %.3f -> %.3f m (%+.1f mm), margin %.2f -> %.2f cal"
              % (st, M, M + dm / 1000, cg, cg2, (cg2 - cg) * 1e3, (OR_CP - cg) / D_REF, (OR_CP - cg2) / D_REF))


if __name__ == "__main__":
    main()
