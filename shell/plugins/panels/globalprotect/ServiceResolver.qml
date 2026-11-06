import QtQuick

// Resolve the plugin's shared service object, which omarchy-shell creates once
// and hands to every bar instance through bar.shell.serviceFor().
//
// A lookup made directly inside a property binding is not enough: the bar
// facade exposes serviceFor() as a plain callback, so the binding never learns
// when the shell publishes the service. If a widget is created while the
// service is still loading (plugin hot-reload, startup), it would keep a null
// service forever while another monitor resolves it a moment later. That is
// what let one bar instance keep its own stale optimistic state.
//
// Retrying here converges every bar instance on the same service object.
Item {
  id: root

  visible: false
  property QtObject host: null
  property string moduleName: ""
  // A typed QObject reference clears (and notifies) if the service is destroyed.
  property QtObject service: null
  property bool disposing: false

  function scheduleSync() {
    if (disposing) return
    retryTimer.stop()
    retryTimer.interval = 100
    Qt.callLater(syncService)
  }

  function syncService() {
    if (disposing) return
    var currentHost = host
    var currentModule = moduleName
    var next = currentHost && typeof currentHost.serviceFor === "function"
      ? currentHost.serviceFor(currentModule) : null
    // The lookup can itself change the host (plugin reload); never adopt its
    // result after the facade or module this resolver was bound to moved on.
    if (disposing || host !== currentHost || moduleName !== currentModule) return
    service = next
    if (service || !currentHost || typeof currentHost.serviceFor !== "function") {
      retryTimer.stop()
    } else {
      // The facade has no service-cache notification, so poll with backoff
      // until the service appears. This stays cheap at the 2s cap.
      retryTimer.start()
    }
  }

  onHostChanged: {
    service = null
    scheduleSync()
  }
  onModuleNameChanged: {
    service = null
    scheduleSync()
  }
  onServiceChanged: if (!service) scheduleSync()
  Component.onCompleted: scheduleSync()
  Component.onDestruction: {
    disposing = true
    retryTimer.stop()
  }

  Timer {
    id: retryTimer
    interval: 100
    repeat: false
    onTriggered: {
      interval = Math.min(interval * 2, 2000)
      root.syncService()
    }
  }
}
