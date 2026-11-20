include<TubesLib.scad>
use<FinCan2Lib.scad>
use<Fins.scad>

$fn=90;
IDXtra=0.2;
Overlap=0.05;

OD=LOC65Body_OD*1.0031+0.3;

rotate([180,0,0])
FC2_FinCanLight(Body_OD=OD, Body_ID=LOC65Body_ID*1.0031, Can_Len=140,
    MotorTube_OD=LOC29Body_OD,
    nFins=5, HasIntegratedCoupler=true, HasFwdCenteringRing=false, Coupler_Len=10, nCouplerBolts=0,
    HasMotorSleeve=true,
    Fin_Root_W=6, Fin_Root_L=130, Fin_Post_h=12, Fin_Chamfer_L=20,
    Cone_Len=30, ThreadedTC=false, Extra_OD=0,
    LowerHalfOnly=false, UpperHalfOnly=false,
    Wall_t=1.2,
    AftClosure_OD=0, AftClosure_Len=0, IncludeCenteringRings=false);
