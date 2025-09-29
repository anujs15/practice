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
           initialItem: Login {
               stackView: stackView
           }
       }

    // app startup and profile loading are handled by the Login page
}


