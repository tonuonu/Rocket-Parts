#!/usr/bin/env python3
"""Hand estimates for the PeregrineCamNose canards: static margin, fail-safe
trim, hinge moment against servo torque, roll authority, stuck-canard roll
rate and rail clearance.

Canard geometry is read from PeregrineCamNose.scad (its CANARD_PARAMS echo).
Rocket data is the OpenRocket L2 model in ~/MyLevel1Peregrine/openrocket/
PeregrineL2.ork, simulation "Langtora Airfield 21 Feb 2026" (J350, the L2
flight). That model has the kit nosecone, not the camera nose, so the
absolute margins here are only as good as its mass model; the canard SHIFTS
(delta CP, trim angle) do not depend on it. Barrowman fin-set theory,
canard-alone roll forcing: canard-wake/fin interaction (which can cut or
even reverse canard roll authority) is NOT modelled.

Usage: canard_estimate.py [--mass-g 250] [-D Canard_Span=20 ...]
"""
import argparse
import math
import os
import subprocess
import tempfile

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
# ---- servo: SH-1250MG retail 3.7 kg cm @4.8 V; SV-1250MG+ sheet 4.6 @6 V ----
SERVO_KGCM_5V = 3.7 + (4.6 - 3.7) * (5.0 - 4.8) / (6.0 - 4.8)
CP_UNCERTAINTY = 0.08          # +- fraction of MAC the real panel CP may move
ALPHA_EXTRA = 5.0              # deg of body AoA on top of a full deflection
SPLINE_TIP_R = 0.0419          # m, Servo_Bottom_R + Servo_Spline_Top


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
                keys = ["cr", "ct", "s", "xr", "z_pivot", "z_le", "fwd", "stop", "cmd", "skin_r"]
                return dict(zip(keys, v))
    raise RuntimeError("no CANARD_PARAMS echo")


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
    ap.add_argument("--mass-g", type=float, default=250.0,
                    help="mass the canard section adds at the pivot station")
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
    # canard CP from the nose tip, in the OR frame: OR nose length minus the
    # LE's height above the nose base, plus the panel CP behind the LE
    x_c = L_NOSE_OR - p["z_le"] / 1000 + xf
    x_m = L_NOSE_OR - p["z_pivot"] / 1000
    dm = a.mass_g / 1000
    print("Canard panel: root %.0f, tip %.0f, span %.0f, LE sweep %.0f mm; area %.0f mm2 each"
          % (cr * 1e3, ct * 1e3, s * 1e3, xr * 1e3, S * 1e6))
    print("MAC %.1f mm; Barrowman panel CP %.1f mm behind root LE; pivot %.1f mm behind root LE"
          " (%.0f%% MAC ahead of the CP)" % (mac * 1e3, xf * 1e3, (xf - p["fwd"] * mac) * 1e3,
                                            p["fwd"] * 100))
    print("CN_alpha of the 4-canard set %.2f /rad (K_fb %.2f), CP %.1f cm from the OR nose tip"
          % (cna_c, kfb, x_c * 100))
    print()
    print("Static margin, canards neutral (OR reference %.1f mm):" % (D_REF * 1e3))
    for name, (cg, cp, cna, v, m) in STATES.items():
        cp2 = (cna * cp + cna_c * x_c) / (cna + cna_c)
        cg2 = (m * cg + dm * x_m) / (m + dm)
        sm0, sm1, sm2 = (cp - cg) / D_REF, (cp2 - cg) / D_REF, (cp2 - cg2) / D_REF
        dl = math.radians(p["stop"])
        trim = cna_c * dl * (cg2 - x_c) / ((cna + cna_c) * (cp2 - cg2))
        print("  %-34s OR %.2f cal -> canards %.2f cal (CP moves %.1f cm forward);"
              " + %.0f g at the canards %.2f cal" % (name, sm0, sm1, (cp - cp2) * 100, a.mass_g, sm2))
        print("  %-34s aft CG limit for 1.0 cal with canards: %.1f cm from the OR tip "
              "(OR CG %.1f cm)" % ("", (cp2 - D_REF) * 100, cg * 100))
        print("  %-34s one pitch pair stuck at the %.0f deg stop: trim AoA %.1f deg"
              % ("", p["stop"], math.degrees(trim)))
        # all four at the stop, both pairs pushing the same diagonal way
        print("  %-34s all four stuck at the stop, diagonal: trim AoA %.1f deg"
              % ("", math.degrees(trim) * math.sqrt(2)))
    print()
    # hinge moment
    v = 173.2
    q = 0.5 * RHO * v * v
    beta = math.sqrt(1 - (v / A_SOUND) ** 2)
    ar = (2 * s) ** 2 / (2 * S)
    cla = 2 * math.pi * ar / (2 + math.sqrt(4 + (ar * beta) ** 2))
    e = (p["fwd"] + CP_UNCERTAINTY) * mac
    arm = R + 0.0008 + s * (cr + 2 * ct) / (3 * (cr + ct)) - SPLINE_TIP_R   # panel CP to spline tip
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
    print("  servo SH-1250MG at 5 V ~%.2f kg cm (direct drive, 1:1) -> worst case uses %.0f%%"
          % (SERVO_KGCM_5V, 100 * worst_kgcm / SERVO_KGCM_5V))
    print()
    # roll, canard-alone
    yc = R + 0.0008 + s * (cr + 2 * ct) / (3 * (cr + ct))
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
    tip = R + 0.0008 + s
    print("Rail: canard tip radius %.1f mm. Clocked 45 deg off the rail line the tip is %.1f mm"
          " to the side of the rail centre line (1010 rail half-width 12.7 mm)."
          % (tip * 1e3, tip * math.sin(math.radians(45)) * 1e3))


if __name__ == "__main__":
    main()
