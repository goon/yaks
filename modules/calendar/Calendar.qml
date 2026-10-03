import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// Month view. Monday-first week, locale weekday/month names. The visible month
// is local state and resets to the real month on every open. Mouse-only:
// chevrons step months, the label jumps back, a ring marks today. No day
// selection — nothing consumes one.
BaseContainer {
    id: root

    readonly property real gridWidth: 320 * Globals.shellScale
    readonly property real cellWidth: gridWidth / 7
    readonly property real cellHeight: 26 * Globals.shellScale

    readonly property var locale: Qt.locale()

    readonly property int offset: (new Date(viewDate.getFullYear(), viewDate.getMonth(), 1).getDay() + 6) % 7
    readonly property int monthLen: new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 0).getDate()
    readonly property int previousMonthLen: new Date(viewDate.getFullYear(), viewDate.getMonth(), 0).getDate()
    readonly property int rows: Math.ceil((offset + monthLen) / 7)
    readonly property bool viewingCurrentMonth: viewDate.getFullYear() === today.getFullYear()
        && viewDate.getMonth() === today.getMonth()

    // The grid's height follows `liveRows`, not the cell count, so a row-count
    // change is animated here instead of landing on implicitHeight in one frame
    // and re-targeting the capsule's own height animation mid-flight.
    property int liveRows: rows

    Behavior on liveRows {
        NumberAnimation {
            duration: Globals.motion.morph
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Globals.motion.easeEmphasis
        }
    }

    property date viewDate: new Date(today)

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    readonly property date today: systemClock.date

    implicitWidth: gridWidth
    focus: true

    function opening() {
        viewDate = new Date(today);
    }

    function shiftMonth(delta) {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + delta, 1);
    }

    // Mouse-only module: right-click anywhere dismisses. `clickable` stays false
    // on purpose — it is what gives BaseContainer its whole-root press-scale,
    // and a popout that shrinks under every press reads as a bounce.
    onRightClicked: Modules.closeAll()

    ColumnLayout {
        id: mainLayout

        width: root.availableWidth
        spacing: Globals.geometry.spacing.md

        // Back on the left, forward on the right, month centred between them.
        RowLayout {
            Layout.fillWidth: true
            spacing: Globals.geometry.spacing.md

            BaseButton {
                icon: "chevron-left"
                hoverColor: Globals.colors.hover
                onClicked: root.shiftMonth(-1)
            }

            BaseText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.locale.standaloneMonthName(root.viewDate.getMonth(), Locale.LongFormat)
                    + " " + root.viewDate.getFullYear()
                font.capitalization: Font.AllUppercase
                pixelSize: Globals.typography.size.lg
                weight: Globals.typography.weight.demi
                font.letterSpacing: 3
                elide: Text.ElideRight
                wrapMode: Text.NoWrap

                TapHandler {
                    cursorShape: Qt.PointingHandCursor
                    onTapped: root.viewDate = new Date(root.today)
                }
            }

            BaseButton {
                icon: "chevron-right"
                hoverColor: Globals.colors.hover
                onClicked: root.shiftMonth(1)
            }
        }

        BaseSeparator {}

        // Weekday labels are pinned to cellWidth, not to a share of the row, so
        // they line up with the grid's columns instead of drifting.
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: 7

                delegate: BaseText {
                    required property int modelData

                    Layout.preferredWidth: root.cellWidth

                    // Monday-first, so index 0 is Monday and the weekend is the
                    // last two columns.
                    readonly property bool weekend: modelData >= 5

                    text: root.locale.dayName((modelData + 1) % 7, Locale.NarrowFormat)
                    horizontalAlignment: Text.AlignHCenter
                    pixelSize: Globals.typography.size.sm
                    weight: Globals.typography.weight.demi
                    font.letterSpacing: 0.5
                    // A header row, so it sits below the days it labels: both
                    // steps are dim, the weekend one step further down.
                    color: weekend ? Globals.colors.faint : Globals.colors.muted
                }
            }
        }

        Item {
            // The grid is wrapped so the popout's height comes from this
            // item's animated preferredHeight alone. A bare `Grid` in the layout
            // would also report its own cell-derived implicitHeight, which
            // changes the instant the month does — that re-targets the
            // capsule's height animation mid-flight and the popout snaps.
            Layout.fillWidth: false
            // fillHeight, so this box absorbs the slack between the capsule's
            // animating height and the month's real height. A ColumnLayout
            // otherwise splits that slack evenly across every row, which slides
            // the header and the weekday row around on each frame of the morph.
            Layout.fillHeight: true
            Layout.preferredHeight: root.liveRows * root.cellHeight
                + Math.max(0, root.liveRows - 1) * Globals.geometry.spacing.xs

            Grid {
                width: root.gridWidth
                // Animated, not the cell-derived implicitHeight: the cells for a
                // 6th row exist the moment the month changes, and clipping them
                // in over motion.morph is what keeps the jump out of it.
                height: root.liveRows * root.cellHeight
                    + Math.max(0, root.liveRows - 1) * Globals.geometry.spacing.xs
                clip: true
                columns: 7
                rowSpacing: Globals.geometry.spacing.xs

            Repeater {
                model: root.rows * 7

                delegate: Item {
                    id: cell

                    width: root.cellWidth
                    height: root.cellHeight

                    readonly property int dayNum: index - root.offset + 1
                    readonly property bool inMonth: dayNum >= 1 && dayNum <= root.monthLen
                    readonly property int ghostNum: dayNum < 1 ? dayNum + root.previousMonthLen
                        : dayNum > root.monthLen ? dayNum - root.monthLen : 0
                    readonly property bool isToday: root.viewingCurrentMonth && inMonth
                        && dayNum === root.today.getDate()

                    HoverHandler {
                        id: cellHover
                    }

                    Rectangle {
                        anchors.fill: parent
                        // Half a step per side, so neighbouring cells leave a
                        // spacing.xs gap instead of their boxes touching.
                        anchors.margins: Globals.geometry.spacing.xs / 2
                        radius: Globals.innerRadius(Globals.geometry.spacing.sm)
                        color: Globals.colors.hover
                        visible: cellHover.hovered

                        Behavior on color { BaseMotion {} }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Globals.geometry.spacing.xs / 2
                        radius: Globals.innerRadius(Globals.geometry.spacing.sm)
                        color: "transparent"
                        border.color: Globals.colors.primary
                        border.width: Globals.geometry.borderWidth.hair
                        visible: cell.isToday
                    }

                    BaseText {
                        anchors.centerIn: parent
                        text: cell.inMonth ? cell.dayNum : cell.ghostNum
                        muted: !cell.inMonth
                        font.features: ({ "tnum": 1 })
                    }
                }
            }
            }
        }
    }
}
