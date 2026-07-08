pragma Singleton
import QtQuick
import Quickshell

// Master list of every toggle type ActionCenterTogglesDelegateChooser knows how
// to render. Used by the action center's edit mode to let the user pick which
// ones show up (and in what order) without having to know the raw config ids.
Singleton {
    id: root

    readonly property list<var> all: [
        { id: "network", name: "Wi-Fi", icon: "wifi-3" },
        { id: "bluetooth", name: "Bluetooth", icon: "bluetooth" },
        { id: "vpn", name: "VPN", icon: "wifi-lock" },
        { id: "powerProfile", name: "Power mode", icon: "flash-on" },
        { id: "idleInhibitor", name: "Keep awake", icon: "drink-coffee" },
        { id: "nightLight", name: "Night light", icon: "weather-moon" },
        { id: "darkMode", name: "Dark mode", icon: "dark-theme" },
        { id: "mic", name: "Microphone", icon: "mic" },
        { id: "musicRecognition", name: "Music recognition", icon: "music-note-2" },
        { id: "notifications", name: "Notifications", icon: "alert" },
        { id: "onScreenKeyboard", name: "On-screen keyboard", icon: "keyboard" },
        { id: "gameMode", name: "Game mode", icon: "games" },
        { id: "screenSnip", name: "Screen snip", icon: "cut" },
        { id: "colorPicker", name: "Color picker", icon: "eyedropper" },
        { id: "docker", name: "Docker", icon: "server" },
    ]

    function nameFor(id) {
        const entry = all.find(t => t.id === id);
        return entry ? entry.name : id;
    }

    function iconFor(id) {
        const entry = all.find(t => t.id === id);
        return entry ? entry.icon : "question";
    }
}
