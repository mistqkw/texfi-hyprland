import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    implicitHeight: contentColumn.implicitHeight
    implicitWidth: contentColumn.implicitWidth

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 0

        // The countdown ring — TexFi: сегментированное кольцо как в
        // texfi_fokus (TimerDial), а не гладкая Material-дуга.
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 200
            implicitHeight: 200

            PixelTimerRing {
                anchors.fill: parent
                progress: TimerService.countdownSecondsLeft / TimerService.countdownDuration
                accentColor: "#4a7dfb"
                trackColor: Appearance.colors.colLayer2

                Behavior on progress {
                    NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        let minutes = Math.floor(TimerService.countdownSecondsLeft / 60).toString().padStart(2, '0');
                        let seconds = Math.floor(TimerService.countdownSecondsLeft % 60).toString().padStart(2, '0');
                        return `${minutes}:${seconds}`;
                    }
                    font.family: Appearance.font.family.title
                    font.pixelSize: 22
                    color: Appearance.m3colors.m3onSurface
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Timer")
                    font.family: Appearance.font.family.title
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: "#4a7dfb"
                }
            }
        }

        // Duration adjustment (only while not running and not started)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5
            spacing: 10
            visible: !TimerService.countdownRunning

            RippleButton {
                implicitHeight: 30
                implicitWidth: 40
                enabled: TimerService.countdownDuration > 60
                onClicked: TimerService.setCountdownDuration(TimerService.countdownDuration - 60)
                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: "-1m"
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer2
                }
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
            }

            RippleButton {
                implicitHeight: 30
                implicitWidth: 40
                onClicked: TimerService.setCountdownDuration(TimerService.countdownDuration + 60)
                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: "+1m"
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer2
                }
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
            }
        }

        // The Start/Stop and Reset buttons
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            spacing: 10

            RippleButton {
                contentItem: StyledText {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: TimerService.countdownRunning ? Translation.tr("Pause") : (TimerService.countdownSecondsLeft === TimerService.countdownDuration) ? Translation.tr("Start") : Translation.tr("Resume")
                    color: TimerService.countdownRunning ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                }
                implicitHeight: 35
                implicitWidth: 90
                font.pixelSize: Appearance.font.pixelSize.larger
                enabled: TimerService.countdownSecondsLeft > 0
                onClicked: TimerService.toggleCountdown()
                colBackground: TimerService.countdownRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
                colBackgroundHover: TimerService.countdownRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
            }

            RippleButton {
                implicitHeight: 35
                implicitWidth: 90

                onClicked: TimerService.resetCountdown()
                enabled: TimerService.countdownSecondsLeft < TimerService.countdownDuration

                font.pixelSize: Appearance.font.pixelSize.larger
                colBackground: Appearance.colors.colErrorContainer
                colBackgroundHover: Appearance.colors.colErrorContainerHover
                colRipple: Appearance.colors.colErrorContainerActive

                contentItem: StyledText {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: Translation.tr("Reset")
                    color: Appearance.colors.colOnErrorContainer
                }
            }
        }
    }
}
