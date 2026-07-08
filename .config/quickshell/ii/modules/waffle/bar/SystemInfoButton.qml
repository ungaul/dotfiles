import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

// Windows 11-style combined corner widget: weather + a glance at resource
// usage in one pill, replacing the old plain "open resource monitor" icon
// button. Clicking opens the same resource monitor popup (now with weather
// at the top); right-clicking refreshes the weather, like WeatherBar in ii.
BarButton {
    id: root

    leftInset: 2
    rightInset: 2
    checked: GlobalStates.resourceMonitorOpen

    onClicked: {
        GlobalStates.resourceMonitorOpen = !GlobalStates.resourceMonitorOpen
    }

    altAction: () => {
        Weather.getData()
    }

    onDownChanged: {
        scaleAnim.duration = root.down ? 150 : 200
        scaleAnim.easing.bezierCurve = root.down ? Looks.transition.easing.bezierCurve.easeIn : Looks.transition.easing.bezierCurve.easeOut
        contentRow.scale = root.down ? 5 / 6 : 1
    }

    contentItem: Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        Behavior on scale {
            NumberAnimation {
                id: scaleAnim
                easing.type: Easing.BezierSpline
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                fill: 0
                text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                iconSize: Looks.font.pixelSize.large
                color: Looks.colors.fg
            }

            WText {
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.data?.temp ?? "--°"
                font.pixelSize: Looks.font.pixelSize.normal
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 14
            color: Looks.colors.bgPanelSeparator
        }

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 0
            text: "speed"
            iconSize: Looks.font.pixelSize.large
            color: Looks.colors.fg
        }
    }

    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip
        text: "Weather & resource monitor"
    }
}
