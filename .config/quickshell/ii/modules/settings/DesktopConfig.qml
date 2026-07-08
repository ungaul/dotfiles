import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "grid_view"
        title: "Desktop Icons"

        ConfigSwitch {
            buttonIcon: "check"
            text: "Enable"
            checked: Config.options.background.widgets.desktopIcons.enable
            onCheckedChanged: {
                Config.options.background.widgets.desktopIcons.enable = checked;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: `Folder path (default: ~/Desktop)`
            text: Config.options.background.widgets.desktopIcons.path
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.background.widgets.desktopIcons.path = text;
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 4
            wrapMode: Text.Wrap
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            text: "Shows every file and folder in that directory as draggable, grid-snapped icons on the wallpaper.\n\n" + "• Left-click selects an icon; clicking empty space clears the selection.\n" + "• Double-click opens it (folders open in Nautilus, files with their default app).\n" + "• Drag an icon to move it; its position is remembered.\n" + "• Right-click an icon for Open, Open With…, Rename, Copy Path, and Move to Trash.\n" + "• Right-click empty space for Open Terminal Here, New Folder, New File, and Refresh."
        }
    }

    ContentSection {
        icon: "photo_size_select_large"
        title: "Icon size"

        ConfigSpinBox {
            icon: "photo_size_select_large"
            text: "Icon size"
            value: Config.options.background.widgets.desktopIcons.iconSize
            from: 24
            to: 128
            stepSize: 4
            onValueChanged: {
                Config.options.background.widgets.desktopIcons.iconSize = value;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "width"
                text: "Cell width"
                value: Config.options.background.widgets.desktopIcons.gridCellWidth
                from: 60
                to: 200
                stepSize: 5
                onValueChanged: {
                    Config.options.background.widgets.desktopIcons.gridCellWidth = value;
                }
            }
            ConfigSpinBox {
                icon: "height"
                text: "Cell height"
                value: Config.options.background.widgets.desktopIcons.gridCellHeight
                from: 60
                to: 200
                stepSize: 5
                onValueChanged: {
                    Config.options.background.widgets.desktopIcons.gridCellHeight = value;
                }
            }
        }
    }

    ContentSection {
        icon: "space_dashboard"
        title: "Grid spacing"

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "swap_horiz"
                text: "Horizontal gap"
                value: Config.options.background.widgets.desktopIcons.gridSpacingX
                from: 0
                to: 120
                stepSize: 4
                onValueChanged: {
                    Config.options.background.widgets.desktopIcons.gridSpacingX = value;
                }
            }
            ConfigSpinBox {
                icon: "swap_vert"
                text: "Vertical gap"
                value: Config.options.background.widgets.desktopIcons.gridSpacingY
                from: 0
                to: 120
                stepSize: 4
                onValueChanged: {
                    Config.options.background.widgets.desktopIcons.gridSpacingY = value;
                }
            }
        }
    }
}
