import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs
import ".."

BaseContainer {
    id: root

    // A power tile is a fixed square, so its metrics live here rather than in
    // Globals: no other component wants a number this shape.
    readonly property int tileSize: 50 * Globals.shellScale

    // Only the hovered tile lights. Rebuilt from the row's own state because a
    // tile row carries its own lit treatment — the BaseIndicator bar exists for
    // vertical lists where nothing else shows the cursor.
    property string hoveredKey: ""

    readonly property var _actions: [
        { key: "logout",   icon: "log-out",  confirm: false, run: function() { Modules.closeAll(); Compositor.quit(); } },
        { key: "suspend",  icon: "moon",     confirm: false, run: function() { Modules.closeAll(); Power.suspend(); } },
        { key: "reboot",   icon: "rotate-cw", confirm: true,  run: function() { Modules.closeAll(); Power.reboot(); } },
        { key: "shutdown", icon: "power",    confirm: true,  run: function() { Modules.closeAll(); Power.shutdown(); } }
    ]

    Row {
        id: tiles
        Layout.alignment: Qt.AlignHCenter
        spacing: Globals.geometry.spacing.md

        Repeater {
            model: root._actions

            delegate: Item {
                id: tile
                required property var modelData

                width: root.tileSize
                height: root.tileSize

                readonly property bool lit: root.hoveredKey === modelData.key
                // The radius of a tile nested inside the capsule: the capsule's
                // radius less the gap it sits behind.
                readonly property real corner: Globals.innerRadius(Globals.geometry.borderWidth.thick)

                Rectangle {
                    anchors.fill: parent
                    radius: tile.corner
                    color: tile.lit ? Globals.colors.raised : Globals.colors.well
                    border.width: Globals.geometry.borderWidth.hair
                    border.color: tile.lit ? Globals.colors.border : Globals.colors.hair

                    Behavior on color { BaseMotion { duration: Globals.motion.hover } }
                }

                // The rising fill needs a clip that carries the tile's own
                // corners. A plain Rectangle clamps its radius to height/2
                // while the fill is still flat, so its corners poke outside
                // the tile outline on the first beat of every hold.
                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: Globals.geometry.borderWidth.hair
                    radius: tile.corner - Globals.geometry.borderWidth.hair
                    color: "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: parent.height * hold.hold
                        visible: hold.holding
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Globals.colors.accentTop }
                            GradientStop { position: 1.0; color: Globals.colors.accentBottom }
                        }
                    }
                }

                BaseIcon {
                    anchors.centerIn: parent
                    icon: modelData.icon
                    size: Globals.typography.icon.lg
                    color: hold.holding ? Globals.colors.accentTop
                                        : (tile.lit ? Globals.colors.text : Globals.colors.faint)

                    Behavior on color { BaseMotion { duration: Globals.motion.hover } }
                }

                BaseHold {
                    id: hold
                    onConfirmed: modelData.run()
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onEntered: root.hoveredKey = modelData.key
                    // Leaving mid-hold drains instead of confirming, so a
                    // pointer that slides off never fires the action.
                    onExited: {
                        if (root.hoveredKey === modelData.key)
                            root.hoveredKey = "";
                        if (modelData.confirm)
                            hold.cancel();
                    }

                    onPressed: if (modelData.confirm) hold.press()
                    onReleased: if (modelData.confirm) hold.release()
                    onClicked: if (!modelData.confirm) modelData.run()
                }
            }
        }
    }

    onModuleStateChanged: {
        if (moduleState === "Closed" || moduleState === "Closing")
            root.hoveredKey = "";
    }
}