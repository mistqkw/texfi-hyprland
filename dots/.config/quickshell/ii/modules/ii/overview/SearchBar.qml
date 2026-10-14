pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RowLayout {
    id: root
    spacing: 6
    property bool animateWidth: false
    property real reveal: 1
    // поочерёдное проявление: i-й элемент стартует с задержкой 0.12 от reveal
    function stage(i) { return Math.max(0, Math.min(1, (reveal - i * 0.12) / 0.55)); }
    property alias searchInput: searchInput
    property string searchingText

    function forceFocus() {
        searchInput.forceActiveFocus();
    }

    enum SearchPrefixType { Action, App, Clipboard, Emojis, Math, ShellCommand, WebSearch, DefaultSearch }

    property var searchPrefixType: {
        if (root.searchingText.startsWith(Config.options.search.prefix.action)) return SearchBar.SearchPrefixType.Action;
        if (root.searchingText.startsWith(Config.options.search.prefix.app)) return SearchBar.SearchPrefixType.App;
        if (root.searchingText.startsWith(Config.options.search.prefix.clipboard)) return SearchBar.SearchPrefixType.Clipboard;
        if (root.searchingText.startsWith(Config.options.search.prefix.emojis)) return SearchBar.SearchPrefixType.Emojis;
        if (root.searchingText.startsWith(Config.options.search.prefix.math)) return SearchBar.SearchPrefixType.Math;
        if (root.searchingText.startsWith(Config.options.search.prefix.shellCommand)) return SearchBar.SearchPrefixType.ShellCommand;
        if (root.searchingText.startsWith(Config.options.search.prefix.webSearch)) return SearchBar.SearchPrefixType.WebSearch;
        return SearchBar.SearchPrefixType.DefaultSearch;
    }
    
    Item {
        id: searchIcon
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 40
        implicitHeight: 40
        opacity: root.stage(0)
        transform: Translate { x: (1 - root.stage(0)) * -10 }
        property string iconName: switch (root.searchPrefixType) {
            case SearchBar.SearchPrefixType.Action: return "settings_suggest";
            case SearchBar.SearchPrefixType.App: return "apps";
            case SearchBar.SearchPrefixType.Clipboard: return "content_paste_search";
            case SearchBar.SearchPrefixType.Emojis: return "add_reaction";
            case SearchBar.SearchPrefixType.Math: return "calculate";
            case SearchBar.SearchPrefixType.ShellCommand: return "terminal";
            case SearchBar.SearchPrefixType.WebSearch: return "travel_explore";
            default: return "search";
        }
        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: Appearance.font.pixelSize.huge
            text: searchIcon.iconName
            animateChange: true // смена режима поиска — короткое перетекание значка
            color: searchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
    ToolbarTextField { // Search box
        id: searchInput
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 40
        colBackground: "transparent"
        opacity: root.stage(1)
        transform: Translate { x: (1 - root.stage(1)) * -10 }
        focus: GlobalStates.overviewOpen
        font.pixelSize: Appearance.font.pixelSize.small
        placeholderText: Translation.tr("Search, calculate or run")
        implicitWidth: root.searchingText == "" ? Appearance.sizes.searchWidthCollapsed : Appearance.sizes.searchWidth

        Behavior on implicitWidth {
            id: searchWidthBehavior
            enabled: root.animateWidth
            NumberAnimation {
                duration: 300
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        onTextChanged: LauncherSearch.query = text

        onAccepted: {
            if (appResults.count > 0) {
                // Get the first visible delegate and trigger its click
                let firstItem = appResults.itemAtIndex(0);
                if (firstItem && firstItem.clicked) {
                    firstItem.clicked();
                }
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab) {
                if (LauncherSearch.results.length === 0) return;
                const tabbedText = LauncherSearch.results[0].name;
                LauncherSearch.query = tabbedText;
                searchInput.text = tabbedText;
                event.accepted = true;
            }
        }
    }

    IconToolbarButton {
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        opacity: root.stage(2)
        transform: Translate { x: (1 - root.stage(2)) * -10 }
        onClicked: {
            GlobalStates.overviewOpen = false;
            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "search"]);
        }
        text: "image_search"
        StyledToolTip {
            text: Translation.tr("Google Lens")
        }
    }

    IconToolbarButton {
        id: songRecButton
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        Layout.rightMargin: 4
        toggled: SongRec.running
        onClicked: SongRec.toggleRunning()
        text: "music_cast"

        StyledToolTip {
            text: Translation.tr("Recognize music")
        }

        opacity: root.stage(3)
        transform: Translate { x: (1 - root.stage(3)) * -10 }

        colText: toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
        background: Item {
            Rectangle {
                id: songRecPlate
                anchors.fill: parent
                radius: Appearance.rounding.small
                color: songRecButton.hovered ? Appearance.colors.colLayer2 : "transparent"
                border.width: 1
                border.color: songRecButton.toggled ? Appearance.colors.colPrimary
                    : (songRecButton.hovered ? Appearance.colors.colHairline : "transparent")
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                Behavior on border.color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
            // пока слушает — кольцо «дышит» вокруг кнопки
            Rectangle {
                id: songRecPulse
                anchors.fill: parent
                anchors.margins: -3
                radius: Appearance.rounding.small + 3
                color: "transparent"
                border.width: 1
                border.color: Appearance.colors.colPrimary
                opacity: 0
                visible: songRecButton.toggled
                SequentialAnimation on opacity {
                    running: songRecButton.toggled && Appearance.motionScale > 0
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.0; to: 0.8; duration: 900; easing.type: Easing.OutCubic }
                    NumberAnimation { from: 0.8; to: 0.0; duration: 900; easing.type: Easing.InCubic }
                }
            }
        }
    }
}
