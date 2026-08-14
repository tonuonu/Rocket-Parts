import math

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
L_NOSE = 94.0
L_EBAY = 160.0
L_CHUTE= 180.0
L_FINCAN=228.0
TOTAL  = L_NOSE+L_EBAY+L_CHUTE+L_FINCAN

S_EBAY = L_NOSE
S_CHUTE= S_EBAY+L_EBAY
S_FIN  = S_CHUTE+L_CHUTE

# Measured mesh volumes, cm^3, from STL Files/Rocket60/README.md -- NOT
# estimates (defect 2a: this file used to carry round-number guesses for
# every printed part, and 58g for a bayonet ring that was abandoned and
# deleted from the design two tasks ago). Material per part from
# R60-PrintSettings.md sec 3.
#
# STL_VOL[10] and [13] re-measured this round (defect 3c / re-export
# after this round's SCAD fixes): [10] was 13.8, the pre-fin-growth fin
# volume (stale -- the fin span grew 55->63mm since, and this entry was
# never actually READ by the fin mass line below, which computed a
# separate planform-prism estimate instead; both are fixed together
# below). [13] grew 3.3->3.5 as a direct consequence of this round's
# defect 2b fix (R60_TetherLatch()'s Base_L: 36.0->38.6mm).
NOSECONE_VOL = 29.4                 # NoseCone.stl
STL_VOL = {1: 16.2, 2: 45.7, 3: 53.5, 4: 12.7, 5: 54.4, 6: 20.0, 7: 10.6,
           8: 55.1, 9: 114.0, 10: 15.8, 11: 13.4, 12: 17.6, 13: 3.5}
MMT_L = 228.0   # R60_MMT_L = R60_FinCan_L (R60Lib.scad, post fix)

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
    # this motor (MMT_L - motor length); TSP E20-P is excluded from the
    # design (spec sec 1.1) and would use MotorAdapter29, not this
    # spacer, but the scaled figure is kept for a like-for-like row.
    spacer_len = max(0.0, MMT_L - mlen)
    spacer_g = pc(STL_VOL[12] / 104.0 * spacer_len) if spacer_len > 1 else 0.0
    items = [
    # (name, mass g, station mm)
     ('nosecone shell',        petg(NOSECONE_VOL),       0.45*L_NOSE),
     ('camera assembly',       60.0,                     0.50*L_NOSE),
     ('neck + bolts',          petg(STL_VOL[1]) + 3.0,   L_NOSE+12),
     ('e-bay tube',            petg(STL_VOL[2]),         S_EBAY+L_EBAY/2),
     ('CATS Vega + sled',      25.0 + petg(STL_VOL[6]),  S_EBAY+L_EBAY/2),
     ('battery + wiring',      45.0,                     S_EBAY+L_EBAY/2),
     ('e-bay fwd bulkhead',    petg(STL_VOL[4]),         S_EBAY+6),
     # 2x MG90S at ~13.4g each (datasheet), mounted upright in the aft
     # bulkhead per its module comment.
     ('e-bay aft bulkhead + 2 servos', petg(STL_VOL[5])+27.0, S_EBAY+L_EBAY-13),
     ('access door + switch',  petg(STL_VOL[7]) + 8.0,   S_EBAY+L_EBAY-40),
     ('chute bay tube',        petg(STL_VOL[3]),         S_CHUTE+L_CHUTE/2),
     ('parachute+cord+hw',     70.0,                     S_CHUTE+L_CHUTE*0.45),
     # Spring/ball-lock carrier (part 8) and the CS4323 spring it holds --
     # missing entirely before this fix. No spring rate/mass figure exists
     # anywhere in the repo (R60Lib.scad's own R60_Pin_d comment); 25g is
     # a stated, UNVERIFIED estimate for a ~44mm OD / 200mm free-length
     # compression spring, not a measurement -- bench-weigh the real part.
     ('spring carrier',        petg(STL_VOL[8]),         S_CHUTE+8),
     ('CS4323 spring (est., unverified)', 25.0,          S_CHUTE+40),
     # Tether latch (part 13) -- also missing entirely before this fix.
     ('tether latch + pin',    petg(STL_VOL[13]) + 1.0,  S_EBAY+L_EBAY-5),
     ('shear pins x2',         0.5,                      S_CHUTE),
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
     ('fins x3 (62% infill)',  NFIN*STL_VOL[10]*RHO_PETG*0.62,
                                                          S_finLE+0.45*Cr),
     ('motor retainer (PC)',   pc(STL_VOL[11]),          TOTAL-30),
     ('rail buttons x2',       4.0,                      TOTAL-60),
     ('motor spacer (PC)',     spacer_g,                 TOTAL-mlen-spacer_len/2),
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
    print(f"   {mo:<12} {v:>5.1f} m/s   ({'OK' if v>15 else 'MARGINAL - want >15 m/s'})")

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
print(f"   Vf = {Vf:.0f} m/s  ({'OK' if Vf >= 3*fastest_v else 'FAIL'}, "
      f"{Vf/(3*fastest_v):.2f}x the 3x-speed floor)")
