pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Column {
    id: root
    property list<string> clockNumbers: DateTime.time.split(/[: ]/)
    property bool isEnabled: Config.options.background.widgets.clock.cookie.timeIndicators
    property color color: Appearance.colors.colOnSecondaryContainer

    property bool hourMarksEnabled: Config.options.background.widgets.clock.cookie.hourMarks
    spacing: -16

    Repeater {
        model: root.clockNumbers

        delegate: StyledText {
            required property string modelData
            text: modelData.padStart(2, "0")
            property bool isAmPm: !text.match(/\d{2}/i)
            property real numberSizeWithoutGlow: isAmPm ? 26 : 68
            property real numberSizeWithGlow: isAmPm ? 20 : 40
            property real numberSize: root.hourMarksEnabled ? numberSizeWithGlow : numberSizeWithoutGlow

            anchors.horizontalCenter: root.horizontalCenter
            color: root.color
            font {
                // TexFi: самое крупное акцентное число во всей оболочке —
                // цифры фиксированы пиксельным шрифтом напрямую, а не через
                // общую роль "expressive" (та же роль стоит на мелких значках
                // номеров рабочих столов, и переключать её всю сразу — заносить
                // пиксельный шрифт туда, где его быть не должно).
                family: "Press Start 2P"
                weight: Font.Normal
                pixelSize: numberSize
            }

            Behavior on numberSize {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
        }
    }
}
