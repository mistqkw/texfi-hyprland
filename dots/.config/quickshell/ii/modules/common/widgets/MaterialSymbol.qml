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
        weight: Font.Normal + (Font.DemiBold - Font.Normal) * truncatedFill
        variableAxes: {
            "FILL": truncatedFill,
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

    // --- TexFi pixel-art overlay -------------------------------------
    // Точечные силуэты для системных иконок, которые пользователь реально
    // видит каждый день (панель, быстрые переключатели, шапка сайдбара).
    // Не полная замена Material Symbols — только эти имена глифов; для
    // всего остального ниже ничего не меняется. Сетка 12x12, тот же принцип,
    // что у PixelIcon в приложениях: символьная строка, '#' — базовый цвет
    // (root.color, тот же, что был бы у обычного глифа), '+' — фирменный
    // синий фиксированным хексом, как акцентный блок у знака TexFi.
    readonly property var pixelGlyphs: ({
        edit: ["............", ".........##.", ".........##.", "........##..", ".......##...", "......##....", ".....##.....", "....##......", "...##.......", "..##........", ".+..........", ".++........."],
        restart_alt: ["............", "............", "...##.......", "..#......#..", "..#.....+++.", ".#.......++.", ".#........#.", "..#......#..", "..#......#..", "...##..##...", ".....##.....", "............"],
        settings: ["......#.....", "............", "..#..##..#..", "...##..##...", "...#....#...", "#.#..++..#.#", "..#..++..##.", "...#....#...", "...##..##...", "..#..##..#..", ".....#......", "............"],
        power_settings_new: ["............", ".....++.....", ".....++.....", "...#.##.#...", "..#..##..#..", "..#..##..#..", "..#..##..#..", "..#......#..", "..#......#..", "...#....#...", "....####....", "............"],
        coffee: ["............", "............", "...+.+......", "...+.+......", "....+.......", "..######....", "..#....###..", "..#....#.#..", "..#....###..", "..#####.....", "............", "............"],
        keyboard: ["............", "............", "............", ".##########.", ".#........#.", ".##########.", ".#..++++..#.", ".##########.", ".##########.", "............", "............", "............"],
        screenshot_region: ["............", ".###....###.", ".#.+....+.#.", ".#........#.", "............", "............", "............", "............", ".#........#.", ".#.+....+.#.", ".###....###.", "............"],
        contrast: ["............", "....####....", "..++++..##..", "..++++...#..", ".+++++....#.", ".+++++....#.", ".+++++....#.", ".+++++....#.", "..++++...#..", "..++++..##..", "....####....", "............"],
        calendar_month: ["..+......+..", "..+......+..", ".##########.", ".##########.", "............", ".#.#.#.#.#..", "............", ".#.+.#.+.#..", "............", ".#.#.+.#.#..", ".##########.", "............"],
        done_outline: ["............", "............", "............", "...........+", "..........++", ".+.......++.", ".++.....++..", "..++...++...", "...++.++....", "....+++.....", ".....+......", "............"],
        schedule: ["....####....", "..##....##..", ".#...++...#.", "#....++....#", "#....++....#", "#....+++++.#", "#..........#", "#..........#", ".#........#.", "..##....##..", "....####....", "............"],
        mic: ["............", "....####....", "...#+++#....", "...#+++#....", "...#+++#....", "...#+++#....", "....####....", ".....++.....", "...#....#...", "....####....", ".....++.....", "...######..."],
        bluetooth: ["............", "....#.......", "....###.....", "....#..##...", "....#..+....", "....###.....", "....#.......", "....###.....", "....#..+....", "....#..##...", "....##......", "............"],
        bell: ["............", ".....##.....", "....####....", "...######...", "..########..", "..########..", "..########..", ".##########.", ".##########.", ".....++.....", "............", "............"],
        volume: ["............", ".....#......", "....##......", "...###......", ".#####..+...", ".#####.+....", ".#####.+....", ".#####..+...", "...###......", "....##......", ".....#......", "............"],
        wifi: ["............", "............", "............", "..########..", ".##......##.", "#...####...#", "..########..", ".##......##.", ".#..####..#.", "...++++++...", ".....++.....", "............"],
    })
    readonly property var pixelAliases: ({
        keyboard_hide: "keyboard",
        mic_off: "mic",
        bluetooth_connected: "bluetooth", bluetooth_disabled: "bluetooth",
        notifications_active: "bell", notifications_paused: "bell",
        volume_up: "volume", volume_off: "volume",
        lan: "wifi", wifi_find: "wifi", signal_wifi_off: "wifi", signal_wifi_bad: "wifi",
        signal_wifi_4_bar: "wifi", network_wifi: "wifi", network_wifi_3_bar: "wifi",
        network_wifi_2_bar: "wifi", network_wifi_1_bar: "wifi", signal_wifi_0_bar: "wifi",
        signal_wifi_statusbar_not_connected: "wifi",
    })
    readonly property string pixelKey: pixelGlyphs[root.text] ? root.text : (pixelAliases[root.text] ?? "")
    readonly property var pixelPattern: pixelGlyphs[pixelKey]
    readonly property color pixelAccentColor: "#4a7dfb"

    Canvas {
        id: pixelCanvas
        anchors.fill: parent
        visible: root.pixelPattern !== undefined
        renderStrategy: Canvas.Cooperative
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const pat = root.pixelPattern;
            if (!pat) return;
            const n = pat.length;
            const cell = width / n;
            for (let y = 0; y < n; y++) {
                const row = pat[y];
                for (let x = 0; x < n; x++) {
                    const c = row[x];
                    if (c === '#' || c === '+') {
                        ctx.fillStyle = c === '+' ? root.pixelAccentColor : root.color;
                        ctx.fillRect(Math.floor(x * cell), Math.floor(y * cell), Math.ceil(cell) + 1, Math.ceil(cell) + 1);
                    }
                }
            }
        }
        Connections {
            target: root
            function onColorChanged() { pixelCanvas.requestPaint(); }
            function onPixelPatternChanged() { pixelCanvas.requestPaint(); }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }
}
