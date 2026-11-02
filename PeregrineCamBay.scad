// Camera-bay mechanics, included by PeregrineCamNose.scad.
// Z is the assembled nosecone coordinate, including for separate parts.
// This is a prototype debris/gas barrier, not a pressure-rated bulkhead.

Bay_Floor_Z = 270;
Bay_Floor_T = 4;
Bay_Floor_D = 64;          // passes through the existing middle-slice lap
Bay_Seat_ID = 46;          // keeps 3 mm of seal land beneath the access scallops
Bay_Seat_T = 8;            // a 5.7 mm insert must not break through the seat
Bay_Seat_Ramp = 17;        // corbel builds inward without an unsupported disk
Bay_Floor_Bolt_R = 28;
Bay_Floor_Bolt_A = [30,150,270];

// These are fit envelopes, not a particular cell's manufacturing spec.
// Measure the wrapped cells before printing; body length excludes tabs.
Bay_Cell_D = 18.5;
Bay_Cell_Body_L = 65;
Bay_Cell_Clearance = 1.0;  // diametral: room for wrappers and insulating liner
Bay_Cell_Pitch = 21;
Bay_End_Relief = 2;        // solder tabs occupy a recess, not the bearing face
Bay_End_Window_D = 14.5;  // annular end supports leave the centre accessible
Bay_Tab_Slot_W = 6;
Bay_Cell_Bottom_Z = Bay_Floor_Z + Bay_Floor_T + Bay_End_Relief;
Bay_Cell_Top_Z = Bay_Cell_Bottom_Z + Bay_Cell_Body_L;
Bay_Keeper_Gap = 0.6;     // take up with a thin insulating annular pad
Bay_Cup_Wall = 2.2;
Bay_Cup_ID = Bay_Cell_D + Bay_Cell_Clearance;
Bay_Cup_OD = Bay_Cup_ID + 2*Bay_Cup_Wall;
Bay_Cup_H = 14;

Bay_Tray_Z = 347;
Bay_Tray_T = 3;
Bay_DCDC = [47,26,13];
Bay_DCDC_Clearance = 0.8; // total clearance on each footprint dimension
Bay_Tray_Wall = 1.8;
Bay_Tray_Rim_H = 3;
Bay_Tray_X = Bay_DCDC[0] + Bay_DCDC_Clearance + 2*Bay_Tray_Wall;
Bay_Tray_Y = Bay_DCDC[1] + Bay_DCDC_Clearance + 2*Bay_Tray_Wall;
// Outboard posts leave the converter's entire 47x26 footprint available.
// Tray screws are countersunk flush; a button head would eat this margin.
Bay_Posts = [[27,0],[-27,0]];
Bay_Post_D = 8;
Bay_M3_Clearance = 3.4;

Bay_Joint_A = [90,210,330]; // clear the two posts and the three floor fasteners
Bay_Joint_Z = Cut2_Z + 3.5;  // middle of the existing 7 mm overlap
Bay_Joint_R = Ogive_OD_At_Z(Bay_Joint_Z, NC_Wall_T)/2 - 0.35;

// The switch is on +Y; charging hardware is on -Y. Neither is keyed to a
// rail-button direction because that relation is not specified in the CAD.
Bay_Switch_Z = 315;
Bay_Switch_Face_Y = Ogive_OD_At_Z(Bay_Switch_Z-11)/2 + 0.8;
Bay_Switch_Panel_T = 6;    // flat front AND back for bezel and mounting nut
Bay_Switch_Hole_D = 12.7;  // finish to actual part; drawing allows 12.6..12.7
Bay_Charge_Z = 321;
Bay_Charge_Face_Y = Ogive_OD_At_Z(Bay_Charge_Z-6)/2 + 0.8;
Bay_Charge_Panel_T = 5;
Bay_Charge_X = [-8,0,8];  // mechanical screw seats only; no assigned polarity
Bay_Charge_Head_D = 6.2;  // nominal M3 90-degree countersunk screw

assert(Bay_Seat_T > Insert_Depth+1, "seat needs material behind its inserts");
assert(Bay_Cell_D > Bay_End_Window_D+2, "cell end bearing annulus too small");
assert(Bay_Cell_Top_Z+Bay_Keeper_Gap+2 < Bay_Tray_Z,
       "cell/keeper too tall for the converter floor");
assert(Bay_Cell_Top_Z+5 < Bay_Tray_Z, "allow at least 5 mm for the upper tabs");
assert(Bay_Tray_Z+Bay_Tray_T+Bay_DCDC[2] < Cut3_Z-Adapter_Spigot_L-3,
       "reserve the upper 15 mm for the camera harness, plus 3 mm clearance");

module Bay_Radial(a, r, z){
    rotate([0,0,a]) translate([r,0,z]) rotate([0,-90,0]) children();
}

module Bay_Seat(){
    z0 = Bay_Floor_Z - Bay_Seat_T - Bay_Seat_Ramp;
    difference(){
        // Slight overlap into the shell makes one connected printed part.
        translate([0,0,z0])
            cylinder(d1=Ogive_OD_At_Z(z0,NC_Wall_T)+0.8,
                     d2=Ogive_OD_At_Z(Bay_Floor_Z,NC_Wall_T)+0.8,
                     h=Bay_Floor_Z-z0, $fn=180);
        translate([0,0,z0-Overlap])
            cylinder(d1=Ogive_OD_At_Z(z0,NC_Wall_T)+0.1,
                     d2=Bay_Seat_ID, h=Bay_Seat_Ramp+Overlap, $fn=180);
        translate([0,0,Bay_Floor_Z-Bay_Seat_T-Overlap])
            cylinder(d=Bay_Seat_ID,h=Bay_Seat_T+2*Overlap,$fn=180);
        for (a=Bay_Floor_Bolt_A)
            translate([Bay_Floor_Bolt_R*cos(a),Bay_Floor_Bolt_R*sin(a),
                       Bay_Floor_Z-Insert_Depth-0.2])
                cylinder(d=Insert_Hole_D,h=Insert_Depth+0.2+Overlap,$fn=36);
    }
}

module Bay_Joint_Bosses(){
    intersection(){
        for (a=Bay_Joint_A)
            Bay_Radial(a,Bay_Joint_R,Bay_Joint_Z)
                cylinder(d=9,h=9,$fn=48);
        // The boss must not obstruct lifting the top shell off its lap.
        translate([0,0,Cut2_Z-2])
            cylinder(d1=Ogive_OD_At_Z(Cut2_Z-2,NC_Wall_T)-0.7,
                     d2=Ogive_OD_At_Z(Cut2_Z+7,NC_Wall_T)-0.7,
                     h=9,$fn=180);
    }
}

module CN_Bay_Middle(){
    difference(){
        union(){
            CN_Slice_Middle_Shell();
            Bay_Seat();
            Bay_Joint_Bosses();
        }
        for (a=Bay_Joint_A){
            // Inserts installed from outside with the top shell removed.
            // Start outside the original library lap too: its outer arc
            // is slightly larger than the conservative new boss envelope.
            Bay_Radial(a,Bay_Joint_R+1,Bay_Joint_Z)
                cylinder(d=Insert_Hole_D,h=Insert_Depth+1.3,$fn=36);
            Bay_Radial(a,Bay_Joint_R+1,Bay_Joint_Z)
                cylinder(d=Bay_M3_Clearance,h=11,$fn=36);
        }
    }
}

// Local XY is the face of the panel; local +Z points into the bay.
module Bay_Switch_Frame(){
    translate([0,Bay_Switch_Face_Y,Bay_Switch_Z]) rotate([90,0,0]) children();
}
module Bay_Charge_Frame(){
    translate([0,-Bay_Charge_Face_Y,Bay_Charge_Z]) rotate([-90,0,0]) children();
}
module Bay_Panel(w,h,t){
    hull() for(x=[-w/2+3,w/2-3]) for(y=[-h/2+3,h/2-3])
        translate([x,y,0]) cylinder(r=3,h=t,$fn=36);
}

module Bay_Camera_Flange(){
    // One print with the service shell. There is no buried spigot or glue
    // gap: the 6 mm shelf joins the shell rim directly. Print flange-down.
    difference(){
        translate([0,0,Cut3_Z-Overlap])
            cylinder(d=Adapter_Flange_OD,h=Adapter_Flange_T+Overlap,$fn=360);
        translate([0,0,Cut3_Z-2*Overlap])
            cylinder(d=Adapter_Bore_D,h=Adapter_Flange_T+3*Overlap,$fn=180);
        for(a=CAD_Bolt_A)
            translate([CAD_Bolt_R*cos(a),CAD_Bolt_R*sin(a),Cut3_Z-2*Overlap])
                cylinder(d=Insert_Hole_D,h=Adapter_Flange_T+3*Overlap,$fn=36);
    }
}

module CN_Bay_Top(){
    difference(){
        union(){
            CN_Slice_Top_Shell();
            Bay_Camera_Flange();
            Bay_Switch_Frame() Bay_Panel(22,22,Bay_Switch_Panel_T);
            Bay_Charge_Frame() Bay_Panel(28,12,Bay_Charge_Panel_T);
        }
        for(a=Bay_Joint_A)
            Bay_Radial(a,Ogive_OD_At_Z(Bay_Joint_Z)/2+1,Bay_Joint_Z)
                cylinder(d=Bay_M3_Clearance,h=8,$fn=36);
        Bay_Switch_Frame(){
            translate([0,0,-Overlap])
                cylinder(d=Bay_Switch_Hole_D,h=Bay_Switch_Panel_T+2*Overlap,$fn=120);
            // R1.2 key relief; 6.35 + (6.05+1.2) = 13.60 overall height.
            translate([0,6.05,-Overlap])
                cylinder(r=1.2,h=Bay_Switch_Panel_T+2*Overlap,$fn=48);
        }
        Bay_Charge_Frame() for(x=Bay_Charge_X){
            translate([x,0,-Overlap])
                cylinder(d=Bay_M3_Clearance,h=Bay_Charge_Panel_T+2*Overlap,$fn=48);
            translate([x,0,-Overlap])
                cylinder(d1=Bay_Charge_Head_D+2*Overlap,d2=Bay_M3_Clearance,
                         h=(Bay_Charge_Head_D-Bay_M3_Clearance)/2+Overlap,$fn=60);
        }
    }
}

module Bay_End_Support(z,t){
    // Two separated arcs carry the insulated rim; the centre and both tab
    // exit slots are empty. No potting or clamping across the cell vent.
    difference(){
        translate([0,0,z]) cylinder(d=Bay_Cup_OD,h=t,$fn=90);
        translate([0,0,z-Overlap])
            cylinder(d=Bay_End_Window_D,h=t+2*Overlap,$fn=90);
        translate([-Bay_Tab_Slot_W/2,-Bay_Cup_OD,z-Overlap])
            cube([Bay_Tab_Slot_W,2*Bay_Cup_OD,t+2*Overlap]);
    }
}

module Bay_Carrier_Plan(h=Bay_Floor_T){
    difference(){
        cylinder(d=Bay_Floor_D,h=h,$fn=180);
        // The insert bosses narrow the service opening. These three
        // scallops let the floor pass them, while still covering the seat
        // bore by 3 mm. Keep their clocking tied to the actual joint bosses.
        for(a=Bay_Joint_A) rotate([0,0,a]) translate([26,-6,-Overlap])
            cube([12,12,h+2*Overlap]);
    }
}

module CN_Battery_Carrier(){
    difference(){
        union(){
            translate([0,0,Bay_Floor_Z]) Bay_Carrier_Plan();
            for(x=[-Bay_Cell_Pitch/2,Bay_Cell_Pitch/2]) translate([x,0,0]){
                Bay_End_Support(Bay_Floor_Z+Bay_Floor_T,Bay_End_Relief);
                difference(){
                    translate([0,0,Bay_Cell_Bottom_Z]) cylinder(d=Bay_Cup_OD,h=Bay_Cup_H,$fn=90);
                    translate([0,0,Bay_Cell_Bottom_Z-Overlap])
                        cylinder(d=Bay_Cup_ID,h=Bay_Cup_H+2*Overlap,$fn=90);
                    // Tab exits open above the continuous barrier floor.
                    translate([-Bay_Tab_Slot_W/2,-Bay_Cup_OD,Bay_Cell_Bottom_Z-Overlap])
                        cube([Bay_Tab_Slot_W,2*Bay_Cup_OD,3+Overlap]);
                }
            }
            for(p=Bay_Posts) translate([p[0],p[1],Bay_Floor_Z+Bay_Floor_T-Overlap])
                cylinder(d=Bay_Post_D,h=Bay_Tray_Z-Bay_Floor_Z-Bay_Floor_T+Overlap,$fn=60);
        }
        for(a=Bay_Floor_Bolt_A)
            translate([Bay_Floor_Bolt_R*cos(a),Bay_Floor_Bolt_R*sin(a),Bay_Floor_Z-Overlap])
                cylinder(d=Bay_M3_Clearance,h=Bay_Floor_T+2*Overlap,$fn=36);
        // Adjacent cups share a wall: cut BOTH cavities after the union so
        // neither cup's outer wall intrudes into its neighbour's cell.
        for(x=[-Bay_Cell_Pitch/2,Bay_Cell_Pitch/2])
            translate([x,0,Bay_Cell_Bottom_Z])
                cylinder(d=Bay_Cup_ID,h=Bay_Cup_H+Overlap,$fn=90);
        for(p=Bay_Posts) translate([p[0],p[1],Bay_Tray_Z-Insert_Depth-0.2])
            cylinder(d=Insert_Hole_D,h=Insert_Depth+0.2+Overlap,$fn=36);
    }
}

module CN_Converter_Tray(){
    keeper_z = Bay_Cell_Top_Z+Bay_Keeper_Gap;
    difference(){
        union(){
            // Shallow epoxy bath. Component volume above it remains open.
            translate([-Bay_Tray_X/2,-Bay_Tray_Y/2,Bay_Tray_Z])
                cube([Bay_Tray_X,Bay_Tray_Y,Bay_Tray_T]);
            difference(){
                translate([-Bay_Tray_X/2,-Bay_Tray_Y/2,Bay_Tray_Z+Bay_Tray_T-Overlap])
                    cube([Bay_Tray_X,Bay_Tray_Y,Bay_Tray_Rim_H+Overlap]);
                translate([-(Bay_DCDC[0]+Bay_DCDC_Clearance)/2,
                           -(Bay_DCDC[1]+Bay_DCDC_Clearance)/2,Bay_Tray_Z+Bay_Tray_T-2*Overlap])
                    cube([Bay_DCDC[0]+Bay_DCDC_Clearance,Bay_DCDC[1]+Bay_DCDC_Clearance,
                          Bay_Tray_Rim_H+4*Overlap]);
            }
            for(p=Bay_Posts) translate([p[0],p[1],Bay_Tray_Z])
                cylinder(d=Bay_Post_D,h=Bay_Tray_T,$fn=60);
            for(x=[-Bay_Cell_Pitch/2,Bay_Cell_Pitch/2]) translate([x,0,0]){
                difference(){
                    translate([0,0,keeper_z-4]) cylinder(d=Bay_Cup_OD,h=4+Overlap,$fn=90);
                    translate([0,0,keeper_z-4-Overlap])
                        cylinder(d=Bay_Cup_ID,h=4+3*Overlap,$fn=90);
                    translate([-Bay_Tab_Slot_W/2,-Bay_Cup_OD,keeper_z-4-Overlap])
                        cube([Bay_Tab_Slot_W,2*Bay_Cup_OD,5]);
                }
                Bay_End_Support(keeper_z,2);
                // Two ribs transmit axial retention load to the tray.
                for(s=[-1,1]) translate([s*(Bay_Cup_ID/2+Bay_Cup_Wall/2)-1,-3,keeper_z+1])
                    cube([2,6,Bay_Tray_Z-keeper_z-1+Overlap]);
            }
        }
        for(p=Bay_Posts){
            translate([p[0],p[1],Bay_Tray_Z-Overlap])
                cylinder(d=Bay_M3_Clearance,h=Bay_Tray_T+2*Overlap,$fn=36);
            translate([p[0],p[1],Bay_Tray_Z+Bay_Tray_T-1.4])
                cylinder(d1=Bay_M3_Clearance,d2=6.2+2*Overlap,
                         h=1.4+Overlap,$fn=60);
        }
        for(x=[-Bay_Cell_Pitch/2,Bay_Cell_Pitch/2])
            translate([x,0,keeper_z-4-Overlap])
                cylinder(d=Bay_Cup_ID,h=4+Overlap,$fn=90);
        // These two channels take a 2.5 mm cable tie around the converter.
        // They are in the tray, never through the blast/debris floor.
        for(y=[-8,8]) translate([-Bay_Tray_X/2-Overlap,y-1.6,Bay_Tray_Z+0.8])
            cube([Bay_Tray_X+2*Overlap,3.2,1.2]);
    }
}

module CN_Bay_Components(){
    for(x=[-Bay_Cell_Pitch/2,Bay_Cell_Pitch/2])
        color([0.18,0.55,0.76]) translate([x,0,Bay_Cell_Bottom_Z])
            cylinder(d=Bay_Cell_D,h=Bay_Cell_Body_L,$fn=90);
    color([0.1,0.5,0.2]) translate([-Bay_DCDC[0]/2,-Bay_DCDC[1]/2,Bay_Tray_Z+Bay_Tray_T])
        cube(Bay_DCDC);
}

module CN_Bay_Assembly(){
    // Cut away only the shell; parts and component envelopes stay whole.
    color([0.78,0.79,0.81,0.45]) difference(){
        union(){CN_Slice_Middle(); CN_Slice_Top();}
        translate([-100,-100,240]) cube([200,100,180]);
        translate([-100,-100,0]) cube([200,200,246]);
    }
    color([0.95,0.62,0.18]) CN_Battery_Carrier();
    color([0.95,0.62,0.18]) CN_Converter_Tray();
    // Flange is integral with the top shell; no separate adapter is shown.
    CN_Bay_Components();
}
