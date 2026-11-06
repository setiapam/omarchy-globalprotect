import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string status: "disconnected"
  property string portal: ""
  property int uptimeSeconds: 0
  property bool pkgInstalled: true
  property string lastError: ""
  property string configError: ""

  readonly property bool active: status === "connected"
  readonly property bool running: status === "connected"
  // upProc deliberately stays alive for the whole VPN session, so it must not
  // keep the toggle permanently "busy".
  property bool busy: status === "connecting" || status === "disconnecting" || statusProc.running || downProc.running

  // Optimistic state while a connection/disconnection is in progress.
  property int _desired: -1
  readonly property bool uiActive: _desired === -1 ? (active || status === "connecting") : (_desired === 1)

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
    status = "connecting"
    lastError = ""
    upProc.running = true
  }

  function down() {
    if (downProc.running) return
    _desired = 0
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
          root.portal = json.portal || ""
          root.pkgInstalled = (json.pkgInstalled !== undefined) ? json.pkgInstalled : true
          root.lastError = json.lastError || ""

          var next = json.status || "disconnected"
          // While upProc is still authenticating, a transient "disconnected"
          // poll must not turn the switch off. Once connected, _desired resets.
          if (!(root._desired === 1 && next === "disconnected" && upProc.running)) {
            root.status = next
          }

          if (json.uptimeSeconds !== null && json.uptimeSeconds !== undefined) {
             root.uptimeSeconds = json.uptimeSeconds
          }

          if (root._desired !== -1 && root.active === (root._desired === 1)) {
             root._desired = -1
          }
        } catch (e) {}
      }
    }
    onExited: function() {
       if (root.status === "disconnected" && root._desired === 0) root._desired = -1
    }
  }

  Process {
    id: upProc
    command: ["bash", "-c", "~/.config/omarchy/plugins/setiapam.globalprotect/bin/omarchy-globalprotect-up"]
    onExited: function() {
      root._desired = -1
      root.refresh()
    }
  }

  Process {
    id: downProc
    command: ["bash", "-c", "~/.config/omarchy/plugins/setiapam.globalprotect/bin/omarchy-globalprotect-down"]
    onExited: function() {
      root._desired = -1
      root.refresh()
    }
  }

  Process {
    id: installProc
    command: ["omarchy-launch-terminal", "omarchy-pkg-add", "globalprotect-openconnect", "python-requests", "nodejs", "xorg-server-xvfb", "chromium"]
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
