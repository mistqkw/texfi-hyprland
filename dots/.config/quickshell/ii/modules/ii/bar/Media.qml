import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + 20
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    // hairline-кнопка: рамка, при наведении светлеет, нажатие — сдвиг на 1px
    Rectangle {
        id: pill
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        radius: Appearance.rounding.small
        color: mouseArea.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
        border.width: 1
        border.color: mouseArea.containsMouse ? Appearance.colors.colTextSecondary : Appearance.colors.colHairline
        transform: Translate { y: mouseArea.pressed ? 1 : 0 }
        Behavior on color { ColorAnimation { duration: 160 * Appearance.motionScale } }
        Behavior on border.color { ColorAnimation { duration: 160 * Appearance.motionScale } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            }
        }
    }

    RowLayout { // Real content
        id: rowLayout

        spacing: 8
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        // hairline: тонкое кольцо прогресса с иконкой
        Item {
            id: mediaCircProg
            Layout.alignment: Qt.AlignVCenter
            property int implicitSize: 20
            implicitWidth: implicitSize
            implicitHeight: implicitSize

            HairRing {
                anchors.fill: parent
                segmentsCount: 12
                ringWidthRatio: 0.36
                progress: activePlayer?.position / activePlayer?.length || 0
                accentColor: Appearance.colors.colPrimary
                trackColor: Appearance.colors.colHairline
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: activePlayer?.isPlaying ? "pause" : "music_note"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colTextPrimary
            }
        }

        StyledText {
            visible: Config.options.bar.verbose
            width: rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2)
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true // Ensures the text takes up available space
            Layout.rightMargin: rowLayout.spacing
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight // Truncates the text on the right
            color: activePlayer ? Appearance.colors.colTextPrimary : Appearance.colors.colTextTertiary
            text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
        }

    }

}
