#!/usr/bin/env bash
# Toggle KDE Plasma 6 Left Sidebar Visibility
# Toggles left sidebar between 'autohide' and 'none' (pinned open).

# Check for qdbus binary
if command -v qdbus6 >/dev/null 2>&1; then
    QDBUS_CMD="qdbus6"
elif command -v qdbus >/dev/null 2>&1; then
    QDBUS_CMD="qdbus"
else
    echo "Error: qdbus/qdbus6 not found." >&2
    exit 1
fi

TOGGLE_JS='(function () {
    var pList = panels();
    for (var i = 0; i < pList.length; ++i) {
        var p = pList[i];
        if (p.location === "left") {
            p.hiding = (p.hiding === "autohide") ? "none" : "autohide";
        }
    }
})();'

"$QDBUS_CMD" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$TOGGLE_JS"
