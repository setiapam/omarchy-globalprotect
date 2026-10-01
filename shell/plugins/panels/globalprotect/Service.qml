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

  readonly property bool active: status === "connected" || status === "connecting"
  readonly property bool running: status === "connected"
  property bool busy: statusProc.running || upProc.running || downProc.running

  // Optimistic UI state matching openfortivpn
  property int _desired: -1
  readonly property bool uiActive: _desired === -1 ? active : (_desired === 1)

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function toggle() {
    if (uiActive) down()
    else up()
  }

  function up() {
    if (upProc.running) return
    _desired = 1
    upProc.running = true
  }

  function down() {
    if (downProc.running) return
    _desired = 0
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
          if (_desired !== -1 && root.active === (_desired === 1)) {
             _desired = -1
          }
        } catch (e) {}
      }
    }
    onExited: function() {
      if (root.status === "disconnected" && _desired === 0) _desired = -1
    }
  }

  Process {
    id: upProc
    command: ["bash", "-c", "~/.config/omarchy/plugins/setiapam.globalprotect/bin/omarchy-globalprotect-up"]
    onExited: function() {
      _desired = -1
      root.refresh()
    }
  }

  Process {
    id: downProc
    command: ["bash", "-c", "~/.config/omarchy/plugins/setiapam.globalprotect/bin/omarchy-globalprotect-down"]
    onExited: function() {
      _desired = -1
      root.refresh()
    }
  }

  Process {
    id: installProc
    command: ["omarchy-launch-terminal", "omarchy-pkg-add", "globalprotect-openconnect"]
    onExited: function() { root.refresh() }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
