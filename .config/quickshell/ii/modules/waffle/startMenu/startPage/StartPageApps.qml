pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

BodyRectangle {
    id: root

    ColumnLayout {
        anchors {
            fill: parent
            leftMargin: 32
            rightMargin: 32
            topMargin: 25
            bottomMargin: 30
        }
        spacing: 26

        AllApps {
            Layout.fillHeight: true
        }
    }

    component AllApps: PageSection {
        title: "All apps"
        Layout.fillHeight: true

        AppListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    component PageSection: ColumnLayout {
        id: pageSection
        required property string title
        default property alias pageData: pageSectionContentArea.data

        spacing: 16

        WText {
            Layout.leftMargin: 32
            text: pageSection.title
            font.pixelSize: Looks.font.pixelSize.large
            font.weight: Looks.font.weight.stronger
        }

        ColumnLayout {
            id: pageSectionContentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
