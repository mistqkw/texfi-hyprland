pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Температура и влажность в комнате с датчика Qingping CGG1.
 * Данные пишет служба room-temp (~/.local/share/room-temp/room_temp.py).
 */
Singleton {
    id: root

    property real temperature: 0
    property real humidity: 0
    property real battery: 0
    // показания старше 10 минут считаем устаревшими и ничего не показываем
    property bool valid: false

    readonly property string text: valid ? `${temperature.toFixed(1)}°` : ""
    readonly property string humidityText: valid ? `${Math.round(humidity)}%` : ""

    function update() {
        file.reload();
        let d;
        try {
            d = JSON.parse(file.text());
        } catch (e) {
            root.valid = false;
            return;
        }
        const fresh = d.measured && (Date.now() / 1000 - d.measured) < 600;
        root.valid = !!fresh && d.temperature !== undefined;
        if (!root.valid)
            return;
        root.temperature = d.temperature;
        root.humidity = d.humidity ?? 0;
        root.battery = d.battery ?? 0;
    }

    FileView {
        id: file
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/room-temp.json"
        watchChanges: true
        onFileChanged: root.update()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.update()
    }
}
