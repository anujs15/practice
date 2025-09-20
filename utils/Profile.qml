import QtQuick 2.15
import QtQuick.Controls 2.15
import "../profile.js" as Profile
import "../learningState.js" as Learning

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
                    }
                }
            }

            // Open From... (file picker)
            Rectangle {
                width: 150; height: 40; radius: 6; color: "#8888ff"
                Text { anchors.centerIn: parent; text: "Open From..."; color: "white"; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: openDialog.open()
                }
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
        function open() { visible = true }
        function close() { visible = false }
        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
            Text { text: "Save profile as (path):"; color: "#ddd" }
            TextField { id: savePath; placeholderText: Store.defaultProfilePath(); color: "#fff" }
            Row {
                spacing: 10
                Rectangle { width: 90; height: 34; radius: 6; color: "yellow"
                    Text { anchors.centerIn: parent; text: "Save"; color: "black"; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: {
                        var p = savePath.text && savePath.text.length ? savePath.text : Store.defaultProfilePath()
                        var payload = Profile.collect(appsdata, Learning.Learning.getAll())
                        if (Store.saveProfile(p, Profile.stringify(payload))) {
                            Store.setLastProfilePath(p)
                            showToast("Saved: " + p)
                        }
                        saveDialog.close()
                    }}
                }
                Rectangle { width: 90; height: 34; radius: 6; color: "#555"
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "#eee" }
                    MouseArea { anchors.fill: parent; onClicked: saveDialog.close() }
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
        function open() { visible = true }
        function close() { visible = false }
        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
            Text { text: "Open profile from (path):"; color: "#ddd" }
            TextField { id: openPath; placeholderText: Store.lastProfilePath(); color: "#fff" }
            Row {
                spacing: 10
                Rectangle { width: 90; height: 34; radius: 6; color: "#8888ff"
                    Text { anchors.centerIn: parent; text: "Open"; color: "white"; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: {
                        var p = openPath.text && openPath.text.length ? openPath.text : Store.lastProfilePath()
                        if (Store.fileExists(p)) {
                            Store.setLastProfilePath(p)
                            var data = Store.loadProfile(p)
                            var profile = Profile.parse(data)
                            Profile.apply(profile, root)
                            if (profile && profile.learning) {
                                Learning.Learning.apply(profile.learning)
                            }
                            showToast("Opened: " + p)
                        } else {
                            showToast("File not found: " + p)
                        }
                        openDialog.close()
                    }}
                }
                Rectangle { width: 90; height: 34; radius: 6; color: "#555"
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "#eee" }
                    MouseArea { anchors.fill: parent; onClicked: openDialog.close() }
                }
            }
        }
    }
}
