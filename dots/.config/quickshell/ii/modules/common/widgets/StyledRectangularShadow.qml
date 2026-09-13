import QtQuick
import qs.modules.common

// TexFi: офсетная тень без blur — сдвинутый плоский прямоугольник, а не
// Material-elevation. Раньше здесь был RectangularShadow с растушёванным
// краем; теперь это просто твёрдый блок под карточкой, как у PixelCard.
Rectangle {
    id: root
    required property var target
    x: target.x + 4
    y: target.y + 4
    width: target.width
    height: target.height
    radius: target.radius
    color: "#8C000000"
}
