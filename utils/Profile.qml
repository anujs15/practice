import QtQuick 2.15
import QtQuick.Controls 2.15
import "../profile.js" as Profile
import "../learningState.js" as Learning
import Qt.labs.folderlistmodel 2.1
import QtQuick.Dialogs 1.3
import "../Logging.js" as Log

Page {
    id: root

    required property var appsdata
    required property StackView stackView
    // map: appId -> attemptedKeys[] captured from Testground or Result screens
    property var learning: ({})

    background: Rectangle { color: "black" }

    // toast / callback message area
    Rectangle {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 60
        radius: 6
        color: "#222222"
        visible: opacity > 0
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Text { id: toastText; anchors.margins: 10; anchors.centerIn: parent; color: "#eeeeee" }
        width: toastText.implicitWidth + 20
        height: toastText.implicitHeight + 10
    }

    function showToast(msg) {
        toastText.text = msg
        toast.opacity = 1
        toastTimer.restart()
    }

    Timer { id: toastTimer; interval: 2200; onTriggered: toast.opacity = 0 }

    Button {
        id: backButton
        text: "Back"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        onClicked: stackView.pop()
    }

    Column {
        spacing: 20
        anchors.centerIn: parent

        Text {
            text: "User Profile"
            color: "white"
            font.pixelSize: 28
            font.bold: true
        }

        Row {
            spacing: 10
            Text { text: "Current profile:"; color: "#cccccc" }
            Text { text: Store.lastProfilePath(); color: "#aaaaaa" }
        }

        // Alias entry & quick alias actions
        Row {
            spacing: 10
            Text { text: "Alias:"; color: "#cccccc" }
            TextField { id: aliasField; placeholderText: "username"; color: "#fff"; width: 160 }
            CheckBox { id: protectCheck; text: "Protect" }
            TextField { id: aliasPassword; placeholderText: "password (optional)"; echoMode: TextInput.Password; color: "#fff"; width: 140 }

            Rectangle { width: 120; height: 36; radius: 6; color: "#44aa44"
                Text { anchors.centerIn: parent; text: "Save Alias"; color: "white" }
                MouseArea { anchors.fill: parent; onClicked: {
                    var alias = aliasField.text && aliasField.text.length ? aliasField.text.trim() : null
                    if (!alias) { showToast("Enter an alias to save"); return }
                    var path = Store.appDataDir() + "/aliases/" + alias + ".json"
                    var payload = Profile.collect(appsdata, Learning.Learning.getAll(), alias)
                    if (protectCheck.checked) {
                        if (!aliasPassword.text || aliasPassword.text.length < 1) { showToast("Enter a password to protect the alias"); return }
                        if (Store.saveEncryptedProfile(path, Profile.stringify(payload), aliasPassword.text)) {
                            Store.setLastProfilePath(path)
                            showToast("Saved protected alias: " + alias)
+                            Log.info("Saved protected alias: " + alias + " at " + path)
                        } else {
                            showToast("Failed to save protected alias")
                        }
                    } else {
                        if (Store.saveProfile(path, Profile.stringify(payload))) {
                            Store.setLastProfilePath(path)
                            showToast("Saved alias: " + alias)
+                            Log.info("Saved alias: " + alias + " at " + path)
                        } else {
                            showToast("Failed to save alias")
                        }
                    }
                }}
            }

            Rectangle { width: 120; height: 36; radius: 6; color: "#3377cc"
                Text { anchors.centerIn: parent; text: "Restore Alias"; color: "white" }
                MouseArea { anchors.fill: parent; onClicked: {
                    var alias = aliasField.text && aliasField.text.length ? aliasField.text.trim() : null
                    if (!alias) { showToast("Enter an alias to restore"); return }
                    var path = Store.appDataDir() + "/aliases/" + alias + ".json"
                    if (!Store.fileExists(path)) { showToast("Alias not found: " + alias); return }
                    Store.setLastProfilePath(path)
                    var data = Store.loadProfile(path)
                    var profile = Profile.parse(data)
                    Profile.apply(profile, root)
                    if (profile && profile.learning) Learning.Learning.apply(profile.learning)
                    showToast("Restored alias: " + alias)
                }}
            }

            Rectangle { width: 120; height: 36; radius: 6; color: "#aaaaaa"
                Text { anchors.centerIn: parent; text: "Manage Aliases"; color: "black" }
                MouseArea { anchors.fill: parent; onClicked: aliasesDialog.open() }
            }
        }

        Row {
            spacing: 20

            Rectangle {
                width: 150; height: 40; radius: 6; color: "yellow"
                Text { anchors.centerIn: parent; text: "Create Default"; color: "black"; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var p = Store.defaultProfilePath()
                        var payload = Profile.collect(appsdata, Learning.Learning.getAll())
                        var ok = Store.saveProfile(p, Profile.stringify(payload))
                        if (ok) {
                            Store.setLastProfilePath(p)
                            showToast("Saved default profile: " + p)
+                            Log.info("Created default profile: " + p)
                        }
                    }
                }
            }

            Rectangle {
                width: 150; height: 40; radius: 6; color: "yellow"
                Text { anchors.centerIn: parent; text: "Save Backup"; color: "black"; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var p = Store.lastProfilePath()
                        if (!p || p === "") p = Store.defaultProfilePath()
                        var payload = Profile.collect(appsdata, Learning.Learning.getAll())
                        if (Store.saveProfile(p, Profile.stringify(payload))) {
                            showToast("Saved profile: " + p)
+                            Log.info("Saved profile (backup): " + p)
                        }
                    }
                }
            }

            // Save As (file picker)
            Rectangle {
                width: 150; height: 40; radius: 6; color: "yellow"
                Text { anchors.centerIn: parent; text: "Save As..."; color: "black"; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onPressed: Log.info("Save As dialog requested")
                    onClicked: saveDialog.open()
                }
            }
        }

        Row {
            spacing: 20

            Rectangle {
                width: 150; height: 40; radius: 6; color: "#8888ff"
                Text { anchors.centerIn: parent; text: "Restore"; color: "white"; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var p = Store.lastProfilePath()
                        if (Store.fileExists(p)) {
                            var data = Store.loadProfile(p)
                            var profile = Profile.parse(data)
                            Profile.apply(profile, root)
                            if (profile && profile.learning) {
                                Learning.Learning.apply(profile.learning)
                            }
                            showToast("Restored from: " + p)
+                            Log.info("Restored profile from: " + p)
                        }
                    }
                }
            }

            Rectangle {
                width: 150; height: 40; radius: 6; color: "#8888ff"
                Text { anchors.centerIn: parent; text: "Open Saved"; color: "white"; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var p = Store.lastProfilePath()
                        if (!Store.fileExists(p)) p = Store.defaultProfilePath()
                        Store.setLastProfilePath(p)
                        var data = Store.loadProfile(p)
                        var profile = Profile.parse(data)
                        Profile.apply(profile, root)
                        if (profile && profile.learning) {
                            Learning.Learning.apply(profile.learning)
                        }
                        showToast("Opened: " + p)
+                        Log.info("Opened profile file: " + p)
                    }
                }
            }

            // Open From... (file picker)
            Rectangle {
                width: 150; height: 40; radius: 6; color: "#8888ff"
                Text { anchors.centerIn: parent; text: "Open From..."; color: "white"; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onPressed: Log.info("Open dialog requested")
                    onClicked: openDialog.open()
                }
            }
        }

        // Log management row
        Row {
            spacing: 10
            Rectangle { width: 160; height: 36; radius: 6; color: "#777";
                Text { anchors.centerIn: parent; text: "Export Logs"; color: "white" }
                MouseArea { anchors.fill: parent; onClicked: {
                    fileExportLogsDialog.title = "Export logs to file"
                    fileExportLogsDialog.open()
                }}
            }

            Rectangle { width: 140; height: 36; radius: 6; color: "#cc4444";
                Text { anchors.centerIn: parent; text: "Clear Logs"; color: "white" }
                MouseArea { anchors.fill: parent; onClicked: {
                    if (Store.clearLogs()) { showToast("Logs cleared"); Log.info("Logs cleared by user") }
                    else { showToast("Failed to clear logs"); Log.warn("Failed to clear logs") }
                }}
            }
        }
    }

    // NOTE: Using Qt Quick Dialogs module could be more native, but to keep style simple and dependencies minimal,
    // this uses a simple inline dialog asking for a path string.
    Rectangle {
        id: saveDialog
        visible: false
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: 140
        radius: 8
        color: "#111111"
        border.color: "#444"
        enabled: visible
        z: 100
        function open() { visible = true; Log.info("Save dialog opened") }
        function close() { visible = false; Log.info("Save dialog closed") }
        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
            Text { text: "Save profile as (path):"; color: "#ddd" }
            TextField { id: savePath; placeholderText: Store.defaultProfilePath(); color: "#fff"; focus: false }
            Row {
                spacing: 10
                Rectangle { width: 90; height: 34; radius: 6; color: "yellow"
                    Text { anchors.centerIn: parent; text: "Save"; color: "black"; font.bold: true }
                    MouseArea { anchors.fill: parent; enabled: saveDialog.visible; onClicked: {
                        var p = savePath.text && savePath.text.length ? savePath.text : Store.defaultProfilePath()
                        var payload = Profile.collect(appsdata, Learning.Learning.getAll())
                        if (Store.saveProfile(p, Profile.stringify(payload))) {
                            Store.setLastProfilePath(p)
                            showToast("Saved: " + p)
+                            Log.info("Saved profile via Save As: " + p)
                        }
                        saveDialog.close()
                    }}
                }
                Rectangle { width: 90; height: 34; radius: 6; color: "#555"
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "#eee" }
                    MouseArea { anchors.fill: parent; enabled: saveDialog.visible; onClicked: saveDialog.close() }
                }
            }
        }
    }

    Rectangle {
        id: openDialog
        visible: false
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: 140
        radius: 8
        color: "#111111"
        border.color: "#444"
        enabled: visible
        z: 100
        function open() { visible = true; Qt.inputMethod.hide(); Log.info("Open dialog opened") }
        function close() { visible = false; Log.info("Open dialog closed") }
        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
            Text { text: "Open profile from (path):"; color: "#ddd" }
            TextField { id: openPath; placeholderText: Store.lastProfilePath(); color: "#fff" }
            Row {
                spacing: 10
                Rectangle { width: 90; height: 34; radius: 6; color: "#8888ff"
                    Text { anchors.centerIn: parent; text: "Open"; color: "white" }
                    MouseArea { anchors.fill: parent; enabled: openDialog.visible; onClicked: {
                        var p = openPath.text && openPath.text.length ? openPath.text : Store.lastProfilePath()
                        if (importMode) {
                            // import the file into aliases folder
                            var base = p.replace(/.*\/(.*)$/,'$1')
                            var dest = Store.appDataDir() + "/aliases/" + base
                            if (Store.copyProfile(p, dest)) {
                                showToast("Imported: " + base)
                                // refresh the alias model if the aliases dialog is open
                                try {
                                    var f = aliasesDialog.aliasModelRef.folder
                                    aliasesDialog.aliasModelRef.folder = ""
                                    aliasesDialog.aliasModelRef.folder = f
                                } catch(e) {}
+                                Log.info("Imported file to aliases: " + base)
                            } else {
                                showToast("Import failed")
                            }
                            importMode = false
                        } else {
                            if (Store.fileExists(p)) {
                                Store.setLastProfilePath(p)
                                var data = Store.loadProfile(p)
                                var profile = Profile.parse(data)
                                Profile.apply(profile, root)
                                if (profile && profile.learning) {
                                    Learning.Learning.apply(profile.learning)
                                }
                                showToast("Opened: " + p)
+                                Log.info("Opened profile file: " + p)
                            } else {
                                showToast("File not found: " + p)
                            }
                        }
                        openDialog.close()
                    }}
                }
                Rectangle { width: 90; height: 34; radius: 6; color: "#555"
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "#eee" }
                    MouseArea { anchors.fill: parent; enabled: openDialog.visible; onClicked: openDialog.close() }
                }
            }
        }
    }

    // Aliases management dialog
    Rectangle {
        id: aliasesDialog
        property alias aliasModelRef: aliasModel
        visible: false
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.6
        radius: 8
        color: "#111111"
        border.color: "#444"
        function open() { visible = true; Log.info("Aliases dialog opened") }
        function close() { visible = false; Log.info("Aliases dialog closed") }

        Column { anchors.fill: parent; anchors.margins: 12; spacing: 8
            Text { text: "Saved aliases"; color: "#ddd" }

            FolderListModel {
                id: aliasModel
                folder: Store.appDataDir() + "/aliases"
                nameFilters: ["*.json"]
            }
            // expose a reference so other dialogs can refresh the model after import
            property alias aliasModelRef: aliasModel

            ListView {
                id: aliasList
                model: aliasModel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                clip: true
                delegate: Rectangle {
                    width: parent.width
                    height: 40
                    color: "#222"
                    Row { anchors.fill: parent; anchors.margins: 6; spacing: 8
                        Text { text: model.fileName.replace(/\.json$/,''); color: "#ddd"; horizontalAlignment: Text.AlignLeft }
                        Rectangle { width: 80; height: 28; radius: 4; color: "#44aa44";
                            Text { anchors.centerIn: parent; text: "Load"; color: "white" }
                            MouseArea { anchors.fill: parent; onClicked: {
                                var path = aliasModel.folder + "/" + model.fileName
                                if (!Store.fileExists(path)) { showToast("File missing: " + model.fileName); return }
                                // If protected, prompt for password
                                if (Store.isEncryptedProfile(path)) {
                                    pwPromptProfile.open(path)
                                    return
                                }
                                Store.setLastProfilePath(path)
                                var data = Store.loadProfile(path)
                                var profile = Profile.parse(data)
                                Profile.apply(profile, root)
                                if (profile && profile.learning) Learning.Learning.apply(profile.learning)
                                aliasField.text = model.fileName.replace(/\.json$/,'')
                                showToast("Loaded alias: " + aliasField.text)
+                                Log.info("Loaded alias from manager: " + model.fileName)
                            }}
                        }
                        Rectangle { width: 80; height: 28; radius: 4; color: "#cc4444";
                            Text { anchors.centerIn: parent; text: "Delete"; color: "white" }
                            MouseArea { anchors.fill: parent; onClicked: {
                                var path = aliasModel.folder + "/" + model.fileName
                                if (Store.removeProfile(path)) {
                                    showToast("Deleted: " + model.fileName)
                                    // refresh the folder model
                                    var f = aliasModel.folder
                                    aliasModel.folder = ""
                                    aliasModel.folder = f
+                                    Log.info("Deleted alias file: " + model.fileName)
                                } else {
                                    showToast("Failed to delete: " + model.fileName)
                                }
                            }}
                        }
                        Rectangle { width: 80; height: 28; radius: 4; color: "#888888";
                            Text { anchors.centerIn: parent; text: "Export"; color: "white" }
                            MouseArea { anchors.fill: parent; onClicked: {
                                // open save dialog - remember source path so the dialog can copy after user chooses target
                                fileExportSource = aliasModel.folder + "/" + model.fileName
                                fileExportDialog.title = "Export " + model.fileName
                                fileExportDialog.open()
+                                Log.info("Open file export dialog")
                            }}
                        }
                    }
                }
            }

            Row { spacing: 10; anchors.horizontalCenter: parent.horizontalCenter
                Rectangle { width: 120; height: 34; radius: 6; color: "#44aa44";
                    Text { anchors.centerIn: parent; text: "Import from file..."; color: "white" }
                    MouseArea { anchors.fill: parent; onClicked: {
                        fileImportDialog.open()
+                        Log.info("Open file import dialog")
                    }}
                }
            }

            Row { spacing: 10; anchors.horizontalCenter: parent.horizontalCenter
                Rectangle { width: 90; height: 34; radius: 6; color: "#555";
                    Text { anchors.centerIn: parent; text: "Close"; color: "#eee" }
                    MouseArea { anchors.fill: parent; onClicked: aliasesDialog.close() }
                }
            }
        }
    }

    // password prompt for protected alias files (profile manager)
    Rectangle {
        id: pwPromptProfile
        visible: false
        anchors.centerIn: parent
        width: parent.width * 0.7
        height: 120
        radius: 8
        color: "#111"
        border.color: "#444"
        property string path: ""
        function open(p) { path = p; visible = true }
        function close() { visible = false; pwdField.text = "" }
        Column { anchors.fill: parent; anchors.margins: 12; spacing: 8
            Text { text: "Enter password for profile"; color: "#ddd" }
            TextField { id: pwdField; placeholderText: "password"; echoMode: TextInput.Password; color: "#fff" }
            Row { spacing: 10; anchors.horizontalCenter: parent.horizontalCenter
                Rectangle { width: 90; height: 34; radius: 6; color: "#44aa44"
                    Text { anchors.centerIn: parent; text: "Open"; color: "white" }
                    MouseArea { anchors.fill: parent; onClicked: {
                        var content = Store.loadEncryptedProfile(path, pwdField.text)
                        if (!content || content === "") { showToast("Wrong password or failed to open") ; return }
                        var profile = Profile.parse(content)
                        Profile.apply(profile, root)
                        if (profile && profile.learning) Learning.Learning.apply(profile.learning)
                        Store.setLastProfilePath(path)
                        pwPromptProfile.close()
                        // refresh aliasField and UI
                        aliasField.text = path.replace(/.*\/(.*)\.json$/,'$1')
                        showToast("Loaded protected alias")
                    }}
                }
                Rectangle { width: 90; height: 34; radius: 6; color: "#555"
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "#eee" }
                    MouseArea { anchors.fill: parent; onClicked: pwPromptProfile.close() }
                }
            }
        }
    }

    // File dialogs for import / export
    FileDialog {
        id: fileImportDialog
        title: "Import profile file"
        selectMultiple: false
        onAccepted: {
            // QtQuick.Dialogs.FileDialog provides "file" (local path) and "selectedFiles" in some builds
            var src = file || (selectedFiles && selectedFiles.length ? selectedFiles[0] : "")
            if (!src) {
                // fallback: open manual path dialog
                showToast("No file selected; use 'Open From...' to enter a path")
                return
            }
            var base = src.replace(/.*\/(.*)$/,'$1')
            var dest = Store.appDataDir() + "/aliases/" + base
            if (Store.copyProfile(src, dest)) {
                showToast("Imported: " + base)
                try { var f = aliasesDialog.aliasModelRef.folder; aliasesDialog.aliasModelRef.folder = ""; aliasesDialog.aliasModelRef.folder = f } catch(e) {}
            } else {
                showToast("Import failed")
            }
        }
        onRejected: { /* user cancelled */ }
    }

    FileDialog {
        id: fileExportDialog
        title: "Export alias"
        selectExisting: false
        onAccepted: {
            var dst = file || (selectedFiles && selectedFiles.length ? selectedFiles[0] : "")
            if (!dst) { showToast("No destination chosen"); return }
            if (Store.copyProfile(fileExportSource, dst)) {
                showToast("Exported to: " + dst)
            } else {
                showToast("Export failed")
            }
        }
        onRejected: { /* user cancelled */ }
    }

    FileDialog {
        id: fileExportLogsDialog
        title: "Export logs"
        selectExisting: false
        onAccepted: {
            var dst = file || (selectedFiles && selectedFiles.length ? selectedFiles[0] : "")
            if (!dst) { showToast("No destination chosen"); return }
            if (Store.exportLogs(dst)) { showToast("Exported logs: " + dst); Log.info("Exported logs to: " + dst) }
            else { showToast("Export failed"); Log.warn("Export logs failed to: " + dst) }
        }
        onRejected: { Log.info("Export logs cancelled") }
    }
}
