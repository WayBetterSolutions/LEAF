import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import NotesApp 1.0

ApplicationWindow {
    id: window
    width: notesManager.config.windowWidth   
    height: notesManager.config.windowHeight 
    minimumWidth: 600
    minimumHeight: 400
    visible: true
    title: "Simple Notes - Ultra Keyboard Friendly"
    
    Colors {
        id: colors
    }
    
    color: colors.background

    // Save window size when it changes
    onWidthChanged: {
        if (width >= minimumWidth) {
            notesManager.setWindowSize(width, height)
        }
    }
    
    onHeightChanged: {
        if (height >= minimumHeight) {
            notesManager.setWindowSize(width, height)
        }
    }

    // Handle card bounds updates when screen size changes
    Connections {
        target: notesManager
        function onCardBoundsNeedUpdate() {
            // Force cards to fill bounds with actual grid dimensions
            if (gridViewRef && appState.isGridView()) {
                notesManager.forceCardFillBounds(gridViewRef.width, gridViewRef.leftMargin)
            }
        }
    }

    // Save window size when closing
    onClosing: (close) => {
        notesManager.setWindowSize(width, height)
        if (appState.isEditing()) {
            saveCurrentNote()
        }
    }

    // State management - cleaner than multiple booleans
    QtObject {
        id: appState
        property string view: "grid"  // "grid" or "editor"
        property string modal: "none" // "none", "search", "delete", "help", "firstTimeSetup", etc.
        
        function isGridView() { return view === "grid" }
        function isEditing() { return view === "editor" }
        function canNavigate() { return view === "grid" && modal === "none" }
        function hasModal() { return modal !== "none" }
    }

    property int currentNoteId: -1
    property var currentNote: ({})
    property int selectedNoteIndex: 0
    property int unsavedChanges: 0
    property bool navigating: false
    property point lastCardPosition: Qt.point(0, 0)
    property var gridViewRef: null
    property bool isFullscreen: false
    property bool showingFirstTimeSetup: false

    flags: Qt.Window | Qt.WindowFullscreenButtonHint

    Component.onCompleted: {
        // Check if we need first-time setup
        if (notesManager.needsFirstCollectionSetup()) {
            showingFirstTimeSetup = true
            appState.modal = "firstTimeSetup"
            timerManager.scheduleFocus(firstCollectionField)
        }
        
        // Set initial theme from config
        var savedTheme = notesManager.getCurrentTheme()
        if (savedTheme) {
            colors.setTheme(savedTheme)
        }
    }

    function toggleFullscreen() {
        if (isFullscreen) {
            // Exit fullscreen
            visibility = Window.Windowed
            flags = Qt.Window | Qt.WindowFullscreenButtonHint
            isFullscreen = false
        } else {
            // Enter fullscreen
            visibility = Window.FullScreen
            flags = Qt.Window | Qt.FramelessWindowHint
            isFullscreen = true
        }
    }

    // Timer management centralized
    QtObject {
        id: timerManager
        
        property Timer autoSaveTimer: Timer {
            id: autoSaveTimer
            interval: notesManager.config.autoSaveInterval
            repeat: false
            onTriggered: {
                if (appState.isEditing() && currentNote.content !== undefined) {
                    saveCurrentNote()
                    unsavedChanges = 0
                }
            }
        }
        
        property Timer focusTimer: Timer {
            id: focusTimer
            interval: 10
            repeat: false
            property var targetItem: null
            onTriggered: {
                if (targetItem) {
                    targetItem.forceActiveFocus()
                    if (targetItem.hasOwnProperty('cursorPosition')) {
                        targetItem.cursorPosition = targetItem.length
                    }
                    targetItem = null
                }
            }
        }
        
        property Timer navigationTimer: Timer {
            id: navigationTimer
            interval: 50
            repeat: false
            onTriggered: navigating = false
        }
        
        property Timer searchDebounceTimer: Timer {
            id: searchDebounceTimer
            interval: notesManager.config.searchDebounceInterval
            repeat: false
            onTriggered: notesManager.updateFilteredNotes()
        }
        
        function scheduleFocus(item) {
            focusTimer.targetItem = item
            focusTimer.restart()
        }
    }

    // Error/Success notifications
    Connections {
        target: notesManager
        function onSaveError(message) {
            notification.show(message, "error")
        }
        function onLoadError(message) {
            notification.show(message, "error")
        }
        function onSaveSuccess() {
            // Silent success - only show errors
        }
    }

    // Notification system - Monochromatic with darker text
    Rectangle {
        id: notification
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: appState.modal === "search" ? 70 : 10
        width: Math.min(parent.width * 0.8, 600)
        height: 50
        radius: 8
        visible: false
        opacity: 0.85  // More transparent
        z: 300

        property string type: "info"

        color: {
            switch(type) {
                case "error": return colors.error
                case "success": return colors.success
                case "warning": return colors.warning
                default: return colors.primary
            }
        }

        // Subtle border using darker version of the background color
        border.color: Qt.darker(color, 2)
        border.width: 1

        Text {
            anchors.centerIn: parent
            id: notificationText
            color: Qt.darker(notification.color, 1.8)  // Same color but darker
            font.family: notesManager.config.fontFamily
            font.pixelSize: 18
            font.bold: true
        }

        Timer {
            id: notificationTimer
            interval: 500
            onTriggered: notification.visible = false
        }

        function show(message, msgType = "info") {
            notificationText.text = message
            type = msgType
            //visible = true
            notificationTimer.restart()
        }

        Behavior on visible {
            NumberAnimation { duration: 200 }
        }

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }    

    // Keyboard shortcuts
    Shortcut {
        sequence: notesManager.config.shortcuts.newNote
        enabled: appState.canNavigate()
        onActivated: createNewNote()
    }
    
    Shortcut {
        sequence: notesManager.config.shortcuts.search
        enabled: appState.isGridView() && appState.modal !== "delete" && appState.modal !== "firstTimeSetup"
        onActivated: {
            appState.modal = "search"
            timerManager.scheduleFocus(searchField)
        }
    }
    
    Shortcut {
        sequence: notesManager.config.shortcuts.help
        enabled: appState.modal !== "firstTimeSetup"
        onActivated: appState.modal = appState.modal === "help" ? "none" : "help"
    }
    
    Shortcut {
        sequence: notesManager.config.shortcuts.quit
        onActivated: {
            if (appState.isEditing()) saveCurrentNote()
            Qt.quit()
        }
    }
    
    // Navigation shortcuts with throttling
    Shortcut {
        sequences: notesManager.config.shortcuts.prevNote
        enabled: appState.canNavigate() && !navigating
        onActivated: navigateGrid("up")
    }
    
    Shortcut {
        sequences: notesManager.config.shortcuts.nextNote
        enabled: appState.canNavigate() && !navigating
        onActivated: navigateGrid("down")
    }
    
    Shortcut {
        sequences: notesManager.config.shortcuts.prevNoteHorizontal
        enabled: appState.canNavigate() && !navigating
        onActivated: navigateGrid("left")
    }
    
    Shortcut {
        sequences: notesManager.config.shortcuts.nextNoteHorizontal
        enabled: appState.canNavigate() && !navigating
        onActivated: navigateGrid("right")
    }
    
    // Open note shortcuts
    Shortcut {
        sequences: notesManager.config.shortcuts.openNote
        enabled: appState.canNavigate() && notesManager.rowCount() > 0
        onActivated: {
            if (selectedNoteIndex >= 0 && selectedNoteIndex < notesManager.rowCount()) {
                var note = notesManager.getNoteByIndex(selectedNoteIndex)
                if (note) editNote(note.id)
            }
        }
    }
    
    // Delete shortcuts
    Shortcut {
        sequence: notesManager.config.shortcuts.delete
        enabled: appState.canNavigate() && notesManager.rowCount() > 0
        onActivated: appState.modal = "delete"
    }
    
    Shortcut {
        sequence: notesManager.config.shortcuts.quickDelete
        enabled: appState.isEditing() && currentNoteId >= 0 && !appState.hasModal()
        onActivated: {
            appState.modal = "delete"
            window.forceActiveFocus()
        }
    }
    
    // Delete confirmation shortcuts

    Shortcut {
        sequences: notesManager.config.shortcuts.confirmDelete
        enabled: appState.modal === "delete"
        onActivated: confirmDelete()
    }
    
    Shortcut {
        sequences: notesManager.config.shortcuts.cancelDelete
        enabled: appState.modal === "delete"
        onActivated: {
            appState.modal = "none"
            if (appState.isEditing()) {
                timerManager.scheduleFocus(contentArea)
            }
        }
    }

    Shortcut {
        sequences: notesManager.config.shortcuts.confirmDelete
        enabled: appState.modal === "deleteCollection"
        onActivated: {
            if (notesManager.deleteCollection(notesManager.currentCollection)) {
                notification.show("Collection deleted", "success")
                appState.modal = "none"
            } else {
                notification.show("Cannot delete the last collection", "error")
            }
        }
    }

    Shortcut {
        sequences: notesManager.config.shortcuts.cancelDelete
        enabled: appState.modal === "deleteCollection"
        onActivated: {
            appState.modal = "none"
        }
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.toggleFullscreen
        onActivated: toggleFullscreen()
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.themeCycle
        onActivated: {
            // Cycle through themes
            var themes = colors.getAvailableThemes()
            var currentIndex = themes.indexOf(colors.currentTheme)
            var nextIndex = (currentIndex + 1) % themes.length
            var nextTheme = themes[nextIndex]
            
            colors.setTheme(nextTheme)
            notesManager.setTheme(nextTheme)
            
            notification.show("Theme changed to " + colors.getCurrentThemeName(), "success")
        }
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.themeCycleBackward
        onActivated: {
            // Show theme selection dialog
            appState.modal = "themes"
        }
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.optimizeCardWidth
        enabled: appState.isGridView()
        onActivated: {
            if (gridViewRef) {
                notesManager.optimizeCardWidth(
                    gridViewRef.width,
                    gridViewRef.leftMargin
                )
                notification.show("Card width optimized to fill window", "success")
            }
        }
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.increaseColumns
        enabled: appState.isGridView()
        onActivated: {
            if (gridViewRef) {
                var success = notesManager.increaseColumns(
                    gridViewRef.width,
                    gridViewRef.leftMargin
                )
                if (success) {
                    notification.show("More columns", "success")
                } else {
                    notification.show("Maximum columns reached - all notes in one row", "warning")
                }
            }
        }
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.decreaseColumns
        enabled: appState.isGridView()
        onActivated: {
            if (gridViewRef) {
                var success = notesManager.decreaseColumns(
                    gridViewRef.width,
                    gridViewRef.leftMargin
                )
                if (success) {
                    notification.show("Fewer columns", "success")
                } else {
                    notification.show("Already at minimum (1 column)", "warning")
                }
            }
        }
    }

    // NEW: Collection shortcuts
    Shortcut {
        sequence: notesManager.config.shortcuts.newCollection
        enabled: !appState.hasModal() || appState.modal === "search"
        onActivated: {
            appState.modal = "newCollection"
            timerManager.scheduleFocus(newCollectionField)
        }
    }

    // Collection shortcuts - UPDATED to handle search mode
    Shortcut {
        sequence: notesManager.config.shortcuts.nextCollection
        enabled: !appState.hasModal() || appState.modal === "search"
        onActivated: {
            var collections = notesManager.collections
            if (collections.length > 1) {
                var currentIndex = collections.indexOf(notesManager.currentCollection)
                var nextIndex = (currentIndex + 1) % collections.length

                if (appState.modal === "search") {
                    // Preserve search state when switching
                    notesManager.switchCollectionWithSearch(collections[nextIndex], searchField.text)
                    // Keep search mode active and refocus
                    timerManager.scheduleFocus(searchField)
                } else {
                    notesManager.switchCollection(collections[nextIndex])
                }
                notification.show("Switched to: " + collections[nextIndex], "success")
            }
        }
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.prevCollection
        enabled: !appState.hasModal() || appState.modal === "search"
        onActivated: {
            var collections = notesManager.collections
            if (collections.length > 1) {
                var currentIndex = collections.indexOf(notesManager.currentCollection)
                var prevIndex = currentIndex > 0 ? currentIndex - 1 : collections.length - 1

                if (appState.modal === "search") {
                    // Preserve search state when switching
                    notesManager.switchCollectionWithSearch(collections[prevIndex], searchField.text)
                    // Keep search mode active and refocus
                    timerManager.scheduleFocus(searchField)
                } else {
                    notesManager.switchCollection(collections[prevIndex])
                }
                notification.show("Switched to: " + collections[prevIndex], "success")
            }
        }
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.deleteCollection
        enabled: (!appState.hasModal() || appState.modal === "search") && notesManager.collections.length > 1
        onActivated: {
            appState.modal = "deleteCollection"
        }
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.renameCollection
        enabled: !appState.hasModal() || appState.modal === "search"
        onActivated: {
            appState.modal = "renameCollection"
            timerManager.scheduleFocus(renameCollectionField)
        }
    }
    
    // Escape handler - UPDATED to not close first-time setup
    Shortcut {
        sequence: notesManager.config.shortcuts.back
        onActivated: {
            if (appState.modal === "firstTimeSetup") {
                // Cannot escape first-time setup
                return
            } else if (appState.modal === "delete") {
                appState.modal = "none"
                if (appState.isEditing()) {
                    timerManager.scheduleFocus(contentArea)
                }
            } else if (appState.modal === "help") {
                appState.modal = "none"
            } else if (appState.modal === "themes") {
                appState.modal = "none"
            } else if (appState.modal === "newCollection") {
                appState.modal = "none"
            } else if (appState.modal === "renameCollection") {
                appState.modal = "none"
            } else if (appState.modal === "deleteCollection") {
                appState.modal = "none"
            } else if (appState.modal === "stats") {
                appState.modal = "none"
            } else if (appState.modal === "search") {
                exitSearchMode()
            } else if (appState.isEditing()) {
                saveCurrentNote()
                showGridView()
            }
        }
    }
    
    // Save shortcut
    Shortcut {
        sequence: notesManager.config.shortcuts.save
        enabled: appState.isEditing() && !appState.hasModal()
        onActivated: saveCurrentNote()
    }
    
    // Navigation helper shortcuts
    Shortcut {
        sequence: notesManager.config.shortcuts.firstNote
        enabled: appState.canNavigate()
        onActivated: selectedNoteIndex = 0
    }
    
    Shortcut {
        sequence: notesManager.config.shortcuts.lastNote
        enabled: appState.canNavigate()
        onActivated: selectedNoteIndex = Math.max(0, notesManager.rowCount() - 1)
    }

    // Font size control shortcuts
    Shortcut {
        sequence: notesManager.config.shortcuts.increaseFontSize
        onActivated: notesManager.increaseFontSize()
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.decreaseFontSize
        onActivated: notesManager.decreaseFontSize()
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.increaseCardFontSize
        onActivated: notesManager.increaseCardFontSize()
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.decreaseCardFontSize
        onActivated: notesManager.decreaseCardFontSize()
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.increaseCardTitleFontSize
        onActivated: notesManager.increaseCardTitleFontSize()
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.decreaseCardTitleFontSize
        onActivated: notesManager.decreaseCardTitleFontSize()
    }

    // Card height control shortcuts
    Shortcut {
        sequence: notesManager.config.shortcuts.increaseCardHeight
        onActivated: notesManager.increaseCardHeight()
    }

    Shortcut {
        sequence: notesManager.config.shortcuts.decreaseCardHeight
        onActivated: notesManager.decreaseCardHeight()
    }

    // Stats shortcut
    Shortcut {
        sequence: notesManager.config.shortcuts.showStats
        onActivated: {
            if (appState.modal === "stats") {
                appState.modal = "none"
            } else {
                appState.modal = "stats"
            }
        }
    }

    function navigateGrid(direction) {
        if (notesManager.rowCount() === 0 || navigating || !gridViewRef) return

        navigating = true
        navigationTimer.restart()

        // Calculate columns based on actual GridView dimensions
        var availableWidth = gridViewRef.width - gridViewRef.leftMargin - gridViewRef.rightMargin
        var cols = Math.floor(availableWidth / gridViewRef.cellWidth)

        // Ensure we have at least 1 column
        cols = Math.max(1, cols)

        var totalNotes = notesManager.rowCount()
        var totalRows = Math.ceil(totalNotes / cols)

        // Convert current 1D index to 2D coordinates
        var currentRow = Math.floor(selectedNoteIndex / cols)
        var currentCol = selectedNoteIndex % cols

        var newRow = currentRow
        var newCol = currentCol

        switch (direction) {
            case "up":
                // Wrap to bottom row if at top
                newRow = (currentRow - 1 + totalRows) % totalRows
                break

            case "down":
                // Wrap to top row if at bottom
                newRow = (currentRow + 1) % totalRows
                break

            case "left":
                // Wrap to rightmost column if at leftmost
                newCol = (currentCol - 1 + cols) % cols
                break

            case "right":
                // Wrap to leftmost column if at rightmost
                newCol = (currentCol + 1) % cols
                break
        }

        // Convert back to 1D index
        var newIndex = newRow * cols + newCol

        // Handle edge case: if we wrapped to a position that doesn't exist
        // (e.g., last row isn't full), find the closest valid position
        if (newIndex >= totalNotes) {
            if (direction === "up" || direction === "down") {
                // For vertical movement, try to stay in the same column
                // but find the closest row that has a note in this column
                for (var r = 0; r < totalRows; r++) {
                    var testIndex = r * cols + newCol
                    if (testIndex < totalNotes) {
                        newIndex = testIndex
                        if (direction === "up") {
                            // For up movement, we want the last valid row with this column
                            continue
                        } else {
                            // For down movement, we want the first valid row with this column
                            break
                        }
                    }
                }
            } else {
                // For horizontal movement, wrap to the last note if we overshoot
                newIndex = totalNotes - 1
            }
        }

        selectedNoteIndex = newIndex
    }

    // Search functions
    function exitSearchMode() {
        appState.modal = "none"
        notesManager.setSearchText("")
        if (searchField) {
            searchField.text = ""
            searchField.focus = false
        }
        selectedNoteIndex = Math.min(selectedNoteIndex, Math.max(0, notesManager.rowCount() - 1))
        window.forceActiveFocus()
    }

    // Core functions
    function createNewNote() {
        if (appState.modal === "search") exitSearchMode()
        
        if (appState.isEditing()) {
            saveCurrentNote()
            showGridView()
            Qt.callLater(function() {
                currentNoteId = -1
                currentNote = { id: -1, title: "", content: "" }
                showNoteEditor()
            })
        } else {
            currentNoteId = -1
            currentNote = { id: -1, title: "", content: "" }
            showNoteEditor()
        }
    }

    function showGridView() {
        appState.view = "grid"
        appState.modal = "none"
        stackView.pop()
        selectedNoteIndex = Math.min(selectedNoteIndex, Math.max(0, notesManager.rowCount() - 1))
    }

    function showNoteEditor() {
        appState.view = "editor"
        appState.modal = "none"
        unsavedChanges = 0
        stackView.push(noteEditor)
    }

    function editNote(noteId) {
        currentNoteId = noteId
        currentNote = notesManager.getNote(noteId)
        showNoteEditor()
    }

    function saveCurrentNote() {
        if (currentNote.content !== undefined && currentNote.content.trim() !== "") {
            if (currentNoteId === -1) {
                currentNoteId = notesManager.createNote(currentNote.content)
            } else {
                notesManager.updateNote(currentNoteId, currentNote.content)
            }
            unsavedChanges = 0
        }
    }

    function confirmDelete() {
        if (appState.isGridView() && selectedNoteIndex >= 0 && selectedNoteIndex < notesManager.rowCount()) {
            var noteToDelete = notesManager.getNoteByIndex(selectedNoteIndex)
            if (noteToDelete && noteToDelete.id !== undefined) {
                notesManager.deleteNote(noteToDelete.id)
                selectedNoteIndex = Math.min(selectedNoteIndex, Math.max(0, notesManager.rowCount() - 1))
            }
        } else if (appState.isEditing() && currentNoteId >= 0) {
            notesManager.deleteNote(currentNoteId)
            showGridView()
        }
        appState.modal = "none"
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: gridView

        // ENTRANCE: Smooth fade in
        pushEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        // EXIT: Quick fade out
        pushExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 150
                easing.type: Easing.InCubic
            }
        }

        // RETURN: Gentle fade back
        popEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 350
                easing.type: Easing.OutCubic
            }
        }

        // EXIT: Smooth fade out
        popExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 200
                easing.type: Easing.InCubic
            }
        }
    }

    // NEW: First Time Setup Modal
    Rectangle {
        anchors.fill: parent
        color: colors.overlayColor
        opacity: appState.modal === "firstTimeSetup" ? 0.9 : 0
        visible: appState.modal === "firstTimeSetup"
        z: 250
        
        // Cannot close this modal - user must create a collection
        
        Rectangle {
            anchors.centerIn: parent
            width: 500
            height: 250
            color: colors.modalBackground
            radius: 15
            border.color: colors.modalBorder
            border.width: 3
            
            Column {
                anchors.centerIn: parent
                spacing: 25
                
                TextField {
                    id: firstCollectionField
                    width: 350
                    font.family: notesManager.config.fontFamily
                    font.pixelSize: 16
                    color: colors.primaryText
                    placeholderTextColor: colors.placeholderColor
                    
                    background: Rectangle {
                        color: colors.searchBarColor
                        radius: 8
                        border.color: parent.activeFocus ? colors.focusBorderColor : colors.borderColor
                        border.width: 2
                    }
                    
                    onAccepted: {
                        if (text.trim() !== "") {
                            if (notesManager.setupFirstCollection(text)) {
                                showingFirstTimeSetup = false
                                appState.modal = "none"
                                notification.show("Collection '" + text + "' created! Welcome to Simple Notes!", "success")
                            } else {
                                notification.show("Could not create collection. Please try again.", "error")
                            }
                        }
                    }
                    
                    // Don't allow escape on first setup
                    Keys.onEscapePressed: {
                        // Do nothing - user must create a collection
                    }
                }
                Button {
                    text: "Create Collection"
                    enabled: firstCollectionField.text.trim() !== ""
                    anchors.horizontalCenter: parent.horizontalCenter

                    onClicked: {
                        if (firstCollectionField.text.trim() !== "") {
                            if (notesManager.setupFirstCollection(firstCollectionField.text)) {
                                showingFirstTimeSetup = false
                                appState.modal = "none"
                                notification.show("Collection '" + firstCollectionField.text + "' created! Welcome to Simple Notes!", "success")
                            } else {
                                notification.show("Could not create collection. Please try again.", "error")
                            }
                        }
                    }

                    background: Rectangle {
                        color: parent.enabled ? colors.accentColor : colors.borderColor
                        radius: 8
                    }

                    contentItem: Text {
                        text: parent.text
                        color: Qt.darker(parent.background.color, 1.8)  // Darker version of background
                        font.family: notesManager.config.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    // Search overlay
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: appState.modal === "search" ? 60 : 0
        color: colors.primary
        visible: appState.modal === "search"
        z: 100
        
        Behavior on height {
            NumberAnimation { duration: 200 }
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            
            Text {
                text: "Search:"
                color: Qt.darker(colors.accentColor, 1.8)
                font.family: notesManager.config.fontFamily
                font.pixelSize: 14
            }

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Type to search notes..."
                text: notesManager.searchText
                font.family: notesManager.config.fontFamily
                font.pixelSize: 14
                color: Qt.darker(colors.accentColor, 1.8)
                placeholderTextColor: colors.placeholderColor
                
                onTextChanged: {
                    notesManager.setSearchText(text)
                    searchDebounceTimer.restart()
                }
                
                onAccepted: {
                    if (notesManager.rowCount() > 0 && selectedNoteIndex >= 0) {
                        var note = notesManager.getNoteByIndex(selectedNoteIndex)
                        if (note) editNote(note.id)
                    }
                }
                
                Keys.onEscapePressed: (event)=> {
                    event.accepted = true
                    exitSearchMode()
                }
                
                Keys.onPressed: (event)=> {
                    if (event.key === Qt.Key_Up || event.key === Qt.Key_Down ||
                        event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                        event.accepted = true
                        var direction = {
                            [Qt.Key_Up]: "up",
                            [Qt.Key_Down]: "down",
                            [Qt.Key_Left]: "left",
                            [Qt.Key_Right]: "right"
                        }[event.key]
                        navigateGrid(direction)
                    } else if (event.key === Qt.Key_Return) {
                        if (notesManager.rowCount() > 0 && selectedNoteIndex >= 0) {
                            event.accepted = true
                            var note = notesManager.getNoteByIndex(selectedNoteIndex)
                            if (note) editNote(note.id)
                        }
                    } else if (event.key === Qt.Key_Home) {
                        event.accepted = true
                        selectedNoteIndex = 0
                    } else if (event.key === Qt.Key_End) {
                        event.accepted = true
                        selectedNoteIndex = Math.max(0, notesManager.rowCount() - 1)
                    }
                }
                
                background: Rectangle {
                    color: colors.searchBarColor
                    radius: 5
                }
            }
            
            Text {
                text: "Found: " + notesManager.rowCount() + " | Esc to exit"
                color: Qt.darker(colors.accentColor, 1.8)
                font.family: notesManager.config.fontFamily
                font.pixelSize: 12
            }
        }

        Connections {
            target: notesManager
            function onCurrentCollectionChanged() {
                // If we're in search mode, make sure the field stays focused
                if (appState.modal === "search") {
                    timerManager.scheduleFocus(searchField)
                    // Trigger search update for new collection
                    if (searchField.text.trim() !== "") {
                        searchDebounceTimer.restart()
                    }
                }
            }
        }
    }

    // NEW: New Collection Modal
    Rectangle {
        anchors.fill: parent
        color: colors.overlayColor
        opacity: appState.modal === "newCollection" ? 0.7 : 0
        visible: appState.modal === "newCollection"
        z: 200
        
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: appState.modal = "none"
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 400
        height: 150
        color: colors.modalBackground
        radius: 10
        border.color: colors.modalBorder
        border.width: 2
        visible: appState.modal === "newCollection"
        z: 201
        focus: appState.modal === "newCollection"
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            Text {
                text: "Create New Collection"
                font.family: notesManager.config.fontFamily
                font.pixelSize: 18
                color: colors.textColor
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            TextField {
                id: newCollectionField
                width: 300
                placeholderText: "Collection name..."
                font.family: notesManager.config.fontFamily
                font.pixelSize: 14
                color: colors.primaryText
                placeholderTextColor: colors.placeholderColor
                
                background: Rectangle {
                    color: colors.searchBarColor
                    radius: 5
                    border.color: parent.activeFocus ? colors.focusBorderColor : colors.borderColor
                    border.width: 1
                }
                
                onAccepted: {
                    if (text.trim() !== "") {
                        if (notesManager.createCollection(text)) {
                            notification.show("Collection '" + text + "' created", "success")
                            notesManager.switchCollection(text)
                            appState.modal = "none"
                            text = ""
                        } else {
                            notification.show("Collection already exists or invalid name", "error")
                        }
                    }
                }
                
                Keys.onEscapePressed: {
                    appState.modal = "none"
                    text = ""
                }
            }
            
            Row {
                spacing: 15
                anchors.horizontalCenter: parent.horizontalCenter
            
                Button {
                    text: "Create"
                    onClicked: {
                        if (newCollectionField.text.trim() !== "") {
                            if (notesManager.createCollection(newCollectionField.text)) {
                                notification.show("Collection '" + newCollectionField.text + "' created", "success")
                                notesManager.switchCollection(newCollectionField.text)
                                appState.modal = "none"
                                newCollectionField.text = ""
                            } else {
                                notification.show("Collection already exists or invalid name", "error")
                            }
                        }
                    }

                    background: Rectangle {
                        color: colors.accentColor
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: Qt.darker(parent.background.color, 1.8)  // Darker version of background
                        font.family: notesManager.config.fontFamily
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // Cancel button
                Button {
                    text: "Cancel"
                    onClicked: {
                        appState.modal = "none"
                        newCollectionField.text = ""
                    }

                    background: Rectangle {
                        color: colors.cardColor
                        border.color: colors.borderColor
                        border.width: 1
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: Qt.darker(parent.background.color, 1.8)  // Darker version of background
                        font.family: notesManager.config.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    // NEW: Rename Collection Modal
    Rectangle {
        anchors.fill: parent
        color: colors.overlayColor
        opacity: appState.modal === "renameCollection" ? 0.7 : 0
        visible: appState.modal === "renameCollection"
        z: 200
        
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: appState.modal = "none"
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 400
        height: 150
        color: colors.modalBackground
        radius: 10
        border.color: colors.modalBorder
        border.width: 2
        visible: appState.modal === "renameCollection"
        z: 201
        focus: appState.modal === "renameCollection"
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            Text {
                text: "Rename Collection: " + notesManager.currentCollection
                font.family: notesManager.config.fontFamily
                font.pixelSize: 18
                color: colors.textColor
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            TextField {
                id: renameCollectionField
                width: 300
                text: notesManager.currentCollection
                placeholderText: "New collection name..."
                font.family: notesManager.config.fontFamily
                font.pixelSize: 14
                color: colors.primaryText
                placeholderTextColor: colors.placeholderColor
                
                Component.onCompleted: {
                    if (appState.modal === "renameCollection") {
                        selectAll()
                    }
                }
                
                background: Rectangle {
                    color: colors.searchBarColor
                    radius: 5
                    border.color: parent.activeFocus ? colors.focusBorderColor : colors.borderColor
                    border.width: 1
                }
                
                onAccepted: {
                    if (text.trim() !== "" && text.trim() !== notesManager.currentCollection) {
                        if (notesManager.renameCollection(notesManager.currentCollection, text)) {
                            notification.show("Collection renamed to '" + text + "'", "success")
                            appState.modal = "none"
                        } else {
                            notification.show("Collection name already exists or invalid", "error")
                        }
                    }
                }
                
                Keys.onEscapePressed: {
                    appState.modal = "none"
                }
            }
            
            Row {
                spacing: 15
                anchors.horizontalCenter: parent.horizontalCenter
                
                Button {
                    text: "Rename"
                    onClicked: {
                        if (renameCollectionField.text.trim() !== "" && 
                            renameCollectionField.text.trim() !== notesManager.currentCollection) {
                            if (notesManager.renameCollection(notesManager.currentCollection, renameCollectionField.text)) {
                                notification.show("Collection renamed to '" + renameCollectionField.text + "'", "success")
                                appState.modal = "none"
                            } else {
                                notification.show("Collection name already exists or invalid", "error")
                            }
                        }
                    }
                    
                    background: Rectangle {
                        color: colors.accentColor
                        radius: 5
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: colors.buttonTextColor
                        font.family: notesManager.config.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                Button {
                    text: "Cancel"
                    onClicked: {
                        appState.modal = "none"
                    }
                    
                    background: Rectangle {
                        color: colors.transparentColor
                        border.color: colors.borderColor
                        border.width: 1
                        radius: 5
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: colors.textColor
                        font.family: notesManager.config.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    // NEW: Delete Collection Confirmation Modal
    Rectangle {
        anchors.fill: parent
        color: colors.overlayColor
        opacity: appState.modal === "deleteCollection" ? 0.7 : 0
        visible: appState.modal === "deleteCollection"
        z: 200
        
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: appState.modal = "none"
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 400
        height: 150
        color: colors.modalBackground
        radius: 10
        border.color: colors.modalBorder
        border.width: 2
        visible: appState.modal === "deleteCollection"
        z: 201
        focus: appState.modal === "deleteCollection"
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            Text {
                text: "Delete Collection: " + notesManager.currentCollection + "?"
                font.family: notesManager.config.fontFamily
                font.pixelSize: 18
                color: colors.textColor
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: "This action cannot be undone. All notes in this collection will be lost."
                font.family: notesManager.config.fontFamily
                font.pixelSize: 12
                color: colors.secondaryText
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.WordWrap
                width: 350
            }
            
            Row {
                spacing: 15
                anchors.horizontalCenter: parent.horizontalCenter
                
                Button {
                    text: "Delete (Y/Enter)"
                    enabled: notesManager.collections.length > 1
                    onClicked: {
                        if (notesManager.deleteCollection(notesManager.currentCollection)) {
                            notification.show("Collection deleted", "success")
                            appState.modal = "none"
                        } else {
                            notification.show("Cannot delete the last collection", "error")
                        }
                    }

                    background: Rectangle {
                        color: colors.deleteButtonColor
                        radius: 5
                        opacity: parent.enabled ? 1.0 : 0.5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: colors.buttonTextColor
                        font.family: notesManager.config.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: "Cancel (N/Esc)"
                    onClicked: {
                        appState.modal = "none"
                    }

                    background: Rectangle {
                        color: colors.transparentColor
                        border.color: colors.borderColor
                        border.width: 1
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: colors.textColor
                        font.family: notesManager.config.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    // Delete confirmation overlay
    Rectangle {
        anchors.fill: parent
        color: colors.overlayColor
        opacity: appState.modal === "delete" ? 0.7 : 0
        visible: appState.modal === "delete"
        z: 200
        
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                appState.modal = "none"
                if (appState.isEditing()) {
                    timerManager.scheduleFocus(contentArea)
                }
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 400
        height: 150
        color: colors.modalBackground
        radius: 10
        border.color: colors.modalBorder
        border.width: 2
        visible: appState.modal === "delete"
        z: 201
        focus: appState.modal === "delete"
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            Text {
                text: "Delete this note?"
                font.family: notesManager.config.fontFamily
                font.pixelSize: 18
                color: colors.textColor
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: "This action cannot be undone."
                font.family: notesManager.config.fontFamily
                font.pixelSize: 12
                color: colors.secondaryText
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Row {
                spacing: 15
                anchors.horizontalCenter: parent.horizontalCenter
                // Yes/Delete button
                Button {
                    text: "Yes (Y/Enter)"
                    onClicked: confirmDelete()

                    background: Rectangle {
                        color: colors.deleteButtonColor
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: Qt.darker(parent.background.color, 1.8)  // Darker version of background
                        font.family: notesManager.config.fontFamily
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // No/Cancel button
                Button {
                    text: "No (N/Esc)"
                    onClicked: {
                        appState.modal = "none"
                        if (appState.isEditing()) {
                            timerManager.scheduleFocus(contentArea)
                        }
                    }

                    background: Rectangle {
                        color: colors.cardColor
                        border.color: colors.borderColor
                        border.width: 1
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: Qt.darker(parent.background.color, 1.8)  // Darker version of background
                        font.family: notesManager.config.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    Rectangle {
        id: helpDialog
        anchors.centerIn: parent
        width: Math.min(window.width * 0.9, 800)
        height: Math.min(window.height * 0.9, 600)
        color: colors.helpDialogBackground
        opacity: 0.95
        radius: 15
        border.color: colors.helpDialogBorder
        border.width: 2
        visible: appState.modal === "help"
        z: 202
        focus: appState.modal === "help"
        
        // Store colors reference at this level
        property var helpColors: colors
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(colors.surface, 1.1) }
            GradientStop { position: 1.0; color: Qt.darker(colors.surface, 1.1) }
        }
        
        // Keyboard handling
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                event.accepted = true
                helpScrollView.ScrollBar.vertical.decrease()
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                event.accepted = true
                helpScrollView.ScrollBar.vertical.increase()
            } else if (event.key === Qt.Key_PageUp) {
                event.accepted = true
                helpScrollView.ScrollBar.vertical.position = Math.max(0, helpScrollView.ScrollBar.vertical.position - 0.5)
            } else if (event.key === Qt.Key_PageDown) {
                event.accepted = true
                helpScrollView.ScrollBar.vertical.position = Math.min(1, helpScrollView.ScrollBar.vertical.position + 0.5)
            } else if (event.key === Qt.Key_Home) {
                event.accepted = true
                helpScrollView.ScrollBar.vertical.position = 0
            } else if (event.key === Qt.Key_End) {
                event.accepted = true
                helpScrollView.ScrollBar.vertical.position = 1
            }
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            // Header
            Text {
                text: "Keyboard Shortcuts"
                font.family: notesManager.config.fontFamily
                font.pixelSize: 24
                font.bold: true
                color: colors.helpDialogText
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            // Scrollable content
            ScrollView {
                id: helpScrollView
                width: parent.width
                height: parent.height - 60
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                clip: true
                
                Column {
                    width: parent.width
                    spacing: 4
                    
                    // ===== BASIC ACTIONS =====
                    Text {
                        text: "Basic Actions"
                        font.family: notesManager.config.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colors.accentColor
                        width: parent.width
                        height: 25
                        topPadding: 10
                    }
                    
                    HelpItem { 
                        label: "New Note" 
                        shortcut: notesManager.config.shortcuts.newNote 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Save Note" 
                        shortcut: notesManager.config.shortcuts.save 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Search Notes" 
                        shortcut: notesManager.config.shortcuts.search 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Back/Cancel" 
                        shortcut: notesManager.config.shortcuts.back 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Help" 
                        shortcut: notesManager.config.shortcuts.help 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Quit Application" 
                        shortcut: notesManager.config.shortcuts.quit 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }

                    // ===== COLLECTIONS =====
                    Text {
                        text: "Collections"
                        font.family: notesManager.config.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colors.accentColor
                        width: parent.width
                        height: 25
                        topPadding: 10
                    }
                    
                    HelpItem { 
                        label: "New Collection" 
                        shortcut: notesManager.config.shortcuts.newCollection 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Rename Collection" 
                        shortcut: notesManager.config.shortcuts.renameCollection 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Next Collection" 
                        shortcut: notesManager.config.shortcuts.nextCollection 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Previous Collection" 
                        shortcut: notesManager.config.shortcuts.prevCollection 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Delete Collection" 
                        shortcut: notesManager.config.shortcuts.deleteCollection 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    
                    // ===== NAVIGATION =====
                    Text {
                        text: "Navigation"
                        font.family: notesManager.config.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colors.accentColor
                        width: parent.width
                        height: 25
                        topPadding: 10
                    }
                    
                    HelpItem { 
                        label: "Navigate Up" 
                        shortcut: Array.isArray(notesManager.config.shortcuts.prevNote) ? 
                                  notesManager.config.shortcuts.prevNote.join(" or ") : 
                                  notesManager.config.shortcuts.prevNote
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Navigate Down" 
                        shortcut: Array.isArray(notesManager.config.shortcuts.nextNote) ? 
                                  notesManager.config.shortcuts.nextNote.join(" or ") : 
                                  notesManager.config.shortcuts.nextNote
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Navigate Left" 
                        shortcut: Array.isArray(notesManager.config.shortcuts.prevNoteHorizontal) ? 
                                  notesManager.config.shortcuts.prevNoteHorizontal.join(" or ") : 
                                  notesManager.config.shortcuts.prevNoteHorizontal
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Navigate Right" 
                        shortcut: Array.isArray(notesManager.config.shortcuts.nextNoteHorizontal) ? 
                                  notesManager.config.shortcuts.nextNoteHorizontal.join(" or ") : 
                                  notesManager.config.shortcuts.nextNoteHorizontal
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Open Note" 
                        shortcut: Array.isArray(notesManager.config.shortcuts.openNote) ? 
                                  notesManager.config.shortcuts.openNote.join(" or ") : 
                                  notesManager.config.shortcuts.openNote
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "First Note" 
                        shortcut: notesManager.config.shortcuts.firstNote 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Last Note" 
                        shortcut: notesManager.config.shortcuts.lastNote 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    
                    // ===== NOTE ACTIONS =====
                    Text {
                        text: "Note Actions"
                        font.family: notesManager.config.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colors.accentColor
                        width: parent.width
                        height: 25
                        topPadding: 10
                    }
                    
                    HelpItem { 
                        label: "Delete Note (Grid)" 
                        shortcut: notesManager.config.shortcuts.delete 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Quick Delete (Editor)" 
                        shortcut: notesManager.config.shortcuts.quickDelete 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    
                    // ===== THEMES =====
                    Text {
                        text: "Themes"
                        font.family: notesManager.config.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colors.accentColor
                        width: parent.width
                        height: 25
                        topPadding: 10
                    }
                    
                    HelpItem { 
                        label: "Cycle Theme" 
                        shortcut: notesManager.config.shortcuts.themeCycle 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Select Theme" 
                        shortcut: notesManager.config.shortcuts.themeCycleBackward 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    
                    // ===== DISPLAY & LAYOUT =====
                    Text {
                        text: "Display & Layout"
                        font.family: notesManager.config.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colors.accentColor
                        width: parent.width
                        height: 25
                        topPadding: 10
                    }
                    
                    HelpItem { 
                        label: "Toggle Fullscreen" 
                        shortcut: notesManager.config.shortcuts.toggleFullscreen 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Auto-Optimize Layout" 
                        shortcut: notesManager.config.shortcuts.optimizeCardWidth 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "More Columns (Narrower)" 
                        shortcut: notesManager.config.shortcuts.increaseColumns 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Fewer Columns (Wider)" 
                        shortcut: notesManager.config.shortcuts.decreaseColumns 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    
                    // ===== FONT SIZES =====
                    Text {
                        text: "Font Sizes"
                        font.family: notesManager.config.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colors.accentColor
                        width: parent.width
                        height: 25
                        topPadding: 10
                    }
                    
                    HelpItem { 
                        label: "Increase Editor Font" 
                        shortcut: notesManager.config.shortcuts.increaseFontSize 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Decrease Editor Font" 
                        shortcut: notesManager.config.shortcuts.decreaseFontSize 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Increase Card Font" 
                        shortcut: notesManager.config.shortcuts.increaseCardFontSize 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Decrease Card Font" 
                        shortcut: notesManager.config.shortcuts.decreaseCardFontSize
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Increase Card Title Font" 
                        shortcut: notesManager.config.shortcuts.increaseCardTitleFontSize 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Decrease Card Title Font" 
                        shortcut: notesManager.config.shortcuts.decreaseCardTitleFontSize
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    
                    // ===== CARD DIMENSIONS =====
                    Text {
                        text: "Card Dimensions"
                        font.family: notesManager.config.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colors.accentColor
                        width: parent.width
                        height: 25
                        topPadding: 10
                    }
                    
                    HelpItem { 
                        label: "Taller Cards" 
                        shortcut: notesManager.config.shortcuts.increaseCardHeight
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Shorter Cards" 
                        shortcut: notesManager.config.shortcuts.decreaseCardHeight
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    
                    // ===== DELETION CONFIRMATIONS =====
                    Text {
                        text: "Delete Confirmations"
                        font.family: notesManager.config.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colors.accentColor
                        width: parent.width
                        height: 25
                        topPadding: 10
                    }
                    
                    HelpItem { 
                        label: "Confirm Delete" 
                        shortcut: Array.isArray(notesManager.config.shortcuts.confirmDelete) ? 
                                  notesManager.config.shortcuts.confirmDelete.join(" or ") : 
                                  notesManager.config.shortcuts.confirmDelete
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Cancel Delete" 
                        shortcut: Array.isArray(notesManager.config.shortcuts.cancelDelete) ? 
                                  notesManager.config.shortcuts.cancelDelete.join(" or ") : 
                                  notesManager.config.shortcuts.cancelDelete
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    
                    // ===== DIALOG NAVIGATION =====
                    Text {
                        text: "Dialog Navigation"
                        font.family: notesManager.config.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: colors.accentColor
                        width: parent.width
                        height: 25
                        topPadding: 10
                    }
                    
                    HelpItem { 
                        label: "Scroll Up" 
                        shortcut: "Up, K, or Page Up" 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Scroll Down" 
                        shortcut: "Down, J, or Page Down" 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Go to Top" 
                        shortcut: "Home" 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    HelpItem { 
                        label: "Go to Bottom" 
                        shortcut: "End" 
                        width: parent.width; itemHeight: 18; fontSize: 11
                        colors: helpDialog.helpColors
                    }
                    
                    // Bottom padding
                    Item {
                        width: parent.width
                        height: 20
                    }
                }
            }
        }
    }

    // Theme selection dialogn
    Rectangle {
        id: themeDialog
        anchors.centerIn: parent
        width: Math.min(window.width * 0.9, 800)  // EXACT same as help dialog
        height: Math.min(window.height * 0.9, 600)  // EXACT same as help dialog
        color: colors.helpDialogBackground
        opacity: 0.95
        radius: 15
        border.color: colors.helpDialogBorder
        border.width: 2
        visible: appState.modal === "themes"
        z: 203
        focus: appState.modal === "themes"

        // Track selected theme for keyboard navigation
        property int selectedThemeIndex: 0
        property var availableThemes: colors.getAllThemeInfo()

        // Calculate dynamic card height to fit all themes - MORE SPACE NOW!
        property real availableHeight: height - 80  // Just header + margins (was 120)
        property real cardHeight: Math.max(35, Math.min(60, availableHeight / availableThemes.length - 4))  // Dynamic height with min/max

        // Initialize selected theme index when dialog opens
        Component.onCompleted: {
            if (appState.modal === "themes") {
                updateSelectedIndex()
            }
        }

        // Update when modal state changes
        onVisibleChanged: {
            if (visible) {
                availableThemes = colors.getAllThemeInfo()
                updateSelectedIndex()
            }
        }

        function updateSelectedIndex() {
            for (var i = 0; i < availableThemes.length; i++) {
                if (availableThemes[i].key === colors.currentTheme) {
                    selectedThemeIndex = i
                    return
                }
            }
            selectedThemeIndex = 0
        }

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(colors.surface, 1.1) }
            GradientStop { position: 1.0; color: Qt.darker(colors.surface, 1.1) }
        }

        // Simple keyboard navigation with wraparound
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                event.accepted = true
                if (selectedThemeIndex <= 0) {
                    selectedThemeIndex = availableThemes.length - 1
                } else {
                    selectedThemeIndex = selectedThemeIndex - 1
                }
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                event.accepted = true
                if (selectedThemeIndex >= availableThemes.length - 1) {
                    selectedThemeIndex = 0
                } else {
                    selectedThemeIndex = selectedThemeIndex + 1
                }
            } else if (event.key === Qt.Key_Home) {
                event.accepted = true
                selectedThemeIndex = 0
            } else if (event.key === Qt.Key_End) {
                event.accepted = true
                selectedThemeIndex = availableThemes.length - 1
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                event.accepted = true
                selectCurrentTheme()
            }
        }

        function selectCurrentTheme() {
            if (selectedThemeIndex >= 0 && selectedThemeIndex < availableThemes.length) {
                var themeInfo = availableThemes[selectedThemeIndex]
                colors.setTheme(themeInfo.key)
                notesManager.setTheme(themeInfo.key)
                appState.modal = "none"

                notification.show("Theme changed to " + themeInfo.displayName, "success")
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Header only
            Text {
                text: "Select Theme"
                font.family: notesManager.config.fontFamily
                font.pixelSize: 24
                font.bold: true
                color: colors.helpDialogText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Theme list - NO SCROLLVIEW, just dynamic Column
            Column {
                width: parent.width
                spacing: 2  // Minimal spacing

                Repeater {
                    model: themeDialog.availableThemes

                    Rectangle {
                        width: parent.width
                        height: themeDialog.cardHeight  // DYNAMIC height

                        property bool isCurrentTheme: colors.currentTheme === modelData.key
                        property bool isKeyboardSelected: index === themeDialog.selectedThemeIndex

                        color: isCurrentTheme ? colors.selectedColor : 
                            isKeyboardSelected ? colors.hoverColor : colors.transparentColor
                        border.color: isCurrentTheme ? colors.accentColor : 
                                    isKeyboardSelected ? colors.primary : colors.borderColor
                        border.width: isCurrentTheme ? 2 : 1
                        radius: 6

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            // Selection indicator
                            Rectangle {
                                width: 5
                                height: 5
                                radius: 2.5
                                color: isCurrentTheme ? colors.accentColor : colors.transparentColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Theme name
                            Text {
                                text: modelData.displayName
                                color: colors.textColor
                                font.family: notesManager.config.fontFamily
                                font.pixelSize: Math.max(12, Math.min(16, themeDialog.cardHeight * 0.35))  // Dynamic font size
                                font.bold: isCurrentTheme
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Current theme indicator
                            Text {
                                text: isCurrentTheme ? "(current)" : ""
                                color: colors.accentColor
                                font.family: notesManager.config.fontFamily
                                font.pixelSize: Math.max(10, Math.min(12, themeDialog.cardHeight * 0.25))  // Dynamic font size
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Keyboard selection indicator
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(14, Math.min(20, themeDialog.cardHeight * 0.4))  // Dynamic size
                            height: width
                            radius: width / 2
                            color: isKeyboardSelected ? colors.primary : colors.transparentColor
                            visible: isKeyboardSelected

                            Text {
                                text: "▸"
                                color: colors.primaryText
                                font.pixelSize: Math.max(8, Math.min(12, themeDialog.cardHeight * 0.25))  // Dynamic font size
                                anchors.centerIn: parent
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: {
                                themeDialog.selectedThemeIndex = index
                            }

                            onClicked: {
                                themeDialog.selectedThemeIndex = index
                                themeDialog.selectCurrentTheme()
                            }
                        }
                    }
                }
            }
        }
    }

    // Stats overlay
    Rectangle {
        id: statsDialog
        anchors.centerIn: parent
        width: Math.min(window.width * 0.9, 800)
        height: Math.min(window.height * 0.9, 600)
        color: colors.helpDialogBackground
        opacity: 0.95
        radius: 15
        border.color: colors.helpDialogBorder
        border.width: 2
        visible: appState.modal === "stats"
        z: 204
        focus: appState.modal === "stats"
        
        property var currentStats: ({})
        property bool showingNoteStats: appState.isEditing() && currentNoteId >= 0
        
        Component.onCompleted: {
            updateStats()
        }
        
        onVisibleChanged: {
            if (visible) {
                updateStats()
            }
        }
        
        function updateStats() {
            if (showingNoteStats) {
                currentStats = notesManager.getNoteStats(currentNoteId)
            } else {
                currentStats = notesManager.getOverallStats()
            }
        }
        
        function formatReadingTime(minutes) {
            if (minutes < 1) {
                return "< 1 minute"
            } else if (minutes < 60) {
                return Math.round(minutes) + " minutes"
            } else {
                var hours = Math.floor(minutes / 60)
                var remainingMinutes = Math.round(minutes % 60)
                if (remainingMinutes === 0) {
                    return hours + " hour" + (hours > 1 ? "s" : "")
                } else {
                    return hours + "h " + remainingMinutes + "m"
                }
            }
        }
        
        function formatDate(dateString) {
            if (!dateString) return "Unknown"
            var date = new Date(dateString)
            return date.toLocaleDateString() + " " + date.toLocaleTimeString()
        }
        
        function formatMostCommonWords() {
            try {
                var words = currentStats.mostCommonWords
                
                if (!words) {
                    return "None"
                }
                
                // QML doesn't recognize Python lists as JS arrays, so check for length property instead
                if (words && typeof words === "object" && words.length > 0) {
                    var result = []
                    for (var i = 0; i < words.length; i++) {
                        var item = words[i]
                        if (item && typeof item === "object" && item.length >= 2) {
                            result.push(item[0] + " (" + item[1] + "x)")
                        }
                    }
                    return result.length > 0 ? result.join(", ") : "None"
                }
                
                return "None"
            } catch (e) {
                return "Error"
            }
        }
        
        // Keyboard handling for scrolling
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                event.accepted = true
                statsScrollView.ScrollBar.vertical.decrease()
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                event.accepted = true
                statsScrollView.ScrollBar.vertical.increase()
            } else if (event.key === Qt.Key_PageUp) {
                event.accepted = true
                statsScrollView.ScrollBar.vertical.position = Math.max(0, statsScrollView.ScrollBar.vertical.position - 0.5)
            } else if (event.key === Qt.Key_PageDown) {
                event.accepted = true
                statsScrollView.ScrollBar.vertical.position = Math.min(1, statsScrollView.ScrollBar.vertical.position + 0.5)
            } else if (event.key === Qt.Key_Home) {
                event.accepted = true
                statsScrollView.ScrollBar.vertical.position = 0
            } else if (event.key === Qt.Key_End) {
                event.accepted = true
                statsScrollView.ScrollBar.vertical.position = 1
            }
        }
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(colors.surface, 1.1) }
            GradientStop { position: 1.0; color: Qt.darker(colors.surface, 1.1) }
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            // Header
            Text {
                text: statsDialog.showingNoteStats ? "Statistics" : "Overall Statistics"
                font.family: notesManager.config.fontFamily
                font.pixelSize: 24
                font.bold: true
                color: colors.helpDialogText
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            // Content
            ScrollView {
                id: statsScrollView
                width: parent.width
                height: parent.height - 60
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                clip: true
                
                Column {
                    width: parent.width
                    spacing: 15
                    
                    // Note-specific stats
                    Column {
                        id: noteStatsColumn
                        width: parent.width
                        spacing: 15
                        visible: statsDialog.showingNoteStats
                        
                        Text {
                            text: "Current Note: " + (statsDialog.currentStats.title || "Untitled")
                            font.family: notesManager.config.fontFamily
                            font.pixelSize: 16
                            font.bold: true
                            color: colors.accentColor
                            width: parent.width
                            height: 25
                            topPadding: 10
                            wrapMode: Text.WordWrap
                        }
                        
                        Grid {
                                columns: 2
                                spacing: 25
                                width: parent.width
                                
                                Column {
                                    spacing: 10
                                    width: parent.width / 2
                                    
                                    Text {
                                        text: "Characters: " + (statsDialog.currentStats.chars || 0) + " (no spaces: " + (statsDialog.currentStats.charsNoSpaces || 0) + ")"
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 13
                                        color: colors.textColor
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        text: "Words: " + (statsDialog.currentStats.words || 0) + " (unique: " + (statsDialog.currentStats.uniqueWords || 0) + ")"
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 13
                                        color: colors.textColor
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        text: "Lines: " + (statsDialog.currentStats.lines || 0)
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 13
                                        color: colors.textColor
                                    }
                                    Text {
                                        text: "Paragraphs: " + (statsDialog.currentStats.paragraphs || 0)
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 13
                                        color: colors.textColor
                                    }
                                    Text {
                                        text: "Sentences: " + (statsDialog.currentStats.sentences || 0)
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 13
                                        color: colors.textColor
                                    }
                                }
                                
                                Column {
                                    spacing: 10
                                    width: parent.width / 2
                                    
                                    Text {
                                        text: "Avg Word Length: " + (statsDialog.currentStats.averageWordLength || 0) + " letters"
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 13
                                        color: colors.textColor
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        text: "Avg Sentence Length: " + (statsDialog.currentStats.averageSentenceLength || 0) + " words"
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 13
                                        color: colors.textColor
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        text: "Lexical Diversity: " + (statsDialog.currentStats.lexicalDiversity || 0)
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 13
                                        color: colors.textColor
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        text: "Dialogue Lines: " + (statsDialog.currentStats.dialogueLines || 0)
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 13
                                        color: colors.textColor
                                    }
                                    Text {
                                        text: "Most Common: " + statsDialog.formatMostCommonWords()
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 13
                                        color: colors.textColor
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                            
                            // Time section
                            Text {
                                text: "Time"
                                font.family: notesManager.config.fontFamily
                                font.pixelSize: 16
                                font.bold: true
                                color: colors.accentColor
                                width: parent.width
                                height: 25
                                topPadding: 10
                            }
                            
                            Row {
                                spacing: 25
                                
                                Text {
                                    text: "Reading: " + statsDialog.formatReadingTime(statsDialog.currentStats.readingTimeMinutes || 0)
                                    font.family: notesManager.config.fontFamily
                                    font.pixelSize: 12
                                    color: colors.textColor
                                }
                                Text {
                                    text: "Speaking: " + statsDialog.formatReadingTime(statsDialog.currentStats.speakingTimeMinutes || 0)
                                    font.family: notesManager.config.fontFamily
                                    font.pixelSize: 12
                                    color: colors.textColor
                                }
                                Text {
                                    text: "Est. Writing Time: " + statsDialog.formatReadingTime(statsDialog.currentStats.estimatedWritingTimeMinutes || 0)
                                    font.family: notesManager.config.fontFamily
                                    font.pixelSize: 12
                                    color: colors.textColor
                                }
                            }
                            
                            
                            Text {
                                text: "Created: " + statsDialog.formatDate(statsDialog.currentStats.created)
                                font.family: notesManager.config.fontFamily
                                font.pixelSize: 12
                                color: colors.textColor
                                width: parent.width
                            }
                            Text {
                                text: "Modified: " + statsDialog.formatDate(statsDialog.currentStats.modified)
                                font.family: notesManager.config.fontFamily
                                font.pixelSize: 12
                                color: colors.textColor
                                width: parent.width
                            }
                    }
                    
                    // Overall stats
                    Column {
                        id: overallStatsColumn
                        width: parent.width
                        spacing: 15
                        visible: !statsDialog.showingNoteStats
                            
                            Text {
                                text: "All Collections Summary"
                                font.family: notesManager.config.fontFamily
                                font.pixelSize: 16
                                font.bold: true
                                color: colors.accentColor
                                width: parent.width
                                height: 25
                                topPadding: 10
                            }
                        
                        Grid {
                                columns: 2
                                spacing: 25
                                width: parent.width
                                
                                Column {
                                    spacing: 10
                                    width: parent.width / 2
                                    
                                    Text {
                                        text: "Total Notes: " + (statsDialog.currentStats.totalNotes || 0)
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 14
                                        color: colors.textColor
                                    }
                                    Text {
                                        text: "Total Words: " + (statsDialog.currentStats.totalWords || 0)
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 14
                                        color: colors.textColor
                                    }
                                    Text {
                                        text: "Total Characters: " + (statsDialog.currentStats.totalChars || 0)
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 14
                                        color: colors.textColor
                                    }
                                    Text {
                                        text: "Total Sentences: " + (statsDialog.currentStats.totalSentences || 0)
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 14
                                        color: colors.textColor
                                    }
                                    Text {
                                        text: "Total Paragraphs: " + (statsDialog.currentStats.totalParagraphs || 0)
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 14
                                        color: colors.textColor
                                    }
                                }
                                
                                Column {
                                    spacing: 10
                                    width: parent.width / 2
                                    
                                    Text {
                                        text: "Collections: " + (statsDialog.currentStats.collectionsCount || 0)
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 14
                                        color: colors.textColor
                                    }
                                }
                            }
                            
                            // Writing activity section
                            Text {
                                text: "Writing Activity"
                                font.family: notesManager.config.fontFamily
                                font.pixelSize: 16
                                font.bold: true
                                color: colors.accentColor
                                topPadding: 15
                            }
                            
                            Row {
                                spacing: 40
                                
                                Text {
                                    text: "Notes This Week: " + (statsDialog.currentStats.notesThisWeek || 0)
                                    font.family: notesManager.config.fontFamily
                                    font.pixelSize: 14
                                    color: colors.textColor
                                }
                                Text {
                                    text: "Notes This Month: " + (statsDialog.currentStats.notesThisMonth || 0)
                                    font.family: notesManager.config.fontFamily
                                    font.pixelSize: 14
                                    color: colors.textColor
                                }
                            }
                        }
                    }
                    
                    // Bottom padding
                    Item {
                        width: parent.width
                        height: 20
                    }
                }
            }
    }

    // Grid View Component
    Component {
        id: gridView
        
        Rectangle {
            color: colors.background
            
            Column {
                anchors.fill: parent
                anchors.topMargin: appState.modal === "search" ? 60 : 0
                
                Behavior on anchors.topMargin {
                    NumberAnimation { duration: 200 }
                }
                
                Rectangle {
                    width: parent.width
                    height: 130  
                    color: colors.background
                    z: 3
                    
                    Column {
                        anchors.fill: parent
                        
                        // Collection tabs
                        Rectangle {
                            width: parent.width
                            height: 50
                            color: colors.headerBgColor
                            visible: notesManager.collections.length > 0  // Only show if collections exist
                            
                            ScrollView {
                                anchors.fill: parent
                                anchors.margins: 5
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                                contentHeight: height
                                clip: true
                                
                                Row {
                                    height: parent.height
                                    spacing: 5
                                    
                                    Repeater {
                                        model: notesManager.collections
                                        
                                        Rectangle {
                                            height: 40
                                            width: Math.max(100, tabText.contentWidth + 20)
                                            color: modelData === notesManager.currentCollection ? 
                                                   colors.selectedColor : colors.cardColor
                                            border.color: modelData === notesManager.currentCollection ? 
                                                         colors.accentColor : colors.borderColor
                                            border.width: modelData === notesManager.currentCollection ? 2 : 1
                                            radius: 5
                                            
                                            Text {
                                                id: tabText
                                                text: modelData
                                                anchors.centerIn: parent
                                                font.family: notesManager.config.fontFamily
                                                font.pixelSize: 14
                                                font.bold: modelData === notesManager.currentCollection
                                                color: colors.textColor
                                                elide: Text.ElideRight
                                            }
                
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    if (modelData !== notesManager.currentCollection) {
                                                        if (appState.modal === "search") {
                                                            // Preserve search state when switching via tabs
                                                            notesManager.switchCollectionWithSearch(modelData, searchField.text)
                                                            // Keep search mode active and refocus
                                                            timerManager.scheduleFocus(searchField)
                                                        } else {
                                                            notesManager.switchCollection(modelData)
                                                        }
                                                        notification.show("Switched to: " + modelData, "success")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Add new collection button
                                    Rectangle {
                                        height: 40
                                        width: 80
                                        color: colors.cardColor
                                        border.color: colors.borderColor
                                        border.width: 1
                                        radius: 5
                                        
                                        Text {
                                            text: "+ New"
                                            anchors.centerIn: parent
                                            font.family: notesManager.config.fontFamily
                                            font.pixelSize: 12
                                            color: colors.secondaryText
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                appState.modal = "newCollection"
                                                timerManager.scheduleFocus(newCollectionField)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Main header
                        Rectangle {
                            width: parent.width
                            height: notesManager.collections.length > 0 ? 80 : 130
                            color: colors.headerBgColor
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                
                                Column {
                                    Layout.fillWidth: true

                                    Text {
                                        text: (notesManager.currentCollection || "Simple Notes") + (notesManager.searchText.trim() !== "" ? " - Search Mode" : "")
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 24
                                        color: colors.textColor
                                    }
                                    Text {
                                        text: notesManager.totalNotesInCollection + " notes"
                                        font.family: notesManager.config.fontFamily
                                        font.pixelSize: 12
                                        color: colors.secondaryText
                                        visible: notesManager.collections.length > 0
                                    }
                                }                   
                                Button {
                                    text: "New (" + notesManager.config.shortcuts.newNote + ")"
                                    enabled: !appState.hasModal() && notesManager.collections.length > 0
                                    onClicked: createNewNote()

                                    background: Rectangle {
                                        color: colors.accentColor
                                        radius: 5
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: Qt.darker(parent.background.color, 1.8)  // Darker version of background
                                        font.family: notesManager.config.fontFamily
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Notes grid section
                ScrollView {
                    width: parent.width
                    height: parent.height - (notesManager.collections.length > 0 ? 130 : 80)
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    visible: notesManager.collections.length > 0  // Only show if collections exist
                    
                    GridView {
                        id: notesGrid
                        focus: true
                        anchors.fill: parent

                        // Simple left-aligned layout with consistent margins
                        leftMargin: 20
                        rightMargin: 0
                        topMargin: 20
                        bottomMargin: 20

                        cellWidth: notesManager.config.cardWidth + 20
                        cellHeight: notesManager.config.cardHeight + 20
                        model: notesManager

                        Component.onCompleted: {
                            window.gridViewRef = notesGrid
                        }

                        // Enable built-in auto-scrolling
                        currentIndex: selectedNoteIndex
                        highlightFollowsCurrentItem: true
                        keyNavigationEnabled: false

                        // Optimize highlight positioning
                        preferredHighlightBegin: height * 0.2
                        preferredHighlightEnd: height * 0.8
                        highlightRangeMode: GridView.ApplyRange

                        // Performance optimizations
                        cacheBuffer: Math.max(0, height * 2)
                        displayMarginBeginning: 100
                        displayMarginEnd: 100

                        // React to selectedNoteIndex changes from window
                        Connections {
                            target: window
                            function onSelectedNoteIndexChanged() {
                                notesGrid.currentIndex = selectedNoteIndex
                            }
                        }

                        delegate: Rectangle {
                            id: noteCard
                            width: notesManager.config.cardWidth
                            height: notesManager.config.cardHeight
                            color: index === selectedNoteIndex ? 
                                    colors.selectedColor : 
                                    colors.cardColor
                            radius: 8
                            border.color: index === selectedNoteIndex ? 
                                            colors.accentColor : 
                                            colors.borderColor
                            border.width: index === selectedNoteIndex ? 3 : 1

                            states: [
                                State {
                                    name: "hovered"
                                    when: mouseArea.containsMouse && index !== selectedNoteIndex
                                    PropertyChanges {
                                        target: noteCard
                                        color: colors.hoverColor
                                    }
                                },
                                State {
                                    name: "selected"
                                    when: index === selectedNoteIndex
                                    PropertyChanges {
                                        target: noteCard
                                        color: colors.selectedColor
                                        border.color: colors.accentColor
                                    }
                                }
                            ]

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    selectedNoteIndex = index
                                    editNote(model.id)
                                }
                            }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 10
                                
                                Text {
                                    id: titleText
                                    text: model.title || ""
                                    font.family: notesManager.config.fontFamily
                                    font.pixelSize: notesManager.config.cardTitleFontSize
                                    font.bold: true
                                    color: index === selectedNoteIndex ? colors.selectedTextColor : colors.textColor
                                    width: parent.width
                                    height: 20
                                    elide: Text.ElideRight
                                    anchors.top: parent.top
                                    wrapMode: Text.NoWrap
                                }

                                Text {
                                    id: contentText
                                    text: {
                                        var content = model.content || ""
                                        var idx = content.indexOf("\n");
                                        return idx === -1 ? "" : content.slice(idx + 1);
                                    }
                                    font.family: notesManager.config.fontFamily
                                    font.pixelSize: notesManager.config.cardFontSize
                                    color: index === selectedNoteIndex ? 
                                            colors.selectedSecondaryTextColor : 
                                            colors.secondaryText
                                    width: parent.width
                                    anchors.top: titleText.bottom
                                    anchors.topMargin: 5
                                    anchors.bottom: timestampText.top
                                    anchors.bottomMargin: 5
                                    wrapMode: Text.WordWrap
                                    clip: true
                                }

                                Text {
                                    id: timestampText
                                    text: {
                                        var modified = model.modified || ""
                                        if (modified) {
                                            var date = new Date(modified)
                                            var now = new Date()
                                            var diff = now - date
                                            var days = Math.floor(diff / (1000 * 60 * 60 * 24))

                                            if (days === 0) return "Today"
                                            else if (days === 1) return "Yesterday"
                                            else if (days < 7) return days + " days ago"
                                            else return date.toLocaleDateString()
                                        }
                                        return ""
                                    }
                                    font.family: notesManager.config.fontFamily
                                    font.pixelSize: Math.min(notesManager.config.cardWidth *.05, 14)
                                    color: colors.secondaryText
                                    opacity: 0.5
                                    width: parent.width
                                    height: 12
                                    anchors.bottom: parent.bottom
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Note Editor Component
    Component {
        id: noteEditor
        
        Rectangle {
            color: colors.editorBackground
            
            StackView.onStatusChanged: {
                if (StackView.status === StackView.Active && !appState.hasModal()) {
                    timerManager.scheduleFocus(contentArea)
                }
            }
            
            Column {
                anchors.fill: parent
                
                // Editor header
                Rectangle {
                    width: parent.width
                    height: 60
                    color: colors.headerBgColor
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15

                        Button {
                            text: "← Back (" + notesManager.config.shortcuts.back + ")"
                            onClicked: {
                                saveCurrentNote()
                                showGridView()
                            }

                            background: Rectangle {
                                color: colors.cardColor
                                border.color: colors.borderColor
                                border.width: 1
                                radius: 5
                            }

                            contentItem: Text {
                                text: parent.text
                                color: Qt.darker(parent.background.color, 1.8)  // Darker version of background
                                font.family: notesManager.config.fontFamily
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Text {
                            text: currentNote.title || "New Note"
                            font.family: notesManager.config.fontFamily
                            font.pixelSize: 16
                            color: colors.textColor
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.leftMargin: 15
                        }
                        
                        Text {
                            text: "Auto-saved"
                            font.family: notesManager.config.fontFamily
                            font.pixelSize: 12
                            color: colors.secondaryText
                            Layout.rightMargin: 15
                        }
                        Button {
                            text: "Delete (" + notesManager.config.shortcuts.quickDelete + ")"
                            visible: currentNoteId >= 0
                            onClicked: {
                                appState.modal = "delete"
                                window.forceActiveFocus()
                            }

                            background: Rectangle {
                                color: colors.deleteButtonColor
                                radius: 5
                            }

                            contentItem: Text {
                                text: parent.text
                                color: Qt.darker(parent.background.color, 1.8)  // Darker version of background
                                font.family: notesManager.config.fontFamily
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
                
                // Text editing area
                Rectangle {
                    width: parent.width
                    height: parent.height - 60
                    color: colors.editorBackground
                    
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 20
                        
                        TextArea {
                            id: contentArea
                            objectName: "contentArea"
                            placeholderText: "Start writing your note...\n\nThe first line will become your note's title automatically."             
                            placeholderTextColor: colors.placeholderColor
                            text: currentNote.content || ""
                            font.family: notesManager.config.fontFamily
                            font.pixelSize: notesManager.config.fontSize
                            color: colors.textColor
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            
                            Component.onCompleted: {
                                if (!appState.hasModal()) {
                                    forceActiveFocus()
                                    cursorPosition = length
                                }
                            }
                            
                            onTextChanged: {
                                currentNote.content = text
                                unsavedChanges++
                                
                                // Update title in real-time
                                if (text.trim()) {
                                    var firstLine = text.split('\n')[0].trim()
                                    // Remove any markdown headers
                                    firstLine = firstLine.replace(/^#+\s*/, '')
                                    if (firstLine.length > 50) {
                                        firstLine = firstLine.substring(0, 47) + "..."
                                    }
                                    currentNote.title = firstLine || "Untitled Note"
                                } else {
                                    currentNote.title = "New Note"
                                }
                                
                                // Trigger update for the title display
                                currentNote = currentNote  // This forces a property change notification
                                
                                // Force save if too many unsaved changes (silently)
                                if (unsavedChanges >= notesManager.config.maxUnsavedChanges) {
                                    saveCurrentNote()
                                } else {
                                    // Normal auto-save timer
                                    autoSaveTimer.restart()
                                }
                            }
                            
                            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_D && (event.modifiers & Qt.ControlModifier)) {
                                    event.accepted = true
                                    appState.modal = "delete"
                                    window.forceActiveFocus()
                                }
                            }
                            
                            background: Rectangle {
                                color: colors.cardColor
                                radius: 5
                                border.color: parent.activeFocus ? colors.focusBorderColor : colors.transparentColor
                                border.width: 2
                            }
                        }
                    }
                }
            }
        }
    }
}