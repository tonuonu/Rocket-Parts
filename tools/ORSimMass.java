// Run every simulation in an .ork (OpenRocket 24.12), optionally with an extra mass component
// (kg at an absolute station, m from the tip) added to the aft body tube, and print each sim's
// motor, max speed, Mach, air density at
// max q, max q, liftoff mass and stability at max speed. Used by tailsteer_estimate.py (OR_VMAX).
// Run with a JDK (the JRE in OpenRocket.app has no compiler):
//   java -Djava.awt.headless=true -cp OpenRocket-24.12.jar tools/ORSimMass.java FILE.ork [dm_kg x_from_tip_m]
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
import com.google.inject.Guice;
import com.google.inject.Injector;
import java.io.File;
import java.util.List;

public class ORSimMass {
    public static void main(String[] a) throws Exception {
        info.openrocket.swing.startup.GuiModule gm = new info.openrocket.swing.startup.GuiModule();
        Injector inj = Guice.createInjector(gm, new PluginModule());
        Application.setInjector(inj);
        gm.startLoader();
        OpenRocketDocument doc = new GeneralRocketLoader(new File(a[0])).load();
        Rocket rocket = doc.getRocket();
        double dm = a.length > 1 ? Double.parseDouble(a[1]) : 0, x = a.length > 2 ? Double.parseDouble(a[2]) : 0;
        if (dm != 0) {
            BodyTube aft = null;
            for (RocketComponent c : rocket) if (c instanceof BodyTube && c.getName().equals("Aft Body tube")) aft = (BodyTube) c;
            if (aft == null) {
                System.err.println("ORSimMass: no body tube named \"Aft Body tube\" in " + a[0] + "; cannot add the mass");
                System.exit(2);
            }
            MassComponent mc = new MassComponent();
            mc.setName("tail steering delta");
            mc.setComponentMass(dm);
            mc.setLength(0);   // 24.12 default is a 25 mm packed length: the CG would sit 12.5 mm aft of x
            aft.addChild(mc);
            mc.setAxialMethod(AxialMethod.ABSOLUTE);
            mc.setAxialOffset(x);
        }
        System.out.println("sim,motor,vmax_mps,mach,rho,q_Pa,liftoff_kg,stab_at_vmax_cal");
        for (Simulation sim : doc.getSimulations()) {
            sim.simulate();
            FlightDataBranch b = sim.getSimulatedData().getBranch(0);
            List<Double> v = b.get(FlightDataType.TYPE_VELOCITY_TOTAL), rho = b.get(FlightDataType.TYPE_AIR_DENSITY),
                         mach = b.get(FlightDataType.TYPE_MACH_NUMBER), m = b.get(FlightDataType.TYPE_MASS),
                         st = b.get(FlightDataType.TYPE_STABILITY);
            int im = 0; double qmax = 0; int iq = 0;
            for (int i = 0; i < v.size(); i++) {
                if (v.get(i) > v.get(im)) im = i;
                double q = 0.5 * rho.get(i) * v.get(i) * v.get(i);
                if (q > qmax) { qmax = q; iq = i; }
            }
            String motor = sim.getActiveConfiguration().getActiveMotors().isEmpty() ? "?" :
                sim.getActiveConfiguration().getActiveMotors().iterator().next().getMotor().getDesignation();
            System.out.printf("%s,%s,%.1f,%.3f,%.3f,%.0f,%.3f,%.2f%n", sim.getName().replace(",", " "), motor,
                v.get(im), mach.get(im), rho.get(iq), qmax, m.get(0), st.get(im));
        }
    }
}
