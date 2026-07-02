pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    function isPinned(appId) {
        return Config.options.dock.pinnedApps.some(id => id.toLowerCase() === appId.toLowerCase());
    }

    function togglePin(appId) {
        if (root.isPinned(appId)) {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id.toLowerCase() !== appId.toLowerCase())
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appId])
        }
    }

    // Reorders the pinned apps list by moving draggedAppId to just before targetAppId.
    // Used for drag-and-drop reordering of the taskbar.
    function movePinnedBefore(draggedAppId, targetAppId) {
        if (draggedAppId.toLowerCase() === targetAppId.toLowerCase()) return;
        const pinned = Config.options.dock.pinnedApps.slice();
        const fromIndex = pinned.findIndex(id => id.toLowerCase() === draggedAppId.toLowerCase());
        if (fromIndex === -1) return;
        const original = pinned[fromIndex];
        pinned.splice(fromIndex, 1);
        let toIndex = pinned.findIndex(id => id.toLowerCase() === targetAppId.toLowerCase());
        if (toIndex === -1) toIndex = pinned.length;
        pinned.splice(toIndex, 0, original);
        Config.options.dock.pinnedApps = pinned;
    }

    // Persists TaskbarAppEntry instances across recomputes of `apps` below, keyed by
    // appId. Without this, every recompute (e.g. on any pinnedApps reorder) would
    // create brand-new QtObject identities for every entry, including unchanged ones.
    // That makes the ScriptModel/ListView backing the taskbar see what looks like an
    // entirely different dataset and destroy+recreate every delegate, which segfaults
    // if one of those delegates currently owns an active DragHandler (drag-to-reorder).
    property var _entryCache: ({})

    property list<var> apps: {
        var map = new Map();

        // Pinned apps
        const pinnedApps = Config.options?.dock.pinnedApps ?? [];
        for (const appId of pinnedApps) {
            if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                pinned: true,
                toplevels: []
            }));
        }

        // Separator
        if (pinnedApps.length > 0) {
            map.set("SEPARATOR", { pinned: false, toplevels: [] });
        }

        // Ignored apps
        const ignoredRegexStrings = Config.options?.dock.ignoredAppRegexes ?? [];
        const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));
        // Open windows
        for (const toplevel of ToplevelManager.toplevels.values) {
            if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
            if (!map.has(toplevel.appId.toLowerCase())) map.set(toplevel.appId.toLowerCase(), ({
                pinned: false,
                toplevels: []
            }));
            map.get(toplevel.appId.toLowerCase()).toplevels.push(toplevel);
        }

        var values = [];
        var nextCache = {};

        for (const [key, value] of map) {
            let entry = root._entryCache[key];
            if (entry) {
                entry.toplevels = value.toplevels;
                entry.pinned = value.pinned;
            } else {
                entry = appEntryComp.createObject(null, { appId: key, toplevels: value.toplevels, pinned: value.pinned });
            }
            nextCache[key] = entry;
            values.push(entry);
        }

        // Destroy entries for apps that disappeared (closed/unpinned) so they don't leak.
        // Mutated in place rather than reassigned: `root._entryCache = nextCache` would
        // change the property's identity and re-trigger this same `apps` binding (which
        // reads _entryCache above), causing a binding loop. In-place mutation keeps the
        // same object reference, so no change notification fires.
        for (const key in root._entryCache) {
            if (!(key in nextCache)) {
                root._entryCache[key].destroy();
                delete root._entryCache[key];
            }
        }
        for (const key in nextCache) {
            root._entryCache[key] = nextCache[key];
        }

        return values;
    }

    component TaskbarAppEntry: QtObject {
        id: wrapper
        required property string appId
        required property list<var> toplevels
        required property bool pinned
    }
    Component {
        id: appEntryComp
        TaskbarAppEntry {}
    }
}
