pragma Singleton
import QtQuick

// =============================================================================
// Theme.qml
// -----------------------------------------------------------------------------
// Jetons de design centralises, extraits de maquette/DESIGN.md ("Lumina
// Transit"). Purement visuel : aucune donnee vehicule ici. Singleton QML afin
// que tous les composants de rendu (Main.qml, SpeedometerGauge.qml,
// ThrottleGauge.qml) partagent la meme palette sans la dupliquer.
// =============================================================================
QtObject {
    readonly property color background: "#000000"
    readonly property color surface: "#121317"
    readonly property color surfaceContainerLowest: "#0d0e12"
    readonly property color surfaceContainerLow: "#1a1b1f"
    readonly property color surfaceContainer: "#1e1f23"
    readonly property color surfaceContainerHigh: "#292a2e"
    readonly property color surfaceContainerHighest: "#343539"

    // Meme raison que pour "onPrimaryColor" plus bas : "onSurface" (sans
    // suffixe) collisionne avec la propriete "surface" declaree plus haut et
    // casse le chargement une fois le singleton correctement enregistre.
    // "onSurfaceVariant" n'a pas ce probleme (aucune propriete "surfaceVariant"
    // n'existe) et reste donc inchangee.
    readonly property color onSurfaceColor: "#e3e2e7"
    readonly property color onSurfaceVariant: "#b9cacb"
    readonly property color outlineVariant: "#3b494b"

    // Cyan electrique : donnees actives / etats "Go"
    readonly property color primary: "#00f0ff"
    // Nom "onPrimaryColor" et non "onPrimary" : QML reserve tout identifiant
    // "on" + Majuscule au mecanisme de gestionnaire de signal implicite:
    // une propriete nommee ainsi est rejetee au chargement ("Cannot assign
    // a value to a signal") des que ce singleton est correctement enregistre
    // et donc reellement compile/type-checke.
    readonly property color onPrimaryColor: "#00363a"

    // Orange securite : reserve aux alertes et seuils critiques
    readonly property color secondary: "#ff5e07"

    // ---- Polices --------------------------------------------------------
    // "Inter" / "JetBrains Mono" sont la police d'intention de la maquette
    // (maquette/DESIGN.md), a installer sur l'image Raspberry Pi pour un
    // rendu fidele. Ce ne sont PAS des paquets Debian/Raspberry Pi OS
    // standard : la maquette HTML de reference les charge depuis Google
    // Fonts en ligne (maquette/code.html), ce qui n'existe pas pour une
    // application embarquee hors-ligne. Le type QML "font" n'expose qu'une
    // seule propriete "family" (pas de "families" au pluriel, contrairement
    // a l'API C++ QFont::setFamilies) : impossible donc de fournir une pile
    // de repli explicite depuis QML. Si "Inter"/"JetBrains Mono" sont
    // absentes de l'image cible, Qt retombe silencieusement sur son
    // mecanisme de substitution de police systeme -- comportement standard,
    // non contournable depuis le seul type QML "font".
    readonly property string fontUi: "Inter"
    readonly property string fontMono: "JetBrains Mono"
}
