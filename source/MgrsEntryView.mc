import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Manual MGRS entry, one field at a time. Fields left to right:
// zone (1-60), band letter, the two 100 km square letters, then the
// five easting and five northing digits. UP/DOWN change the active
// field, START steps to the next one (finishing after the last),
// MENU accepts the whole grid immediately, BACK steps backwards and
// exits from the first field. The form is pre-filled from the current
// fix (or the newest saved waypoint), since a grid being entered is
// usually nearby and shares most of the prefix.
class MgrsEntryView extends WatchUi.View {

    const FIELD_COUNT = 14; // zone, band, sq1, sq2, 5 + 5 digits

    var mainView;
    var field = 0;
    var flashText = null;

    var zone = 31;
    var bandIdx = 18;        // into MgrsParse.BANDS ("U")
    var colIdx = 0;          // into MgrsParse.colLetters(zone)
    var rowIdx = 0;          // into MgrsParse.ROWS
    var digits = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    function initialize(main) {
        View.initialize();
        mainView = main;
        var seed = main.currentMgrs;
        if (seed == null || !prefill(seed)) {
            var last = MgrsStore.latest();
            if (last != null) {
                prefill(last["mgrs"]);
            }
        }
    }

    // Seed the fields from a "32T MK 12345 67890" string. Polar "(UPS)"
    // references can't be entered, so they don't seed either.
    function prefill(mgrs) {
        var parts = MgrsFormat.split(mgrs, " ");
        if (parts.size() != 4) {
            return false;
        }
        var zb = parts[0];
        var sq = parts[1];
        if (zb.length() < 2 || sq.length() != 2
            || parts[2].length() != 5 || parts[3].length() != 5) {
            return false;
        }
        var z = zb.substring(0, zb.length() - 1).toNumber();
        var bi = MgrsParse.BANDS.find(zb.substring(zb.length() - 1, zb.length()));
        if (z == null || z < 1 || z > 60 || bi == null) {
            return false;
        }
        var ci = MgrsParse.colLetters(z).find(sq.substring(0, 1));
        var ri = MgrsParse.ROWS.find(sq.substring(1, 2));
        if (ci == null || ri == null) {
            return false;
        }
        var ds = [];
        for (var i = 0; i < 5; i++) {
            var de = parts[2].substring(i, i + 1).toNumber();
            var dn = parts[3].substring(i, i + 1).toNumber();
            if (de == null || dn == null) {
                return false;
            }
            ds.add(de);
            ds.add(dn);
        }
        zone = z;
        bandIdx = bi;
        colIdx = ci;
        rowIdx = ri;
        for (var i = 0; i < 5; i++) {
            digits[i] = ds[i * 2];
            digits[i + 5] = ds[i * 2 + 1];
        }
        return true;
    }

    // UP/DOWN: step the active field by +/-1, wrapping.
    function adjust(delta) {
        flashText = null;
        if (field == 0) {
            zone = ((zone - 1 + delta + 60) % 60) + 1;
        } else if (field == 1) {
            bandIdx = (bandIdx + delta + 20) % 20;
        } else if (field == 2) {
            colIdx = (colIdx + delta + 8) % 8;
        } else if (field == 3) {
            rowIdx = (rowIdx + delta + 20) % 20;
        } else {
            var i = field - 4;
            digits[i] = (digits[i] + delta + 10) % 10;
        }
        WatchUi.requestUpdate();
    }

    // START: next field; finishing the last field accepts the grid.
    function nextField() {
        flashText = null;
        if (field == FIELD_COUNT - 1) {
            accept();
            return;
        }
        field++;
        WatchUi.requestUpdate();
    }

    // BACK: previous field; from the first field, leave the form.
    function prevField() {
        flashText = null;
        if (field == 0) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return;
        }
        field--;
        WatchUi.requestUpdate();
    }

    function accept() {
        var easting = 0;
        var northing = 0;
        for (var i = 0; i < 5; i++) {
            easting = easting * 10 + digits[i];
            northing = northing * 10 + digits[i + 5];
        }
        var band = letter(MgrsParse.BANDS, bandIdx);
        var sq1 = letter(MgrsParse.colLetters(zone), colIdx);
        var sq2 = letter(MgrsParse.ROWS, rowIdx);
        var ll = MgrsParse.latLonFrom(zone, band, sq1, sq2, easting, northing);
        if (ll == null) {
            // Square letter that never occurs in this band.
            flashText = "Invalid grid";
            WatchUi.requestUpdate();
            return;
        }
        var mgrs = zone.format("%d") + band + " " + sq1 + sq2 + " "
            + easting.format("%05d") + " " + northing.format("%05d");
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        mainView.addManualWaypoint(mgrs, ll[0], ll[1]);
    }

    function letter(s, i) {
        return s.substring(i, i + 1);
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 8, Graphics.FONT_XTINY, "ENTER GRID",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var band = letter(MgrsParse.BANDS, bandIdx);
        var sq1 = letter(MgrsParse.colLetters(zone), colIdx);
        var sq2 = letter(MgrsParse.ROWS, rowIdx);

        // Each segment is [text, fieldIndex]; -1 = decoration.
        var line1 = [
            [zone.format("%d"), 0], [band, 1], [" ", -1], [sq1, 2], [sq2, 3]
        ];
        var line2 = [];
        for (var i = 0; i < 10; i++) {
            if (i == 5) {
                line2.add([" ", -1]);
            }
            line2.add([digits[i].format("%d"), i + 4]);
        }
        drawSegments(dc, cx, (h * 33) / 100, Graphics.FONT_MEDIUM, line1);
        drawSegments(dc, cx, (h * 50) / 100, Graphics.FONT_MEDIUM, line2);

        var footer;
        if (flashText != null) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            footer = flashText;
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            footer = "UP/DN: change  START: next";
        }
        dc.drawText(cx, (h * 70) / 100, Graphics.FONT_XTINY, footer,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 82) / 100, Graphics.FONT_XTINY, "MENU: save",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Draw text segments centered on cx, the active field in yellow.
    function drawSegments(dc, cx, y, font, segments) {
        var total = 0;
        for (var i = 0; i < segments.size(); i++) {
            total += dc.getTextWidthInPixels(segments[i][0], font);
        }
        var x = cx - total / 2;
        for (var i = 0; i < segments.size(); i++) {
            var seg = segments[i];
            if (seg[1] == field) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawText(x, y, font, seg[0],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            x += dc.getTextWidthInPixels(seg[0], font);
        }
    }
}

class MgrsEntryDelegate extends WatchUi.BehaviorDelegate {

    var view;

    function initialize(entryView) {
        BehaviorDelegate.initialize();
        view = entryView;
    }

    function onPreviousPage() { // UP
        view.adjust(1);
        return true;
    }

    function onNextPage() { // DOWN
        view.adjust(-1);
        return true;
    }

    function onSelect() { // START
        view.nextField();
        return true;
    }

    function onMenu() { // hold UP
        view.accept();
        return true;
    }

    function onBack() {
        view.prevField();
        return true;
    }
}
