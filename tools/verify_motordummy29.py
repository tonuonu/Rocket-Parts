#!/usr/bin/env python3
"""Render and measure MotorDummy29 (mass-equivalent inert 29mm motors).

6th review, finding 4: this part shipped with NO verification harness at
all, despite exporting three STLs (one per Motor_Class) whose ECHOED
ballast masses the ground test literally depends on -- a wrong Shell_g (a
bad density assumption, a cavity math slip) would silently mis-load every
swing/separation test run against it, with nothing to catch it. Follows
the SAME render/measure/genus/build-volume conventions as
verify_rocket60.py/verify_nosecone.py/verify_camnose.py, and now reuses
scad_verify.render() itself (that function's own `-D <var>=` selector
defaults to "Render_Part", but takes an override -- MotorDummy29.scad's
own selector is `-D Motor_Class=N`, so this file calls
render(SCAD, part, out, var="Motor_Class")) instead of maintaining a
second, hardcoded copy of the subprocess/OpenSCAD-path plumbing.
"""
import os, re, shutil, subprocess, sys, tempfile

from scad_verify import REPO, render, measure, components, volume, overshoot

SCAD = os.path.join(REPO, "MotorDummy29.scad")

NAMES = {0: "G80T-14A", 1: "H182R-14A", 2: "H135W-14A"}

# [OD, length, loaded mass g, propellant mass g] -- restated from
# MotorDummy29.scad's own Motor_Data (rule 4: a Python file cannot
# include<> a .scad file). Both this table's OD (29mm, all 3 classes) and
# R60Lib.scad's R60_MMT_ID ("29.0 + 0.3 -- 29mm motor, slip fit") /
# tools/r60_assembly.scad's Pair 11 (`cylinder(d=29.0, ...)`) all assume
# the SAME real motor OD -- MMT_ID_EXPECT below cross-checks the dummy
# actually fits the MMT it is meant to load-test, not just its own
# internally-consistent arithmetic.
MOTOR_DATA = {0: (29, 124, 128, 63), 1: (29, 203, 207, 115), 2: (29, 216, 212, 82)}
FILAMENT_DENSITY = 1.27   # g/cm3, PETG -- matches MotorDummy29.scad's own
IDXTRA = 0.2
WALL = 2.0
END_T = 3.0
MMT_ID_EXPECT = 29.3   # R60Lib.scad's R60_MMT_ID = 29.0+0.3


def render_with_echo(part, out):
    """Render Motor_Class=`part` to `out` via the shared scad_verify.render()
    (var="Motor_Class", MotorDummy29.scad's own dispatch variable), and
    also scrape MotorDummy29.scad's echoed ballast-mass lines out of the
    same render's console output (return_log=True) -- an independent
    second render just to capture output render() already produced would
    be a needless doubling of an OpenSCAD invocation this file's own
    900s-timeout comment (see scad_verify.render()) already flags as
    expensive.

    Returns (genus, echoed) -- genus per scad_verify.render()'s own
    contract (None if no "Genus:" line was found), echoed a dict of the
    parsed masses (None per key if that echo line was not found)."""
    genus, err = render(SCAD, part, out, var="Motor_Class", return_log=True)
    # Targeted per-line patterns, not a generic "key: first number" scan
    # (MotorDummy29.scad's own "shell (100% fill): X cm3 = Y g" line has
    # the mass we actually want to cross-check, Y, AFTER the "=", not the
    # first number after the colon (X, the volume) -- a generic scan
    # would have silently compared the wrong quantity).
    echoed = {}
    for key, pattern in (
            ("shell_g", r"shell \(100% fill\):\s*[-0-9.]+\s*cm3\s*=\s*([-0-9.]+)\s*g"),
            ("ballast_loaded_g", r"BALLAST, loaded\s*:\s*([-0-9.]+)\s*g"),
            ("ballast_burnout_g", r"BALLAST, burnout\s*:\s*([-0-9.]+)\s*g")):
        mo = re.search(pattern, err)
        echoed[key] = float(mo.group(1)) if mo else None
    return genus, echoed


def checks(m, echoed):
    """Return list of (label, actual, expected, tolerance)."""
    c = []
    a = lambda p, k: m[p][k]
    for p in m:
        m_od, m_l, m_wet, m_prop = MOTOR_DATA[p]
        body_od = m_od - IDXTRA
        cavity_d = body_od - 2 * WALL
        cavity_l = m_l - END_T
        shell_mm3 = (3.141592653589793 * (body_od / 2) ** 2 * m_l
                     - 3.141592653589793 * (cavity_d / 2) ** 2 * cavity_l)
        shell_cm3 = shell_mm3 / 1000.0
        shell_g = shell_cm3 * FILAMENT_DENSITY
        cavity_cm3 = 3.141592653589793 * (cavity_d / 2) ** 2 * cavity_l / 1000.0

        # Geometry, measured off the rendered mesh -- not trusted from the
        # parameters that were supposed to produce it.
        c += [("Motor_Class %d (%s) OD" % (p, NAMES[p]), a(p, "dmax"),
               body_od, 0.05),
              ("Motor_Class %d (%s) length" % (p, NAMES[p]),
               a(p, "height"), m_l, 0.05)]
        # Fits the SAME MMT the real motor does (MMT_ID_EXPECT, R60Lib.
        # scad's own R60_MMT_ID) -- a REAL clearance check against the
        # rendered OD, not (MMT_ID_EXPECT-body_od) compared to itself,
        # which could never fail regardless of what body_od is. clear is
        # MMT_ID_EXPECT-dmax, a DIAMETER difference, so /2.0 to get the
        # true RADIAL clearance the label promises (a diameter difference
        # is twice the radial gap all the way round). Positive (a genuine
        # slip fit, no interference) and no more than 0.15mm radial (0.25mm
        # radial clearance is already deliberately loose -- MotorDummy29.
        # scad's own comment -- so a real regression would have to be
        # gross before this is too tight to catch it).
        clear = (MMT_ID_EXPECT - a(p, "dmax")) / 2.0
        c += [("Motor_Class %d fits its own 29mm MMT (radial clearance)"
               % p, clear, 0.25, 0.15)]
        # Genus 0 (one-end-open cup, not a sealed void) -- see
        # MotorDummy29.scad's own Cavity_L comment for the -1-vs-0
        # history this cross-checks. A missing genus (render() found no
        # "Genus:" line) must be a loud FAIL (nan, never <= any
        # tolerance), not a TypeError from comparing None -- same idiom
        # verify_rocket60.py/verify_nosecone.py/verify_camnose.py use.
        g = a(p, "genus")
        c += [("Motor_Class %d genus" % p,
               g if g is not None else float("nan"), 0, 0)]
        c += [("Motor_Class %d connected components" % p,
               components(a(p, "stl")), 1, 0)]
        # overshoot() (scad_verify) instead of a bare max(0.0, ...): a nan
        # height (a degenerate, zero-triangle mesh, measure()'s own
        # convention) must fail this loudly, not silently compare as a
        # 0mm overshoot -- see that helper's own docstring.
        c += [("Motor_Class %d fits 250mm Z" % p,
               overshoot(a(p, "height"), 250.0), 0.0, 0.01)]

        # Ballast math, cross-checked mesh-against-echo: the SHELL VOLUME
        # this file computes analytically from its own parameters must
        # match the volume of the mesh it actually exported (a wrong
        # Cavity_d/Cavity_L slip would silently desync the echoed ballast
        # figure from the printed part's real cavity without this).
        # Tolerance is wider than a pure cylinder-minus-cylinder match:
        # the analytic formula (and MotorDummy29.scad's own echo, which
        # uses the identical formula) does not subtract the 2 grip-flat
        # cuts near the aft end, a deliberately minor simplification --
        # measured gap ~0.06cm3 (~0.08g) across all 3 motor classes, small
        # against the multi-hundred-gram ballast figures this check
        # actually guards. 0.15 comfortably covers that known, expected
        # gap while still catching a materially larger regression (a
        # wrong Cavity_d/Cavity_L, not just the unmodelled flats).
        real_shell_cm3 = volume(a(p, "stl"))
        c += [("Motor_Class %d shell volume (analytic vs rendered)" % p,
               shell_cm3, real_shell_cm3, 0.15)]

        ech = echoed.get(p, {})

        def echo_f(key, default=float("nan")):
            v = ech.get(key)
            return v if v is not None else default

        c += [("Motor_Class %d echoed shell mass" % p,
               echo_f("shell_g"), shell_g, 0.01),
              ("Motor_Class %d echoed ballast, loaded" % p,
               echo_f("ballast_loaded_g"), m_wet - shell_g, 0.01),
              ("Motor_Class %d echoed ballast, burnout" % p,
               echo_f("ballast_burnout_g"), m_wet - m_prop - shell_g, 0.01)]

        # Sanity: the shell alone must be LIGHTER than even the burnout
        # target (loose ballast only ever ADDS mass, never removes it) and
        # the required loaded-ballast density must be achievable with
        # loose-packed shot (steel ~4.5, lead ~6.5 g/cm3 -- see
        # MotorDummy29.scad's own comment). Neither is guaranteed by the
        # arithmetic alone: a print that came out too dense/heavy, or a
        # cavity sized too small for the target mass, would both silently
        # fail the ground test's actual purpose without ever tripping a
        # SCAD-side assert.
        dry_g = m_wet - m_prop
        c += [("Motor_Class %d shell lighter than burnout target" % p,
               1.0 if shell_g < dry_g else 0.0, 1.0, 0.0)]
        if cavity_cm3 > 0:
            ballast_density = (m_wet - shell_g) / cavity_cm3
            c += [("Motor_Class %d loaded ballast density achievable "
                   "(<=6.5 g/cm3, loose lead shot)" % p,
                   1.0 if 0 < ballast_density <= 6.5 else 0.0, 1.0, 0.0)]
    return c


def main(argv):
    parts = [int(x) for x in argv[1:]] or [0, 1, 2]
    m, echoed = {}, {}
    tmp = tempfile.mkdtemp(prefix="motordummy29-")
    # (9th review) try/finally: this used to mkdtemp() and never clean up
    # -- see verify_rocket60.py's own main() comment for the measured
    # 16-27 MB/run figure and the two other files sharing this same gap.
    try:
        bad = 0
        for p in parts:
            out = os.path.join(tmp, "motor%d.stl" % p)
            try:
                genus, echoed[p] = render_with_echo(p, out)
            except (RuntimeError, subprocess.TimeoutExpired) as e:
                print("FAIL  render Motor_Class %d (%s)\n%s"
                      % (p, NAMES.get(p, "?"), e))
                bad += 1
                continue
            m[p] = measure(out, genus)
            print("rendered Motor_Class %d %-12s h=%7.2f  dia=%6.2f  vol=%6.2f cm3"
                  % (p, NAMES.get(p, "?"), m[p]["height"], m[p]["dmax"],
                     volume(out)))
        print()
        for (label, actual, expected, tol) in checks(m, echoed):
            ok = abs(actual - expected) <= tol
            bad += 0 if ok else 1
            print("%-4s %-58s %10.4f  want %.4f +/- %.4f"
                  % ("OK" if ok else "FAIL", label, actual, expected, tol))
        print("\n%d check(s) failed" % bad)
        return 1 if bad else 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
