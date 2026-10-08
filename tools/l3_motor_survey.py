#!/usr/bin/env python3
"""Motor survey for flying the Peregrine L3 airframe on L2 (J/K/L) motors.

1-DOF vertical flight model: real thrust curves from ThrustCurve.org, mass
decreasing with delivered impulse, ISA atmosphere, constant Cd with a mild rise
above Mach 0.8, no wind, no rail friction. It is a motor-selection filter, not
a substitute for OpenRocket (no stability, no weathercocking).

Each motor is flown in three bracketing cases:
  high  - light airframe, low drag      -> upper bound on apogee (ceiling check)
  mid   - nominal airframe, nominal drag -> likely apogee
  heavy - heavy airframe, high drag      -> slowest rail exit

The model is calibrated against the L2 flight (see `calibrate`); its rail-exit
speed reads ~5 % higher than OpenRocket, so the heavy case is scaled by
RAIL_CORR before classifying.

Usage:
  tools/l3_motor_survey.py                 # calibrate + survey + rail table
  tools/l3_motor_survey.py survey --dry 5.2 --rail 2.4
  tools/l3_motor_survey.py --refresh       # re-download ThrustCurve data

Results are written up in L3-TestFlights.md. Standard library only.
"""
import argparse, bisect, json, math, os, sys, urllib.request

CACHE = os.path.expanduser("~/.cache/rocket-parts/thrustcurve.json")
API = "https://www.thrustcurve.org/api/v1/"

# Home field (Långtora, Enköping - SMRK)
SITE_ALT = 15.0          # m ASL
CEILING = 1340.0         # m AGL
MAX_LIFTOFF = 10.0       # kg

# L3 airframe (L3-Design.md); dry mass excludes the M-motor nose ballast
DIA = 0.1401             # m, BT137
DRY = 5.0                # kg, nominal
DRY_SPREAD = 0.5         # kg, +/- for the light/heavy cases
ADAPTER_54 = 0.3         # kg added for a 75->54 mm adapter
RAIL = 1.8               # m

CD = {"high": 0.45, "mid": 0.55, "heavy": 0.60}   # 0.55 fits the L2 flight
RAIL_CORR = 0.95         # model rail exit vs OpenRocket (L2 calibration)

# Classification
ROBUST_APOGEE = 1160.0   # m, high case: ~13 % under the ceiling
ROBUST_RAIL = 24.0       # m/s, heavy case, corrected
MIN_RAIL = 15.0          # m/s, floor
MIN_TW = 5.0             # TUSC typical liftoff thrust-to-weight

# Calibration flight: L2 Peregrine, 2026-02-22 (MyLevel1Peregrine flight log)
L2 = dict(motor="J350W", dia=0.09906, liftoff=3.100, rail=1.2,
          openrocket=dict(apogee=1002, v_rail=21.6, vmax=173),
          flight=dict(apogee=986, vmax=172.6))


# --- ThrustCurve data ------------------------------------------------------

def _post(endpoint, body):
    req = urllib.request.Request(API + endpoint, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def fetch():
    """Candidate motors (AeroTech/Cesaroni reloads, 54/75 mm, J-L, regular
    availability, avg thrust >= 300 N) plus the calibration motor."""
    found = []
    for dia in (54, 75):
        for cls in "JKL":
            found += _post("search.json", {"diameter": dia, "impulseClass": cls,
                                           "maxResults": 500})["results"]
    found = [m for m in found
             if m["manufacturerAbbrev"] in ("AeroTech", "Cesaroni")
             and m.get("availability") == "regular" and m["type"] != "hybrid"
             and m["avgThrustN"] >= 300 and m.get("dataFiles", 0) > 0]
    found += [m for m in _post("search.json", {"commonName": "J350", "manufacturer": "AeroTech"})["results"]
              if m["designation"] == L2["motor"]]
    ids = [m["motorId"] for m in found]
    curves = {}
    for r in _post("download.json", {"motorIds": ids, "format": "RASP",
                                     "data": "samples", "maxResults": 1000})["results"]:
        if r.get("samples") and r["motorId"] not in curves:
            curves[r["motorId"]] = [(s["time"], s["thrust"]) for s in r["samples"]]
    motors = []
    for m in found:
        if m["motorId"] in curves and m.get("totalWeightG") and m.get("propWeightG"):
            motors.append(dict(m, curve=curves[m["motorId"]]))
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(CACHE, "w") as fh:
        json.dump(motors, fh)
    return motors


def load(refresh=False):
    if refresh or not os.path.exists(CACHE):
        print("Downloading motor data from ThrustCurve.org ...", file=sys.stderr)
        return fetch()
    with open(CACHE) as fh:
        return json.load(fh)


# --- Flight model ----------------------------------------------------------

def isa(h):
    T = 288.15 - 0.0065 * h
    p = 101325 * (T / 288.15) ** 5.2559
    return p / (287.05 * T), math.sqrt(1.4 * 287.05 * T)


def cd_mach(cd0, mach):
    return cd0 if mach < 0.8 else cd0 * (1 + 2.0 * (mach - 0.8))


def fly(motor, dry_kg, dia, cd0, rail, dt=0.002):
    """Vertical flight to apogee. Returns apogee (m AGL), rail-exit and max
    velocity (m/s), max Mach, time to apogee (s), liftoff mass (kg),
    avg and peak thrust-to-weight."""
    t_c = [p[0] for p in motor["curve"]]
    f_c = [p[1] for p in motor["curve"]]
    if t_c[0] > 0:
        t_c.insert(0, 0.0); f_c.insert(0, 0.0)
    tb = t_c[-1]
    I_tot = sum((t_c[i + 1] - t_c[i]) * (f_c[i + 1] + f_c[i]) / 2 for i in range(len(t_c) - 1))

    def thrust(t):
        if t >= tb:
            return 0.0
        i = bisect.bisect_right(t_c, t) - 1
        return f_c[i] + (f_c[i + 1] - f_c[i]) * (t - t_c[i]) / (t_c[i + 1] - t_c[i])

    prop = motor["propWeightG"] / 1000
    m0 = dry_kg + motor["totalWeightG"] / 1000
    area = math.pi * dia ** 2 / 4
    t = h = v = I = 0.0
    v_rail = None; vmax = mmax = 0.0
    while True:
        F = thrust(t)
        mass = m0 - prop * min(I / I_tot, 1.0)
        rho, a = isa(SITE_ALT + h)
        drag = 0.5 * rho * v * abs(v) * cd_mach(cd0, abs(v) / a) * area
        acc = (F - drag) / mass - 9.81
        if h <= 0 and acc < 0 and t < tb:   # sitting on the pad until thrust > weight
            acc = 0.0
        v += acc * dt; h += v * dt; I += F * dt; t += dt
        if v_rail is None and h >= rail:
            v_rail = v
        vmax = max(vmax, v); mmax = max(mmax, v / a)
        if t > tb and v <= 0:
            break
    w = m0 * 9.81
    return dict(apogee=h, v_rail=v_rail or 0.0, vmax=vmax, mach=mmax, t_apo=t,
                m0=m0, tw_avg=motor["avgThrustN"] / w, tw_peak=max(f_c) / w,
                peak_n=max(f_c))


# --- Commands --------------------------------------------------------------

def name(m):
    return ("CTI " if m["manufacturerAbbrev"] == "Cesaroni" else "AT ") + m["designation"]


def calibrate(motors):
    m = next(x for x in motors if x["designation"] == L2["motor"] and x["diameter"] == 38)
    dry = L2["liftoff"] - m["totalWeightG"] / 1000
    r = fly(m, dry, L2["dia"], CD["mid"], L2["rail"])
    o, f = L2["openrocket"], L2["flight"]
    print(f"Calibration: L2 Peregrine, {L2['motor']}, {L2['liftoff']} kg, "
          f"{L2['rail']} m rail, Cd {CD['mid']}")
    print(f"  {'':12} {'model':>7} {'OpenRocket':>10} {'flight':>7}")
    print(f"  {'apogee m':12} {r['apogee']:7.0f} {o['apogee']:10.0f} {f['apogee']:7.0f}")
    print(f"  {'rail exit':12} {r['v_rail']:7.1f} {o['v_rail']:10.1f} {'-':>7}")
    print(f"  {'max vel':12} {r['vmax']:7.1f} {o['vmax']:10.1f} {f['vmax']:7.1f}")
    print()


def cases(m, dry, rail):
    extra = ADAPTER_54 if m["diameter"] == 54 else 0.0
    hi = fly(m, dry - DRY_SPREAD + extra, DIA, CD["high"], rail)
    mid = fly(m, dry + extra, DIA, CD["mid"], rail)
    hv = fly(m, dry + DRY_SPREAD + extra, DIA, CD["heavy"], rail)
    return hi, mid, hv


def classify(hi, mid, hv):
    vr = hv["v_rail"] * RAIL_CORR
    if hi["apogee"] > CEILING:
        return "out", f"apogee up to {hi['apogee']:.0f} m"
    if vr < MIN_RAIL:
        return "out", f"rail exit {vr:.1f} m/s"
    if hv["tw_avg"] < MIN_TW:
        return "out", f"avg T/W {hv['tw_avg']:.1f}"
    if mid["m0"] > MAX_LIFTOFF:
        return "out", f"liftoff {mid['m0']:.1f} kg"
    why = []
    if hi["apogee"] > ROBUST_APOGEE:
        why.append(f"apogee up to {hi['apogee']:.0f} m")
    if vr < ROBUST_RAIL:
        why.append(f"rail exit {vr:.1f} m/s")
    return ("marginal", ", ".join(why)) if why else ("robust", "")


def rank(motors, dry, rail):
    rows = {"robust": [], "marginal": [], "out": []}
    for m in motors:
        if m["diameter"] not in (54, 75):
            continue
        hi, mid, hv = cases(m, dry, rail)
        cls, why = classify(hi, mid, hv)
        rows[cls].append((m, hi, mid, hv, why))
    return rows


def survey(rows, dry, rail):
    print(f"Survey: BT137, dry {dry - DRY_SPREAD:.1f}/{dry:.1f}/{dry + DRY_SPREAD:.1f} kg "
          f"(high/mid/heavy, +{ADAPTER_54} kg for 54 mm), Cd "
          f"{CD['high']}/{CD['mid']}/{CD['heavy']}, rail {rail} m, ceiling {CEILING:.0f} m")
    print(f"Robust: high-case apogee <= {ROBUST_APOGEE:.0f} m and heavy-case rail exit "
          f">= {ROBUST_RAIL:.0f} m/s (x{RAIL_CORR})\n")
    hdr = (f"  {'motor':20} {'dia':>3} {'case':14} {'N*s':>5} {'liftoff':>7} {'apo mid':>7} "
           f"{'apo high':>8} {'rail':>5} {'peak N':>6} {'pk T/W':>6} {'Mach':>4}")
    for cls in ("robust", "marginal"):
        print(f"{cls.upper()} ({len(rows[cls])})")
        print(hdr + ("  why" if cls == "marginal" else ""))
        for m, hi, mid, hv, why in sorted(rows[cls], key=lambda r: (r[2]["apogee"])):
            print(f"  {name(m):20} {m['diameter']:3} {m.get('caseInfo') or '?':14} "
                  f"{m['totImpulseNs']:5.0f} {mid['m0']:6.1f}k {mid['apogee']:7.0f} "
                  f"{hi['apogee']:8.0f} {hv['v_rail'] * RAIL_CORR:5.1f} {mid['peak_n']:6.0f} "
                  f"{mid['tw_peak']:6.0f} {hi['mach']:4.2f}" + (f"  {why}" if why else ""))
        print()
    out = sorted(rows["out"], key=lambda r: (r[0]["diameter"], r[0]["totImpulseNs"]))
    print(f"OUT ({len(out)})")
    for m, hi, mid, hv, why in out:
        print(f"  {name(m):20} {m['diameter']:3}  {why}")
    print()


def rails(rows, dry, lengths=(1.8, 2.4, 3.0)):
    print("Rail exit, heavy case, corrected (m/s)")
    print(f"  {'motor':20}" + "".join(f"{L:>7.1f}m" for L in lengths))
    for cls in ("robust", "marginal"):
        for m, *_ in sorted(rows[cls], key=lambda r: r[2]["apogee"]):
            extra = ADAPTER_54 if m["diameter"] == 54 else 0.0
            vs = [fly(m, dry + DRY_SPREAD + extra, DIA, CD["heavy"], L)["v_rail"] * RAIL_CORR
                  for L in lengths]
            print(f"  {name(m):20}" + "".join(f"{v:8.1f}" for v in vs) + f"   {cls}")
    print()


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("command", nargs="?", default="all",
                    choices=("all", "calibrate", "survey", "rails"))
    ap.add_argument("--dry", type=float, default=DRY, help="nominal dry mass, kg (default %(default)s)")
    ap.add_argument("--rail", type=float, default=RAIL, help="rail length, m (default %(default)s)")
    ap.add_argument("--refresh", action="store_true", help="re-download ThrustCurve data")
    a = ap.parse_args()
    motors = load(a.refresh)
    if a.command in ("all", "calibrate"):
        calibrate(motors)
    if a.command == "calibrate":
        return
    rows = rank(motors, a.dry, a.rail)
    if a.command in ("all", "survey"):
        survey(rows, a.dry, a.rail)
    if a.command in ("all", "rails"):
        rails(rows, a.dry)

if __name__ == "__main__":
    main()
