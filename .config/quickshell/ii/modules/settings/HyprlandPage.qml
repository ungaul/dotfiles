import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ContentPage {
    id: root
    forceWidth: true

    property string hyprPath:      FileUtils.trimFileProtocol(`${Directories.config}/hypr`)
    property string variablesPath: hyprPath + "/hyprland/variables.lua"
    property string execsPath:     hyprPath + "/hyprland/execs.lua"

    property bool variablesFound: false
    property bool execsFound:     false

    ListModel { id: appVarsModel }
    ListModel { id: execsModel }
    ListModel { id: envVarsModel }

    Process {
        id: checkVariables
        running: false
        property string buf: ""
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { checkVariables.buf += data + "\n" } }
        onExited: (code) => {
            if (code === 0 && checkVariables.buf.trim() === "1") {
                root.variablesFound = true
                catVariables.command = ["bash", "-c", "cat '" + root.variablesPath + "'"]
                catVariables.running = true
            }
            checkVariables.buf = ""
        }
    }

    Process {
        id: checkExecs
        running: false
        property string buf: ""
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { checkExecs.buf += data + "\n" } }
        onExited: (code) => {
            if (code === 0 && checkExecs.buf.trim() === "1") {
                root.execsFound = true
                catExecs.command = ["bash", "-c", "cat '" + root.execsPath + "'"]
                catExecs.running = true
            }
            checkExecs.buf = ""
        }
    }

    Process {
        id: catVariables
        running: false
        property string buf: ""
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { catVariables.buf += data + "\n" } }
        onExited: (code) => { if (code === 0) root.parseVariables(catVariables.buf); catVariables.buf = "" }
    }

    Process {
        id: catExecs
        running: false
        property string buf: ""
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { catExecs.buf += data + "\n" } }
        onExited: (code) => { if (code === 0) root.parseExecs(catExecs.buf); catExecs.buf = "" }
    }

    function writeFile(path, content) {
        let b64 = btoa(unescape(encodeURIComponent(content)))
        Quickshell.execDetached(["python3", "-c",
            "import base64; open('" + path + "','w').write(base64.b64decode('" + b64 + "').decode())"])
    }

    function loadAll() {
        appVarsModel.clear(); envVarsModel.clear(); execsModel.clear()
        root.variablesFound = false; root.execsFound = false
        checkVariables.command = ["bash", "-c", "[ -f '" + root.variablesPath + "' ] && echo 1 || echo 0"]
        checkVariables.running = true
        checkExecs.command = ["bash", "-c", "[ -f '" + root.execsPath + "' ] && echo 1 || echo 0"]
        checkExecs.running = true
    }

    function parseVariables(content) {
        appVarsModel.clear(); envVarsModel.clear()
        const appDefs = [
            { name: "terminal",    label: "Terminal",     icon: "terminal"    },
            { name: "browser",     label: "Browser",      icon: "public"      },
            { name: "fileManager", label: "File manager", icon: "folder_open" },
            { name: "codeEditor",  label: "Code editor",  icon: "code"        },
            { name: "textEditor",  label: "Text editor",  icon: "edit_note"   },
            { name: "volumeMixer", label: "Volume mixer", icon: "volume_up"   },
            { name: "settingsApp", label: "Settings app", icon: "settings"    },
            { name: "taskManager", label: "Task manager", icon: "task"        },
        ]
        for (let def of appDefs) {
            let m = content.match(new RegExp(`^${def.name}\\s*=\\s*"([^"]*)"`, 'm'))
            appVarsModel.append({ varName: def.name, label: def.label, varIcon: def.icon, value: m ? m[1] : "" })
        }
        const envRe = /hl\.env\("([^"]+)",\s*"([^"]*)"\)/g
        let em
        while ((em = envRe.exec(content)) !== null)
            envVarsModel.append({ envKey: em[1], envValue: em[2] })
    }

    function parseExecs(content) {
        execsModel.clear()
        const re = /^(\s+)(--\s*)?hl\.exec_cmd\("([^"]+)"\)/gm
        let m
        while ((m = re.exec(content)) !== null)
            execsModel.append({ execCmd: m[3], execEnabled: !m[2] })
    }

    function buildExecsFile() {
        let lines = ['hl.on("hyprland.start", function ()']
        for (let i = 0; i < execsModel.count; i++) {
            let item = execsModel.get(i)
            lines.push((item.execEnabled ? "    " : "    -- ") + 'hl.exec_cmd("' + item.execCmd + '")')
        }
        lines.push("end)")
        return lines.join("\n") + "\n"
    }

    function saveExecs() { writeFile(root.execsPath, buildExecsFile()) }

    function addExec(cmd) {
        if (!cmd.trim()) return
        execsModel.append({ execCmd: cmd.trim(), execEnabled: true })
        saveExecs()
    }

    function deleteExec(index) { execsModel.remove(index); saveExecs() }

    function toggleExec(index) {
        execsModel.setProperty(index, "execEnabled", !execsModel.get(index).execEnabled)
        saveExecs()
    }

    function saveVariable(varName, value) {
        Quickshell.execDetached(["bash", "-c",
            `sed -i 's|^${varName} = ".*"|${varName} = "${value}"|' '${root.variablesPath}'`])
    }

    function saveEnvVar(key, value) {
        Quickshell.execDetached(["bash", "-c",
            `sed -i 's|hl\\.env("${key}", ".*")|hl.env("${key}", "${value}")|' '${root.variablesPath}'`])
    }

    // ── Keybind section helpers ────────────────────────────────────────────
    property string keybindSearch: ""

    property var keybindKeySubstitutions: ({
        "Super":      "",
        "Return":     "Enter",
        "BackSpace":  "⌫",
        "Escape":     "Esc",
        "Space":      "Space",
        "Tab":        "Tab",
        "Slash":      "/",
        "Hash":       "#",
        "Period":     ".",
        "Equal":      "=",
        "Minus":      "-",
        "mouse_up":   "Scroll↑",
        "mouse_down": "Scroll↓",
        "mouse:272":  "LMB",
        "mouse:273":  "RMB",
        "mouse:275":  "MouseBack",
    })

    function resolveKeyLabel(k) {
        return keybindKeySubstitutions[k] || k
    }

    function keybindChips(mods, key) {
        var chips = mods.map(m => resolveKeyLabel(m))
        var blacklist = ["Super_L", "Super_R"]
        if (key && blacklist.indexOf(key) === -1)
            chips.push(resolveKeyLabel(key))
        return chips
    }

    function allKeybindSections() {
        var result = []
        var tree = HyprlandKeybinds.keybinds
        if (!tree || !tree.children) return result
        for (var i = 0; i < tree.children.length; i++) {
            var col = tree.children[i]
            if (!col || !col.children) continue
            for (var j = 0; j < col.children.length; j++)
                result.push(col.children[j])
        }
        return result
    }

    function filteredKeybindSections() {
        var q = keybindSearch.toLowerCase().trim()
        var sections = allKeybindSections()
        if (!q) return sections
        return sections.map(s => ({
            name: s.name,
            keybinds: (s.keybinds || []).filter(b =>
                (b.comment || "").toLowerCase().includes(q) ||
                (b.key    || "").toLowerCase().includes(q) ||
                (b.mods   || []).some(m => m.toLowerCase().includes(q))
            )
        })).filter(s => s.keybinds.length > 0)
    }

    Component.onCompleted: loadAll()

    // ── Default applications ───────────────────────────────────────────────
    ContentSection {
        icon: "apps"
        title: "Default applications"

        RowLayout {
            Layout.fillWidth: true
            visible: !root.variablesFound
            spacing: 6
            MaterialSymbol { text: "info"; iconSize: 16; color: Appearance.colors.colSubtext }
            StyledText {
                Layout.fillWidth: true
                text: "Config not found: " + root.variablesPath
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.Wrap
            }
        }

        Repeater {
            model: appVarsModel
            delegate: RowLayout {
                id: appDel
                required property int    index
                required property string varName
                required property string label
                required property string varIcon
                required property string value
                Layout.fillWidth: true
                spacing: 8
                MaterialSymbol { iconSize: 18; text: appDel.varIcon; color: Appearance.colors.colSubtext }
                StyledText { text: appDel.label; color: Appearance.colors.colOnLayer1; Layout.minimumWidth: 120 }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: "command…"
                    text: appDel.value
                    wrapMode: TextEdit.NoWrap
                    property string lastSaved: appDel.value
                    onActiveFocusChanged: {
                        if (!activeFocus && text !== lastSaved) {
                            root.saveVariable(appDel.varName, text)
                            lastSaved = text
                        }
                    }
                }
            }
        }
    }

    // ── Startup commands ───────────────────────────────────────────────────
    ContentSection {
        icon: "play_circle"
        title: "Startup commands"

        StyledText {
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
            text: "Changes apply on next Hyprland login"
        }

        RowLayout {
            Layout.fillWidth: true
            visible: !root.execsFound
            spacing: 6
            MaterialSymbol { text: "info"; iconSize: 16; color: Appearance.colors.colSubtext }
            StyledText {
                Layout.fillWidth: true
                text: "Config not found: " + root.execsPath
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.Wrap
            }
        }

        Repeater {
            model: execsModel
            delegate: RowLayout {
                id: execDel
                required property int    index
                required property string execCmd
                required property bool   execEnabled
                Layout.fillWidth: true
                spacing: 6
                property bool initialized: false
                Component.onCompleted: initialized = true
                StyledSwitch {
                    checked: execDel.execEnabled
                    onCheckedChanged: {
                        if (execDel.initialized && checked !== execDel.execEnabled)
                            root.toggleExec(execDel.index)
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    text: execDel.execCmd
                    elide: Text.ElideRight
                    color: execDel.execEnabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.monospace
                }
                RippleButton {
                    implicitWidth: 30; implicitHeight: 30
                    buttonRadius: Appearance.rounding.full
                    onClicked: root.deleteExec(execDel.index)
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "delete"; iconSize: 16; color: Appearance.colors.colSubtext
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.execsFound
            spacing: 8
            MaterialTextArea {
                id: newExecField
                Layout.fillWidth: true
                placeholderText: "New startup command…"
                wrapMode: TextEdit.NoWrap
                Keys.onReturnPressed: { root.addExec(text); text = "" }
            }
            RippleButtonWithIcon {
                materialIcon: "add"; mainText: "Add"
                buttonRadius: Appearance.rounding.full
                onClicked: { root.addExec(newExecField.text); newExecField.text = "" }
            }
        }
    }

    // ── Environment variables ──────────────────────────────────────────────
    ContentSection {
        icon: "code"
        title: "Environment variables"

        StyledText {
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
            text: "Changes apply on next Hyprland login"
        }

        RowLayout {
            Layout.fillWidth: true
            visible: !root.variablesFound
            spacing: 6
            MaterialSymbol { text: "info"; iconSize: 16; color: Appearance.colors.colSubtext }
            StyledText {
                Layout.fillWidth: true
                text: "Config not found: " + root.variablesPath
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.Wrap
            }
        }

        Repeater {
            model: envVarsModel
            delegate: RowLayout {
                id: envDel
                required property int    index
                required property string envKey
                required property string envValue
                Layout.fillWidth: true
                spacing: 8
                StyledText {
                    text: envDel.envKey
                    color: Appearance.colors.colPrimary
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.minimumWidth: 230
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    text: envDel.envValue
                    placeholderText: "value"
                    wrapMode: TextEdit.NoWrap
                    property string lastSaved: envDel.envValue
                    onActiveFocusChanged: {
                        if (!activeFocus && text !== lastSaved) {
                            root.saveEnvVar(envDel.envKey, text)
                            lastSaved = text
                        }
                    }
                }
            }
        }
    }

    // ── Keybindings ───────────────────────────────────────────────────────
    Item { implicitHeight: 8 }
    ContentSection {
        icon: "keyboard"
        title: "Keybindings"

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: "Search keybindings…"
            wrapMode: TextEdit.NoWrap
            onTextChanged: root.keybindSearch = text
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: Math.min(keybindCol.implicitHeight, 440)
            clip: true

            StyledFlickable {
                anchors.fill: parent
                contentHeight: keybindCol.implicitHeight

                Column {
                    id: keybindCol
                    width: parent.width
                    spacing: 14

                    Repeater {
                        id: keybindSectionRepeater
                        model: root.filteredKeybindSections()

                        delegate: Column {
                            id: keybindSectionDelegate
                            required property var modelData
                            required property int index
                            width: keybindCol.width
                            spacing: 2

                            // Divider between sections (not before the first)
                            Rectangle {
                                visible: keybindSectionDelegate.index > 0
                                width: parent.width
                                height: 1
                                color: Appearance.colors.colLayer1
                                opacity: 0.5
                            }

                            // Category name
                            StyledText {
                                topPadding: keybindSectionDelegate.index > 0 ? 4 : 0
                                text: keybindSectionDelegate.modelData.name || "General"
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: Appearance.colors.colPrimary
                                bottomPadding: 4
                            }

                            // Bind rows
                            Repeater {
                                model: keybindSectionDelegate.modelData.keybinds || []
                                delegate: RowLayout {
                                    id: bindRow
                                    required property var modelData
                                    width: keybindCol.width
                                    spacing: 8

                                    // Key chips
                                    Row {
                                        spacing: 3
                                        Layout.minimumWidth: 180
                                        Repeater {
                                            model: root.keybindChips(bindRow.modelData.mods || [], bindRow.modelData.key || "")
                                            delegate: Row {
                                                required property var modelData
                                                required property int index
                                                spacing: 2
                                                StyledText {
                                                    visible: index > 0
                                                    text: "+"
                                                    color: Appearance.colors.colSubtext
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                                KeyboardKey {
                                                    key: modelData
                                                    pixelSize: Appearance.font.pixelSize.smaller
                                                }
                                            }
                                        }
                                    }

                                    // Description
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: bindRow.modelData.comment || ""
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    // Empty state
                    StyledText {
                        width: keybindCol.width
                        visible: keybindSectionRepeater.count === 0
                        text: root.keybindSearch.length > 0 ? ('No keybindings match "' + root.keybindSearch + '"') : "No keybindings found.\nMake sure Hyprland is running."
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 20
                        bottomPadding: 20
                    }
                }
            }
        }
    }

    // ── Monitors ──────────────────────────────────────────────────────────
    ContentSection {
        icon: "monitor"
        title: "Monitors"

        Repeater {
            model: HyprlandData.monitors
            delegate: ColumnLayout {
                id: monitorDelegate
                required property var modelData
                Layout.fillWidth: true
                spacing: 4

                // Header row: name + focused badge
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialSymbol {
                        text: monitorDelegate.modelData.focused ? "tv" : "monitor"
                        iconSize: 18
                        color: monitorDelegate.modelData.focused
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: monitorDelegate.modelData.name
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: monitorDelegate.modelData.focused
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        visible: monitorDelegate.modelData.focused
                        text: "active"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colPrimary
                        opacity: 0.7
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: monitorDelegate.modelData.dpmsStatus ? "on" : "off (DPMS)"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: monitorDelegate.modelData.dpmsStatus
                            ? Appearance.colors.colSubtext
                            : Appearance.colors.colError
                    }
                }

                // Description line
                StyledText {
                    visible: (monitorDelegate.modelData.description || "").length > 0
                    Layout.fillWidth: true
                    Layout.leftMargin: 26
                    text: monitorDelegate.modelData.description || ""
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }

                // Stats grid
                GridLayout {
                    Layout.leftMargin: 26
                    columns: 4
                    columnSpacing: 20
                    rowSpacing: 2

                    // Resolution
                    StyledText {
                        text: "Resolution"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: monitorDelegate.modelData.width + "×" + monitorDelegate.modelData.height
                              + " @ " + monitorDelegate.modelData.refreshRate.toFixed(2) + " Hz"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer1
                        font.family: Appearance.font.family.monospace
                    }

                    // Position
                    StyledText {
                        text: "Position"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: monitorDelegate.modelData.x + ", " + monitorDelegate.modelData.y
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer1
                        font.family: Appearance.font.family.monospace
                    }

                    // Scale
                    StyledText {
                        text: "Scale"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: monitorDelegate.modelData.scale.toFixed(2) + "×"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer1
                        font.family: Appearance.font.family.monospace
                    }

                    // Workspace
                    StyledText {
                        text: "Workspace"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: (monitorDelegate.modelData.activeWorkspace?.name || "none")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer1
                        font.family: Appearance.font.family.monospace
                    }
                }

                // Divider between monitors
                Rectangle {
                    visible: monitorDelegate.index < HyprlandData.monitors.length - 1
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    height: 1
                    color: Appearance.colors.colLayer1
                    opacity: 0.5
                }
            }
        }
    }

    // ── Reload button ──────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        RippleButtonWithIcon {
            materialIcon: "restart_alt"
            mainText: "Reload Hyprland config"
            buttonRadius: Appearance.rounding.full
            onClicked: Quickshell.execDetached(["hyprctl", "reload"])
            StyledToolTip { text: "Applies changes to variables and general config." }
        }
    }
}
