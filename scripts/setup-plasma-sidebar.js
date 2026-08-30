// Setup KDE Plasma 6 Vertical Auto-Hiding Sidebar Panel
// Executed via: qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "<content>"

(function () {
    // 1. Clean up any existing left sidebar panels on primary display
    var existingPanels = panels();
    for (var i = existingPanels.length - 1; i >= 0; --i) {
        var p = existingPanels[i];
        if (p.location === "left") {
            p.remove();
        }
    }

    // 2. Create new left vertical panel
    var panel = new Panel;
    panel.location = "left";
    panel.alignment = "center";
    panel.hiding = "autohide";
    panel.lengthMode = "fill";
    panel.height = 56; // 56px thickness

    // 3. Add Top Application Launcher
    panel.addWidget("org.kde.plasma.kickoff");

    // 4. Add Expanding Spacer to anchor bottom utilities
    panel.addWidget("org.kde.plasma.panelspacer");

    // 5. Add Unified Nitro Hardware & System Resource Dashboard
    panel.addWidget("org.mfrozi.nitrocontrol");

    // 6. Add Session / Power Controls
    panel.addWidget("org.kde.plasma.lock_logout");
})();
