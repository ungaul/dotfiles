import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.bar.tasks
import qs.modules.waffle.bar.tray

Rectangle {
    id: root

    color: Looks.colors.bg0
    implicitHeight: 48

    Rectangle {
        id: border
        anchors {
            left: parent.left
            right: parent.right
            top: Config.options.waffles.bar.bottom ? parent.top : undefined
            bottom: Config.options.waffles.bar.bottom ? undefined : parent.bottom
        }
        color: Looks.colors.bg0Border
        implicitHeight: 1
    }

    // When apps are centered, there's nothing balancing the bar on the left, so
    // the weather/perf widget lives there instead — same as it did before apps
    // could be left-aligned. Once apps move to the left, it relocates to the
    // right (systemRow, next to the keyboard layout button) so it doesn't end
    // up sitting awkwardly next to the Start button.
    BarGroupRow {
        id: bloatRow
        anchors.left: parent.left
        opacity: Config.options.waffles.bar.leftAlignApps ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            animation: Looks.transition.opacity.createObject(this)
        }

        SystemInfoButton {}
    }

    BarGroupRow {
        id: appsRow
        anchors.left: undefined
        anchors.horizontalCenter: parent.horizontalCenter

        states: State {
            name: "left"
            when: Config.options.waffles.bar.leftAlignApps
            AnchorChanges {
                target: appsRow
                anchors.left: parent.left
                anchors.horizontalCenter: undefined
            }
        }

        transitions: Transition {
            animations: Looks.transition.anchor.createObject(this)
        }

        StartButton {}
        Tasks {}
    }

    BarGroupRow {
        id: systemRow
        anchors.right: parent.right
        Tray {}
        UpdatesButton {}
        FadeLoader {
            Layout.fillHeight: true
            shown: Config.options.waffles.bar.leftAlignApps
            sourceComponent: SystemInfoButton {}
        }
        KeyboardLayoutButton {}
        SystemButton {}
        TimeButton {}
    }

    component BarGroupRow: RowLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0
    }
}
