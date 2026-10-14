import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

// hairline: плоская кнопка — линия 1px, радиус 10, без тени.
// Фокус/наведение: рамка становится основным цветом, фон чуть светлее.
RippleButton {
    id: button

    property string buttonIcon
    property string buttonText
    property string hotkey
    property bool keyboardDown: false
    property real size: 120
    readonly property bool lit: button.focus || button.hovered
    readonly property bool isDown: button.down || button.keyboardDown

    buttonRadius: Appearance.rounding.normal
    colBackground: Appearance.colors.colLayer1
    colBackgroundHover: Appearance.colors.colLayer2
    colRipple: Appearance.colors.colLayer2Active
    property color colText: button.lit ? Appearance.colors.colTextPrimary : Appearance.colors.colOnLayer0

    Binding {
        target: button.background
        property: "color"
        value: button.lit ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1
    }

    // нажатие — сдвиг на 1px вниз
    transform: Translate { y: button.isDown ? 1 : 0 }

    // линия поверх фона
    Rectangle {
        anchors.fill: parent
        z: 1
        radius: button.buttonRadius
        color: "transparent"
        border.width: 1
        border.color: button.lit ? Appearance.colors.colTextPrimary : Appearance.colors.colHairline
    }

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    background.implicitHeight: size
    background.implicitWidth: size

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = true
            button.clicked()
            event.accepted = true;
        }
    }
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = false
            event.accepted = true;
        }
    }

    contentItem: MaterialSymbol {
        id: icon
        anchors.fill: parent
        color: button.colText
        horizontalAlignment: Text.AlignHCenter
        iconSize: 44
        text: buttonIcon
    }

    // горячая клавиша — моно 11px, верхний регистр, как подпись в hairline
    StyledText {
        visible: button.hotkey !== ""
        anchors { left: parent.left; top: parent.top; leftMargin: 10; topMargin: 8 }
        z: 2
        text: button.hotkey
        font.family: Appearance.font.family.monospace
        font.pixelSize: 11
        font.letterSpacing: 1.2
        color: button.lit ? Appearance.colors.colPrimary : Appearance.colors.colTextTertiary
    }

    StyledToolTip {
        text: buttonText
    }

}
