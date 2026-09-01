import Toybox.Lang;
import Toybox.WatchUi;

class MgrsMainDelegate extends WatchUi.BehaviorDelegate {

    var view;

    function initialize(mainView) {
        BehaviorDelegate.initialize();
        view = mainView;
    }

    // START/SELECT: save the current position on the live page, or
    // re-send the shown waypoint to the native Saved Locations.
    function onSelect() {
        if (view.pageIndex == 0) {
            return view.saveCurrent();
        }
        return view.exportCurrentPage();
    }

    function onNextPage() {
        view.nextPage();
        return true;
    }

    function onPreviousPage() {
        view.prevPage();
        return true;
    }

    // MENU (hold UP): enter a grid manually on the live page, or
    // delete the saved waypoint on the current page.
    function onMenu() {
        var idx = view.storeIndexForPage();
        if (idx < 0) {
            var entry = new MgrsEntryView(view);
            WatchUi.pushView(entry, new MgrsEntryDelegate(entry),
                WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        var list = MgrsStore.load();
        if (idx >= list.size()) {
            return false;
        }
        var name = list[idx]["name"];
        var dialog = new WatchUi.Confirmation("Delete " + name + "?");
        WatchUi.pushView(dialog, new MgrsDeleteConfirmDelegate(view, idx),
            WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

class MgrsDeleteConfirmDelegate extends WatchUi.ConfirmationDelegate {

    var view;
    var storeIndex;

    function initialize(mainView, index) {
        ConfirmationDelegate.initialize();
        view = mainView;
        storeIndex = index;
    }

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            MgrsStore.removeAt(storeIndex);
            view.clampPage();
        }
        return true;
    }
}
