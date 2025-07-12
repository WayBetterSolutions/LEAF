import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs
import QtQuick.Layouts 1.15

Rectangle {
    id: themeEditor
    anchors.centerIn: parent
    width: Math.min(900, parent.width * 0.9)
    height: Math.min(700, parent.height * 0.9)
    
    visible: appState.modal === "themeEditor"
    focus: visible
    z: 300
    
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) {
            if (themeNameField.text.trim() !== "") {
                saveTheme()
                event.accepted = true
            }
        } else if (event.key === Qt.Key_Escape) {
            themeEditor.close()
            event.accepted = true
        }
    }
    
    color: colors.helpDialogBackground
    radius: 15
    border.color: colors.helpDialogBorder
    border.width: 3
    opacity: 0.95
    
    property string editingThemeKey: ""
    property bool isNewTheme: false
    property var editingTheme: ({})
    
    function openEditor(themeKey, isNew) {
        editingThemeKey = themeKey || ""
        isNewTheme = isNew || false
        
        if (isNew) {
            // Default new theme colors
            editingTheme = {
                name: "New Theme",
                background: "#1a1a1a",
                surface: "#2a2a2a", 
                primary: "#0078d4",
                primaryText: "#ffffff",
                secondaryText: "#cccccc",
                success: "#00cc00",
                error: "#ff0000"
            }
            themeNameField.text = "New Theme"
        } else {
            var theme = notesManager.getTheme(themeKey)
            editingTheme = theme
            themeNameField.text = theme.name || themeKey
        }
        
        // Update color fields
        backgroundColorField.text = editingTheme.background
        surfaceColorField.text = editingTheme.surface
        primaryColorField.text = editingTheme.primary
        primaryTextColorField.text = editingTheme.primaryText
        secondaryTextColorField.text = editingTheme.secondaryText
        successColorField.text = editingTheme.success
        errorColorField.text = editingTheme.error
        
        appState.modal = "themeEditor"
    }
    
    function close() {
        appState.modal = "none"
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
            
        // Header with help
        Column {
            Layout.fillWidth: true
            
            RowLayout {
                width: parent.width
                
                Text {
                    text: isNewTheme ? "Create New Theme" : "Edit Theme"
                    font.family: notesManager.config.fontFamily
                    font.pixelSize: 20
                    font.bold: true
                    color: colors.helpDialogText
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: "Escape: Cancel  •  Ctrl+Enter: Save"
                    font.family: notesManager.config.fontFamily
                    font.pixelSize: 10
                    color: colors.secondaryText
                }
            }
        }
            
            // Theme Name
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Theme Name:"
                    font.family: notesManager.config.fontFamily
                    color: colors.helpDialogText
                    Layout.minimumWidth: 120
                }
                
                TextField {
                    id: themeNameField
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: colors.helpDialogBackground
                        border.color: colors.helpDialogBorder
                        radius: 4
                    }
                    color: colors.helpDialogText
                    font.family: notesManager.config.fontFamily
                    selectByMouse: true
                }
            }
            
        // Color Fields
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 15
            rowSpacing: 10
                
                // Background Color
                Text {
                    text: "Background:"
                    font.family: notesManager.config.fontFamily
                    font.pixelSize: 12
                    color: colors.helpDialogText
                }
                ColorField {
                    id: backgroundColorField
                    Layout.fillWidth: true
                    onColorUpdated: updatePreview()
                }
                
                // Surface Color  
                Text {
                    text: "Surface:"
                    font.family: notesManager.config.fontFamily
                    font.pixelSize: 12
                    color: colors.helpDialogText
                }
                ColorField {
                    id: surfaceColorField
                    Layout.fillWidth: true
                    onColorUpdated: updatePreview()
                }
                
                // Primary Color
                Text {
                    text: "Primary:"
                    font.family: notesManager.config.fontFamily
                    font.pixelSize: 12
                    color: colors.helpDialogText
                }
                ColorField {
                    id: primaryColorField
                    Layout.fillWidth: true
                    onColorUpdated: updatePreview()
                }
                
                // Primary Text Color
                Text {
                    text: "Primary Text:"
                    font.family: notesManager.config.fontFamily
                    font.pixelSize: 12
                    color: colors.helpDialogText
                }
                ColorField {
                    id: primaryTextColorField
                    Layout.fillWidth: true
                    onColorUpdated: updatePreview()
                }
                
                // Secondary Text Color
                Text {
                    text: "Secondary Text:"
                    font.family: notesManager.config.fontFamily
                    font.pixelSize: 12
                    color: colors.helpDialogText
                }
                ColorField {
                    id: secondaryTextColorField
                    Layout.fillWidth: true
                    onColorUpdated: updatePreview()
                }
                
                // Success Color
                Text {
                    text: "Success:"
                    font.family: notesManager.config.fontFamily
                    font.pixelSize: 12
                    color: colors.helpDialogText
                }
                ColorField {
                    id: successColorField
                    Layout.fillWidth: true
                    onColorUpdated: updatePreview()
                }
                
                // Error Color
                Text {
                    text: "Error:"
                    font.family: notesManager.config.fontFamily
                    font.pixelSize: 12
                    color: colors.helpDialogText
                }
                ColorField {
                    id: errorColorField
                    Layout.fillWidth: true
                    onColorUpdated: updatePreview()
                }
            }
            
        // Preview Area
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            color: backgroundColorField.text || "#1a1a1a"
            border.color: primaryColorField.text || "#0078d4"
            border.width: 1
            radius: 8
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                
                // Header
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: Qt.darker(surfaceColorField.text || "#2a2a2a", 1.15)
                    radius: 0
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        
                        Text {
                            text: "My Notes"
                            font.family: notesManager.config.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                            color: primaryTextColorField.text || "#ffffff"
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        
                        Rectangle {
                            width: 60
                            height: 20
                            color: primaryColorField.text || "#0078d4"
                            radius: 4
                            
                            Text {
                                anchors.centerIn: parent
                                text: "New Note"
                                font.pixelSize: 8
                                color: Qt.darker(primaryColorField.text || "#0078d4", 1.8)
                            }
                        }
                    }
                }
                
                // Note Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: surfaceColorField.text || "#2a2a2a"
                    radius: 8
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                        
                        Text {
                            text: "Meeting Notes"
                            font.family: notesManager.config.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: primaryTextColorField.text || "#ffffff"
                            Layout.fillWidth: true
                        }
                        
                        Text {
                            text: "Discussed quarterly goals and project deadlines. Need to follow up on budget approval."
                            font.family: notesManager.config.fontFamily
                            font.pixelSize: 10
                            color: secondaryTextColorField.text || "#cccccc"
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.WordWrap
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            
                            Text {
                                text: "Today"
                                font.family: notesManager.config.fontFamily
                                font.pixelSize: 9
                                color: secondaryTextColorField.text || "#cccccc"
                            }
                            
                            Item { Layout.fillWidth: true }
                            
                            Rectangle {
                                width: 35
                                height: 16
                                color: successColorField.text || "#00cc00"
                                radius: 3
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    font.pixelSize: 8
                                    color: "white"
                                }
                            }
                            
                            Rectangle {
                                width: 35
                                height: 16
                                color: errorColorField.text || "#ff0000"
                                radius: 3
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "✗"
                                    font.pixelSize: 8
                                    color: "white"
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Action Buttons - moved outside preview
        RowLayout {
            Layout.fillWidth: true
            
            Item { Layout.fillWidth: true }
            
            Rectangle {
                width: 80
                height: 30
                color: Qt.darker(colors.surface, 1.4)
                border.color: Qt.darker(colors.surface, 2.0)
                radius: 4
                
                Text {
                    text: "Cancel"
                    anchors.centerIn: parent
                    color: colors.primaryText
                    font.family: notesManager.config.fontFamily
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: themeEditor.close()
                }
            }
            
            Rectangle {
                width: 80
                height: 30
                color: themeNameField.text.trim() !== "" ? Qt.darker(colors.primary, 1.2) : Qt.darker(colors.surface, 1.4)
                border.color: themeNameField.text.trim() !== "" ? Qt.darker(colors.primary, 2.0) : Qt.darker(colors.surface, 2.0)
                radius: 4
                opacity: themeNameField.text.trim() !== "" ? 1.0 : 0.5
                
                Text {
                    text: isNewTheme ? "Create" : "Save"
                    anchors.centerIn: parent
                    color: "white"
                    font.family: notesManager.config.fontFamily
                }
                
                MouseArea {
                    anchors.fill: parent
                    enabled: themeNameField.text.trim() !== ""
                    onClicked: if (enabled) saveTheme()
                }
            }
        }
    }
    
    function updatePreview() {
        // Force property binding updates
    }
    
    function saveTheme() {
        var key = editingThemeKey
        if (isNewTheme) {
            // Generate a key from the name
            key = themeNameField.text.toLowerCase().replace(/[^a-z0-9]/g, '')
            if (!key) key = "customTheme" + Date.now()
        }
        
        var success = false
        if (isNewTheme) {
            success = colors.createTheme(
                key,
                themeNameField.text,
                backgroundColorField.text,
                surfaceColorField.text,
                primaryColorField.text,
                primaryTextColorField.text,
                secondaryTextColorField.text,
                successColorField.text,
                errorColorField.text
            )
        } else {
            success = colors.updateTheme(
                key,
                themeNameField.text,
                backgroundColorField.text,
                surfaceColorField.text,
                primaryColorField.text,
                primaryTextColorField.text,
                secondaryTextColorField.text,
                successColorField.text,
                errorColorField.text
            )
        }
        
        if (success) {
            // Apply the new/updated theme
            colors.setTheme(key)
            notesManager.setTheme(key)
            themeEditor.close()
        }
    }
}