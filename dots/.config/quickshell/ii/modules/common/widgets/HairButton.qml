import qs.modules.common
import qs.modules.common.widgets
import QtQuick

// hairline-кнопка. primary: заливка основным цветом текста, при наведении
// «пустая» (прозрачная, текст основной). ghost: прозрачная, рамка hairline,
// при наведении рамка становится основной. Нажатие — сдвиг на 1px вниз.
RippleButton {
    id: root

    property bool primary: true
    property color colLabel: primary
        ? (hovered ? Appearance.colors.colTextPrimary : Appearance.colors.colLayer0Base)
        : Appearance.colors.colTextPrimary

    rippleEnabled: false
    buttonRadius: Appearance.rounding.small
    padding: 0
    implicitHeight: 36
    implicitWidth: label.implicitWidth + 44

    colBackground: primary ? Appearance.colors.colTextPrimary : "transparent"
    colBackgroundHover: primary ? "transparent" : "transparent"
    colBackgroundToggled: colBackground
    colBackgroundToggledHover: colBackgroundHover

    transform: Translate { y: root.down ? 1 : 0 }

    Rectangle {
        anchors.fill: parent
        z: 1
        radius: root.buttonRadius
        color: "transparent"
        border.width: 1
        border.color: root.primary ? Appearance.colors.colTextPrimary
            : (root.hovered ? Appearance.colors.colTextPrimary : Appearance.colors.colHairline)
    }

    contentItem: StyledText {
        id: label
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.buttonText.toUpperCase()
        font.family: Appearance.font.family.monospace
        font.pixelSize: 11
        font.letterSpacing: 1.2
        color: root.colLabel
    }
}
