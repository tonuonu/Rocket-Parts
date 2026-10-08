// ***********************************
// Project: 3D Printed Rocket
// Filename: RocketExperimentalWarkField.scad
// by David M. Flynn
// Created: 5/23/2026 
// Revision: 0.9.1  6/15/2026 
// Units: mm
// ***********************************
//  ***** Notes *****
//
//  Rocket with ULine 102mm Body and 54mm motor. 
//
//   Mission Control V3 / RocketServo
//
//
//  ***** Parts *****
//
// Blue Tube 2.1" Body Tube
// 63" Parachute
// 1/2" Braided Nylon Shock Cord (30 feet)
//
//  ***** Hardware *****
//
//
//  ***** History *****
//
// 0.9.1  6/15/2026  Corrcted sliding parts to Couper_OD-0.6
// 0.9.0  5/23/2026  First code
//
// ***********************************
//  ***** for STL output *****
//
// NoseCone();
// 
//
// NightLaunchNC_Base();
// NC_ShockcordRingDual(Tube_OD=Body_OD, Tube_ID=Body_ID, NC_Base_L=NC_Base_L, nRivets=6, nBolts=6); // alt
//
// rotate([180,0,0]) EBay(TopOnly=true, BottomOnly=false);
// EBay(TopOnly=false, BottomOnly=true);
//
// rotate([-90,0,0]) EB_RocketServo2Door(Tube_OD=Body_OD, HasMagSwitch=true, HasBatt=false, BlankDoor=false, EndFlat_t=0.4);
// rotate([-90,0,0]) EB_AltDoor(Tube_OD=Body_OD, BlankDoor=false, IsLoProfile=false, EndFlat_t=0.4);
// rotate([-90,0,0]) EB_BattDoor(Tube_OD=Body_OD, HasSwitch=false, TallDoor=true, DoubleBatt=false, BlankDoor=false);
//
// *** Ball Lock ***
//
// STB_LockDisk(Body_ID=Body_ID, nLockBalls=nLockBalls, HasLargeInnerBearing=true, Xtra_r=0.0);
// rotate([180,0,0]) R102UL_BallRetainerTop(Body_OD=Body_OD, Body_ID=Body_ID, CouplerLenXtra=CouplerLenXtra, nBolts=6, Xtra_r=0.0);
// R102UL_BallRetainerBottom(Body_OD=Body_OD, Body_ID=Body_ID, Xtra_r=0.0);
// rotate([180,0,0]) STB_TubeEnd(Body_ID=Body_ID, nLockBalls=nLockBalls, Body_OD=Body_OD, Engagement_Len=Engagement_Len);
//
// *** petal deployer ***
//
// DroguePetalHub();
// PD_NC_PetalHub(OD=Slider_OD, nPetals=3, HasReplaceableSpringHolder=true, nRopes=3, ShockCord_a=-1, HasThreadedCore=false, ST_DSpring_ID=SE_Spring_CS4323_ID(), ST_DSpring_OD=SE_Spring_CS4323_OD(), CouplerTube_ID=0, CouplerTubeLen=0);
// rotate([-90,0,0]) PD_PetalSpringHolder(OD=Slider_OD);
// PD_Petals(OD=Slider_OD, Len=DroguePetalLen, nPetals=nPetals, AntiClimber_h=4);
// PD_Petals(OD=Slider_OD, Len=PetalLen, nPetals=nPetals, AntiClimber_h=4);
//
// rotate([180,0,0]) SE_SpringTop(OD=Slider_OD, Piston_Len=50, nRopes=6);
// SE_SlidingSpringMiddle(OD=Slider_OD, nRopes=6, SliderLen=40, SpLen=35, SpringStop_Z=20);
// SE_SpringEndBottom(OD=Slider_OD, Tube_ID=Coupler_OD-2.4, nRopeHoles=6, CutOutCenter=true);
//
// rotate([0,0,90]) RocketFin();
// rotate([0,0,90]) NacelleFin();
// FinCan(LowerHalfOnly=false, UpperHalfOnly=true);
// rotate([180,0,0]) FinCan(LowerHalfOnly=true, UpperHalfOnly=false);
// MotorRetainer();
//
//  *** Nacelle ***
//
// 
//
//
// FW_MagSw_Mount(HasMountingEars=false, Reversed=false);
// rotate([90,0,0]) BoltOnRailGuide(Length = RailGuideLen, BoltSpace=12.7, RoundEnds=true, ExtraBack=0);
//
// ***********************************
//  ***** Routines *****
//
//
// ***********************************
//  ***** for Viewing *****
//
// ShowRocket();
// ShowRocket(ShowInternals=true);
//
// ***********************************
include<TubesLib.scad>
use<R102ULLib.scad>			 echo(R102ULLibRev());
use<FinCan2Lib.scad> 		 echo(FinCan2LibRev());
use<AT_RMS_Lib.scad>		 echo(AT_RMS_Lib_Rev());
use<RailGuide.scad>			 echo(RailGuideRev());
use<BatteryHolderLib.scad>   echo(BatteryHolderLibRev());
use<Fins.scad>				 echo(FinsRev());
use<NoseCone.scad>			 echo(NoseConeRev());
use<ElectronicsBayLib.scad>  echo(ElectronicsBayLibRev());
use<SpringThingBooster.scad> echo(SpringThingBoosterRev());
use<PetalDeploymentLib.scad> echo(PetalDeploymentLibRev());
use<SpringEndsLib.scad>		 echo(SpringEndsLibRev());


//also included
 //include<CommonStuffSAEmm.scad>

Overlap=0.05;
IDXtra=0.2;
$fn=$preview? 36:90;
Bolt4Inset=4;

NC_Len=240;
NC_Tip_r=8;
NC_Base_L=15;
NC_Wall_t=1.8;


PetalLen=200;
DroguePetalLen=100;

Body_OD=ULine102Body_OD;
Body_ID=ULine102Body_ID;
Coupler_OD=ULine102Coupler_OD;
Coupler_ID=ULine102Coupler_ID;
Slider_OD=Couper_OD-0.6; // -1 was too small
MotorTube_OD=BT54Body_OD;
MotorTube_ID=BT54Body_ID;

nFins=6;
Fin_Post_h=18;
Fin_Root_L=220;
Fin_Root_W=14;
Fin_Tip_W=2;
Fin_Tip_L=140;
Fin_TipInset=0;
Fin_Span=140;
Fin_TipOffset=00;
Fin_Chamfer_L=26;
Fin_HasBluntTip=false;
FinInset_Len=5;
FinCanLen=Fin_Root_L+FinInset_Len*2;

Nacelle_Fin_Tip_L=Fin_Root_L-40;
Nacelle_Fin_Tip_W=Fin_Root_W-4;
Nacelle_Fin_Span=Fin_Span-80;
Nacelle_Fin_TipPost_h=12;
Nacelle_Fin_TipOffset=-20;

CouplerLenXtra=-20;
Cone_Len=65;
nLockBalls=6;
Engagement_Len=20;
nPetals=3;
ShockCord_a=17;// offset between PD_PetalHub and R65_BallRetainerBottom

PodRadiator1Len=100;

PodRadiator2Len=50;

WarpCoreTube_OD=130.2;
WarpCoreTube_ID=125.2;
WarpCoreEnd_Len=40;
WarpCoreBody_Len=306;

EBay_Len=180;
BodyTube_Len=300;


RailGuide_h=WarpCoreTube_OD/2+2;
RailGuideLen=35;

module ShowRocket(ShowInternals=false){
	FinCan_Z=0;
	Fin_Z=FinCan_Z+FinCanLen/2;
	WarpCore_Z=FinCan_Z+FinCanLen+WarpCoreEnd_Len+0.2;
	WarpCoreTop_Z=WarpCore_Z+WarpCoreBody_Len;
	EBay_Z=WarpCoreTop_Z+WarpCoreEnd_Len+0.2;
	STB_Z=EBay_Z+EBay_Len+34.2;
	
	BodyTube_Z=STB_Z+Engagement_Len/2+0.2;
	NoseCone_Z=BodyTube_Z+BodyTube_Len;
	
	translate([0,0,NoseCone_Z]){
		NoseCone();
		}
	
	if (!ShowInternals)
		translate([0,0,BodyTube_Z]) color("White") Tube(OD=Body_OD, ID=Body_ID, Len=BodyTube_Len, myfn=90);
	
	translate([0,0,STB_Z]) {
		rotate([180,0,0]) STB_TubeEnd(Body_ID=Body_ID, nLockBalls=nLockBalls, Body_OD=Body_OD, Engagement_Len=20);
		rotate([180,0,0]) R102UL_BallRetainerTop(Body_OD=Body_OD, Body_ID=Body_ID, nBolts=3, Xtra_r=0.0);
	}
	
	translate([0,0,EBay_Z]) EBay(TopOnly=false, BottomOnly=false);
	
	translate([0,0,WarpCore_Z])
		WarpCoreEnd(OD=WarpCoreTube_OD*CF_Comp, HasCoupler=false);
		
	translate([0,0,WarpCoreTop_Z])
		rotate([180,0,0]) WarpCoreEnd(OD=WarpCoreTube_OD*CF_Comp, HasCoupler=true);
	
	//*
	for (j=[0,2,3,5]) rotate([0,0,360/nFins*j+180/nFins])
		translate([0,Body_OD/2-Fin_Post_h, Fin_Z]) 
			rotate([-90,0,0]) color("Orange") RocketFin();
			
	for (j=[1,4]) rotate([0,0,360/nFins*j+180/nFins])
		translate([0,Body_OD/2-Fin_Post_h, Fin_Z]) 
			rotate([-90,0,0]) color("Orange") NacelleFin();
	/**/
	
	translate([0,0,FinCan_Z]){
		FinCan();
		MotorRetainer();}
		
	
} // ShowRocket

// ShowRocket();

LED_OD=5;
LED_Len=6;

NacelleCover_X=50;
NacelleCover_Y=200;
NacelleCover_t=1.5;

module DroguePetalHub(){
	
	PD_PetalHub(OD=Slider_OD, 
						nPetals=3, 
						HasReplaceableSpringHolder=true,
						HasBolts=true,
						nBolts=6, // Same as nPetals
						ShockCord_a=-2,
						HasNCSkirt=false, 
							Body_OD=BT75Body_OD,
							Body_ID=BT75Body_ID,
							NC_Base=0, 
							SkirtLen=10, 
						CenterHole_d=0);
	
} // DroguePetalHub

// DroguePetalHub();

module NoseCone(){
	BluntOgiveNoseCone(ID=Coupler_OD, OD=Body_OD*CF_Comp, L=NC_Len, Base_L=NC_Base_L, 
						nRivets=6, RivertInset=0, Tip_R=NC_Tip_r, HasThreadedTip=false, Wall_T=NC_Wall_t, 
							Cut_d=0, LowerPortion=false, FillTip=true);
} // NoseCone

// NoseCone();


module LampClamp(){
	OD=54;
	ID=38.5;
	H=4;
	BC=47;
	nBolts=6;
	
	difference(){
		cylinder(d=OD, h=H);
		
		translate([0,0,-Overlap]) cylinder(d=ID, h=H+Overlap*2);
		
		for (j=[0:nBolts]) rotate([0,0,360/nBolts*j])
			translate([0,BC/2,H]) Bolt4ButtonHeadHole();
	} // difference
} // LampClamp

//translate([0,0,30.2]) LampClamp();

module LampHolder(HasBattNotches=true){
	H=30;
	OD=54;
	BC=47;
	nBolts=6;
	
	difference(){
		cylinder(d=OD, h=H);
		
		translate([0,0,H-1]) cylinder(d=43.5, h=5);
		
		translate([0,0,-Overlap]) cylinder(d=24, h=H+Overlap*2);
		
		translate([0,0,-Overlap]) cylinder(d1=45, d2=24, h=20);
		
		for (j=[0:nBolts]) rotate([0,0,360/nBolts*j])
			translate([0,BC/2,H]) Bolt4Hole();
		
		// Keying notches
		rotate([0,0,30]) translate([0,OD/2-3,H])
			cube([8.5,10,2],center=true);
			
		rotate([0,0,135+30]) translate([0,OD/2-3,H])
			cube([7,10,2],center=true);
			
		rotate([0,0,-135+30]) translate([0,OD/2-3,H])
			cube([7,10,2],center=true);
		
		// Batteries
		if (HasBattNotches)
		for (j=NC_Batt_a) rotate([0,0,j]) translate([0,0,-Overlap]) hull(){
			translate([-20,OD/2-2,0]) cube([40,10,15]);
			translate([-20,OD/2,20]) cube([40,10,1]);
		}
		
		// Wire path
		translate([0,0,7]) rotate([0,0,75]) rotate([90,0,0]) cylinder(d=5,h=OD/2+5);
	} // difference
} // LampHolder

//LampHolder();

NC_Batt_a=[-30,30,150,210];

module NightLaunchNC_Base(Tube_OD=Body_OD*CF_Comp, Tube_ID=Body_ID, nRivets=6){


	// Big Spring
	Spring_CS4009_OD=2.328*25.4;
	Spring_CS4009_ID=2.094*25.4;
	Spring_CS4009_FL=18.5*25.4;
	Spring_CS4009_CL=1.64*25.4;
	// Small Spring
	Spring_CS4323_OD=44.30;
	Spring_CS4323_ID=40.50;
	Spring_CS4323_CBL=22; // coil bound length
	Spring_CS4323_FL=200; // free length

	Plate_t=4;
	nBT_Bolts=6;
	nHoles=6;
	Rivet_d=4;
	Tube_d=12.7;
	Tube_Z=30;
	CR_z=-3;
	Spring_OD=(Tube_OD>110)? Spring_CS4009_OD:Spring_CS4323_OD;
	BodyTube_L=15;
	SpringEnd_Z=10;
	SpringSplice_OD=BT54Body_ID;
	Extension=20;
	nBatteries=4;

	
	module LightAndBatteries(){
	
		for (j=NC_Batt_a) rotate([0,0,j])
			translate([0,Tube_ID/2-15,0]) SingleBatteryPocket(ShowBattery=false);
	} // LightAndBatteries
	
	module BattEjectHoles(){
		for (j=NC_Batt_a) rotate([0,0,j]){
			translate([0,Tube_ID/2-15,-10]) cylinder(d=12, h=20);
			translate([0,Tube_ID/2-15,0]) RoundRect(X=28,Y=18,Z=50,R=3);
			}
	} // BattEjectHoles
	
	translate([0,0,38]) LampHolder();
	
	difference(){
		union(){
			LightAndBatteries();
			
			//Skirt
			translate([0,0,CR_z]) Tube(OD=54, ID=45, Len=25+Extension, myfn=$preview? 90:360);
			
			// Stop ring
			translate([0,0,CR_z+BodyTube_L]) Tube(OD=Tube_OD, ID=Tube_ID-1, Len=3, myfn=$preview? 90:360);
	
			// Nosecone interface
			translate([0,0,CR_z+BodyTube_L]) Tube(OD=Tube_ID-IDXtra*2, 
									ID=Tube_ID-IDXtra*2-4.4, Len=NC_Base_L+3, myfn=$preview? 90:360);
			// Body tube interface
			translate([0,0,CR_z]) Tube(OD=Tube_ID, 
									ID=Tube_ID-4.4, Len=BodyTube_L+1, myfn=$preview? 90:360);
				
			// Stiffener Plate
			translate([0,0,CR_z])
				cylinder(d=Tube_ID-1, h=6);
				
			// Tube holder
			hull(){
				translate([0,0,Tube_Z]) 
					rotate([0,90,0]) cylinder(d=Tube_d+4.4, h=Tube_ID-4, center=true);
				translate([0,0,CR_z+5]) cube([Tube_ID-4, Tube_d+12, 10],center=true);
			} // hull
			
			// Spring Holder
			cylinder(d1=SpringSplice_OD+8, d2=Spring_OD+6, h=SpringEnd_Z+4);
		} // union
		
		//translate([-4,-34,4]) FW_GPS_SW_Hole(-9);
		
		// Nosecone rivets
		for (j=[0:nRivets-1]) rotate([0,0,360/nRivets*j]) translate([0,-Tube_ID/2-1,CR_z+15+3+NC_Base_L/2])
			rotate([-90,0,0]){ cylinder(d=Rivet_d, h=10); 
			translate([0,0,3.2]) cylinder(d=Rivet_d*2, h=6);}
		
		// Body tube bolts
		for (j=[0:nBT_Bolts-1]) rotate([0,0,360/nBT_Bolts*j]) translate([0,Tube_OD/2,CR_z+BodyTube_L/2])
			rotate([-90,0,0]) Bolt4Hole();
		
		// Center hole
		translate([0,0,-6]) cylinder(d=Spring_OD-6, h=Tube_Z+30);
		
		// Spring
		translate([0,0,SpringEnd_Z]) rotate([180,0,0]) {
			cylinder(d=Spring_OD, h=30);
			translate([0,0,4]) cylinder(d1=Spring_OD, d2=Spring_OD+4, h=8);
			translate([0,0,12-Overlap]) cylinder(d=Spring_OD+4, h=30);
			}
		
		// Tube hole
		translate([0,0,Tube_Z]) rotate([0,90,0]) cylinder(d=Tube_d, h=Tube_OD, center=true);
		
		// Retention cord
		for (j=[0:nHoles-1]) rotate([0,0,360/nHoles*j]) translate([0,Tube_ID/2-8,-10]) cylinder(d=4, h=30);
		
		BattEjectHoles();
		
		//if ($preview) cube([50,50,50]);
	} // difference
	
} // NightLaunchNC_Base

// NightLaunchNC_Base();

module NacelleCover(H=Nacelle_Fin_Tip_L, W=10, Thickness=4, R=3){
	RoundRect(X=H, Y=W, Z=Thickness, R=R);
} // NacelleCover

//NacelleCover();

module Nacelle_LED_Strip(H=Nacelle_Fin_Tip_L, W=10, Thickness=5, R=3){
	nLEDs=12;
	Wall_t=1.2;
	Skirt_t=6;
	
	// Skirt
	difference(){
		RoundRect(X=H, Y=W, Z=Thickness+Skirt_t, R=R);
		translate([0,0,-Overlap]) RoundRect(X=H-Wall_t*2, Y=W-Wall_t*2, Z=Thickness+Skirt_t+Overlap*2, R=R-Wall_t);
	} // difference
	
	difference(){
		RoundRect(X=H, Y=W, Z=Thickness, R=R);
		
		Sp=H/nLEDs;
		for (j=[0:nLEDs-1]) translate([-H/2+Sp/2+Sp*j,0,-Overlap]) {
			cylinder(d=5, h=Thickness+Overlap*2);
		}
	} // difference
} // Nacelle_LED_Strip

// Nacelle_LED_Strip();

Nacelle_OD=74;
Nacelle_Corner_r=4;
Nacelle_nSides=5;

module Nacelle_Body(OD=Nacelle_OD, Len=1, Wall_t=0){
		hull() for (j=[0:Nacelle_nSides-1]) rotate([0,0,360/Nacelle_nSides*j])
			translate([0,-OD/2+Nacelle_Corner_r,0])
				cylinder(r=Nacelle_Corner_r-Wall_t, h=Len, center=true);
	} // Nacelle_Body
	
module NacelleNosecone(){
	H=54;
	D=54;
	OD=Nacelle_OD;
	nSides=Nacelle_nSides;
	Corner_r=Nacelle_Corner_r;
	Lamp_d=30.55;
	Wall_t=1.8;
	
	difference(){
		union(){
			difference(){
				hull(){
					translate([0,0,5]) Nacelle_Body(Len=10);
					cylinder(d=Lamp_d+Wall_t*2, h=H);
				} // hull
				
				hull(){
					translate([0,0,-Overlap]) translate([0,0,5]) Nacelle_Body(Len=10, Wall_t=Wall_t);
					translate([0,0,H-6]) cylinder(d1=Lamp_d+Wall_t*2, d2=Lamp_d, h=3);
				} // hull
			} // difference
			
			difference(){
				Nacelle_Body(Len=10, Wall_t=Wall_t);
				// Inside of skirt
				Nacelle_Body(OD=OD-Wall_t*2, Len=11, Wall_t=Wall_t);
				hull(){
					translate([0,0,5]) Nacelle_Body(Len=Overlap, Wall_t=Wall_t);
					
					translate([0,0,1]) Nacelle_Body(OD=OD-Wall_t*2, Len=Overlap, Wall_t=Wall_t);
				} // hull
			} // difference
		} // union
		
		
		
		// Lamp top
		cylinder(d=Lamp_d+IDXtra*2, h=H*2+10, center=true);
		
		// Lamp base
		translate([0,0,-10.05]) cylinder(d=D+1, h=20, $fn=180);
	} // difference
} // NacelleNosecone

// NacelleNosecone();
// translate([0,0,-30]) LampHolder();

module Nacelle_FwdLampHolder(){
	Wall_t=1.8;
	Lamp_a=41.5;
	CenterHole_d=37;
	//#translate([0,0,11]) cylinder(d=70, h=1);
	
	difference(){
		union(){
			translate([0,0,-7+1]) Nacelle_Body(OD=Nacelle_OD, Len=2, Wall_t=Wall_t);
			translate([0,0,-7+3]) Nacelle_Body(OD=Nacelle_OD-Wall_t*2, Len=6, Wall_t=Wall_t);
		} // union
		
		translate([0,0,-7-Overlap]) cylinder(d=52, h=6+Overlap*2);
	} // difference
	
	difference(){
		translate([0,0,-18]) rotate([0,0,Lamp_a]) LampHolder(HasBattNotches=false);
		
		translate([0,0,-20]) cylinder(d=Nacelle_OD, h=13);
		translate([0,0,-10]) cylinder(d=CenterHole_d, h=50);
	} // difference
} // Nacelle_FwdLampHolder

// Nacelle_FwdLampHolder();

module Nacelle_AftLampHolder(){
	nLEDs=8;
	Wall_t=1.8;
	
	difference(){
		union(){
			translate([0,0,1]) Nacelle_Body(OD=Nacelle_OD, Len=2, Wall_t=Wall_t);
			translate([0,0,3]) Nacelle_Body(OD=Nacelle_OD-Wall_t*2, Len=6, Wall_t=Wall_t);
		} // union
		
		for (j=[0:nLEDs-1]) rotate([0,0,360/nLEDs*j]) translate([0,15,-Overlap]){
			cylinder(d=7, h=3);
			cylinder(d=5, h=10);
		}
		//translate([0,0,-7-Overlap]) cylinder(d=52, h=6+Overlap*2);
	} // difference
		
} // Nacelle_AftLampHolder

// Nacelle_AftLampHolder();

module NacelleTailcone(){
	H=54;
	D=54;
	OD=Nacelle_OD;
	nSides=Nacelle_nSides;
	Corner_r=Nacelle_Corner_r;
	Lamp_d=30.55;
	Wall_t=1.8;
	
	difference(){
		hull(){
			translate([0,0,2]) Nacelle_Body(Len=4);
			translate([0,0,H-Lamp_d/2]) sphere(d=Lamp_d);
		} // hull
		
		hull(){
			translate([0,0,-Overlap]) translate([0,0,2]) Nacelle_Body(Len=4, Wall_t=Wall_t);
			translate([0,0,H-Lamp_d/2]) sphere(d=Lamp_d-Wall_t*2);
		} // hull
	} // difference
	
	difference(){
		Nacelle_Body(Len=10, Wall_t=Wall_t);
		// Inside of skirt
		Nacelle_Body(OD=OD-Wall_t*2, Len=11, Wall_t=Wall_t);
		hull(){
			translate([0,0,5]) Nacelle_Body(Len=Overlap, Wall_t=Wall_t);
			
			translate([0,0,1]) Nacelle_Body(OD=OD-Wall_t*2, Len=Overlap, Wall_t=Wall_t);
		} // hull
	} // difference
		
} // NacelleTailcone

// NacelleTailcone();

module Nacelle(Len=Nacelle_Fin_Tip_L+30){
	OD=Nacelle_OD;
	Corner_r=Nacelle_Corner_r;
	Wall_t=1.8;
	nSides=Nacelle_nSides;
	
	
	// Body
	difference(){
		Nacelle_Body(OD=OD, Len=Len, Wall_t=0);
		
		Nacelle_Body(OD=OD, Len=Len+Overlap, Wall_t=Wall_t);	
		
		TrapFin3Slots(Tube_OD=OD, nFins=1, Post_h=Nacelle_Fin_TipPost_h, Root_L=Nacelle_Fin_Tip_L, 
						Root_W=Nacelle_Fin_Tip_W, Chamfer_L=Fin_Chamfer_L);
						
		rotate([0,0,90+360/nSides]) rotate([0,90,0]) 
			NacelleCover(H=Nacelle_Fin_Tip_L+IDXtra*2, W=10+IDXtra*2, Thickness=OD/2, R=3+IDXtra);
		rotate([0,0,90-360/nSides]) rotate([0,90,0]) 
			NacelleCover(H=Nacelle_Fin_Tip_L+IDXtra*2, W=10+IDXtra*2, Thickness=OD/2, R=3+IDXtra);
	} // difference
	//+360/nSides*2
	
	//rotate([0,0,90+360/nSides]) translate([15.5,0,0]) rotate([0,90,0]) cylinder(d=10, h=15);
		
	difference(){
		
		intersection(){
			union(){
				rotate([0,0,90+360/nSides]) translate([15.5,0,0]) rotate([0,90,0]) 
					NacelleCover(H=Nacelle_Fin_Tip_L+Wall_t*2+IDXtra*2, W=10+Wall_t*2+IDXtra*2, Thickness=OD/2, R=3+Wall_t+IDXtra);
				rotate([0,0,90-360/nSides]) translate([15.5,0,0]) rotate([0,90,0]) 
					NacelleCover(H=Nacelle_Fin_Tip_L+Wall_t*2+IDXtra*2, W=10+Wall_t*2+IDXtra*2, Thickness=OD/2, R=3+Wall_t+IDXtra);
					
				// gussets
				hull(){
					translate([0,OD/2-6.6,0]) cylinder(d=Wall_t,h=Nacelle_Fin_Tip_L+Wall_t*2+IDXtra*2, center=true);
					translate([-25,10,0]) cylinder(d=Wall_t,h=Nacelle_Fin_Tip_L+Wall_t*2+IDXtra*2, center=true);
				} // hull
				hull(){
					translate([0,OD/2-6.6,0]) cylinder(d=Wall_t,h=Nacelle_Fin_Tip_L+Wall_t*2+IDXtra*2, center=true);
					translate([25,10,0]) cylinder(d=Wall_t,h=Nacelle_Fin_Tip_L+Wall_t*2+IDXtra*2, center=true);
				} // hull
				// gussets
				hull(){
					translate([0,-OD/2,0]) cylinder(d=Wall_t,h=Nacelle_Fin_Tip_L+Wall_t*2+IDXtra*2, center=true);
					translate([-28,10,0]) cylinder(d=Wall_t,h=Nacelle_Fin_Tip_L+Wall_t*2+IDXtra*2, center=true);
				} // hull
				hull(){
					translate([0,-OD/2,0]) cylinder(d=Wall_t,h=Nacelle_Fin_Tip_L+Wall_t*2+IDXtra*2, center=true);
					translate([28,10,0]) cylinder(d=Wall_t,h=Nacelle_Fin_Tip_L+Wall_t*2+IDXtra*2, center=true);
				} // hull
			} // union
			
			Nacelle_Body(OD=OD, Len=Len, Wall_t=0);
		} // intersection
		
		rotate([0,0,90+360/nSides]) rotate([0,90,0]) 
			NacelleCover(H=Nacelle_Fin_Tip_L+IDXtra*2, W=10+IDXtra*2, Thickness=OD/2, R=3+IDXtra);
		rotate([0,0,90-360/nSides]) rotate([0,90,0]) 
			NacelleCover(H=Nacelle_Fin_Tip_L+IDXtra*2, W=10+IDXtra*2, Thickness=OD/2, R=3+IDXtra);
		TrapFin3Slots(Tube_OD=OD, nFins=1, Post_h=Nacelle_Fin_TipPost_h, Root_L=Nacelle_Fin_Tip_L, 
						Root_W=Nacelle_Fin_Tip_W, Chamfer_L=Fin_Chamfer_L);
	} // difference
	
	Fin_Inset=1;
	// Fin socket
	difference(){
		intersection(){
			translate([0,-OD/2+Wall_t+Nacelle_Fin_TipPost_h/2,0]) 
				cube([Nacelle_Fin_Tip_W+Wall_t*2, Nacelle_Fin_TipPost_h+Wall_t+Fin_Inset, Len-20], center=true);
				
			Nacelle_Body(OD=OD, Len=Len, Wall_t=0);
		} // intersection
		
		TrapFin3Slots(Tube_OD=OD, nFins=1, Post_h=Nacelle_Fin_TipPost_h+Fin_Inset, Root_L=Nacelle_Fin_Tip_L, 
						Root_W=Nacelle_Fin_Tip_W, Chamfer_L=Fin_Chamfer_L);
	} // difference
	
} // Nacelle

// Nacelle();
// translate([0,0,Nacelle_Fin_Tip_L/2+15.2]) NacelleNosecone();

//translate([0,0,80]) LampHolder();

module WarpCoreLEDRing(nLEDs=12, OD=Body_OD, Len=20, HasCR=true, HasCoupler=true){
	Wall_t=1.4;
	CR_ID=MotorTube_OD+IDXtra*3;
	nSpokes=(nLEDs>0)? nLEDs/2:6;
	
	difference(){
		union(){
			Tube(OD=OD, ID=OD-Wall_t*2, Len=Len, myfn=$preview? 90:360);
			
			if (HasCoupler){
				translate([0,0,Len-Overlap]) Tube(OD=OD-Wall_t*2, ID=OD-Wall_t*4, Len=2, myfn=$preview? 90:360);
			
				difference(){
					translate([0,0,Len-Wall_t*2]) cylinder(d=OD-1, h=Wall_t*2, $fn=360);
					translate([0,0,Len-Wall_t*2-Overlap]) cylinder(d1=OD-Wall_t*2, d2=OD-Wall_t*4, h=Wall_t*2+Overlap*2, $fn=360);
				} // difference
			} // HasCoupler
			
			for (j=[0:nLEDs-1]) rotate([0,0,360/nLEDs*j]) translate([0,OD/2-1,Len/2])
				rotate([90,0,0]) cylinder(d1=LED_OD+8,d2=LED_OD+2, h=LED_Len-1.5);
				
			if (HasCR){
				for (j=[0:nSpokes-1]) rotate([0,0,360/nSpokes*j+180/nSpokes]) 
				difference(){
					translate([-0.55,CR_ID/2,0])
						cube([1.1,OD/2-CR_ID/2-0.5,6]);
						
					translate([-0.7,OD/2-Wall_t*2-0.5,-Overlap])
						cube([1.4,5,2.3]);
				} // difference
			
				Tube(OD=CR_ID+2, ID=CR_ID, Len=6, myfn=$preview? 90:360);
			} // HasCR
		} // union
		
		for (j=[0:nLEDs-1]) rotate([0,0,360/nLEDs*j]) translate([0,OD/2+1,Len/2])
			rotate([90,0,0]) cylinder(d=LED_OD, h=20);
			
		
	} // difference

} // WarpCoreLEDRing

// WarpCoreLEDRing(nLEDs=0, OD=Body_OD, Len=18, HasCR=true, HasCoupler=true);
// WarpCoreLEDRing();
// WarpCoreLEDRing(nLEDs=12, OD=Body_OD, Len=20, HasCR=false, HasCoupler=true);
// WarpCoreLEDRing(nLEDs=16, OD=Body_OD, Len=18, HasCR=false, HasCoupler=false); // center ring

/*
translate([0,0,20.05*11]) WarpCoreLEDRing(HasCR=true, HasCoupler=false);
translate([0,0,20.05*10]) WarpCoreLEDRing(HasCR=false, HasCoupler=true);
translate([0,0,20.05*9]) WarpCoreLEDRing(HasCR=true, HasCoupler=true);
translate([0,0,20.05*8]) WarpCoreLEDRing(HasCR=false, HasCoupler=true);

translate([0,0,20.05*7]) WarpCoreLEDRing(HasCR=false, HasCoupler=true);
translate([0,0,20.05*6]) WarpCoreLEDRing(HasCR=true, HasCoupler=true);
translate([0,0,20.05*5]) WarpCoreLEDRing(HasCR=true, HasCoupler=true);
translate([0,0,20.05*4]) WarpCoreLEDRing(HasCR=false, HasCoupler=true);

translate([0,0,20.05*3]) WarpCoreLEDRing(HasCR=false, HasCoupler=true);
translate([0,0,20.05*2]) WarpCoreLEDRing(HasCR=true, HasCoupler=true);
translate([0,0,20.05*1]) WarpCoreLEDRing(HasCR=false, HasCoupler=true);
translate([0,0,20.05*0]) WarpCoreLEDRing(HasCR=true, HasCoupler=true);
/**/

module RailGuideRing(OD=Body_OD*CF_Comp){
	Wall_t=1.6;
	Len=90;
	ID=OD-Wall_t*2;
	nBolts=6;
	Coupler_Len=15;
	BoltInset=7.5;
	Bolt_a=30;
	CR_ID=MotorTube_OD+IDXtra*3;
	
	difference(){
		Tube(OD=OD, ID=ID, Len=Len, myfn=$preview? 90:360);
		for (j=[0:nBolts-1]) rotate([0,0,360/nBolts*j+Bolt_a]) translate([0,OD/2,BoltInset])
				rotate([-90,0,0]) Bolt4Hole();
	} // difference
	
	// Coupler
	difference(){
		translate([0,0,Len-Overlap]) Tube(OD=Body_ID, ID=Body_ID-Wall_t*2, Len=Coupler_Len+Overlap, myfn=$preview? 90:360);
		for (j=[0:nBolts-1]) rotate([0,0,360/nBolts*j+Bolt_a]) translate([0,Body_OD/2,Len+BoltInset])
				rotate([-90,0,0]) Bolt4Hole();
	} // difference
	difference(){
		translate([0,0,Len-Wall_t*2]) cylinder(d=Body_ID+1, h=Wall_t*2);
		
		translate([0,0,Len-Wall_t*2-Overlap]) cylinder(d2=Body_ID-Wall_t*2, d1=ID, h=Wall_t*2+Overlap*2, $fn=360);
	} // difference
	
	translate([0,0,Len/2+5]){
		RailGuidePost(OD=OD, MtrTube_OD=MotorTube_OD, H=RailGuide_h, 
			TubeLen=RailGuideLen+30, Length = RailGuideLen, BoltSpace=12.7, AddTaper=false, Wall_t=Wall_t);
		
		nSpokes=6;
		Spoke_t=Wall_t;
		// spokes
		for (j=[1:nSpokes-1]) rotate([0,0,360/nSpokes*j]) hull(){
			translate([0,MotorTube_OD/2+Spoke_t/2+IDXtra*2,0]) cylinder(d=Spoke_t, h=RailGuideLen+30, center=true);
			translate([0,ID/2,0]) cylinder(d=Spoke_t, h=RailGuideLen+30, center=true);
		}
	}
			
	
} // RailGuideRing

// RailGuideRing();

module MTCR(OD=Body_ID, ID=MotorTube_OD+IDXtra*3, Len=20){
	OuterWall_t=1.7;
	Spoke_t=1.2;
	nSpokes=6;
	nBolts=6;
	InnerWall_t=1.2;
	
	difference(){
		Tube(OD=OD, ID=OD-OuterWall_t*2, Len=Len, myfn=$preview? 90:360);
		for (j=[0:nBolts-1]) rotate([0,0,360/nBolts*j+180/nSpokes]) 
			translate([0,OD/2,Len/2]) rotate([-90,0,0]) Bolt4Hole();
	} // difference
	
	Tube(OD=ID+InnerWall_t*2, ID=ID, Len=Len, myfn=$preview? 90:360);
	
	for (j=[0:nSpokes-1]) rotate([0,0,360/nSpokes*j]) hull(){
		translate([0,OD/2-Spoke_t/2]) cylinder(d=Spoke_t, h=Len);
		translate([0,ID/2+Spoke_t/2]) cylinder(d=Spoke_t, h=Len);
	} // hull
} // MTCR

// MTCR();

module WarpCoreEnd(OD=WarpCoreTube_OD*CF_Comp, HasCoupler=false){
	Wall_t=1.8;
	Len=WarpCoreEnd_Len;
	CR_ID=MotorTube_OD+IDXtra*3;
	nBolts=6;
	BoltInset=7.5;
	Coupler_Len=15;
	
	translate([0,0,-5]) Tube(OD=OD, ID=WarpCoreTube_ID, Len=5, myfn=$preview? 90:360);
	// Coupler
	Tube(OD=WarpCoreTube_ID, ID=WarpCoreTube_ID-Wall_t*2, Len=5, myfn=$preview? 90:360);
	difference(){
		translate([0,0,-Wall_t*2]) cylinder(d=WarpCoreTube_ID+1, h=Wall_t*2, $fn=360);
		translate([0,0,-Wall_t*2-Overlap]) cylinder(d1=WarpCoreTube_ID, d2=WarpCoreTube_ID-Wall_t*2, h=Wall_t*2+Overlap*2, $fn=360);
	} // difference
	
	if (HasCoupler){
		difference(){
			translate([0,0,-Len-Coupler_Len]) Tube(OD=Body_ID, ID=Body_ID-Wall_t*2, Len=Coupler_Len+Overlap, myfn=$preview? 90:360);
			for (j=[0:nBolts-1]) rotate([0,0,360/nBolts*j]) translate([0,Body_OD/2,-Len-BoltInset])
				rotate([-90,0,0]) Bolt4Hole();
		} // difference
		difference(){
			translate([0,0,-Len]) cylinder(d=Body_ID+1, h=Wall_t*2);
			
			translate([0,0,-Len-Overlap]) cylinder(d1=Body_ID-Wall_t*2, d2=Body_ID, h=Wall_t*2+Overlap*2, $fn=360);
		} // difference
	} // HasCoupler
	
	CenteringRing(OD=WarpCoreTube_ID-1, ID=Body_OD, Thickness=5, nHoles=12, Offset=0, myfn=$preview? 90:360);
	
	translate([0,0,-Len]) Tube(OD=Body_OD, ID=Body_ID, Len=Len+5, myfn=$preview? 90:360);
	
	// transition
	difference(){
		translate([0,0,-Len+5-Overlap]) cylinder(d1=Body_OD, d2=OD, h=Len-10+Overlap*2, $fn=360);
		
		translate([0,0,-Len+5-Overlap*2]) cylinder(d1=Body_OD-Wall_t*2, d2=OD-Wall_t*2, h=Len-10+Overlap*4, $fn=360);
		translate([0,0,-Len+4]) cylinder(d=Body_ID, h=8, $fn=360);
	} // difference
	
} // WarpCoreEnd

//translate([0,0,-5.2]) WarpCoreEnd();
// rotate([180,0,0]) WarpCoreEnd(); // print
// rotate([180,0,0]) WarpCoreEnd(HasCoupler=true); // print


module EBay(TopOnly=false, BottomOnly=false){

	Doors_a=[[0],[],[90,180,270]]; // Misson Control + 3 large battery doors
	
	EB_Electronics_BayUniversal(Tube_OD=Body_OD, Tube_ID=Body_ID, DoorAngles=Doors_a, Len=EBay_Len, 
									nBolts=6, BoltInset=7.5, ShowDoors=false,
									HasFwdIntegratedCoupler=false, HasFwdShockMount=false,
									HasAftIntegratedCoupler=false, HasAftShockMount=false,
									HasRailGuide=false, RailGuideLen=35,
									HasFwdCenteringRing=false, HasAftCenteringRing=false, InnerTube_OD=BT54Body_OD,
									Bolted=true, ExtraBolts=[], GlobalExtraBolts=[], TopOnly=TopOnly, BottomOnly=BottomOnly);
} // EBay

// EBay(TopOnly=false, BottomOnly=false);

module MotorRetainer(){
	FC2_MotorRetainer(Body_OD=Body_OD,
						MotorTube_OD=MotorTube_OD, MotorTube_ID=MotorTube_ID,
						HasWrenchCuts=false, Cone_Len=65, ExtraLen=0, Extra_OD=2, Extra_ID=0, Ogive=false);
						
	
} // MotorRetainer

//MotorRetainer();


module NacelleFin(){
	TrapFin3(Post_h=Fin_Post_h, Root_L=Fin_Root_L, Tip_L=Nacelle_Fin_Tip_L, Root_W=Fin_Root_W,
				Tip_W=Nacelle_Fin_Tip_W, Span=Nacelle_Fin_Span, Chamfer_L=Fin_Chamfer_L,
				TipOffset=Nacelle_Fin_TipOffset, HasBluntTip=true, TipPost_h=Nacelle_Fin_TipPost_h,
				Bisect=false, Bisect_X=0,
				HasSpar=false, Spar_d=8, Spar_L=100,
				PrinterBrim_H=0.6, HasSpiralVaseRibs=false);
	
} // NacelleFin

//NacelleFin();

module RocketFin(){
	
	TrapFin3(Post_h=Fin_Post_h, Root_L=Fin_Root_L, Tip_L=Fin_Tip_L, Root_W=Fin_Root_W,
				Tip_W=Fin_Tip_W, Span=Fin_Span, Chamfer_L=Fin_Chamfer_L,
				TipOffset=Fin_TipOffset,
				Bisect=false, Bisect_X=0,
				HasSpar=false, Spar_d=8, Spar_L=100,
				PrinterBrim_H=0.6, HasSpiralVaseRibs=false);
	
} // RocketFin

//RocketFin();

module FinCan(LowerHalfOnly=false, UpperHalfOnly=false){
	Wall_t=1.2;
	MidCR=(LowerHalfOnly||UpperHalfOnly);
	
	difference(){
		FC2_FinCan(Body_OD=Body_OD, Body_ID=Body_ID, Coupler_ID=0, Can_Len=FinCanLen,
				MotorTube_OD=MotorTube_OD, RailGuide_h=RailGuide_h, RailGuide_z=0,
				nFins=6, HasIntegratedCoupler=true, HasFwdCenteringRing=false, HasMidCenteringRing=MidCR, Coupler_Len=10, nCouplerBolts=0,
				HasMotorSleeve=true, HasAftIntegratedCoupler=false,
				Fin_Root_W=Fin_Root_W, Fin_Root_L=Fin_Root_L, Fin_Post_h=Fin_Post_h, Fin_Chamfer_L=Fin_Chamfer_L,
				Cone_Len=Cone_Len, ThreadedTC=true, Extra_OD=2, RailGuideLen=RailGuideLen,
				LowerHalfOnly=LowerHalfOnly, UpperHalfOnly=UpperHalfOnly, HasWireHoles=false, HollowTailcone=true, 
				HollowFinRoots=true, Wall_t=Wall_t, OgiveTailCone=false, Ogive_Len=400, OgiveCut_d=BT54Body_OD+8,
				UseTrapFin3=true, AftClosure_OD=ATRMS_54_Aft_d(), AftClosure_Len=10);
				
		if (UpperHalfOnly) cylinder(d=RailGuide_h*2+4, h=FinCanLen/2-10);
	} // difference
} // FinCan1

// FinCan();








































