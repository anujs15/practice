import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Shapes 1.15
import QtQuick.Controls 2.15
import "../learningState.js" as Learning
import "../Logging.js" as Log

Rectangle{
     id:root
     anchors.fill: parent
     color:"black"
     visible: true

     // make properties optional and provide safe defaults so component can instantiate
     property var appsdata: ({ test: [], shortcuts: [], sets: [], title: "", appicon: "", id: "" })
     property var stackView: null
     property var attemptedKeys: []
     property int correctkey: 0
     property int wrongkey: 0

     function updateKeyCounts() {
         let correct = 0;
         let wrong = 0;
         for (let i = 0; i < attemptedKeys.length; i++) {
             if (attemptedKeys[i].correct === true) correct++;
             if (attemptedKeys[i].attempt === true && attemptedKeys[i].correct === false) wrong++;
         }
         correctkey = correct;
         wrongkey = wrong;
     }

    Component.onCompleted: {
        if ((!attemptedKeys || attemptedKeys.length === 0) && appsdata && appsdata.id) {
            var map = Learning.Learning.getAll()
            if (map && map[appsdata.id]) attemptedKeys = map[appsdata.id]
        }
        updateKeyCounts()
        Log.info("Result page opened for app: " + (appsdata && appsdata.id ? appsdata.id : "unknown"))
    }

     Shape{
         id:shape

         property real progress: 0.0
         anchors.centerIn: parent
         width:300
         height:300

         smooth:true
         antialiasing: true
         ShapePath{
             strokeWidth: 30
             fillColor: root.color
             strokeColor: "#7cfc00"

             PathAngleArc{
                 centerX: shape.width/2
                 centerY: shape.height/2
                 radiusX: shape.width/2
                 radiusY: shape.height/2

                 startAngle: -90
                 sweepAngle: shape.progress*360
             }
         }
         Text {
             anchors.centerIn: parent
             font{
                 pointSize: 14
                 weight: Font.DemiBold
             }

             text: (shape.progress*100).toFixed(0)+"%"
             color: "white"
         }
     }
    NumberAnimation{
        target: shape
        property: "progress"
        from: 0.0
        to: (attemptedKeys && attemptedKeys.length > 0) ? (correctkey/attemptedKeys.length) : 0.0
        duration: 3000
        running: true
    }

    Row {
          visible: true
          spacing: parent.width/3
          anchors{
                bottom: parent.bottom
                bottomMargin: parent.height/10
                horizontalCenter: parent.horizontalCenter
            }
         Text {
                id: correct
                text: "Correct: " + correctkey
                font.bold: true
                font.pixelSize: 25
                color:"green"
             }
         Text {
                id: wrong
                text: "Wrong: " + wrongkey
                font.bold: true
                font.pixelSize: 25
                color:"red"
             }
       Text {
              id: notattempt
              text: "Notattempt: " + ((attemptedKeys ? attemptedKeys.length : 0) - wrongkey - correctkey)
              font.bold: true
              font.pixelSize: 25
              color:"yellow"
             }
       }

}


