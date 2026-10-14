pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: clockColumn
    spacing: 0

    property bool isVertical: Config.options.background.widgets.clock.digital.vertical
    property color colText: Appearance.colors.colOnSecondaryContainer
    property var textHorizontalAlignment: Text.AlignHCenter

    // hairline: крупное время Unbounded, синее двоеточие, тонкая линия, дата моно капсом
    readonly property var timeParts: DateTime.time.split(/[: ]/)
    readonly property bool leftAligned: clockColumn.textHorizontalAlignment === Text.AlignLeft
    readonly property bool rightAligned: clockColumn.textHorizontalAlignment === Text.AlignRight
    readonly property real timeSize: Config.options.background.widgets.clock.digital.font.size
    // дата по-русски независимо от системной локали; пересчитывается вместе со временем
    readonly property string dateText: {
        DateTime.time;
        return Qt.locale("ru_RU").toString(new Date(), "dddd  ·  d MMMM").toUpperCase();
    }

    Row {
        id: timeRow
        Layout.alignment: clockColumn.leftAligned ? Qt.AlignLeft : clockColumn.rightAligned ? Qt.AlignRight : Qt.AlignHCenter
        spacing: clockColumn.timeSize * 0.04

        Repeater {
            model: clockColumn.isVertical ? [clockColumn.timeParts[0]] : clockColumn.timeParts.slice(0, 2)
            delegate: Row {
                required property string modelData
                required property int index
                spacing: clockColumn.timeSize * 0.04
                Text {
                    visible: index > 0
                    text: ":"
                    color: Appearance.colors.colPrimary
                    renderType: Text.NativeRendering
                    font { family: "Unbounded"; weight: Font.DemiBold; pixelSize: clockColumn.timeSize }
                    anchors.verticalCenter: parent.verticalCenter
                    // двоеточие чуть приподнято, оно визуально «тонет» у базовой линии
                    topPadding: -clockColumn.timeSize * 0.06
                }
                Text {
                    text: modelData.padStart(2, "0")
                    color: Appearance.colors.colTextPrimary
                    renderType: Text.NativeRendering
                    font { family: "Unbounded"; weight: Font.DemiBold; pixelSize: clockColumn.timeSize; features: { "tnum": 1 } }
                }
            }
        }
    }

    // линия: hairline на всю ширину времени, первые 56px — акцент
    Item {
        visible: Config.options.background.widgets.clock.digital.showDate
        Layout.alignment: timeRow.Layout.alignment
        Layout.preferredWidth: timeRow.implicitWidth
        Layout.topMargin: 6
        Layout.bottomMargin: 8
        implicitHeight: 1
        Rectangle { anchors.fill: parent; color: Appearance.colors.colTextTertiary; opacity: 0.45 }
        Rectangle {
            anchors { left: clockColumn.rightAligned ? undefined : parent.left; right: clockColumn.rightAligned ? parent.right : undefined; top: parent.top; bottom: parent.bottom }
            width: 56
            color: Appearance.colors.colPrimary
        }
    }

    // Date
    Text {
        visible: Config.options.background.widgets.clock.digital.showDate
        Layout.alignment: timeRow.Layout.alignment
        text: clockColumn.dateText
        color: Appearance.colors.colTextSecondary ?? "#a3a3ad"
        renderType: Text.NativeRendering
        font {
            family: Appearance.font.family.monospace
            pixelSize: Math.max(11, clockColumn.timeSize * 0.12)
            letterSpacing: 2.2
        }
    }

    // температура в комнате с датчика CGG1: моно-подпись, значение акцентом
    Row {
        visible: RoomTemp.valid
        Layout.alignment: timeRow.Layout.alignment
        Layout.topMargin: 6
        spacing: 10
        Text {
            text: "КОМНАТА"
            color: Appearance.colors.colTextSecondary ?? "#a3a3ad"
            renderType: Text.NativeRendering
            font {
                family: Appearance.font.family.monospace
                pixelSize: Math.max(11, clockColumn.timeSize * 0.12)
                letterSpacing: 2.2
            }
            anchors.baseline: tempText.baseline
        }
        Text {
            id: tempText
            text: RoomTemp.text
            color: Appearance.colors.colPrimary
            renderType: Text.NativeRendering
            font {
                family: "Unbounded"
                weight: Font.DemiBold
                pixelSize: Math.max(16, clockColumn.timeSize * 0.2)
                features: { "tnum": 1 }
            }
        }
        Text {
            text: RoomTemp.humidityText
            color: Appearance.colors.colTextSecondary ?? "#a3a3ad"
            renderType: Text.NativeRendering
            font {
                family: Appearance.font.family.monospace
                pixelSize: Math.max(11, clockColumn.timeSize * 0.12)
                letterSpacing: 2.2
            }
            anchors.baseline: tempText.baseline
        }
    }

    // Quote
    ClockText {
        visible: Config.options.background.widgets.clock.quote.enable && Config.options.background.widgets.clock.quote.text.length > 0
        font.pixelSize: Appearance.font.pixelSize.normal
        text: Config.options.background.widgets.clock.quote.text
        animateChange: false
        color: clockColumn.colText
        horizontalAlignment: clockColumn.textHorizontalAlignment
    }
}
