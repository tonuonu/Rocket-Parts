include<TubesLib.scad>
use<FinCan2Lib.scad>
$fn=36; IDXtra=0.2; Overlap=0.05;
OD=LOC65Body_OD*CF_Comp+0.3;
FC2_TailConeLight(Body_OD=OD, MotorTube_OD=LOC29Body_OD,
    nFins=5, Fin_Root_W=6, Fin_Root_L=130, Fin_Post_h=12, Fin_Chamfer_L=20,
    Threaded=false, Cone_Len=30, Interface_OD=LOC65Body_ID-1,
    FinInset_Len=5, Wall_t=1.2, Extra_OD=2);
