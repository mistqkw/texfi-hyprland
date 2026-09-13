import QtQuick

// TexFi: кольцо таймера как в texfi_fokus (TimerDial._DialPainter) — не
// гладкая дуга, а 60 отдельных прямоугольных сегментов (по минуте на
// сегмент часового оборота). Так прогресс читается "зернисто", как
// единицы времени, а не как абстрактный процент.
Canvas {
    id: root

    property real progress: 0 // 0..1
    property int segmentsCount: 60
    property color accentColor: "#4a7dfb"
    property color trackColor: "#3a3f4a"
    property real ringWidthRatio: 0.14 // доля радиуса

    antialiasing: false

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (width <= 0 || height <= 0) return;

        const cx = width / 2;
        const cy = height / 2;
        const radius = Math.min(width, height) / 2;
        const ringWidth = radius * ringWidthRatio;
        const ringRadius = radius - ringWidth;
        const filled = Math.round(root.progress * root.segmentsCount);

        for (let i = 0; i < root.segmentsCount; i++) {
            // Отсчёт от 12 часов по часовой стрелке — как в TimerDial.
            const angle = -Math.PI / 2 + (i / root.segmentsCount) * 2 * Math.PI;
            const isFilled = i < filled;
            const blockSize = ringWidth * (isFilled ? 0.72 : 0.5);
            const px = cx + Math.cos(angle) * ringRadius;
            const py = cy + Math.sin(angle) * ringRadius;

            ctx.save();
            ctx.translate(px, py);
            ctx.rotate(angle + Math.PI / 2);
            ctx.fillStyle = isFilled ? root.accentColor : root.trackColor;
            ctx.fillRect(-blockSize / 2, -blockSize * 1.4 / 2, blockSize, blockSize * 1.4);
            ctx.restore();
        }
    }

    onProgressChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onAccentColorChanged: requestPaint()
    onTrackColorChanged: requestPaint()
    Component.onCompleted: requestPaint()
}
