import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
import Toybox.WatchUi;

// Full-screen widget view. Page 0 shows the live MGRS position; pages
// 1..N show saved waypoints, newest first. Navigate with UP/DOWN,
// save with START, delete a saved waypoint with MENU (hold UP).
class MgrsMainView extends WatchUi.View {

    var pageIndex = 0;
    var currentMgrs = null;
    var currentLat = null;
    var currentLon = null;
    var accuracy = Position.QUALITY_NOT_AVAILABLE;
    var flashText = null;

    function initialize() {
        View.initialize();
    }

    function onShow() {
        // Seed from a running activity so the widget agrees with an
        // in-progress (navigation) activity immediately.
        seedFromActivity();
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onHide() {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    function seedFromActivity() {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentLocation != null) {
            setLocation(info.currentLocation);
            if (info.currentLocationAccuracy != null) {
                accuracy = info.currentLocationAccuracy;
            }
        }
    }

    function onPosition(info as Position.Info) as Void {
        if (info.position != null) {
            setLocation(info.position);
        }
        if (info.accuracy != null) {
            accuracy = info.accuracy;
        }
        WatchUi.requestUpdate();
    }

    function setLocation(location) {
        var mgrs = MgrsFormat.fromLocation(location);
        if (mgrs != null) {
            currentMgrs = mgrs;
            var deg = location.toDegrees();
            currentLat = deg[0];
            currentLon = deg[1];
        }
    }

    function pageCount() {
        return MgrsStore.count() + 1;
    }

    function nextPage() {
        pageIndex = (pageIndex + 1) % pageCount();
        flashText = null;
        WatchUi.requestUpdate();
    }

    function prevPage() {
        pageIndex = (pageIndex + pageCount() - 1) % pageCount();
        flashText = null;
        WatchUi.requestUpdate();
    }

    function clampPage() {
        if (pageIndex >= pageCount()) {
            pageIndex = pageCount() - 1;
        }
        WatchUi.requestUpdate();
    }

    // Storage index of the entry shown on the current page (newest first).
    function storeIndexForPage() {
        if (pageIndex == 0) {
            return -1;
        }
        return MgrsStore.count() - pageIndex;
    }

    function saveCurrent() {
        if (currentMgrs == null) {
            flashText = "No fix yet";
            WatchUi.requestUpdate();
            return true;
        }
        var name = MgrsStore.nextName();
        MgrsStore.add(name, currentMgrs, currentLat, currentLon, Time.now().value());
        flashText = "Saved " + name;
        if (WatchUi has :showToast) {
            WatchUi.showToast("Saved " + name, null);
        }
        WatchUi.requestUpdate();
        return true;
    }

    function accuracyLabel() {
        if (accuracy == Position.QUALITY_GOOD) {
            return "GPS good";
        } else if (accuracy == Position.QUALITY_USABLE) {
            return "GPS ok";
        } else if (accuracy == Position.QUALITY_POOR) {
            return "GPS poor";
        } else if (accuracy == Position.QUALITY_LAST_KNOWN) {
            return "last known";
        }
        return "acquiring...";
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        if (pageIndex == 0) {
            drawLivePage(dc, cx, h);
        } else {
            drawSavedPage(dc, cx, h);
        }
    }

    function drawLivePage(dc, cx, h) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 8, Graphics.FONT_XTINY, "CURRENT  -  " + accuracyLabel(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var lines = MgrsFormat.toLines(currentMgrs);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 32) / 100, Graphics.FONT_MEDIUM, lines[0],
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, (h * 47) / 100, Graphics.FONT_MEDIUM, lines[1],
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 62) / 100, Graphics.FONT_XTINY,
            MgrsFormat.latLonString(currentLat, currentLon),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var footer;
        if (flashText != null) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            footer = flashText;
        } else {
            footer = "START: save";
        }
        dc.drawText(cx, (h * 76) / 100, Graphics.FONT_XTINY, footer,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 88) / 100, Graphics.FONT_XTINY,
            "saved: " + MgrsStore.count(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawSavedPage(dc, cx, h) {
        var idx = storeIndexForPage();
        var list = MgrsStore.load();
        if (idx < 0 || idx >= list.size()) {
            clampPage();
            return;
        }
        var entry = list[idx];

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 8, Graphics.FONT_SMALL, entry["name"],
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var lines = MgrsFormat.toLines(entry["mgrs"]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 32) / 100, Graphics.FONT_MEDIUM, lines[0],
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, (h * 47) / 100, Graphics.FONT_MEDIUM, lines[1],
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 62) / 100, Graphics.FONT_XTINY,
            MgrsFormat.latLonString(entry["lat"], entry["lon"]),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, (h * 74) / 100, Graphics.FONT_XTINY,
            MgrsFormat.timestampString(entry["ts"]),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, (h * 88) / 100, Graphics.FONT_XTINY,
            "" + pageIndex + "/" + (pageCount() - 1) + "  MENU: delete",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
