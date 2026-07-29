import QtQuick

// =============================================================================
// Placeholder.qml
// -----------------------------------------------------------------------------
// Composant de rendu PUR : ecran d'attente pour les entrees de la sidebar pas
// encore raccordees a une source de donnees reelle (Itineraire, Climatisation,
// Info passagers, Diagnostics). Ne recoit qu'un texte et une icone depuis
// l'exterieur -- aucune donnee vehicule, aucun contrat de donnees suppose --
// pour ne jamais laisser croire a des informations mesurees qui n'existent
// pas. Positionnement (anchors) laisse a la charge de l'appelant, comme pour
// NavSidebar.qml.
// =============================================================================
Item {
    id: root

    property string message: ""
    property string icon: "⚒"

    Column {
        anchors.centerIn: parent
        spacing: 18

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            color: Theme.onSurfaceVariant
            opacity: 0.45
            font.family: Theme.fontUi
            font.pixelSize: 42
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.message
            color: Theme.onSurfaceVariant
            font.family: Theme.fontUi
            font.pixelSize: 20
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            width: 420
            wrapMode: Text.WordWrap
        }
    }
}
