import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "volume_up"
        title: "Audio"

        ConfigSwitch {
            buttonIcon: "hearing"
            text: "Earbang protection"
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                Config.options.audio.protection.enable = checked;
            }
            StyledToolTip {
                text: "Prevents abrupt increments and restricts volume limit"
            }
        }
        ConfigRow {
            enabled: Config.options.audio.protection.enable
            ConfigSpinBox {
                icon: "arrow_warm_up"
                text: "Max allowed increase"
                value: Config.options.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowedIncrease = value;
                }
            }
            ConfigSpinBox {
                icon: "vertical_align_top"
                text: "Volume limit"
                value: Config.options.audio.protection.maxAllowed
                from: 0
                to: 154 // pavucontrol allows up to 153%
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowed = value;
                }
            }
        }
    }

    ContentSection {
        icon: "battery_android_full"
        title: "Battery"

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "warning"
                text: "Low warning"
                value: Config.options.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.low = value;
                }
            }
            ConfigSpinBox {
                icon: "dangerous"
                text: "Critical warning"
                value: Config.options.battery.critical
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.critical = value;
                }
            }
        }
        ConfigRow {
            uniform: false
            Layout.fillWidth: false
            ConfigSwitch {
                buttonIcon: "pause"
                text: "Automatic suspend"
                checked: Config.options.battery.automaticSuspend
                onCheckedChanged: {
                    Config.options.battery.automaticSuspend = checked;
                }
                StyledToolTip {
                    text: "Automatically suspends the system when battery is low"
                }
            }
            ConfigSpinBox {
                enabled: Config.options.battery.automaticSuspend
                text: "at"
                value: Config.options.battery.suspend
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.suspend = value;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "charger"
                text: "Full warning"
                value: Config.options.battery.full
                from: 0
                to: 101
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.full = value;
                }
            }
        }
    }

    ContentSection {
        icon: "notification_sound"
        title: "Sounds"
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "battery_android_full"
                text: "Battery"
                checked: Config.options.sounds.battery
                onCheckedChanged: {
                    Config.options.sounds.battery = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "av_timer"
                text: "Pomodoro"
                checked: Config.options.sounds.pomodoro
                onCheckedChanged: {
                    Config.options.sounds.pomodoro = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "nest_clock_farsight_analog"
        title: "Time"

        ConfigSwitch {
            buttonIcon: "pace"
            text: "Second precision"
            checked: Config.options.time.secondPrecision
            onCheckedChanged: {
                Config.options.time.secondPrecision = checked;
            }
            StyledToolTip {
                text: "Enable if you want clocks to show seconds accurately"
            }
        }

        ContentSubsection {
            title: "Format"
            tooltip: ""

            ConfigSelectionArray {
                currentValue: Config.options.time.format.replace(":ss", "")
                onSelected: newValue => {
                    if (newValue === "hh:mm") {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    } else {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    }

                    if (Config.options.time.format.includes(":ss")) {
                        newValue = newValue.replace(":mm", ":mm:ss");
                    }
                    Config.options.time.format = newValue;
                }
                options: [
                    {
                        displayName: "24h",
                        value: "hh:mm"
                    },
                    {
                        displayName: "12h am/pm",
                        value: "h:mm ap"
                    },
                    {
                        displayName: "12h AM/PM",
                        value: "h:mm AP"
                    },
                ]
            }

            ConfigSwitch {
                buttonIcon: "timer"
                text: "Display seconds"
                checked: Config.options.time.format.includes(":ss")
                onCheckedChanged: {
                    if (checked && !Config.options.time.format.includes(":ss")) {
                        Config.options.time.format = Config.options.time.format.replace(":mm", ":mm:ss");
                        Config.options.time.secondPrecision = true;
                    } else if (!checked && Config.options.time.format.includes(":ss")) {
                        Config.options.time.format = Config.options.time.format.replace(":ss", "");
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "brightness_auto"
        title: "Night light"

        ConfigSwitch {
            buttonIcon: "schedule"
            text: "Automatic (time-based)"
            checked: Config.options.light.night.automatic
            onCheckedChanged: { Config.options.light.night.automatic = checked }
        }

        ConfigRow {
            uniform: true
            ContentSubsection {
                title: "From"
                tooltip: "Format: HH:mm (24h)"
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: "19:00"
                    text: Config.options.light.night.from
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: { Config.options.light.night.from = text }
                }
            }
            ContentSubsection {
                title: "To"
                tooltip: "Format: HH:mm (24h)"
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: "06:30"
                    text: Config.options.light.night.to
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: { Config.options.light.night.to = text }
                }
            }
        }

        ConfigSpinBox {
            icon: "thermometer"
            text: "Color temperature (K)"
            value: Config.options.light.night.colorTemperature
            from: 1000; to: 6500; stepSize: 100
            onValueChanged: { Config.options.light.night.colorTemperature = value }
            StyledToolTip { text: "Lower = warmer/more orange. Default: 5000K" }
        }
    }

    ContentSection {
        icon: "open_in_new"
        title: "Windows"

        ConfigSwitch {
            buttonIcon: "web_asset"
            text: "Show titlebar in shell windows"
            checked: Config.options.windows.showTitlebar
            onCheckedChanged: { Config.options.windows.showTitlebar = checked }
        }
        ConfigSwitch {
            buttonIcon: "align_justify_center"
            text: "Center title"
            enabled: Config.options.windows.showTitlebar
            checked: Config.options.windows.centerTitle
            onCheckedChanged: { Config.options.windows.centerTitle = checked }
        }
    }

    ContentSection {
        icon: "view_agenda"
        title: "Waffle"

        ConfigSwitch {
            buttonIcon: "format_align_left"
            text: "Left-align taskbar items"
            checked: Config.options.waffles.bar.leftAlignApps
            onCheckedChanged: { Config.options.waffles.bar.leftAlignApps = checked }
            StyledToolTip {
                text: "When enabled, the Start button and open apps sit at the left of the Waffle taskbar instead of centered"
            }
        }
    }

    ContentSection {
        icon: "touch_app"
        title: "Interactions"

        ConfigSwitch {
            buttonIcon: "swipe"
            text: "Faster touchpad scroll"
            checked: Config.options.interactions.scrolling.fasterTouchpadScroll
            onCheckedChanged: { Config.options.interactions.scrolling.fasterTouchpadScroll = checked }
            StyledToolTip { text: "Increases scroll speed on touchpad for shell elements" }
        }
        ConfigSpinBox {
            icon: "scroll_selector_knob"
            text: "Touchpad scroll factor"
            value: Config.options.interactions.scrolling.touchpadScrollFactor
            from: 50; to: 2000; stepSize: 50
            onValueChanged: { Config.options.interactions.scrolling.touchpadScrollFactor = value }
        }
        ConfigSpinBox {
            icon: "mouse"
            text: "Mouse scroll factor"
            value: Config.options.interactions.scrolling.mouseScrollFactor
            from: 50; to: 2000; stepSize: 50
            onValueChanged: { Config.options.interactions.scrolling.mouseScrollFactor = value }
        }
    }

}
