pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item { // Player instance
    id: root
    required property MprisPlayer player
    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property bool downloaded: false
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000 // Max value in the data points
    property int visualizerSmoothing: 2 // Number of points to average for smoothing
    property real radius

    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""

    component TrackChangeButton: RippleButton {
        implicitWidth: 28
        implicitHeight: 28
        property var iconName
        rippleEnabled: false
        buttonRadius: Appearance.rounding.small
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colRipple: "transparent"

        contentItem: MaterialSymbol {
            iconSize: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: parent.hovered ? Appearance.colors.colTextPrimary : Appearance.colors.colTextSecondary
            text: iconName
            Behavior on color { ColorAnimation { duration: 160 * Appearance.motionScale } }
        }
    }

    Timer { // Force update for revision
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: {
            root.player.positionChanged()
        }
    }

    onArtFilePathChanged: {
        if (root.artUrl.length == 0) {
            root.artDominantColor = Appearance.m3colors.m3secondaryContainer
            return;
        }

        // Binding does not work in Process
        coverArtDownloader.targetFile = root.artUrl 
        coverArtDownloader.artFilePath = root.artFilePath
        // Download
        root.downloaded = false
        coverArtDownloader.running = true
    }

    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'` ]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = true
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }

    Rectangle { // hairline-карточка плеера
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: Appearance.colors.colLayer1Base
        radius: Appearance.rounding.normal
        border.width: 1
        border.color: Appearance.colors.colHairline

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 16

            Rectangle { // обложка
                Layout.fillHeight: true
                implicitWidth: height
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2Base
                border.width: 1
                border.color: Appearance.colors.colHairline
                clip: true

                StyledImage {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    asynchronous: true
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: root.displayedArtFilePath === ""
                    text: "music_note"
                    iconSize: 28
                    color: Appearance.colors.colTextTertiary
                }
            }

            ColumnLayout { // название и управление
                Layout.fillHeight: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colTextPrimary
                    elide: Text.ElideRight
                    text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Untitled"
                    animateChange: true
                    animationDistanceX: 6
                    animationDistanceY: 0
                }
                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colTextSecondary
                    elide: Text.ElideRight
                    text: root.player?.trackArtist ?? ""
                    animateChange: true
                    animationDistanceX: 6
                    animationDistanceY: 0
                }
                Item { Layout.fillHeight: true }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: trackTime.implicitHeight + sliderRow.implicitHeight + 8

                    StyledText {
                        id: trackTime
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 6
                        anchors.left: parent.left
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: 11
                        font.letterSpacing: 0.8
                        color: Appearance.colors.colTextTertiary
                        text: `${StringUtils.friendlyTimeForSeconds(root.player?.position)} / ${StringUtils.friendlyTimeForSeconds(root.player?.length)}`
                    }

                    RowLayout {
                        id: sliderRow
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        spacing: 4

                        TrackChangeButton {
                            iconName: "skip_previous"
                            downAction: () => root.player?.previous()
                        }

                        Item { // тонкая линия прогресса, по ней можно перематывать
                            id: progressLine
                            Layout.fillWidth: true
                            implicitHeight: 20
                            readonly property real frac: Math.max(0, Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1)))

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 1
                                color: Appearance.colors.colHairline
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * progressLine.frac
                                height: 2
                                color: Appearance.colors.colPrimary
                                Behavior on width { NumberAnimation { duration: 200 * Appearance.motionScale } }
                            }
                            Rectangle { // точка-ползунок
                                visible: seekArea.enabled
                                x: parent.width * progressLine.frac - width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: seekArea.containsMouse || seekArea.pressed ? 9 : 5
                                height: width
                                radius: width / 2
                                color: Appearance.colors.colTextPrimary
                                Behavior on width { NumberAnimation { duration: 140 * Appearance.motionScale } }
                            }
                            MouseArea {
                                id: seekArea
                                anchors.fill: parent
                                enabled: root.player?.canSeek ?? false
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                function seek(mx) {
                                    root.player.position = Math.max(0, Math.min(1, mx / width)) * root.player.length;
                                }
                                onPressed: (mouse) => seek(mouse.x)
                                onPositionChanged: (mouse) => { if (pressed) seek(mouse.x) }
                            }
                        }

                        TrackChangeButton {
                            iconName: "skip_next"
                            downAction: () => root.player?.next()
                        }
                    }

                    RippleButton { // пуск/пауза: белая заливка, при наведении пустая
                        id: playPauseButton
                        anchors.right: parent.right
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 6
                        implicitWidth: 40
                        implicitHeight: 40
                        rippleEnabled: false
                        buttonRadius: Appearance.rounding.small
                        downAction: () => root.player.togglePlaying();
                        colBackground: Appearance.colors.colTextPrimary
                        colBackgroundHover: "transparent"
                        transform: Translate { y: playPauseButton.down ? 1 : 0 }

                        Rectangle {
                            anchors.fill: parent
                            z: 1
                            radius: playPauseButton.buttonRadius
                            color: "transparent"
                            border.width: 1
                            border.color: Appearance.colors.colTextPrimary
                        }
                        contentItem: MaterialSymbol {
                            iconSize: 24
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: playPauseButton.hovered ? Appearance.colors.colTextPrimary : Appearance.colors.colLayer0Base
                            text: root.player?.isPlaying ? "pause" : "play_arrow"
                        }
                    }
                }
            }
        }
    }
}
