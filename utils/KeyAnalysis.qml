import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../learningState.js" as Learning
import "../Logging.js" as Log

pragma ComponentBehavior: Bound

Rectangle {
    id: main
    color: "#000000"
    property var appsdata: ({ test: [], shortcuts: [], sets: [], title: "", appicon: "", id: "" })
    property var stackView: null
    property var attemptedKeys: []
    Component.onCompleted: {
        Log.info("KeyAnalysis opened")
        if ((!attemptedKeys || attemptedKeys.length === 0) && appsdata && appsdata.id) {
            var map = Learning.Learning.getAll()
            if (map && map[appsdata.id]) attemptedKeys = map[appsdata.id]
        }
    }

    Button {
        id: backButton
        text: "Back"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        onClicked: main.stackView.pop()
    }

    Rectangle {
        id: content
        color: "black"
        width: parent.width / 1.2
        anchors {
            top: backButton.bottom
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            topMargin: backButton.height / 1.2
            bottomMargin: backButton.height
        }

        Rectangle {
            id: logo
            width: parent.width
            height: parent.height / 7
            color: "black"

            Image {
                id: applogo
                source: main.appsdata.appicon
                height: parent.height * 0.8
                fillMode: Image.PreserveAspectFit
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                id: appname
                text: main.appsdata.title
                color: "white"
                font { pixelSize: applogo.height / 2; bold: true }
                anchors {
                    left: applogo.right
                    leftMargin: applogo.width / 10
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle {
            id: test
            width: parent.width
            height: logo.height / 1.2
            color: "#070707"
            radius: 7
            anchors {
                top: logo.bottom
            }

            Text {
                id: response
                text: "Your response"
                color: "#969292"
                font { pixelSize: parent.height / 5; bold: true }
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    rightMargin: parent.width/40
                    bottomMargin: parent.height / 5
                }
            }

            Text {
                id: sequence
                text: "Correct Sequence"
                color: "#969292"
                font { pixelSize: parent.height / 5; bold: true }
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: parent.height / 5
                }
            }

            Text {
                id: keysets
                text: "KeySets"
                color: "#969292"
                font { pixelSize: parent.height / 5; bold: true }
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    leftMargin: parent.width/40
                    bottomMargin: parent.height / 5
                }
            }
        }

        Rectangle {
            color: "#070707"
            radius: 7
            anchors {
                top: test.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }

            ListView {
                id: listView
                model: main.appsdata.test
                spacing: 3
                clip: true
                anchors.fill: parent

                delegate: Rectangle {
                    id: delegateRect
                    required property int index
                    required property var modelData
                    width: listView.width
                    height: 70
                    color: "#808080"
                    radius: 10

                    property int currentIndex: index

                    Row {
                        anchors.fill: parent
                        spacing: 10

                        // Title text with color depending on correctness

                        Text {
                            anchors{
                                left: parent.left
                                leftMargin: parent.width/40
                                verticalCenter: parent.verticalCenter
                            }
                            text: delegateRect.modelData.title
                            property var ak: (main.attemptedKeys && main.attemptedKeys.length > delegateRect.currentIndex) ? main.attemptedKeys[delegateRect.currentIndex] : {attempt:false, correct:false, keypressed:[], color:[]}
                            color: ak.correct ? "green" : ak.attempt ? "red" : "#222222"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        // Correct sequence keys
                        Row {
                            spacing: 10
                            anchors{
                                horizontalCenter: parent.horizontalCenter
                                 verticalCenter: parent.verticalCenter
                            }
                            Repeater {
                                model: delegateRect.modelData.keys
                                delegate: Rectangle {
                                    required property var modelData
                                    width: 60
                                    height: 40
                                    color: "white"
                                    border.color: "black"
                                    border.width: 2
                                    radius: 10

                                    Text {
                                        anchors.centerIn: parent
                                        font.pointSize: 14
                                        color: "black"
                                        text: parent.modelData
                                    }
                                }
                            }
                        }

                        // Attempted keys with badges
                        Row {
                            spacing: 10
                            anchors{
                                right: parent.right
                                rightMargin: parent.width/40
                                 verticalCenter: parent.verticalCenter
                            }

                            Repeater {
                                property var akLocal: (main.attemptedKeys && main.attemptedKeys.length > delegateRect.currentIndex) ? main.attemptedKeys[delegateRect.currentIndex] : {attempt:false, correct:false, keypressed:[], color:[]}
                                model: akLocal.keypressed
                                 delegate: Rectangle {
                                     id: attemptedKeyRect
                                     required property int index
                                     required property var modelData
                                     width: 60
                                     height: 40
                                     color: "white"
                                     border.color: "black"
                                     border.width: 2
                                     radius: 10
                                     
                                     property string badgeColor: {
                                         var akLocal = (main.attemptedKeys && main.attemptedKeys.length > delegateRect.currentIndex) ? main.attemptedKeys[delegateRect.currentIndex] : {attempt:false, correct:false, keypressed:[], color:[]}
                                         return (akLocal.color && akLocal.color.length > index) ? akLocal.color[index] : "gray"
                                     }

                                    Text {
                                        anchors.centerIn: parent
                                        font.pointSize: 14
                                        color: "black"
                                        text: parent.modelData
                                    }

                                    Rectangle {
                                        visible: parent.badgeColor === "green" || parent.badgeColor === "red"
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.rightMargin: -5
                                        anchors.topMargin: -5
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: parent.badgeColor

                                        Text {
                                            anchors.centerIn: parent
                                            font.pointSize: 12
                                            color: "white"
                                            text: attemptedKeyRect.badgeColor === "green" ? "✓" : "✗"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 8
                    contentItem: Rectangle {
                        color: "gray"
                        implicitWidth: 6
                        radius: 3
                    }
                }
            }
        }
    }
}

