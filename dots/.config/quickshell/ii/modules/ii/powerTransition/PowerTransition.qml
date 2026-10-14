pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.functions

// hairline-анимации включения и выключения.
//  intro  — при входе: чёрный экран, по центру пробегает тонкая линия, створки раскрываются
//           вверх и вниз, расходятся кольца.
//  outro  — перед выключением/перезагрузкой/выходом: кольца сходятся, створки смыкаются,
//           линия сжимается в точку; только после этого выполняется действие.
// Запасные выходы: таймеры гарантируют, что оверлей не зависнет, а действие выполнится.
Scope {
    id: root

    property bool active: false
    property real cover: 1      // 1 — створки сомкнуты (экран закрыт), 0 — раскрыты
    property real lineW: 0      // ширина центральной линии, 0..1
    property real lineOp: 1
    property real ringT: 0      // 0 — кольца в центре, 1 — разошлись; прозрачность = 1 - ringT
    property real dotOp: 0
    property string pendingAction: ""
    property bool actionRan: false
    readonly property real k: Appearance.motionScale
    readonly property color accent: Appearance.colors.colPrimary
    readonly property color paper: "#0a0a0c"

    function runAction() {
        if (root.actionRan) return;
        root.actionRan = true;
        if (root.pendingAction !== "" && typeof Session[root.pendingAction] === "function")
            Session[root.pendingAction]();
        else
            root.active = false; // тестовый прогон без действия
    }

    function playIntro() {
        if (root.k === 0 || root.active) return;
        introAnim.restart();
        safetyTimer.restart();
    }

    function playOutro(action) {
        root.pendingAction = action;
        root.actionRan = false;
        if (root.k === 0) { root.runAction(); return; }
        outroAnim.restart();
        outroFallback.restart();
    }

    Component.onCompleted: GlobalStates.powerTransitionReady = true
    Component.onDestruction: GlobalStates.powerTransitionReady = false

    Connections {
        target: GlobalStates
        function onPowerOutroRequested(action) { root.playOutro(action); }
    }

    IpcHandler {
        target: "powerTransition"
        function intro(): void { root.playIntro(); }
        // outro("") — только показать анимацию, без действия
        function outro(action: string): void { root.playOutro(action); }
    }

    Timer { id: safetyTimer; interval: 3500; onTriggered: if (!outroAnim.running) root.active = false }
    Timer { id: outroFallback; interval: 2600; onTriggered: root.runAction() }

    SequentialAnimation {
        id: introAnim
        ScriptAction { script: { root.cover = 1; root.lineW = 0; root.lineOp = 1; root.ringT = 0; root.dotOp = 0; root.active = true; } }
        NumberAnimation { target: root; property: "lineW"; to: 1; duration: 420 * root.k; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.texfiEnter }
        ParallelAnimation {
            NumberAnimation { target: root; property: "cover"; to: 0; duration: 760 * root.k; easing.type: Easing.InOutCubic }
            NumberAnimation { target: root; property: "lineOp"; to: 0; duration: 520 * root.k; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "ringT"; to: 1; duration: 1000 * root.k; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: root.active = false }
    }

    SequentialAnimation {
        id: outroAnim
        ScriptAction { script: { root.cover = 0; root.lineW = 1; root.lineOp = 0; root.ringT = 1; root.dotOp = 0; root.active = true; } }
        ParallelAnimation {
            NumberAnimation { target: root; property: "cover"; to: 1; duration: 580 * root.k; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "ringT"; to: 0; duration: 580 * root.k; easing.type: Easing.InCubic }
        }
        NumberAnimation { target: root; property: "lineOp"; to: 1; duration: 60 * root.k }
        ParallelAnimation {
            NumberAnimation { target: root; property: "lineW"; to: 0; duration: 380 * root.k; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "dotOp"; to: 1; duration: 380 * root.k; easing.type: Easing.InCubic }
        }
        PauseAnimation { duration: 140 * root.k }
        NumberAnimation { target: root; property: "dotOp"; to: 0; duration: 140 * root.k }
        ScriptAction { script: root.runAction() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: root.active
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:powerTransition"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            Item {
                id: stage
                anchors.fill: parent

                Rectangle { // верхняя створка
                    width: stage.width
                    height: Math.ceil(stage.height / 2)
                    y: -(1 - root.cover) * height
                    color: root.paper
                }
                Rectangle { // нижняя створка
                    width: stage.width
                    height: Math.ceil(stage.height / 2)
                    y: stage.height / 2 + (1 - root.cover) * height
                    color: root.paper
                }

                Rectangle { // центральная линия
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: stage.width * root.lineW
                    height: 1
                    color: root.accent
                    opacity: root.lineOp
                }

                Repeater { // кольца
                    model: 3
                    delegate: Rectangle {
                        required property int index
                        readonly property real t: Math.max(0, Math.min(1, root.ringT * (1 + index * 0.18) - index * 0.06))
                        readonly property real r: Math.max(1, t * Math.hypot(stage.width, stage.height) * 0.45 * (0.55 + index * 0.22))
                        width: r * 2
                        height: width
                        radius: r
                        anchors.centerIn: parent
                        color: "transparent"
                        border.width: 1
                        border.color: root.accent
                        opacity: (1 - root.ringT) * (0.85 - index * 0.2)
                    }
                }

                Rectangle { // точка при выключении
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: root.accent
                    opacity: root.dotOp
                }
            }
        }
    }
}
