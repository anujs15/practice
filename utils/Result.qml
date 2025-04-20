import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Shapes
import QtQuick.Controls 2.15

Rectangle{
     id:root
     anchors.fill: parent
     color:"black"
     visible: true

     required property StackView stackView
     required property var attemptedKeys
     required property int count
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

    Component.onCompleted: updateKeyCounts()
    onAttemptedKeysChanged: updateKeyCounts()

    Rectangle{
             height:70
             width:70
             Text {
                      text: `${wrongkey} + ${correctkey}`
                      color:"black"
             }
    }

     Shape{
         id:shape

         property real progress: 0.0
         anchors.centerIn: parent
         width:200
         height:200

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
        to:wrongkey/attemptedKeys.length
        duration: 3000
        running: true
    }
}

