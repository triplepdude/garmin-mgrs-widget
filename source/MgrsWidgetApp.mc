import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// MGRS Coords widget entry point.
// Runs in the glance loop (system widget menu) on the Forerunner 255.
(:glance)
class MgrsWidgetApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        var view = new MgrsMainView();
        return [view, new MgrsMainDelegate(view)];
    }

    (:glance)
    function getGlanceView() {
        return [new MgrsGlanceView()];
    }
}
