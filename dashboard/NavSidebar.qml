pragma ComponentBehavior: Bound
import QtQuick

// =============================================================================
// NavSidebar.qml
// -----------------------------------------------------------------------------
// Composant de rendu PUR (style "Lumina Transit") : barre de navigation
// laterale de la maquette (maquette/screen.png). Ne connait rien du vehicule
// ni de la simulation -- il recoit une liste d'entrees ("items") et la cle
// actuellement selectionnee ("activeKey"), et se contente d'emettre
// "itemSelected(key)" au clic. C'est Main.qml qui decide quoi charger en
// reaction a ce signal (cf. Loader + "window.activeNav").
// =============================================================================
Rectangle {
    id: root

    width: 240
    color: Theme.surfaceContainerLowest
    border.color: Qt.rgba(1, 1, 1, 0.05)
    border.width: 1

    property string brandTitle: ""
    property string brandSubtitle: ""
    property string activeKey: ""
    // items: [{ key, label, icon }]
    property var items: []

    signal itemSelected(string key)

    // ---- Logo -----------------------------------------------------------
    Row {
        id: logoRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 12

        Rectangle {
            width: 44
            height: 44
            radius: 10
            color: Theme.surfaceContainer
            border.color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "S8"
                color: Theme.primary
                font.family: Theme.fontUi
                font.pixelSize: 14
                font.weight: Font.Bold
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.brandTitle
                color: Theme.onSurfaceColor
                font.family: Theme.fontUi
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }

            Text {
                text: root.brandSubtitle
                color: Theme.primary
                font.family: Theme.fontUi
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 1
            }
        }
    }

    // ---- Liste de navigation --------------------------------------------
    Column {
        anchors.top: logoRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        anchors.topMargin: 32
        spacing: 8

        Repeater {
            model: root.items

            delegate: Rectangle {
                id: navButton

                required property var modelData
                readonly property bool active: modelData.key === root.activeKey

                width: parent.width
                height: 48
                radius: 8
                color: active ? Theme.secondary : (navArea.pressed ? Theme.surfaceContainerHigh : "transparent")

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text {
                        text: navButton.modelData.icon
                        color: navButton.active ? Theme.onSurfaceColor : Theme.onSurfaceVariant
                        font.family: Theme.fontUi
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: navButton.modelData.label
                        color: navButton.active ? Theme.onSurfaceColor : Theme.onSurfaceVariant
                        font.family: Theme.fontUi
                        font.pixelSize: 14
                        font.weight: navButton.active ? Font.DemiBold : Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: navArea
                    anchors.fill: parent
                    onClicked: root.itemSelected(navButton.modelData.key)
                }
            }
        }
    }
}
