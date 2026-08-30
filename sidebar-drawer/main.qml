import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

Window {
    id: drawerWindow

    title: "Nitro Sense Drawer"
    visible: true
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.BypassWindowManagerHint
    color: "transparent"

    // When open, full 370px overlay. When closed, 0px width.
    property bool isOpen: false
    property bool openedViaHover: false
    property real lastToggleTime: 0

    width: isOpen ? 370 : 0
    height: Screen.desktopAvailableHeight || Screen.height
    x: 0
    y: 0

    // Hardware State Properties
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

    Component.onCompleted: {
        pollStatus();
    }

    // -------------------------------------------------------------------------
    // 1. Background Hardware Data Poller
    // -------------------------------------------------------------------------
    Plasma5Support.DataSource {
        id: statusSource
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
            if (data && data["exit code"] === 0 && data["stdout"]) {
                try {
                    var json = JSON.parse(data["stdout"].trim());
                    drawerWindow.cpuFanRpm = json.cpu_fan_rpm || 0;
                    drawerWindow.gpuFanRpm = json.gpu_fan_rpm || 0;
                    drawerWindow.cpuTemp = json.cpu_temp || 0;
                    drawerWindow.gpuTemp = json.gpu_temp || 0;
                    drawerWindow.cpuPercent = Math.min(100, Math.max(0, json.cpu_percent || 0));
                    drawerWindow.ramPercent = Math.min(100, Math.max(0, json.ram_percent || 0));
                    drawerWindow.fanMode = json.fan_mode || "auto";
                    drawerWindow.fanTurbo = json.fan_turbo || false;
                    drawerWindow.batteryLimitEnabled = json.battery_limit_enabled || false;
                    drawerWindow.batteryPercent = json.battery_percent || 0;
                    drawerWindow.batteryStatus = json.battery_status || "Unknown";
                } catch (e) {
                    console.error("Error parsing nitro status JSON: " + e);
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // 2. Action Execution Source
    // -------------------------------------------------------------------------
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

    // -------------------------------------------------------------------------
    // 3. Hotkey Toggle File IPC Watcher
    // -------------------------------------------------------------------------
    Plasma5Support.DataSource {
        id: toggleCheckSource
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
            if (data && data["stdout"]) {
                var out = data["stdout"].trim();
                if (out.length > 0 && out !== toggleWatcher.lastActionTime) {
                    toggleWatcher.lastActionTime = out;
                    drawerWindow.toggleDrawer();
                }
            }
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

    function launchApp(command) {
        actionSource.run(command + " &");
        closeDrawer();
    }

    function runSessionAction(action) {
        if (action === "lock") actionSource.run("loginctl lock-session");
        else if (action === "suspend") actionSource.run("systemctl suspend");
        else if (action === "restart") actionSource.run("systemctl reboot");
        else if (action === "poweroff") actionSource.run("systemctl poweroff");
        closeDrawer();
    }

    /*
    function openViaHover() {
        if (isOpen) return;
        openedViaHover = true;
        isOpen = true;
        hoverOpenTimer.stop();
        autoCloseTimer.stop();
        pollStatus();
    }
    */

    function openViaShortcut() {
        isOpen = true;
        pollStatus();
    }

    function toggleDrawer() {
        var now = Date.now();
        if (now - lastToggleTime < 350) {
            return;
        }
        lastToggleTime = now;

        if (isOpen) {
            closeDrawer();
        } else {
            openViaShortcut();
        }
    }

    function closeDrawer() {
        isOpen = false;
    }

    /*
    // Hover Dwell Timer: prevents accidental triggers when sweeping past screen edge
    Timer {
        id: hoverOpenTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (!drawerWindow.isOpen && edgeTrigger.containsMouse) {
                drawerWindow.openViaHover();
            }
        }
    }

    // Auto-close when opened via Hover and mouse exits
    Timer {
        id: autoCloseTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (drawerWindow.openedViaHover && drawerWindow.isOpen) {
                drawerWindow.closeDrawer();
            }
        }
    }
    */

    Timer {
        id: pollTimer
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pollStatus()
    }

    Timer {
        id: toggleWatcher
        interval: 100
        running: true
        repeat: true
        property string lastActionTime: ""
        onTriggered: {
            toggleCheckSource.connectSource("cat /tmp/nitro_drawer_toggle 2>/dev/null || echo ''");
        }
    }

    // Color Helpers
    function getTempColor(t) {
        if (t >= 85) return "#f87171";
        if (t >= 70) return "#fbbf24";
        return "#38bdf8";
    }

    function getLoadColor(pct) {
        if (pct >= 85) return "#f87171";
        if (pct >= 65) return "#fbbf24";
        return "#34d399";
    }

    /*
    // =========================================================================
    // Edge Hover Hotspot: Continuous Left Edge Trigger (active ONLY when closed)
    // =========================================================================
    MouseArea {
        id: edgeTrigger
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 6
        hoverEnabled: true
        enabled: !drawerWindow.isOpen
        visible: !drawerWindow.isOpen
        z: 10

        onEntered: {
            if (!drawerWindow.isOpen) {
                hoverOpenTimer.restart();
            }
        }
        onExited: {
            hoverOpenTimer.stop();
        }
    }

    // Hover Tracker across the full drawer window to manage Auto-Close on exit
    HoverHandler {
        id: drawerHoverHandler
        enabled: drawerWindow.isOpen
        onHoveredChanged: {
            if (hovered) {
                autoCloseTimer.stop();
            } else if (drawerWindow.openedViaHover && drawerWindow.isOpen) {
                autoCloseTimer.restart();
            }
        }
    }
    */

    // Keyboard Handling (Escape dismisses drawer)
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: drawerWindow.closeDrawer()
        Component.onCompleted: forceActiveFocus()
    }

    // =========================================================================
    // Glassmorphic Drawer Body
    // =========================================================================
    Rectangle {
        id: drawerBody
        width: 350
        height: parent.height - 20
        y: 10

        // Slide Animation
        x: drawerWindow.isOpen ? 8 : -width - 20
        Behavior on x {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        radius: 18
        color: Qt.rgba(0.06, 0.08, 0.13, 0.94)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.12, 0.16, 0.25, 0.96) }
            GradientStop { position: 1.0; color: Qt.rgba(0.06, 0.08, 0.12, 0.96) }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // -----------------------------------------------------------------
            // 1. Header: Nitro Sense Brand & Status
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "NITRO SENSE"
                        font.pixelSize: 16
                        font.bold: true
                        font.letterSpacing: 2
                        color: "#f8fafc"
                    }
                    Text {
                        text: "Performance & Control Hub"
                        font.pixelSize: 11
                        color: "#94a3b8"
                    }
                }

                Item { Layout.fillWidth: true }

                // Close Button
                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: closeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.07)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#e2e8f0"
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: drawerWindow.closeDrawer()
                    }
                }
            }

            // -----------------------------------------------------------------
            // 2. Primary Toggles: Turbo Fan & Battery Health Mode
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Turbo Fan Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 82
                    radius: 14
                    color: drawerWindow.fanTurbo ? Qt.rgba(0.95, 0.3, 0.1, 0.28) : Qt.rgba(0.12, 0.17, 0.28, 0.6)
                    border.color: drawerWindow.fanTurbo ? "#ff5722" : Qt.rgba(0.35, 0.55, 0.9, 0.3)
                    border.width: 1.5

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Kirigami.Icon {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                source: drawerWindow.fanTurbo ? "weather-storm" : "sensors-fan-symbolic"
                                color: drawerWindow.fanTurbo ? "#ff7043" : "#60a5fa"
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                radius: 6
                                width: turboBadgeText.implicitWidth + 8
                                height: 16
                                color: drawerWindow.fanTurbo ? "#ff5722" : Qt.rgba(0.3, 0.5, 0.9, 0.3)
                                Text {
                                    id: turboBadgeText
                                    anchors.centerIn: parent
                                    text: drawerWindow.fanTurbo ? "TURBO" : "AUTO"
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: "#ffffff"
                                }
                            }
                        }

                        Text {
                            text: "Turbo Fan"
                            font.pixelSize: 11
                            color: "#94a3b8"
                        }
                        Text {
                            text: drawerWindow.fanTurbo ? "Max Speed (6000+)" : (drawerWindow.cpuFanRpm > 0 ? (drawerWindow.cpuFanRpm + " RPM") : "Dynamic Auto")
                            font.pixelSize: 12
                            font.bold: true
                            color: "#f8fafc"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: drawerWindow.toggleTurbo()
                    }
                }

                // Battery Health Limit Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 82
                    radius: 14
                    color: drawerWindow.batteryLimitEnabled ? Qt.rgba(0.05, 0.65, 0.3, 0.28) : Qt.rgba(0.15, 0.18, 0.24, 0.6)
                    border.color: drawerWindow.batteryLimitEnabled ? "#10b981" : Qt.rgba(0.4, 0.5, 0.6, 0.3)
                    border.width: 1.5

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Kirigami.Icon {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                source: drawerWindow.batteryLimitEnabled ? "security-high" : "battery-charging"
                                color: drawerWindow.batteryLimitEnabled ? "#34d399" : "#e2e8f0"
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                radius: 6
                                width: batBadgeText.implicitWidth + 8
                                height: 16
                                color: drawerWindow.batteryLimitEnabled ? "#10b981" : Qt.rgba(1, 1, 1, 0.15)
                                Text {
                                    id: batBadgeText
                                    anchors.centerIn: parent
                                    text: drawerWindow.batteryLimitEnabled ? "80% CAP" : "100%"
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: "#ffffff"
                                }
                            }
                        }

                        Text {
                            text: "Battery Health"
                            font.pixelSize: 11
                            color: "#94a3b8"
                        }
                        Text {
                            text: drawerWindow.batteryPercent + "% (" + (drawerWindow.batteryLimitEnabled ? "80% Limit" : "Full Charge") + ")"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#f8fafc"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: drawerWindow.toggleBatteryLimit()
                    }
                }
            }

            // -----------------------------------------------------------------
            // 3. Thermal & Fan Speeds Display
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 96
                radius: 14
                color: Qt.rgba(0.10, 0.14, 0.22, 0.7)
                border.color: Qt.rgba(1, 1, 1, 0.09)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    // CPU Metric
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Text { text: "CPU System"; font.pixelSize: 11; font.bold: true; color: "#e2e8f0" }
                            Item { Layout.fillWidth: true }
                            Text { text: drawerWindow.cpuTemp + "°C"; font.pixelSize: 11; font.bold: true; color: drawerWindow.getTempColor(drawerWindow.cpuTemp) }
                        }
                        Text {
                            text: drawerWindow.cpuFanRpm > 0 ? (drawerWindow.cpuFanRpm + " RPM") : "Idle"
                            font.pixelSize: 15
                            font.bold: true
                            color: "#38bdf8"
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 5
                            radius: 3
                            color: Qt.rgba(1, 1, 1, 0.1)
                            Rectangle {
                                width: Math.min(parent.width, (parent.width * drawerWindow.cpuFanRpm) / 6000)
                                height: parent.height
                                radius: 3
                                color: "#38bdf8"
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: Qt.rgba(1, 1, 1, 0.1)
                    }

                    // GPU Metric
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Text { text: "GPU System"; font.pixelSize: 11; font.bold: true; color: "#e2e8f0" }
                            Item { Layout.fillWidth: true }
                            Text { text: drawerWindow.gpuTemp + "°C"; font.pixelSize: 11; font.bold: true; color: drawerWindow.getTempColor(drawerWindow.gpuTemp) }
                        }
                        Text {
                            text: drawerWindow.gpuFanRpm > 0 ? (drawerWindow.gpuFanRpm + " RPM") : "Idle"
                            font.pixelSize: 15
                            font.bold: true
                            color: "#818cf8"
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 5
                            radius: 3
                            color: Qt.rgba(1, 1, 1, 0.1)
                            Rectangle {
                                width: Math.min(parent.width, (parent.width * drawerWindow.gpuFanRpm) / 6000)
                                height: parent.height
                                radius: 3
                                color: "#818cf8"
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 4. Resource Usage: CPU & Memory
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 88
                radius: 14
                color: Qt.rgba(0.10, 0.14, 0.22, 0.7)
                border.color: Qt.rgba(1, 1, 1, 0.09)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    // CPU
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        RowLayout {
                            Text { text: "Processor Load"; font.pixelSize: 11; font.bold: true; color: "#cbd5e1" }
                            Item { Layout.fillWidth: true }
                            Text { text: drawerWindow.cpuPercent + "%"; font.pixelSize: 11; font.bold: true; color: drawerWindow.getLoadColor(drawerWindow.cpuPercent) }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 5
                            radius: 3
                            color: Qt.rgba(1, 1, 1, 0.1)
                            Rectangle {
                                width: Math.min(parent.width, (parent.width * drawerWindow.cpuPercent) / 100)
                                height: parent.height
                                radius: 3
                                color: drawerWindow.getLoadColor(drawerWindow.cpuPercent)
                            }
                        }
                    }

                    // RAM
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        RowLayout {
                            Text { text: "System Memory (RAM)"; font.pixelSize: 11; font.bold: true; color: "#cbd5e1" }
                            Item { Layout.fillWidth: true }
                            Text { text: drawerWindow.ramPercent + "%"; font.pixelSize: 11; font.bold: true; color: drawerWindow.getLoadColor(drawerWindow.ramPercent) }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 5
                            radius: 3
                            color: Qt.rgba(1, 1, 1, 0.1)
                            Rectangle {
                                width: Math.min(parent.width, (parent.width * drawerWindow.ramPercent) / 100)
                                height: parent.height
                                radius: 3
                                color: drawerWindow.getLoadColor(drawerWindow.ramPercent)
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 5. Quick Launch Grid
            // -----------------------------------------------------------------
            Text {
                text: "QUICK LAUNCH"
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.5
                color: "#94a3b8"
                Layout.topMargin: 2
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 10
                columnSpacing: 10

                // Terminal
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 12
                    color: termArea.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Kirigami.Icon { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 22; Layout.preferredHeight: 22; source: "utilities-terminal"; color: "#38bdf8" }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Terminal"; font.pixelSize: 10; color: "#e2e8f0" }
                    }
                    MouseArea { id: termArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: drawerWindow.launchApp("alacritty || konsole") }
                }

                // Browser
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 12
                    color: browArea.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Kirigami.Icon { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 22; Layout.preferredHeight: 22; source: "zen-browser"; color: "#f43f5e" }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Browser"; font.pixelSize: 10; color: "#e2e8f0" }
                    }
                    MouseArea { id: browArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: drawerWindow.launchApp("zen-browser || google-chrome-stable || firefox") }
                }

                // Files
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 12
                    color: fileArea.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Kirigami.Icon { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 22; Layout.preferredHeight: 22; source: "system-file-manager"; color: "#eab308" }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Files"; font.pixelSize: 10; color: "#e2e8f0" }
                    }
                    MouseArea { id: fileArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: drawerWindow.launchApp("dolphin") }
                }

                // System Monitor
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 12
                    color: monArea.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Kirigami.Icon { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 22; Layout.preferredHeight: 22; source: "utilities-system-monitor"; color: "#10b981" }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Monitor"; font.pixelSize: 10; color: "#e2e8f0" }
                    }
                    MouseArea { id: monArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: drawerWindow.launchApp("plasma-systemmonitor || ksysguard") }
                }
            }

            Item { Layout.fillHeight: true }

            // -----------------------------------------------------------------
            // 6. Bottom Session Controls
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: 12
                color: Qt.rgba(0.04, 0.06, 0.10, 0.8)
                border.color: Qt.rgba(1, 1, 1, 0.09)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    // Lock
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: lockArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
                        Kirigami.Icon { anchors.centerIn: parent; source: "system-lock-screen"; color: "#94a3b8" }
                        MouseArea { id: lockArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: drawerWindow.runSessionAction("lock") }
                    }

                    // Suspend
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: suspArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
                        Kirigami.Icon { anchors.centerIn: parent; source: "system-suspend"; color: "#94a3b8" }
                        MouseArea { id: suspArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: drawerWindow.runSessionAction("suspend") }
                    }

                    // Restart
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: rebootArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
                        Kirigami.Icon { anchors.centerIn: parent; source: "system-reboot"; color: "#94a3b8" }
                        MouseArea { id: rebootArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: drawerWindow.runSessionAction("restart") }
                    }

                    // Shutdown
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        color: powerArea.containsMouse ? Qt.rgba(0.9, 0.2, 0.2, 0.35) : "transparent"
                        Kirigami.Icon { anchors.centerIn: parent; source: "system-shutdown"; color: "#f87171" }
                        MouseArea { id: powerArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: drawerWindow.runSessionAction("poweroff") }
                    }
                }
            }
        }
    }
}
