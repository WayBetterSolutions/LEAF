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
    
    // Helper function to format shortcuts with full key names
    function formatShortcut(shortcut) {
        if (Array.isArray(shortcut)) {
            return shortcut.map(function(key) {
                return formatSingleKey(key)
            }).join(" | ")
        } else {
            return formatSingleKey(shortcut)
        }
    }
    
    function formatSingleKey(key) {
        // Convert shorthand to symbols and full key names
        return key.replace(/Up/g, "↑")
                 .replace(/Down/g, "↓") 
                 .replace(/Left/g, "←")
                 .replace(/Right/g, "→")
                 .replace(/Return/g, "Enter")
                 .replace(/Escape/g, "Escape")
                 .replace(/Page_Up/g, "Page Up")
                 .replace(/Page_Down/g, "Page Down")
                 .replace(/Delete/g, "Delete")
                 .replace(/Home/g, "Home")
                 .replace(/End/g, "End")
                 .replace(/Space/g, "Spacebar")
                 .replace(/Tab/g, "Tab")
    }
    
    Text {
        text: label
        // Use system default font for maximum legibility
        font.pixelSize: fontSize
        color: colors.helpDialogText
        width: parent.width * 0.65  
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        wrapMode: Text.NoWrap
    }
    
    Text {
        text: formatShortcut(shortcut)
        // Use system default font for maximum legibility
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