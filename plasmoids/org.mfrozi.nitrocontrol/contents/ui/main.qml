import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    // System and Hardware Properties
    property int cpuFanRpm: 0
    property int gpuFanRpm: 0
    property int cpuTemp: 0
    property int gpuTemp: 0
    property int cpuPercent: 0
    property int ramPercent: 0
    property string fanMode: "auto"
    property bool fanTurbo: false
    property bool batteryLimitEnabled: false
    property int batteryPercent: 0
    property string batteryStatus: "Unknown"

    // Background Data Source (JSON Status Exporter)
    Plasma5Support.DataSource {
        id: statusSource
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
            if (data && data["exit code"] === 0 && data["stdout"]) {
                try {
                    var json = JSON.parse(data["stdout"].trim());
                    root.cpuFanRpm = json.cpu_fan_rpm || 0;
                    root.gpuFanRpm = json.gpu_fan_rpm || 0;
                    root.cpuTemp = json.cpu_temp || 0;
                    root.gpuTemp = json.gpu_temp || 0;
                    root.cpuPercent = Math.min(100, Math.max(0, json.cpu_percent || 0));
                    root.ramPercent = Math.min(100, Math.max(0, json.ram_percent || 0));
                    root.fanMode = json.fan_mode || "auto";
                    root.fanTurbo = json.fan_turbo || false;
                    root.batteryLimitEnabled = json.battery_limit_enabled || false;
                    root.batteryPercent = json.battery_percent || 0;
                    root.batteryStatus = json.battery_status || "Unknown";
                } catch (e) {
                    console.error("Error parsing nitro status JSON: " + e);
                }
            }
        }
    }

    // Action Execution Source
    Plasma5Support.DataSource {
        id: actionSource
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
            pollTimer.restart();
            pollStatus();
        }

        function run(cmd) {
            connectSource(cmd);
        }
    }

    function pollStatus() {
        var statusScript = "$HOME/dotfiles/scripts/get-nitro-status.sh";
        statusSource.connectSource(statusScript);
    }

    function toggleTurbo() {
        actionSource.run("$HOME/dotfiles/useful-scripts/toggle-fan-turbo.sh toggle");
    }

    function toggleBatteryLimit() {
        actionSource.run("$HOME/dotfiles/useful-scripts/toggle-battery-limit.sh");
    }

    Timer {
        id: pollTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pollStatus()
    }

    // Helpers for load-based color coding
    function getLoadColor(pct) {
        if (pct >= 85) return "#ef4444"; // Red
        if (pct >= 65) return "#f59e0b"; // Amber
        return "#10b981"; // Emerald
    }

    // =========================================================================
    // Compact Representation (Vertical Sidebar Integrated Hub)
    // =========================================================================
    compactRepresentation: Item {
        id: compactRoot
        Layout.fillWidth: true
        Layout.minimumHeight: mainColumn.implicitHeight + 8
        Layout.preferredHeight: mainColumn.implicitHeight + 8

        ColumnLayout {
            id: mainColumn
            anchors.centerIn: parent
            width: Math.min(parent.width - 6, 48)
            spacing: 6

            // -----------------------------------------------------------------
            // 1. Fan Speed & Turbo Toggle Card
            // -----------------------------------------------------------------
            Rectangle {
                id: fanCard
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: parent.width
                Layout.preferredHeight: 48
                radius: 8
                color: root.fanTurbo ? Qt.rgba(0.95, 0.25, 0.05, 0.3) : Qt.rgba(0.12, 0.16, 0.25, 0.6)
                border.color: root.fanTurbo ? "#ff5722" : Qt.rgba(0.3, 0.5, 0.8, 0.35)
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    // Custom Fan Blades Icon
                    Canvas {
                        id: fanCanvas
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var cx = width / 2;
                            var cy = height / 2;
                            var r = width / 2 - 2;

                            ctx.fillStyle = root.fanTurbo ? "#ff7043" : "#60a5fa";
                            for (var i = 0; i < 3; ++i) {
                                var angle = (i * 2 * Math.PI) / 3;
                                ctx.beginPath();
                                ctx.arc(cx + Math.cos(angle) * (r * 0.45), cy + Math.sin(angle) * (r * 0.45), r * 0.45, 0, 2 * Math.PI);
                                ctx.fill();
                            }
                            ctx.fillStyle = "#ffffff";
                            ctx.beginPath();
                            ctx.arc(cx, cy, 3, 0, 2 * Math.PI);
                            ctx.fill();
                        }

                        RotationAnimator on rotation {
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: root.fanTurbo ? 300 : (root.cpuFanRpm > 0 ? 1200 : 3500)
                            running: true
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.fanTurbo ? "TURBO" : (root.cpuFanRpm > 0 ? (Math.round(root.cpuFanRpm / 100) / 10).toFixed(1) + "k" : "AUTO")
                        font.pixelSize: 8
                        font.bold: true
                        font.letterSpacing: 0.5
                        color: root.fanTurbo ? "#ffab91" : "#93c5fd"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.toggleTurbo()
                    QQC2.ToolTip.visible: containsMouse
                    QQC2.ToolTip.delay: 250
                    QQC2.ToolTip.text: "🌪️ Fan System: " + (root.fanTurbo ? "TURBO Mode (Max RPM)" : "AUTO Mode") + "\nCPU: " + root.cpuFanRpm + " RPM (" + root.cpuTemp + "°C)\nGPU: " + root.gpuFanRpm + " RPM (" + root.gpuTemp + "°C)\n\n👉 Click to toggle Turbo"
                }
            }

            // -----------------------------------------------------------------
            // 2. Battery Charge Limit Toggle Card
            // -----------------------------------------------------------------
            Rectangle {
                id: batCard
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: parent.width
                Layout.preferredHeight: 40
                radius: 8
                color: root.batteryLimitEnabled ? Qt.rgba(0.05, 0.65, 0.3, 0.3) : Qt.rgba(0.15, 0.18, 0.22, 0.5)
                border.color: root.batteryLimitEnabled ? "#10b981" : Qt.rgba(0.4, 0.5, 0.6, 0.3)
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: root.batteryLimitEnabled ? "security-high" : (root.batteryStatus === "Charging" ? "battery-charging" : "battery")
                        color: root.batteryLimitEnabled ? "#34d399" : (root.batteryPercent <= 20 ? "#ef4444" : "#e2e8f0")
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.batteryLimitEnabled ? "80% LIM" : root.batteryPercent + "%"
                        font.pixelSize: 8
                        font.bold: true
                        font.letterSpacing: 0.5
                        color: root.batteryLimitEnabled ? "#6ee7b7" : "#cbd5e1"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.toggleBatteryLimit()
                    QQC2.ToolTip.visible: containsMouse
                    QQC2.ToolTip.delay: 250
                    QQC2.ToolTip.text: "🔋 Battery Health Limit: " + (root.batteryLimitEnabled ? "80% Limit (Active)" : "100% Full Charge") + "\nLevel: " + root.batteryPercent + "% (" + root.batteryStatus + ")\n\n👉 Click to toggle Limit"
                }
            }

            // -----------------------------------------------------------------
            // 3. Compact CPU & RAM Vertical Meters
            // -----------------------------------------------------------------
            Rectangle {
                id: sysMeterCard
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: parent.width
                Layout.preferredHeight: 64
                radius: 8
                color: Qt.rgba(0.1, 0.13, 0.2, 0.55)
                border.color: Qt.rgba(0.3, 0.4, 0.6, 0.25)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    // CPU Meter Row
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "CPU"
                                font.pixelSize: 7
                                font.bold: true
                                color: "#94a3b8"
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.cpuPercent + "%"
                                font.pixelSize: 7
                                font.bold: true
                                color: root.getLoadColor(root.cpuPercent)
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            radius: 2
                            color: Qt.rgba(0.3, 0.3, 0.4, 0.4)

                            Rectangle {
                                width: Math.max(2, (parent.width * root.cpuPercent) / 100)
                                height: parent.height
                                radius: 2
                                color: root.getLoadColor(root.cpuPercent)
                            }
                        }
                    }

                    // RAM Meter Row
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "RAM"
                                font.pixelSize: 7
                                font.bold: true
                                color: "#94a3b8"
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.ramPercent + "%"
                                font.pixelSize: 7
                                font.bold: true
                                color: root.getLoadColor(root.ramPercent)
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            radius: 2
                            color: Qt.rgba(0.3, 0.3, 0.4, 0.4)

                            Rectangle {
                                width: Math.max(2, (parent.width * root.ramPercent) / 100)
                                height: parent.height
                                radius: 2
                                color: root.getLoadColor(root.ramPercent)
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.expanded = !root.expanded
                    QQC2.ToolTip.visible: containsMouse
                    QQC2.ToolTip.delay: 250
                    QQC2.ToolTip.text: "📊 System Resources:\nCPU Usage: " + root.cpuPercent + "% (" + root.cpuTemp + "°C)\nRAM Usage: " + root.ramPercent + "%\nGPU Temp: " + root.gpuTemp + "°C\n\n👉 Click for details"
                }
            }
        }
    }

    // =========================================================================
    // Full Representation (Expanded Dashboard Card)
    // =========================================================================
    fullRepresentation: Item {
        implicitWidth: 300
        implicitHeight: popupLayout.implicitHeight + 24

        ColumnLayout {
            id: popupLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Kirigami.Heading {
                level: 3
                text: "Nitro Hardware Dashboard"
                Layout.alignment: Qt.AlignHCenter
            }

            // Fan System Details
            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    spacing: 6

                    Kirigami.Heading {
                        level: 4
                        text: "🌪️ Fan System"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "CPU Fan Speed:"; color: Kirigami.Theme.textColor; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: root.cpuFanRpm + " RPM (" + root.cpuTemp + "°C)"; color: Kirigami.Theme.textColor }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "GPU Fan Speed:"; color: Kirigami.Theme.textColor; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: root.gpuFanRpm + " RPM (" + root.gpuTemp + "°C)"; color: Kirigami.Theme.textColor }
                    }

                    QQC2.Button {
                        Layout.fillWidth: true
                        text: root.fanTurbo ? "🔥 Switch Fans to AUTO" : "⚡ Switch Fans to TURBO (Max)"
                        icon.name: root.fanTurbo ? "weather-few-clouds" : "weather-storm"
                        onClicked: root.toggleTurbo()
                    }
                }
            }

            // Battery Health Details
            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    spacing: 6

                    Kirigami.Heading {
                        level: 4
                        text: "🔋 Battery Health"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Battery Level:"; color: Kirigami.Theme.textColor; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: root.batteryPercent + "% (" + root.batteryStatus + ")"; color: Kirigami.Theme.textColor }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Health Limit (80%):"; color: Kirigami.Theme.textColor; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: root.batteryLimitEnabled ? "Enabled (80% Cap)" : "Disabled (100% Full)"; color: root.batteryLimitEnabled ? "#10b981" : Kirigami.Theme.textColor }
                    }

                    QQC2.Button {
                        Layout.fillWidth: true
                        text: root.batteryLimitEnabled ? "⚡ Set Charge Limit to 100%" : "🛡️ Set Health Limit to 80%"
                        icon.name: root.batteryLimitEnabled ? "battery-charging" : "security-high"
                        onClicked: root.toggleBatteryLimit()
                    }
                }
            }

            // System Load Details
            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    spacing: 6

                    Kirigami.Heading {
                        level: 4
                        text: "📊 System Load"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "CPU Usage:"; color: Kirigami.Theme.textColor; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: root.cpuPercent + "% (" + root.cpuTemp + "°C)"; color: root.getLoadColor(root.cpuPercent) }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "RAM Usage:"; color: Kirigami.Theme.textColor; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: root.ramPercent + "%"; color: root.getLoadColor(root.ramPercent) }
                    }
                }
            }
        }
    }
}
