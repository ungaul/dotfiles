pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

WBarAttachedPanelContent {
    id: root

    readonly property bool barAtBottom: Config.options.waffles.bar.bottom

    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    contentItem: WPane {
        contentItem: ColumnLayout {
            implicitWidth: 560
            spacing: 16

            RowLayout {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 14
                Layout.bottomMargin: 6
                spacing: 10

                MaterialSymbol {
                    fill: 0
                    text: "speed"
                    iconSize: 24
                    color: Looks.colors.fg
                }

                WText {
                    text: "System"
                    font {
                        weight: Looks.font.weight.stronger
                        pixelSize: Looks.font.pixelSize.xlarger
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                MaterialSymbol {
                    fill: 0
                    text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                    iconSize: 32
                    color: Looks.colors.fg
                }

                ColumnLayout {
                    spacing: 0
                    WText {
                        text: Weather.data?.temp ?? "--°"
                        font {
                            weight: Looks.font.weight.stronger
                            pixelSize: Looks.font.pixelSize.xlarger
                        }
                    }
                    WText {
                        text: Weather.data?.city ?? "Weather"
                        color: Looks.colors.subfg
                        font.pixelSize: Looks.font.pixelSize.normal
                    }
                }

                Item { Layout.fillWidth: true }

                WPanelIconButton {
                    iconName: "arrow-sync"
                    iconSize: 16
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: Weather.getData()
                }
            }

            WPanelSeparator {
                Layout.fillWidth: true
            }

            ResourceRow {
                Layout.fillWidth: true
                iconName: "planner_review"
                label: "CPU"
                value: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                percentage: ResourceUsage.cpuUsage
            }

            ResourceRow {
                Layout.fillWidth: true
                iconName: "memory"
                label: "Memory"
                value: `${root.formatKB(ResourceUsage.memoryUsed)} / ${root.formatKB(ResourceUsage.memoryTotal)}`
                percentage: ResourceUsage.memoryUsedPercentage
            }

            ResourceRow {
                Layout.fillWidth: true
                visible: ResourceUsage.swapTotal > 0
                iconName: "swap_horiz"
                label: "Swap"
                value: `${root.formatKB(ResourceUsage.swapUsed)} / ${root.formatKB(ResourceUsage.swapTotal)}`
                percentage: ResourceUsage.swapUsedPercentage
            }

            WPanelSeparator {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
            }

            NetRow {
                iconName: "arrow_downward"
                label: "Download"
                value: ResourceUsage.formatNetSpeed(ResourceUsage.netRxSpeed)
            }
            NetRow {
                iconName: "arrow_upward"
                label: "Upload"
                value: ResourceUsage.formatNetSpeed(ResourceUsage.netTxSpeed)
                Layout.bottomMargin: 16
            }
        }
    }

    component ResourceRow: ColumnLayout {
        id: resourceRow
        required property string label
        required property string value
        required property real percentage
        required property string iconName
        spacing: 8
        Layout.leftMargin: 20
        Layout.rightMargin: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            MaterialSymbol {
                fill: 0
                text: resourceRow.iconName
                iconSize: 18
                color: Looks.colors.fg
            }
            WText {
                text: resourceRow.label
                font.pixelSize: Looks.font.pixelSize.large
            }
            Item { Layout.fillWidth: true }
            WText {
                text: resourceRow.value
                font.pixelSize: Looks.font.pixelSize.normal
                color: Looks.colors.subfg
            }
        }
        WProgressBar {
            Layout.fillWidth: true
            implicitHeight: 12
            value: resourceRow.percentage
        }
    }

    component NetRow: RowLayout {
        id: netRow
        required property string label
        required property string value
        required property string iconName
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        spacing: 8

        MaterialSymbol {
            fill: 0
            text: netRow.iconName
            iconSize: 18
            color: Looks.colors.fg
        }
        WText {
            text: netRow.label
            font.pixelSize: Looks.font.pixelSize.normal
            color: Looks.colors.subfg
        }
        Item { Layout.fillWidth: true }
        WText {
            text: netRow.value
            font.pixelSize: Looks.font.pixelSize.normal
        }
    }
}
