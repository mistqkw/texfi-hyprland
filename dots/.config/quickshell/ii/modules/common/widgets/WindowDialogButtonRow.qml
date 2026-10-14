import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

RowLayout {
    id: root
    spacing: 4

    // TexFi: -8 тут компенсировал скруглённый угол диалога Material —
    // тянул кнопки наружу, чтобы они не "утопали" из-за радиуса. Теперь
    // Appearance.rounding.large = 0, отступ контента и так нулевой, и
    // старая компенсация выталкивала кнопки за острый край диалога.
    Layout.margins: 0
}
