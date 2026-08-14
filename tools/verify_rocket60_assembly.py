#!/usr/bin/env python3
"""Assembly-interference check for Rocket 60: for every mating pair in the
printed stack, render BOTH parts in their real assembled relative position
(tools/r60_assembly.scad) and assert the intersection() volume is zero.

This exists because three rounds of review found interference that no
per-part dimension check can see: two parts can each individually pass
every check in verify_rocket60.py and still collide once actually
assembled, because the collision only exists in the RELATIVE position
between them (a rail that runs the tube's full length is fine on its own;
it only fails once you also place the neck's skirt where it actually
seats). intersection() + measured volume is the only check that is
looking at the same thing an assembler's hands would find.

Where a joint has a stroke -- the chute tube telescopes over the e-bay
aft bulkhead's skirt and the spring carrier as they're bonded together
during assembly -- checked ALONG the stroke (Ins=0..80mm), not only at
the final seated position: a joint can be clear when fully seated and
still jam partway through assembly (exactly what defect 1 does: clear at
the seated position, but the tether lug catches solid carrier material
partway through the stroke and the rocket cannot be assembled at all).
"""
import os, subprocess, sys, tempfile

from scad_verify import REPO, OPENSCAD, volume
import verify_rocket60 as vr60

SCAD = os.path.join(REPO, "tools", "r60_assembly.scad")

# Zero-volume tolerance. A genuinely clear fit renders a truly EMPTY
# solid (OpenSCAD: "Current top level object is empty", no output file at
# all) -- there is no meshing/triangulation noise to tolerate the way
# there can be for two independently-rendered, non-intersected meshes.
# 0.001 cm3 (1 mm3) is generous headroom above that while still catching
# every defect this file has found so far by 1-2 orders of magnitude
# (0.0211-0.42 cm3).
EPS_CM3 = 0.001

PAIRS = {
    0: "neck vs e-bay tube",
    1: "e-bay fwd bulkhead vs e-bay tube",
    2: "e-bay aft bulkhead vs e-bay tube",
    3: "vega sled vs e-bay tube",
    4: "access door vs e-bay tube",
    5: "aft bulkhead skirt vs chute tube (stroke)",
    6: "spring carrier vs chute tube (stroke)",
    7: "chute tube vs fin can",
    8: "motor spacer vs MMT (fin can)",
    9: "tether latch vs aft bulkhead",
    10: "thrust ring obstructs motor+spacer (forward trap)",
    11: "motor retainer obstructs motor (aft trap)",
    # 4th review, harness item 2 (complete the pair matrix) -- see
    # r60_assembly.scad's own pair-enumeration comment block for the full
    # part-by-part table this was read off, including what was
    # deliberately excluded and why.
    12: "tether latch vs spring carrier",
    13: "tether latch vs chute tube (stroke)",
    14: "spring carrier vs aft bulkhead",
    # Not part-vs-part -- a declared MOVING ELEMENT's required path
    # (harness item 3) vs. the real part(s) around it.
    15: "servo-2 horn/pin-release path vs tether latch",
    16: "arming switch envelope vs access door",
}
STROKE_PAIRS = (5, 6, 13)
# Insertion stroke sweep -- 0 (first contact) through 80 (fully seated,
# shear pins aligned -- see r60_assembly.scad's Pair 5/6 comment for the
# derivation).
#
# 4th review, harness item 5: this used to be a fixed 5mm grid while the
# comment here claimed a "closing to 1mm near the transition" refinement
# pass that did not exist anywhere in this file -- a jam narrower than
# 5mm, sitting entirely BETWEEN two clean coarse samples, would read a
# clean pass at every one of them (finding 1, 3rd review, was exactly
# this shape: clear at Ins=0 and at full seating, solid for most of the
# middle of the stroke). A refine-near-hits scheme cannot fix this
# either: there is no hit to refine around when both flanking coarse
# samples are already clean. The only sweep that can actually promise
# "nothing narrower than Xmm slips through" is one sampled AT Xmm
# throughout -- so this is now a genuine, unconditional 1mm sweep (81
# samples per stroke pair), not a coarse pass with a refinement step.
INS_SWEEP = list(range(0, 81, 1))

# Obstruction-proof pairs (defect 3, the missing forward thrust ring):
# INVERTED polarity from every other pair here. Push=0 is the normal
# assembled (flush, touching) position and must be clear, same as every
# other pair; Push=OVERTRAVEL_MM simulates the motor+spacer stack (10) or
# the motor (11) being driven a few mm past its resting position under
# load, and for a joint that actually obstructs, THAT must come back
# NON-zero -- solid material genuinely colliding, not passing through an
# oversized bore. OBSTRUCT_MIN_CM3 is deliberately far above EPS_CM3 (by
# 1-2 orders of magnitude, matching every real defect this file has
# found) so this cannot pass on meshing noise.
OBSTRUCTION_PAIRS = (10, 11)
OVERTRAVEL_MM = 2.0
OBSTRUCT_MIN_CM3 = 0.01


def render_probe(pair, ins, out, facing_y=None, push=0.0, sw_z=None):
    """Render one assembly-probe pair to ASCII STL. Returns the measured
    intersection volume in cm3 -- 0.0 for a genuinely empty intersection
    (OpenSCAD's own "Current top level object is empty", the expected
    result for a clean mating fit), not an error: a per-part render
    failing empty (scad_verify.render()'s convention) means something
    went wrong, but an assembly PROBE failing empty means the fit is
    clean, which is the good outcome, not a bug."""
    env = dict(os.environ, OPENSCADPATH=REPO)
    args = [OPENSCAD, "--export-format", "asciistl", "-o", out,
            "-D", "Pair=%d" % pair]
    if pair in STROKE_PAIRS:
        args += ["-D", "Ins=%d" % ins]
    if pair == 3:
        args += ["-D", "Facing_Y=%.4f" % facing_y]
    if pair in OBSTRUCTION_PAIRS:
        args += ["-D", "Push=%.3f" % push]
    if pair == 16:
        args += ["-D", "SwZ=%.4f" % sw_z]
    args += [SCAD]
    r = subprocess.run(args, capture_output=True, text=True, env=env,
                        timeout=900)
    err = r.stdout + r.stderr
    if "Current top level object is empty" in err:
        return 0.0
    if (r.returncode != 0 or "ERROR:" in err.upper()
            or "Can't find include file" in err
            or "Ignoring unknown module" in err):
        raise RuntimeError("render of pair %d (Ins=%s) failed:\n%s"
                            % (pair, ins, err[-2000:]))
    if not os.path.exists(out) or os.path.getsize(out) < 10:
        return 0.0
    return volume(out)


def measure_facing_y(tmp):
    """Vega sled's rail-contact Y, measured off part 2's own rendered
    rails -- reuses verify_rocket60.py's rail_facing_gap()/RAIL_INNER_R/
    RAIL_Z_CAP so Pair 3's placement is derived from the SAME mesh
    measurement that file's own sled-fit check uses, not a second,
    independently-typed number (rule 4)."""
    out = os.path.join(tmp, "ebaytube_for_facing_y.stl")
    vr60.render(vr60.SCAD, 2, out)
    _, facing_y = vr60.rail_facing_gap(out, vr60.RAIL_INNER_R, vr60.RAIL_Z_CAP)
    return facing_y


def measure_switch_z(tmp):
    """Arming switch hole's own measured Z centre, off part 2's rendered
    mesh -- reuses verify_rocket60.py's switch_hole_z() so Pair 16's
    switch-envelope probe is derived from the SAME mesh measurement that
    file's own arming-switch-Z check uses, not a second, independently-
    typed number (rule 4), and specifically not the kind of restated-
    formula drift (Sw_Z0 silently omitting R60_Door_Overlap) that caused
    finding 3 in the first place."""
    out = os.path.join(tmp, "ebaytube_for_switch_z.stl")
    vr60.render(vr60.SCAD, 2, out)
    return vr60.switch_hole_z(out)


def main(argv):
    pairs = [int(x) for x in argv[1:]] or sorted(PAIRS)
    tmp = tempfile.mkdtemp(prefix="r60asm-")
    bad = 0

    # 4th review, harness item 6: measure_facing_y()/measure_switch_z()
    # both call render() (scad_verify.py), which raises RuntimeError or
    # subprocess.TimeoutExpired on a failed/slow render -- every OTHER
    # render call in this file (render_probe(), below) is already guarded
    # for exactly that; these two were not, so a failed part-2 render used
    # to kill the WHOLE run with a raw traceback instead of a clean FAIL
    # on just the pair(s) that needed the measurement. A failure here now
    # drops only that pair from the run.
    facing_y = None
    if 3 in pairs:
        try:
            facing_y = measure_facing_y(tmp)
            print("measured Vega sled rail-contact Y = %.3fmm\n" % facing_y)
        except (RuntimeError, subprocess.TimeoutExpired) as e:
            print("FAIL  pair 3 setup (measure_facing_y): %s" % e)
            bad += 1
            pairs = [p for p in pairs if p != 3]

    sw_z = None
    if 16 in pairs:
        try:
            sw_z = measure_switch_z(tmp)
            print("measured arming switch hole Z centre = %.3fmm\n" % sw_z)
        except (RuntimeError, subprocess.TimeoutExpired) as e:
            print("FAIL  pair 16 setup (measure_switch_z): %s" % e)
            bad += 1
            pairs = [p for p in pairs if p != 16]

    for p in pairs:
        name = PAIRS.get(p, "?")
        if p in STROKE_PAIRS:
            worst = (0.0, None)
            for ins in INS_SWEEP:
                out = os.path.join(tmp, "pair%d_ins%d.stl" % (p, ins))
                try:
                    vol = render_probe(p, ins, out)
                except (RuntimeError, subprocess.TimeoutExpired) as e:
                    print("FAIL  pair %d %-42s Ins=%3d  render error: %s"
                          % (p, name, ins, e))
                    bad += 1
                    continue
                ok = vol <= EPS_CM3
                bad += 0 if ok else 1
                print("%-4s pair %d %-42s Ins=%3dmm  %.4f cm3"
                      % ("OK" if ok else "FAIL", p, name, ins, vol))
                if vol > worst[0]:
                    worst = (vol, ins)
            print("      -> worst along stroke: %.4f cm3 at Ins=%s\n"
                  % worst)
        elif p in OBSTRUCTION_PAIRS:
            try:
                out0 = os.path.join(tmp, "pair%d_push0.stl" % p)
                vol0 = render_probe(p, None, out0, push=0.0)
                out1 = os.path.join(tmp, "pair%d_push.stl" % p)
                vol1 = render_probe(p, None, out1, push=OVERTRAVEL_MM)
            except (RuntimeError, subprocess.TimeoutExpired) as e:
                print("FAIL  pair %d %-42s  render error: %s" % (p, name, e))
                bad += 1
                continue
            ok0 = vol0 <= EPS_CM3
            ok1 = vol1 >= OBSTRUCT_MIN_CM3
            bad += 0 if ok0 else 1
            bad += 0 if ok1 else 1
            print("%-4s pair %2d %-42s  flush (Push=0):    %.4f cm3"
                  % ("OK" if ok0 else "FAIL", p, name, vol0))
            print("%-4s pair %2d %-42s  overtravel (%.0fmm): %.4f cm3"
                  % ("OK" if ok1 else "FAIL", p, name, OVERTRAVEL_MM, vol1))
        else:
            out = os.path.join(tmp, "pair%d.stl" % p)
            try:
                vol = render_probe(p, None, out, facing_y=facing_y, sw_z=sw_z)
            except (RuntimeError, subprocess.TimeoutExpired) as e:
                print("FAIL  pair %d %-42s  render error: %s" % (p, name, e))
                bad += 1
                continue
            ok = vol <= EPS_CM3
            bad += 0 if ok else 1
            print("%-4s pair %d %-42s  %.4f cm3"
                  % ("OK" if ok else "FAIL", p, name, vol))

    print("\n%d check(s) failed" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
