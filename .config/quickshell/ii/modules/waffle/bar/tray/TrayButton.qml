pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.bar

BarIconButton {
    id: root

    required property SystemTrayItem item
    property alias menuOpen: menu.visible
    readonly property bool barAtBottom: Config.options.waffles.bar.bottom
    iconSource: item.icon
    iconScale: 0
    Component.onCompleted: {
        root.iconScale = 1
    }
    Behavior on iconScale {
        animation: Looks.transition.enter.createObject(this)
    }

    onClicked: {
        item.activate();
    }

    altAction: () => {
        if (item.hasMenu) menu.active = true
    }

    // QsMenuOpener just exposes the tray item's menu entries — the actual UI is a
    // normal waffle-styled BarMenu, instead of QsMenuAnchor's native/Basic-style
    // popup (which ignores the system theme and always renders dark).
    // TODO: hasChildren (submenus) aren't supported yet — those entries just won't
    // do anything when clicked, same as cascading menus weren't handled before.
    QsMenuOpener {
        id: menuOpener
        menu: root.item.menu
    }

    BarMenu {
        id: menu
        anchorItem: root
        model: menuOpener.children.values
            .filter(entry => !entry.hasChildren)
            .map(entry => entry.isSeparator
                ? { type: "separator" }
                : {
                    text: entry.text,
                    iconName: entry.icon,
                    monochromeIcon: false,
                    action: () => entry.triggered()
                })
    }

    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip && !root.Drag.active
        text: TrayService.getTooltipForItem(root.item)
    }
}
