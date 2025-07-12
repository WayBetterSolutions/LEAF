import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

RowLayout {
    id: colorField
    
    property alias text: textField.text
    property color currentColor: text || "#000000"
    
    signal colorUpdated()
    
    TextField {
        id: textField
        Layout.fillWidth: true
        placeholderText: "#000000"
        selectByMouse: true
        
        background: Rectangle {
            color: colors.surface
            border.color: colors.borderColor
            radius: 4
        }
        
        color: colors.primaryText
        
        validator: RegularExpressionValidator {
            regularExpression: /^#[0-9A-Fa-f]{6}$/
        }
        
        onTextChanged: {
            if (acceptableInput || text === "") {
                colorField.colorUpdated()
            }
        }
    }
    
    Rectangle {
        width: 40
        height: 30
        color: colorField.currentColor
        border.color: colors.borderColor
        border.width: 1
        radius: 4
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                colorPicker.currentColor = colorField.currentColor
                colorPicker.open()
            }
        }
    }
    
    // Simple color picker dialog
    Dialog {
        id: colorPicker
        title: "Pick Color"
        modal: true
        anchors.centerIn: parent
        width: 300
        height: 400
        
        property color currentColor: "#000000"
        
        background: Rectangle {
            color: colors.modalBackground
            border.color: colors.modalBorder
            radius: 8
        }
        
        onAccepted: {
            var hex = "#" + Math.floor(currentColor.r * 255).toString(16).padStart(2, '0') +
                            Math.floor(currentColor.g * 255).toString(16).padStart(2, '0') +
                            Math.floor(currentColor.b * 255).toString(16).padStart(2, '0')
            textField.text = hex
        }
        
        contentItem: ColumnLayout {
            spacing: 16
            
            // Color preview
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: colorPicker.currentColor
                border.color: colors.borderColor
                border.width: 1
                radius: 4
                
                Text {
                    anchors.centerIn: parent
                    text: "Preview"
                    color: colorPicker.currentColor.r + colorPicker.currentColor.g + colorPicker.currentColor.b > 1.5 ? "black" : "white"
                }
            }
            
            // RGB Sliders
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 8
                rowSpacing: 8
                
                Text { text: "R:"; color: colors.primaryText }
                Slider {
                    id: redSlider
                    Layout.fillWidth: true
                    from: 0; to: 1; value: colorPicker.currentColor.r
                    onValueChanged: colorPicker.updateColor()
                }
                Text { text: Math.round(redSlider.value * 255); color: colors.primaryText; Layout.minimumWidth: 30 }
                
                Text { text: "G:"; color: colors.primaryText }
                Slider {
                    id: greenSlider
                    Layout.fillWidth: true
                    from: 0; to: 1; value: colorPicker.currentColor.g
                    onValueChanged: colorPicker.updateColor()
                }
                Text { text: Math.round(greenSlider.value * 255); color: colors.primaryText; Layout.minimumWidth: 30 }
                
                Text { text: "B:"; color: colors.primaryText }
                Slider {
                    id: blueSlider
                    Layout.fillWidth: true
                    from: 0; to: 1; value: colorPicker.currentColor.b
                    onValueChanged: colorPicker.updateColor()
                }
                Text { text: Math.round(blueSlider.value * 255); color: colors.primaryText; Layout.minimumWidth: 30 }
            }
            
            // Hex input
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Hex:"
                    color: colors.primaryText
                }
                
                TextField {
                    id: hexField
                    Layout.fillWidth: true
                    text: "#" + Math.floor(colorPicker.currentColor.r * 255).toString(16).padStart(2, '0') +
                                Math.floor(colorPicker.currentColor.g * 255).toString(16).padStart(2, '0') +
                                Math.floor(colorPicker.currentColor.b * 255).toString(16).padStart(2, '0')
                    
                    background: Rectangle {
                        color: colors.surface
                        border.color: colors.borderColor
                        radius: 4
                    }
                    
                    color: colors.primaryText
                    selectByMouse: true
                    
                    validator: RegularExpressionValidator {
                        regularExpression: /^#[0-9A-Fa-f]{6}$/
                    }
                    
                    onTextChanged: {
                        if (acceptableInput) {
                            colorPicker.currentColor = text
                        }
                    }
                }
            }
            
            // Common colors
            GridLayout {
                Layout.fillWidth: true
                columns: 8
                
                property var commonColors: [
                    "#ff0000", "#00ff00", "#0000ff", "#ffff00", "#ff00ff", "#00ffff", "#ffffff", "#000000",
                    "#ff8080", "#80ff80", "#8080ff", "#ffff80", "#ff80ff", "#80ffff", "#c0c0c0", "#808080",
                    "#800000", "#008000", "#000080", "#808000", "#800080", "#008080", "#404040", "#202020"
                ]
                
                Repeater {
                    model: parent.commonColors
                    
                    Rectangle {
                        width: 25
                        height: 25
                        color: modelData
                        border.color: colors.borderColor
                        border.width: 1
                        radius: 2
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                colorPicker.currentColor = parent.color
                            }
                        }
                    }
                }
            }
        }
        
        onOpened: {
            redSlider.value = currentColor.r
            greenSlider.value = currentColor.g
            blueSlider.value = currentColor.b
        }
        
        function updateColor() {
            currentColor = Qt.rgba(redSlider.value, greenSlider.value, blueSlider.value, 1.0)
        }
        
        standardButtons: Dialog.Ok | Dialog.Cancel
    }
}