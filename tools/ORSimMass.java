// Run every simulation in an .ork (OpenRocket 24.12), optionally with an extra mass (kg at an
// absolute station, m from the tip) in the aft body tube and optionally with the main fin set's
// outline replaced, and print each sim's motor, max speed, Mach, air density at max q, max q,
// liftoff mass and CG, the mass, stability, CG and CP at max speed. Used by
// tailsteer_estimate.py (the OR tables per airframe).
// The mass goes in as a zero-length mass component in "Aft Body tube". If the aft tube or any
// component above it (up to the rocket) overrides the mass or the CG of its subcomponents, a new
// component would be hidden: the mass is folded into the topmost such override (mass and CG), and
// the tool exits if that component overrides only one of the two.
// --fins FILE: "x_mm,y_mm" lines, the freeform outline of "Fin set" in fin coordinates (x aft from
// the root LE, y out from the body). The root leading edge stays where it was. With a mass as well,
// the mass is taken to already hold the fin change (new minus .ork fins, as tailsteer_estimate.py
// prints it), so the fin set's mass and CG stay pinned at their .ork values and only its aerodynamics
// change; OpenRocket would otherwise add the new outline's mass a second time.
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

    static double at(List<Double> l, int i) {   // a series OpenRocket did not record prints as NaN
        return l == null || i >= l.size() || l.get(i) == null ? Double.NaN : l.get(i);
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
            if (dm != 0) {
                // pin the .ork fin mass and CG (an own override, if any, already does)
                double m0 = fs.isMassOverridden() ? fs.getOverrideMass() : fs.getComponentMass();
                double cg0 = fs.isCGOverridden() ? fs.getOverrideCGX() : fs.getComponentCG().x;
                fs.setMassOverridden(true);
                fs.setOverrideMass(m0);
                fs.setCGOverridden(true);
                fs.setOverrideCGX(cg0);
                System.err.printf("ORSimMass: fin set mass and CG pinned at the .ork's %.4f kg, %.4f m behind the root LE"
                    + " (the mass given holds the fin change)%n", m0, cg0);
            }
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
            RocketComponent hide = null;   // topmost component whose override covers the aft tube's contents
            for (RocketComponent c = aft; c != null; c = c.getParent())
                if ((c.isMassOverridden() && c.isSubcomponentsOverriddenMass()) || (c.isCGOverridden() && c.isSubcomponentsOverriddenCG()))
                    hide = c;
            if (hide != null) {
                if (!(hide.isMassOverridden() && hide.isSubcomponentsOverriddenMass()
                      && hide.isCGOverridden() && hide.isSubcomponentsOverriddenCG())) {
                    System.err.println("ORSimMass: \"" + hide.getName() + "\" overrides only one of mass and CG for its"
                        + " subcomponents; the mass cannot be added or folded in");
                    System.exit(2);
                }
                double M = hide.getOverrideMass(), loc = hide.getComponentLocations()[0].x;
                double cg = loc + hide.getOverrideCGX();   // the override CG is relative to the component's front
                hide.setOverrideMass(M + dm);
                hide.setOverrideCGX((M * cg + dm * x) / (M + dm) - loc);
                System.err.printf("ORSimMass: override of \"%s\" %.4f kg at %.4f m -> %.4f kg at %.4f m%n",
                    hide.getName(), M, cg, M + dm, loc + hide.getOverrideCGX());
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
                v.get(im), at(mach, im), at(rho, iq), qmax, at(m, 0), at(cgl, 0), at(m, im), at(st, im), at(cgl, im), at(cpl, im));
        }
    }
}
