import QtQuick
import QtQuick.Shapes
import qs

// Signal-aware wifi glyph: three arcs over a base dot, the lit-arc count
// standing for signal strength (>0.66 -> 3, >0.33 -> 2, >0 -> 1). Radio off
// dims every stroke and adds a diagonal slash. Shared by the wifi device rows
// and the settings menu. Paths live in 24x24 space, centred on both axes.
Item {
    id: glyphRoot

    property real level: 0
    property bool on: true

    implicitWidth: Globals.typography.icon.lg
    implicitHeight: Globals.typography.icon.lg

    readonly property int litCount: !on ? 0 : (level > 0.66 ? 3 : (level > 0.33 ? 2 : (level > 0 ? 1 : 0)))
    readonly property color litColor: Globals.colors.text
    readonly property color unlitColor: Globals.alpha(Globals.colors.text, on ? 0.4 : 0.18)

    readonly property real u: Math.min(width, height) / 24
    readonly property real stroke: (2 / glyphRoot.u) * Globals.shellScale

    readonly property real glyphX: arcs.boundingRect.width > 0
        ? glyphRoot.width / 2 - (arcs.boundingRect.x + arcs.boundingRect.width / 2) * glyphRoot.u
        : (glyphRoot.width - 24 * glyphRoot.u) / 2
    readonly property real glyphY: arcs.boundingRect.height > 0
        ? glyphRoot.height / 2 - (arcs.boundingRect.y + arcs.boundingRect.height / 2) * glyphRoot.u
        : (glyphRoot.height - 24 * glyphRoot.u) / 2

    Shape {
        id: arcs

        width: 24
        height: 24
        scale: glyphRoot.u
        transformOrigin: Item.TopLeft
        x: glyphRoot.glyphX
        y: glyphRoot.glyphY
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: glyphRoot.litCount >= 1 ? glyphRoot.litColor : glyphRoot.unlitColor
            fillColor: "transparent"
            strokeWidth: glyphRoot.stroke
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M9.17 13.17 A4 4 0 0 1 14.83 13.17" }
        }
        ShapePath {
            strokeColor: glyphRoot.litCount >= 2 ? glyphRoot.litColor : glyphRoot.unlitColor
            fillColor: "transparent"
            strokeWidth: glyphRoot.stroke
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M6.34 10.34 A8 8 0 0 1 17.66 10.34" }
        }
        ShapePath {
            strokeColor: glyphRoot.litCount >= 3 ? glyphRoot.litColor : glyphRoot.unlitColor
            fillColor: "transparent"
            strokeWidth: glyphRoot.stroke
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M3.5 7.5 A12 12 0 0 1 20.5 7.5" }
        }
        ShapePath {
            strokeColor: "transparent"
            fillColor: glyphRoot.litCount >= 1 ? glyphRoot.litColor : glyphRoot.unlitColor
            PathSvg { path: "M12 14.1 A1.5 1.5 0 0 1 12 17.1 A1.5 1.5 0 0 1 12 14.1z" }
        }
    }

    Shape {
        id: slash

        width: 24
        height: 24
        scale: glyphRoot.u
        transformOrigin: Item.TopLeft
        x: glyphRoot.glyphX
        y: glyphRoot.glyphY
        visible: !glyphRoot.on
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Globals.colors.faint
            fillColor: "transparent"
            strokeWidth: (1.7 / glyphRoot.u) * Globals.shellScale
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M4 3 L20 19" }
        }
    }
}
