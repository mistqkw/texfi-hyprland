import QtQuick

// hairline: кольцо прогресса — тонкая дуга по тонкому треку, 12 часов по часовой.
Canvas {
    id: root

    property real progress: 0 // 0..1
    property color accentColor: "#4a7dfb"
    property color trackColor: "#26262c"
    // совместимость со старым PixelTimerRing; на вид не влияют
    property int segmentsCount: 0
    property real ringWidthRatio: 0

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (width <= 0 || height <= 0) return;
        const radius = Math.min(width, height) / 2;
        const lw = Math.max(1.5, Math.min(3, radius * 0.16));
        const r = radius - lw / 2;
        const a0 = -Math.PI / 2;
        ctx.lineWidth = lw;
        ctx.lineCap = "butt";
        ctx.strokeStyle = root.trackColor;
        ctx.beginPath(); ctx.arc(width / 2, height / 2, r, 0, Math.PI * 2); ctx.stroke();
        if (root.progress > 0) {
            ctx.strokeStyle = root.accentColor;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, r, a0, a0 + Math.min(1, root.progress) * Math.PI * 2);
            ctx.stroke();
        }
    }

    onProgressChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onAccentColorChanged: requestPaint()
    onTrackColorChanged: requestPaint()
    Component.onCompleted: requestPaint()
}
