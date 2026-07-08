import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

QuickToggleButton {
    id: root
    buttonIcon: "deployed_code"
    toggled: Docker.available && Docker.runningCount > 0

    StyledToolTip {
        text: !Docker.available
              ? "Docker non disponible"
              : Docker.runningCount > 0
                ? "%1 container(s) running · Click to manage".arg(Docker.runningCount)
                : "Docker · No running containers"
    }
}
