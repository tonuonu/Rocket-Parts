// *********************************************
// Project: 2.6 inch rocket depoyment system
// Filename: Rocket6551.scad
// by David M. Flynn
// Modified: Tõnu Samuel (CATS Vega, metric hardware)
// Created: 9/18/2025
// Revision: 2.0.0  3/4/2026
// Units: mm
// *********************************************
//  ***** Notes *****
//
//  This is a 2.6 inch diameter rocket, single deploy
//  Uses CableReleaseBBMini and CATS Vega flight computer.
//  CATS Vega PWM output drives servo directly (no RocketServo PCB).
//  CATS Vega magnetic arming (no external switch needed).
//  Uses one 4323CS spring and petal deployment system (non-pyro).
//  All metric hardware: M6 center rod, M5 outer bolts, M3 board mount.
//
//
//  Assemble single deploy for flight:
//		1) Assemble entire ebay from spacer to NoseCone; parachutes, battery, everything.
//		2) Slide airframe over and secure with rivets.
//		3) Stack onto fincan. Airframe and fincan should be tight against each other.
//
//  ***** History *****
// 2.0.0   3/4/2026   CATS Vega e-bay, metric hardware, 3D printed body tube.
// 1.0.0   10/25/2025 Just a little clean up.
// 0.9.11  10/23/2025 R65_EBayMiddleRing() now has 6 rivet holes.
// 0.9.10  10/23/2025 Moved ebays to R65Lib.scad
// 0.9.9   10/21/2025 Moved common routines to R65Lib.scad, working on the 2 stage/dual deploy version
// 0.9.8   9/29/2025  Got one finished, work on booster for 2 stage version.
// 0.9.7   9/28/2025  Mission Control EBay, 38mm motor, GPS mount
// 0.9.6   9/26/2025  cleanup, added new variants
// 0.9.5   9/24/2025  Petal locks now 30°. More changes to fin can.
// 0.9.4   9/23/2025  Making all the parts smaller, thinner and lighter.
// 0.9.3   9/21/2025  Added vent holes to FwdSpringEnd. New fin/nosecone shape "Little Bird".
// 0.9.2   9/21/2025  Code cleanup and small fixes. Changed fin post to 12mm.
// 0.9.1   9/20/2025  It's comming together, printing and building...
// 0.9.0   9/18/2025  Copied from RocketScooter
//
//  ***** Hardware *****
//
// M6 threaded rod ~250mm + M6 nuts (4 req) — center rod
// M5 x 12mm socket head cap screw (4 req) — e-bay plate outer bolts
// M3 x 10mm socket head cap screw (3 req) — CATS Vega board mount
// M3 nut (3 req) — board retention
// MR84-2RS Bearing (3 req) — Ball Lock
// 5/16" Delrin Ball (3 req) — Ball Lock
// 4mm Dia. x 16mm Undersize Steel Dowel (3 req) — Ball Lock
// 3/16" Dia x 1/8" Disc Magnet N42 (2 req) — Ball Lock
// MG90S Micro Servo (1 req) — Ball Lock (driven by CATS Vega PWM)
// CATS Vega Flight Computer
// 2S LiPo battery (≤55 x 30 x 15mm)
// CS4323 Spring (1 req) — deployment
// 5/16" Dia x 1-1/4" Spring (3 req) — PetalHub
// 36" Parachute
// 1/2" Braided Nylon Shock Cord (6m)
//
// *********************************************
//  ***** for STL output *****
//
//
// *** Nose Cone ***
// NoseCone();
//
// *** Petal Deployment ***
// R65_PetalHub(OD=Coupler_OD, nPetals=nPetals, nBolts=nPetals*2, Skirt_h=5, HasWirePath=false); // also nosecone base
// rotate([-90,0,0]) PD_PetalSpringHolder();
// rotate([180,0,0]) PD_Petals(OD=Coupler_OD, Len=Petal_Len, nPetals=nPetals, Wall_t=1.6, AntiClimber_h=4, HasLocks=true, Lock_Span_a=30);
// R65_FwdSpringEnd(OD=Coupler_OD, ID=Coupler_ID, LockPin_d=16, nRopes=6, Skirt_h=25, HasServoConnector=false);
// R65_SpringSliderLight(OD=Coupler_OD, Len=35);
//
// *** CableReleaseBBMini ***
//  CRBBm_CenteringRingMount(OD=Body_ID, Thickness=7, Spring_OD=SE_Spring_CS4323_OD(), Spring_ID=SE_Spring_CS4323_ID());
//  CRBBm_ExtensionRod(LockPin_d=LockPin_d, Len=26, ID=CV_M5_d, Light=true);
//  CRBBm_LockingPin(nBalls=nBalls, LockPin_d=LockPin_d, LockPin_Len=LockPin_Len, GuidePoint=GuidePoint);
//  rotate([180,0,0]) CRBBm_LockRing(LockPin_d=LockPin_d, nBalls=nBalls, GuidePoint=false, Light=true);
//	rotate([180,0,0]) CRBBm_TopRetainer(LockPin_d=LockPin_d, nBalls=nBalls, LockRing_d=CRBBm_LockRingDiameter(), Flange_t=TopRetainerFlange_t, OD=0, HasMountingBolts=true, GuidePoint=GuidePoint, Light=true);
//  CRBBm_OuterBearingRetainer(Light=true);
//  rotate([180,0,0]) CRBBm_TriggerPost();
//  rotate([180,0,0]) CRBBm_MagnetBracket();
//  CRBBm_Activator(OD=Coupler_OD, Thread_d=MotorBolt_d, Thread_p=MotorBoltPitch);
//
// *** CATS Vega E-Bay (metric) ***
// R65_EBayCV_Sled(OD=Coupler_OD);
// R65_EBayCV_TopPlate(OD=Coupler_OD);
//
// *** Single Deploy Spacer ***
// Tube(OD=Coupler_OD, ID=Coupler_OD-2.4, Len=Spacer_Len, myfn=$preview? 90:180);
//
// *** Motor Mount ***
// rotate([180,0,0]) R65_MotorTubeTopper(OD=Body_ID, ID=MotorTube_OD, MT_ID=MotorTube_ID-3);
// R65_MotorNutStop(MT_ID=MotorTube_ID, Hole_d=MotorBolt_d);
//
// *** Fin Can and Fins ***
// rotate([180,0,0]) Fincan(LowerHalfOnly=false, UpperHalfOnly=false);
// rotate([0,0,90]) RocketFin(HasSpiralVaseRibs=false, PrinterBrim_H=0.6);
//
//
// *** Rail Buttons ***
// RailButton(OD=11, Flange_h=2, Slot_w=2.8);  // for 1010 Rail
//
// *********************************************
//  ***** for Viewing *****
//
// ShowRocket(ShowInternals=false);
 ShowRocket(ShowInternals=true);
//
// *********************************************

include<TubesLib.scad>
use<AT_RMS_Lib.scad>		 echo(AT_RMS_Lib_Rev());
use<SpringEndsLib.scad>      echo(SpringEndsLibRev());
use<PetalDeploymentLib.scad> echo(PetalDeploymentLibRev());
use<CableReleaseBBMini.scad> echo(CableReleaseBBMiniRev());
use<ThreadLib.scad>          echo(ThreadLibRev());
use<SG90ServoLib.scad>       echo(SG90ServoLibRev());
use<Fins.scad>               echo(FinsRev());
use<FinCan2Lib.scad>         echo(FinCan2LibRev());
use<NoseCone.scad>           echo(NoseConeRev());
use<RailGuide.scad>          echo(RailGuideRev());
use<R65Lib.scad>			 echo(R65Lib_Rev());
include<Stager75BBLib.scad>  echo(Stager75BBLib_Rev());
use<R65_EBayCV.scad>		 echo(R65_EBayCV_Rev());

// Also included
//include<CommonStuffSAEmm.scad>

$fn=$preview? 36:90;
IDXtra=0.2;
Overlap=0.05;

Bolt4Inset=4;
Bolt10Inset=5.5;
LooseFit=0.8; // add to hole ID

Body_OD=LOC65Body_OD;
Body_ID=LOC65Coupler_OD+0.8; // 65.6mm, 0.8mm clearance over Coupler_OD for FDM fit
Coupler_OD=LOC65Coupler_OD;
Coupler_ID=Coupler_OD-1.8; // thin wall

nPetals=3;

LockPin_d=16; // OD is determined by the bearing OD so making this smaller doesn't change the OD
LockPin_Len=25;
TopRetainerFlange_t=4;
nBalls=3;
GuidePoint=false;
Spring_OD=SE_Spring_CS4323_OD();
Spring_ID=SE_Spring_CS4323_ID();

// ========== Metric hardware constants ==========
CV_M6_d=6.0;       // center rod
CV_M6_p=1.0;
CV_M5_d=5.0;       // outer plate bolts
CV_M5_p=0.8;

// ========== E-Bay dimensions ==========
EBay_Len=CV_EBay_Len();  // 120mm, exported function from R65_EBayCV.scad

// ========== 3D Printed Body Tube ==========

/*
// Original nose cone
NC_Len=155;
NC_Base_L=6;
NC_Tip_R=5;
NC_Wall_t=1.2;
/**/

/*
// More Pointy
NC_Len=185;
NC_Base_L=6;
NC_Tip_R=4;
NC_Wall_t=1.2;
/**/

/*
// Little Blue Data
Petal_Len=120; // 80 minimum, 100,120 or 140 is preferred 140 is max for a single 4323 spring
MotorTube_OD=LOC29Body_OD;
MotorTube_ID=LOC29Body_ID;
MotorBolt_d=CV_M6_d;          // M6 center rod
MotorBoltPitch=CV_M6_p;

MotorTubeLen=304;
BodyTubeLen=18*25.4;

NC_Len=155;
NC_Base_L=6;
NC_Tip_R=5;
NC_Wall_t=1.2;

// Small fins
nFins=5;
Fin_Post_h=12;
Fin_Root_L=130;
Fin_Root_W=6;
Fin_Tip_W=2.0;
Fin_Tip_L=60;
Fin_Span=60;
Fin_TipOffset=20;
Fin_Chamfer_L=20;
FinInset_Len=5;
Fin_TipBase=0;
FinCan_Len=Fin_Root_L+FinInset_Len*2;
FinCanWall_t=1.2;
/**/

//*
// Little Bird data
MotorTube_OD=LOC29Body_OD;
MotorTube_ID=LOC29Body_ID;
MotorBolt_d=CV_M6_d;          // M6 center rod
MotorBoltPitch=CV_M6_p;

MotorTubeLen=304;
BodyTubeLen=18*25.4; // uncut estes tube

NC_Len=185;
NC_Base_L=6;
NC_Tip_R=4;
NC_Wall_t=1.0;
Petal_Len=140;

// Little Bird fins
nFins=5;
Fin_Post_h=12;
Fin_Root_L=130;
Fin_Root_W=6;
Fin_Tip_W=2.0;
Fin_Tip_L=80;
Fin_Span=80;
Fin_TipOffset=65;
Fin_Chamfer_L=20;
FinInset_Len=5;
Fin_TipBase=10;
FinCan_Len=Fin_Root_L+FinInset_Len*2;
FinCanWall_t=0.8;
/**/

/*
// Little Red One Data
Petal_Len=140; // 80 minimum, 100,120 or 140 is preferred 140 is max for a single 4323 spring
BPetal_Len=140;

MotorTube_OD=ULine38Body_OD;
MotorTube_ID=ULine38Body_ID;
MotorBolt_d=CV_M6_d;          // M6 center rod
MotorBoltPitch=CV_M6_p;

MotorTubeLen=304;
BoosterMotorTubeLen=330; // 330 is min for 38/600 case, 380 is min for 38/720 case

BodyTubeLen=764; // uncut Loc tube
BoosterBodyTubeLen=540;

NC_Len=185;
NC_Base_L=6;
NC_Tip_R=4;
NC_Wall_t=1.2;

// Little Red One fins
nFins=5;
Fin_Post_h=12;
Fin_Root_L=140;
Fin_Root_W=7.5;
Fin_Tip_W=2.0;
Fin_Tip_L=70;
Fin_Span=70;
Fin_TipOffset=25;
Fin_Chamfer_L=24;
FinInset_Len=5;
Fin_TipBase=0;
FinCan_Len=Fin_Root_L+FinInset_Len*2;
FinCanWall_t=1.2;

// Booster fins
B_Scale=1.25; // Booster fins are 125% of sustainer fins
BFin_Post_h=12;
BFin_Root_L=140*B_Scale;
BFin_Root_W=7.5*B_Scale;
BFin_Tip_W=2.0;
BFin_Tip_L=70*B_Scale;
BFin_Span=70*B_Scale;
BFin_TipOffset=25*B_Scale;
BFin_Chamfer_L=24*B_Scale;
BFinInset_Len=5;
BFin_TipBase=0;
BFinCan_Len=BFin_Root_L+BFinInset_Len*2;
/**/

SecurityRod_BC_d=(MotorTube_ID<31)? Body_ID-(Body_ID-MotorTube_OD)/2+4:Body_ID-Bolt10Inset*2; // 29mm:38mm motor
echo(SecurityRod_BC_d=SecurityRod_BC_d);

Vinyl_d=0.3;
TailCone_Len=30;
TailConeExtra_OD=2;

Thread1024_d=0.190*25.4;
Thread25020_d=0.250*25.4;
CRBBm_Activator_Bolt_a=[22.5,162,253,323];

// constants for 65mm stager (from Stager75BBLib, overrides for our tube size)
Default_nLocks=2;
nLocks=Default_nLocks;
DefaultBody_OD=LOC65Body_OD;
DefaultBody_ID=LOC65Body_ID;
DefaultMotorTube_OD=ULine38Body_OD;
DefaultServo=ServoMG90S_ID;
MainBearing_OD=Bearing6705_OD;
MainBearing_ID=Bearing6705_ID;
MainBearing_T=Bearing6705_T;

// Spacer between MotorTubeTopper and E-Bay bottom plate
// Adjusted for taller CATS Vega e-bay (was 25mm with Blue Raven 84mm e-bay)
Spacer_Len=25;  // tune to pull nosecone tight against body tube

CRBBm_Activator_Bolt_a=[22.5,162,253,323];

// ========== Body Tube Printing ==========

// Number of sections needed (auto-calculated)



// ========== Viewing ==========

module ShowRocket(ShowInternals=false, IsSustainer=false){
	FinCan_Z=TailCone_Len;
	Fin_Z=FinCan_Z+FinCan_Len/2;
	MotorTube_Z=FinCan_Z-TailCone_Len;
	EBay_Z=MotorTube_Z+MotorTubeLen+3+Spacer_Len;
	BodyTube_Z=FinCan_Z+FinCan_Len+Overlap*2;
	NoseCone_Z=BodyTube_Z+BodyTubeLen+0.1;
	
	FwdSpringEnd_Z=NoseCone_Z-14.5-Petal_Len-4;
	SCR_Z=FwdSpringEnd_Z-50;
	
	echo(str("Overall Length = ",(NoseCone_Z+NC_Len)/25.4, " inches"));
	echo(str("Overall Length = ",(NoseCone_Z+NC_Len), " mm"));

	translate([0,0,NoseCone_Z]){
		rotate([0,0,90]) color("Orange") NoseCone();
		
		if (ShowInternals)
			translate([0,0,-5]) color("Tan") rotate([180,0,30]) 
				R65_PetalHub(OD=Coupler_OD, nPetals=nPetals, nBolts=nPetals*2, Skirt_h=5, HasWirePath=false);
			
		if (ShowInternals){
			translate([0,0,-14.5]) rotate([180,0,30]) 
				PD_Petals(OD=Coupler_OD, Len=Petal_Len, nPetals=nPetals, Wall_t=1.6, AntiClimber_h=0, HasLocks=true);
		}
	}
	
	if (ShowInternals)			
		translate([0,0,FwdSpringEnd_Z]) color("Tan") rotate([180,0,0]) 
			R65_FwdSpringEnd(OD=Coupler_OD, ID=Coupler_ID, LockPin_d=16, nRopes=6, Skirt_h=25, HasServoConnector=false);

	
	if (ShowInternals){
		translate([0,0,SCR_Z]) ShowCableRelease();
		translate([0,0,SCR_Z-22.5]) color("LightGreen") rotate([0,0,180]) CRBBm_Activator();
		// CATS Vega E-Bay
		translate([0,0,EBay_Z]) color("LightGreen")
			R65_EBayCV_Sled(OD=Coupler_OD);
	}
		
	if (!ShowInternals)
		translate([0,0,BodyTube_Z]) color("LightBlue") 
			Tube(OD=Body_OD, ID=Body_ID, Len=BodyTubeLen-Overlap*2, myfn=$preview? 90:360);
		

	
	if (ShowInternals)
		translate([0,0,MotorTube_Z]) {
			color("Blue") Tube(OD=MotorTube_OD, ID=MotorTube_ID, Len=MotorTubeLen-Overlap*2, myfn=$preview? 90:360);
			translate([0,0,MotorTubeLen-18]) R65_MotorTubeTopper(OD=Body_ID, ID=MotorTube_OD, MT_ID=MotorTube_ID);
			translate([0,0,MotorTubeLen+3]) color("LightGreen") Tube(OD=Coupler_OD, ID=Coupler_OD-2.4, Len=Spacer_Len, myfn=$preview? 90:180); // spacer
		}	
	translate([0,0,FinCan_Z]) color("Orange") Fincan(LowerHalfOnly=false, UpperHalfOnly=false, IsSustainer=IsSustainer);
	
	for (j=[0:nFins-1]) rotate([0,0,360/nFins*j+180/nFins])
		translate([0, Body_OD/2-Fin_Post_h, Fin_Z]) 
			rotate([-90,0,0]) color("Orange") RocketFin(false);
		
} // ShowRocket

// ShowRocket(ShowInternals=false);

module ShowCableRelease(){
//*
	translate([0,0,LockPin_Len-7.5]) CRBBm_ExtensionRod(LockPin_d=LockPin_d, Len=26, ID=CV_M5_d, Light=true);

	CRBBm_LockingPin(nBalls=nBalls, LockPin_d=LockPin_d, LockPin_Len=LockPin_Len, GuidePoint=GuidePoint);
	CRBBm_LockRing(LockPin_d=LockPin_d, nBalls=nBalls, GuidePoint=GuidePoint, Light=true);
	CRBBm_TopRetainer(LockPin_d=LockPin_d, nBalls=nBalls, LockRing_d=CRBBm_LockRingDiameter(), Flange_t=TopRetainerFlange_t, OD=0, HasMountingBolts=true, GuidePoint=GuidePoint, Light=true);
/**/	
	translate([0,0,-19.5]){ 
		CRBBm_OuterBearingRetainer(Light=true);
		rotate([0,0,360/9*3]) CRBBm_MagnetBracket();
		rotate([0,0,360/9*2]) CRBBm_TriggerPost();
		}
//*
	translate([0,0,TopRetainerFlange_t+8.7]) 
		CRBBm_CenteringRingMount(OD=Body_ID, Thickness=7, Spring_OD=SE_Spring_CS4323_OD(), Spring_ID=SE_Spring_CS4323_ID());
/**/
} // ShowCableRelease

// ShowCableRelease();

module NoseCone(){
	R65_NoseCone(Shoulder_OD=Coupler_OD, OD=Body_OD*CF_Comp+Vinyl_d, nBolts=nPetals*2,
			NC_Len=NC_Len, NC_Base_L=NC_Base_L, NC_Tip_R=NC_Tip_R, NC_Wall_t=NC_Wall_t);
} // NoseCone

module Fincan(LowerHalfOnly=false, UpperHalfOnly=false, IsSustainer=false){
	Wall_t=FinCanWall_t;
	HasMotorSleeve=false;
	TailConeExtra_OD=0;
		
	TC_Len=IsSustainer? 0:TailCone_Len;
	OD=Body_OD*CF_Comp+Vinyl_d;
	MotorTubeHole_d=MotorTube_OD+IDXtra*2;
	myfn=180;
	
	echo(str("Body OD w/ Comp = ",Body_OD*CF_Comp+Vinyl_d));
	echo(str("Target OD = ", Body_OD+Vinyl_d));
	
	difference(){
		union(){
			FC2_FinCanLight(Body_OD=OD, Body_ID=Body_ID*CF_Comp, Can_Len=FinCan_Len,
				MotorTube_OD=MotorTube_OD, 
				nFins=nFins, HasIntegratedCoupler=true, HasFwdCenteringRing=false, Coupler_Len=10, nCouplerBolts=0,
				HasMotorSleeve=HasMotorSleeve, 
				Fin_Root_W=Fin_Root_W, Fin_Root_L=Fin_Root_L, Fin_Post_h=Fin_Post_h, Fin_Chamfer_L=Fin_Chamfer_L,
				Cone_Len=TC_Len, ThreadedTC=false, Extra_OD=TailConeExtra_OD,
				LowerHalfOnly=LowerHalfOnly, UpperHalfOnly=UpperHalfOnly,
				Wall_t=Wall_t,
				AftClosure_OD=0, AftClosure_Len=0, IncludeCenteringRings=false);
				
			if (IsSustainer)				
				difference(){
					translate([0,0,-Overlap]) Tube(OD=OD, ID=MotorTubeHole_d, Len=FinInset_Len-1, myfn=$preview? 90:myfn);
						
					translate([0,0,-4-Overlap]) rotate([0,0,90]) Stager_CupHoles(Tube_OD=OD, nLocks=nLocks, BoltsOn=true, Collar_h=0);
				} // difference
			
		} // union

		// Wire path
		if (IsSustainer)
			rotate([0,0,156]) translate([0,OD/2-8,-5]) cylinder(d=5/16*25.4+IDXtra, h=20);
		
	} // difference
} // Fincan


// Fincan(LowerHalfOnly=false, UpperHalfOnly=false);

module RocketFin(HasSpiralVaseRibs=true, PrinterBrim_H=0.6){
	TrapFin3(Post_h=Fin_Post_h, Root_L=Fin_Root_L, Tip_L=Fin_Tip_L, Root_W=Fin_Root_W,
				Tip_W=Fin_Tip_W, Span=Fin_Span, Chamfer_L=Fin_Chamfer_L,
				TipOffset=Fin_TipOffset,
				Bisect=false, Bisect_X=0,
				HasSpar=false, Spar_d=8, Spar_L=100, PrinterBrim_H=PrinterBrim_H, HasSpiralVaseRibs=HasSpiralVaseRibs, TipBase=Fin_TipBase);
} // RocketFin

// RocketFin(HasSpiralVaseRibs=true);
