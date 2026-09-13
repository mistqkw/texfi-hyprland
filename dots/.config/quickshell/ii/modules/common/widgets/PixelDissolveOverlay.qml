import QtQuick

// TexFi: тот же pixel-dissolve, что в texfi_fokus
// (lib/core/theme/app_page_transitions.dart) — блоки уходят волной сверху
// вниз по детерминированному хешу координат (без Random, чтобы кадр не
// «шумел»), поверх один раз пробегают сканлайны, ярче в начале перехода.
//
// progress: 0 — полностью закрыто блоками, 1 — блоков нет.
Canvas {
    id: root
    property real progress: 1.0
    property color blockColor: "black"
    property color scanlineColor: "#4a7dfb"
    property real blockSize: 10

    visible: progress < 0.999
    antialiasing: false

    function _hash(x, y) {
        var h = (x * 374761393 + y * 668265263) & 0xFFFFFFFF;
        h = ((h ^ (h >>> 13)) * 1274126177) & 0xFFFFFFFF;
        h = (h ^ (h >>> 16)) >>> 0;
        return (h & 0xFFFF) / 0xFFFF;
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (width <= 0 || height <= 0) return;
        const cols = Math.ceil(width / blockSize);
        const rows = Math.ceil(height / blockSize);
        ctx.fillStyle = blockColor;
        for (let y = 0; y < rows; y++) {
            const wave = rows === 0 ? 0 : (y / rows) * 0.35;
            for (let x = 0; x < cols; x++) {
                const threshold = Math.min(1, _hash(x, y) * 0.65 + wave);
                if (progress < threshold) {
                    ctx.fillRect(x * blockSize, y * blockSize, blockSize, blockSize);
                }
            }
        }
        const scanAlpha = (1 - progress) * 0.9;
        if (scanAlpha > 0.01) {
            ctx.strokeStyle = Qt.rgba(scanlineColor.r, scanlineColor.g, scanlineColor.b, scanAlpha);
            ctx.lineWidth = 1;
            for (let sy = 0.5; sy < height; sy += 4) {
                ctx.beginPath();
                ctx.moveTo(0, sy);
                ctx.lineTo(width, sy);
                ctx.stroke();
            }
        }
    }

    onProgressChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onBlockColorChanged: requestPaint()
    Component.onCompleted: requestPaint()
}
