// Colors.qml
import QtQuick 2.15

QtObject {
    property string currentTheme: "nightOwl"
    property var themes: ({})
    
    // Load themes from backend on startup
    Component.onCompleted: {
        if (typeof notesManager !== 'undefined') {
            loadThemes()
            // Set current theme from config
            var savedTheme = notesManager.getCurrentTheme()
            if (savedTheme && themes[savedTheme]) {
                currentTheme = savedTheme
            }
        }
    }
    
    // Theme reloading will be handled manually when needed
    
    function loadThemes() {
        if (typeof notesManager !== 'undefined') {
            var allThemes = notesManager.getAllThemes()
            themes = allThemes || {}
        }
    }
    
    property var currentColors: themes[currentTheme] || {
        background: "#0d1117",
        surface: "#21262d", 
        primary: "#58a6ff",
        primaryText: "#f0f6fc",
        secondaryText: "#7d8590",
        success: "#238636",
        error: "#f85149"
    }
    
    property color background: currentColors.background
    property color surface: currentColors.surface
    property color primary: currentColors.primary
    property color primaryText: currentColors.primaryText
    property color secondaryText: currentColors.secondaryText
    property color success: currentColors.success
    property color error: currentColors.error
    
    property color hoverColor: Qt.lighter(surface, 1.15)
    property color selectedColor: Qt.lighter(surface, 1.25)
    property color borderColor: Qt.lighter(surface, 1.2)
    property color searchBarColor: surface
    property color headerBgColor: Qt.darker(surface, 1.15)
    
    property color placeholderColor: Qt.rgba(secondaryText.r, secondaryText.g, secondaryText.b, 0.6)
    property color selectedTextColor: Qt.lighter(primaryText, 1.1)
    property color selectedSecondaryTextColor: Qt.lighter(secondaryText, 1.1)
    
    property color overlayColor: Qt.rgba(background.r, background.g, background.b, 0.9)
    property color modalBackground: surface
    property color modalBorder: primary
    
    property color cardColor: surface
    property color textColor: primaryText
    property color accentColor: primary
    property color buttonTextColor: primaryText
    property color buttonBorderColor: borderColor
    property color deleteButtonColor: error
    property color successColor: success
    property color focusBorderColor: primary
    property color searchBarTextColor: primaryText
    property color notificationTextColor: primaryText
    property color transparentColor: "transparent"
    
    property color editorBackground: background
    property color editorFocusBorder: primary
    property color helpDialogBackground: surface
    property color helpDialogBorder: primary
    property color helpDialogText: primaryText
    property color confirmationDialogBackground: surface
    property color confirmationDialogBorder: primary
    
    function setTheme(themeName) {
        if (themes[themeName]) {
            currentTheme = themeName
        }
    }
    
    function getAvailableThemes() {
        if (typeof notesManager !== 'undefined') {
            return notesManager.getAvailableThemes()
        }
        return Object.keys(themes)
    }
    
    function getThemeDisplayName(themeName) {
        var theme = themes[themeName]
        return theme ? (theme.name || themeName) : themeName
    }
    
    function getCurrentThemeName() {
        return getThemeDisplayName(currentTheme)
    }
    
    function getAllThemeInfo() {
        var themeList = []
        var availableThemes = getAvailableThemes()
        
        for (var i = 0; i < availableThemes.length; i++) {
            var themeName = availableThemes[i]
            themeList.push({
                "key": themeName,
                "displayName": getThemeDisplayName(themeName)
            })
        }
        return themeList
    }
    
    // New theme management functions
    function createTheme(key, name, background, surface, primary, primaryText, secondaryText, success, error) {
        if (typeof notesManager !== 'undefined') {
            var result = notesManager.createTheme(key, name, background, surface, primary, primaryText, secondaryText, success, "#ffaa00", error)
            if (result) {
                loadThemes()
            }
            return result
        }
        return false
    }
    
    function updateTheme(key, name, background, surface, primary, primaryText, secondaryText, success, error) {
        if (typeof notesManager !== 'undefined') {
            var result = notesManager.updateTheme(key, name, background, surface, primary, primaryText, secondaryText, success, "#ffaa00", error)
            if (result) {
                loadThemes()
            }
            return result
        }
        return false
    }
    
    function deleteTheme(key) {
        if (typeof notesManager !== 'undefined') {
            var result = notesManager.deleteTheme(key)
            if (result) {
                loadThemes()
            }
            return result
        }
        return false
    }
    
    function renameTheme(key, newName) {
        if (typeof notesManager !== 'undefined') {
            var result = notesManager.renameTheme(key, newName)
            if (result) {
                loadThemes()
            }
            return result
        }
        return false
    }
    
}