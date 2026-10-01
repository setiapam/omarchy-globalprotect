import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string status: "disconnected"
  property string portal: ""
  property int uptimeSeconds: 0
  property bool pkgInstalled: true
  property string configError: ""

  readonly property bool active: status === "connected"
  readonly property bool running: status === "connected"
  property bool busy: statusProc.running || upProc.running || downProc.running

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function toggle() {
    if (active) down()
    else up()
  }

  function up() {
    if (upProc.running) return
    status = "connecting"
    upProc.running = true
  }

  function down() {
    if (downProc.running) return
    status = "disconnecting"
    downProc.running = true
  }

  function installPackage() {
    if (installProc.running) return
    installProc.running = true
  }

  Process {
    id: statusProc
    command: ["bash", "-c", "~/.config/omarchy/plugins/setiapam.globalprotect/bin/omarchy-globalprotect-status"]
    stdout: SplitParser {
      onRead: function(data) {
        try {
          var json = JSON.parse(data)
          root.status = json.status || "disconnected"
          root.portal = json.portal || ""
          root.pkgInstalled = (json.pkgInstalled !== undefined) ? json.pkgInstalled : true
          if (json.uptimeSeconds !== null && json.uptimeSeconds !== undefined) {
             root.uptimeSeconds = json.uptimeSeconds
          }
        } catch (e) {}
      }
    }
  }

  Process {
    id: upProc
    command: ["bash", "-c", "~/.config/omarchy/plugins/setiapam.globalprotect/bin/omarchy-globalprotect-up"]
    onExited: function() { root.refresh() }
  }

  Process {
    id: downProc
    command: ["bash", "-c", "~/.config/omarchy/plugins/setiapam.globalprotect/bin/omarchy-globalprotect-down"]
    onExited: function() { root.refresh() }
  }

  Process {
    id: installProc
    command: ["omarchy-launch-terminal", "omarchy-pkg-add", "globalprotect-openconnect"]
    onExited: function() { root.refresh() }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
