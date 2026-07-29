cmake_minimum_required(VERSION 3.16)
project(ShuttleDashboard LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Version explicite : le projet utilise deja l'API CMake moderne de Qt
# (qt_add_qml_module, qt_standard_project_setup), qui requiert Qt >= 6.2.
# La rendre explicite ici transforme un Qt trop ancien sur la cible Linux
# (paquets de distribution en retrait par rapport a la derniere version Qt)
# en une erreur de configuration CMake claire et immediate, plutot qu'en
# echec de compilation confus plus loin dans le build.
find_package(Qt6 6.2 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

qt_standard_project_setup()

qt_add_executable(ShuttleDashboard main.cpp)

# Pas de policy QTP0001 forcee ici : le prefixe de ressource genere par
# qt_add_qml_module differe selon la version Qt (">=6.8" vs "<6.8" -- voir
# main.cpp), et le forcer ici obligerait a maintenir le meme seuil de version
# dans deux fichiers. main.cpp sonde directement les ressources embarquees au
# demarrage et reste donc correct quelle que soit la valeur par defaut retenue
# ici -- inutile de la figer.

# "pragma Singleton" dans Theme.qml ne suffit pas a lui seul : sans cette
# marque explicite (posee AVANT qt_add_qml_module, qui lit l'etat des
# proprietes source au moment de son appel), le qmldir genere liste Theme
# comme un type QML normal (non singleton). Consequence a l'execution :
# "Theme.xxx" (utilise partout, Main.qml y compris) se resout en undefined
# au lieu de la valeur de la propriete -- sans erreur ni warning au demarrage,
# juste un rendu qui retombe silencieusement sur les couleurs par defaut de
# Qt Quick (fond blanc, texte noir) au lieu du theme sombre "Lumina Transit".
set_source_files_properties(Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE true
)

qt_add_qml_module(ShuttleDashboard
    URI Dashboard
    VERSION 1.0
    QML_FILES
        Main.qml
        VehicleDataSimulator.qml
        SimulationEngine.js
        SpeedometerGauge.qml
        ThrottleGauge.qml
        NavSidebar.qml
        Placeholder.qml
        Translations.js
        Theme.qml
)

target_link_libraries(ShuttleDashboard PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)
