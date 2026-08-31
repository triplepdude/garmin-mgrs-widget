import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Formatting helpers shared by the glance and the main view.
(:glance)
module MgrsFormat {

    // Convert a Position.Location to an MGRS string using the built-in
    // Garmin formatter (WGS84 datum, 1 m precision).
    function fromLocation(location) {
        if (location == null) {
            return null;
        }
        var s = null;
        try {
            s = location.toGeoString(Position.GEO_MGRS);
        } catch (ex) {
            // Polar regions (outside MGRS coverage) or invalid fixes.
            s = null;
        }
        return s;
    }

    // Split "32T MK 12345 67890" into two display lines:
    // ["32T MK", "12345 67890"]. Falls back to a single line.
    function toLines(mgrs) {
        if (mgrs == null) {
            return ["- - -", ""];
        }
        var parts = split(mgrs, " ");
        if (parts.size() >= 4) {
            return [parts[0] + " " + parts[1], parts[2] + " " + parts[3]];
        }
        return [mgrs, ""];
    }

    function split(s, sep) {
        var result = [];
        var str = s;
        var idx = str.find(sep);
        while (idx != null) {
            var tok = str.substring(0, idx);
            if (tok.length() > 0) {
                result.add(tok);
            }
            str = str.substring(idx + 1, str.length());
            idx = str.find(sep);
        }
        if (str.length() > 0) {
            result.add(str);
        }
        return result;
    }

    function timestampString(ts) {
        if (ts == null) {
            return "";
        }
        var g = Gregorian.info(new Time.Moment(ts), Time.FORMAT_SHORT);
        return Lang.format("$1$-$2$-$3$ $4$:$5$", [
            g.year,
            g.month.format("%02d"),
            g.day.format("%02d"),
            g.hour.format("%02d"),
            g.min.format("%02d")
        ]);
    }

    function latLonString(lat, lon) {
        if (lat == null || lon == null) {
            return "";
        }
        return lat.format("%.5f") + ", " + lon.format("%.5f");
    }
}
