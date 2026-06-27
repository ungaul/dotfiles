import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    property bool auto: Config.options.light.night.automatic

    name: "Night Light"
    statusText: (auto ? "Auto, " : "") + (toggled ? "Active" : "Inactive")

    toggled: Hyprsunset.temperatureActive
    icon: auto ? "night_sight_auto" : "bedtime"
    
    mainAction: () => {
        Hyprsunset.toggleTemperature()
    }
    hasMenu: true

    Component.onCompleted: {
        Hyprsunset.fetchState()
    }
    
    tooltipText: "Night Light | Right-click to configure"
}
