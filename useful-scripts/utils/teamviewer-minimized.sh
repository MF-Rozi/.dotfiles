#!/usr/bin/env bash
# Start TeamViewer GUI in background and hide it from taskbar and pager

/usr/bin/teamviewer &

# Watch for TeamViewer window, hide from taskbar, and minimize
python3 -c '
import subprocess, time

js_code = """
var list = workspace.windowList();
for (var i = 0; i < list.length; i++) {
    var w = list[i];
    if (w.resourceClass === "TeamViewer" || w.caption === "TeamViewer") {
        w.skipTaskbar = true;
        w.skipPager = true;
        w.minimized = true;
    }
}
"""

with open("/tmp/tv_auto_hide.js", "w") as f:
    f.write(js_code)

for attempt in range(25):
    time.sleep(0.4)
    p = subprocess.run(["qdbus6", "org.kde.KWin", "/Scripting", "loadScript", "/tmp/tv_auto_hide.js"], capture_output=True, text=True)
    num = p.stdout.strip()
    if num:
        subprocess.run(["qdbus6", "org.kde.KWin", f"/Scripting/Script{num}", "run"], capture_output=True)
        subprocess.run(["qdbus6", "org.kde.KWin", f"/Scripting/Script{num}", "stop"], capture_output=True)
        if attempt >= 5:
            break
' &
