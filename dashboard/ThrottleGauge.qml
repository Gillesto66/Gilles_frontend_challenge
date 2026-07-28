import QtQuick

// =============================================================================
// ThrottleGauge.qml
// -----------------------------------------------------------------------------
// Jauge verticale "PWR" (style Lumina Transit) purement decorative : recoit
// "percent" (0-100) depuis l'exterieur et anime le remplissage. Aucune
// logique de simulation ici non plus -- seul SimulationEngine.js sait
// comment cette valeur est produite.
//
// SmoothedAnimation (et non NumberAnimation) : "percent" est pilote en
// direct par le slider de test (glissement continu, potentiellement
// inverse tres rapidement -- cf. test de robustesse "spam" de
// l'accelerateur). SmoothedAnimation est concue pour etre re-ciblee en
// continu sans a-coup lors des inversions de sens, ce qu'une NumberAnimation
// a easing/duree fixe gere moins proprement si elle est relancee avant la
// fin de sa transition.
// =============================================================================
Item {
    id: root

    property real percent: 0 // 0-100

    width: 96
    height: 340

    readonly property real _clampedPercent: Math.max(0, Math.min(100, percent))
    property real _animatedPercent: _clampedPercent
    Behavior on _animatedPercent {
        SmoothedAnimation { velocity: 400 }
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Theme.surfaceContainer
        border.color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 1
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "PWR"
            color: Theme.primary
            font.families: Theme.fontUiStack
            font.pixelSize: 12
            font.weight: Font.Bold
            font.letterSpacing: 2
        }

        Item {
            id: track
            width: 28
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height - 74

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.surfaceContainerLowest
                border.color: Qt.rgba(0, 0, 0, 0.6)
                border.width: 1
            }

            // Halo lumineux derriere le remplissage (glow low-cost, sans
            // dependance a Qt5Compat.GraphicalEffects)
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -2
                radius: width / 2
                color: Theme.primary
                opacity: 0.35
                height: fill.height + 4
            }

            Rectangle {
                id: fill
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 4
                radius: width / 2
                color: Theme.primary
                height: (track.height - 8) * root._animatedPercent / 100
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root._animatedPercent.toFixed(0) + " %"
            color: Theme.primary
            font.families: Theme.fontMonoStack
            font.pixelSize: 16
            font.weight: Font.Medium
        }
    }
}
