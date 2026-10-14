import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    property string title
    property string icon: ""
    default property alias contentData: sectionContent.data

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        spacing: 6
        OptionalMaterialSymbol {
            icon: root.icon
            iconSize: Appearance.font.pixelSize.hugeass
        }
        StyledText {
            // TexFi: заголовок секции переведён (Translation.tr), а Press
            // Start 2P не содержит кириллицу и другие не-латинские алфавиты —
            // подстановка системного шрифта на буквы ломает метрики строки
            // и текст наезжает на соседние элементы. Держим обычный читаемый
            // шрифт, но чуть крупнее и с более смелым начертанием.
            text: root.title
            font.family: Appearance.font.family.main
            font.pixelSize: Appearance.font.pixelSize.small
            font.variableAxes: Appearance.font.variableAxes.title
            color: Appearance.colors.colOnSecondaryContainer
        }
    }

    ColumnLayout {
        id: sectionContent
        Layout.fillWidth: true
        spacing: 4

    }
}
