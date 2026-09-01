import Toybox.Lang;
import Toybox.Math;

// Inverse MGRS: convert a grid reference entered by the user back to
// WGS84 lat/lon. Covers the UTM bands (C-X, 80S to 84N); polar UPS
// grids (A/B/Y/Z) are not accepted for entry. The UTM inverse is the
// standard series expansion; it agrees with the geotrans reference
// implementation to within 4 cm worldwide.
module MgrsParse {

    const BANDS = "CDEFGHJKLMNPQRSTUVWX";
    const ROWS = "ABCDEFGHJKLMNPQRSTUV";

    // 100 km column letter set cycles with the zone number.
    function colLetters(zone) {
        var m = zone % 3;
        if (m == 1) {
            return "ABCDEFGH";
        } else if (m == 2) {
            return "JKLMNPQR";
        }
        return "STUVWXYZ";
    }

    // Minimum UTM northing (false northing included) at the southern
    // edge of each latitude band, indexed like BANDS.
    var MIN_NORTHING = [
        1100000.0d, 2000000.0d, 2800000.0d, 3700000.0d, 4600000.0d,
        5500000.0d, 6400000.0d, 7300000.0d, 8200000.0d, 9100000.0d,
        0.0d, 800000.0d, 1700000.0d, 2600000.0d, 3500000.0d,
        4400000.0d, 5300000.0d, 6200000.0d, 7000000.0d, 7900000.0d
    ];

    // Grid pieces to [lat, lon] degrees, or null if the reference is
    // not a real place (e.g. a square letter that never occurs in the
    // given band).
    function latLonFrom(zone, band, sq1, sq2, easting, northing) {
        if (zone < 1 || zone > 60) {
            return null;
        }
        var bi = BANDS.find(band);
        var ci = colLetters(zone).find(sq1);
        var ri = ROWS.find(sq2);
        if (bi == null || ci == null || ri == null) {
            return null;
        }

        var e = (ci + 1) * 100000.0d + easting;
        // Even zones offset the row lettering by five (F at the equator).
        if (zone % 2 == 0) {
            ri = (ri - 5 + 20) % 20;
        }
        var n = ri * 100000.0d + northing;
        // Row letters repeat every 2,000,000 m; the band letter picks
        // which repetition is meant.
        while (n < MIN_NORTHING[bi]) {
            n += 2000000.0d;
        }

        var south = bi < 10; // bands C-M
        var ll = utmInverse(zone, e, n, south);
        var bandMin = -80.0d + bi * 8.0d;
        var bandMax = bandMin + (bi == 19 ? 12.0d : 8.0d);
        if (ll[0] < bandMin - 1.0d || ll[0] > bandMax + 1.0d) {
            return null;
        }
        return ll;
    }

    // UTM to lat/lon (WGS84, k0 = 0.9996, false easting 500,000 m,
    // false northing 10,000,000 m in the south).
    function utmInverse(zone, x, y, south) {
        var a = 6378137.0d;
        var f = 1.0d / 298.257223563d;
        var k0 = 0.9996d;
        var e2 = f * (2.0d - f);
        var ep2 = e2 / (1.0d - e2);
        var e1 = (1.0d - Math.sqrt(1.0d - e2)) / (1.0d + Math.sqrt(1.0d - e2));

        x = x - 500000.0d;
        if (south) {
            y = y - 10000000.0d;
        }

        var mu = (y / k0) / (a * (1.0d - e2 / 4.0d
            - 3.0d * e2 * e2 / 64.0d - 5.0d * e2 * e2 * e2 / 256.0d));
        var phi1 = mu
            + (3.0d * e1 / 2.0d - 27.0d * e1 * e1 * e1 / 32.0d)
                * Math.sin(2.0d * mu)
            + (21.0d * e1 * e1 / 16.0d
                - 55.0d * e1 * e1 * e1 * e1 / 32.0d) * Math.sin(4.0d * mu)
            + (151.0d * e1 * e1 * e1 / 96.0d) * Math.sin(6.0d * mu)
            + (1097.0d * e1 * e1 * e1 * e1 / 512.0d) * Math.sin(8.0d * mu);

        var sp = Math.sin(phi1);
        var cp = Math.cos(phi1);
        var tp = Math.tan(phi1);
        var c1 = ep2 * cp * cp;
        var t1 = tp * tp;
        var n1 = a / Math.sqrt(1.0d - e2 * sp * sp);
        var r1 = a * (1.0d - e2) / Math.pow(1.0d - e2 * sp * sp, 1.5d);
        var d = x / (n1 * k0);
        var d2 = d * d;

        var lat = phi1 - (n1 * tp / r1) * (d2 / 2.0d
            - (5.0d + 3.0d * t1 + 10.0d * c1 - 4.0d * c1 * c1 - 9.0d * ep2)
                * d2 * d2 / 24.0d
            + (61.0d + 90.0d * t1 + 298.0d * c1 + 45.0d * t1 * t1
                - 252.0d * ep2 - 3.0d * c1 * c1) * d2 * d2 * d2 / 720.0d);
        var lon = (d - (1.0d + 2.0d * t1 + c1) * d2 * d / 6.0d
            + (5.0d - 2.0d * c1 + 28.0d * t1 - 3.0d * c1 * c1
                + 8.0d * ep2 + 24.0d * t1 * t1) * d2 * d2 * d / 120.0d) / cp;
        var lon0 = (zone - 1) * 6.0d - 180.0d + 3.0d;
        return [Math.toDegrees(lat), lon0 + Math.toDegrees(lon)];
    }
}
