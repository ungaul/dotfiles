pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, and CPU usage.
 */
Singleton {
    id: root
	property real memoryTotal: 1
	property real memoryFree: 0
	property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
	property real swapFree: 0
	property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats

	property real netRxSpeed: 0
	property real netTxSpeed: 0
	property var previousNetStats: null
	readonly property real netSpeedRef: 100 * 1024 * 1024
	property real netRxPercentage: Math.min(netRxSpeed / netSpeedRef, 1)
	property real netTxPercentage: Math.min(netTxSpeed / netSpeedRef, 1)

	function formatNetSpeed(bytesPerSec) {
	    if (bytesPerSec >= 1024 * 1024)
	        return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
	    else if (bytesPerSec >= 1024)
	        return (bytesPerSec / 1024).toFixed(0) + " KB/s"
	    else
	        return bytesPerSec.toFixed(0) + " B/s"
	}

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }
    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
    }

	Timer {
		interval: 1
        running: true 
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()
            fileNetDev.reload()

            // Parse memory and swap usage
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // Parse CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3] + stats[4] // idle + iowait

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            // Parse network usage
            const textNetDev = fileNetDev.text()
			const lines = textNetDev.split('\n')
			let totalRx = 0, totalTx = 0
			for (const line of lines.slice(2)) {
			    const trimmed = line.trim()
			    if (!trimmed) continue
			    const colonIdx = trimmed.indexOf(':')
			    if (colonIdx === -1) continue
			    const iface = trimmed.substring(0, colonIdx).trim()
			    // Only physical interfaces: skip lo, veth*, br-*, docker*
			    if (iface === 'lo' || iface.startsWith('veth') || 
			        iface.startsWith('br-') || iface.startsWith('docker')) continue
			    const parts = trimmed.substring(colonIdx + 1).trim().split(/\s+/)
			    if (parts.length >= 9) {
			        totalRx += parseInt(parts[0]) || 0
			        totalTx += parseInt(parts[8]) || 0
			    }
			}
			const now = Date.now()
			if (root.previousNetStats) {
			    const dt = (now - root.previousNetStats.time) / 1000
			    root.netRxSpeed = dt > 0 ? Math.max(0, (totalRx - root.previousNetStats.rx) / dt) : 0
			    root.netTxSpeed = dt > 0 ? Math.max(0, (totalTx - root.previousNetStats.tx) / dt) : 0
			}
			root.previousNetStats = { rx: totalRx, tx: totalTx, time: now }
            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileNetDev; path: "/proc/net/dev" }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }
}
