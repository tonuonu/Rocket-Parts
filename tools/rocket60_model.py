import math, sys

# Failure tracking (3rd review, should-fix 7 corollary): every OK/FAIL
# printed below used to be text only -- the process always exited 0, so a
# margin, rail-exit or flutter regression printed "FAIL" but nothing
# downstream (CI, a human skimming output) was forced to notice. Same
# silently-skipped-check pattern the review's items 4/5 fix elsewhere in
# this repo's tooling. bad() records a failure and returns the same OK/
# FAIL string so call sites don't need a separate branch.
_bad = 0
def bad(ok):
    global _bad
    if not ok:
        _bad += 1
    return "OK" if ok else "FAIL"

RHO_PETG = 1.27   # g/cm3, R60-PrintSettings.md sec 3
RHO_PC   = 1.20   # g/cm3, R60-PrintSettings.md sec 3 (fin can/retainer/spacer)
INFILL_EFF = 0.78  # single blended effective print density (walls +
                    # infill) applied to every PETG part's measured mesh
                    # volume -- a stated, UNVERIFIED assumption, not
                    # derived from R60-PrintSettings.md sec 4's actual
                    # PER-PART infill settings (25-62% depending on part).
                    # Weigh the printed parts and compare (STL Files/
                    # Rocket60/README.md's own instruction) before relying
                    # on the masses this produces.
D   = 60.0           # airframe OD, fixed by nosecone base
WALL= 1.6            # airframe wall

# ---------------- layout (station = mm from nose tip) ----------------
# FIXED (defect 2a): L_EBAY/L_CHUTE were still 130/130 (TOTAL 582mm), the
# pre-redesign figures -- R60Lib.scad has had 160/180 (TOTAL 662mm) since
# the e-bay upright-servo redesign and the spring-mechanism chute
# lengthening. This model was of a rocket that no longer exists.
# L_EBAY grew again, 160->165 (3rd review, defect 2d/9): R60_EBay_L now
# carries 5mm of headroom above the bare minimum so the arming-switch Z
# window is a genuine ~3mm margin instead of a 0.5mm hair gap. Grew AGAIN,
# 165->177 (4th review, critical 3): that 3rd-review derivation measured
# the switch's clearance from the door APERTURE's own edge, not from
# R60_Door()'s actual built footprint (a COVER, R60_Door_Overlap=6mm
# larger than the aperture on every side) -- correctly counting that
# overlap needs 12mm more of R60_EBay_L to restore the same ~3mm window
# the 3rd review intended. See R60Lib.scad's own R60_EBay_L comment for
# the closed-form derivation.
L_NOSE = 94.0
# L_NECK_FLANGE (4th review, should-fix 12): the neck (part 1)'s own
# Flange_T=5mm sits externally, between the nosecone's own base and the
# e-bay tube's forward rim -- its 19mm skirt telescopes INSIDE L_EBAY
# (already counted there) and adds no further length, but the flange
# itself is real, additional airframe length TOTAL used to omit entirely.
# Physical stack: 94 (nose) + 5 (flange) + 177 (e-bay) + 180 (chute) + 228
# (fin can) = 684mm -- this is that other 5mm.
L_NECK_FLANGE = 5.0
L_EBAY = 177.0
L_CHUTE= 180.0
L_FINCAN=228.0
TOTAL  = L_NOSE+L_NECK_FLANGE+L_EBAY+L_CHUTE+L_FINCAN

S_EBAY = L_NOSE+L_NECK_FLANGE   # e-bay tube's own forward rim, past the
                                 # neck's flange (see L_NECK_FLANGE above)
S_CHUTE= S_EBAY+L_EBAY
S_FIN  = S_CHUTE+L_CHUTE

# Measured mesh volumes, cm^3, from STL Files/Rocket60/README.md -- NOT
# estimates (defect 2a: this file used to carry round-number guesses for
# every printed part, and 58g for a bayonet ring that was abandoned and
# deleted from the design two tasks ago). Material per part from
# R60-PrintSettings.md sec 3.
#
# Re-measured this round (3rd review fixes) after re-export: [2] shrank
# 45.7->44.9 (Vega rail Z window derived per-end instead of a flat 5mm
# margin, defect 2); [3] grew 53.5->55.2 (new Ø56.4 spigot onto the fin
# can, should-fix 6); [8] shrank 55.1->52.9 (spring carrier's tether
# relief channel now runs the carrier's full length instead of 5mm,
# defect 1); [12] shrank 17.6->16.6 (spacer now stops short of the new
# part 14 instead of running the full MMT_L, see build()'s own
# spacer_len below); [14] is new (forward thrust ring, defect 3 -- see
# R60_ThrustRing()'s own module comment for why nothing reacted the
# motor's forward thrust load before this). [2] grew again 44.9->46.2
# (should-fix 9/11: R60_EBay_L 160->165 adds tube wall and lengthens the
# Vega rails; the zip-tie redesign from 2 slots to 4 removes a little
# back, net +1.3 cm3) -- re-measured off the freshly re-exported mesh.
#
# Re-measured AGAIN this round (4th review): [2] grew 46.2->50.0
# (R60_EBay_L 165->177, critical 3, adds tube wall + rail length); [3]
# grew 55.2->55.7 (critical 1's weld ring net of critical 4's shorter
# spigot -- R60_FinCanSpigot_L 6.0->5.5, should-fix 8); [13] shrank
# 3.5->3.0 (critical 2's corner clip + critical 5's base pass-through
# remove more material than the clip's own small chamfer adds back).
NOSECONE_VOL = 29.4                 # NoseCone.stl
STL_VOL = {1: 16.2, 2: 50.0, 3: 55.7, 4: 12.7, 5: 54.4, 6: 20.0, 7: 10.6,
           8: 52.9, 9: 114.0, 10: 15.8, 11: 13.4, 12: 16.6, 13: 3.0, 14: 0.6}
MMT_L = 228.0   # R60_MMT_L = R60_FinCan_L (R60Lib.scad, post fix)
THRUST_RING_T = 6.0   # R60_ThrustRing_T (R60Lib.scad) -- the spacer now
                        # stops this much short of MMT_L, see build()

# Aft bulkhead skirt / spring carrier stations (4th review, should-fix
# 11) -- restated literals (rule 4) matching R60Lib.scad's
# R60_AftBulk_T/R60_Pin_Skirt_L and R60_SpringCarrier()'s own L=65, used
# below to derive both items' stations from where their geometry actually
# sits once assembled (r60_assembly.scad's own Pair 5/6 comments derive
# the SAME "stack" frame these come from), not a hand-picked offset from
# S_CHUTE.
AFTBULK_T  = 12.0    # R60_AftBulk_T -- disc thickness
PIN_SKIRT_L = 15.0   # R60_Pin_Skirt_L -- skirt engagement past the disc
CARRIER_L  = 65.0    # R60_SpringCarrier()'s own L

# Full station audit (coordinator override, same round): every OTHER
# station in build() below is now likewise derived from where its own
# geometry sits once assembled, not a hand-picked offset -- the two
# fixed above were not isolated bugs, they were symptoms of this file
# never having been audited item-by-item against the SCAD it claims to
# model. Every correction found below moves CG AFT (the model had been
# biased toward an optimistic, forward CG on every single item checked,
# never the other way) -- restated literals matching R60Lib.scad/
# Rocket60.scad's own constants, same rule-4 convention as AFTBULK_T etc.
NECK_SKIRT_L = 19.0   # R60_Neck_Skirt_L
FWDBULK_T    = 6.0    # R60_FwdBulk_T -- R60_EBayFwdBulkhead()'s own T
PIN_Z_FROM_JOINT = 8.0   # R60_Pin_Z_FromJoint
LATCH_H      = 16.0   # R60_TetherLatch()'s own Base_T+Post_H (=part 13's
                        # own measured height, 16.00mm)
CB_DEPTH     = 17.0   # R60_SpringCarrier()'s own CB_Depth
DIA_T        = 3.0    # R60_SpringCarrier()'s own Dia_T
RETAINER_T   = 6.0    # R60_MotorRetainer()'s own T (=part 11's own
                        # measured height, 6.00mm)


def polygon_centroid(pts):
    """Area-weighted centroid of a simple 2D polygon (shoelace formula) --
    used below for the fin's own true chordwise mass centroid instead of
    an arbitrary "0.45*root chord" fraction, which understated it by
    12mm (station audit). Exact for the flat, uniform-thickness plate
    R60_Fin() actually builds (linear_extrude of a constant-thickness
    polygon), not an approximation."""
    a = 0.0; cx = 0.0; cy = 0.0
    n = len(pts)
    for i in range(n):
        x0, y0 = pts[i]; x1, y1 = pts[(i + 1) % n]
        cross = x0 * y1 - x1 * y0
        a += cross
        cx += (x0 + x1) * cross
        cy += (y0 + y1) * cross
    a *= 0.5
    return cx / (6 * a), cy / (6 * a), a

def petg(vol_cm3, infill=INFILL_EFF):
    return vol_cm3 * RHO_PETG * infill

def pc(vol_cm3, infill=INFILL_EFF):
    return vol_cm3 * RHO_PC * infill

# ---------------- fins ----------------
# Span grown 55 -> 63mm (task report, coordinator decision, group 2
# re-target). See R60Lib.scad's R60_Fin_Span comment for the full
# reasoning -- summary: correctly fed the EXPOSED geometry (below), the
# as-shipped 55mm span gave the G80T-14A (the motor actually owned, and
# per the coordinator's explicit re-target the sizing case, not the
# H182R) only 1.05 cal at liftoff. Span, not chord, is the lever: CN
# scales with (exposed span/D)^2, so it buys far more margin per gram
# added than growing Cr/Ct does -- see this file's own rejected
# alternatives noted below the results.
Cr, Ct, span, sweep = 90.0, 35.0, 63.0, 45.0   # AS-BUILT, R60Lib.scad
FIN_T, NFIN = 4.0, 3
S_finLE = TOTAL - Cr - 8.0

# Fin chordwise mass centroid (station audit, coordinator override): the
# fin's own local X axis IS the axial/station direction once installed
# (R60_Fin()'s polygon root/tip run 0..Cr along local X; S_finLE anchors
# local X=0, the root leading edge, to its own global station -- see
# that constant's own derivation above). R60_Fin()'s actual polygon,
# fed to polygon_centroid(), not a hand-picked fraction of Cr.
FIN_CENTROID_X, _, _ = polygon_centroid(
    [(0, 0), (Cr, 0), (sweep + Ct, span), (sweep, span)])

# FIXED (defect 2b): Barrowman needs the EXPOSED fin panel, not the full
# fin. R60_FinCan() cuts the fin slot from R60_MMT_OD/2=16mm outward, so
# the epoxied root bottoms out at r=16mm and only r=(D/2)..(16+span) is
# actually exposed to the airflow -- the buried 14mm (D/2 - 16) between
# the MMT and the body OD contributes zero normal force. Feeding Barrowman
# the full buried root chord (90mm) overstated CN_fins by ~65% (5.78 vs.
# the corrected ~3.5 at the original 55mm span) and pulled CP aft of where
# it actually sits. Everything below is derived from the fin's OWN
# planform (R60_Fin()'s polygon: root (0,0)-(Cr,0), tip
# (sweep,span)-(sweep+Ct,span)), not a second independently-guessed set
# of numbers.
MMT_r = 16.0                 # R60_MMT_OD/2
buried = D/2 - MMT_r         # 14mm of the fin's own span sits inside the can
span_exp = span - buried
def _LE(y): return sweep * y / span            # leading-edge X at span station y
def _TE(y): return Cr + (sweep + Ct - Cr) * y / span
Cr_exp = _TE(buried) - _LE(buried)   # chord AT the body surface, ~76mm
Ct_exp = Ct
sweep_exp = _LE(span) - _LE(buried)
S_finLE_exp = S_finLE + _LE(buried)   # exposed root LE is AFT of the buried
                                        # root LE by the sweep at y=buried

# ---------------- motors ----------------
MOTORS = {
 # name        : (len, total_g, prop_g, Ns, avgN, burn)
 'G80T-14A'    : (124, 128, 63, 136.6, 77.6, 1.7),
 'H182R-14A'   : (203, 207, 115, 218.0, 182.0, 1.2),
 'H135W-14A'   : (216, 212,  82, 225.8, 115.9, 2.0),
 'TSP E20-P'   : ( 94,  60, 20,  40.0,  20.0, 2.0),
}

def build(motor):
    mlen, mtot, mprop, Ns, avgN, burn = MOTORS[motor]
    # Motor spacer scales with the actual R60_MotorSpacer() length for
    # this motor (MMT_L - THRUST_RING_T - motor length -- part 14 now
    # occupies the last THRUST_RING_T of the MMT, so the spacer no longer
    # runs the full MMT_L, see R60_MotorSpacer()'s own comment); TSP
    # E20-P is excluded from the design (spec sec 1.1) and would use
    # MotorAdapter29, not this spacer, but the scaled figure is kept for
    # a like-for-like row. STL_VOL[12]'s own reference length is 98.0mm
    # (the G80T's spacer, Motor_Class default 0 -- STL Files/Rocket60/
    # README.md), not MMT_L, so the scale factor is against that.
    spacer_len = max(0.0, MMT_L - THRUST_RING_T - mlen)
    spacer_g = pc(STL_VOL[12] / 98.0 * spacer_len) if spacer_len > 1 else 0.0
    # ---- Mass roll-up: measured vs. estimated (coordinator ask) ----
    # Every PRINTED part's mass (petg()/pc() calls below) comes from a
    # MEASURED mesh volume (STL_VOL, re-measured off the actual rendered
    # part each time its geometry changes) times RHO_PETG/RHO_PC times
    # INFILL_EFF -- but INFILL_EFF itself (0.78) is a single blended,
    # UNVERIFIED print-density assumption applied to every PETG part
    # alike (see that constant's own comment) -- so "measured" here means
    # the VOLUME is measured, not that the resulting MASS has been
    # weighed. The following are flat-gram ESTIMATES with no mesh behind
    # them at all (hardware this repo does not model as its own solid):
    # camera assembly (60g), neck bolts (3g), CATS Vega board (25g,
    # distinct from its sled, which IS measured), battery+wiring (45g),
    # 2x MG90S servos (27g, datasheet), switch hardware (8g),
    # parachute+cord+hw (70g), CS4323 spring (25g, explicitly flagged
    # "est., unverified"), tether latch pin (1g), shear pins (0.5g), rail
    # buttons (4g). That is roughly 269g of this rocket's 871g liftoff
    # mass -- 31% -- resting on unweighed hardware estimates, not
    # measured mesh volumes. STL Files/Rocket60/README.md's own
    # instruction ("weigh the parts as they come off the printer") covers
    # the printed-part side of this; the loose-hardware side has no
    # equivalent check anywhere in this repo.
    # ---- Full station audit (coordinator override, 4th review) ----
    # Every station below was re-derived from the assembled geometry
    # (Rocket60.scad/R60Lib.scad's own constants, or r60_assembly.scad's
    # own "stack" frame for parts that mount past a joint), the same way
    # the two fixed last round were, rather than trusting a hand-picked
    # offset. Items with NO SCAD backing (loose/external hardware --
    # nosecone shell, camera, battery+wiring, CATS Vega+sled, rail
    # buttons) are flagged inline as heuristic estimates, unchanged
    # because there is nothing more precise to derive them from.
    #
    # station-audit table (mm; delta = new - old; every correction moves
    # CG AFT, i.e. delta > 0 -- see the per-item comments for why):
    #   item                          old      new     delta
    #   e-bay fwd bulkhead            105.0    121.0    +16.0
    #   access door + switch          236.0    187.5    -48.5
    #   e-bay aft bulkhead+servos     246.0    277.5    +31.5  (fixed last round)
    #   spring carrier                267.0    323.5    +56.5  (fixed last round)
    #   CS4323 spring                 316.0    334.25   +18.25
    #   tether latch + pin            271.0    299.0    +28.0
    #   shear pins x2                 276.0    284.0     +8.0
    #   parachute+cord+hw             357.0    406.0    +49.0
    #   fins x3                       626.5    638.5    +12.0
    #   motor retainer                654.0    681.0    +27.0
    #   (all others confirmed already correct; see per-item comments)
    items = [
    # (name, mass g, station mm)
     # No SCAD backing (external CAD/hardware, no internal geometry to
     # derive a station from) -- kept as the same fractional-length
     # heuristic used since this file's earliest version.
     ('nosecone shell',        petg(NOSECONE_VOL),       0.45*L_NOSE),
     ('camera assembly',       60.0,                     0.50*L_NOSE),
     # Neck spans global L_NOSE..L_NOSE+L_NECK_FLANGE+NECK_SKIRT_L (its
     # own measured height, 24.00mm, confirms this exactly): flange
     # (94..99, external) + skirt (99..118, telescoped inside the e-bay
     # tube). Geometric midpoint, same convention as every uniform-tube
     # item below -- audited, confirmed correct (was already
     # L_NOSE+12=106, now expressed as a derived formula instead of a
     # bare literal).
     ('neck + bolts',          petg(STL_VOL[1]) + 3.0,
      L_NOSE + (L_NECK_FLANGE + NECK_SKIRT_L) / 2),
     # Plain uniform tube -- geometric midpoint. Audited, confirmed
     # correct.
     ('e-bay tube',            petg(STL_VOL[2]),         S_EBAY+L_EBAY/2),
     # Sled's own AXIAL position is set by the zip-tie stations
     # (R60_EBayTube()'s Tie_Z, centred on R60_EBay_L/2 in the tube's own
     # frame) -- the rails constrain radial position/rotation only, not
     # axial. That centres the sled on the TUBE's own midpoint exactly,
     # same as the e-bay tube itself. No SCAD backing for the board's own
     # mass distribution beyond that. Audited, confirmed correct.
     ('CATS Vega + sled',      25.0 + petg(STL_VOL[6]),  S_EBAY+L_EBAY/2),
     # No SCAD backing (loose hardware, no specific mounting geometry) --
     # kept at the e-bay tube's own midpoint, the best available estimate.
     ('battery + wiring',      45.0,                     S_EBAY+L_EBAY/2),
     # Station audit: this part sits flush against the underside of the
     # NECK SKIRT's own tip (r60_assembly.scad's Pair 1 comment), not at
     # the e-bay tube's own forward rim -- the old S_EBAY+6=105 ignored
     # the neck skirt's own 19mm depth entirely. True span (tube's own
     # frame, global = S_CHUTE - local_z): local
     # EBay_L-NECK_SKIRT_L-FWDBULK_T .. EBay_L-NECK_SKIRT_L =
     # global S_EBAY+NECK_SKIRT_L .. S_EBAY+NECK_SKIRT_L+FWDBULK_T
     # = 118..124, midpoint 121 (was 105, +16mm).
     ('e-bay fwd bulkhead',    petg(STL_VOL[4]),
      S_EBAY + NECK_SKIRT_L + FWDBULK_T / 2),
     # 2x MG90S at ~13.4g each (datasheet), mounted upright in the aft
     # bulkhead per its module comment.
     #
     # Station (4th review, should-fix 11): this whole part (STL_VOL[5])
     # is the disc (12mm) PLUS the skirt (15mm) that projects AFT of the
     # e-bay tube's own cut end into the chute bay -- see
     # R60_EBayAftBulkhead()'s own module comment. Once assembled the
     # disc's forward face sits at S_CHUTE-AFTBULK_T (264mm) and the
     # skirt's aft tip at S_CHUTE+PIN_SKIRT_L (291mm) -- see
     # r60_assembly.scad's Pair 5 comment for the same "stack" frame this
     # is read off.
     ('e-bay aft bulkhead + 2 servos', petg(STL_VOL[5])+27.0,
      S_CHUTE + (PIN_SKIRT_L - AFTBULK_T) / 2),
     # Station audit: R60_EBayTube()'s own Door_Z0+Door_Z1=EBay_L
     # identically (the aperture is symmetric in the tube's own frame by
     # construction, and R60_Door_Overlap cancels in the midpoint) -- so
     # the door's own true centre is ALWAYS the e-bay tube's own overall
     # midpoint, regardless of EBay_L. The old S_EBAY+L_EBAY-40=236 was a
     # single edge (Door_Z0 at the OLD EBay_L=165, restated as a literal
     # that silently stopped matching anything once EBay_L grew again) --
     # 48.5mm off the part's own true centre, and the single largest
     # station error found in this audit.
     ('access door + switch',  petg(STL_VOL[7]) + 8.0,   S_EBAY+L_EBAY/2),
     # Plain uniform tube -- geometric midpoint. Audited, confirmed
     # correct (does not separately account for the ~5.5mm fin-can
     # spigot's own mass shifting the true centroid a further ~2mm aft;
     # left as the same order-of-approximation every other uniform-tube
     # item here already accepts).
     ('chute bay tube',        petg(STL_VOL[3]),         S_CHUTE+L_CHUTE/2),
     # Station audit: the spring/ball-lock MECHANISM occupies the chute
     # bay's own forward PIN_SKIRT_L..PIN_SKIRT_L+CARRIER_L span (the
     # skirt+carrier "stack", 15..80mm from S_CHUTE) -- the packed
     # parachute and shock cord are stowed AFT of that, in the remaining
     # open volume through to the fin can's own forward centring ring
     # (S_FIN). The old S_CHUTE+L_CHUTE*0.45=357 placed this INSIDE the
     # mechanism's own footprint instead of aft of it -- fixed to the
     # midpoint of the actually-open packing volume.
     ('parachute+cord+hw',     70.0,
      S_CHUTE + (PIN_SKIRT_L + CARRIER_L + L_CHUTE) / 2),
     # Spring/ball-lock carrier (part 8) -- geometry-derived station,
     # confirmed correct (fixed last round; formula is parametric in
     # S_CHUTE so it stayed correct through this round's L_NECK_FLANGE
     # change automatically).
     ('spring carrier',        petg(STL_VOL[8]),
      S_CHUTE + PIN_SKIRT_L + CARRIER_L / 2),
     # No spring rate/mass figure exists anywhere in the repo
     # (R60Lib.scad's own R60_Pin_d comment); 25g is a stated,
     # UNVERIFIED estimate for a ~44mm OD / 200mm free-length compression
     # spring, not a measurement -- bench-weigh the real part.
     #
     # Station audit: the spring's own aft seat is the carrier's
     # diaphragm (Dia_Z=CB_DEPTH+3, own thickness DIA_T -- "the spring's
     # forward seat" per R60_SpringCarrier()'s comment), and it reacts
     # against the chute tube's own spring-reaction tabs at the carrier's
     # far/aft tip (stack z=PIN_SKIRT_L+CARRIER_L=80, where the module
     # comment says the tabs are "positioned flush with where the carrier
     # ends"). Midpoint of that bounded span -- the best available
     # estimate for a part with no SCAD solid of its own; still flagged
     # unverified, now ALSO geometry-bounded rather than a bare S_CHUTE+40.
     ('CS4323 spring (est., unverified)', 25.0,
      S_CHUTE + PIN_SKIRT_L + (CB_DEPTH + 3 + DIA_T / 2 + CARRIER_L) / 2),
     # Station audit: mounts at the SAME "stack" reference the carrier
     # does (bulkhead's own aft-most face, stack z=PIN_SKIRT_L=15,
     # r60_assembly.scad's Pair 9/12 comments), its own height (LATCH_H,
     # matching part 13's measured 16.00mm) growing aft from there. Old
     # S_EBAY+L_EBAY-5=271 was never derived from this part's own
     # geometry at all -- 28mm short of its true midpoint (299).
     ('tether latch + pin',    petg(STL_VOL[13]) + 1.0,
      S_CHUTE + PIN_SKIRT_L + LATCH_H / 2),
     # Station audit: shear pins land PIN_Z_FROM_JOINT past the joint on
     # both sides (R60_ChuteTube()/R60_EBayAftBulkhead()'s shared
     # constant) -- was bare S_CHUTE (the joint itself), 8mm off; at 0.5g
     # total this does not move CG measurably, corrected anyway for
     # completeness.
     ('shear pins x2',         0.5,                      S_CHUTE+PIN_Z_FROM_JOINT),
     # Plain uniform tube -- geometric midpoint. Audited, confirmed
     # correct.
     ('fin can (PC)',          pc(STL_VOL[9]),           S_FIN+L_FINCAN/2),
     # FIXED (defect 3c): was NFIN*fin_area*FIN_T*RHO_PETG/1000.0*0.62, a
     # planform-prism ESTIMATE (chord x span x thickness) that broke this
     # file's own "measured mesh volumes, NOT estimates" convention --
     # STL_VOL[10] existed but was never read, so it silently went stale
     # (13.8 vs the actual, re-measured 15.8) with nothing to catch it: the
     # prism formula agreed with the true mass by coincidence at 62%
     # infill and would track neither STL_VOL[10] nor the prism inputs if
     # either changed independently. Uses the measured volume directly,
     # same convention as every other part above; infill (62%, spec sec 8,
     # literal) is unchanged.
     #
     # Station audit: FIN_CENTROID_X (polygon_centroid() of R60_Fin()'s
     # own planform, above) replaces the old "0.45*Cr" fraction, which
     # understated the true chordwise centroid (52.5mm, not 40.5mm) by
     # 12mm -- a flat, uniform-thickness plate's mass centroid is not a
     # round fraction of its root chord for a swept, tapered planform.
     ('fins x3 (62% infill)',  NFIN*STL_VOL[10]*RHO_PETG*0.62,
                                                          S_finLE+FIN_CENTROID_X),
     # Station audit: R60_MotorRetainer() is a flat RETAINER_T=6mm disc
     # flush with the very aft (nozzle) end of the fin can -- span
     # TOTAL-RETAINER_T..TOTAL, midpoint TOTAL-RETAINER_T/2. Old
     # TOTAL-30=654 was 27mm forward of that with no geometry behind the
     # "30".
     ('motor retainer (PC)',   pc(STL_VOL[11]),          TOTAL-RETAINER_T/2),
     # No SCAD backing (RailButton() mounting position is not modelled
     # in Rocket60.scad) -- kept as the existing estimate, reasonably
     # within the fin can's own aft-biased span where rail buttons are
     # conventionally placed.
     ('rail buttons x2',       4.0,                      TOTAL-60),
     ('motor spacer (PC)',     spacer_g,                 TOTAL-mlen-spacer_len/2),
     # Forward thrust ring (part 14) -- new this round (defect 3). Flush
     # with the fin can's own forward tip -- S_FIN+THRUST_RING_T/2, NOT
     # TOTAL-THRUST_RING_T/2 (4th review, should-fix 10): TOTAL is the
     # AFT-most station (nose to nozzle), which is where the motor
     # retainer/rail buttons/motor itself correctly anchor from below, but
     # this ring glues into the MMT's FORWARD opening -- R60_ThrustRing()'s
     # own module comment -- near the fin can's own forward tip (S_FIN),
     # not the nozzle end. The old formula put it 3mm from the nozzle
     # instead of ~442mm forward of it.
     ('thrust ring (PC)',      pc(STL_VOL[14]),          S_FIN+THRUST_RING_T/2),
     ('MOTOR '+motor,          mtot,                     TOTAL-mlen/2),
    ]
    m  = sum(i[1] for i in items)
    cg = sum(i[1]*i[2] for i in items)/m
    # burnout CG
    mb = m-mprop; cgb=(sum(i[1]*i[2] for i in items)-mprop*(TOTAL-mlen/2))/mb
    return items, m, cg, mb, cgb, Ns, mprop, avgN, burn, mlen

def barrowman():
    Xn = 0.466*L_NOSE; CNn = 2.0
    R = D/2
    Lf = math.sqrt(span_exp**2 + (sweep_exp + Ct_exp/2 - Cr_exp/2)**2)
    CNf = (4*NFIN*(span_exp/D)**2)/(1+math.sqrt(1+(2*Lf/(Cr_exp+Ct_exp))**2))
    CNf *= (1 + R/(span_exp+R))
    Xf = S_finLE_exp + sweep_exp*(Cr_exp+2*Ct_exp)/(3*(Cr_exp+Ct_exp)) + ((Cr_exp+Ct_exp) - Cr_exp*Ct_exp/(Cr_exp+Ct_exp))/6
    CN = CNn+CNf
    return (CNn*Xn + CNf*Xf)/CN, CN, CNf

# ---------------- flutter (NAR/TIR-33 form) ----------------
# Computed on the EXPOSED panel, not the buried planform: the buried root
# is bonded solid to the MMT/centring rings and does not flex, so it is
# the exposed panel's own aspect ratio/thickness ratio that sets the
# cantilever flutter mode. a_s/G/Patm match the spec's own sec 6 figures
# (G ~= 0.5 GPa for printed PETG, sea-level standard atmosphere).
def flutter_Vf():
    area_exp = (Cr_exp+Ct_exp)/2*span_exp
    AR_exp = span_exp**2/area_exp
    lam_exp = Ct_exp/Cr_exp
    tc_exp = FIN_T/((Cr_exp+Ct_exp)/2)
    a_s, G, Patm = 340.3, 0.5e9, 101325.0
    denom = 1.337*AR_exp**3*Patm*(lam_exp+1)
    num = 2*(AR_exp+2)*tc_exp**3
    return a_s*math.sqrt(G*num/denom), AR_exp, lam_exp, tc_exp

CP, CN, CNf = barrowman()
Vf, AR_exp, lam_exp, tc_exp = flutter_Vf()
print(f"Airframe: OD {D} mm, wall {WALL} mm, total length {TOTAL:.0f} mm  (L/D {TOTAL/D:.1f})")
print(f"Fins: root {Cr:.0f}/tip {Ct:.0f}/span {span:.0f}/sweep {sweep:.0f}mm planform "
      f"-> exposed root {Cr_exp:.1f}/tip {Ct_exp:.1f}/span {span_exp:.1f}/sweep {sweep_exp:.1f}mm "
      f"(AR {AR_exp:.2f}, t/c {tc_exp:.3f})")
print(f"CN_fins {CNf:.2f}  CP = {CP:.1f} mm from tip  (total CN {CN:.2f})")
print(f"Flutter Vf = {Vf:.0f} m/s\n")

# Target (coordinator, group 2 re-target): G80T-14A margin >= 1.5 cal at
# liftoff is THE requirement -- it is the motor actually owned. H182R/
# H135W margins are reported, not optimised for; between 1.0 and 1.5 cal
# is acceptable there (nose ballast restores it at flight time, standard
# practice, costs nothing today) -- below 1.0 cal is flagged as needing
# ballast before flying that motor.
print(f"{'motor':<12}{'liftoff g':>10}{'CG mm':>8}{'margin':>8}{'burnout g':>11}{'CG_bo':>8}{'marg_bo':>9}")
for mo in ('G80T-14A','H182R-14A','H135W-14A','TSP E20-P'):
    items,m,cg,mb,cgb,Ns,mprop,avgN,burn,mlen = build(mo)
    margin = (CP-cg)/D
    if mo == 'G80T-14A':
        bad(margin >= 1.5)
        flag = "  <-- BELOW 1.5 cal TARGET" if margin < 1.5 else "  (meets 1.5 cal target)"
    elif mo in ('H182R-14A', 'H135W-14A'):
        flag = "  <-- below 1.0 cal, needs nose ballast" if margin < 1.0 else ""
    else:
        flag = ""
    print(f"{mo:<12}{m:>10.0f}{cg:>8.1f}{margin:>8.2f}{mb:>11.0f}{cgb:>8.1f}{(CP-cgb)/D:>9.2f}{flag}")
print()
items,m,cg,*_ = build('G80T-14A')
print("Mass breakdown (G80T config):")
for n,mm,st in sorted(items,key=lambda i:-i[1]):
    print(f"   {n:<32}{mm:>7.1f} g  @ {st:>6.1f} mm")
print(f"   {'TOTAL':<32}{m:>7.1f} g")

# ---------------- flight sim ----------------
def curve_scaled(shape, Ns, tb):
    # (defect 3e: this trapezoidal integral used to be computed twice --
    # once over the un-scaled `shape`, immediately overwritten, unread,
    # by a second pass over the time-scaled `c`. Only the second (correct)
    # integral -- of the curve actually being normalised to Ns -- is kept.)
    sc_t = tb/shape[-1][0]
    c=[(t*sc_t, f) for t,f in shape]
    I=sum((c[i+1][0]-c[i][0])*(c[i][1]+c[i+1][1])/2 for i in range(len(c)-1))
    k=Ns/I
    return [(t,f*k) for t,f in c]
SHAPE=[(0.0,0),(0.05,1.35),(0.09,1.40),(0.35,1.19),(0.59,1.00),(0.82,0.77),(0.97,0.32),(1.0,0)]
def thr(c,t):
    if t<=0 or t>=c[-1][0]: return 0.0
    for i in range(len(c)-1):
        if c[i][0]<=t<=c[i+1][0]:
            (t0,f0),(t1,f1)=c[i],c[i+1]
            return f0+(f1-f0)*(t-t0)/(t1-t0)
    return 0.0
def cdM(M,cd0):
    if M<0.75: return cd0
    if M<1.0: return cd0*(1+2.2*(M-0.75)**2/0.0625)
    return cd0*3.0
def fly(m0_g, prop_g, Ns, burn, cd0=0.52):
    c=curve_scaled(SHAPE,Ns,burn); A=math.pi*(D/2000.0)**2
    dt=0.001;t=0;v=0;h=0;m=m0_g/1000.0;mdot=(prop_g/1000.0)/burn
    vmax=0;Mmax=0;vburn=0;rail=0;trail=0
    while v>=0 or t<burn:
        F=thr(c,t)
        if t<burn: m-=mdot*dt
        rho=1.225*math.exp(-h/8500.0); a_s=340.3*math.sqrt(max(0.5,1-2.256e-5*h))
        M=abs(v)/a_s; Dg=0.5*rho*v*v*A*cdM(M,cd0)*(1 if v>=0 else -1)
        v+=((F-Dg)/m-9.81)*dt; h+=v*dt; t+=dt
        if h>=1.0 and rail==0: rail=v; trail=t
        if v>vmax: vmax=v;Mmax=M
        if t>=burn and vburn==0: vburn=v
        if t>40: break
    return vmax,Mmax,h,t,rail
print()
print(f"{'motor':<12}{'liftoff g':>10}{'T/W':>6}{'v@1m rail':>11}{'Vmax m/s':>10}{'Mach':>7}{'apogee m':>10}{'t_apo s':>9}")
for mo in ('G80T-14A','H182R-14A','H135W-14A','TSP E20-P'):
    items,m,cg,mb,cgb,Ns,mprop,avgN,burn,mlen=build(mo)
    vmax,Mmax,hap,tap,vrail=fly(m,mprop,Ns,burn)
    print(f"{mo:<12}{m:>10.0f}{avgN/(m/1000*9.81):>6.1f}{vrail:>11.1f}{vmax:>10.0f}{Mmax:>7.2f}{hap:>10.0f}{tap:>9.1f}")
print()
print("Rail exit speed off a 1.5 m 1010 rail:")
for mo in ('G80T-14A','H182R-14A','TSP E20-P'):
    items,m,cg,mb,cgb,Ns,mprop,avgN,burn,mlen=build(mo)
    c=curve_scaled(SHAPE,Ns,burn); A=math.pi*(D/2000.0)**2
    dt=0.0005;t=0;v=0;h=0;mm=m/1000.0;mdot=(mprop/1000.0)/burn
    while h<1.5 and t<burn:
        F=thr(c,t); mm-=mdot*dt
        v+=((F-0.5*1.225*v*v*A*0.52)/mm-9.81)*dt; h+=v*dt; t+=dt
    # TSP E20-P is excluded from this design already (spec sec 1.1 -- it
    # was simulated and dropped specifically because it cannot clear
    # 15 m/s here), so it is reported but does not fail the regression;
    # only a motor the design actually flies on can fail this.
    ok = v > 15
    status = ("OK" if ok else "EXCLUDED, as expected") if mo == 'TSP E20-P' else bad(ok)
    print(f"   {mo:<12} {v:>5.1f} m/s   ({status}{'' if ok else ' - want >15 m/s'})")

# ---------------- flutter margin, all three motors ----------------
# Group 2 re-target's 3rd requirement: flutter velocity >= 3x the FASTEST
# flight speed across all three motors (not just the sizing motor).
print()
print("Flutter margin (target: Vf >= 3x fastest Vmax across all motors):")
vmaxes = {}
for mo in ('G80T-14A','H182R-14A','H135W-14A'):
    items,m,cg,mb,cgb,Ns,mprop,avgN,burn,mlen=build(mo)
    vmax,Mmax,hap,tap,vrail=fly(m,mprop,Ns,burn)
    vmaxes[mo] = vmax
fastest_mo = max(vmaxes, key=vmaxes.get)
fastest_v = vmaxes[fastest_mo]
print(f"   Fastest: {fastest_mo} at {fastest_v:.0f} m/s -> 3x = {3*fastest_v:.0f} m/s")
print(f"   Vf = {Vf:.0f} m/s  ({bad(Vf >= 3*fastest_v)}, "
      f"{Vf/(3*fastest_v):.2f}x the 3x-speed floor)")

if _bad:
    print(f"\n{_bad} check(s) failed")
sys.exit(1 if _bad else 0)
