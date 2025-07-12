// Colors.qml
import QtQuick 2.15

QtObject {
    property string currentTheme: "nightOwl"
    
    property var themes: ({
        "nightOwl": {
            background: "#011627",
            surface: "#1d3b53",
            primary: "#c792ea",
            primaryText: "#d6deeb",
            secondaryText: "#7fdbca",
            success: "#addb67",
            warning: "#ffcb6b",
            error: "#ef5350"
        },
        "dracula": {
            background: "#282a36",
            surface: "#44475a",
            primary: "#bd93f9",
            primaryText: "#f8f8f2",
            secondaryText: "#6272a4",
            success: "#50fa7b",
            warning: "#f1fa8c",
            error: "#ff5555"
        },
        "monokai": {
            background: "#272822",
            surface: "#3e3d32",
            primary: "#f92672",
            primaryText: "#f8f8f2",
            secondaryText: "#75715e",
            success: "#a6e22e",
            warning: "#e6db74",
            error: "#f92672"
        },
        "githubDark": {
            background: "#0d1117",
            surface: "#21262d",
            primary: "#58a6ff",
            primaryText: "#f0f6fc",
            secondaryText: "#7d8590",
            success: "#238636",
            warning: "#d29922",
            error: "#f85149"
        },
        "catppuccin": {
            background: "#1e1e2e",
            surface: "#313244",
            primary: "#cba6f7",
            primaryText: "#cdd6f4",
            secondaryText: "#f9e2af",
            success: "#a6e3a1",
            warning: "#fab387",
            error: "#f38ba8"
        },
        "tokyoNight": {
            background: "#1a1b26",
            surface: "#24283b",
            primary: "#7aa2f7",
            primaryText: "#c0caf5",
            secondaryText: "#9ece6a",
            success: "#9ece6a",
            warning: "#e0af68",
            error: "#f7768e"
        },
        "nordDark": {
            background: "#2e3440",
            surface: "#3b4252",
            primary: "#88c0d0",
            primaryText: "#eceff4",
            secondaryText: "#d08770",
            success: "#a3be8c",
            warning: "#ebcb8b",
            error: "#bf616a"
        },
        "gruvboxDark": {
            background: "#282828",
            surface: "#3c3836",
            primary: "#83a598",
            primaryText: "#ebdbb2",
            secondaryText: "#fe8019",
            success: "#b8bb26",
            warning: "#fabd2f",
            error: "#fb4934"
        },
        "oneDark": {
            background: "#1e2127",
            surface: "#2c323c",
            primary: "#61afef",
            primaryText: "#abb2bf",
            secondaryText: "#e06c75",
            success: "#98c379",
            warning: "#e5c07b",
            error: "#e06c75"
        },
        "materialDark": {
            background: "#121212",
            surface: "#1e1e1e",
            primary: "#bb86fc",
            primaryText: "#ffffff",
            secondaryText: "#03dac6",
            success: "#4caf50",
            warning: "#ff9800",
            error: "#f44336"
        },
        "ayuDark": {
            background: "#0a0e14",
            surface: "#1f2430",
            primary: "#ffb454",
            primaryText: "#b3b1ad",
            secondaryText: "#e6b450",
            success: "#c2d94c",
            warning: "#ffb454",
            error: "#f07178"
        },
        "forest": {
            background: "#1a2319",
            surface: "#2d3b2c",
            primary: "#7ec699",
            primaryText: "#e8f2e8",
            secondaryText: "#a8c9a8",
            success: "#90d4a0",
            warning: "#d4b85a",
            error: "#d97a7a"
        }
    })
    
    property var currentColors: themes[currentTheme] || themes["nightOwl"]
    
    property color background: currentColors.background
    property color surface: currentColors.surface
    property color primary: currentColors.primary
    property color primaryText: currentColors.primaryText
    property color secondaryText: currentColors.secondaryText
    property color success: currentColors.success
    property color warning: currentColors.warning
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
    property color warningColor: warning
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
        return Object.keys(themes)
    }
    
    function getThemeDisplayName(themeName) {
        var displayNames = {
            "nightOwl": "Night Owl",
            "dracula": "Dracula",
            "monokai": "Monokai",
            "githubDark": "GitHub Dark",
            "catppuccin": "Catppuccin",
            "tokyoNight": "Tokyo Night",
            "nordDark": "Nord Dark",
            "gruvboxDark": "Gruvbox Dark",
            "oneDark": "One Dark",
            "materialDark": "Material Dark",
            "ayuDark": "Ayu Dark",
            "forest": "Forest"
        }
        return displayNames[themeName] || themeName
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
}