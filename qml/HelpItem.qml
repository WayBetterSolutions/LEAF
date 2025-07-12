import QtQuick 2.15
import QtQuick.Controls 2.15

Row {
    property string label: ""
    property string shortcut: ""
    property real itemHeight: 22
    property real fontSize: 12
    property var colors
    
    spacing: 3  
    width: parent ? parent.width : 0
    height: itemHeight
    
    Text {
        text: label
        font.family: notesManager.config.fontFamily
        font.pixelSize: fontSize
        color: colors.helpDialogText
        width: parent.width * 0.65  
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        wrapMode: Text.NoWrap
    }
    
    Text {
        text: shortcut
        font.family: notesManager.config.fontFamily
        font.pixelSize: fontSize
        font.bold: true
        color: colors.helpDialogText
        width: parent.width * 0.27  
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        wrapMode: Text.NoWrap
        horizontalAlignment: Text.AlignLeft
    }
}