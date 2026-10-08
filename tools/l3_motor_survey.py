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

The model is calibrated against OpenRocket on the L2 rocket with identical
inputs (see `calibrate`): Cd 0.50 reproduces OpenRocket's apogee, rail exit
and max velocity within 2 %. The L2 flight itself agrees with OpenRocket.

Rail exit is taken when the aft rail button leaves the rail, i.e. after
rail length minus AFT_BUTTON of travel.

Usage:
  tools/l3_motor_survey.py                 # calibrate + survey + rail table
  tools/l3_motor_survey.py survey --dry 5.4 --spread 0.1 --rail 2.4
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

# L3 airframe (L3-Design.md). Dry mass from tools/l3_mass.py (4.3/5.3/6.2 kg
# low/nominal/high), without the nose ballast that only the M motor needs.
# Once the airframe is weighed, run with --dry <kg> --spread 0.1.
DIA = 0.1401             # m, BT137
DRY = 5.3                # kg, nominal
DRY_SPREAD = 0.95        # kg, +/- for the light/heavy cases
ADAPTER_54 = 0.3         # kg added for a 75->54 mm adapter
RAIL = 1.8               # m
AFT_BUTTON = 0.2         # m, aft rail button above the aft end (assumed)

CD = {"high": 0.40, "mid": 0.50, "heavy": 0.60}   # 0.50 matches OpenRocket on L2

# Classification
ROBUST_APOGEE = 1160.0   # m, high case: ~13 % under the ceiling
ROBUST_RAIL = 24.0       # m/s, heavy case (~5 m/s wind at 5x)
MIN_RAIL = 15.0          # m/s, floor (~3 m/s wind at 5x)
ACCEL_LIMIT = 32.0       # g, CATS Vega LSM6DSO32 range (+/-32 g)
MIN_TW = 5.0             # TUSC typical liftoff thrust-to-weight

# Calibration: L2 Peregrine, 2026-02-22. Inputs are those of the OpenRocket
# sim "Långtora Airfield 21 Feb 2026" in MyLevel1Peregrine/openrocket/
# PeregrineL2.ork (stage mass override 2.8 kg + J350W-OLD 0.651 kg). The
# flight log gives 3.1 kg liftoff; flight apogee is barometric, uncorrected
# for the cold day (~938 m corrected).
L2 = dict(motor="J350W-OLD", motor_kg=0.651, dia=0.09906, liftoff=3.451, rail=1.2,
          openrocket=dict(apogee=1002, v_rail=21.6, vmax=173.2),
          flight=dict(apogee=986, vmax=172.6))


# --- ThrustCurve data ------------------------------------------------------

def _post(endpoint, body):
    req = urllib.request.Request(API + endpoint, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def fetch():
    """Candidate motors (AeroTech/Cesaroni reloads and single-use, 54/75 mm,
    J-L, regular availability, avg thrust >= 300 N) plus the calibration motor."""
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
        if m["designation"] == L2["motor"]:
            m = dict(m, totalWeightG=m.get("totalWeightG") or L2["motor_kg"] * 1000)
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
    """Vertical flight to apogee. `rail` is the travel until the aft rail
    button leaves the rail. Returns apogee (m AGL), rail-exit and max velocity
    (m/s), max Mach, time to apogee (s), liftoff mass (kg), avg thrust-to-weight
    and peak acceleration (g)."""
    pts = sorted(dict(motor["curve"]).items())   # some files repeat time stamps
    t_c = [p[0] for p in pts]
    f_c = [p[1] for p in pts]
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
    # ThrustCurve's listed peak can exceed the sampled curve's; use the larger
    peak = max(max(f_c), motor.get("maxThrustN") or 0.0)
    return dict(apogee=h, v_rail=v_rail or 0.0, vmax=vmax, mach=mmax, t_apo=t,
                m0=m0, tw_avg=motor["avgThrustN"] / (m0 * 9.81), peak_n=peak,
                peak_g=peak / (m0 * 9.81) - 1)


# --- Commands --------------------------------------------------------------

def name(m):
    return ("CTI " if m["manufacturerAbbrev"] == "Cesaroni" else "AT ") + m["designation"]


def kind(m):
    """Hardware and motor ejection: 'SU 6-14' single-use with delays,
    'RMS-54/852 P' reload, plugged (no motor ejection)."""
    d = m.get("delays") or "?"
    if m["type"] == "SU":
        return f"SU {d.split(',')[0]}-{d.split(',')[-1]}" if "," in d else f"SU {d}"
    return f"{m.get('caseInfo') or '?'} {'P' if d == 'P' else d.split(',')[0] + '-' + d.split(',')[-1] if ',' in d else d}"


def calibrate(motors):
    m = next(x for x in motors if x["designation"] == L2["motor"])
    dry = L2["liftoff"] - L2["motor_kg"]
    r = fly(m, dry, L2["dia"], CD["mid"], L2["rail"])
    o, f = L2["openrocket"], L2["flight"]
    print(f"Calibration: L2 Peregrine, {L2['motor']}, {L2['liftoff']} kg, "
          f"{L2['rail']} m rail, Cd {CD['mid']}")
    print(f"  {'':12} {'model':>7} {'OpenRocket':>10} {'flight':>7}")
    print(f"  {'apogee m':12} {r['apogee']:7.0f} {o['apogee']:10.0f} {f['apogee']:7.0f}")
    print(f"  {'rail exit':12} {r['v_rail']:7.1f} {o['v_rail']:10.1f} {'-':>7}")
    print(f"  {'max vel':12} {r['vmax']:7.1f} {o['vmax']:10.1f} {f['vmax']:7.1f}")
    print()


def cases(m, dry, rail, spread):
    extra = ADAPTER_54 if m["diameter"] == 54 else 0.0
    travel = rail - AFT_BUTTON
    hi = fly(m, dry - spread + extra, DIA, CD["high"], travel)
    mid = fly(m, dry + extra, DIA, CD["mid"], travel)
    hv = fly(m, dry + spread + extra, DIA, CD["heavy"], travel)
    return hi, mid, hv


def classify(hi, mid, hv):
    vr = hv["v_rail"]
    if hi["apogee"] > CEILING:
        return "out", f"apogee up to {hi['apogee']:.0f} m"
    if vr < MIN_RAIL:
        return "out", f"rail exit {vr:.1f} m/s"
    if hv["tw_avg"] < MIN_TW:
        return "out", f"avg T/W {hv['tw_avg']:.1f}"
    if hv["m0"] > MAX_LIFTOFF:
        return "out", f"liftoff {hv['m0']:.1f} kg"
    why = []
    if hi["apogee"] > ROBUST_APOGEE:
        why.append(f"apogee up to {hi['apogee']:.0f} m")
    if vr < ROBUST_RAIL:
        why.append(f"rail exit {vr:.1f} m/s")
    return ("marginal", ", ".join(why)) if why else ("robust", "")


def rank(motors, dry, rail, spread):
    rows = {"robust": [], "marginal": [], "out": []}
    for m in motors:
        if m["diameter"] not in (54, 75):
            continue
        hi, mid, hv = cases(m, dry, rail, spread)
        cls, why = classify(hi, mid, hv)
        rows[cls].append((m, hi, mid, hv, why))
    return rows


def survey(rows, dry, rail, spread):
    print(f"Survey: BT137, dry {dry - spread:.2f}/{dry:.2f}/{dry + spread:.2f} kg "
          f"(high/mid/heavy, +{ADAPTER_54} kg for 54 mm), Cd "
          f"{CD['high']}/{CD['mid']}/{CD['heavy']}, rail {rail} m, ceiling {CEILING:.0f} m")
    print(f"Robust: high-case apogee <= {ROBUST_APOGEE:.0f} m and heavy-case rail exit "
          f">= {ROBUST_RAIL:.0f} m/s; aft button {AFT_BUTTON} m above the aft end")
    print(f"Columns: liftoff/apo mid/peak g = mid case, apo high/Mach = high case, "
          f"rail = heavy case; '!' = peak g over the {ACCEL_LIMIT:.0f} g altimeter range\n")
    hdr = (f"  {'motor':20} {'dia':>3} {'hardware':18} {'N*s':>5} {'liftoff':>7} {'apo mid':>7} "
           f"{'apo high':>8} {'rail':>5} {'peak N':>6} {'peak g':>6} {'Mach':>4}")
    for cls in ("robust", "marginal"):
        print(f"{cls.upper()} ({len(rows[cls])})")
        print(hdr + ("  why" if cls == "marginal" else ""))
        for m, hi, mid, hv, why in sorted(rows[cls], key=lambda r: (r[2]["apogee"])):
            sat = "!" if mid["peak_g"] > ACCEL_LIMIT else " "
            print(f"  {name(m):20} {m['diameter']:3} {kind(m):18} "
                  f"{m['totImpulseNs']:5.0f} {mid['m0']:6.1f}k {mid['apogee']:7.0f} "
                  f"{hi['apogee']:8.0f} {hv['v_rail']:5.1f} {mid['peak_n']:6.0f} "
                  f"{mid['peak_g']:5.0f}{sat} {hi['mach']:4.2f}" + (f"  {why}" if why else ""))
        print()
    out = sorted(rows["out"], key=lambda r: (r[0]["diameter"], r[0]["totImpulseNs"]))
    print(f"OUT ({len(out)})")
    for m, hi, mid, hv, why in out:
        print(f"  {name(m):20} {m['diameter']:3}  {why}")
    print()


def rails(rows, dry, spread, lengths=(1.8, 2.4, 3.0)):
    print(f"Rail exit, heavy case (m/s), aft button {AFT_BUTTON} m above the aft end")
    print(f"  {'motor':20}" + "".join(f"{L:>7.1f}m" for L in lengths))
    for cls in ("robust", "marginal"):
        for m, *_ in sorted(rows[cls], key=lambda r: r[2]["apogee"]):
            extra = ADAPTER_54 if m["diameter"] == 54 else 0.0
            vs = [fly(m, dry + spread + extra, DIA, CD["heavy"], L - AFT_BUTTON)["v_rail"]
                  for L in lengths]
            print(f"  {name(m):20}" + "".join(f"{v:8.1f}" for v in vs) + f"   {cls}")
    print()


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("command", nargs="?", default="all",
                    choices=("all", "calibrate", "survey", "rails"))
    ap.add_argument("--dry", type=float, default=DRY, help="nominal dry mass, kg (default %(default)s)")
    ap.add_argument("--spread", type=float, default=DRY_SPREAD,
                    help="+/- dry mass for the light/heavy cases, kg (default %(default)s)")
    ap.add_argument("--rail", type=float, default=RAIL, help="rail length, m (default %(default)s)")
    ap.add_argument("--refresh", action="store_true", help="re-download ThrustCurve data")
    a = ap.parse_args()
    motors = load(a.refresh)
    if a.command in ("all", "calibrate"):
        calibrate(motors)
    if a.command == "calibrate":
        return
    rows = rank(motors, a.dry, a.rail, a.spread)
    if a.command in ("all", "survey"):
        survey(rows, a.dry, a.rail, a.spread)
    if a.command in ("all", "rails"):
        rails(rows, a.dry, a.spread)

if __name__ == "__main__":
    main()
