import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "setiapam.globalprotect"
  ipcTarget: "setiapam.globalprotect"
  manageIpc: false

  property string focusSection: "header"
  property bool cursorActive: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  
  readonly property color barIconColor: vpn.uiActive ? foreground : Qt.darker(foreground, 1.55)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    cursorActive = false
    vpn.refresh()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  Service {
    id: vpn
  }
  
  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { vpn.refresh(); return "ok" }
    function toggleVpn(): string { vpn.toggle(); return "ok" }
  }

  property bool isConfigOpen: false

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    foreground: root.barIconColor
    
    iconComponent: Component {
      Item {
        implicitWidth: Style.space(11)
        implicitHeight: Style.space(11)
        
        Text {
          text: "\uf023" // lock icon
          color: root.barIconColor
          font.family: root.fontFamily
          font.pixelSize: Style.space(11)
          anchors.centerIn: parent
        }
        
        Rectangle {
          visible: !vpn.uiActive
          anchors.centerIn: parent
          width: parent.width * 1.22
          height: Math.max(2, parent.height * 0.14)
          radius: height / 2
          color: root.barIconColor
          rotation: -45
        }
      }
    }
    
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) vpn.toggle()
      else if (buttonCode === Qt.MiddleButton) vpn.refresh()
      else root.toggle()
    }
    
    SequentialAnimation on opacity {
      running: vpn.status === "connecting" || vpn.status === "disconnecting"
      loops: Animation.Infinite
      NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutQuad }
      NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        if (dy > 0 && root.focusSection === "header") root.focusSection = "config"
        else if (dy < 0 && root.focusSection === "config") root.focusSection = "header"
      }
      onActivateRequested: {
        if (root.cursorActive) {
          if (root.focusSection === "header") vpn.toggle()
          else if (root.focusSection === "config") root.isConfigOpen = !root.isConfigOpen
        }
      }
      onCloseRequested: root.close()
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      spacing: Style.space(8)

      // Package Missing Alert Banner
      Rectangle {
        visible: !vpn.pkgInstalled
        Layout.fillWidth: true
        implicitHeight: missingBox.implicitHeight + Style.space(16)
        color: Qt.rgba(root.urgent.r, root.urgent.g, root.urgent.b, 0.15)
        border.color: root.urgent
        border.width: 1
        radius: Style.space(4)

        ColumnLayout {
          id: missingBox
          anchors.fill: parent
          anchors.margins: Style.space(8)
          spacing: Style.space(6)

          Text {
            text: "globalprotect-openconnect is not installed"
            font.family: root.fontFamily
            font.pixelSize: Style.fontSize(11)
            font.weight: Font.Bold
            color: root.urgent
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          Button {
            text: "Install Package"
            Layout.fillWidth: true
            onClicked: vpn.installPackage()
          }
        }
      }

      // Connection Status Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(2)

          Text {
            text: "GlobalProtect VPN"
            font.family: root.fontFamily
            font.pixelSize: Style.fontSize(14)
            font.weight: Font.DemiBold
            color: root.foreground
          }

          Text {
            text: vpn.uiActive ? ("Connected to " + (vpn.portal || "VPN")) : "Disconnected"
            font.family: root.fontFamily
            font.pixelSize: Style.fontSize(11)
            color: vpn.uiActive ? root.foreground : root.dim
          }
        }

        Button {
          text: vpn.uiActive ? "Disconnect" : "Connect"
          enabled: vpn.pkgInstalled && !vpn.busy
          onClicked: vpn.toggle()
        }
      }

      // Settings Toggle Button
      Button {
        Layout.fillWidth: true
        text: root.isConfigOpen ? "Hide Settings" : "Configure VPN"
        onClicked: root.isConfigOpen = !root.isConfigOpen
      }

      // Inline Settings Panel
      ConfigPanel {
        visible: root.isConfigOpen
        Layout.fillWidth: true
        pluginDir: "$HOME/.config/omarchy/plugins/setiapam.globalprotect"
        onCloseRequested: root.isConfigOpen = false
        onConfigSaved: vpn.refresh()
      }
    }
  }
}
