.pragma library

// =============================================================================
// Translations.js
// -----------------------------------------------------------------------------
// i18n minimaliste pour ce prototype : deux objets litteraux (fr/en), pas de
// Qt Linguist (.ts/.qm), comme demande. Ajouter une langue = ajouter un objet
// et une entree dans get(). Les vues ne font que lire les proprietes de
// l'objet retourne par get(lang) ; aucune dependance a QML ici.
// =============================================================================

var fr = {
    windowTitle: "Tableau de bord - Navette electrique",
    brandTitle: "Navette 01",
    brandSubtitle: "Simulation CAN",
    sysStatus: "SYS OK",
    odometerLabel: "ODO",
    throttleLabel: "PWR",
    testInputLabel: "Entree test (pedale simulee)",
    navDashboard: "Tableau de bord",
    navRoute: "Itineraire",
    navClimate: "Climatisation",
    navPassenger: "Info passagers",
    navDiagnostics: "Diagnostics",
    placeholderModule: "Module en cours de developpement"
};

var en = {
    windowTitle: "Electric Shuttle - Dashboard",
    brandTitle: "Shuttle 01",
    brandSubtitle: "CAN Simulation",
    sysStatus: "SYS OK",
    odometerLabel: "ODO",
    throttleLabel: "PWR",
    testInputLabel: "Test input (simulated pedal)",
    navDashboard: "Dashboard",
    navRoute: "Route",
    navClimate: "Climate",
    navPassenger: "Passenger Info",
    navDiagnostics: "Diagnostics",
    placeholderModule: "Module under development"
};

function get(lang) {
    return lang === "en" ? en : fr;
}
