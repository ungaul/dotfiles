import QtQuick
import qs.services

QuickToggleModel {
    id: root
    name: "Docker"
    icon: "deployed_code"
    hasMenu: true
    hasStatusText: true

    toggled: Docker.available && Docker.runningCount > 0
    statusText: !Docker.available ? "N/A"
              : Docker.runningCount > 0 ? "%1 running".arg(Docker.runningCount)
              : "Stopped"
    tooltipText: "Docker | Click to manage"

    mainAction: () => Docker.refresh()
}
