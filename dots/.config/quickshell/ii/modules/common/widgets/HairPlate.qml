import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// hairline: плоская плашка под иконку — поверхность, линия 1px, без тени.
Item {
    id: root
    property alias text: symbol.text
    property alias iconSize: symbol.iconSize
    property alias font: symbol.font
    property alias colSymbol: symbol.color
    property real padding: 6
    property color color: Appearance.colors.colLayer2
    property int shape: 0 // совместимость со старым API
    property real implicitSize: Math.max(symbol.implicitWidth, symbol.implicitHeight) + padding * 2

    implicitWidth: implicitSize
    implicitHeight: implicitSize
    colSymbol: Appearance.colors.colOnLayer2

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: root.color
        border.width: 1
        border.color: Appearance.colors.colHairline
    }

    MaterialSymbol {
        id: symbol
        anchors.centerIn: parent
        color: root.colSymbol
    }
}
