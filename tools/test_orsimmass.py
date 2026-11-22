#!/usr/bin/env python3
"""Test tools/ORSimMass.java: a mass change with a new fin outline (--fins) must not count the
fins twice. The mass change already holds new-minus-.ork fins, so with --fins the liftoff mass
and CG must equal the run with the mass change alone, while the outline (and so the CP) changes.
Run it on an .ork where no component overrides its subcomponents' mass (the case where the
double count would show), e.g. MyLevel1Peregrine's openrocket/PeregrineL2-CamNose.ork.

Usage: test_orsimmass.py FILE.ork [--java JAVA] [--jar OpenRocket-24.12.jar]
  defaults: $OR_JAVA or ~/.cache/or-sim/jdk-17.0.21_9-x64_mac/Contents/Home/bin/java,
            $OR_JAR or ~/.cache/or-sim/OpenRocket-24.12.jar
Exits 0 if every check passes.
"""
import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

TOOL = Path(__file__).resolve().parent / "ORSimMass.java"
DM, X = 0.460, 1.531                       # kg at m from the tip (the Peregrine tail change)
OUTLINE = "0,0\n167,125\n257,125\n228.27,0\n"   # the Zephyr fin, unlike the .ork's


def run(java, jar, ork, *extra):
    r = subprocess.run([java, "-Djava.awt.headless=true", "-cp", jar, str(TOOL), ork, *extra],
                       capture_output=True, text=True, check=True)
    rows = [l.split(",") for l in r.stdout.splitlines() if l.count(",") == 11 and not l.startswith("sim,")]
    return {row[0]: row for row in rows}, r.stderr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ork")
    ap.add_argument("--java", default=os.environ.get("OR_JAVA", str(Path.home() / ".cache/or-sim/jdk-17.0.21_9-x64_mac/Contents/Home/bin/java")))
    ap.add_argument("--jar", default=os.environ.get("OR_JAR", str(Path.home() / ".cache/or-sim/OpenRocket-24.12.jar")))
    a = ap.parse_args()
    with tempfile.TemporaryDirectory() as d:
        fins = Path(d) / "fins.csv"
        fins.write_text(OUTLINE)
        mass, err_m = run(a.java, a.jar, a.ork, str(DM), str(X))
        both, err_b = run(a.java, a.jar, a.ork, str(DM), str(X), "--fins", str(fins))
    fails = []
    check = lambda ok, msg: (print(("PASS " if ok else "FAIL ") + msg), ok or fails.append(msg))
    check("override of" not in err_m + err_b, "no subcomponent override in the .ork (the mass goes in as a component)")
    check(set(mass) == set(both) and mass, "the same %d simulations in both runs" % len(mass))
    for sim in sorted(set(mass) & set(both)):
        m, b = mass[sim], both[sim]
        # columns: 6 liftoff_kg, 7 liftoff_cg_m, 11 cp_at_vmax_m
        check(abs(float(b[6]) - float(m[6])) < 0.0005 and abs(float(b[7]) - float(m[7])) < 0.0001,
              "%s: liftoff %s kg at %s m with --fins = %s kg at %s m with the mass alone" % (sim, b[6], b[7], m[6], m[7]))
    cp = [(sim, mass[sim][11], both[sim][11]) for sim in sorted(set(mass) & set(both))
          if "NaN" not in (mass[sim][11], both[sim][11])]
    check(cp and all(abs(float(c1) - float(c0)) > 0.001 for _, c0, c1 in cp),
          "the outline still reaches the aerodynamics: CP at max speed moves in every sim that records it (%s)"
          % "; ".join("%s %s -> %s m" % c for c in cp))
    print("%s" % ("all checks passed" if not fails else "%d checks failed" % len(fails)))
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
