pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    property alias tasks: adapter.tasks
    property bool ready: false

    function addTask(content: string): void {
        const list = adapter.tasks.slice()
        list.push({ content: content, done: false })
        adapter.tasks = list
    }

    function markDone(index: int): void {
        const list = adapter.tasks.slice()
        if (index < 0 || index >= list.length) return
        list[index] = Object.assign({}, list[index], { done: true })
        adapter.tasks = list
    }

    function markUnfinished(index: int): void {
        const list = adapter.tasks.slice()
        if (index < 0 || index >= list.length) return
        list[index] = Object.assign({}, list[index], { done: false })
        adapter.tasks = list
    }

    function deleteItem(index: int): void {
        const list = adapter.tasks.slice()
        if (index < 0 || index >= list.length) return
        list.splice(index, 1)
        adapter.tasks = list
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p",
            Directories.todoPath.substring(0, Directories.todoPath.lastIndexOf("/"))
        ])
    }

    Timer {
        id: writeTimer
        interval: 100
        repeat: false
        onTriggered: fileView.writeAdapter()
    }

    FileView {
        id: fileView
        path: Directories.todoPath
        watchChanges: true

        onFileChanged: fileView.reload()
        onAdapterUpdated: writeTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                fileView.writeAdapter()
            }
        }

        JsonAdapter {
            id: adapter
            property list<var> tasks: []
        }
    }
}
