import QtQuick 2.15
import QtQuick.Controls 2.15
import "../Logging.js" as Log
import "../learningState.js" as Learning

Page {
    id: shortcutPage

    property var appsdata: ({ test: [], shortcuts: [], sets: [], title: "", appicon: "", id: "" })
    property var stackView: null

    background: Rectangle{
        color: "black"
    }

    property int currentIndex: 0
    property var activeKeys: ({})
    property var expectedSequence: []
    property int currentStep: 0
    property var keyColors: []
    property var keyText: []
    property var attemptedKeys: []
    property int count:1
    property bool skipright:true
    // allow CategoryView to pass and read done counts
    property int donecount: 0

    Button {
        id: backButton
        text: "Back"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        onClicked: stackView.pop()
    }

    Component.onCompleted: {
        resetSequence()
        try { attemptedKeys = (Learning && Learning.getAll && Learning.getAll()[appsdata && appsdata.id]) ? Learning.getAll()[appsdata.id] : [] } catch(e) { attemptedKeys = [] }
        keyHandler.forceActiveFocus()
        Log.info("ShortcutView opened for: " + (appsdata && appsdata.title ? appsdata.title : "unknown"))
    }

    function resetSequence() {
        currentStep = 0
        activeKeys = {}
        if (!appsdata || !appsdata.shortcuts || appsdata.shortcuts.length === 0) {
            expectedSequence = []
            keyColors = []
            keyText = []
            return
        }
        // ensure currentIndex in range
        if (currentIndex < 0) currentIndex = 0
        if (currentIndex >= appsdata.shortcuts.length) currentIndex = appsdata.shortcuts.length - 1
        expectedSequence = appsdata.shortcuts[currentIndex].keys
        keyColors = new Array(expectedSequence.length).fill("white")
        keyText = new Array(expectedSequence.length).fill("")
    }

    function checkKeyPress(event) {
        const currentKey = expectedSequence[currentStep]

        let keyMatch = false

        if (currentKey === "Ctrl") {
            keyMatch = event.modifiers & Qt.ControlModifier
        } else if (currentKey === "Shift") {
            keyMatch = event.modifiers & Qt.ShiftModifier
        } else if (currentKey === "Enter") {
            keyMatch = (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
        } else if (currentKey === "Alt") {
            keyMatch = event.modifiers & Qt.AltModifier
        }else if (currentKey === "PageDown") {
            keyMatch = event.key === Qt.Key_PageDown
        }else if (currentKey === "PageUp") {
            keyMatch = event.key === Qt.Key_PageUp
        }else if (currentKey === "Space") {
            keyMatch = event.key === Qt.Key_Space
        }else if (currentKey === "Tab") {
            keyMatch = event.key === Qt.Key_Tab
         }else if (currentKey === "Backtab") {
             keyMatch = event.key === Qt.Key_Backtab
         }else if (currentKey === "Backspace") {
             keyMatch = event.key === Qt.Key_Backspace
         }else if (currentKey === "Delete") {
             keyMatch = event.key === Qt.Key_Delete
         }else if (currentKey === "Insert") {
             keyMatch = event.key === Qt.Key_Insert
         }else if (currentKey === "Home") {
             keyMatch = event.key === Qt.Key_Home
         }else if (currentKey === "End") {
             keyMatch = event.key === Qt.Key_End
         }else if (currentKey === "Up") {
             keyMatch = event.key === Qt.Key_Up
         }else if (currentKey === "Down") {
             keyMatch = event.key === Qt.Key_Down
         }else if (currentKey === "F1") {
             keyMatch = event.key === Qt.Key_F1
         }else if (currentKey === "F2") {
             keyMatch = event.key === Qt.Key_F2
         }else if (currentKey === "F3") {
             keyMatch = event.key === Qt.Key_F3
         }else if (currentKey === "F4") {
             keyMatch = event.key === Qt.Key_F4
         }else if (currentKey === "F5") {
             keyMatch = event.key === Qt.Key_F5
         }else if (currentKey === "F6") {
             keyMatch = event.key === Qt.Key_F6
         }else if (currentKey === "F7") {
             keyMatch = event.key === Qt.Key_F7
         }else if (currentKey === "F8") {
             keyMatch = event.key === Qt.Key_F8
         }else if (currentKey === "F9") {
             keyMatch = event.key === Qt.Key_F9
         }else if (currentKey === "F10") {
             keyMatch = event.key === Qt.Key_F10
         }else if (currentKey === "F11") {
             keyMatch = event.key === Qt.Key_F11
         }else if (currentKey === "F12") {
             keyMatch = event.key === Qt.Key_F12
         }else {
             keyMatch = event.key === currentKey.charCodeAt(0)
         }

         return keyMatch && !activeKeys[currentKey]
     }

    Rectangle {
        id: keyHandler
        anchors.fill: parent
        focus: true
        color: "transparent"
        Keys.enabled: true

        Keys.onPressed: function(event) {
            if (event.isAutoRepeat) return

            if (event.key === Qt.Key_Escape) {
                if(stackView) stackView.pop()
                event.accepted=true
                return
            } else if(event.key === Qt.Key_Right && currentStep==0) {
                skipRight()
            } else if(event.key === Qt.Key_Left && currentStep==0) {
                skipLeft()
            } else {
                const currentKey = expectedSequence[currentStep]

                var newColors = keyColors.slice()
                newColors[currentStep] = checkKeyPress(event) ? "green" : "red"
                keyColors = newColors
                activeKeys[currentKey] = true
                currentStep++

                if (currentStep === expectedSequence.length) {
                    var isallkeys=keyColors.includes("red")
                       if(!isallkeys){
                            showResult(true)
                           nextShortcutTimer.start()
                        }
                       else{
                           showResult(false)
                           resetTimer.start()
                       }
                       Log.info("Shortcut attempt result: app=" + (appsdata && appsdata.title ? appsdata.title : "unknown") + ", index=" + currentIndex + ", success=" + (!isallkeys))
                       event.accepted = true
                }
            }
        }

        Keys.onReleased: function(event) {
            const releasedKey = Object.keys(activeKeys).find(key =>
                (key === "Ctrl" && !(event.modifiers & Qt.ControlModifier)) ||
                (key === "Shift" && !(event.modifiers & Qt.ShiftModifier)) ||
                (key === "Alt" && !(event.modifiers & Qt.AltModifier)) ||
                (key === "Enter" && (event.key === Qt.Key_Enter || event.key===Qt.Key_Return)) ||
                (event.key === key.charCodeAt(0))
            )

            if((event.key=== Qt.Key_Right || event.key=== Qt.Key_Left) && currentStep==0) {
                resetSequence()
            }else if (!releasedKey && currentStep === expectedSequence.length) {
                delete activeKeys[releasedKey]
            } else if (releasedKey) {
                delete activeKeys[releasedKey]
                if (currentStep > 0 && currentStep < expectedSequence.length) {
                    resetSequence()
                }
            }
             else {
                delete activeKeys[releasedKey]
                resetSequence()
            }
        }

        // count store
        Rectangle{
            id:countstore
            height:50
            width: 50
            color:"black"

            anchors{
                right: parent.right
                top:parent.top
                rightMargin: 40
                topMargin: 40
            }

            Text {
                id: text
                font.pointSize: 18
                anchors.centerIn: parent
                text:  shortcutPage.count + "/" + ((shortcutPage.appsdata && shortcutPage.appsdata.shortcuts) ? shortcutPage.appsdata.shortcuts.length : 0)
                color: "white"
            }
        }

        // Column layout -- replace malformed block with a clean, anchor-safe Column
        Column {
            id: main
            width: parent.width
            height: parent.height
            spacing: 40
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 0
            }

            // spacer to provide top offset safely inside Column
            Item { height: parent.height / 3 }

            Text {
                id: keydes
                text: appsdata.shortcuts && appsdata.shortcuts[currentIndex] ? appsdata.shortcuts[currentIndex].title : ""
                color: (shortcutPage.keyColors && shortcutPage.keyColors[shortcutPage.currentIndex] && shortcutPage.keyColors[shortcutPage.currentIndex] === "green") ? "black" : (shortcutPage.attemptedKeys && shortcutPage.attemptedKeys[shortcutPage.currentIndex] && shortcutPage.attemptedKeys[shortcutPage.currentIndex].attempt ? "gray" : "white")
                font { pixelSize: 48; bold: true }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                id: keycol
                spacing: 30
                anchors.horizontalCenter: keydes.horizontalCenter

                Repeater {
                    model: (appsdata && appsdata.shortcuts && appsdata.shortcuts[currentIndex]) ? appsdata.shortcuts[currentIndex].keys : []
                    delegate: Rectangle {
                        id: keyrect
                        // expose a local index to satisfy linters and make bindings explicit
                        property int idx: index
                        width: (shortcutPage.keyColors && shortcutPage.keyColors[idx] === "green") ? 70 : (shortcutPage.keyColors && shortcutPage.keyColors[idx] === "red") ? 70 : 60
                        height: (shortcutPage.keyColors && shortcutPage.keyColors[idx] === "green") ? 50 : (shortcutPage.keyColors && shortcutPage.keyColors[idx] === "red") ? 50 : 40
                        color: (shortcutPage.keyColors && shortcutPage.keyColors[idx]) ? ((shortcutPage.keyColors[idx] === "green" || shortcutPage.keyColors[idx] === "red") ? "white" : "black") : "black"
                        border.color: (shortcutPage.keyColors && shortcutPage.keyColors[idx]) ? ((shortcutPage.keyColors[idx] === "green" || shortcutPage.keyColors[idx] === "red") ? "white" : "gray") : "gray"
                         border.width: 2
                         radius: 10

                        Text {
                            anchors.centerIn: parent
                            font.pointSize: 14
                            color: (shortcutPage.keyColors && shortcutPage.keyColors[idx] && (shortcutPage.keyColors[idx] === "green" || shortcutPage.keyColors[idx] === "red")) ? "black" : "gray"
                            text: modelData ? modelData : ""
                        }

                        Rectangle {
                            id: statusBadge
                            // make parent property reference explicit to avoid scope issues
                            property int idxLocal: keyrect.idx
                            visible: shortcutPage.keyColors && (shortcutPage.keyColors[statusBadge.idxLocal] === "green" || shortcutPage.keyColors[statusBadge.idxLocal] === "red")
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.rightMargin: -5
                            anchors.topMargin: -5
                            width: 18; height: 18; radius: 9
                            color: (shortcutPage.keyColors && shortcutPage.keyColors[statusBadge.idxLocal] === "green") ? "green" : "red"
                            Text { anchors.centerIn: parent; font.pointSize: 14; color: "black"; text: (shortcutPage.keyColors && shortcutPage.keyColors[statusBadge.idxLocal] === "green") ? "✓" : "✗" }
                        }
                    }
                }
            }

            // result area - wrapped in Item so anchors inside are valid
            Item {
                id: resultWrapper; width: parent.width; height: parent.height / 6
                Text {
                    id: resultDisplay
                    text: ""
                    color: "white"
                    font.pixelSize: 24
                    anchors.right: parent.right
                    anchors.rightMargin: (parent.width/3)
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
     }

    Timer {
            id: resetTimer
            interval: 500
            onTriggered: {
                currentStep = 0
                activeKeys = {}
                keyColors = new Array(appsdata.shortcuts[currentIndex].keys.length).fill("white")
                expectedSequence = appsdata.shortcuts[currentIndex].keys
                resultDisplay.opacity = 0
            }
    }

    Timer {
        id: nextShortcutTimer
        interval: 1500
        onTriggered: advanceShortcut()
    }

    Timer {
        id: errorResetTimer
        interval: 1000
        onTriggered: resultDisplay.opacity = 0
    }

    function skipRight()
    {
        if (!appsdata || !appsdata.shortcuts || appsdata.shortcuts.length === 0) return
        currentIndex = (currentIndex + 1) < appsdata.shortcuts.length ? currentIndex + 1 : (appsdata.shortcuts.length - 1)
        count = (((count + 1) < appsdata.shortcuts.length + 1)) ? count + 1 : appsdata.shortcuts.length
        resetSequence()
    }

    function skipLeft()
    {
        if (!appsdata || !appsdata.shortcuts || appsdata.shortcuts.length === 0) return
        currentIndex = (currentIndex - 1) >= 0 ? currentIndex - 1 : 0
        count=(count - 1)>0?count-1:1
        resetSequence()
    }

    function advanceShortcut() {
        currentIndex = (currentIndex + 1) % appsdata.shortcuts.length
        count=(((count + 1) % (appsdata.shortcuts.length+1))==0)?1:count+1
        resetSequence()
        resultDisplay.opacity = 0
    }

    function showResult(success) {
         resultDisplay.text = success ? "✓ Correct!" : "✗ Try Again!"
         resultDisplay.color = success ? "green" : "red"
         resultDisplay.opacity = 1
         if (!success) errorResetTimer.restart()
     }
}











