import math

RHO_PETG = 1.27e-3   # g/mm3
D   = 60.0           # airframe OD, fixed by nosecone base
WALL= 1.6            # airframe wall

def tube_g(L, od=D, wall=WALL, rho=RHO_PETG):
    return math.pi*((od/2)**2-(od/2-wall)**2)*L*rho

# ---------------- layout (station = mm from nose tip) ----------------
L_NOSE = 94.0
L_EBAY = 130.0
L_CHUTE= 130.0
L_FINCAN=228.0
TOTAL  = L_NOSE+L_EBAY+L_CHUTE+L_FINCAN

S_EBAY = L_NOSE
S_CHUTE= S_EBAY+L_EBAY
S_FIN  = S_CHUTE+L_CHUTE

# ---------------- fins ----------------
Cr, Ct, span, sweep = 90.0, 35.0, 55.0, 45.0
FIN_T, NFIN = 4.0, 3
S_finLE = TOTAL - Cr - 8.0

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
    mmt_od, mmt_id, mmt_len = 32.0, 29.0, 223.0
    fin_area = (Cr+Ct)/2*span
    items = [
    # (name, mass g, station mm)
     ('nosecone shell',        37.0, 0.45*L_NOSE),
     ('camera assembly',       60.0, 0.50*L_NOSE),
     ('neck + bolts',          22.0, L_NOSE+12),
     ('e-bay tube',            tube_g(L_EBAY),           S_EBAY+L_EBAY/2),
     ('CATS Vega + sled',      25.0+35.0,                S_EBAY+L_EBAY/2),
     ('battery + wiring',      45.0,                     S_EBAY+L_EBAY/2),
     ('e-bay bulkheads',       24.0,                     S_EBAY+L_EBAY/2),
     ('chute bay tube',        tube_g(L_CHUTE),          S_CHUTE+L_CHUTE/2),
     ('parachute+cord+hw',     70.0,                     S_CHUTE+L_CHUTE*0.45),
     ('bayonet + 2 servos',    58.0,                     S_CHUTE+8),
     ('fin can tube',          tube_g(L_FINCAN),         S_FIN+L_FINCAN/2),
     ('MMT',   math.pi*((mmt_od/2)**2-(mmt_id/2)**2)*mmt_len*RHO_PETG, S_FIN+L_FINCAN/2),
     ('centering rings x3',    3*math.pi*((D/2-WALL)**2-(mmt_od/2)**2)*3.0*RHO_PETG, S_FIN+L_FINCAN/2),
     ('fins x3 (60% infill)',  NFIN*fin_area*FIN_T*RHO_PETG*0.62, S_finLE+0.45*Cr),
     ('retainer + rail buttons',26.0, TOTAL-30),
     ('MOTOR '+motor,          mtot, TOTAL-mlen/2),
    ]
    m  = sum(i[1] for i in items)
    cg = sum(i[1]*i[2] for i in items)/m
    # burnout CG
    mb = m-mprop; cgb=(sum(i[1]*i[2] for i in items)-mprop*(TOTAL-mlen/2))/mb
    return items, m, cg, mb, cgb, Ns, mprop, avgN, burn, mlen

def barrowman():
    Xn = 0.466*L_NOSE; CNn = 2.0
    R = D/2
    Lf = math.sqrt(span**2 + (sweep + Ct/2 - Cr/2)**2)
    CNf = (4*NFIN*(span/D)**2)/(1+math.sqrt(1+(2*Lf/(Cr+Ct))**2))
    CNf *= (1 + R/(span+R))
    Xf = S_finLE + sweep*(Cr+2*Ct)/(3*(Cr+Ct)) + ((Cr+Ct) - Cr*Ct/(Cr+Ct))/6
    CN = CNn+CNf
    return (CNn*Xn + CNf*Xf)/CN, CN, CNf

CP, CN, CNf = barrowman()
print(f"Airframe: OD {D} mm, wall {WALL} mm, total length {TOTAL:.0f} mm  (L/D {TOTAL/D:.1f})")
print(f"Fins: {NFIN}x  Cr {Cr} Ct {Ct} span {span} sweep {sweep} t {FIN_T} mm   CN_fins {CNf:.2f}")
print(f"CP = {CP:.1f} mm from tip  (total CN {CN:.2f})\n")

print(f"{'motor':<12}{'liftoff g':>10}{'CG mm':>8}{'margin':>8}{'burnout g':>11}{'CG_bo':>8}{'marg_bo':>9}")
for mo in ('G80T-14A','H182R-14A','H135W-14A','TSP E20-P'):
    items,m,cg,mb,cgb,Ns,mprop,avgN,burn,mlen = build(mo)
    print(f"{mo:<12}{m:>10.0f}{cg:>8.1f}{(CP-cg)/D:>8.2f}{mb:>11.0f}{cgb:>8.1f}{(CP-cgb)/D:>9.2f}")
print()
items,m,cg,*_ = build('G80T-14A')
print("Mass breakdown (G80T config):")
for n,mm,st in sorted(items,key=lambda i:-i[1]):
    print(f"   {n:<26}{mm:>7.1f} g  @ {st:>6.1f} mm")
print(f"   {'TOTAL':<26}{m:>7.1f} g")

# ---------------- flight sim ----------------
def curve_scaled(shape, Ns, tb):
    I=sum((shape[i+1][0]-shape[i][0])*(shape[i][1]+shape[i+1][1])/2 for i in range(len(shape)-1))
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
