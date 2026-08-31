import Toybox.Application;
import Toybox.Lang;

// Persistent storage for saved MGRS waypoints.
// Each entry is a Dictionary: { "name", "mgrs", "lat", "lon", "ts" }
(:glance)
module MgrsStore {

    const STORAGE_KEY = "savedMgrs";
    const COUNTER_KEY = "wptCounter";
    const MAX_ENTRIES = 50;

    function load() {
        var list = Application.Storage.getValue(STORAGE_KEY);
        if (list == null || !(list instanceof Lang.Array)) {
            return [];
        }
        return list;
    }

    function count() {
        return load().size();
    }

    // Most recently saved entry, or null.
    function latest() {
        var list = load();
        if (list.size() == 0) {
            return null;
        }
        return list[list.size() - 1];
    }

    function add(name, mgrs, lat, lon, ts) {
        var list = load();
        list.add({
            "name" => name,
            "mgrs" => mgrs,
            "lat" => lat,
            "lon" => lon,
            "ts" => ts
        });
        // Drop oldest entries beyond the cap so Storage stays small.
        while (list.size() > MAX_ENTRIES) {
            var trimmed = [];
            for (var i = 1; i < list.size(); i++) {
                trimmed.add(list[i]);
            }
            list = trimmed;
        }
        Application.Storage.setValue(STORAGE_KEY, list);
    }

    function removeAt(index) {
        var list = load();
        if (index < 0 || index >= list.size()) {
            return;
        }
        var out = [];
        for (var i = 0; i < list.size(); i++) {
            if (i != index) {
                out.add(list[i]);
            }
        }
        Application.Storage.setValue(STORAGE_KEY, out);
    }

    function nextName() {
        var n = Application.Storage.getValue(COUNTER_KEY);
        if (n == null || !(n instanceof Lang.Number)) {
            n = 0;
        }
        n = n + 1;
        Application.Storage.setValue(COUNTER_KEY, n);
        return "WPT " + n;
    }
}
