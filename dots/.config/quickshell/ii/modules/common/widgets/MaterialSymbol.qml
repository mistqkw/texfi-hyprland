import qs.modules.common
import QtQuick

StyledText {
    id: root
    property real iconSize: Appearance?.font.pixelSize.small ?? 16
    property real fill: 0
    property real truncatedFill: fill.toFixed(1) // Reduce memory consumption spikes from constant font remapping
    renderType: Text.NativeRendering
    font {
        hintingPreference: Font.PreferNoHinting
        family: Appearance?.font.family.iconMaterial ?? "Material Symbols Rounded"
        // Размер всегда настоящий: он же определяет implicitWidth/Height
        // текста, от которых зависит фактический размер всего элемента
        // (и, соответственно, Canvas ниже через anchors.fill: parent).
        // Занижать его ради "спрятать глиф" нельзя — так схлопывается
        // размер всего виджета, не только буквы.
        pixelSize: iconSize
        variableAxes: {
            "FILL": truncatedFill,
            "wght": 300, // hairline: линия 1.5px
            // "wght": font.weight,
            // "GRAD": 0,
            "opsz": iconSize,
        }
    }

    Behavior on fill { // Leaky leaky, no good
        NumberAnimation {
            duration: Appearance?.animation.elementMoveFast.duration ?? 200
            easing.type: Appearance?.animation.elementMoveFast.type ?? Easing.BezierSpline
            easing.bezierCurve: Appearance?.animation.elementMoveFast.bezierCurve ?? [0.34, 0.80, 0.34, 1.00, 1, 1]
        }
    }
}
