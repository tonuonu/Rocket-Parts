#!/usr/bin/env python3
"""Hand estimates for the PeregrineCamNose canards: static margin, fail-safe
trim, hinge moment against servo torque, roll authority, stuck-canard roll
rate and rail clearance.

Canard geometry is read from PeregrineCamNose.scad (its CANARD_PARAMS echo).
Rocket data is the OpenRocket L2 model in ~/MyLevel1Peregrine/openrocket/
PeregrineL2.ork, simulation "Langtora Airfield 21 Feb 2026" (J350, the L2
flight). That model has the kit nosecone and a 2.8 kg stage-mass override,
so it is no basis for the CG. This tool therefore gives CG LIMITS, measured
from the forward rim of the forward body tube (the nose's base plane, Z=0
in the CAD), for >= 1.0 cal with the canards: the OR CP is moved from the
kit nose to the camera nose (slender-body nose CN_alpha = 2 at V/A_base
from the base), then the canards are added. Barrowman fin-set theory,
canard-alone roll forcing: canard-wake/fin interaction (which can cut or
even reverse canard roll authority) is NOT modelled.

Usage: canard_estimate.py [-D Canard_Span=20 ...] [--cg-from-rim MM]
"""
import argparse
import math
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))   # also under python -I
from rocket60_mesh import rocket60_nose_stl

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPENSCAD = "/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD"

# ---- OpenRocket PeregrineL2.ork, sim "Langtora Airfield 21 Feb 2026" ----
D_REF = 0.1016                 # OR reference diameter, m
L_NOSE_OR = 0.503123           # OR nosecone length (kit nose), m
STATES = {
    # name: (CG m, CP m, CN_alpha /rad, V m/s, mass kg)  from the sim log
    "rod exit (21.6 m/s, AoA 7.4 deg)": (1.176, 1.225, 1.757 / 0.129, 21.6, 3.408),
    "max speed (173 m/s)":              (1.142, 1.305, 11.0,           173.2, 3.084),
}
I_ROLL = 0.0075                # kg m^2, sim log
RHO = 1.2
A_SOUND = 340.3
# fins: 3, freeform (finpoints from the .ork), root at the body, r = 50.8 mm
FIN_PTS = [(0.0, 0.0), (0.0508, 0.04191), (0.09398, 0.0762), (0.127, 0.09525),
           (0.1524, 0.10541), (0.1778, 0.11176), (0.2032, 0.1143), (0.2286, 0.112776),
           (0.254, 0.107442), (0.2794, 0.098552), (0.3048, 0.08509), (0.3175, 0.076454),
           (0.324104, 0.07112), (0.324983, 0.0694722), (0.323342, 0.068326),
           (0.3048, 0.063754), (0.2794, 0.049276), (0.2667, 0.036576), (0.25908, 0.0254),
           (0.254, 0.015494), (0.24892, 0.0)]
FIN_CLA = 2.0                  # /rad, low-AR swept fin, rough
# ---- servo: MKS HV6160 (MKS: 11.7 @4.8 V, 14.5 @6.0, 17.0 @7.4 V stall),
# fed straight from the servo 2S 18650 pack in the cassette (7.4 V nominal;
# 8.4 full, the HV6160's maximum). Use the 6.0 V figure as the floor for a
# sagging pack.
SERVO = "MKS HV6160"
SERVO_KGCM = 14.5
CP_UNCERTAINTY = 0.08          # +- fraction of MAC the real panel CP may move
ALPHA_EXTRA = 5.0              # deg of body AoA on top of a full deflection



def scad_params(defines=()):
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "p.echo")
        extra = [x for d in defines for x in ("-D", d)]
        subprocess.run([OPENSCAD, "-o", out, "-D", "Render_Part=-1", *extra,
                        os.path.join(REPO, "PeregrineCamNose.scad")],
                       capture_output=True, text=True, check=True,
                       env=dict(os.environ, OPENSCADPATH=REPO))
        for line in open(out):
            if "CANARD_PARAMS" in line:
                v = [float(x) for x in line.split("CANARD_PARAMS", 1)[1].strip().strip('"').split()]
                keys = ["cr", "ct", "s", "xr", "z_pivot", "z_le", "fwd", "stop", "cmd", "skin_r",
                        "spline_tip_r", "root_gap"]
                return dict(zip(keys, v))
    raise RuntimeError("no CANARD_PARAMS echo")


def nose_v_over_a(profile):
    """Slender-body nose CP: V / A_base, measured forward from the base.
    profile: list of (z from base, outer radius) at increasing z."""
    v = 0.0
    for (z1, r1), (z2, r2) in zip(profile, profile[1:]):
        v += math.pi * (z2 - z1) * (r1 * r1 + r1 * r2 + r2 * r2) / 3
    return v / (math.pi * profile[0][1] ** 2)


def camera_nose_profile():
    """Outer radius vs Z of the camera nose: the 574.55 ogive shell up to the
    flange (Z 389.23), then the owner's CAD camera nose from its mesh on
    feature/rocket60. Radii in m, Z in m from the nose base."""
    R, L, base_l, cut3, flange_t = 50.75, 574.55, 15.0, 383.23, 6.0
    p = (R * R + L * L) / (2 * R)
    prof = [(0.0, R), (base_l, R)]
    for z in range(20, int(cut3) + 1, 5):
        prof.append((z, R - p + math.sqrt(p * p - (z - base_l) ** 2)))
    prof.append((cut3 + flange_t, 30.0))
    blob = rocket60_nose_stl()
    n = struct.unpack("<I", blob[80:84])[0]
    pts = []
    for i in range(n):
        o = 84 + 50 * i + 12
        for k in range(3):
            pts.append(struct.unpack("<3f", blob[o + 12 * k:o + 12 * k + 12]))
    top = max(q[2] for q in pts)
    bins = {}
    for x, y, z in pts:
        b = round(z)
        bins[b] = max(bins.get(b, 0.0), math.hypot(x, y))
    for b in sorted(bins):
        if b > 0:
            prof.append((cut3 + flange_t + b, bins[b]))
    prof.append((cut3 + flange_t + top, 0.0))
    return [(z / 1000, r / 1000) for z, r in prof], (cut3 + flange_t + top) / 1000


def fin_chord(y):
    xs = []
    pts = FIN_PTS + FIN_PTS[:1]
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        if (y1 - y) * (y2 - y) < 0:
            xs.append(x1 + (y - y1) * (x2 - x1) / (y2 - y1))
    xs.sort()
    return sum(xs[i + 1] - xs[i] for i in range(0, len(xs) - 1, 2))


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--cg-from-rim", type=float, default=None,
                    help="rocket CG in mm aft of the tube rim, if known: prints the margin")
    ap.add_argument("-D", dest="defines", action="append", default=[],
                    help="OpenSCAD override, e.g. -D Canard_Span=20")
    a = ap.parse_args()
    p = scad_params(a.defines)
    cr, ct, s, xr = (p[k] / 1000 for k in ("cr", "ct", "s", "xr"))
    R = p["skin_r"] / 1000
    d = 2 * R
    S = (cr + ct) / 2 * s
    lam = ct / cr
    mac = 2 / 3 * cr * (1 + lam + lam * lam) / (1 + lam)
    xf = xr * (cr + 2 * ct) / (3 * (cr + ct)) + (cr + ct - cr * ct / (cr + ct)) / 6
    lm = math.hypot(s, xr + ct / 2 - cr / 2)
    # Barrowman, 4 fins, body interference, normalised to the OR reference
    cna4 = 4 * 4 * (s / d) ** 2 / (1 + math.sqrt(1 + (2 * lm / (cr + ct)) ** 2)) * (d / D_REF) ** 2
    kfb = 1 + R / (s + R)
    cna_c = cna4 * kfb
    # positions in m AFT of the forward body-tube rim (nose base plane)
    x_c = -(p["z_le"] / 1000 - xf)
    zcp_kit = 0.466 * L_NOSE_OR       # tangent ogive (OR: 5:1 ogive, shape 1.0)
    prof, l_cam = camera_nose_profile()
    zcp_cam = nose_v_over_a(prof)     # forward of the rim
    print("Canard panel: root %.0f, tip %.0f, span %.0f, LE sweep %.0f mm; area %.0f mm2 each"
          % (cr * 1e3, ct * 1e3, s * 1e3, xr * 1e3, S * 1e6))
    print("MAC %.1f mm; Barrowman panel CP %.1f mm behind root LE; pivot %.1f mm behind root LE"
          " (%.0f%% MAC ahead of the CP)" % (mac * 1e3, xf * 1e3, (xf - p["fwd"] * mac) * 1e3,
                                            p["fwd"] * 100))
    print("CN_alpha of the 4-canard set %.2f /rad (K_fb %.2f), CP %.1f mm ahead of the rim"
          % (cna_c, kfb, -x_c * 1e3))
    print("Nose CP (CN_alpha 2): kit %.1f mm, camera nose %.1f mm ahead of the rim "
          "(camera nose length %.1f mm)" % ((L_NOSE_OR - zcp_kit) * 1e3, zcp_cam * 1e3, l_cam * 1e3))
    print()
    print("CG limits for >= 1.0 cal (OR reference %.1f mm), measured AFT of the forward"
          " body-tube rim:" % (D_REF * 1e3))
    for name, (cg_or, cp_or, cna, v, m) in STATES.items():
        cp_kit = cp_or - L_NOSE_OR                     # aft of rim
        cp_cam = cp_kit + 2 * ((L_NOSE_OR - zcp_kit) - zcp_cam) / cna
        cp2 = (cna * cp_cam + cna_c * x_c) / (cna + cna_c)
        lim = cp2 - D_REF
        dl = math.radians(p["stop"])
        trim = cna_c * dl * (lim - x_c) / ((cna + cna_c) * (cp2 - lim))
        print("  %-34s CP %.1f mm (kit nose, no canards: %.1f; canards move it %.1f mm forward)"
              % (name, cp2 * 1e3, cp_kit * 1e3, (cp_cam - cp2) * 1e3))
        print("  %-34s CG limit %.0f mm aft of the rim (kit nose without canards: %.0f mm)"
              % ("", lim * 1e3, (cp_kit - D_REF) * 1e3))
        print("  %-34s at that CG, canards stuck at %.0f deg: one pair %.1f deg AoA, all four"
              " diagonal %.1f deg" % ("", p["stop"], math.degrees(trim), math.degrees(trim) * math.sqrt(2)))
        if a.cg_from_rim is not None:
            print("  %-34s with CG %.0f mm aft of the rim: margin %.2f cal"
                  % ("", a.cg_from_rim, (cp2 - a.cg_from_rim / 1000) / D_REF))
    print("  (OR's own CG is not used: stage-mass override 2.8 kg.)")
    print()
    # hinge moment
    v = 173.2
    q = 0.5 * RHO * v * v
    beta = math.sqrt(1 - (v / A_SOUND) ** 2)
    ar = (2 * s) ** 2 / (2 * S)
    cla = 2 * math.pi * ar / (2 + math.sqrt(4 + (ar * beta) ** 2))
    e = (p["fwd"] + CP_UNCERTAINTY) * mac
    arm = R + p["root_gap"] / 1000 + s * (cr + 2 * ct) / (3 * (cr + ct)) - p["spline_tip_r"] / 1000   # panel CP to spline tip
    print("Hinge moment at %.0f m/s, q = %.1f kPa, panel CL_alpha %.2f /rad (AR %.2f):"
          % (v, q / 1e3, cla, ar))
    for dd, lab in ((p["cmd"], "commanded max"), (p["stop"], "at the stop"),
                    (p["stop"] + ALPHA_EXTRA, "stop + %.0f deg AoA" % ALPHA_EXTRA)):
        lift = q * S * cla * math.radians(dd)
        mh = lift * e
        print("  %-22s %5.1f deg: panel load %5.1f N, hinge moment <= %.2f kg cm "
              "(CP %.1f mm off the pivot), spline bending %.2f N m"
              % (lab, dd, lift, mh / 9.81 * 100, e * 1e3, lift * arm))
    worst_kgcm = mh / 9.81 * 100   # last row: stop + ALPHA_EXTRA
    print("  servo %s >= %.1f kg cm stall on the 2S pack (direct drive, 1:1) -> worst case uses %.0f%%"
          % (SERVO, SERVO_KGCM, 100 * worst_kgcm / SERVO_KGCM))
    print()
    # roll, canard-alone
    yc = R + p["root_gap"] / 1000 + s * (cr + 2 * ct) / (3 * (cr + ct))
    print("Roll (canard-alone; fin-wake interaction not modelled), I_roll %.4f kg m2:" % I_ROLL)
    for vv in (30, 60, 100, 173.2):
        qq = 0.5 * RHO * vv * vv
        mr = 4 * qq * S * cla * math.radians(p["cmd"]) * yc
        print("  %5.1f m/s, %.0f deg: roll moment %.3f N m, %.0f rad/s2 (stops 360 deg/s in %.2f s)"
              % (vv, p["cmd"], mr, mr / I_ROLL, 2 * math.pi / (mr / I_ROLL)))
    n = 400
    smax = max(y for _, y in FIN_PTS)
    damp = 3 * sum(FIN_CLA * fin_chord((i + .5) / n * smax) * (0.0508 + (i + .5) / n * smax) ** 2 * smax / n for i in range(n))
    damp += 4 * sum(cla * (cr + (ct - cr) * (i + .5) / n) * (R + (i + .5) / n * s) ** 2 * s / n for i in range(n))
    force = 4 * S * cla * math.radians(p["stop"]) * yc
    for vv in (100, 173.2):
        print("  all four stuck at the stop in the roll sense, steady roll at %.0f m/s: %.1f rev/s"
              % (vv, force / damp * vv / (2 * math.pi)))
    print()
    tip = R + p["root_gap"] / 1000 + s
    print("Rail: canard tip radius %.1f mm. Clocked 45 deg off the rail line the tip is %.1f mm"
          " to the side of the rail centre line (1010 rail half-width 12.7 mm)."
          % (tip * 1e3, tip * math.sin(math.radians(45)) * 1e3))


if __name__ == "__main__":
    main()
