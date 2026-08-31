import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Glance shown in the system widget loop. Reads only the activity's
// current fix (no GPS is started from the glance) and falls back to the
// most recently saved waypoint.
(:glance)
class MgrsGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.clear();

        var label = "MGRS";
        var line = null;

        var info = Activity.getActivityInfo();
        if (info != null && info.currentLocation != null) {
            line = MgrsFormat.fromLocation(info.currentLocation);
        }
        if (line == null) {
            var last = MgrsStore.latest();
            if (last != null) {
                label = "MGRS - " + last["name"];
                line = last["mgrs"];
            }
        }
        if (line == null) {
            line = "No position yet";
        }

        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, h / 4, Graphics.FONT_GLANCE, label,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, (h * 3) / 4, Graphics.FONT_GLANCE, line,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
