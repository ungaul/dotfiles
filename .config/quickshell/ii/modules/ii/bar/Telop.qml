import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Scrolling ticker styled after the Japanese TV/radio "telop" (テロップ) news
// crawl, fed with real headlines from Japan's Google News RSS edition.
Item {
    id: root

    readonly property string newsUrl: "https://news.google.com/rss?hl=ja&gl=JP&ceid=JP:ja"
    readonly property int refreshInterval: 10 * 60 * 1000 // 10 min
    property list<string> headlines: []
    readonly property string tickerText: headlines.length > 0
        ? headlines.join("　●　") + "　●　"
        : "ニュース取得中…　"
    property real scrollSpeed: 40 // px/s

    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.maximumWidth: 310
    implicitWidth: 160
    implicitHeight: Appearance.sizes.barHeight
    clip: true

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: newsFetch.running = true
    }

    Process {
        id: newsFetch
        command: ["curl", "-s", "--max-time", "5", root.newsUrl]
        stdout: StdioCollector {
            onStreamFinished: {
                const titles = [];
                const itemBlocks = text.split("<item>").slice(1);
                for (const block of itemBlocks) {
                    const m = block.match(/<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?<\/title>/);
                    if (m) titles.push(m[1]);
                    if (titles.length >= 10) break;
                }
                if (titles.length > 0) root.headlines = titles;
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }

    Row {
        id: track
        height: root.height
        spacing: 0

        Connections {
            target: hoverArea
            function onContainsMouseChanged() {
                if (!hoverArea.containsMouse) track.x = 0;
            }
        }

        StyledText {
            id: sample
            text: root.tickerText
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            anchors.verticalCenter: parent.verticalCenter
            elide: hoverArea.containsMouse ? Text.ElideNone : Text.ElideRight
            width: hoverArea.containsMouse ? undefined : root.width
        }
        StyledText {
            visible: hoverArea.containsMouse
            text: root.tickerText
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    NumberAnimation {
        target: track
        property: "x"
        running: hoverArea.containsMouse && sample.implicitWidth > 0
        loops: Animation.Infinite
        from: 0
        to: -sample.implicitWidth
        duration: sample.implicitWidth > 0 ? (sample.implicitWidth / root.scrollSpeed) * 1000 : 1000
    }
}
