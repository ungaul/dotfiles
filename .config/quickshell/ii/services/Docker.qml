pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Docker service: polls container/stack state and exposes actions.
 */
Singleton {
    id: root

    property bool available: false
    property bool loading: false
    property var containers: []  // [{id, name, state, status, image, composeProject, composeService}]
    property var stacks: []      // [{name, status, configFiles}]

    readonly property int runningCount: {
        let n = 0;
        for (const c of containers) if (c.state === "running") n++;
        return n;
    }

    // Stacks enriched with their containers
    readonly property var stacksWithContainers: {
        return stacks.map(s => ({
            name: s.name,
            status: s.status,
            configFiles: s.configFiles,
            containers: containers.filter(c => c.composeProject === s.name)
        }));
    }

    // Containers not belonging to any known compose stack
    readonly property var standaloneContainers: {
        const projectNames = stacks.map(s => s.name);
        return containers.filter(c => !c.composeProject || !projectNames.includes(c.composeProject));
    }

    // ── public actions ────────────────────────────────────────────────────────

    function refresh() {
        if (!available) return;
        loading = true;
        containersProc.running = true;
    }

    function startContainer(name) {
        Quickshell.execDetached(["docker", "start", name]);
        delayedRefresh.restart();
    }
    function stopContainer(name) {
        Quickshell.execDetached(["docker", "stop", "-t", "5", name]);
        delayedRefresh.restart();
    }
    function restartContainer(name) {
        Quickshell.execDetached(["docker", "restart", name]);
        delayedRefresh.restart();
    }
    function startStack(project) {
        Quickshell.execDetached(["docker", "compose", "-p", project, "start"]);
        delayedRefresh.restart();
    }
    function stopStack(project) {
        Quickshell.execDetached(["docker", "compose", "-p", project, "stop"]);
        delayedRefresh.restart();
    }
    function restartStack(project) {
        Quickshell.execDetached(["docker", "compose", "-p", project, "restart"]);
        delayedRefresh.restart();
    }

    // ── internal timers ───────────────────────────────────────────────────────

    // Delayed refresh after an action (give docker time to act)
    Timer {
        id: delayedRefresh
        interval: 2500
        repeat: false
        onTriggered: root.refresh()
    }

    // Periodic polling
    Timer {
        interval: 12000
        repeat: true
        running: root.available
        triggeredOnStart: false
        onTriggered: root.refresh()
    }

    // ── processes ─────────────────────────────────────────────────────────────

    // Check if docker is installed
    Process {
        id: checkAvailProc
        running: true
        command: ["which", "docker"]
        onExited: (code) => {
            root.available = (code === 0);
            if (root.available) root.refresh();
        }
    }

    // Step 1: get all containers
    Process {
        id: containersProc
        command: ["bash", "-c", "docker ps -a --format '{{json .}}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(l => l.trim());
                root.containers = lines.map(line => {
                    try {
                        const obj = JSON.parse(line);
                        const labels = obj.Labels || "";
                        const getLabel = (key) => {
                            const entry = labels.split(',').find(p => p.startsWith(key + '='));
                            return entry ? entry.slice(key.length + 1) : "";
                        };
                        return {
                            id: obj.ID || "",
                            name: obj.Names || "",
                            state: obj.State || "",
                            status: obj.Status || "",
                            image: obj.Image || "",
                            composeProject: getLabel('com.docker.compose.project'),
                            composeService: getLabel('com.docker.compose.service')
                        };
                    } catch (e) { return null; }
                }).filter(c => c && c.name);

                // Step 2: now fetch stacks
                stacksProc.running = true;
            }
        }
    }

    // Step 2: get compose stacks
    Process {
        id: stacksProc
        command: ["docker", "compose", "ls", "--all", "--format", "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = text.trim();
                    const arr = raw ? JSON.parse(raw) : [];
                    root.stacks = Array.isArray(arr) ? arr.map(s => ({
                        name: s.Name || "",
                        status: s.Status || "",
                        configFiles: s.ConfigFiles || ""
                    })) : [];
                } catch (e) {
                    root.stacks = [];
                }
                root.loading = false;
            }
        }
    }
}
