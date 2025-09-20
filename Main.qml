import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "utils"
import "profile.js" as Profile
import "keydata.js" as Fn
import "learningState.js" as Learning

ApplicationWindow {
    id: mainWindow
    width: 400
    height: 600
    visible: true
    title: "VS Code Shortcuts"

    StackView {
           id: stackView
           anchors.fill: parent
           initialItem: AppsView {
               appsdata: Fn.appsdata
               stackView: stackView
           }
       }

    // user initialization & auto reopen
    Component.onCompleted: {
        var p = Store.lastProfilePath()
        if (Store.fileExists(p)) {
            var data = Store.loadProfile(p)
            var prof = Profile.parse(data)
            // we only keep learning map here; can be used by pages that accept it
            if (prof && prof.learning) {
                Learning.Learning.apply(prof.learning)
            }
        } else {
            // create a default profile automatically on first run
            var payload = Profile.collect(Fn.appsdata, Learning.Learning.getAll())
            var ok = Store.saveProfile(Store.defaultProfilePath(), Profile.stringify(payload))
            if (ok) Store.setLastProfilePath(Store.defaultProfilePath())
        }
    }
}


