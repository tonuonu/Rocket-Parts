// Run every simulation in an .ork (OpenRocket 24.12), optionally with an extra mass (kg at an
// absolute station, m from the tip) in the aft body tube and optionally with the main fin set's
// outline replaced, and print each sim's motor, max speed, Mach, air density at max q, max q,
// liftoff mass and CG, the mass, stability, CG and CP at max speed. Used by
// tailsteer_estimate.py (the OR tables per airframe).
// The mass goes in as a zero-length mass component in "Aft Body tube". If the stage carries a mass
// override that covers its subcomponents (the Zephyr model), a component would be ignored, so the
// mass is folded into the override instead (mass and CG).
// --fins FILE: "x_mm,y_mm" lines, the freeform outline of "Fin set" in fin coordinates (x aft from
// the root LE, y out from the body). The root leading edge stays where it was.
// Run with a JDK (the JRE in OpenRocket.app has no compiler):
//   java -Djava.awt.headless=true -cp OpenRocket-24.12.jar tools/ORSimMass.java FILE.ork [dm_kg x_from_tip_m] [--fins FILE]
//   e.g. PeregrineL2-CamNose.ork 0.460 1.531 (the tail-steering change)
import info.openrocket.core.document.OpenRocketDocument;
import info.openrocket.core.document.Simulation;
import info.openrocket.core.file.GeneralRocketLoader;
import info.openrocket.core.plugin.PluginModule;
import info.openrocket.core.rocketcomponent.*;
import info.openrocket.core.rocketcomponent.position.AxialMethod;
import info.openrocket.core.simulation.FlightDataBranch;
import info.openrocket.core.simulation.FlightDataType;
import info.openrocket.core.startup.Application;
import info.openrocket.core.util.Coordinate;
import com.google.inject.Guice;
import com.google.inject.Injector;
import java.io.File;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.List;

public class ORSimMass {
    static void usage() {
        System.err.println("usage: ORSimMass FILE.ork [dm_kg x_from_tip_m] [--fins FILE]  (the mass needs its position)");
        System.exit(1);
    }

    public static void main(String[] args) throws Exception {
        List<String> a = new ArrayList<>();
        String fins = null;
        for (int i = 0; i < args.length; i++) {
            if (args[i].equals("--fins")) {
                if (i + 1 >= args.length) usage();
                fins = args[++i];
            } else a.add(args[i]);
        }
        if (a.size() != 1 && a.size() != 3) usage();
        info.openrocket.swing.startup.GuiModule gm = new info.openrocket.swing.startup.GuiModule();
        Injector inj = Guice.createInjector(gm, new PluginModule());
        Application.setInjector(inj);
        gm.startLoader();
        OpenRocketDocument doc = new GeneralRocketLoader(new File(a.get(0))).load();
        Rocket rocket = doc.getRocket();
        double dm = a.size() == 3 ? Double.parseDouble(a.get(1)) : 0, x = a.size() == 3 ? Double.parseDouble(a.get(2)) : 0;
        BodyTube aft = null;
        for (RocketComponent c : rocket) if (c instanceof BodyTube && c.getName().equals("Aft Body tube")) aft = (BodyTube) c;
        if ((dm != 0 || fins != null) && aft == null) {
            System.err.println("ORSimMass: no body tube named \"Aft Body tube\" in " + a.get(0));
            System.exit(2);
        }
        if (fins != null) {
            FreeformFinSet fs = null;
            for (RocketComponent c : aft.getChildren()) if (c instanceof FreeformFinSet && c.getName().equals("Fin set")) fs = (FreeformFinSet) c;
            if (fs == null) {
                System.err.println("ORSimMass: no freeform fin set named \"Fin set\" in the aft body tube");
                System.exit(2);
            }
            double le = fs.getComponentLocations()[0].x;   // root leading edge, from the tip
            List<Coordinate> pts = new ArrayList<>();
            for (String line : Files.readAllLines(new File(fins).toPath())) {
                line = line.trim();
                if (line.isEmpty() || line.startsWith("#")) continue;
                String[] f = line.split(",");
                pts.add(new Coordinate(Double.parseDouble(f[0]) / 1000, Double.parseDouble(f[1]) / 1000));
            }
            fs.setPoints(pts.toArray(new Coordinate[0]));
            fs.setAxialMethod(AxialMethod.ABSOLUTE);
            fs.setAxialOffset(le);
            System.err.printf("ORSimMass: fin outline from %s, %d points, root LE kept at %.5f m%n", fins, pts.size(), fs.getComponentLocations()[0].x);
        }
        if (dm != 0) {
            AxialStage stage = aft.getStage();
            if (stage.isMassOverridden() && stage.isSubcomponentsOverriddenMass()) {
                double M = stage.getOverrideMass(), cg = stage.getOverrideCGX();
                if (!stage.isCGOverridden() || !stage.isSubcomponentsOverriddenCG()) {
                    System.err.println("ORSimMass: the stage overrides its mass but not its CG; cannot fold the mass in");
                    System.exit(2);
                }
                stage.setOverrideMass(M + dm);
                stage.setOverrideCGX((M * cg + dm * x) / (M + dm));   // the stage starts at the tip
                System.err.printf("ORSimMass: stage override %.4f kg at %.4f m -> %.4f kg at %.4f m%n", M, cg, M + dm, stage.getOverrideCGX());
            } else {
                MassComponent mc = new MassComponent();
                mc.setName("tail steering delta");
                mc.setComponentMass(dm);
                mc.setLength(0);   // 24.12 default is a 25 mm packed length: the CG would sit 12.5 mm aft of x
                aft.addChild(mc);
                mc.setAxialMethod(AxialMethod.ABSOLUTE);
                mc.setAxialOffset(x);
            }
        }
        System.out.println("sim,motor,vmax_mps,mach,rho,q_Pa,liftoff_kg,liftoff_cg_m,vmax_kg,stab_at_vmax_cal,cg_at_vmax_m,cp_at_vmax_m");
        for (Simulation sim : doc.getSimulations()) {
            sim.simulate();
            FlightDataBranch b = sim.getSimulatedData().getBranch(0);
            List<Double> v = b.get(FlightDataType.TYPE_VELOCITY_TOTAL), rho = b.get(FlightDataType.TYPE_AIR_DENSITY),
                         mach = b.get(FlightDataType.TYPE_MACH_NUMBER), m = b.get(FlightDataType.TYPE_MASS),
                         st = b.get(FlightDataType.TYPE_STABILITY), cgl = b.get(FlightDataType.TYPE_CG_LOCATION),
                         cpl = b.get(FlightDataType.TYPE_CP_LOCATION);
            int im = 0; double qmax = 0; int iq = 0;
            for (int i = 0; i < v.size(); i++) {
                if (v.get(i) > v.get(im)) im = i;
                double q = 0.5 * rho.get(i) * v.get(i) * v.get(i);
                if (q > qmax) { qmax = q; iq = i; }
            }
            String motor = sim.getActiveConfiguration().getActiveMotors().isEmpty() ? "?" :
                sim.getActiveConfiguration().getActiveMotors().iterator().next().getMotor().getDesignation();
            System.out.printf("%s,%s,%.1f,%.3f,%.3f,%.0f,%.3f,%.4f,%.3f,%.2f,%.4f,%.4f%n", sim.getName().replace(",", " "), motor,
                v.get(im), mach.get(im), rho.get(iq), qmax, m.get(0), cgl.get(0), m.get(im), st.get(im), cgl.get(im), cpl.get(im));
        }
    }
}
