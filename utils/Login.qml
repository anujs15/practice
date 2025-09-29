import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt.labs.folderlistmodel 2.1
import "../profile.js" as Profile
import "../learningState.js" as Learning
import "keydata.js" as Fn
import "../Logging.js" as Log

Page {
    id: login

    required property StackView stackView
    property int selectedIndex: -1

    background: Rectangle { color: "black" }

    Column { anchors.centerIn: parent; spacing: 12
        Text { text: "Sign in"; color: "white"; font.pixelSize: 28; font.bold: true }

        FolderListModel {
            id: aliasModel
            folder: Store.appDataDir() + "/aliases"
            nameFilters: ["*.json"]
        }

        ListView {
            id: listView
            width: parent.width * 0.8
            height: parent.height * 0.4
            model: aliasModel
            clip: true
            delegate: Rectangle {
                height: 48
                width: parent.width
                color: ListView.isCurrentItem ? "#333" : "#111"
                Row { anchors.fill: parent; anchors.margins: 8; spacing: 10
                    Text { text: model.fileName.replace(/\.json$/,''); color: "#ddd" }
                    Text { text: Store.isEncryptedProfile(aliasModel.folder + "/" + model.fileName) ? "(protected)" : ""; color: "#999" }
                }
                MouseArea { anchors.fill: parent; onClicked: { listView.currentIndex = index; login.selectedIndex = index } }
            }
        }

        Row { spacing: 10; anchors.horizontalCenter: parent.horizontalCenter
            Rectangle { width: 120; height: 38; radius: 6; color: "#3377cc"
                Text { anchors.centerIn: parent; text: "Login"; color: "white" }
                MouseArea { anchors.fill: parent; onClicked: {
                    if (selectedIndex < 0) { showToast("Select an alias or continue as guest") ; return }
                    var file = aliasModel.folder + "/" + aliasModel.get(selectedIndex).fileName
                    if (Store.isEncryptedProfile(file)) {
                        Log.info("Protected alias selected; prompting for password")
                        pwPrompt.open(file)
                        return
                    }
                    var data = Store.loadProfile(file)
                    var profile = Profile.parse(data)
                    Profile.apply(profile, root)
                    if (profile && profile.learning) Learning.Learning.apply(profile.learning)
                    Store.setLastProfilePath(file)
                    // persist signed-in alias (store alias name without extension)
                    var an = aliasModel.get(selectedIndex).fileName.replace(/\.json$/,'')
                    Store.setSignedInAlias(an)
                    Log.info("Logged in as alias: " + an)
                    stackView.push("AppsView.qml", { appsdata: Fn.appsdata, stackView: stackView })
                }}
            }

            Rectangle { width: 160; height: 38; radius: 6; color: "#44aa44"
                Text { anchors.centerIn: parent; text: "Continue as guest"; color: "white" }
                MouseArea { anchors.fill: parent; onClicked: {
                    // if existing last profile present and valid load it, else create default
                    var p = Store.lastProfilePath()
                    if (Store.fileExists(p) && !Store.isEncryptedProfile(p)) {
                        var data = Store.loadProfile(p)
                        var profile = Profile.parse(data)
                        Profile.apply(profile, root)
                        if (profile && profile.learning) Learning.Learning.apply(profile.learning)
                        // persist as signed-in alias if file belongs to aliases dir
                        try {
                            var fn = p.replace(/.*\/(.*)\.json$/,'$1')
                            Store.setSignedInAlias(fn)
                            Log.info("Continuing as signed-in alias: " + fn)
                        } catch(e) {}
                    } else {
                        var payload = Profile.collect(Fn.appsdata, Learning.Learning.getAll())
                        var ok = Store.saveProfile(Store.defaultProfilePath(), Profile.stringify(payload))
                        if (ok) Store.setLastProfilePath(Store.defaultProfilePath())
                        Store.setSignedInAlias("")
                        Log.info("Continuing as guest; no signed-in alias persisted")
                    }
                    stackView.push("AppsView.qml", { appsdata: Fn.appsdata, stackView: stackView })
                }}
            }
        }

        Rectangle { width: 300; height: 1; color: "#222" }

        Rectangle { width: 200; height: 34; radius: 6; color: "#aaaaaa"
            Text { anchors.centerIn: parent; text: "Open Profile Settings"; color: "black" }
            MouseArea { anchors.fill: parent; onClicked: stackView.push("Profile.qml", { appsdata: Fn.appsdata, stackView: stackView }) }
        }
    }

    // small password prompt for protected profiles
    Rectangle {
        id: pwPrompt
        visible: false
        anchors.centerIn: parent
        width: parent.width * 0.7
        height: 120
        radius: 8
        color: "#111"
        border.color: "#444"
        property string path: ""
        function open(p) { path = p; visible = true }
        function close() { visible = false; passwordField.text = "" }
        Column { anchors.fill: parent; anchors.margins: 12; spacing: 8
            Text { text: "Enter password for profile"; color: "#ddd" }
            TextField { id: passwordField; placeholderText: "password"; echoMode: TextInput.Password; color: "#fff" }
            Row { spacing: 10; anchors.horizontalCenter: parent.horizontalCenter
                Rectangle { width: 90; height: 34; radius: 6; color: "#44aa44"
                    Text { anchors.centerIn: parent; text: "Open"; color: "white" }
                    MouseArea { anchors.fill: parent; onClicked: {
                        var content = Store.loadEncryptedProfile(path, passwordField.text)
                        if (!content || content === "") { showToast("Wrong password or failed to open") ; return }
                        var profile = Profile.parse(content)
                        Profile.apply(profile, root)
                        if (profile && profile.learning) Learning.Learning.apply(profile.learning)
                        Store.setLastProfilePath(path)
                        pwPrompt.close()
                        Log.info("Logged in with protected alias at: " + path)
                        stackView.push("AppsView.qml", { appsdata: Fn.appsdata, stackView: stackView })
                    }}
                }
                Rectangle { width: 90; height: 34; radius: 6; color: "#555"
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "#eee" }
                    MouseArea { anchors.fill: parent; onClicked: pwPrompt.close() }
                }
            }
        }
    }

    Component.onCompleted: {
        // if a signed-in alias exists, attempt to auto-login
        var alias = Store.signedInAlias()
        if (alias && alias.length) {
            Log.info("Auto-login attempt for alias: " + alias)
            var path = Store.appDataDir() + "/aliases/" + alias + ".json"
            if (Store.fileExists(path)) {
                if (Store.isEncryptedProfile(path)) {
                    pwPrompt.open(path)
                } else {
                    var data = Store.loadProfile(path)
                    var profile = Profile.parse(data)
                    Profile.apply(profile, login)
                    if (profile && profile.learning) Learning.Learning.apply(profile.learning)
                    Store.setLastProfilePath(path)
                    stackView.push("AppsView.qml", { appsdata: Fn.appsdata, stackView: stackView })
                }
            }
        }
    }

    // profile password prompt on profile settings page
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
            Text { text: "Enter password for alias"; color: "#ddd" }
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
                        try { var fn = path.replace(/.*\/(.*)\.json$/,'$1'); Store.setSignedInAlias(fn) } catch(e) {}
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
}
