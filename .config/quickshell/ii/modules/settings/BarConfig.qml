import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "visibility"
        title: "Appearance"

        ConfigSwitch {
            buttonIcon: "calendar_today"
            text: "Show date"
            checked: Config.options.bar.verbose
            onCheckedChanged: { Config.options.bar.verbose = checked }
            StyledToolTip { text: "Show date next to the clock in the bar" }
        }
        ConfigSwitch {
            buttonIcon: "background_replace"
            text: "Show background"
            checked: Config.options.bar.showBackground
            onCheckedChanged: { Config.options.bar.showBackground = checked }
        }
        ConfigSwitch {
            buttonIcon: "shadow"
            text: "Shadow (Float style)"
            visible: Config.options.bar.cornerStyle === 1
            checked: Config.options.bar.floatStyleShadow
            onCheckedChanged: { Config.options.bar.floatStyleShadow = checked }
            StyledToolTip { text: "Only applies when bar corner style is set to Float" }
        }
    }

    ContentSection {
        icon: "memory"
        title: "Resources monitor"

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "developer_board"
                text: "Always show CPU"
                checked: Config.options.bar.resources.alwaysShowCpu
                onCheckedChanged: { Config.options.bar.resources.alwaysShowCpu = checked }
            }
            ConfigSwitch {
                buttonIcon: "swap_horiz"
                text: "Always show Swap"
                checked: Config.options.bar.resources.alwaysShowSwap
                onCheckedChanged: { Config.options.bar.resources.alwaysShowSwap = checked }
            }
        }

        ConfigSpinBox {
            icon: "developer_board"
            text: "CPU warning threshold (%)"
            value: Config.options.bar.resources.cpuWarningThreshold
            from: 10; to: 100; stepSize: 5
            onValueChanged: { Config.options.bar.resources.cpuWarningThreshold = value }
        }
        ConfigSpinBox {
            icon: "memory"
            text: "RAM warning threshold (%)"
            value: Config.options.bar.resources.memoryWarningThreshold
            from: 10; to: 100; stepSize: 5
            onValueChanged: { Config.options.bar.resources.memoryWarningThreshold = value }
        }
        ConfigSpinBox {
            icon: "swap_horiz"
            text: "Swap warning threshold (%)"
            value: Config.options.bar.resources.swapWarningThreshold
            from: 10; to: 100; stepSize: 5
            onValueChanged: { Config.options.bar.resources.swapWarningThreshold = value }
        }
    }

    ContentSection {
        icon: "notifications"
        title: "Notifications"
        ConfigSwitch {
            buttonIcon: "counter_2"
            text: "Unread indicator: show count"
            checked: Config.options.bar.indicators.notifications.showUnreadCount
            onCheckedChanged: {
                Config.options.bar.indicators.notifications.showUnreadCount = checked;
            }
        }
    }
    
    ContentSection {
        icon: "spoke"
        title: "Positioning"

        ConfigRow {
            ContentSubsection {
                title: "Bar position"
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: "Top",
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: "Left",
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: "Bottom",
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: "Right",
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: "Automatically hide"
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: "No",
                            icon: "close",
                            value: false
                        },
                        {
                            displayName: "Yes",
                            icon: "check",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {
            
            ContentSubsection {
                title: "Corner style"
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: "Hug",
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: "Float",
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: "Rect",
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: "Group style"
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => {
                        Config.options.bar.borderless = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: "Pills",
                            icon: "location_chip",
                            value: false
                        },
                        {
                            displayName: "Line-separated",
                            icon: "split_scene",
                            value: true
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "shelf_auto_hide"
        title: "Tray"

        ConfigSwitch {
            buttonIcon: "keep"
            text: 'Make icons pinned by default'
            checked: Config.options.tray.invertPinnedItems
            onCheckedChanged: {
                Config.options.tray.invertPinnedItems = checked;
            }
        }
        
        ConfigSwitch {
            buttonIcon: "colors"
            text: 'Tint icons'
            checked: Config.options.tray.monochromeIcons
            onCheckedChanged: {
                Config.options.tray.monochromeIcons = checked;
            }
        }
    }

    ContentSection {
        icon: "widgets"
        title: "Utility buttons"

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "content_cut"
                text: "Screen snip"
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenSnip = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: "Color picker"
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showColorPicker = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: "Keyboard toggle"
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showKeyboardToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: "Mic toggle"
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showMicToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: "Dark/Light toggle"
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showDarkModeToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "speed"
                text: "Performance Profile toggle"
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "videocam"
                text: "Record"
                checked: Config.options.bar.utilButtons.showScreenRecord
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenRecord = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "music_note"
        title: "Media"
        ConfigSwitch {
            buttonIcon: "text_fields"
            text: "Show track name"
            checked: Config.options.bar.media.showTrackName
            onCheckedChanged: {
                Config.options.bar.media.showTrackName = checked;
            }
            StyledToolTip { text: "When disabled, only the circular playback icon is shown" }
        }
    }

    ContentSection {
        icon: "cloud"
        title: "Weather"
        ConfigSwitch {
            buttonIcon: "check"
            text: "Enable"
            checked: Config.options.bar.weather.enable
            onCheckedChanged: {
                Config.options.bar.weather.enable = checked;
            }
        }
    }

    ContentSection {
        icon: "news"
        title: "Telop (news ticker)"
        ConfigSwitch {
            buttonIcon: "check"
            text: "Enable"
            checked: Config.options.bar.telop.enable
            onCheckedChanged: {
                Config.options.bar.telop.enable = checked;
            }
        }
    }

    ContentSection {
        icon: "workspaces"
        title: "Workspaces"

        ConfigSwitch {
            buttonIcon: "counter_1"
            text: 'Always show numbers'
            checked: Config.options.bar.workspaces.alwaysShowNumbers
            onCheckedChanged: {
                Config.options.bar.workspaces.alwaysShowNumbers = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "award_star"
            text: 'Show app icons'
            checked: Config.options.bar.workspaces.showAppIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.showAppIcons = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "colors"
            text: 'Tint app icons'
            checked: Config.options.bar.workspaces.monochromeIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.monochromeIcons = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "font_download"
            text: 'Use Nerd Font icons'
            checked: Config.options.bar.workspaces.useNerdFont
            onCheckedChanged: { Config.options.bar.workspaces.useNerdFont = checked }
            StyledToolTip { text: "Use Nerd Font glyphs for workspace indicators" }
        }

        ConfigSpinBox {
            icon: "view_column"
            text: "Workspaces shown"
            value: Config.options.bar.workspaces.shown
            from: 1
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.bar.workspaces.shown = value;
            }
        }

        ConfigSpinBox {
            icon: "touch_long"
            text: "Number show delay when pressing Super (ms)"
            value: Config.options.bar.workspaces.showNumberDelay
            from: 0
            to: 1000
            stepSize: 50
            onValueChanged: {
                Config.options.bar.workspaces.showNumberDelay = value;
            }
        }

        ContentSubsection {
            title: "Number style"

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                }
                options: [
                    {
                        displayName: "Normal",
                        icon: "timer_10",
                        value: '[]'
                    },
                    {
                        displayName: "Han chars",
                        icon: "square_dot",
                        value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
                    },
                    {
                        displayName: "Roman",
                        icon: "account_balance",
                        value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "tooltip"
        title: "Tooltips"
        ConfigSwitch {
            buttonIcon: "ads_click"
            text: "Click to show"
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
        }
    }
}
