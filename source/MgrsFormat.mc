import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Formatting helpers shared by the glance and the main view.
(:glance)
module MgrsFormat {

    // Convert a Position.Location to an MGRS string (WGS84, 1 m precision).
    // Inside UTM coverage (84N to 80S) the built-in Garmin formatter is
    // used. Poleward of that, MGRS is defined on the Universal Polar
    // Stereographic (UPS) grid: zones Y/Z (north) and A/B (south). Those
    // references are computed here and marked with a "(UPS)" suffix.
    function fromLocation(location) {
        if (location == null) {
            return null;
        }
        var deg = location.toDegrees();
        var lat = deg[0];
        var lon = deg[1];
        if (lat > 84.0 || lat < -80.0) {
            return polarMgrs(lat, lon);
        }
        var s = null;
        try {
            s = location.toGeoString(Position.GEO_MGRS);
        } catch (ex) {
            s = null;
        }
        return s;
    }

    // MGRS polar reference from a UPS (polar stereographic, WGS84,
    // k0 = 0.994, false easting/northing 2,000,000 m) projection.
    // Returns e.g. "Z AH 00000 00000 (UPS)"; null if out of range.
    function polarMgrs(lat, lon) {
        var north = lat > 0.0;

        var a = 6378137.0d;
        var f = 1.0d / 298.257223563d;
        var e2 = f * (2.0d - f);
        var e = Math.sqrt(e2);
        var k0 = 0.994d;

        var phi = Math.toRadians(north ? lat : -lat);
        var lam = Math.toRadians(lon);
        var sp = e * Math.sin(phi);
        var t = Math.tan(Math.PI / 4.0d - phi / 2.0d)
            / Math.pow((1.0d - sp) / (1.0d + sp), e / 2.0d);
        var c = 2.0d * a * k0
            / Math.sqrt(Math.pow(1.0d + e, 1.0d + e) * Math.pow(1.0d - e, 1.0d - e));
        var rho = c * t;

        var x = 2000000.0d + rho * Math.sin(lam);
        var y = north ? 2000000.0d - rho * Math.cos(lam)
                      : 2000000.0d + rho * Math.cos(lam);

        var eIdx = Math.floor(x / 100000.0d).toNumber();
        var nIdx = Math.floor(y / 100000.0d).toNumber();

        // 100 km square letters skip D, E, I, M, N, O, V, W in columns
        // and I, O in rows (DMA TM 8358.1 polar scheme).
        var gzd;
        var colLetters;
        var colBase;
        var rowLetters;
        var rowBase;
        if (north) {
            rowLetters = "ABCDEFGHJKLMNP";
            rowBase = 13;
            if (x < 2000000.0d) {
                gzd = "Y";
                colLetters = "RSTUXYZ";
                colBase = 13;
            } else {
                gzd = "Z";
                colLetters = "ABCFGHJ";
                colBase = 20;
            }
        } else {
            rowLetters = "ABCDEFGHJKLMNPQRSTUVWXYZ";
            rowBase = 8;
            if (x < 2000000.0d) {
                gzd = "A";
                colLetters = "JKLPQRSTUXYZ";
                colBase = 8;
            } else {
                gzd = "B";
                colLetters = "ABCFGHJKLPQR";
                colBase = 20;
            }
        }

        var ci = eIdx - colBase;
        var ri = nIdx - rowBase;
        if (ci < 0 || ci >= colLetters.length()
            || ri < 0 || ri >= rowLetters.length()) {
            return null;
        }

        var square = colLetters.substring(ci, ci + 1)
            + rowLetters.substring(ri, ri + 1);
        var em = (x - eIdx * 100000.0d).toNumber();
        var nm = (y - nIdx * 100000.0d).toNumber();
        return gzd + " " + square + " "
            + em.format("%05d") + " " + nm.format("%05d") + " (UPS)";
    }

    // Split "32T MK 12345 67890" into two display lines:
    // ["32T MK", "12345 67890"]. Polar references carry their "(UPS)"
    // marker on the first line: ["Z AH (UPS)", "00000 00000"].
    function toLines(mgrs) {
        if (mgrs == null) {
            return ["- - -", ""];
        }
        var parts = split(mgrs, " ");
        if (parts.size() >= 5) {
            return [parts[0] + " " + parts[1] + " " + parts[4],
                    parts[2] + " " + parts[3]];
        }
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
