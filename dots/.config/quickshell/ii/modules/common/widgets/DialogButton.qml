import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

/**
 * hairline: текстовая кнопка диалога — моно 11px, верхний регистр, без пилюли.
 */
RippleButton {
    id: root

    property string buttonText
    padding: 14
    implicitHeight: 36
    implicitWidth: buttonTextWidget.implicitWidth + padding * 2
    buttonRadius: Appearance?.rounding.small ?? 3

    property color colEnabled: Appearance?.colors.colPrimary ?? "#65558F"
    property color colDisabled: Appearance?.m3colors.m3outline ?? "#8D8C96"
    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer3)
    colBackgroundHover: Appearance.colors.colLayer3Hover
    colRipple: Appearance.colors.colLayer3Active
    property alias colText: buttonTextWidget.color

    contentItem: StyledText {
        id: buttonTextWidget
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        text: buttonText.toUpperCase()
        horizontalAlignment: Text.AlignHCenter
        font.family: Appearance.font.family.monospace
        font.pixelSize: 11
        font.letterSpacing: 1.2
        color: root.enabled ? root.colEnabled : root.colDisabled

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

}
