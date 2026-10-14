import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

StyledText {
    // TexFi: не пиксельный шрифт — это переведённый текст (Translation.tr),
    // а Press Start 2P не содержит кириллицу и другие не-латинские алфавиты.
    // Подстановка системного шрифта на отдельные буквы ломает метрики строки
    // и текст наезжает на соседние элементы (баг в диалогах Wi-Fi/Bluetooth).
    text: "Dialog Title"
    color: Appearance.colors.colOnSurface
    wrapMode: Text.Wrap
    font {
        family: Appearance.font.family.main
        pixelSize: Appearance.font.pixelSize.title
        variableAxes: Appearance.font.variableAxes.title
    }
}
