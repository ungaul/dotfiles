pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    // Misc props
    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    onSinkChanged: root.lastCycledProfileLabel = ""
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00 // People keep joking about setting volume to 5172% so...
    property string audioTheme: Config.options.sounds.theme
    property real value: sink?.audio.volume ?? 0
    
    function friendlyDeviceName(node) {
        return (node.nickname || node.description || "Unknown");
    }
    function appNodeDisplayName(node) {
        return (node.properties["application.name"] || node.description || node.name)
    }

    // Lists
    function correctType(node, isSink) {
        return (node.isSink === isSink) && node.audio
    }
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
            return root.correctType(node, isSink) && node.isStream
        })
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return root.correctType(node, isSink) && !node.isStream
        })
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    // Signals
    signal sinkProtectionTriggered(string reason);

    // Controls
    function toggleMute() {
        Audio.sink.audio.muted = !Audio.sink.audio.muted
    }

    function toggleMicMute() {
        Audio.source.audio.muted = !Audio.source.audio.muted
    }

    function incrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step);
    }
    
    function decrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        Audio.sink.audio.volume -= step;
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function cycleOutput() {
        const devices = root.outputDevices;
        if (devices.length === 0) return;
        const currentIndex = devices.findIndex(node => node.id === root.sink?.id);
        const nextDevice = devices[(currentIndex + 1) % devices.length];
        root.setDefaultSink(nextDevice);
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Card profile switching (this laptop's ALSA card exposes only one sink at a
    // time depending on active profile — analog vs HDMI 1/2/3 — so switching
    // "outputs" really means switching the card profile, not the PipeWire node).
    property string cardName: ""
    property string activeProfile: ""
    property var availableProfiles: [] // list of profile names, in priority order
    readonly property var profileCyclePriority: [
        "output:analog-stereo+input:analog-stereo",
        "output:hdmi-stereo+input:analog-stereo",
        "output:hdmi-stereo-extra1+input:analog-stereo",
        "output:hdmi-stereo-extra2+input:analog-stereo"
    ]

    function refreshCardInfo() {
        cardInfoProc.buffer = "";
        cardInfoProc.running = true;
    }

    Process {
        id: cardInfoProc
        property string buffer: ""
        command: ["pactl", "list", "cards"]
        stdout: SplitParser {
            onRead: line => cardInfoProc.buffer += line + "\n"
        }
        onExited: {
            const lines = cardInfoProc.buffer.split("\n");
            let currentCard = "";
            let profiles = [];
            let active = "";
            for (const rawLine of lines) {
                const line = rawLine.trim();
                const cardMatch = rawLine.match(/^Card #\d+/);
                const nameMatch = line.match(/^Name:\s*(\S+)/);
                if (nameMatch && line.startsWith("Name:")) {
                    currentCard = nameMatch[1];
                }
                if (currentCard.startsWith("alsa_card") && line.match(/available: (yes|unknown)\)$/)) {
                    const profMatch = line.match(/^([^:]+:\S+):/);
                    if (profMatch) profiles.push(profMatch[1]);
                }
                if (currentCard.startsWith("alsa_card") && line.startsWith("Active Profile:")) {
                    root.cardName = currentCard;
                    root.availableProfiles = profiles;
                    root.activeProfile = line.replace("Active Profile:", "").trim();
                    profiles = [];
                }
            }
        }
    }

    Process {
        id: setProfileProc
        onExited: root.refreshCardInfo()
    }

    function setCardProfile(profile) {
        if (!root.cardName) return;
        setProfileProc.command = ["pactl", "set-card-profile", root.cardName, profile];
        setProfileProc.running = true;
    }

    readonly property var profileFriendlyNames: ({
        "output:analog-stereo+input:analog-stereo": "Analog",
        "output:hdmi-stereo+input:analog-stereo": "HDMI",
        "output:hdmi-stereo-extra1+input:analog-stereo": "HDMI 2",
        "output:hdmi-stereo-extra2+input:analog-stereo": "HDMI 3"
    })

    property string lastCycledProfileLabel: ""
    signal profileCycled()

    function notifyProfile(profile) {
        root.lastCycledProfileLabel = root.profileFriendlyNames[profile] || profile;
        root.profileCycled();
    }

    function cycleProfile() {
        const order = root.profileCyclePriority.filter(p => root.availableProfiles.includes(p));
        if (order.length === 0) return;
        const currentIndex = order.indexOf(root.activeProfile);
        const next = order[(currentIndex + 1) % order.length];
        root.setCardProfile(next);
        root.notifyProfile(next); // always shown, even if next === current (nothing else available)
    }

    // If HDMI is unplugged while active, its profile becomes unavailable and
    // audio dies silently until the user manually re-selects analog. Watch
    // pactl events and fall back to analog automatically when that happens.
    Process {
        id: cardEventWatcher
        running: true
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("card")) root.refreshCardInfo();
            }
        }
    }

    Connections {
        target: root
        function onAvailableProfilesChanged() {
            if (root.activeProfile && !root.availableProfiles.includes(root.activeProfile)
                && root.availableProfiles.includes("output:analog-stereo+input:analog-stereo")) {
                root.setCardProfile("output:analog-stereo+input:analog-stereo");
            }
        }
    }

    Component.onCompleted: root.refreshCardInfo()

    // Internals
    PwObjectTracker {
        objects: [sink, source]
    }

    Connections { // Protection against sudden volume changes
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!Config.options.audio.protection.enable) return;
            const newVolume = sink.audio.volume;
            // when resuming from suspend, we should not write volume to avoid pipewire volume reset issues
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                lastVolume = 0;
                return;
            }
            if (!lastReady) {
                lastVolume = newVolume;
                lastReady = true;
                return;
            }
            const maxAllowedIncrease = Config.options.audio.protection.maxAllowedIncrease / 100; 
            const maxAllowed = Config.options.audio.protection.maxAllowed / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered("Illegal increment");
            } else if (newVolume > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered("Exceeded max allowed");
                sink.audio.volume = Math.min(lastVolume, maxAllowed);
            }
            lastVolume = sink.audio.volume;
        }
    }

    IpcHandler {
        target: "audio"

        function cycleOutput() {
            root.cycleOutput()
        }

        function cycleProfile() {
            root.cycleProfile()
        }
    }

    function playSystemSound(soundName) {
        const ogaPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`;
        const oggPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`;

        // Try playing .oga first
        let command = [
            "ffplay",
            "-nodisp",
            "-autoexit",
            ogaPath
        ];
        Quickshell.execDetached(command);

        // Also try playing .ogg (ffplay will just fail silently if file doesn't exist)
        command = [
            "ffplay",
            "-nodisp",
            "-autoexit",
            oggPath
        ];
        Quickshell.execDetached(command);
    }
}
