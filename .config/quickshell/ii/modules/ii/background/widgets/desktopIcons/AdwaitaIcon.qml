import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

// Renders GNOME/Nautilus-style (Adwaita) icons regardless of the system's
// active Qt/KDE icon theme, since Quickshell.iconPath always resolves
// against the global theme (e.g. Breeze on KDE, which looks like Dolphin).
Image {
    id: root
    required property var fileModelData
    asynchronous: true
    fillMode: Image.PreserveAspectFit

    readonly property string base: "/usr/share/icons/Adwaita/scalable"
    readonly property var specialFolders: ({
            "documents": "documents",
            "downloads": "download",
            "music": "music",
            "pictures": "pictures",
            "public": "publicshare",
            "templates": "templates",
            "videos": "videos"
        })

    function folderIconPath() {
        const lower = fileModelData.fileName.toLowerCase();
        const special = specialFolders[lower];
        return special ? `${root.base}/places/folder-${special}.svg` : `${root.base}/places/folder.svg`;
    }

    function mimeIconPath(mime) {
        const category = mime.split("/")[0];
        if (category === "video")
            return `${root.base}/mimetypes/video-x-generic.svg`;
        if (category === "audio")
            return `${root.base}/mimetypes/audio-x-generic.svg`;
        if (category === "font")
            return `${root.base}/mimetypes/font-x-generic.svg`;
        if (mime === "text/html")
            return `${root.base}/mimetypes/text-html.svg`;
        if (category === "text")
            return `${root.base}/mimetypes/text-x-generic.svg`;
        if (["application/zip", "application/x-tar", "application/gzip", "application/x-7z-compressed", "application/x-rar-compressed", "application/x-xz", "application/x-bzip2"].includes(mime))
            return `${root.base}/mimetypes/package-x-generic.svg`;
        if (["application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.oasis.opendocument.text", "application/pdf"].includes(mime))
            return `${root.base}/mimetypes/x-office-document.svg`;
        if (["application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.oasis.opendocument.spreadsheet"].includes(mime))
            return `${root.base}/mimetypes/x-office-spreadsheet.svg`;
        if (["application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.presentationml.presentation", "application/vnd.oasis.opendocument.presentation"].includes(mime))
            return `${root.base}/mimetypes/x-office-presentation.svg`;
        if (mime === "application/x-executable" || mime === "application/x-sharedlib")
            return `${root.base}/mimetypes/application-x-executable.svg`;
        return `${root.base}/mimetypes/application-x-generic.svg`;
    }

    source: fileModelData.fileIsDir ? folderIconPath() : `${root.base}/mimetypes/application-x-generic.svg`

    onStatusChanged: {
        if (status === Image.Error)
            source = fileModelData.fileIsDir ? `${root.base}/places/folder.svg` : `${root.base}/mimetypes/application-x-generic.svg`;
    }

    Process {
        running: !fileModelData.fileIsDir
        command: ["file", "--mime-type", "-b", fileModelData.filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                root.source = root.mimeIconPath(text.trim());
            }
        }
    }
}
